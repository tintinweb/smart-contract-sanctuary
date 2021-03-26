/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity 0.8.2;
//"SPDX-License-Identifier: UNLICENSED"

contract Lottery {

    address[] public players;
    uint public bank;
    address public manager;

    constructor(address) {
        manager = msg.sender;
    }


    modifier onlyManager{
        require(msg.sender == manager, 'Only manager can pick winner');
        _;
    }

    function enter() public payable {
        require(msg.value > 0.009 ether);
        address player = msg.sender;
        players.push(player);
        bank += msg.value;

    }

    function getManager() public view returns(address){
        return manager;
    }

    function getNumberOfPlayers() public view returns(uint){
        return players.length;
    }

    function getPlayers() public view returns(address [] memory) {
        return players;
    }


    function getPlayer(uint32 num) public view returns (address){
        require(num<players.length, 'Please submit number less than number of participating members');
        return players[num];
    }

    function random() public view returns (uint){
        return uint(keccak256(abi.encode(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public onlyManager {
        require(players.length>3, "Need at least 4 players");
        uint index;
        index = random() % players.length;
        address payable winner = payable(players[index]);
        winner.transfer(bank);
        players = new address[](0);
        assert(players.length == 0);
    }

}