//SourceUnit: Main.sol

pragma solidity ^0.5.4;

contract Main {

    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    event Record(string info);
    event FailedPayment(address indexed beneficiary, uint amount);
    event Payment(address indexed beneficiary, uint amount);

    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    function kill() public onlyOwner{
        selfdestruct(owner);
    }

    function getOwner() public view returns (address) {
        return owner;
    }
  
    function sendRecord(string memory data) public onlyOwner {
        emit Record(data);
    }
    
    function withdraw(uint amount) public onlyOwner {
        require (amount <= address(this).balance, "Increase amount larger than balance.");
        if (owner.send(amount)) {
            emit Payment(owner, amount);
        } else {
            emit FailedPayment(owner, amount);
        }
    }
}