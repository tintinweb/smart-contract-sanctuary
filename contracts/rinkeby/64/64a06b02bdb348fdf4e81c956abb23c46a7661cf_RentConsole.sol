/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity ^0.8.0;

contract RentConsole {
    
    address payable owner;
    uint rentalPeriod;
    
    mapping (uint => Console) consoles;
    mapping (uint => rentInfo) rentedConsoles;
    
    enum ConsoleType {PS4, PS3, Xbox360, xboxOne}
    
    struct Console {
        string color;
        uint price;
        bool isValid;
        ConsoleType consoleType;
    }
    
    struct rentInfo {
        address payable renter;
        uint startTime; 
        uint lastPayedPrice;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAfterConsolePeriod(uint consoleId) {
        require(block.timestamp > rentedConsoles[consoleId].startTime + rentalPeriod);
        _;
    }
    
    modifier onlyIfConsoleExist(uint consoleId) {
        require(consoles[consoleId].isValid == true);
        _;
    }
    
    constructor(uint _rentalPeriod) {
        owner = payable(msg.sender);
        rentalPeriod = _rentalPeriod;
    }
    
    function addConsole(uint consoleId, string memory color, uint consoleType, uint price) public {
        Console memory console = Console(color, price, true, ConsoleType(consoleType));
        
        consoles[consoleId] = console;
    }
    
    event logEvent(string);
    
    function rent(uint consoleId) public payable onlyIfConsoleExist(consoleId) {
        Console memory console = consoles[consoleId];
        
        uint payedPrice = msg.value;
        uint consolePrice = console.price * 10**18;
        
        address payable renter = payable(msg.sender);
        
        if (payedPrice == consolePrice) {
            require(block.timestamp > rentedConsoles[consoleId].startTime + rentalPeriod);
            
            rentInfo memory info = rentInfo(renter, block.timestamp, payedPrice);
            rentedConsoles[consoleId] = info;
            
            emit logEvent("Console Rented.");
        } else if (payedPrice == consolePrice * 2) {
            address payable oldRenter = rentedConsoles[consoleId].renter;
            uint lastPayed = rentedConsoles[consoleId].lastPayedPrice;
            
            require(oldRenter.send(lastPayed));
            
            rentedConsoles[consoleId].lastPayedPrice = payedPrice;
            delegate(consoleId, renter);
        } else {
            emit logEvent("Invalid Price.");
        }
    }
    
    function revoke(uint consoleId) public onlyOwner onlyAfterConsolePeriod(consoleId) {
        delete rentedConsoles[consoleId];
        emit logEvent("Revoke Console done.");
    }
    
    function delegate(uint consoleId, address payable newRenter) public {
        rentedConsoles[consoleId].renter = newRenter;
        emit logEvent("Delegate complete.");
    }
    
    function getConsole(uint consoleId) public view returns(string memory, ConsoleType, uint, uint, uint, address) {
        
        Console memory console = consoles[consoleId];
        
        return (console.color, console.consoleType, console.price, 
        rentedConsoles[consoleId].startTime, rentedConsoles[consoleId].lastPayedPrice, 
        rentedConsoles[consoleId].renter);
    }
}