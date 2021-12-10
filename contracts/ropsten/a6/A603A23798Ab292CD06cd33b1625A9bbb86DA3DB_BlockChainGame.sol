/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract BlockChainGame{
    struct player{
        address playerAddress;
        string playerName;
        uint8 number;
    }

    event receiveEther(address etherAddress, uint value);
    event matchInfo(address playerAddress, uint sum, string matchResult);

    player[] players;
    player[] winners;

    uint entropy = 0;
    address owner;

    constructor(){
        owner = msg.sender;
    }

    function playGuessingGame(string memory _playerName, uint8 _number)public payable{
        require(1 <= _number && _number <= 10);
        require(address(this).balance >= msg.value*2);
        players.push(player(msg.sender, _playerName, _number));

        uint hashBlock = uint(blockhash(block.number-1));
        uint hashName = uint(keccak256(bytes(_playerName)));
        uint hashNumber = uint(keccak256(abi.encode(_number)));

        entropy += hashBlock % 1000 + hashName % 1000 + hashNumber % 1000;

        if(players.length == 5) game();
    }

    function game()private{
        delete winners;

        uint8 result = uint8(uint(keccak256(abi.encode(entropy))) % 10 + 1);
        for(uint8 i = 0; i < 5; i++){
            if(players[i].number == result){
                winners.push(players[i]);
                payable(players[i].playerAddress).transfer(msg.value*2);
                emit matchInfo(players[i].playerAddress, msg.value, "Win");
            }else{
                emit matchInfo(players[i].playerAddress, msg.value, "Lose");
            }
        }
        delete players;
    }

    function getWinners()public returns(player[] memory){
        return winners;
    }

    receive() external payable{
        emit receiveEther(msg.sender, msg.value);
    }

    function getBalance()public view returns(uint){
        require(owner == msg.sender);
        return address(this).balance;
    }

    function getAllProfit()public{
        require(owner == msg.sender);
        payable(address(this)).transfer(address(this).balance);
    }
}