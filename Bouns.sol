
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

contract Bouns is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint256 public amount;

    uint256 public bondAmount;

    uint256 public period;

    uint256 public claimAmount;

    address public USDT;

    bool public started;

    mapping(uint256 => uint256) public periodTotal;

    mapping(uint256 => User[]) public participants;

    mapping(uint256 => User[]) public userRewards;

    mapping(address => bool) public bondAddress;

    struct User {
        uint256 amount;
        address user;
    }

    constructor(
        address _USDT,
        uint256 _amount//1000000000000000000000
    ) {
        USDT = _USDT;
        amount = _amount;
        bondAmount = _amount;
        period = 1;
        started = true;
    }

    function addBondAddress(address _bondAddress) external onlyOwner() {
        bondAddress[_bondAddress] = true;
    }

    function setStarted() external onlyOwner() {
        started = !started;
    }

    function setAmount(uint256 _amount) external onlyOwner() {
        amount = _amount;
    }

    function setBondAmount(uint256 _bondAmount) external onlyOwner() {
        bondAmount = _bondAmount;
    }

    function removeBondAddress(address _bondAddress) external onlyOwner() {
        delete bondAddress[_bondAddress];
    }

    function inputData(address _user,uint256 _amount) external{
        require(bondAddress[msg.sender] == true, "Not bond");
        uint256 myBalance = IERC20(USDT).balanceOf(address(this));
        if(started && _amount >= bondAmount && myBalance.sub(claimAmount) > amount){
            participants[period].push(
                User({
                    user: _user,
                    amount: _amount
                })
            );
            periodTotal[period] += _amount;
            release();
        }
    }



    function testAdd(address _user,uint256 _amount) external {
        participants[period].push(
                User({
                    user: _user,
                    amount: _amount
                })
            );
        periodTotal[period] += _amount;
        release();

    }

    function release() internal {
        uint256 myBalance = IERC20(USDT).balanceOf(address(this));
        User[] memory info = participants[period];
        if(myBalance > claimAmount && info.length == 10){
            for(uint256 i = 0;i<10;i++){
                uint256 rewardAmount = info[i].amount.mul(1e9).div(periodTotal[period]).mul(amount).div(1e9);
                IERC20(USDT).safeTransfer(info[i].user,rewardAmount);
                claimAmount += rewardAmount;
                userRewards[period].push(
                    User({
                        user: info[i].user,
                        amount: rewardAmount
                    })
                );
            }
            period++;
        }
    }

    function getData() external view returns(uint256 _USDTBalance,uint256 _num,User[] memory info){
        _USDTBalance = IERC20(USDT).balanceOf(address(this));
        _num = participants[period].length;
        info = userRewards[period-1];
    }

    function withdraw(address _Token) external onlyOwner() {
        uint256 _amount = IERC20(_Token).balanceOf(address(this));
        IERC20(_Token).transfer(msg.sender, _amount);
    }
}
