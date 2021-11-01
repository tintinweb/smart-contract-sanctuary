/**
 *Submitted for verification at BscScan.com on 2021-10-31
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

contract VestingContract is Context, Ownable {
    using SafeMath for uint256;
    

    address dogex;
    uint256 public installmentPeriod = 1 hours; //weeks;
    uint256 public startTime;
    mapping(address => uint256) private _tokenBalances;
    mapping(address => uint256) private _tokenClaimed;
    mapping(address => uint256) private _claimed;

    event Claimed(
        address indexed to,
        uint256 amount,
        uint256 installmentIndex
    );
    

    constructor(address _dogex)  {
        startTime = block.timestamp;
        dogex = _dogex;
    }
    
    function updateClaimableToken(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "invalid input data");
        uint256 length = accounts.length;
        for(uint256 i=0 ; i< length; i++){
            _tokenBalances[accounts[i]] = amounts[i];
        }
    }
   
   function claim1() external {
       require(block.timestamp > startTime.add(installmentPeriod), "Installment is locked");
       require(_claimed[_msgSender()] == 0, "Already Claimed or Previous not Claimed");
       uint256 amount = _tokenBalances[_msgSender()].div(4);
       
       _claimed[_msgSender()] = 1;
    //   TransferHelper.safeTransfer(dogex,_msgSender(),amount);
       emit Claimed(_msgSender(),amount,1);
   }
   
   function claim2() external {
       require(block.timestamp > startTime.add(installmentPeriod*2), "Installment is locked");
       require(_claimed[_msgSender()] == 1 , "Already Claimed or Previous not Claimed");
       uint256 amount = _tokenBalances[_msgSender()].div(4);
       
       _claimed[_msgSender()] = 2;
    //   TransferHelper.safeTransfer(dogex,_msgSender(),amount);
       emit Claimed(_msgSender(),amount,2);
   }
   
   function claim3() external {
       require(block.timestamp > startTime.add(installmentPeriod*3), "Installment is locked");
       require(_claimed[_msgSender()] == 2, "Already Claimed or Previous not Claimed");
       uint256 amount = _tokenBalances[_msgSender()].div(4);
       
       _claimed[_msgSender()] = 3;
    //   TransferHelper.safeTransfer(dogex,_msgSender(),amount);
       emit Claimed(_msgSender(),amount,3);
   }
   
   function claim4() external {
       require(block.timestamp > startTime.add(installmentPeriod*4), "Installment is locked");
       require(_claimed[_msgSender()] == 3, "Already Claimed or Previous not Claimed");
       uint256 amount = _tokenBalances[_msgSender()].div(4);
       
       _claimed[_msgSender()] = 4;
    //   TransferHelper.safeTransfer(dogex,_msgSender(),amount);
       emit Claimed(_msgSender(),amount,4);
   }
   
    function getClaimedStatus(address account) external view returns (uint256) {
        return _claimed[account];
    }
    

    function getClaimbleBalance(address account) external view returns (uint256) {
        return _tokenBalances[account];
    }
    
    function getPhase() external view returns (uint256) {
        return block.timestamp.sub(startTime).div(installmentPeriod);
    }
}