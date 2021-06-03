/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// Beeeef Registry
//
// https://github.com/bokkypoobah/BeeeefRegistry
//
// Deployed to 0xbEEeEfffE871CE4b6aEAc8717194913f2bc27577
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2021. The MIT Licence.
// ----------------------------------------------------------------------------


contract Curated {
    address public curator;

    event CuratorTransferred(address indexed from, address indexed to);

    modifier onlyCurator {
        require(msg.sender == curator);
        _;
    }

    constructor() {
        curator = msg.sender;
    }
    function transferCurator(address _curator) public onlyCurator {
        emit CuratorTransferred(curator, _curator);
        curator = _curator;
    }
}


enum Permission { None, View, ComposeWith, Permission3, Permission4, Permission5, Permission6, Permission7 }
enum Curation { None, LoadByDefault, DisableView, DisableComposeWith, Curation4, Curation5, Curation6, Curation7 }


library Entries {
    struct Entry {
        uint index;
        uint64 timestamp;
        address account;
        address token;
        Permission permission;
        Curation curation;
    }
    struct Data {
        bool initialised;
        mapping(bytes32 => Entry) entries;
        bytes32[] index;
    }

    event EntryAdded(bytes32 key, address account, address token, Permission permission);
    event EntryRemoved(bytes32 key, address account, address token);
    event EntryUpdated(bytes32 key, address account, address token, Permission permission);
    event EntryCurated(bytes32 key, address account, address token, Curation curation);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function generateKey(address account, address token) internal view returns (bytes32 hash) {
        return keccak256(abi.encodePacked(address(this), account, token));
    }
    function hasKey(Data storage self, bytes32 key) internal view returns (bool) {
        return self.entries[key].timestamp > 0;
    }
    function add(Data storage self, address account, address token, Permission permission) internal {
        bytes32 key = generateKey(account, token);
        require(self.entries[key].timestamp == 0);
        self.index.push(key);
        self.entries[key] = Entry(self.index.length - 1, uint64(block.timestamp), account, token, permission, Curation(0));
        emit EntryAdded(key, account, token, permission);
    }
    function remove(Data storage self, address account, address token) internal {
        bytes32 key = generateKey(account, token);
        require(self.entries[key].timestamp > 0);
        uint removeIndex = self.entries[key].index;
        emit EntryRemoved(key, account, token);
        uint lastIndex = self.index.length - 1;
        bytes32 lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.entries[lastIndexKey].index = removeIndex;
        delete self.entries[key];
        if (self.index.length > 0) {
            self.index.pop();
        }
    }
    function update(Data storage self, address account, address token, Permission permission) internal {
        bytes32 key = generateKey(account, token);
        Entry storage entry = self.entries[key];
        require(entry.timestamp > 0);
        entry.timestamp = uint64(block.timestamp);
        entry.permission = permission;
        emit EntryUpdated(key, account, token, permission);
    }
    function curate(Data storage self, address account, address token, Curation curation) internal {
        bytes32 key = generateKey(account, token);
        Entry storage entry = self.entries[key];
        require(entry.timestamp > 0);
        entry.curation = curation;
        emit EntryCurated(key, account, token, curation);
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}


contract BeeeefRegistry is Curated {
    using Entries for Entries.Data;
    using Entries for Entries.Entry;

    Entries.Data private entries;

    event EntryAdded(bytes32 key, address account, address token, uint permission);
    event EntryRemoved(bytes32 key, address account, address token);
    event EntryUpdated(bytes32 key, address account, address token, uint permission);
    event EntryCurated(bytes32 key, address account, address token, Curation curation);

    constructor() {
        entries.init();
    }

    function addEntry(address token, Permission permission) public {
        entries.add(msg.sender, token, permission);
    }
    function removeEntry(address token) public {
        entries.remove(msg.sender, token);
    }
    function updateEntry(address token, Permission permission) public {
        entries.update(msg.sender, token, permission);
    }
    function curateEntry(address account, address token, Curation curation) public onlyCurator {
        entries.curate(account, token, curation);
    }

    function entriesLength() public view returns (uint) {
        return entries.length();
    }
    function getEntryByIndex(uint i) public view returns (address _account, address _token, Permission _permission) {
        require(i < entries.length(), "getEntryByIndex: Invalid index");
        Entries.Entry memory entry = entries.entries[entries.index[i]];
        return (entry.account, entry.token, entry.permission);
    }
    function getEntries() public view returns (address[] memory accounts, address[] memory tokens, Permission[] memory permissions, Curation[] memory curations) {
        uint length = entries.length();
        accounts = new address[](length);
        tokens = new address[](length);
        permissions = new Permission[](length);
        curations = new Curation[](length);
        for (uint i = 0; i < length; i++) {
            Entries.Entry memory entry = entries.entries[entries.index[i]];
            accounts[i] = entry.account;
            tokens[i] = entry.token;
            permissions[i] = entry.permission;
            curations[i] = entry.curation;
        }
    }
}