/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: Unlimited
pragma solidity ^0.8.0;

contract MPHPresaleTest {

	mapping (address => bool) public _presaleAddresses;
	mapping (address => bool) public _presaleAddressesMinted;
	address public owner;

    constructor () {
        owner = msg.sender;
    }

    function setMainContract(address _address) public {
        require(msg.sender == owner, "My Pet Hooligan: You are not the owner");
        owner = _address;
    }

    function addPresalers(address[] calldata _addresses) public {
        require(msg.sender == owner, "My Pet Hooligan: You are not the owner");
        for (uint x = 0; x < _addresses.length; x++) {
            _presaleAddresses[_addresses[x]] = true;
        }
    }
    
    function removePresalers(address[] calldata _addresses) public {
        require(msg.sender == owner, "My Pet Hooligan: You are not the owner");
        for (uint x = 0; x < _addresses.length; x++) {
            _presaleAddresses[_addresses[x]] = false;
        }
    }

    function isInPresale(address _address) public view returns (bool) {
        return _presaleAddresses[_address];
    }

    function isInMintedPresale(address _address) public view returns (bool) {
        return _presaleAddressesMinted[_address];
    }

    function addToMinted(address _address) public {
        require(msg.sender == owner, "My Pet Hooligan: You are not the owner");
        _presaleAddressesMinted[_address] = true;
    }

}