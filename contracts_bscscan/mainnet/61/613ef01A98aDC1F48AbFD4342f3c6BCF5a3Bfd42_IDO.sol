/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
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
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "e3");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ow1");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ow2");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "e4");
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}



contract IDO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    IERC20 public idoToken;
    IERC20 public USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    uint256 public minAmount = 1250*1e18;
    uint256 public maxAmount = 12500*1e18;
    uint256 public price = 8*1e16;
    address public feeAddress;
    
    mapping(address=>uint256) public userIdoList;
    
    
    struct Info {
    IERC20  idoToken;
    IERC20  USDT;
    uint256  minAmount;
    uint256  maxAmount;
    uint256  price;
    }
    
    
    function getUserInfo(address _address) public view returns (Info memory igoInfo,uint256 quote) {
        igoInfo = Info(idoToken,USDT,minAmount,maxAmount,price);
        quote = maxAmount.sub(userIdoList[_address]);
    }
    
    function setFeeAddress (address _address) public onlyOwner {
        feeAddress = _address;
    }
    
    
    function setToken(IERC20 _token) public onlyOwner {
        idoToken = _token;
    }
    
    function setAmount(uint256 _minAmount,uint256 _maxAmount) public onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }
    
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    
    
    function setIgoAmount(IERC20 _token,uint256 _minAmount,uint256 _maxAmount,uint256 _price) public onlyOwner {
        idoToken = _token;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        price = _price;
    }
    
    
    function ido(uint256 _amount) public nonReentrant {
        require(_amount>=minAmount && _amount<=maxAmount,"e01");
        require(_amount.add(userIdoList[msg.sender])<=maxAmount,"e02");
        uint256 usdtAmount = _amount.mul(price).div(1e18);
        USDT.transferFrom(msg.sender,feeAddress,usdtAmount);
        idoToken.safeTransfer(msg.sender,_amount);
        userIdoList[msg.sender] = userIdoList[msg.sender].add(_amount);
    }
    

    function takeTokens(address _token) public onlyOwner returns (bool){
        if (_token == address(0) && address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
            return true;
        } else if (_token != address(0) && IERC20(_token).balanceOf(address(this)) > 0) {
            IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
            return true;
        } else {
            return false;
        }
    }


    receive() payable external {}
}