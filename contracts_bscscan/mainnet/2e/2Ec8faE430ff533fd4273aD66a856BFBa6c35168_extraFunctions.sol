/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract extraFunctions is Ownable {
    mapping(uint256 => productStruct) _product;

    struct productStruct {
        bool whitelistEnabled;
        mapping (address => bool) isWhitelisted;
    }



    //mapping(address => bool) isWhitelisted;


    function whitelist(uint256 productId, address[] memory _addresses) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            _product[productId].isWhitelisted[_addresses[i]] = true;
        }
    }

    function removeWhitelist(uint256 productId, address[] memory _addresses) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            _product[productId].isWhitelisted[_addresses[i]] = false;
        }
    }

    function setProductWhitelistEnabled(uint256 productId, bool _state) public onlyOwner {
        _product[productId].whitelistEnabled = _state;
    }

    function isProductWhitelistEnabled(uint256 productId) public view returns(bool) {
        return _product[productId].whitelistEnabled;
    }

    function getProductAddressIsWhitelisted(uint256 productId, address _address) public view returns(bool) {
        return _product[productId].isWhitelisted[_address];
    }
}