pragma solidity ^0.4.17;

//this is a totally different contract 


contract EtherTransferTo{
    address public owner;
    
    constructor() public {
    owner = msg.sender;
  }
  
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;

    }
    
    function () payable public {
        // nothing to do!
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function withdraw(uint amount) onlyOwner returns(bool) {
        require(amount <= this.balance);
        owner.transfer(amount);
        return true;

    }
    

}