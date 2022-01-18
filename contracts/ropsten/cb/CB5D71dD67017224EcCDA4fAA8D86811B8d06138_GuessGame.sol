/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract GuessGame
{
    struct Player
    {
        address addr;
        string nickname;
        string playerResult;
        uint8 number;
    }

    uint prizeFund = 0;
    uint round = 1;
    uint entropy = 0;
    uint minBet;
    uint maxBet;
    address owner;
    bool canStartNewRound = true;
    
    Player[] players;
    Player[] winners;

    event winNumberHistory(uint, uint8);
    event participantInfo(uint, address, string, uint8, string, uint);
    event received(address, uint);

    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }

    modifier roundNotStarted()
    {
        require(players.length == 0);
        _;
    }

    constructor(uint minBet_, uint maxBet_)
    {
        owner = msg.sender;
        minBet = minBet_;
        maxBet = maxBet_;
    }

    function makeBet(string memory nickname, uint8 number) public payable
    {
        require((players.length > 0) || canStartNewRound);
        require((1 <= number) && (number <= 10));
        require((minBet <= msg.value) && (msg.value <= maxBet));

        players.push(Player(msg.sender, nickname, "Game in process", number));

        prizeFund += msg.value;

        uint hashBlock = uint(blockhash(block.number));
        uint hashName = uint(keccak256(bytes(nickname)));
        uint hashNumber = uint(keccak256(abi.encode()));
        entropy += hashBlock % 1000 + hashName % 1000 + hashNumber % 1000;

        if (players.length == 5)
        {
            game();
        }
    }

    function game() private
    {
        delete winners;
        uint8 winNumber = uint8(entropy % 10 + 1);
        emit winNumberHistory(round, winNumber);
        for (uint8 i = 0; i < 5; ++i)
        {
            if (players[i].number == winNumber)
            {
                players[i].playerResult = "Won in the round";
                winners.push(players[i]);
            }
            else
            {
                players[i].playerResult = "Lost in the round";
                emit participantInfo(round, players[i].addr, players[i].nickname, players[i].number, players[i].playerResult, 0);
            }
        }
        if (winners.length > 0)
        {
            uint eachPrize = prizeFund / winners.length;
            for (uint8 i = 0; i < winners.length; ++i)
            {
                payable(winners[i].addr).transfer(eachPrize);
                emit participantInfo(round, winners[i].addr, winners[i].nickname, winners[i].number, winners[i].playerResult, eachPrize);
            }
        }
        
        delete players;
        ++round;
        prizeFund = 0;
    }

    receive() external payable
    {
        emit received(msg.sender, msg.value);
    }

    function getPrizeFund() public view returns(uint)
    {
        return prizeFund;
    }

    function getBetBorders() public view returns(uint, uint)
    {
        return (minBet, maxBet);
    }

    function getWinners() public view returns(Player[] memory)
    {
        return winners;
    }

    function getBalance() public view onlyOwner returns(uint)
    {
        return address(this).balance;
    }

    function setCanStartNewRound(bool value) public onlyOwner
    {
        canStartNewRound = value;
    }

    function setBetBorders(uint minBet_, uint maxBet_) public onlyOwner roundNotStarted
    {
        minBet = minBet_;
        maxBet = maxBet_;
    }

    function transferProfit(uint value) public onlyOwner roundNotStarted
    {
        require(address(this).balance >= value);
        payable(msg.sender).transfer(value);
    }

    function transferAllProfit() public onlyOwner roundNotStarted
    {
        payable(msg.sender).transfer(address(this).balance);
    }

}