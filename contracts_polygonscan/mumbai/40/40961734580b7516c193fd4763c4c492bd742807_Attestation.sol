/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.4.24;

/**
 * Contract for Vanity URL on SpringRole
 * Go to beta.springrole.com to try this out!
 */

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of “user permissions”.
 */

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

/*
Attestatuion contract to enter event data for all attestations
*/
contract Attestation is Ownable {
    /*
    Attest by user
    */
    event Attest(address _address, string _type, string _data);

    function write(string _type, string _data) public returns (bool) {
        emit Attest(msg.sender, _type, _data);
        return true;
    }

    event AttestByOwner(string _address, string _type, string _data);

    /*
    Write by owner to be committed in case of data migration
    */
    function writeByOwner(
        string _type,
        string _data,
        string _address
    ) public onlyOwner returns (bool) {
        emit AttestByOwner(_address, _type, _data);
        return true;
    }
}