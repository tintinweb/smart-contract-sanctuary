/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity ^0.5.0;

//Interface for ERC20 Token
contract TokenInterface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

//Safe Math Library for 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
    }
    
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b; 
        require(a == 0 || c / a == b);
    }
    
    function safeDiv(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}

//NordToken inheriting TokenInterface and SafeMath Contracts
contract NordToken is TokenInterface, SafeMath {
    string public name; //Name of the Token
    string public symbol; //Symbol for the Token
    uint8 public decimals; //Decimal Precision with Which Tokens can be Transferred
    uint256 public total_Supply; //Total Supply of the Token
    
    mapping(address => uint) balances; //Mapping to Store Balance of All Addresses holding the Token
    mapping(address => mapping(address => uint)) allowed;

     //Constructor is triggered when the Smart Contract is Deployed and the total supply of tokens are send to the Account that created the Smart Contract
    constructor() public {
        name = "NordToken";
        symbol = "NTKN";
        decimals = 10;
        total_Supply = 100000000000000000;

        balances[msg.sender] = total_Supply;
        emit Transfer(address(0), msg.sender, total_Supply);
    }
    
    //Function Returning Total Tokens in Supply
    function totalSupply() public view returns (uint) {
        return total_Supply;
    }

    //Function Returning Tokens held by Address
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    //
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}