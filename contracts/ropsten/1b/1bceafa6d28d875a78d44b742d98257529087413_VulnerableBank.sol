/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.8.0;

contract VulnerableBank {
    
    mapping (address=>uint256) balance;
    
    function deposit () external payable {
        balance[msg.sender]+=msg.value;
    }
    function withdraw () external payable{
        require(balance[msg.sender]>=0,'Not enough ether');
        payable(msg.sender).call{value:balance[msg.sender]}("");
        balance[msg.sender]=0;
    }
    function banksBalance () public view returns (uint256){
        return address(this).balance;
    }
    function userBalance (address _address) public view returns (uint256){
        return balance[_address];
    }
}