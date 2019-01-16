//Solidity Version
pragma solidity ^0.5.0;

//contract Declaration
contract myProperyContract {
    
    //variables Declaration
    string myStringStorage;
    uint myIntegerStorage;
    address ContractOwner;
    address currentOwner;
    uint AmountOfOwner;
    
    //constructor allows to define default values
    constructor() public {
        myStringStorage = "";
        myIntegerStorage = 0;
        AmountOfOwner = 1;
        ContractOwner = 0x641AD78BAca220C5BD28b51Ce8e0F495e85Fe689;
        currentOwner = 0x641AD78BAca220C5BD28b51Ce8e0F495e85Fe689;
    }
    
    modifier onlyCurrentOwner() {
        require(msg.sender == currentOwner);
        _;
    }
    
    modifier sellOnlyFor200Ether() {
        require(msg.value == 200 ether);
        _;
    }
    
    function getStringValue() public view returns (string memory) {
        return myStringStorage;
    }
    
    function getIntegerValue() public view returns (uint) {
        return myIntegerStorage;
    }
    
    function setIntegerValue(uint _newValue) public onlyCurrentOwner {
        myIntegerStorage = _newValue;
    }
    
    function setStringValue(string memory _newValue) public onlyCurrentOwner {
        myStringStorage = _newValue;
    }
    
    function doSomeActionWithIncrement(string memory _newValue) public {
        myIntegerStorage = myIntegerStorage + 1;
        myStringStorage = _newValue;
    }
    
    function sellPropertyAndChangeOwnership(address _newOwner) public onlyCurrentOwner {
        AmountOfOwner = AmountOfOwner +1;
        currentOwner = _newOwner;
    }
    
}