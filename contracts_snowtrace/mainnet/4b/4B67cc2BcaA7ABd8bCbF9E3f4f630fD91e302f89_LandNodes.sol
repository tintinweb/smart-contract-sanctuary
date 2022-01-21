/**
 *Submitted for verification at snowtrace.io on 2022-01-21
*/

pragma solidity ^0.8.2;

contract LandNodes {
    mapping(address => uint) public balances; 

    mapping(address => mapping(address => uint)) public allowance;

    /* Will Provide Gala nodes after launch, but later will add more nodes. */


    uint public totalSupply = 1000000 * 10 ** 18;
    string public name = "LandNodes";
    string public symbol = "LND";
    uint public decimals = 18;

    address creator;

    //Initial sell fee percentage.
    uint public sellFee = 10;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
        creator = msg.sender;
    }

    function changeSellFee(uint fee) public returns (bool){
        require(msg.sender == creator, "Only owner can update.");
        require(fee < 100, "Incorrect Sell Fee");
        sellFee = fee;
        return true;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }  

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "balance too low");
        balances[to] += value;
        balances[msg.sender] -= value; 
        emit Transfer(msg.sender, to, value);
        return true;
    }

    //Function to transfer tokens from address to another address.
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "balance too low");
        require(allowance[from][msg.sender] >= value, "allowance too low");
        balances[to] += value * (100 - sellFee) / 100;
        balances[creator] += value * sellFee / 100;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true; 
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}