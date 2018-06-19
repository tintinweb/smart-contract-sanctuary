pragma solidity ^0.4.13;

contract Prover {
    // attach library
    using Sets for *;


    // storage vars
    address owner;
    Sets.addressSet internal users;
    mapping (address => UserAccount) internal ledger;
    
    
    // structs
    struct UserAccount {
        Sets.bytes32Set hashes;
        mapping (bytes32 => Entry) entries;
    }

    struct Entry {
        uint256 time;
        uint256 value;
    }


    // constructor
    function Prover() {
        owner = msg.sender;
    }
    
    
    // fallback: unmatched transactions will be returned
    function () {
        revert();
    }


    // modifier to check if sender has an account
    modifier hasAccount() {
        assert(ledger[msg.sender].hashes.length() >= 1);
        _;
    }


    // external functions
    // proving
    function proveIt(address target, bytes32 dataHash) external constant
        returns (bool proved, uint256 time, uint256 value)
    {
        return status(target, dataHash);
    }

    function proveIt(address target, string dataString) external constant
        returns (bool proved, uint256 time, uint256 value)
    {
        return status(target, sha3(dataString));
    }
    
    // allow access to our structs via functions with convenient return values
    function usersGetter() public constant
        returns (uint256 number_unique_addresses, address[] unique_addresses)
    {
        return (users.length(), users.members);
    }

    function userEntries(address target) external constant returns (bytes32[]) {
        return ledger[target].hashes.members;
    }
    
    
    // public functions
    // adding entries
    function addEntry(bytes32 dataHash) payable {
        _addEntry(dataHash);
    }

    function addEntry(string dataString) payable {
        _addEntry(sha3(dataString));
    }

    // deleting entries
    function deleteEntry(bytes32 dataHash) hasAccount {
        _deleteEntry(dataHash);
    }

    function deleteEntry(string dataString) hasAccount {
        _deleteEntry(sha3(dataString));
    }
    
    // allow owner to delete contract if no accounts exist
    function selfDestruct() {
        if ((msg.sender == owner) && (users.length() == 0)) {
            selfdestruct(owner);
        }
    }


    // internal functions
    function _addEntry(bytes32 dataHash) internal {
        // ensure the entry doesn&#39;t exist
        assert(!ledger[msg.sender].hashes.contains(dataHash));
        // update UserAccount (hashes then entries)
        ledger[msg.sender].hashes.insert(dataHash);
        ledger[msg.sender].entries[dataHash] = Entry(now, msg.value);
        // add sender to userlist
        users.insert(msg.sender);
    }

    function _deleteEntry(bytes32 dataHash) internal {
        // ensure the entry does exist
        assert(ledger[msg.sender].hashes.contains(dataHash));
        uint256 rebate = ledger[msg.sender].entries[dataHash].value;
        // update UserAccount (hashes then entries)
        ledger[msg.sender].hashes.remove(dataHash);
        delete ledger[msg.sender].entries[dataHash];
        // send the rebate
        if (rebate > 0) {
            msg.sender.transfer(rebate);
        }
        // delete from userlist if this was the user&#39;s last entry
        if (ledger[msg.sender].hashes.length() == 0) {
            users.remove(msg.sender);
        }
    }

    // return status of arbitrary address and dataHash
    function status(address target, bytes32 dataHash) internal constant
        returns (bool proved, uint256 time, uint256 value)
    {
        return (ledger[msg.sender].hashes.contains(dataHash),
                ledger[target].entries[dataHash].time,
                ledger[target].entries[dataHash].value);
    }
}

