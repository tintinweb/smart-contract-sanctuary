/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: GPL-3.0
/**
 *  @authors: [@mtsalenc]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.1;

/**
 * @title PingPong
 * @dev Exercise on syncing and transaction submission.
 */
contract PingPong {
    
    address public pinger;
    
    constructor() {
        pinger = msg.sender;
    }
    
    event Ping();
    event Pong(bytes32 txHash);
    
    function ping() external {
        require(msg.sender == pinger, "Only the pinger can call this.");
        
        emit Ping();
    }
    
    function pong(bytes32 _txHash) external {
        emit Pong(_txHash);
    }
}