/**
 *Submitted for verification at polygonscan.com on 2021-09-12
*/

pragma solidity ^0.4.24;
 
//Safe Math Interface
 
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
 
 
//ERC Token Standard #20 Interface
 
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
 
 
//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//Actual token contract
 
contract SAASToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public minelimit;
    uint public mined;
    uint public teamPart;
    uint public investPart;
    address public owner;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        symbol = "SAAS";
        name = "SAAS Token";
        decimals = 2;
        _totalSupply = 1500000000;
        minelimit = 2500000000;
        mined = 0;
        teamPart = 1000000000;
        investPart = 5000000000;
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function transferOwnership(address _owner) public returns (bool) {
		require(msg.sender==owner,"Only owner call this function");
		owner=_owner;
		return true;
	}
    
    function mine(address miner,uint tokens) public returns (bool success){
        require(msg.sender==owner,"Only owner can call this function");
        require(tokens<=minelimit,"Token quantity must be less then minelimit.");
        mined = mined + tokens;
        minelimit = minelimit - tokens;
        _totalSupply = _totalSupply + tokens;
        balances[miner] = safeAdd(balances[miner], tokens);
        emit Transfer( address(0x00), miner, tokens);
        return true;
    }
    
    function changeMineLimit(uint newLimit) public returns (bool success){
        require(msg.sender==owner,"Only owner can call this function");
        minelimit = newLimit;
        return true;
    }
    
    function unlockTeamCoins(uint tokens) public returns (bool success){
        require(msg.sender==owner,"Only owner can call this function");
        require(tokens<=teamPart,"Token quantity must be less then teamPart.");
        _totalSupply = _totalSupply + tokens;
        teamPart = teamPart - tokens;
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        emit Transfer( address(0x00), msg.sender, tokens);
        return true;
    }
    
    function changeTeamPart(uint newLimit) public returns (bool success){
        require(msg.sender==owner,"Only owner can call this function");
        teamPart = newLimit;
        return true;
    }
    
    function unlockInvestorsCoins(uint tokens) public returns (bool success){
        require(msg.sender==owner,"Only owner can call this function");
        require(tokens<=investPart,"Token quantity must be less then investPart.");
        _totalSupply = _totalSupply + tokens;
        investPart = investPart - tokens;
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        emit Transfer( address(0x00), msg.sender, tokens);
        return true;
    }
    
    function changeInvestPart(uint newLimit) public returns (bool success){
        require(msg.sender==owner,"Only owner can call this function");
        investPart = newLimit;
        return true;
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        require(tokens<=balances[msg.sender],"Not enough tokens to transfer.");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        require(tokens<=balances[msg.sender],"Not enough tokens to approve.");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokens<=balances[msg.sender],"Not enough tokens to transfer.");
        require(tokens<=allowed[from][msg.sender],"Not enough tokens approved to transfer.");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function burn(uint tokens) public returns (bool success){
        require(tokens<=balances[msg.sender],"Not enough tokens to burn.");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        _totalSupply =_totalSupply - tokens;
        return true;
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
}