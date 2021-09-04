/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl{
    
    address payable owner;
    uint256 LockExpiryTime;
    
    constructor() {
        owner = payable(msg.sender);
        LockExpiryTime = block.timestamp + 365 days;
    }

    function GetOwner() external view returns (address) {
        return owner;
    }
    
    function CheckContractBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function Withdraw() external returns(uint256){
        require (block.timestamp > LockExpiryTime, "lock time has not expired");
        uint256 balance = CheckContractBalance();
        owner.transfer(balance);
        return owner.balance;
    }
   
    function Destroy() external{
        require (block.timestamp > LockExpiryTime, "lock time has not expired");
        selfdestruct(payable(msg.sender));
    }
    
    /////////////////////////////////////////////////
    fallback() external payable {      
    }                            
  
    receive() external payable {            
    }
    
}