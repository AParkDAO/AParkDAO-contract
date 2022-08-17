// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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

contract APEPARKPreSale is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public alphaAPD;
    address public DAOAddress;
    address public USDT;

    uint public minAmount; 
    uint public maxAmount; 
    uint public salePrice; 
    
    uint public toTalAmount;
    uint public saleAmount;

    uint public startTimestamp;
    

    mapping(address => bool) public bought;
    mapping(address => bool) public whiteListed;

    function whiteListBuyers(address[] memory _buyers) external onlyOwner() {
        for (uint i; i < _buyers.length; i++) {
            whiteListed[_buyers[i]] = true;
        }
    }

    function initialize(
        address _DAOAddress,//0xCDf13985Af32f58a53804624c3DeD42EF89b4352
        address _alphaAPD,//0xE7B9CEccB5260B976EC5Bd772A1d032278415de9
        address _USDT,//0xD8691a1A815a874E3094A8B5102C5cC9520cA8Ed
        uint _minAmount,//500000000000000000000
        uint _maxAmount,//1000000000000000000000
        uint _toTalAmount,//500000000000000000000000
        uint _salePrice,//5000000000000000000
        uint _startTimestamp//1647698400
        ) external onlyOwner() {
        DAOAddress = _DAOAddress;
        alphaAPD = _alphaAPD;
        USDT = _USDT;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        toTalAmount = _toTalAmount;
        salePrice = _salePrice;
        startTimestamp = _startTimestamp;
    }

    function purchasea(uint256 _val) external {
        require(whiteListed[msg.sender] == true, 'Not whitelisted');
        require(_val >= minAmount, 'Below minimum allocation');
        require(_val <= maxAmount, 'More than allocation');
        saleAmount = saleAmount.add(_val);
        require(saleAmount <= toTalAmount, 'The amount entered exceeds Fundraise Goal');
        require(bought[msg.sender] == false, 'Already participated');
        require(startTimestamp < block.timestamp,"Not started yet");
        bought[msg.sender] = true;
        IERC20(USDT).safeTransferFrom(msg.sender ,DAOAddress, _val);
        uint _purchaseAmount = _calculateSaleQuote(_val);
        IERC20(alphaAPD).safeTransfer(msg.sender, _purchaseAmount);
    }
    
    function _calculateSaleQuote(uint paymentAmount_) internal view returns (uint) {
        return uint(1e9).mul(paymentAmount_).div(salePrice);
    }

    function calculateSaleQuote(uint paymentAmount_) external view returns (uint) {
        return _calculateSaleQuote(paymentAmount_);
    }

    function withdraw(address _token) external onlyOwner() {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }
    
}