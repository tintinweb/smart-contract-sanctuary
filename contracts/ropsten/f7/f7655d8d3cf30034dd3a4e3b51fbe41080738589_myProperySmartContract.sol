//Solidity Version
pragma solidity ^0.5.0;

//contract Declaration
contract myProperySmartContract {
    
    //variables Declaration
    address public currentOwner;
    address public potentialOwner; //person we want to sell
    
    uint public AmountOfOwner; //keep track of amount of owners
    uint public sizeInM2 = 10;
    
    uint public currentPrice = 1 ether; //selling price;
    
    
    //constructor allows to define default values
    constructor(address _defaultOwner) public {
        AmountOfOwner = 1;
        currentOwner = _defaultOwner;
    }
    
    modifier onlyCurrentOwner() {
        require(msg.sender == currentOwner, "you are not the owner");
        _;
    }

    modifier onlyPotentialOwner() {
        require(msg.sender == potentialOwner, "you are not potential owner");
        _;
    }

    //price change function
    function changePrice(uint _newPrice) public onlyCurrentOwner {
        currentPrice = _newPrice;
    }

    function allocateOwnership(address _newOwner) public onlyCurrentOwner {
        potentialOwner = _newOwner;
    }

    function buyProperty() public payable onlyPotentialOwner {
        require(msg.value >= currentPrice);
        currentOwner = potentialOwner;
        AmountOfOwner = AmountOfOwner + 1;
    }
    
}