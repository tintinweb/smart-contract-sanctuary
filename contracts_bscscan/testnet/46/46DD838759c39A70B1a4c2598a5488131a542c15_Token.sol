/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

pragma solidity ^0.8.2;

contract Token{

    // creating the public variables balances, totalsupply, name,symbol,decimal
    mapping(address => uint) public balances;

    // mapping of address for dApp to access holder token
    mapping(address => mapping(address => uint)) public allowance;

    uint public totalSupply = 1000000 * 10 ** 18;
    string public name = "Shiroi";
    string public symbol = "SHI";
    uint public decimals = 18;

    // emitted event for smart contract
    event Transfer(address indexed from, address indexed to, uint value);

    // Approval event
    event Approval(address indexed owner, address indexed spender, uint value);

    // sending the token to the deploy
    constructor(){
        balances[msg.sender] = totalSupply;
    }

    // reading the balance of any address that hold this tokens
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }

    // function to transfer from address to another
    function transfer(address to, uint value)public returns(bool){
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value; 
        emit Transfer(msg.sender, to, value);
        return true;
    }

    // Delegated tranfer from one address to another
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value)public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}