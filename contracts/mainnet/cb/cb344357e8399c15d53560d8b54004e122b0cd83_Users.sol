pragma solidity 0.4.24;

// File: contracts/Users.sol

contract Users {
    struct Entry {
        uint keyIndex;
        string value;
    }

    struct AddressStringMap {
        mapping(address => Entry) data;
        address[] keys;
    }

    AddressStringMap internal usernames;

    function putUsername(string _username)
        public
        returns (bool)
    {
        address senderAddress = msg.sender;
        Entry storage entry = usernames.data[senderAddress];
        entry.value = _username;
        if (entry.keyIndex > 0) {
            return true;
        } else {
            entry.keyIndex = ++usernames.keys.length;
            usernames.keys[entry.keyIndex - 1] = senderAddress;
            return false;
        }
    }

    function removeUsername()
        public
        returns (bool)
    {
        address senderAddress = msg.sender;
        Entry storage entry = usernames.data[senderAddress];
        if (entry.keyIndex == 0) {
            return false;
        }

        if (entry.keyIndex <= usernames.keys.length) {
            // Move an existing element into the vacated key slot.
            usernames.data[usernames.keys[usernames.keys.length - 1]].keyIndex = entry.keyIndex;
            usernames.keys[entry.keyIndex - 1] = usernames.keys[usernames.keys.length - 1];
            usernames.keys.length -= 1;
            delete usernames.data[senderAddress];
            return true;
        }
    }

    function size()
        public
        view
        returns (uint)
    {
        return usernames.keys.length;
    }

    function getUsernameByAddress(address _address)
        public
        constant
        returns (string)
    {
        return usernames.data[_address].value;
    }

    function getAddressByIndex(uint idx)
        public
        constant
        returns (address)
    {
        return usernames.keys[idx];
    }

    function getUsernameByIndex(uint idx)
        public
        constant
        returns (string)
    {
        return usernames.data[usernames.keys[idx]].value;
    }
}