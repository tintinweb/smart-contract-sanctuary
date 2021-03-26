/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Leaderboard {
    
    mapping(address => mapping (bytes32 => Repartition)) public registery;
    
    struct Repartition {
        uint256 unallocated;
        mapping (bytes32 => uint256) allocated;
    }
    
    event newAllocation(
        address _at,
        bytes32 _leaderHash,
        bytes32 _fromEntryHash,
        bytes32 _toEntryHash,
        uint256 _value
    );
    
    event newLeaderboard(address _from, bytes32 leaderHash, uint256 intialValue);
    event deletedLeaderboard(address _from, bytes32 leaderHash);
    
    // Creation
    
    function createLeaderboard(bytes32 _leaderHash, uint256 _intialValue) public {
        registery[msg.sender][_leaderHash].unallocated = _intialValue;
        emit newLeaderboard(msg.sender, _leaderHash, _intialValue);
    }
    
    // Allocation
    
    function allocateEntryFromUnallocated(
        bytes32 _leaderHash,
        bytes32 _toEntryHash,
        uint256 _value
    ) public {
        // Checking repartion
        require(_value <= registery[msg.sender][_leaderHash].unallocated, "not enought");
        // Changing repartition
        registery[msg.sender][_leaderHash].unallocated -= _value;
        registery[msg.sender][_leaderHash].allocated[_toEntryHash] += _value;
        emit newAllocation(msg.sender, _leaderHash, "", _toEntryHash, _value);
    }
    
    function allocateEntryFromEntry(
        bytes32 _leaderHash,
        bytes32 _fromEntryHash,
        bytes32 _toEntryHash,
        uint256 _value
    ) public {
        // Checking repartion
        require(_value <= registery[msg.sender][_leaderHash].allocated[_fromEntryHash], "not enought");
        // Changing repartition
        registery[msg.sender][_leaderHash].allocated[_fromEntryHash] -= _value;
        registery[msg.sender][_leaderHash].allocated[_toEntryHash] += _value;
        emit newAllocation(msg.sender, _leaderHash, _fromEntryHash, _toEntryHash, _value);
    }
    
    function deallocateEntry(
        bytes32 _leaderHash,
        bytes32 _fromEntryHash,
        uint256 _value
    ) public {
        // Checking repartion
        require(_value <= registery[msg.sender][_leaderHash].allocated[_fromEntryHash], "not enought");
        // Changing repartition
        registery[msg.sender][_leaderHash].allocated[_fromEntryHash] -= _value;
        registery[msg.sender][_leaderHash].unallocated += _value;
        emit newAllocation(msg.sender, _leaderHash, _fromEntryHash, "", _value);
    }
    
    // Getters
    
    function getUnallocation(address _from, bytes32 leaderHash) public view returns (uint256 _unallocatedAmount){
        return registery[_from][leaderHash].unallocated;
    }
    
    function getAllocation(address _from, bytes32 leaderHash, bytes32 _entryHash) public view returns (uint256 _allocatedAmount) {
        return registery[_from][leaderHash].allocated[_entryHash];
    }
}