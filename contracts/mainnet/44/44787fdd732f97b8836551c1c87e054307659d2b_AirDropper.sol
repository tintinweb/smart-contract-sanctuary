// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;

/*  by cryptovale.eth
 *  This contract supports minting and sending large amount of tokens
 *  It can be flexibly used to send an amount of tokens in a run, but it should be tested where limits are based on gas restrictions
 *  The using contract has to implement airdropper_mint, allowedToken and allowedCaller
 *  airdropper_mint: is called by this contract to mint a single token to an address
 *  airdropper_allowedToken is used to give back, if the id is allowed to be airdropped (if you foresee a section)
 *  airdropper_allowedCaller checks if a caller is allowed to call your contract for an airdrop
 *  
 *  You register your contract by calling registerContract (your contract needs to have you as an allowed caller)
 *  You can unregister the contract by calling unregisterContract
 *  
 *  You should save the address of this contract in your token contract and protect the calls
 *  require(airdroppers[msg.sender], "Not an airdropper contract");
 */

abstract contract externalInterface{
    function airdropper_mint(address to, uint256 tokenId) public virtual;
    function airdropper_allowedToken(uint256 tokenId) public virtual returns(bool);
    function airdropper_allowedCaller(address caller) public virtual returns(bool);
}

contract AirDropper{
    mapping(address => externalInterface) contracts;
    mapping(address => bool) activeContracts;

    function registerContract(address contractAddress) public{
        externalInterface _temp = externalInterface(contractAddress);
        require(_temp.airdropper_allowedCaller(msg.sender), "Caller not allowed");
        activeContracts[contractAddress] = true;
        contracts[contractAddress] = externalInterface(contractAddress);
    }

    function unregisterContract(address contractAddress) public{
        require(contracts[contractAddress].airdropper_allowedCaller(msg.sender), "Caller not allowed");
        activeContracts[contractAddress] = false;
    }

    function airdropByIndex(address contractAddress, address[] memory receivers, uint256 startIndex) public{
        require(contracts[contractAddress].airdropper_allowedCaller(msg.sender), "Caller not allowed");
        require(activeContracts[contractAddress], "Contract not registered");
        for (uint256 i = 0; i < receivers.length; i++) {
            require(contracts[contractAddress].airdropper_allowedToken(startIndex + i), "Token not allowed");
            contracts[contractAddress].airdropper_mint(receivers[i], startIndex + i);
        }
    }

    function airdrop(address contractAddress, address[] memory receivers, uint256[] memory indexes) public{
        require(contracts[contractAddress].airdropper_allowedCaller(msg.sender), "Caller not allowed");
        require(activeContracts[contractAddress], "Contract not registered");
        require(receivers.length == indexes.length, "Wrong amount");
        for (uint256 i = 0; i < receivers.length; i++) {
            require(contracts[contractAddress].airdropper_allowedToken(indexes[i]), "Token not allowed");
            contracts[contractAddress].airdropper_mint(receivers[i], indexes[i]);
        }
    }

}