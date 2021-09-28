/**
 *Submitted for verification at polygonscan.com on 2021-09-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract GoGBattleSimulator {
    event Match(address indexed playerOne, address indexed playerTwo, string ipfs, uint256 matchID);
    event MatchResult(address indexed winner, uint256 matchID, uint256 timestamp);
    event RewardPrize(address indexed winner, uint256 indexed tokenID);
    
    address _referee;
    uint256 _nextMatchID;
    
    constructor() {
        _referee = msg.sender;
        _nextMatchID = 0;
    }
    
    modifier refereeOnly {
        require(msg.sender == _referee);
        _;
    }
    
    function setReferee(address referee) refereeOnly() public {
        _referee = referee;
    }

    function claimMatchComplete(address playerOne, address playerTwo, string memory ipfs) public {
        emit Match(playerOne, playerTwo, ipfs, _nextMatchID);
        _nextMatchID++;
    }

    function confirmMatchResults(address winner, uint256 matchID, uint256 timestamp, uint256 prizeID) refereeOnly() public {
        emit MatchResult(winner, matchID, timestamp);
        emit RewardPrize(winner, prizeID);
    }

}