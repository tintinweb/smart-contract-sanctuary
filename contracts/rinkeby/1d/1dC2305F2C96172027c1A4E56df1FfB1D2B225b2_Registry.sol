// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Registry {

    //This stores the address of who added the registry and the timw it was added
    struct Entry {
        address owner;
        uint256 timestamp;
    }

    //This emits an event whenever a new registry is added
    event LogEntry(string cid, address indexed owner, uint256 timestamp);

    //This stores the registry information in a map
    mapping(string => Entry) entries;

    //This stores all the registry CIDs
    string[] cids;

    //A write-only function that allows anyone to add a registry
    function register(string memory _cid) public {
        address _owner = msg.sender;
        Entry memory entry;
        entry.owner = _owner;
        entry.timestamp = block.timestamp;
        entries[_cid] = entry;
        cids.push(_cid);
        emit LogEntry(_cid, _owner, entry.timestamp);
    }

    //A read-only function that allows anyone to check the address that stored a CID
    function getOwner(string memory _cid) public view returns (address) {
        return entries[_cid].owner;
    }

    //A read-only function that allows anyone to check all the uploaded CIDs
    function getCids() public view returns (string[] memory) {
        return cids;
    }

    //A read-only function that allows anyone to check the timestamp of a specific CID
    function getTimestamp(string memory _cid) public view returns (uint256) {
        return entries[_cid].timestamp;
    }

    //A read-only function that allows anyone to check the information of a specific CID
    function getCidInfo(string memory _cid) public view returns (address, uint256) {
        return (entries[_cid].owner, entries[_cid].timestamp);
    }

    //A read-only function that allows anyone to check if a specific CID has been stored
    function confirmRegistry(string memory _cid) public view returns (string memory) {
        if (entries[_cid].owner == 0x0000000000000000000000000000000000000000) {
            return "Not registered";
        } else {
            return "Registered";
        }
    }

}