/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

pragma solidity 0.8.0;

contract SimpleErc20Token{
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor() {
        symbol = "Jack";
        name = "Jack Magic Token";
        decimals = 18;
        totalSupply = 1000000000000000000000000000;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[receiver] = balances[receiver] + tokens;
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address sender, address receiver, uint tokens) public returns (bool success) {
        balances[sender] = balances[sender] - tokens;
        allowed[sender][msg.sender] = allowed[sender][msg.sender] - tokens;
        balances[receiver] = balances[receiver] + tokens;
        emit Transfer(sender, receiver, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}