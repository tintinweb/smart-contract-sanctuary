// SPDX-License-Identifier: UNLICENCED
pragma solidity >0.8.0;
import "./Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) whitelist;
    mapping(address => bool) adminlist;
    
    constructor(){
        whitelist[owner()]=true;
        adminlist[owner()]=true;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function addAddressToWhitelist(address _address) public onlyAdminlisted {
        whitelist[_address] = true;
    }

    function removeAddressFromWhitelist(address _address) public onlyAdminlisted {
        whitelist[_address] = false;
    }
    
    function addMultiAddressesToWhitelist(address[] memory _addresses) public onlyAdminlisted {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addAddressToWhitelist(_addresses[i]);
        }
    }

    function removeMultiAddressesFromWhitelist(address[] memory _addresses) public onlyAdminlisted {
        for (uint256 i = 0; i < _addresses.length; i++) {
            removeAddressFromWhitelist(_addresses[i]);
        }
    }


    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
    
    modifier onlyAdminlisted() {
        require(isAdminlisted(msg.sender));
        _;
    }
    
    function addAddressToAdminlist(address _address) private onlyOwner {
        adminlist[_address] = true;
    }

    function removeAddressFromAdminlist(address _address) private onlyOwner {
        adminlist[_address] = false;
    }

    function isAdminlisted(address _address) private view returns(bool) {
        return adminlist[_address];
    }
}