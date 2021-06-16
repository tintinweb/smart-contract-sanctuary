/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT
/*
 * Copyright © 2020 reflect.finance. ALL RIGHTS RESERVED.
 */

pragma solidity ^0.6.2;

// interface IERC20 {
  
//   function transfer(address recipient, uint amount) external returns(bool);

  
//   event Transfer(address indexed from, address indexed to, uint value);
//   event Approval(address indexed owner, address indexed spender, uint value);
// }

 abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

library SafeMath {
  function add(uint a, uint b) internal pure returns(uint) {
    uint c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint a, uint b) internal pure returns(uint) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
    require(b <= a, errorMessage);
    uint c = a - b;

    return c;
  }

  function mul(uint a, uint b) internal pure returns(uint) {
    if (a == 0) {
        return 0;
    }

    uint c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint a, uint b) internal pure returns(uint) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint c = a / b;

    return c;
  }
}

  contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

  /*
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  * Functions for owner
  * ----------------------------------------------------------------------------------------------------------------------------------------------
  */
  
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// interface ICatoshi {
//   function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool);
// }

contract BridgeBase is Context, Ownable {
    using SafeMath for uint256;
    
    uint256 private _mintFee = 5;
    mapping (address => uint256) private _balances;

    // ICatoshi catoshi;
    address catoshiAddress;
    address system;
    
    event SwapRequest(
      address to,
      uint256 amount
    );

    modifier onlySystem() {
        require(system == _msgSender(), "Ownable: caller is not the system");
        _;
    }

    constructor(address _catoshi, address _system) public {
    //   catoshi = ICatoshi(_catoshi);
      catoshiAddress = _catoshi;
      system = _system;
    }
    /**
   * @dev Transfer token to a specified address.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
   
  // function transfer(address to, uint256 value) public override returns (bool) {
  //   _transfer(msg.sender, to, value);
  //   return true;
  // }

  
  /** 
   * @dev Transfer token for a specified addresses.
   * @param from The address to transfer from.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   */
  //  function _transfer(address from, address to, uint256 value) internal {
  //   require(from != address(0),"Invalid from Address");
  //   require(to != address(0),"Invalid to Address");
  //   require(value > 0, "Invalid Amount");
  //   _balances[from] = _balances[from].sub(value);
  //   _balances[to] = _balances[to].add(value);
  //   emit Transfer(from, to, value);
  // }

   
   /**
   * @dev Function for setting mint fee by owner
   * @param mintFee Mint Fee
   */
  function setMintFee(uint256 mintFee) public onlyOwner returns(bool){
    require(mintFee > 0, "Invalid Percentage");
    _mintFee = mintFee;
    return true;
  }

  /**
   * @dev Function for getting rewards percentage by owner
   */
  function getMintFee() public view returns(uint256){
    return _mintFee;
  }

    function swap (uint256 amount) external {
        
        TransferHelper.safeTransferFrom(catoshiAddress, _msgSender(), address(this), amount);
        // catoshi.transferFrom(_msgSender(), to, temp);
        emit SwapRequest(_msgSender(),amount);
    }

    function feeCalculation(uint256 amount) public view returns(uint256) { 
       uint256 _amountAfterFee = (amount-(amount.mul(_mintFee)/100));
        return _amountAfterFee;
    }  

    function swapBack (address to, uint256 amount) external onlySystem {
      uint256 temp = feeCalculation(amount);
      TransferHelper.safeApprove(catoshiAddress,address(this),temp);
      TransferHelper.safeTransferFrom(catoshiAddress, address(this), to, temp);
        // catoshi.transferFrom(address(this),to,temp);

    }  
}