/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

// lottery contract
contract Lottery {
    // manager address
    address public manager;
    // lottery players
    address[] public  players;
    // lottery players
    address[] public  winners;

    // target amount of tickets
    uint public target_amount;
    // price of ticket
    uint public ticket_price;
    // max price of ticket
    uint public max_ticket_price;
    // check if game finished
    bool public isGameEnded = true;
    bool public isReadyPickWinner = false;
    uint public startedTime = 0;


    // add mapping
    // mapping(address => bool) playerEntered;

    // add event
    event PickWinner(address indexed winner, uint balance);

    // constructor
    constructor() {
        // define administrator with deployer
        manager = msg.sender;
        isGameEnded = true;
    }

    // role middleware
    modifier restricted() {
        require(msg.sender == manager,"only manager has access");
        _;
    }
    // middleware to check if game is on or off
    modifier onGame() {
        require(!isGameEnded && !isReadyPickWinner, "Game has not started yet.");
        _;
    }

    // Get Balance of pool
    function balanceInPool()public view returns(uint){
        return address(this).balance;
    }

    // enter the game
    function enter() public payable onGame{
        // require(!playerEntered[msg.sender], "You have already taken the ticket");
        require(msg.value == ticket_price,"the price doesnot match with standard price");
        require(target_amount > 0, "the whole tickets has been sold");
        players.push(msg.sender);

        target_amount = target_amount - 1;
        if(target_amount == 0) {
            isReadyPickWinner = true;
        }
    }

    // initialize the game
    function initialize(
        uint _ticketPrice,
        uint _ticketAmount
    ) public restricted {
        // before init newly, previous game should be finished.
        require(isGameEnded, "Game is running now.");

        startedTime = block.timestamp;

        ticket_price = _ticketPrice;
        target_amount = _ticketAmount;
        isGameEnded = false;
        isReadyPickWinner = false;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players)));
    }

    function pickWinner() public restricted {
        require(isReadyPickWinner, "Game is running now.");

        uint index = random() % players.length;
        address payable winner = payable(players[index]);
        players = new address[](0);
        uint winBalance = address(this).balance;
        winner.transfer(address(this).balance);
        isGameEnded = true;
        winners.push(winner);

        emit PickWinner(winner, winBalance);
    }

    function getPlayers()public view returns(address[] memory){
        return players;
    }
    
    function getWinners()public view returns(address[] memory){
        return winners;
    }

    function getPlayerNumber() public view returns(uint) {
        return players.length;
    }

    function getStartedTime() public view returns(uint) {
        return block.timestamp - startedTime;
    }

    function getPercent() public view returns(uint) {
        if(isGameEnded) return 0;
        if(isReadyPickWinner) return 100;
        return getPlayerNumber() * 100 / (target_amount + getPlayerNumber());
    }
}