
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

}

interface IOwnable {

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner_) external;
}

contract Ownable is IOwnable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual override onlyOwner() {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner_) public virtual override onlyOwner() {
        require(newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner_);
        _owner = newOwner_;
    }
}

contract Invite is Ownable {
    using SafeMath for uint;

    uint256 public denominator = 1e4;
    uint256 public bondRate;

    mapping(address => address) public superiorAddress;

    mapping(address => bool) public memberAddress;

    mapping(address => bool) public bondAddress;

    mapping(address => User) public users;

    mapping(uint256 => uint256) public rewardRate;

    mapping(address => address[]) public invites;
    
    mapping(address => uint256) public inviteNum;


    struct User {
        uint256 totalAmount;
        uint256 pendingAmount;
        uint256 claimAmount;
    }

     constructor(
        uint256 _bondRate,//10000
        uint256 _oneRewardRate,//1000
        uint256 _twoRewardRate//500
    ) {
        bondRate = _bondRate;
        rewardRate[1] = _oneRewardRate;
        rewardRate[2] = _twoRewardRate;
    }


    function inviteAddress(address _superiorAddress) external returns (bool) {
        require(msg.sender != _superiorAddress, "Not superAddress");
        require(memberAddress[msg.sender] == false, "Not superAddress");
        require(_superiorAddress != address(0), "Zero superAddress");
        require(superiorAddress[_superiorAddress] != msg.sender, "error superAddress");
        memberAddress[msg.sender] = true;
        superiorAddress[msg.sender] = _superiorAddress;
        invites[_superiorAddress].push(msg.sender);
        inviteNum[_superiorAddress] += 1;
        return true;
    }

    function buyBond(address _userAddress,uint256 _bondAmount)external returns(
        uint256 _userAmount,
        uint256 totalReward,
        address[] memory _rewardAddress,
        uint256[] memory _rewardAmount) {
        require(bondAddress[msg.sender] == true, "Not bond");

        if(users[_userAddress].pendingAmount > 0){
            uint256 _claimAmount = bondRate > 0?_bondAmount.mul(bondRate).div(denominator) : _bondAmount ;
            if(users[_userAddress].pendingAmount >= _claimAmount){
                _userAmount = _claimAmount;
                users[_userAddress].pendingAmount -= _claimAmount;
            }else{
                _userAmount = users[_userAddress].pendingAmount;
                users[_userAddress].pendingAmount = 0;
            }
            users[_userAddress].claimAmount += _userAmount;
        }
        _rewardAddress = new address[](2);
        _rewardAmount = new uint256[](2);
        for(uint256 i = 1;i<=2;i++){
            address _superiorAddress = superiorAddress[_userAddress];
            if(_superiorAddress != address(0)){
                uint256 rewardAmount = _bondAmount.mul(rewardRate[i]).div(denominator);
                totalReward += rewardAmount;
                if(bondRate > 0){
                    users[_superiorAddress].pendingAmount += rewardAmount;
                }else{
                    _rewardAddress[i]=_superiorAddress;
                    _rewardAmount[i]=rewardAmount;
                }
                users[_superiorAddress].totalAmount += rewardAmount;
                _userAddress = _superiorAddress;
            }else{
                break;
            }
        }
    }

    function addBondAddress(address _bondAddress) external onlyOwner() {
        bondAddress[_bondAddress] = true;
    }

    function removeBondAddress(address _bondAddress) external onlyOwner() {
        delete bondAddress[_bondAddress];
    }

    function totalRewardRate() external view returns (uint256){
        return rewardRate[1] + rewardRate[2];
    }

}
