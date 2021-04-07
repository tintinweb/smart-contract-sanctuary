/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RecordingContract {
    event Transfer(address indexed _from, address indexed _to, string _value);

    // OWNER INFO
    address OWNER = 0xf6A45a11197a9a6Fc47429D5d3cfE82Fe6d000Bf;

    // VARIABLES
    mapping(address => string) users;

    /*
    * modifier
    */
    modifier onlyOwner {
        if (msg.sender != OWNER)
            revert(); 
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner == address(0x0)) {
            revert();
        } else {
            OWNER = newOwner;
        }
    }

    /*
    * owner run the function to create contract between sender and receiver
    * owner cost gas to run the contract
    * only owner can run the function
    */
    function transfer(address from, address to, string memory _contract) onlyOwner public {
        // Owner is not allowed.
        require(from != OWNER && to != OWNER, "Owner is not allowed");

        require(
            bytes(users[from]).length == 0 && bytes(users[to]).length == 0,
            "The contract existing."
        );

        require(
            bytes(_contract).length > 0, "The contract invalid."
        );

        users[from] = _contract;
        users[to] = _contract;
        emit Transfer(from, to, _contract);
    }

    function contractOf(address user) public view returns(string memory) {
        return users[user];
    }
}