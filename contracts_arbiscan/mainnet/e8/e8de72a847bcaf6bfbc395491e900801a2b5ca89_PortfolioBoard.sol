/**
 *Submitted for verification at arbiscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract PortfolioBoard {
    address private owner;
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }
    
    bytes32[] private consolidatedHashes; 
    
    function addNewPortfolioHash (bytes32 _traderPortfolioHash) payable public {
        consolidatedHashes.push(_traderPortfolioHash);
    }

    function totalTrades ()  public view returns (uint256) {
        return consolidatedHashes.length;
    }
}