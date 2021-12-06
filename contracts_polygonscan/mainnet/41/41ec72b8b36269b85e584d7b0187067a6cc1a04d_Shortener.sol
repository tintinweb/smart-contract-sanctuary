/**
 *Submitted for verification at polygonscan.com on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * The intention of this smart contract is to create a mutable URL shortener.
 * You can for example register a name and tie it to some value that fits in a uint256.
 *
 * Keys are structured in such a way that they need to be unique per wallet address.
 * So any number of users can register the key "test" as long as each registration is
 * done with a different wallet address. The key + address is the unique key.
 *
 * The purpose here is for the distributed web where the value is intended to be a
 * hash from an IPFS CID. You'll find no use for this if you need to store larger values.
 * You will need a companion library to properly translate the uint256 to a IPFS CID.
 * 
 * This contract is, in essense, a key -> value store and you can use it as such too.
 *
 * You can access a GUI for this and find more information on https://u.sc2.nl
 * 
 */
 
contract Shortener
{
    struct ValueData
    {
        address owner;
        uint256 value;
    }

    mapping(bytes32 => ValueData) private kvMapping;
    
    event valueChanged(string key, uint256 value, address owner);
    
    // Only the owner of a key can change it. Or anyone if the address is 0.
    modifier keyExists(bytes32 key, address owner)
    {
        ValueData memory data = kvMapping[key];
        require(data.owner == owner || data.owner == address(0), "You're not the owner of this record.");
        _;
    }

    function setValue(string calldata key, uint256 value) public keyExists(composeKeyHash(key, msg.sender), msg.sender)
    {
        bytes32 hashValue = composeKeyHash(key, msg.sender);
        kvMapping[hashValue] = ValueData(msg.sender, value);

        // Emitted for any change, including newly added values.
        emit valueChanged(key, value, msg.sender);
    }

    function composeKeyHash(string calldata key, address owner) internal pure returns(bytes32)
    {
        return sha256(bytes.concat(bytes(key), abi.encodePacked(owner)));
    }

    function getValue(string calldata key, address owner) public view returns(uint256)
    {
        ValueData memory data = kvMapping[composeKeyHash(key, owner)];
        return data.value;
    }
}