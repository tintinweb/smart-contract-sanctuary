/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

/**
 *Submitted for verification at Etherscan.io on 2019-12-21
*/

pragma solidity ^0.5.15;

/** @title Owned */
contract Owned {
    address payable public  owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Owned constructor
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

/** @title FourArt Image saving contract */
contract FourArtSaveFingerPrint is Owned {
    struct FingerPrint{
      string fpHash;
      bool isValue;
   }
    mapping(string => FingerPrint) private fingerPrints;
    
    
   function uploadFingerPrint(string memory storageRef, string memory hash) onlyOwner public {
       if (!fingerPrints[storageRef].isValue) {
           fingerPrints[storageRef].fpHash =  hash;
           fingerPrints[storageRef].isValue =  true; 
       }
   }
   
   function getFingerPrint(string memory sInfo) public view returns (string memory) {
        return fingerPrints[sInfo].fpHash;
   } 
}