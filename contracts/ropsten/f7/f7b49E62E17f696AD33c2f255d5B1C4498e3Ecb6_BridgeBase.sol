/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: MIT
/*
 * Copyright © 2020 reflect.finance. ALL RIGHTS RESERVED.
 */

pragma solidity ^0.8.4;

 abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
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

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

  
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

contract BridgeBase is Context, Ownable {
    using SafeMath for uint256;
    
  
    
    uint256 private _nonce;
    mapping(uint256 => bool) private _nonceProcessed;
    uint256 private _processedFees = 0.005 ether;
    uint256 private _bridgeFee = 2;
    bool public _isBridgingPaused = false;
    
    mapping(address => bool) private _blacklisted;


    address dogex;
    address system;
    address bridgeFeesAddress = 0xDF4aFe2711A3f42769958f1049e6256fB8865E69;

    
    event SwapRequest(
      address indexed to,
      uint256 amount,
      uint256 nonce
    );

    modifier onlySystem() {
        require(system == _msgSender(), "Ownable: caller is not the system");
        _;
    }
    
    modifier bridgingPaused() {
        require(!_isBridgingPaused, "the bridging is paused");
        _;
    }

    constructor(address _system)  {
      system = _system;
        
    }
   
   function updateDogexContract(address _dogex) external onlyOwner {
       dogex = _dogex;
   }
    function setBridgeFee(uint256 bridgeFee) external onlyOwner returns(bool){
        require(bridgeFee > 0, "Invalid Percentage");
        _bridgeFee = bridgeFee;
        return true;
  }
    
      function getBridgeFee() external view returns(uint256){
        return _bridgeFee;
      }
      
      function setSystem(address _system) external onlyOwner returns(bool){
          system = _system;
          return true;
      }
      
    //   function isBlacklisted(address account) external view returns(bool) {
    //       return _blacklisted[account];
    //   }
      
      
      function setProcessedFess(uint256 processedFees) external onlyOwner {
          _processedFees = processedFees;
      }
  

    function getBridgeStatus(uint256 nonce) external view returns(bool) {
        return _nonceProcessed[nonce];
    }
    
    
    function updateBridgingStaus(bool paused) external onlyOwner {
        _isBridgingPaused = paused;
    }
    

    
    function swap (uint256 amount) external bridgingPaused payable {
        require(msg.value>= _processedFees, "Insufficient processed fees");
        _nonce.add(1);
        TransferHelper.safeTransferFrom(dogex, _msgSender(), address(this), amount);
        payable(system).transfer(msg.value);
        emit SwapRequest(_msgSender(),amount,_nonce);
    }
    
    function feeCalculation(uint256 amount) public view returns(uint256) { 
       uint256 _amountAfterFee = (amount-(amount.mul(_bridgeFee)/1000));
        return _amountAfterFee;
    }  
    
    function swapBack (address to, uint256 amount,uint256 nonce) external onlySystem {
        require(!_nonceProcessed[nonce], "Swap is already proceeds");
        _nonceProcessed[nonce] = true;
        
        uint256 temp = feeCalculation(amount);
        uint256 fees = amount.sub(temp);
      
    //   TransferHelper.safeApprove(dogex,address(this),fees);
      TransferHelper.safeTransfer(dogex,bridgeFeesAddress, fees);
      
    //   TransferHelper.safeApprove(dogex,address(this),temp);
      TransferHelper.safeTransfer(dogex, to, temp);

    }  
}