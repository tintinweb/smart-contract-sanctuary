/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

contract Proxy {

    // address of the platorm manager
    address public platform;

    mapping(string => address) public resourceContractAddress;
    mapping(string => bool) public enabled;

    event ResourceRegistered(address indexed resource, string resourceId);
    event ResourceModified(
        string indexed resourceId,
        address indexed currentAddress,
        address indexed newAddress
    );
    event ResourceEnabled(string indexed resourceContractAddress);
    event ResourceDisabled(string indexed resourceContractAddress);

    constructor() {
        platform = msg.sender;
    }

    function registerResource(string memory resourceId, address contractAddress) external {
        resourceContractAddress[resourceId] = contractAddress;
        emit ResourceRegistered(contractAddress, resourceId);
    }

    function enable(string memory resourceId) external {
        enabled[resourceId] = true;
        emit ResourceEnabled(resourceId);
    }

    function disable(string memory resourceId) external {
        enabled[resourceId] = false;
        emit ResourceDisabled(resourceId);
    }

    function modifyResource(string memory resourceId, address newResourceContractAddress)
        external
    {
        address currentAddress = resourceContractAddress[resourceId];
        resourceContractAddress[resourceId] = newResourceContractAddress;
        emit ResourceModified(resourceId, currentAddress, newResourceContractAddress);
    }

    function deleteResource(string memory resourceId) internal {
        resourceContractAddress[resourceId] = address(0);
    }
}