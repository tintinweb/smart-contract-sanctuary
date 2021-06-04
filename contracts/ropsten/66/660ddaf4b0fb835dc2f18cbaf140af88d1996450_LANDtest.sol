/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.6;

contract LANDtest {
     
    mapping(address => mapping(address => bool)) public managers; 
    mapping(uint256 => mapping(address => bool)) public operators;
    mapping(uint256 => address) public assetOwners;
    
    constructor() public {
        
    }
    
    function mint(address owner, uint256 assetId) external {
        assetOwners[assetId] = owner;
    }
    
    function isUpdateAuthorized(address operator, uint256 assetId) view external returns(bool) {
        address owner = assetOwners[assetId];
        return managers[owner][operator] || operators[assetId][operator];
    }
    
    function setUpdateManaget(address owner, address operator, bool approved) external{
        require(operator != msg.sender, "self");
        managers[owner][operator] = approved;
    }
    
    function setUpdateOperator(uint256 assetId, address operator) external {
        require(operator != msg.sender, "self");
        operators[assetId][operator] = true;
    }
}