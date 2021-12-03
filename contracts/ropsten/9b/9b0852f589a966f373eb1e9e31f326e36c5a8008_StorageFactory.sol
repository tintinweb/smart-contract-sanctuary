//SPDX-License-Identifier: UNLICENSED


pragma solidity >=0.8.10 <0.9.0;

import "./Storage.sol";
import "./CloneFactory.sol";

contract StorageFactory is CloneFactory  {
    address public admin;
    address public implementation;


    mapping(address => address) public DCAWallets; // Only one per address
    event ClonedContract(address _clonedContract);

    constructor(address _implementation){
        implementation = _implementation;
        admin = msg.sender;
    }
    
    function createStorage() public {
        require(DCAWallets[msg.sender] == address(0), "Wallet already exist for this address");
        //Create clone of Storage smart contract
        address clone = createClone(implementation);
        // Storage(clone).init(msg.sender); fonction pour initialiser le clone 
        Wallet(clone).init();
        DCAWallets[msg.sender] = clone;
        emit ClonedContract(clone);
    }

    function getWalletAddress(address _addr) view external returns (address){
        return DCAWallets[_addr];
    }
}