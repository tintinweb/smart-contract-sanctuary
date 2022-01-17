/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery{

    address payable public manager;
    address payable[] public players;

    constructor()  {
        manager = payable(msg.sender);

    }

    function enter() public payable{
        require (msg.value > 0.01 ether);

        players.push(payable(msg.sender));
    }

    function random_num() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pick_winner() public restricted_func {
        uint index = random_num() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    function get_list_players() public view returns(address payable[] memory) {
        return players;
    }


    modifier restricted_func{
        require (msg.sender == manager);
        _;
    }

}