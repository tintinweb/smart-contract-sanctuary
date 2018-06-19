pragma solidity ^0.4.23;

contract EthMash {

    address public owner;
    mapping (address => uint) public balances;

    address[6] public leaders;
    uint[6] public buyins;

    event Challenge(uint buyin, uint draw, address challenger, address defender, bool success);
    event Withdraw(address player, uint amount);

    constructor() public {
        owner = msg.sender;
        leaders = [owner, owner, owner, owner, owner, owner];
        buyins = [20 finney, 60 finney, 100 finney, 200 finney, 600 finney, 1000 finney];   
    }

    function publicGetBalance(address player) view public returns (uint) {
        return balances[player];
    }

    function publicGetState() view public returns (address[6]) {
        return leaders;
    }

    function ownerChange(uint index, address holder) public {
        require(msg.sender == owner);
        require(leaders[index] == owner);
        leaders[index] = holder;
    }

    function userWithdraw() public {
        require(balances[msg.sender] > 0);
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        emit Withdraw(msg.sender, amount);
        msg.sender.transfer(amount);
    }

    function userChallenge(uint index) public payable {
        require(index >= 0 && index < 6);
        require(msg.value == buyins[index]);
        
        uint random = ((uint(blockhash(block.number - 1)) + uint(leaders[index]) + uint(msg.sender)) % 100) + 1;
        
        if (random > 50) {
            emit Challenge(buyins[index], random, msg.sender, leaders[index], true);
            balances[msg.sender] += buyins[index];
            leaders[index] = msg.sender;
        } else {
            emit Challenge(buyins[index], random, msg.sender, leaders[index], false);
            balances[leaders[index]] += (buyins[index] * 95 / 100);
            balances[owner] += (buyins[index] * 5 / 100);
        }
    }
}