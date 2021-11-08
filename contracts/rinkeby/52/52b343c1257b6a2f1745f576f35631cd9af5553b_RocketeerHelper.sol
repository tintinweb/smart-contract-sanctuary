/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Rocketeer {
    function totalSupply () external view returns ( uint256 );
    function balanceOf ( address owner ) external view returns ( uint256 );
    function spawnRocketeer ( address _to ) external;
    function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
}

/** @title Streamline the creation of "Rocketeer"-NFTs
    @author RamiRond
    @notice This simple contract has 3 main purposes:
            1: Spawning multiple Rocketeers at once. The Rocketeer contract only allows you to spawn one Rocketeer at a time.
               You cannot have enough of them, so this makes it more easy to buy as many as you want!
            2: Saving gas fees. While Rcoketeers themselves are free to spawn, using Ethereum is not. By minting multiple
               NFTs at once, you save about 10-20% per Rocketeer on gas fees.
               But be cautious: Your transactions can still fail if MetaMask gas estimation isn't correct anymore at execution time.
               So make sure to supply enough gas, you'll always get the remainder refunded if it was too much.
            3: Handling the "42nd-mechanic" nicely. Every 42nd mint creates two (special!) Rocketeers, one for the user and one for the devs.
               This can result in failed transactions and lost gas. To mitigate this effect, you can specify whether you
               want to mint a 42nd or not.
    @dev Could add some checks to not try minting over max supply of 3475, but this is short lived anyway. Let's save that gas instead.
*/
contract RocketeerHelper {

    Rocketeer rocketeer = Rocketeer(0x95d6b9549315212D3FDce9FdCa9d80978b8bB41D);

    /**
    @notice Convenience function to forward the current supply of Rocketeers (as the contract isn't verified at the time of writing this).
    */
    function totalSupply() external view returns(uint256) {
        return rocketeer.totalSupply();
    }

    /**
    @notice Try to spawn one Rocketeer. Can be used to either reliably snipe or avoid the 42nd.
    @param spawn_for_devs True if you only want to spawn if it's a 42nd, False if you only want to spawn if it's NOT a 42nd.
    */
    function spawnOne(bool spawn_for_devs) external {
        bool next_is_42nd = rocketeer.totalSupply() % 42 == 41;
        if (next_is_42nd && spawn_for_devs ||
            !next_is_42nd && !spawn_for_devs) {
            rocketeer.spawnRocketeer(msg.sender);
        }
    }

    /**
    @notice Unconditionally spawn an exact amount of Rocketeers. Might wrap over 42 and mint one (or more) Rocketeer(s) for the devs.
    @param amount Amount of Rocketeers to spawn.
    */
    function spawnMany(uint16 amount) public {
        for (uint i = 0; i < amount; i++) {
            rocketeer.spawnRocketeer(msg.sender);
        }
    }

    /**
    @notice Try to spawn an exact amount of Rocketeers, but stop at the next 41st (so you don't pay extra for the devs).
    @param max_amount The desired amount of Rocketeers to spawn.
    */
    function spawnManyLimited(uint16 max_amount) external {
        uint16 avail = 41 - uint16(rocketeer.totalSupply()) % 42;
        spawnMany(max_amount > avail ? avail : max_amount);
    }

    /**
    @notice Spawn as many Rocketeers as possible until the next double Rocketeer.
    @param spawn_for_devs Set true if you want to buy the 42nd (and pay the extra gas), otherwise set false.
    */
    function spawnUntil42(bool spawn_for_devs) external {
        spawnMany((spawn_for_devs ? 42 : 41) - uint16(rocketeer.totalSupply()) % 42);
    }

    /**
    @notice Spawn all Rocketeers up until a specific ID (like 1337). Doesn't care about 42 mechanic.
    @param id The last id to spawn.
    */
    function spawnUntilId(uint16 id) external {
        uint16 cur_id = uint16(rocketeer.totalSupply());
        require(id < cur_id, "Sorry, the Rocketeer with this ID has been minted already!");
        spawnMany(id - cur_id);
    }
}