// note: breaks if members.length exceeds 2^256-1 (so, not really a problem)
library Sets {
    // address set
    struct addressSet {
        address[] members;
        mapping (address => bool) memberExists;
        mapping (address => uint) memberIndex;
    }

    function insert(addressSet storage self, address other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(addressSet storage self, address other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
            // change index of last value to index of other 
            self.memberIndex[self.members[self.members.length - 1]] = index;
            // copy last value over other and decrement length
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(addressSet storage self, address other) returns (bool) {
        return self.memberExists[other];
    }

    function length(addressSet storage self) returns (uint256) {
        return self.members.length;
    }


    // uint set
    struct uintSet {
        uint[] members;
        mapping (uint => bool) memberExists;
        mapping (uint => uint) memberIndex;
    }

    function insert(uintSet storage self, uint other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(uintSet storage self, uint other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
            // change index of last value to index of other 
            self.memberIndex[self.members[self.members.length - 1]] = index;
            // copy last value over other and decrement length
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(uintSet storage self, uint other) returns (bool) {
        return self.memberExists[other];
    }

    function length(uintSet storage self) returns (uint256) {
        return self.members.length;
    }


    // uint8 set
    struct uint8Set {
        uint8[] members;
        mapping (uint8 => bool) memberExists;
        mapping (uint8 => uint) memberIndex;
    }

    function insert(uint8Set storage self, uint8 other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(uint8Set storage self, uint8 other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
            // change index of last value to index of other 
            self.memberIndex[self.members[self.members.length - 1]] = index;
            // copy last value over other and decrement length
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(uint8Set storage self, uint8 other) returns (bool) {
        return self.memberExists[other];
    }

    function length(uint8Set storage self) returns (uint256) {
        return self.members.length;
    }


    // int set
    struct intSet {
        int[] members;
        mapping (int => bool) memberExists;
        mapping (int => uint) memberIndex;
    }

    function insert(intSet storage self, int other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(intSet storage self, int other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
            // change index of last value to index of other 
            self.memberIndex[self.members[self.members.length - 1]] = index;
            // copy last value over other and decrement length
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(intSet storage self, int other) returns (bool) {
        return self.memberExists[other];
    }

    function length(intSet storage self) returns (uint256) {
        return self.members.length;
    }


    // int8 set
    struct int8Set {
        int8[] members;
        mapping (int8 => bool) memberExists;
        mapping (int8 => uint) memberIndex;
    }

    function insert(int8Set storage self, int8 other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(int8Set storage self, int8 other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
            // change index of last value to index of other 
            self.memberIndex[self.members[self.members.length - 1]] = index;
            // copy last value over other and decrement length
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(int8Set storage self, int8 other) returns (bool) {
        return self.memberExists[other];
    }

    function length(int8Set storage self) returns (uint256) {
        return self.members.length;
    }


    // byte set
    struct byteSet {
        byte[] members;
        mapping (byte => bool) memberExists;
        mapping (byte => uint) memberIndex;
    }

    function insert(byteSet storage self, byte other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(byteSet storage self, byte other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
            // change index of last value to index of other 
            self.memberIndex[self.members[self.members.length - 1]] = index;
            // copy last value over other and decrement length
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(byteSet storage self, byte other) returns (bool) {
        return self.memberExists[other];
    }

    function length(byteSet storage self) returns (uint256) {
        return self.members.length;
    }


    // bytes32 set
    struct bytes32Set {
        bytes32[] members;
        mapping (bytes32 => bool) memberExists;
        mapping (bytes32 => uint) memberIndex;
    }

    function insert(bytes32Set storage self, bytes32 other) {
        if (!self.memberExists[other]) {
            self.memberExists[other] = true;
            self.memberIndex[other] = self.members.length;
            self.members.push(other);
        }
    }

    function remove(bytes32Set storage self, bytes32 other) {
        if (self.memberExists[other])  {
            self.memberExists[other] = false;
            uint index = self.memberIndex[other];
            // change index of last value to index of other 
            self.memberIndex[self.members[self.members.length - 1]] = index;
            // copy last value over other and decrement length
            self.members[index] = self.members[self.members.length - 1];
            self.members.length--;
        }
    }

    function contains(bytes32Set storage self, bytes32 other) returns (bool) {
        return self.memberExists[other];
    }

    function length(bytes32Set storage self) returns (uint256) {
        return self.members.length;
    }
}