/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Sizzle {

    mapping(address => string) requests;
    
    event CertPublishRequestCreated(address requestor, string domain);
    
    function certPublishRequest(string memory domain) public {
        requests[msg.sender] = domain;
        emit CertPublishRequestCreated(msg.sender, domain);
    }
}