// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/** 
 * @title DailyLog
 * @dev records daily interaction count
 */
contract DailyLog {
    
    address public owner;
    
    mapping(string => mapping(bytes32=> bytes32)) public dailyLogs; // date => (branchId, hash)
    
    modifier onlyOwner() {
        require(msg.sender==owner, "only Owner allowed");
        _;
    }
    
    constructor() {
            
        owner = msg.sender; 
    }
    
    function addLogs(string[] calldata dates, bytes32[] calldata branchIds, bytes32[] calldata hashes) external onlyOwner {
        
        for (uint i=0; i<dates.length; i++) {
            dailyLogs[dates[i]][branchIds[i]]=hashes[i];
        }
    }
    
    function getHash(string calldata date, bytes32 branchId) public view returns (bytes32) {
        return dailyLogs[date][branchId];
    }
}