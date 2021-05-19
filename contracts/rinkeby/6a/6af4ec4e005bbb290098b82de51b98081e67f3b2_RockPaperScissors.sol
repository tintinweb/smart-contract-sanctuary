/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract RockPaperScissors {
    address public player1;
    address public player2;
    uint public bet;
    uint public lastCommitTime;
    bool public paid;
    struct Player {
        bytes32 commit;
        uint choice;
    }
    mapping (address => Player) public  players;
    uint constant public TIME_OUT_INTERVAL = 4 hours;
    // Rock = 1
    // Paper = 2
    // Scissor = 3
    event Init(address _player1, address _player2, uint _bet);
    event Commit(address _player, bytes32 _commit, uint _lastCommitTime);
    event Reveal(address _player, uint _choice);
    event ClaimTimeOut(address _reciever, uint _amount);
    event Claim(address _reciever, uint _amount);
    modifier isPlayer() {
        require(msg.sender==player1 || msg.sender==player2, "Not a player");
        _;
    }
    modifier notOver() {
        require(!paid);
        _;
    }
    constructor(address _player1, address _player2, uint _bet) {
        require(_player1 != _player2);
        require(_player1 != address(0));
        require(_player2 != address(0));
        player1 = _player1;
        player2 = _player2;
        bet = _bet;
        emit Init(_player1, _player2, _bet);
    }
    function commit(bytes32 _commit) public payable isPlayer notOver {
        require(msg.value == bet);
        require(players[msg.sender].commit == bytes32(0));
        players[msg.sender].commit = _commit;
        lastCommitTime = block.timestamp;
        emit Commit(msg.sender, _commit, lastCommitTime);
    }
    function reveal(uint _choice, uint _salt) public isPlayer notOver{
        require(players[player1].commit != bytes32(0));
        require(players[player2].commit != bytes32(0));
        require(players[msg.sender].commit==keccak256(abi.encode(_choice,_salt)));
        players[msg.sender].choice = _choice;
        emit Reveal(msg.sender, _choice);
    }
    function claimTimeOut() public notOver {
        require(lastCommitTime != 0);
        require(block.timestamp - lastCommitTime > TIME_OUT_INTERVAL);
        require((players[player1].choice == 0) || (players[player2].choice == 0));
        paid = true;
        if ((players[player1].commit != bytes32(0)) && (players[player2].commit == bytes32(0))) {
            payable(player1).transfer(bet);
            emit ClaimTimeOut(player1, bet);
            return;
        }
        if ((players[player1].commit == bytes32(0)) && (players[player2].commit != bytes32(0))) {
            payable(player2).transfer(bet);
            emit ClaimTimeOut(player2, bet);
            return;
        }
        if ((players[player1].choice != 0) && (players[player2].choice == 0)) {
            payable(player1).transfer(2*bet);
            emit ClaimTimeOut(player1, 2*bet);
            return;
        }
        if ((players[player1].choice == 0) && (players[player2].choice != 0)) {
            payable(player2).transfer(2*bet);
            emit ClaimTimeOut(player2, 2*bet);
            return;
        }
    }
    function claim() public notOver {
        require(players[player1].choice != 0);
        require(players[player2].choice != 0);
        paid = true;
        if (players[player1].choice==players[player2].choice) {
            payable(player1).transfer(bet);
            payable(player2).transfer(bet);
            emit Claim(player1, bet);
            emit Claim(player2, bet);
            return;
        }
        if ((players[player2].choice==players[player1].choice+1) || (players[player2].choice==players[player1].choice-2)) {
            payable(player2).transfer(2*bet);
            emit Claim(player2, 2*bet);
            return;
        }
        payable(player1).transfer(2*bet);
        emit Claim(player1, 2*bet);
    }
}