/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Coin{
    uint entropy = 0;
    uint round = 1;
    uint minBet;
    uint maxBet;
    uint sum = 0;
    address payable owner;
    
    event luckyNumber(uint, uint8);
    event playersResult(uint, address, string, uint8, string, uint);

    struct player{
        address playerAddress;
        string playerName;
        string playerResult;
        uint8 number;

    }
    player[] players;
    player[] winners;
    bool stop=false;

    modifier ownerOnly(){
        require(msg.sender == owner);
        _;
    }

     modifier unbegin(){
        require(players.length == 0);
        _;
    }

    constructor(uint _minBet, uint _maxBet){
        minBet = _minBet;
        maxBet = _maxBet;
        owner = payable(msg.sender);
    }

    function play(string calldata _name, uint8 _num)public payable{
        assert( !stop || players.length != 0);
        assert(_num<=10 && minBet <= msg.value && msg.value <= maxBet);

        sum += msg.value;
        players.push(player(msg.sender, _name, "Lost in the round", _num));

        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashName = uint(keccak256(abi.encode(_name)));
        uint hashCoin = uint(keccak256(abi.encode(_num)));

        entropy += hashCoin%1000 + hashName%1000 + hashBlock%1000;

        if(players.length == 5){
            game();
        }
    }
    
    function game()private{
        delete winners;
        uint8 result = uint8(entropy%10 + 1);
        emit luckyNumber(round, result);

        for(uint i=0;i<5;i++){
            if(players[i].number == result){
                players[i].playerResult = "Won in the round";
                winners.push(players[i]);
            }else{
                emit playersResult(round, players[i].playerAddress, players[i].playerName, players[i].number, players[i].playerResult, 0);
            }
        }

        
        for(uint i=0; i < winners.length ;i++){
            payable(winners[i].playerAddress).transfer(sum/winners.length);
            emit playersResult(round, winners[i].playerAddress, winners[i].playerName, winners[i].number, winners[i].playerResult, sum/winners.length);
        }

        sum = 0;
        round++;
        delete players;
    }

    receive()external payable{}

    function getBorders()public view returns(uint, uint){
        return (minBet, maxBet);
    }

    function getCurrentSum()public view returns(uint){
        return sum;
    }

    function getWinners()public view returns(player[] memory){
        return winners;
    }

    function getBalance()public ownerOnly view returns(uint){
        return address(this).balance;
    }

    function setBorders(uint _minBet, uint _maxBet) public ownerOnly unbegin{
        minBet = _minBet;
        maxBet = _maxBet;
    }

    function getPart(uint _value)public ownerOnly unbegin{
        owner.transfer(_value);
    }

    function getAll()public ownerOnly unbegin{
        owner.transfer(address(this).balance);
    }

    function stopAfterRound()public ownerOnly{
        stop = true;
    }

    function start()public ownerOnly{
        stop = false;
    }

}