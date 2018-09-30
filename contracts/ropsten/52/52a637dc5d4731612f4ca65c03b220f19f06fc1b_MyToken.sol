pragma solidity ^0.4.24;

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

contract MyToken is ERC20Interface {
    string public name;
    string public symbol;
    uint public decimals;
    uint _totalSupply;
    
    mapping (address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor(string tokenName, string tokenSymbol) public {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = 18;
        _totalSupply = 1000000 * 10**uint(decimals);
        balanceOf[msg.sender] = _totalSupply;
        //emit transfer(address(0), msg.sender, totalSupply);
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
    
    //allow sender to withdraw from your account
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    //transfer balance from owner account to another account
    function transfer(address to, uint tokens) public returns (bool success) {
        require (balanceOf[msg.sender] < tokens);
        balanceOf[msg.sender] -= tokens;
        balanceOf[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    //send tokens from address &#39;from&#39; to address &#39;to&#39;
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balanceOf[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balanceOf[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
    
    //returns amount of tokens aprroved by owner that can be transferred to spender
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balanceOf[tokenOwner];
    }
    
    
    //function getDecimals() public returns (uint) {
    //    return decimals;
    //}
    
    //function getName() public returns (string) {
    //    return name;
    //}
    
    //function getSymbol() public returns (string) {
    //   return symbol;
    //}
}