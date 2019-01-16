pragma solidity ^0.4.24;


contract BwData {
    address public owner;

    uint public constant WEIS_IN_ETHER = 1e18;
    uint public constant AREA_MULTIPLE = 1e2;

    struct UnitDetail {
        string unitProject;
        string unitNo;
        string unitType;
        uint unitArea;
        string unitDeed;
    }

    event AddedData(address customer, string unitProject, string unitNo, uint time);

    mapping (address => UnitDetail) public customers;

    uint public customerCount;

    constructor() public {
        owner = msg.sender;
    }

    function newContract(string unitProject, string unitNo, string unitType, uint unitArea, string unitDeed)
    public returns (bool) {
        //require(msg.sender != owner); //must not owner
        bytes memory tempEmptyString = bytes(customers[msg.sender].unitNo);
        require(tempEmptyString.length == 0);

        customers[msg.sender].unitProject = unitProject;
        customers[msg.sender].unitNo = unitNo;
        customers[msg.sender].unitType = unitType;
        customers[msg.sender].unitArea = unitArea;
        customers[msg.sender].unitDeed = unitDeed;
        customerCount++;

        emit AddedData(msg.sender, unitProject, unitNo, now);
        return true;
    }

    function viewContract() public view returns (string, string, string, uint, string) {
        bytes memory tempEmptyString = bytes(customers[msg.sender].unitNo);
        require(tempEmptyString.length > 0);

        return (customers[msg.sender].unitProject, customers[msg.sender].unitNo, customers[msg.sender].unitType
        , customers[msg.sender].unitArea, customers[msg.sender].unitDeed);
    }
}