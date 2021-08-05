/**
 *Submitted for verification at Etherscan.io on 2020-12-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract License {
    
    /* Licenses for trader.js the DeFi degen companion script */
    
    address payable admin;
    uint256 public price;
    mapping (address => bool) public licenses;
    
    constructor() {
        admin = msg.sender;
        licenses[msg.sender] = true;
        price = 2 ether;
    }
    
    receive() external payable {
        require(msg.value >= price, "Not enough ETH was sent");
        require(!licenses[msg.sender], "User already has a license");
        licenses[msg.sender] = true;
    }
    
    function withdraw() external {
        admin.transfer(address(this).balance);
    }
    
    function check() external view returns(bool) {
        return(licenses[msg.sender]);
    }
    
    function updatePrice(uint256 _new) external {
        require(admin == msg.sender, "Admin only!");
        price = _new;
    }
}