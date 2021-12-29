/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

/// @title Legal Entity Verification
/// @author Deniz Surmeli
/// @author Doğukan Türksoy
/// @notice Use it only for simulation.
/// @dev It's used in ./Provenance.sol contract for address authorization 

contract LegalEntityVerification {
    /// @notice Verified addresses will return true.
    mapping(address=>bool) verifiedAddresses;

    /// @notice Deployer of the contract will be stored here for later checkings.
    address public stateAuthority;

    constructor(){
        stateAuthority = msg.sender;
    }

    /// @notice Only state authority can perform actions.
    /// @param _address Address to be queried.
    modifier onlyStateAuthority(address _address){
        require(_address == msg.sender);
        _;
    }
    /// @notice Only non-verified addresses can perform actions.
    /// @param _address Address to be queried.
    modifier onlyNonVerified(address _address){
        require(!(verifiedAddresses[_address]));
        _;
    }

    /// @notice Verify an address.
    /// @param _address address to be verified. 
    function verify(address _address) onlyStateAuthority(msg.sender) onlyNonVerified(_address) public {
        verifiedAddresses[_address] = true;
    }
    
    /// @notice Query the verification of an address.
    /// @param _address address to be queried.
    /// @return A bool whether the address is verified or not. 
    function isVerified(address _address) public view returns(bool){
        return verifiedAddresses[_address];
    }

    /// @notice Address of the state authority.
    /// @return Address of the state authority.
    function getStateAuthorityAddress() public view returns(address){
        return stateAuthority;
    }
}