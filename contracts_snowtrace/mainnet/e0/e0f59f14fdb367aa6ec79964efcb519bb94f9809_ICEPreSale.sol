/**
 *Submitted for verification at snowtrace.io on 2021-12-01
*/

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

contract ICEPreSale is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public alphaICE;
    address public  DAOAddress;
    address public mim;

    uint public minAmount; 
    uint public maxAmount; 
    uint public salePrice; 
    uint public startTimestamp;
    uint public endTimestamp;
    uint public toTalAmount;
    uint public sellAmount;
    uint public remainingPurchasesMaxAmt;

    bool public saleStarted;

    mapping(address => bool) public boughtICE;
    mapping(address => bool) public whiteListed;

    function whiteListBuyers(address[] memory _buyers) external onlyOwner() returns (bool) {
        for (uint i; i < _buyers.length; i++) {
            whiteListed[_buyers[i]] = true;
        }
        return true;
    }

    function initialize(
        address _DAOAddress,
        address _alphaICE,
        address _mim,
        uint _minAmount,
        uint _maxAmount,
        uint _toTalAmount,
        uint _salePrice,
        uint _startTimestamp,
        uint _endTimestamp,
        uint _remainingPurchasesMaxAmt
        ) external onlyOwner() returns (bool) {

        alphaICE = _alphaICE;

        mim = _mim;

        salePrice = _salePrice;

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        DAOAddress = _DAOAddress;

        minAmount = _minAmount;

        maxAmount = _maxAmount;

        toTalAmount = _toTalAmount;

        remainingPurchasesMaxAmt = _remainingPurchasesMaxAmt;

        saleStarted = true;
        return true;
    }
    
    function setStart() external onlyOwner() returns (bool) {
        saleStarted = !saleStarted;
        return saleStarted;
    }

    function purchaseaICE(uint256 _val) external returns (bool) {

        require(_val >= minAmount, 'Below minimum allocation');
        require(_val <= maxAmount, 'More than allocation');
        sellAmount = sellAmount.add(_val);
        require(sellAmount <= toTalAmount, 'The amount entered exceeds Fundraise Goal');
        require(saleStarted == true, 'Not started');
        require(boughtICE[msg.sender] == false, 'Already participated');
        require(startTimestamp < block.timestamp,"Not started yet");

        boughtICE[msg.sender] = true;

        if(endTimestamp < block.timestamp){
            require(_val <= remainingPurchasesMaxAmt , "Exceeded IDO limit");
        }else{
            require(whiteListed[msg.sender] == true, 'Not whitelisted');
            require(block.timestamp < endTimestamp, 'Sale over');
        }
        IERC20(mim).safeTransferFrom(msg.sender ,address(this), _val);
        IERC20(mim).safeTransfer(DAOAddress, _val);
        uint _purchaseAmount = _calculateSaleQuote(_val);
        IERC20(alphaICE).safeTransfer(msg.sender, _purchaseAmount);
        return true;
    }
    
    function _calculateSaleQuote(uint paymentAmount_) internal view returns (uint) {
        return uint(1e9).mul(paymentAmount_).div(salePrice);
    }

    function calculateSaleQuote(uint paymentAmount_) external view returns (uint) {
        return _calculateSaleQuote(paymentAmount_);
    }
    
}