/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

pragma solidity ^0.8.10;

// ----------------------------------------------------------------------------
// --- Name   : AlphaDAO - [https://www.alphadao.financial/]
// --- Symbol : Format - {OX}
// --- Supply : Generated from DAO
// --- @title : the Beginning and the End 
// --- 01000110 01101111 01110010 00100000 01110100 01101000 01100101 00100000 01101100 
// --- 01101111 01110110 01100101 00100000 01101111 01100110 00100000 01101101 01111001 
// --- 00100000 01100011 01101000 01101001 01101100 01100100 01110010 01100101 01101110
// --- AlphaDAO.financial - EJS32 - 2021
// --- @dev pragma solidity version:0.8.10+commit.fc410830
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Interface IERC20
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// --- Library SafeMath
// ----------------------------------------------------------------------------

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
        return c;
    }
}

// ----------------------------------------------------------------------------
// --- Library Address
// ----------------------------------------------------------------------------

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// ----------------------------------------------------------------------------
// --- Library SafeERC20
// ----------------------------------------------------------------------------

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
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// ----------------------------------------------------------------------------
// --- Interface IOwnable 
// ----------------------------------------------------------------------------

interface IOwnable {

  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

// ----------------------------------------------------------------------------
// --- contract Ownable 
// ----------------------------------------------------------------------------

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

// ----------------------------------------------------------------------------
// --- contract OXPreSale 
// ----------------------------------------------------------------------------

contract OXPreSale is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;  
    
    address public iOX;
    address public DAI;
    address public addressToSendDai;
    
    uint public salePrice;
    uint public totalWhiteListed;
    uint public endOfSale;

    bool public saleStarted;

    mapping(address => bool) boughtOX;
    mapping(address => bool) whiteListed;

    function whiteListBuyers( address[] memory _buyers ) external onlyOwner() returns ( bool ) {
        require(saleStarted == false, 'Already initialized');

        totalWhiteListed = totalWhiteListed.add( _buyers.length );

        for( uint i; i < _buyers.length; i++ ) {
            whiteListed[_buyers[i]] = true;
        }

        return true;

    }
    
    function initialize ( address _addressToSendDai, address _dai, address _iOX, uint _salePrice, uint _saleLength ) external onlyOwner() returns(bool) {
        require(saleStarted == false, 'Already initialized');

        iOX = _iOX;
        
        DAI = _dai;

        salePrice = _salePrice;
        
        endOfSale = _saleLength.add(block.timestamp);

        saleStarted = true;

        addressToSendDai = _addressToSendDai;

        return true;
    }

    function getAllotmentPerBuyer() public view returns (uint) {
        return IERC20( iOX ).balanceOf(address(this)).div(totalWhiteListed);
    }

    function purchaseiOX(uint _amountDAI) external returns(bool) {
        require (saleStarted == true, 'Not started');
        require(whiteListed[msg.sender] == true, 'Not whitelisted');
        require(boughtOX[msg.sender] == false, 'Already participated');
        require(block.timestamp < endOfSale, 'Sale over');

        boughtOX[msg.sender] = true;

        uint _purchaseAmount = _calculateSaleQuote( _amountDAI );



        IERC20( DAI ).safeTransferFrom(msg.sender, addressToSendDai, _amountDAI);
        IERC20( iOX ).safeTransfer(msg.sender, _purchaseAmount);

        return true;
    }

    function sendRemainingiOX() external onlyOwner() returns(bool) {
        require (saleStarted == true, 'Not started');
        require (block.timestamp >= endOfSale, 'Not ended');

        IERC20( iOX ).safeTransfer(msg.sender, IERC20( iOX ).balanceOf(address(this)));

        return true;

    }

    function _calculateSaleQuote( uint paymentAmount_ ) internal view returns ( uint ) {
      return uint(1e9).mul(paymentAmount_).div(salePrice);
    }

    function calculateSaleQuote( uint paymentAmount_ ) external view returns ( uint ) {
      return _calculateSaleQuote( paymentAmount_ );
    }
}