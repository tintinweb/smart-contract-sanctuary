/**
 *Submitted for verification at Etherscan.io on 2020-09-06
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-03
*/

pragma solidity >=0.4.22 <0.7.0;

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

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


contract DPerpetual is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    string perpfii7624ii;
    string perpfi4563iii;
    string perpfii45ii;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public {
        name = "perp.fi";
        symbol = "PERP";
        decimals = 18; //preferrably 18
        _totalSupply = 22462500  * 10 **18;   // 24 decimals 
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    
    string perpfii34i76323i;
    string perpfii5ii;

    string perpfi2345235yiii;string perp234fiiii;

    uint256 public _totalSupply;
    function allowance(address tokenOwner, address spender) virtual override public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) virtual override public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) virtual override public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
        string perpfiii23451i;string perpfii32ii;
    string perpfi567243iii;
    function transferFrom(address from, address to, uint tokens) virtual override public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function totalSupply() virtual override public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) virtual override public view returns (uint balance) {
        return balances[tokenOwner];
    }
    

}