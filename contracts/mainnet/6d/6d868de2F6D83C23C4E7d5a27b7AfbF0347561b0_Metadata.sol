/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity ^0.8.4;
//SPDX-License-Identifier: MIT


abstract contract StoreHubInterface {
    mapping(address => bool) public isValidStore;
}

abstract contract StoreProxy {
    address public owner;
}

contract Metadata {
    event MetaDataUpdated(address indexed store, string[7] metaData);
    
    StoreHubInterface usdcHub;
    
    constructor(address _hub) {
        usdcHub = StoreHubInterface(_hub);
    }
    
    function setMetaData(address _store, string[7] calldata _metaData) external {
        require(usdcHub.isValidStore(_store) == true);
        require(StoreProxy(_store).owner() == msg.sender);
        emit MetaDataUpdated(_store, _metaData);
    }
}