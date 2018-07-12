pragma solidity ^0.4.21;

contract Caseus {

    event NewItem(uint256 itemId, string productType);
    event NewLocationRecord(uint256 timestamp, string pickup, string destination);

    struct LocationRecord {
        uint256 timestamp;
        string pickup;
        string destination;
    }

    struct Item {
        bool initialized;
        string productType;
        uint256 itemId;
        uint256 locationRecordsLength;
        mapping (uint256 => LocationRecord) locationRecords;
    }

    mapping (address => bool) public whitelist;

    mapping(uint256  => Item) public items;

    constructor() public {
        whitelist[msg.sender] = true;
    }

    function addItem(uint256 itemId, string productType) public returns(bool) {
        require(whitelist[msg.sender] == true);
        require(items[itemId].initialized != true);

        items[itemId] = Item(true, productType, itemId, 0);
        emit NewItem(itemId, productType);
        return true;
    }

    function addLocationRecord(uint256 itemId, uint256 timestamp, string pickup, string destination)
    public returns(bool) {
        require(whitelist[msg.sender] == true);
        require(items[itemId].initialized == true);

        Item storage item = items[itemId];
        uint256 currentIndex = item.locationRecordsLength;
        item.locationRecords[currentIndex + 1] = LocationRecord(timestamp, pickup, destination);
        item.locationRecordsLength = item.locationRecordsLength + 1;

        emit NewLocationRecord(timestamp, pickup, destination);
        return true;
    }
}