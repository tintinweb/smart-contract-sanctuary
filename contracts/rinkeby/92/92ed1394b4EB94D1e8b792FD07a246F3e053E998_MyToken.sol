pragma solidity ^0.8.0;

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);

    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    
	function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);

    function transfer(address to, uint tokens) virtual public returns (bool success);
    
	function approve(address spender, uint tokens) virtual public returns (bool success);

    function transferFrom (address from, address to, uint tokens) virtual public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MyToken is ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    

    constructor() {
        name = "MyToken";
        symbol = "MT";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view override returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public override returns (bool success) {
        //balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[msg.sender] = balances[msg.sender] - tokens;
        //balances[to] = safeAdd(balances[to], tokens);
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        //balances[from] = safeSub(balances[from], tokens);
        balances[from] = balances[from] - tokens;
        //allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
        //balances[to] = safeAdd(balances[to], tokens);
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
}