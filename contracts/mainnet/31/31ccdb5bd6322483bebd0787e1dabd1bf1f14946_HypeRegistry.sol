/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.8.0;

contract HypeRegistry {
    
    address public owner;
    address[] public registry;
    mapping(address=>uint256) public registryMap;
    int256 public counter;
    
    event HypeAdded(address hype, uint256 index);
    event HypeRemoved(address hype, uint256 index);
    
    constructor() {
        owner = msg.sender;    
    }
    
    function add(address hype) external {
        require(msg.sender == owner,"only owner");
        require(registryMap[hype]==0, "exists");
        registry.push(hype);
        registryMap[hype] = registry.length;
        counter++;
        emit HypeAdded(hype, registry.length-1);
    }
    
    function addMany(address[] memory hypes) external {
        require(msg.sender == owner,"only owner");
        for(uint256 i=0; i<hypes.length; i++) {
            if(registryMap[hypes[i]]!=0) continue;
            registry.push(hypes[i]);
            registryMap[hypes[i]] = registry.length;
            counter++;
            emit HypeAdded(hypes[i], registry.length-1);
        }
    }

    function remove(address hype) external {
        require(msg.sender == owner,"only owner");
        require(registryMap[hype]!=0, "not exists");
        emit HypeRemoved(hype, registryMap[hype]-1);
        registryMap[hype] = 0;
        counter--;
    }
    
    function hypeByIndex(uint256 index) external view returns (address, uint256){
        return (registry[index], registryMap[registry[index]]);
    }
    
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "only owner");
        owner = newOwner;
    }

}