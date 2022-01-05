/**
 *Submitted for verification at polygonscan.com on 2022-01-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract transferTest {

    address[] users;
    uint256[] values;
    uint256 total;
    
    address owner;

    constructor() {
        owner = msg.sender;
    }


    mapping (address => bool) public Wallets; 
    
    function transderToContract() payable public {
        require(!Wallets[msg.sender], "donated");
        require(msg.value >= 0.02 ether, "min");
        require(msg.value <= 1 ether, "max");
        require(total <= 20 ether, "complete");

        users.push(msg.sender);
        values.push(msg.value);
        Wallets[msg.sender] = true;
        total += msg.value;
        payable(owner).transfer(msg.value);
    }
    
    function getTotal() public view returns (uint256) {
        return total;
    }

    function getAddress() public view returns (address) {
        return owner;
    }

    function getUsers() public view returns (address[] memory, uint256[] memory) {
        return (users, values);
    }
}