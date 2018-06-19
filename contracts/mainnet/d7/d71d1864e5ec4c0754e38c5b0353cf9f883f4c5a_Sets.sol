pragma solidity ^0.4.13;

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