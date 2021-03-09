/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;

// 
// A faucet that replies with ether
contract FaucetDummy {

    address payable owner;
    uint withdraw_amount = 1e6 gwei;

    constructor() {
        owner = payable(msg.sender);
    }

    function clear() external {

        require(msg.sender == owner);
        owner.transfer(address(this).balance);

    }

    // Accept any incoming amount
    fallback() external payable {
        // Send amount to the address that requested it
        msg.sender.transfer( withdraw_amount ); 

    }
}