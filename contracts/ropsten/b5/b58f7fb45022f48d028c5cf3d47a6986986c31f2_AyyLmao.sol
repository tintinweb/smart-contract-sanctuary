pragma solidity ^0.5.0;

contract AyyLmao {
    address payable internal owner;
    
    constructor() public{
        owner = msg.sender;
        msg.sender.transfer(address(this).balance);
    }
    
    function ayy() payable public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}