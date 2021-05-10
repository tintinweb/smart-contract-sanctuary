/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.8.1;
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
  
    
}
abstract contract ERC20Interface {

     function totalSupply() 
        virtual
		public 
		view 
		returns (uint);

    function balanceOf(address tokenOwner) 
        virtual
		public 
		view 
		returns (uint balance);
    
	function allowance(address tokenOwner, address spender) 
		virtual
		public 
		view 
		returns (uint remaining);

    function transfer(address to, uint tokens)
        virtual
        public 
		returns (bool success);
    
	function approve(address spender, uint tokens) 	
	    virtual
	    public 
		returns (bool success);

    function transferFrom(address from, address to, uint tokens)
		virtual
		public 
		returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract EwanCoin is ERC20Interface,SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    uint256 public _totalSupply;
    address public owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    constructor() public {
        name = "EwanCoin";
        symbol = "EFC";
        decimals = 18;
        _totalSupply = 3333333333333333333333333;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0),msg.sender,_totalSupply);
    }
    function totalSupply() public override view returns (uint supply) {
        return 3333333;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
}