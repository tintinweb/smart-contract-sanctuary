/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.5.0;


contract Wallet {
    address payable public owner;
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    modifier OnlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function topup() public payable {
        
    }
    
    function withdraw(address payable to, uint256 value) public OnlyOwner {
        to.transfer(value);
    }

    function () external payable{}
}