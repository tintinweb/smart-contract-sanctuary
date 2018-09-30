pragma solidity ^0.4.24;


contract Records {
    struct Record {
        string manufacturerName;
        uint serialNumber;
        address walletAddress;
        string macAddress;
        string error;
        string value;
    }

    Record[] public records;
    mapping(uint => address) public tokenOwner;

    function getRecordsCount() public view returns(uint) {
        return records.length;
    }

    function createRecord(
        string _manufacturerName, 
        uint _serialNumber, 
        address _walletAddress, 
        string _macAddress, 
        string _error, 
        string _value) 
    public {
        uint id = records.length;
        records.push(Record(_manufacturerName, _serialNumber, _walletAddress, _macAddress, _error, _value));
        tokenOwner[id] = msg.sender;
    }
}