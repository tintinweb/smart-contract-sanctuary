/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity ^0.5.4;

contract NiftyRegistry {

    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);

    modifier onlyOwner() {
        require(isOwner[msg.sender] == true);
        _;
    }

    mapping(address => bool) niftyManagers;
    mapping (address => bool) public isOwner;

    function isValidNiftyManager(address sending_key) public view returns (bool) {
        return(niftyManagers[sending_key]);
    }

    function addNiftyManager(address new_sending_key) external onlyOwner {
        niftyManagers[new_sending_key] = true;
    }

    function removeNiftyManager(address sending_key) external onlyOwner {
        niftyManagers[sending_key] = false;
    }

    constructor(address[] memory _owners, address[] memory signing_keys) public {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        for (uint i=0; i<signing_keys.length; i++) {
            require(signing_keys[i] != address(0));
            niftyManagers[signing_keys[i]] = true;
        }
    }

    function addOwner(address owner) public onlyOwner {
        isOwner[owner] = true;
        emit OwnerAddition(owner);
    }

    function removeOwner(address owner) public onlyOwner {
        isOwner[owner] = false;
        emit OwnerRemoval(owner);
    }

}