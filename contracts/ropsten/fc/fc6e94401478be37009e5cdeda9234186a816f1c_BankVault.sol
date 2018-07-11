pragma solidity ^0.4.23;

contract BankVault {
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }
    
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }
}