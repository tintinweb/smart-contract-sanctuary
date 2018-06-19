pragma solidity ^0.4.13;

contract Prover {
    // attach library
    using Sets for Sets.addressSet;
    using Sets for Sets.bytes32Set;

    // storage vars
    address owner;
    Sets.addressSet users;
    mapping(address => Account) internal accounts;

    // structs
    struct Account {
        Sets.bytes32Set entries;
        mapping(bytes32 => Entry) values;
    }

    struct Entry {
        uint time;
        uint staked;
    }


    // constructor
    function Prover() {
        owner = msg.sender;
    }
    
    
    // fallback: unmatched transactions will be returned
    function() {
        revert();
    }


    // modifier to check if a target address has a particular entry
    modifier entryExists(address target, bytes32 dataHash, bool exists) {
        assert(accounts[target].entries.contains(dataHash) == exists);
        _;
    }


    // external functions
    // allow access to our structs via functions with convenient return values
    function registeredUsers() external constant
        returns (uint number_unique_addresses, address[] unique_addresses)
    {
        return (users.length(), users.members);
    }

    function userEntries(address target) external constant returns (bytes32[]) {
        return accounts[target].entries.members;
    }
    // proving
    function proveIt(address target, bytes32 dataHash) external constant
        returns (bool proved, uint time, uint staked)
    {
        return status(target, dataHash);
    }

    function proveIt(address target, string dataString) external constant
        returns (bool proved, uint time, uint staked)
    {
        return status(target, sha3(dataString));
    }

    
    // public functions
    // adding entries
    function addEntry(bytes32 dataHash) payable {
        _addEntry(dataHash);
    }

    function addEntry(string dataString) payable
    {
        _addEntry(sha3(dataString));
    }

    // deleting entries
    function deleteEntry(bytes32 dataHash) {
        _deleteEntry(dataHash);
    }

    function deleteEntry(string dataString) {
        _deleteEntry(sha3(dataString));
    }
    
    // allow owner to delete contract if no accounts exist
    function selfDestruct() {
        if ((msg.sender == owner) && (users.length() == 0)) {
            selfdestruct(owner);
        }
    }


    // internal functions
    function _addEntry(bytes32 dataHash)
        entryExists(msg.sender, dataHash, false)
        internal
    {
        users.insert(msg.sender);
        accounts[msg.sender].entries.insert(dataHash);
        accounts[msg.sender].values[dataHash] = Entry(now, msg.value);
    }

    function _deleteEntry(bytes32 dataHash)
        entryExists(msg.sender, dataHash, true)
        internal
    {
        uint rebate = accounts[msg.sender].values[dataHash].staked;
        // update user account
        delete accounts[msg.sender].values[dataHash];
        accounts[msg.sender].entries.remove(dataHash);
        // delete from users if this was the user&#39;s last entry
        if (accounts[msg.sender].entries.length() == 0) {
            users.remove(msg.sender);
        }
        // send the rebate
        if (rebate > 0) msg.sender.transfer(rebate);
    }

    // return status of arbitrary address and dataHash
    function status(address target, bytes32 dataHash) internal constant
        returns (bool proved, uint time, uint staked)
    {
        return (accounts[target].entries.contains(dataHash),
                accounts[target].values[dataHash].time,
                accounts[target].values[dataHash].staked);
    }
}

pragma solidity ^0.4.13;

