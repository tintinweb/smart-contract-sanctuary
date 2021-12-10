/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Guess{
    uint entropy = 0;
    uint round = 1;
    uint money = 0;
    uint min;
    uint max;
    address immutable owner;

    constructor(uint _min, uint _max) {
        owner = msg.sender;
        min = _min;
        max = _max;
    }

    struct player {
        address adr;
        string name;
        uint8 num;
        string result;
    }

    player[] players;
    player[] winners;

    event RoundPlayer(uint rnd, address addr, string name, uint num, string result, uint sum);
    event Round(uint number, uint winNumber);

    function Step(string memory name, uint8 num) public payable {
        require(num >= 1 && num <= 10);
        require(msg.value >= min && msg.value <= max);
        money += msg.value;
        players.push(player(msg.sender, name, num, ""));
        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashName = uint(keccak256(bytes(name)));
        uint hashNum = uint(keccak256(abi.encode(num)));
        entropy += hashBlock % 1000 + hashName % 1000 + hashNum % 1000;
        if (players.length == 5) game();
    } 

    function game() private {
        delete winners;
        uint num = entropy % 10 + 1;
        emit Round(round, num);
        for (uint i = 0; i < players.length; i++){
            if (players[i].num == num) {
                players[i].result = "Won in the round";
                winners.push(players[i]);
            }
            else {
                players[i].result = "Lost in the round";
                emit RoundPlayer(round, msg.sender, players[i].name, players[i].num, players[i].result, 0);
            }
        }
        for (uint i = 0; i < winners.length; i++){
            payable(winners[i].adr).transfer(money / winners.length);
        }
        money = 0;
        round++;
        delete players;
    }

   modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    function getBalance() public isOwner view returns(uint){
        return address(this).balance;
    }

    function getProfit(uint sum) public payable isOwner{
        require(players.length == 0);
        payable(owner).transfer(sum);
    }

    function getAllProfit() public payable isOwner{
        require(players.length == 0);
        payable(owner).transfer(address(this).balance);
    }

    function getResult() public view returns (player[] memory){
        return winners;
    }

    function setMinMax(uint _min, uint _max) isOwner public {
        require(players.length == 0);
        min = _min;
        max = _max;
    }

    function getMinMax() public view returns (uint, uint) {
        return (min, max);
    }

    function getMoney() public view returns (uint){
        return money;
    }
}