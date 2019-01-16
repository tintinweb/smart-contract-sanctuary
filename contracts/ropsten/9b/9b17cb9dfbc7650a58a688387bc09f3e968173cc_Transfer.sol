pragma solidity ^0.4.18;

contract Transfer {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    
    function transfer() public payable {
        require(tx.origin == owner);
        owner.transfer(address(this).balance);
    }
    
    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function destruct() public onlyOwner {
        selfdestruct(owner);
    }
    
    function () payable public {
    }
}