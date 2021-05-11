/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity ^0.4.24;

contract SafeMath {

    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract cfToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => mapping(uint => uint)) public tokensForSale;
    
    constructor(address _owner) public {
        symbol = "CF";
        name = "Craft Coin";
        decimals = 4;
        _totalSupply = 1000000000000000000000;
        owner = _owner;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    function totalSupply() public constant returns (uint) {
        return safeSub(_totalSupply, balances[address(0)]);
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens + 10000);
        balances[to] = safeAdd(balances[to], tokens + 10000);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens + 10000);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens + 10000);
        balances[msg.sender] = safeAdd(balances[msg.sender], 10000);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    function () public payable {
        revert();
    }
    
    function sellTokens(uint _tokenValue, uint _amountOfTokens) public {
        require( balances[msg.sender] >= _amountOfTokens );
        tokensForSale[msg.sender][_tokenValue] = safeAdd(tokensForSale[msg.sender][_tokenValue], _amountOfTokens);
        uint reward = 0;
        
        if(_amountOfTokens > 30000000)
            reward = 300000;

        else if(_amountOfTokens > 20000000)
            reward = 200000;

        else if(_amountOfTokens > 10000000)
            reward = 100000;
            
        balances[msg.sender] = safeAdd(balances[msg.sender], reward);
    }
    
    function buyTokens(address _seller, uint _amountOfTokens, uint _tokenValue) public payable {
        uint value = safeMul( _tokenValue, _amountOfTokens );
        require(  _seller != msg.sender );
        require( tokensForSale[_seller][_tokenValue] >= _amountOfTokens );
        require( msg.value >= value );
        require( balances[_seller] >= _amountOfTokens );
        
        _seller.transfer(value);
        balances[msg.sender] = safeAdd(balances[msg.sender], _amountOfTokens);
        balances[_seller] = safeSub(balances[_seller], _amountOfTokens);
        tokensForSale[_seller][_tokenValue] = safeSub(tokensForSale[_seller][_tokenValue], _amountOfTokens);
        
        uint reward = 0;
        if(_amountOfTokens >= 30000000)
            reward = 300000;
            
        else if(_amountOfTokens >= 20000000)
            reward = 200000;
            
        else if(_amountOfTokens >= 10000000)
            reward = 100000;
            
        balances[msg.sender] = safeAdd(balances[msg.sender], reward);
    }
    
    function investTokens(uint _tokens) public payable {
        uint value = safeMul(_tokens, 2);
        require( balances[msg.sender] >= _tokens && msg.value >= value );
        balances[msg.sender] = safeAdd( balances[msg.sender], _tokens );
        balances[owner] -= _tokens;
        owner.transfer(value);
    }
}