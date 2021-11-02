// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Splitter child contract for splitting ether
/// @author The Systango Team

contract Factory {

    // The address of Factory owner address
    address payable public factoryOwner;

    // The array of contracts produced by this factory contract.
    address[] public contracts;

    // Event to trigger the creation of new Child contract address.
    event SplitterCreated(address indexed contractAddress);

    // This is the constructor of the contract. It is called at deploy time.
    // This will set the factoryOwner as the address used to deploy the contract.
    constructor(){
        factoryOwner = payable(msg.sender);
    }

    // Returns the length of all the contracts deployed through this factory contract.
    function getContractCount() public view returns (uint256) {
        return contracts.length;
    }

    // This function is called when a new child contract has to be created.

    /// @param owner The owner of the new child contract which will be created. 
    /// @param payeeAddresses The address array of the new contract in which the funds 
    /// will be splitted.
    /// @param payeeShare The precentage array of the respective ethereum addresses
    /// provided for the funds to get splitted.

}