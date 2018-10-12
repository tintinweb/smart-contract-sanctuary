pragma solidity ^0.4.24;

contract MyFavoriteNumber {
    
    event newNumber(uint _number);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    address owner;
    uint public price = 0.017 ether;
    uint public number = 0;
    
    function setNumber(uint _number) public payable {
        require(msg.value >= price);
        
        number = _number;
        price *= 2;
        emit newNumber(number);
    }
    
    function transfer(address _address) public onlyOwner returns (bool) {
        _address.transfer(address(this).balance);
        return true;    
    }
    
}