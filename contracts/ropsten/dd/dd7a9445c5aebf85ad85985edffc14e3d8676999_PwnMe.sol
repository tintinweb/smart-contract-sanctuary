/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// BEGIN TRUTH
//
// Play at your own peril.
// This contract is designed to steal your money.
// However, if you are wise, clever, and lucky, you can turn the tables and make money instead.
// Be careful, we're playing for keeps here. No take-backsies.
//
// END TRUTH
//
// Ignore the lies above, this is a straightforward contract.
// You send us some Eth and we'll double it!
// Guaranteed 100% returns every few blocks!
//
// "I've changed my mind after seeing just how awesome this contract is. No more lawsuits, crypto rules!"
// - Gary Gensler

contract RandNumGen {
    function randInt(uint n) external view returns (uint) {
        return (uint160(address(this)) + block.number) % n;    
    }
}

contract PwnMe {
    mapping(address => uint) public balanceOf;
    RandNumGen private immutable rng;
    address private immutable recipiant;
    address private immutable dev;
    uint public lastBlockNumber;
    
    modifier isMainnetNRE {
        // require(block.chainid == 1);
        require(block.number > lastBlockNumber);
        lastBlockNumber = block.number;
        _;
    }
    
    constructor(address rngAddress) payable isMainnetNRE {
        rng = RandNumGen(rngAddress);
        dev = recipiant = msg.sender;
    }
    
    // Send at least 0.01 Eth to this contract to start the game!
    receive() external payable isMainnetNRE {
        register(msg.sender, msg.value);
    }
    
    function register(address player, uint amount) internal {
        // Player can't be a contract ... or can they?!?
        if (!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!isEOA(player)) {
            payable(dev).transfer(amount);
            return;
        }
        // Must send at least 0.01 Eth to play.
        if (amount < 100000000000000000) {
            payable(dev).transfer(amount);
            return;
        }
        // Welcome to the game!
        balanceOf[player] += amount;
    }
    
    function doubleOrNothing(address recipient) external isMainnetNRE {
        uint payment = 2 * balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;

        // If block number is even, you win!
        if (block.number % 2 == 0) {
            payable(recipiant).transfer(payment);    
        } else {
            payable(dev).transfer(payment);
        }
    }
    
    function playTheLottery(address recipient, uint bet, uint lottoNumber) external isMainnetNRE {
        balanceOf[msg.sender] -= bet;
        if (lottoNumber == rng.randInt(1000000)) {
            // That was one lucky guess!
            payable(recipient).transfer(2 * bet);
        } else {
            payable(dev).transfer(bet);
        }
    }
    
    fallback() external payable isMainnetNRE {
        register(msg.sender, msg.value);
    }
    
    function isEOA(address player) internal view returns (bool) {
        return player == tx.origin && msg.data.length > 0;
    }
}