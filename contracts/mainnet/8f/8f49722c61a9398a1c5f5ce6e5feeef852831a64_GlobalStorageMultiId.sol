pragma solidity ^0.4.15;

// Global Storage Multi id
// Author: Juan Livingston @ Ethernity.live

contract GlobalStorageMultiId {
    
    uint256 public totalUsers;
    uint256 public regPrice;
    uint256 public totalCollected;
    address public admin;

    // mapping(address => bytes32) ids;
    mapping(bytes32 => address) users;
    mapping(bytes32 => mapping(bytes32 => uint256)) dataUint;
    mapping(bytes32 => mapping(bytes32 => bytes32)) dataBytes32;
    mapping(bytes32 => mapping(bytes32 => string)) dataString;
    mapping(bytes32 => mapping(bytes32 => address)) dataAddress; 

    event Error(string _string);
    event RegisteredUser(address _address , bytes32 _id);
    event ChangedAdd(bytes32 _id , address _old , address _new);


    modifier onlyOwner(bytes32 _id) {
        require(msg.sender == users[_id]);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }


    function GlobalStorageMultiId() {
        regPrice = 0.005 ether; // Promotional price - will change in the future
        admin = msg.sender;
    }


    // User&#39;s admin functions

    function registerUser(bytes32 _id) payable returns(bool) {

        require(msg.value >= regPrice);

        if ( users[_id] != 0x0 ) {
            Error("ID already exists");
            msg.sender.send(msg.value);
            return false;
        }

        users[_id] = msg.sender;
        // ids[msg.sender] = _id;
        totalUsers += 1;
        totalCollected += msg.value;
        admin.send(msg.value);
        RegisteredUser(msg.sender , _id);
        return true;
    }
    

    function changeAddress(bytes32 _id , address _newAddress) onlyOwner(_id) returns(bool) {
        users[_id] = _newAddress;
        ChangedAdd(_id , msg.sender , _newAddress);
        return true;
    }
    
    function checkId(bytes32 _id) constant returns(address _address) {
        return users[_id];
    }


    // Users&#39;s data storage

    // Uint

    function setUint(bytes32 _id , bytes32 _key , uint256 _data , bool _overwrite) onlyOwner(_id) returns(bool) {
        if (dataUint[_id][_key] == 0 ||  _overwrite) {
            dataUint[_id][_key] = _data;
            return true;
        } else {
            Error("Data exists");
            return false;
        }
    }

    function getUint(bytes32 _id , bytes32 _key) constant returns(uint _data) {
        return dataUint[_id][_key];
    }


    // String

    function setString(bytes32 _id , bytes32 _key , string _data , bool _overwrite) onlyOwner(_id) returns(bool) {
        if (bytes(dataString[_id][_key]).length == 0  ||  _overwrite) {
            dataString[_id][_key] = _data;
            return true;
        } else {
            Error("Data exists");
            return false;
        }
    }

    function getString(bytes32 _id , bytes32 _key) constant returns(string _data) {
        return dataString[_id][_key];
    }

    // Address

    function setAddress(bytes32 _id , bytes32 _key , address _data , bool _overwrite) onlyOwner(_id) returns(bool) {
        if (dataAddress[_id][_key] == 0x0  ||  _overwrite) {
            dataAddress[_id][_key] = _data;
            return true;
        } else {
            Error("Data exists");
            return false;
        }
    }

    function getAddress(bytes32 _id , bytes32 _key) constant returns(address _data) {
        return dataAddress[_id][_key];
    }

    // Bytes32
    
    function setBytes32(bytes32 _id , bytes32 _key , bytes32 _data , bool _overwrite) onlyOwner(_id) returns(bool) {
        if (dataBytes32[_id][_key] == 0x0  ||  _overwrite) {
            dataBytes32[_id][_key] = _data;
            return true;
        } else {
            Error("Data exists");
            return false;
        }
    }

    function getBytes32(bytes32 _id , bytes32 _key) constant returns(bytes32 _data) {
        return dataBytes32[_id][_key];
    }


    // Admin functions

    function changePrice(uint _newPrice) onlyAdmin {
        regPrice = _newPrice;
    }

    function changeAdmin(address _newAdmin) onlyAdmin {
        admin = _newAdmin;
    }

}