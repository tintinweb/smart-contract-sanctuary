// SPDX-License-Identifier: Unlicense

pragma solidity^0.8.0;

contract CorruptionsBidirectionalDataMapper {
    address constant public chosenAddress = 0x4fFFFF3eD1E82057dffEe66b4aa4057466E24a38;
    address public owner;
    
    struct DataMap {
        bool created;
        bool locked;
        string name;
        mapping(uint256 => uint256) values;
    }
    
    mapping(uint256 => DataMap) public dataMaps;
    uint256 public mapCount;
    
    constructor() {
        owner = msg.sender;
    }
    
    function addMap(string memory name) public {
        require(msg.sender == owner, "CorruptionsBidirectionalDataMapper: not owner");
        DataMap storage map = dataMaps[mapCount];
        map.created = true;
        map.name = name;
        mapCount++;
    }

    function setValue(uint256 mapIndex, uint256 key, uint256 value) public {
        require(msg.sender == owner || msg.sender == chosenAddress, "CorruptionsBidirectionalDataMapper: not owner or allowed");
        DataMap storage map = dataMaps[mapIndex];
        require(map.locked == false, "CorruptionsBidirectionalDataMapper: map is locked");
        map.values[key] = value;
    }
    
    function valueFor(uint256 mapIndex, uint256 key) public view returns (uint256) {
        DataMap storage map = dataMaps[mapIndex];
        return map.values[key];
    }
    
    // owner or chosen address can "commit" a map's value once it's finalized
    // this makes the values immutable
    function commitMap(uint256 mapIndex) public {
        require(msg.sender == owner || msg.sender == chosenAddress, "CorruptionsBidirectionalDataMapper: not owner");
        DataMap storage map = dataMaps[mapIndex];
        map.locked = true;
    }
}