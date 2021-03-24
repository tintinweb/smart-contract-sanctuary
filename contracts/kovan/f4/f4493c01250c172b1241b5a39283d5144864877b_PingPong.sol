/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: GPL-3.0
/**
 *  @authors: [@mtsalenc]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.1;

/**
 * @title PingPong
 * @dev Exercise on syncing and transaction submission.
 */
contract PingPong {
    
    address public pinger;
    uint private pings;
    mapping(uint => bool) private pingPonged;
    
    constructor() {
        pinger = msg.sender;
    }
    
    event Ping(uint _ping);
    event Pong(uint _ping);
    
    function ping() external {
        require(msg.sender == pinger, "Only the pinger can call this.");
        
        pings++;
        emit Ping(pings);
    }
    
    function pong(uint _ping) external {
        require(!pingPonged[_ping], "Already ponged this ping.");
        pingPonged[_ping] = true;
        emit Pong(_ping);
    }
}