/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: Unlicense
// not bidirectional; for possible internal use only

pragma solidity^0.8.7;

interface ICorruptionsDataMapper {
    function setValue(uint256 mapIndex, uint256 key, uint256 value) external;
}

contract CorruptionsDataMapper {
    address public owner;
    
    struct DataMap {
        bool created;
        string name;
        mapping(uint256 => uint256) values;
    }
    
    mapping(uint256 => DataMap) public dataMaps;
    uint256 public mapCount;
    
    mapping (address => bool) public allowList;
    
    constructor() {
        owner = msg.sender;
    }
    
    function addToAllowList(address addr) public {
        require(msg.sender == owner, "CorruptionsDataMapper: not owner");
        allowList[addr] = true;
    }
    
    function removeFromAllowList(address addr) public {
        require(msg.sender == owner, "CorruptionsDataMapper: not owner");
        allowList[addr] = false;
    }
    
    function addMap(string memory name) public {
        require(msg.sender == owner, "CorruptionsDataMapper: not owner");
        DataMap storage map = dataMaps[mapCount];
        map.created = true;
        map.name = name;
        mapCount++;
    }
    
    function setValue(uint256 mapIndex, uint256 key, uint256 value) public {
        require(msg.sender == owner || allowList[msg.sender] == true, "CorruptionsDataMapper: not owner or allowed");
        DataMap storage map = dataMaps[mapIndex];
        map.values[key] = value;
    }
    
    function valueFor(uint256 mapIndex, uint256 key) public view returns (uint256) {
        DataMap storage map = dataMaps[mapIndex];
        return map.values[key];
    }
}