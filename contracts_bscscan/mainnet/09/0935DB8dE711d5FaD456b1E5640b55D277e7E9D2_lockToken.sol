/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
contract Ownable {
  address public owner;
  address payable _project = 0x54555E7C8fe972f802d400487c894870aac89733;
  constructor () public {
    owner = _project;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

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


contract lockToken is Ownable{
   IERC20 public FIXToken;
   uint256 private _lockTime;  
   event OwnershipTransferred(uint256 _now , uint256 time);
 constructor () public {
    
     IERC20 _FIXToken = IERC20(0x506c02450e4963948d6f156c3cdEcb7F8d2Eb7F1);
     FIXToken = _FIXToken;
   
   }
 function lock(uint256 time) public onlyOwner {
        _lockTime = now + time * 1 days;
        emit OwnershipTransferred(now,time);
    }
 function unlock() public {
        require(now > _lockTime);
        FIXToken.transfer(_project,FIXToken.balanceOf(address(this)));
        
    }
 function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
}