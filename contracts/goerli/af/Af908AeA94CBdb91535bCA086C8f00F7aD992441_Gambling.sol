// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

/**
 * (E)t)h)e)x) Jackpot Contract 
 *  This smart-contract is the part of Ethex Lottery fair game.
 *  See latest version at https://github.com/ethex-bet/ethex-contracts 
 *  http://ethex.bet
 */

 import "./Ownable.sol";

contract Gambling is Ownable {
    
    Ticket[] public tickets;

    event BuyTicket(address, uint, uint);

    struct Ticket {
        uint32 number;
        address player;
        uint value;
        uint8 game;
    }

    enum Game { 
        EVEN, 
        ODD, 
        LARGE,
        SMALL
    }

    
    function getTicket(uint32 number, uint8 game) public payable {
        require(msg.value > 0, "Value greater than 0");
        require(msg.sender != address(0));
        tickets.push(Ticket(number, msg.sender, msg.value, game));
        emit BuyTicket(msg.sender, msg.value, game);
    }

    function getBlockHash() public view returns (bytes32) {
        bytes32 hash = blockhash(block.number);
        return hash;
    } 


    // fallback() external payable {
        
    // }

}