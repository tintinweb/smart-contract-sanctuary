/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// Ordering and updating incremental

// version4

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

// Contract

contract firmwareUpdate is owned{
    
    // Structure for Firmwares
    
    struct registerFirmwares {
        uint nodeID;
        uint firmwareVersion;
        string checkSum;
        uint batteryLevel;
        uint memorysize;
        uint registrationID;
        bool status;
    }
    
    // Structure for Nodes
    
    struct nodesStatus {
        uint nodeID;
        uint firmwareVersion;
        uint timestamp;
        uint nodeUpdateUniqueID;
        uint lastUpdateVersion;
        bool updateStatus;
    }
    

    // Variables and Tables
    uint public size;
    uint public sizeNodes;
    uint[] allNodeRegistrations;
    uint[] allUpdates;
    uint[] allUniqueRegistrationID;
    registerFirmwares[] private registerFirmwaresRecords;
    nodesStatus[] private nodesStatusRecords;

    // Register a Firmware Version to Node

    function registerNewFirmware(uint _nodeID, uint _firmwareVersion, string _checkSum, uint _batterylevel, uint _memorysize) public returns(uint) {
        require(msg.sender==owner);
        size = registerFirmwaresRecords.length++;
        registerFirmwaresRecords[registerFirmwaresRecords.length-1].nodeID = _nodeID;
        registerFirmwaresRecords[registerFirmwaresRecords.length-1].firmwareVersion = _firmwareVersion;
        registerFirmwaresRecords[registerFirmwaresRecords.length-1].checkSum = _checkSum;
        registerFirmwaresRecords[registerFirmwaresRecords.length-1].batteryLevel = _batterylevel;
        registerFirmwaresRecords[registerFirmwaresRecords.length-1].memorysize = _memorysize;
        // the registrationID is registration of each New Firmware
        registerFirmwaresRecords[registerFirmwaresRecords.length-1].registrationID = size+10000;
        registerFirmwaresRecords[registerFirmwaresRecords.length-1].status = false;
        allNodeRegistrations.push(registerFirmwaresRecords[registerFirmwaresRecords.length-1].nodeID);
        allUniqueRegistrationID.push(registerFirmwaresRecords[registerFirmwaresRecords.length-1].registrationID);
        return registerFirmwaresRecords.length;
    }
    
    // Update Node Status using nID

    function updateNodeStatus(uint _nID, uint _registerFirmware, bool _status) public returns(uint) {
        require(msg.sender==owner);
        sizeNodes = nodesStatusRecords.length++;
        uint index;
        for (uint i=0; i<=size; i++){
            if (registerFirmwaresRecords[i].nodeID == _nID){
                index=i;
            }
        }
        nodesStatusRecords[nodesStatusRecords.length-1].nodeID = registerFirmwaresRecords[index].nodeID;
        nodesStatusRecords[nodesStatusRecords.length-1].firmwareVersion = _registerFirmware;
        nodesStatusRecords[nodesStatusRecords.length-1].timestamp = now;
        // At each step the nodeUpdateUniqueID is the latest registration ID
        nodesStatusRecords[nodesStatusRecords.length-1].nodeUpdateUniqueID = registerFirmwaresRecords[index].registrationID;
        nodesStatusRecords[nodesStatusRecords.length-1].updateStatus = _status;
        registerFirmwaresRecords[index].status = _status;
        allUpdates.push(nodesStatusRecords[nodesStatusRecords.length-1].nodeUpdateUniqueID);
        return nodesStatusRecords.length;
    }
    
    // Read Functions
    
    // Get Firmware versions per Node using nodeID
    
    function readFirmwareVersion(uint nID) public constant returns(uint, uint, string, uint, uint, uint, bool) {
        uint index;
        for (uint i=0; i<=size; i++){
            if (registerFirmwaresRecords[i].nodeID == nID){
                index=i;
            }
        }
        return (registerFirmwaresRecords[index].nodeID, registerFirmwaresRecords[index].firmwareVersion, registerFirmwaresRecords[index].checkSum, registerFirmwaresRecords[index].batteryLevel, registerFirmwaresRecords[index].memorysize, registerFirmwaresRecords[index].registrationID, registerFirmwaresRecords[index].status);
    }
    
    // Get Firmware versions per Node using registrationID
    
    function readFirmwareVersionUsingRID(uint _rID) public constant returns(uint, uint, string, uint, uint, uint, bool) {
        uint index;
        for (uint i=0; i<=size; i++){
            if (registerFirmwaresRecords[i].registrationID == _rID){
                index=i;
            }
        }
        return (registerFirmwaresRecords[index].nodeID, registerFirmwaresRecords[index].firmwareVersion, registerFirmwaresRecords[index].checkSum, registerFirmwaresRecords[index].batteryLevel, registerFirmwaresRecords[index].memorysize, registerFirmwaresRecords[index].registrationID, registerFirmwaresRecords[index].status);
    }
    
    // Read Firmware versions using index
    
    function readFirmwareVersionUsingIndex(uint indexID) public constant returns(uint, uint, string, uint, uint, uint, bool) {
        uint index;
        index=indexID;
        return (registerFirmwaresRecords[index].nodeID, registerFirmwaresRecords[index].firmwareVersion, registerFirmwaresRecords[index].checkSum, registerFirmwaresRecords[index].batteryLevel, registerFirmwaresRecords[index].memorysize, registerFirmwaresRecords[index].registrationID, registerFirmwaresRecords[index].status);
    }
    
    // Get Node update versions per Node using node ID
    
    function readUpdateVersionUsingNodeID(uint nID) public constant returns(uint, uint, uint, uint, bool) {
        uint index;
        for (uint i=0; i<=sizeNodes; i++){
            if (nodesStatusRecords[i].nodeID == nID){
                index=i;
            }
        }
        return (nodesStatusRecords[index].nodeID, nodesStatusRecords[index].firmwareVersion, nodesStatusRecords[index].timestamp, nodesStatusRecords[index].nodeUpdateUniqueID, nodesStatusRecords[index].updateStatus);
    }
    
    // Get Node update versions per Node using Unique ID
    
    function readUpdateVersionUsingUID(uint _uID) public constant returns(uint, uint, uint, uint, bool) {
        uint index;
        for (uint i=0; i<=sizeNodes; i++){
            if (nodesStatusRecords[i].nodeUpdateUniqueID == _uID){
                index=i;
            }
        }
        return (nodesStatusRecords[index].nodeID, nodesStatusRecords[index].firmwareVersion, nodesStatusRecords[index].timestamp, nodesStatusRecords[index].nodeUpdateUniqueID, nodesStatusRecords[index].updateStatus);
    }
    
    // Gets the queue of Registrations for all Nodes
    
    function getAllNodeRegistrations() constant returns (uint[]) {
    return allNodeRegistrations;
    }
    
    // Gets the the unique registrationIDs for each Node
    
    function getUniqueRegistrationID() constant returns (uint[]) {
    return allUniqueRegistrationID;
    }
    
    // Gets all updates
    
    function getUpdates() constant returns (uint[]) {
    return allUpdates;
    }
    
    // Returns the latest update on the Node and the Latest Firmware 
    
    function getOrdering(uint nID) public constant returns(uint, uint) {
        uint indexLatestUpdate;
        indexLatestUpdate=0;
        uint indexLatestFirmware;
        // get index of LatestUpdate for Node
        for (uint i=0; i<=sizeNodes; i++){
            if (nodesStatusRecords[i].nodeID == nID){
                indexLatestUpdate=i;
            }
        }
        // get index of Latest Firmware for Node
        for (uint y=0; y<=size; y++){
            if (registerFirmwaresRecords[y].nodeID == nID){
                indexLatestFirmware=y;
            }
        }
        
        return (nodesStatusRecords[indexLatestUpdate].firmwareVersion, registerFirmwaresRecords[indexLatestFirmware].firmwareVersion);
    }
    
    
    
  
    
}