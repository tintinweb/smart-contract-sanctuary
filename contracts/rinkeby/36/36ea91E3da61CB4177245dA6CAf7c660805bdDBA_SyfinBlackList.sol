// SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;

contract SyfinBlackList {
    
    mapping (address => bool) private blacklistedaddy;
    
    mapping (uint => bool) private blacklistedid;
    
    address[] public updates;
    
    uint[] public idupdates;

    event SetBlackListedAddress(address indexed hashAddress, bool blacklisted);
    
    event SetBlackListedNFT(uint indexed nftID, bool blacklisted);
    
    address public owner;

    constructor ()  {
       owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setBlackListedAddress(address addy, bool blacklisted) public onlyOwner {
        
        updates.push(addy);
        
        blacklistedaddy[addy] = blacklisted;

        emit SetBlackListedAddress(addy, blacklisted);
    }
    
    function setBlackListedNFT(uint nftID, bool blacklisted) public onlyOwner {
        
        idupdates.push(nftID);
        
        blacklistedid[nftID] = blacklisted;

        emit SetBlackListedNFT(nftID, blacklisted);
    }

    function getBlackListedAddress(address blAddress) public view returns (bool) {
        return blacklistedaddy[blAddress];
    }
    
    function getBlackListedNFT(uint nftID) public view returns (bool) {
        return blacklistedid[nftID];
    }
    
    function AddyCount() public view returns (uint) {
        return updates.length;
    }
    
    function IDCount() public view returns (uint) {
        return idupdates.length;
    }
}