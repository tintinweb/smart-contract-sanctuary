pragma solidity ^0.4.24;

contract UnitsFactory {
    address public creatorAddress;
    address public factoryAddress;
    
    address[] private proposedUnits;
    
    struct proposedUnitSummary {
        string title;
        address unitAddress;
        uint sqiPrice;
        uint totalSqi;
        uint currentAvailableSqi;
    }
    
    mapping (address => proposedUnitSummary) public proposedUnitSummaries;


    // METHODS CALLS
    // -----------------------------------------------------------------------------------------------------------------
    
    constructor () public {
        creatorAddress = msg.sender;
        factoryAddress = address(this);
    }
    
    
    function createUnit (string title, uint sqiPrice, uint totalSqi) public {
        require (msg.sender == creatorAddress);
        
        // task creation 
        address newUnit = new Unit(creatorAddress, factoryAddress, title, sqiPrice, totalSqi);
        proposedUnits.push(newUnit);
        
        // Updating mapping values
        proposedUnitSummary memory temp;
        temp.unitAddress = newUnit;
        temp.title = title;
        temp.sqiPrice = sqiPrice;
        temp.totalSqi = totalSqi;
        temp.currentAvailableSqi = totalSqi;

        proposedUnitSummaries[newUnit] = temp;
    }
    
    
    function updateCurrentAvailableSqi(address unitAddress, uint newCurrentSqi ) public {
        require (msg.sender == unitAddress);
        proposedUnitSummaries[unitAddress].currentAvailableSqi = newCurrentSqi;
    }
    
    function getProposedUnits() public view returns (address[]) {
        return proposedUnits;
    }
    
    function getFactoryBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function () public payable  {

    }
    
}


contract Unit {
    address private creator;
    address private factory;
    address public factoryAddress;

    string private title;
    uint private sqiPrice;
    uint private totalSqi;
    uint private currentAvailableSqi;
    
    

    constructor(address _creator, address _factory, string _title, uint _sqiPrice, uint _totalSqi) public {
        creator = _creator;
        factory = _factory;
        // check title not null
        bytes memory _titleCheck = bytes(_title); // Uses memory
        require(_titleCheck.length != 0);
        
        // setted by the constructor
        title = _title;
        sqiPrice = _sqiPrice;
        totalSqi = _totalSqi;
        currentAvailableSqi = _totalSqi;
    
    }
    
    // GETTER
    // -------------------------------------------------------------------------
    function getUnitInfo() public view returns (
        address, string, uint, uint, uint, uint) { 
            return (
                factory,
                title,
                totalSqi,
                currentAvailableSqi,
                sqiPrice,
                address(this).balance
            );
        }
    
    
    
    
    // PUT ETHERS IN THE HOUSE
    // -------------------------------------------------------------------------
    function invest(uint numberOfSqi) public payable  {

        require(msg.value >= sqiPrice * numberOfSqi);
        require(numberOfSqi <= currentAvailableSqi);
        currentAvailableSqi = currentAvailableSqi - numberOfSqi;
        
        UnitsFactory f = UnitsFactory(factory);
        f.updateCurrentAvailableSqi(address(this), currentAvailableSqi);

    }
    

    // TRANSFERRING ETHERS FROM THE HOUSE TO THE FACTORY 
    // -------------------------------------------------------------------------
    function transferToCreator() public  {
        require(msg.sender == creator);
        creator.transfer(address(this).balance); 
    }

}