// sets support up to 2^256-2 members
// memberIndices stores the index of members + 1, not their actual index
library Sets {
    // address set
    struct addressSet {
        address[] members;
        mapping(address => uint) memberIndices;
    }

    function insert(addressSet storage self, address other) {
        if (!contains(self, other)) {
            self.members.push(other);
            self.memberIndices[other] = length(self);
        }
    }

    function remove(addressSet storage self, address other) {
        if (contains(self, other)) {
            uint replaceIndex = self.memberIndices[other];
            address lastMember = self.members[length(self)-1];
            // overwrite other with the last member and remove last member
            self.members[replaceIndex-1] = lastMember;
            self.members.length--;
            // reflect this change in the indices
            self.memberIndices[lastMember] = replaceIndex;
            delete self.memberIndices[other];
        }
    }

    function contains(addressSet storage self, address other)
        constant
        returns (bool)
    {
        return self.memberIndices[other] > 0;
    }

    function length(addressSet storage self) constant returns (uint) {
        return self.members.length;
    }


    // uint set
    struct uintSet {
        uint[] members;
        mapping(uint => uint) memberIndices;
    }

    function insert(uintSet storage self, uint other) {
        if (!contains(self, other)) {
            self.members.push(other);
            self.memberIndices[other] = length(self);
        }
    }

    function remove(uintSet storage self, uint other) {
        if (contains(self, other)) {
            uint replaceIndex = self.memberIndices[other];
            uint lastMember = self.members[length(self)-1];
            // overwrite other with the last member and remove last member
            self.members[replaceIndex-1] = lastMember;
            self.members.length--;
            // reflect this change in the indices
            self.memberIndices[lastMember] = replaceIndex;
            delete self.memberIndices[other];
        }
    }

    function contains(uintSet storage self, uint other)
        constant
        returns (bool)
    {
        return self.memberIndices[other] > 0;
    }

    function length(uintSet storage self) constant returns (uint) {
        return self.members.length;
    }


    // uint8 set
    struct uint8Set {
        uint8[] members;
        mapping(uint8 => uint) memberIndices;
    }

    function insert(uint8Set storage self, uint8 other) {
        if (!contains(self, other)) {
            self.members.push(other);
            self.memberIndices[other] = length(self);
        }
    }

    function remove(uint8Set storage self, uint8 other) {
        if (contains(self, other)) {
            uint replaceIndex = self.memberIndices[other];
            uint8 lastMember = self.members[length(self)-1];
            // overwrite other with the last member and remove last member
            self.members[replaceIndex-1] = lastMember;
            self.members.length--;
            // reflect this change in the indices
            self.memberIndices[lastMember] = replaceIndex;
            delete self.memberIndices[other];
        }
    }

    function contains(uint8Set storage self, uint8 other)
        constant
        returns (bool)
    {
        return self.memberIndices[other] > 0;
    }

    function length(uint8Set storage self) constant returns (uint) {
        return self.members.length;
    }


    // int set
    struct intSet {
        int[] members;
        mapping(int => uint) memberIndices;
    }

    function insert(intSet storage self, int other) {
        if (!contains(self, other)) {
            self.members.push(other);
            self.memberIndices[other] = length(self);
        }
    }

    function remove(intSet storage self, int other) {
        if (contains(self, other)) {
            uint replaceIndex = self.memberIndices[other];
            int lastMember = self.members[length(self)-1];
            // overwrite other with the last member and remove last member
            self.members[replaceIndex-1] = lastMember;
            self.members.length--;
            // reflect this change in the indices
            self.memberIndices[lastMember] = replaceIndex;
            delete self.memberIndices[other];
        }
    }

    function contains(intSet storage self, int other)
        constant
        returns (bool)
    {
        return self.memberIndices[other] > 0;
    }

    function length(intSet storage self) constant returns (uint) {
        return self.members.length;
    }


    // int8 set
    struct int8Set {
        int8[] members;
        mapping(int8 => uint) memberIndices;
    }

    function insert(int8Set storage self, int8 other) {
        if (!contains(self, other)) {
            self.members.push(other);
            self.memberIndices[other] = length(self);
        }
    }

    function remove(int8Set storage self, int8 other) {
        if (contains(self, other)) {
            uint replaceIndex = self.memberIndices[other];
            int8 lastMember = self.members[length(self)-1];
            // overwrite other with the last member and remove last member
            self.members[replaceIndex-1] = lastMember;
            self.members.length--;
            // reflect this change in the indices
            self.memberIndices[lastMember] = replaceIndex;
            delete self.memberIndices[other];
        }
    }

    function contains(int8Set storage self, int8 other)
        constant
        returns (bool)
    {
        return self.memberIndices[other] > 0;
    }

    function length(int8Set storage self) constant returns (uint) {
        return self.members.length;
    }


    // byte set
    struct byteSet {
        byte[] members;
        mapping(byte => uint) memberIndices;
    }

    function insert(byteSet storage self, byte other) {
        if (!contains(self, other)) {
            self.members.push(other);
            self.memberIndices[other] = length(self);
        }
    }

    function remove(byteSet storage self, byte other) {
        if (contains(self, other)) {
            uint replaceIndex = self.memberIndices[other];
            byte lastMember = self.members[length(self)-1];
            // overwrite other with the last member and remove last member
            self.members[replaceIndex-1] = lastMember;
            self.members.length--;
            // reflect this change in the indices
            self.memberIndices[lastMember] = replaceIndex;
            delete self.memberIndices[other];
        }
    }

    function contains(byteSet storage self, byte other)
        constant
        returns (bool)
    {
        return self.memberIndices[other] > 0;
    }

    function length(byteSet storage self) constant returns (uint) {
        return self.members.length;
    }


    // bytes32 set
    struct bytes32Set {
        bytes32[] members;
        mapping(bytes32 => uint) memberIndices;
    }

    function insert(bytes32Set storage self, bytes32 other) {
        if (!contains(self, other)) {
            self.members.push(other);
            self.memberIndices[other] = length(self);
        }
    }

    function remove(bytes32Set storage self, bytes32 other) {
        if (contains(self, other)) {
            uint replaceIndex = self.memberIndices[other];
            bytes32 lastMember = self.members[length(self)-1];
            // overwrite other with the last member and remove last member
            self.members[replaceIndex-1] = lastMember;
            self.members.length--;
            // reflect this change in the indices
            self.memberIndices[lastMember] = replaceIndex;
            delete self.memberIndices[other];
        }
    }

    function contains(bytes32Set storage self, bytes32 other)
        constant
        returns (bool)
    {
        return self.memberIndices[other] > 0;
    }

    function length(bytes32Set storage self) constant returns (uint) {
        return self.members.length;
    }
}