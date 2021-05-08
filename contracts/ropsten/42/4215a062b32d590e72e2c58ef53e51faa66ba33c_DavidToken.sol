/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

pragma solidity ^0.8.4;


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

// contract ERC20Interface {
//     function totalSupply() public returns (uint);
//     function balanceOf(address tokenOwner) public returns (uint balance);
//     function allowance(address tokenOwner, address spender) public returns (uint remaining);
//     function transfer(address to, uint tokens) public returns (bool success);
//     function approve(address spender, uint tokens) public returns (bool success);
//     function transferFrom(address from, address to, uint tokens) public returns (bool success);

//     event Transfer(address indexed from, address indexed to, uint tokens);
//     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
// }

contract DavidToken is SafeMath {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    address public owner;
    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    constructor() payable {
        owner = msg.sender;
        name = "David Token";
        symbol = "DTK";
        decimals = 2;
        totalSupply = 100000;
        balances[owner] = totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint) {
        return balances[account];
    }
    
	
	modifier onlyOwner() {
	    require(owner == msg.sender, "not owner!");
	    _;
	}
	
	function transfer(address _to, uint token) public onlyOwner returns (bool) {
	    require(balances[msg.sender] > token);
	    require(token > 0);
	    balances[msg.sender] = safeSub(balances[msg.sender], token);
        balances[_to] = safeAdd(balances[msg.sender], token);
        emit Transfer(msg.sender, _to, token);
        
        return true;
	}
	
	function transferFrom(address _from, address _to, uint256 tokens) public returns (bool) {
	    require(balances[_from] >= tokens);
	    require(allowed[_from][msg.sender] >= tokens);
        balances[_to] = safeSub(balances[msg.sender], tokens);
        balances[_from] = safeAdd(balances[_to], tokens);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], tokens);
        emit Transfer(_from, _to, tokens);
        
        return true;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint){
	    return allowed[_owner][_spender];
    }

}