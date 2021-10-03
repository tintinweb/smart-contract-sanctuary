/**
 *Submitted for verification at polygonscan.com on 2021-10-02
*/

pragma solidity 0.8.0;

contract EVStations {
    
    // state variables
    enum StationType {AC, DC}
    
    address public companyAddress;
    string public companyName;
    
    struct Investor{
        string investorName;
        uint totalStationCount;
    }
    mapping(address => Investor) public investors;
    mapping(address => bool) public isInvestor;
    
    mapping(StationType => uint) public stationTypePrice;
    mapping(StationType => uint) public saleableStations;
    mapping(StationType => uint) public perUnitFees;
    
    struct Station{
        uint stationId;
        StationType typeOfStation;
        uint pricePerUnit;
        uint location;
        bool isActive;
    }
    mapping(uint => Station) public stations;
    mapping(uint => address) public stationsOwners;
    uint public stationCounter;
    
    // logic
    
    modifier onlyCompany() {
        require(msg.sender == companyAddress, "EVStations: sender is not the owner");
        _;
    }
    
    modifier allowedToAdd(StationType _type) {
        require( stationTypePrice[_type] != 0, "EVStations: station price cannot be zero");
        _;
    }
    
    modifier onlyInvestor() {
        require( isInvestor[msg.sender] , "EVStations: you are not registered as an investor" );
        _;
    }
    
    modifier onlyStationOwner(uint _stationId) {
        require( stationsOwners[_stationId] == msg.sender, "EVStations: you are not the station owner" );
        _;
    }
    
    constructor (string memory _companyName) {
        companyAddress = msg.sender;
        companyName = _companyName;
    }
    
    function addStation(StationType _type, uint _quantity) public onlyCompany allowedToAdd(_type) {
        saleableStations[_type] += _quantity;
    }
    
    function setTypePrice(StationType _type, uint _price) public onlyCompany {
        stationTypePrice[_type] = _price * (1 ether);
    }
    
    function setPerUnitFee(StationType _type, uint _perUnitFee) public onlyCompany {
        perUnitFees[_type] = _perUnitFee;
    }
    
    function registerAsInvestor(string memory _investorName) public {
        isInvestor[msg.sender] = true;
        Investor memory investor = Investor(_investorName,0);
        investors[msg.sender] = investor;
    }
    
    function buyStation(StationType _type, uint _location) public onlyInvestor payable {
        require( stationTypePrice[_type] == msg.value, "EVStations: please send correct amount" );
        saleableStations[_type]--;
        stationCounter++;
        Station memory station = Station(stationCounter,_type, 0,_location, false);
        stations[stationCounter] = station;
        stationsOwners[stationCounter] = msg.sender;
        investors[msg.sender].totalStationCount++;
    }
    
    function activateStation(uint _stationId) public onlyStationOwner(_stationId) {
        require( stations[_stationId].pricePerUnit != 0, "EVStations: cannot activate with price per unit = 0" );
        stations[_stationId].isActive = true;
    }
    
    function deactivateStation(uint _stationId) public onlyStationOwner(_stationId) {
        stations[_stationId].isActive = false;
    }
    
    function setPricePerUnit(uint _stationId, uint _pricePerUnit) public onlyStationOwner(_stationId) {
        stations[_stationId].pricePerUnit = _pricePerUnit;
    }
    
}