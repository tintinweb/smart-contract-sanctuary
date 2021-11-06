/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Rocketeer {
    function totalSupply () external view returns ( uint256 );
    function balanceOf ( address owner ) external view returns ( uint256 );
    function spawnRocketeer ( address _to ) external;
    function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
}

contract MultiRocketeer {

    Rocketeer rocketeer;

    constructor (address rocketeerAddress) {
        rocketeer = Rocketeer(rocketeerAddress);
    }

    /**
    @notice Unconditionally buy exact amount of Rocketeers. Might wrap over 42 so you pay for less than you receive.
    */
    function multiBuy(uint amount) public {
        for (uint i = 0; i < amount; ++i)
            rocketeer.spawnRocketeer(msg.sender);
    }

    /**
    @notice Try to buy exact amount of Rocketeers, but stop at the 41nd (so you don't pay for the 42nd).
    */
    function multiBuyUntil42(uint max_amount) public {
        uint avail = 41 - rocketeer.totalSupply() % 42;
        multiBuy(max_amount > avail ? avail : max_amount);
    }

    /**
    @notice Buy as many Rocketeers as possible until the next double Rocketeer.
    @param including Set true if you want to buy the 42th (and pay the extra gas), otherwise set to false.
    */
    function buyUntil42(bool including) public {
        multiBuy((including ? 42 : 41) - rocketeer.totalSupply() % 42);
    }
}