/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract PEG9 {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "Play Earn Game";
    string public symbol = "PEGv2";
    uint public decimals = 18;
    
    address private taxWallet  = 0x9a78f38fd8613fc5DECadD4A148e08a59AFEF4A0;
    address public dead  = 0x000000000000000000000000000000000000dEaD;
    address public admin;
    bool public pollRunning = false;
    uint public currentVote = 0;
    mapping(uint => mapping(address => bool)) public alreadyVoted;
    mapping(uint => uint[]) public votes;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Burn(address indexed from, address indexed to, uint value);
    event Taxed(address indexed from, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event PollResults(uint totalVotes, uint votesForArgA);
    
    constructor() {
        admin = msg.sender;
        balances[admin] = totalSupply;
    }
    
    
    function newPoll() public returns(bool){
        require(msg.sender == admin, 'not allowed to use this function');
        pollRunning = true;
        currentVote++;
        return true;
    }
    
    function endPoll() public returns(bool){
        require(msg.sender == admin, 'not allowed to use this function');
        pollRunning = false;
        uint k = 0;
        for( uint i = 0; i < votes[currentVote].length; i++){
            if( votes[currentVote][i] == 1)
                k++;
        }
        emit PollResults(votes[currentVote].length, k);
        return true;
    }
    
    function vote(uint arg) external returns(bool){
        require(pollRunning == true, 'none to vote about');
        require(balanceOf(msg.sender) > 0, 'not allowed to vote');
        require(!alreadyVoted[currentVote][msg.sender], 'already voted');
        require(arg == 0 || arg == 1, 'this is not an argument of this vote');
        votes[currentVote].push(arg);
        alreadyVoted[currentVote][msg.sender] = true;
        return true;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        uint toBurn = value / 100;
        uint toTax = value / 50;
        uint total = value + toTax + toBurn;
        require(balanceOf(msg.sender) >= total, 'balance too low');
        balances[dead] += toBurn;
        emit Transfer(msg.sender, dead, toBurn);
        balances[taxWallet] += toTax;
        emit Transfer(msg.sender, taxWallet, toTax);
        balances[to] += value;
        balances[msg.sender] -= total;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        uint toBurn = value / 100;
        uint toTax = value / 50;
        uint total = value + toTax + toBurn;
        require(balanceOf(from) >= total, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}