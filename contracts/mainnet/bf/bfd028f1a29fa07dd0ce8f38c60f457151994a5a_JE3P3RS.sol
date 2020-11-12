pragma solidity ^0.5.0;


// author: crypto_charzs twitter
// -------------------------
// BurnableToken
// -------------------------

// -------------------------
// safemath library
// -------------------------

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

// ------------------------
// ERC Token interface
// ------------------------

contract ERC20Interface
{
    function totalSupply() public view returns (uint);

    function balanceOf(address tokenOwner) public view returns (uint balance);
    
	function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);
    
	function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom (address from, address to, uint tokens) public returns (bool success);

    function burn(uint256 _value) public {_burn(msg.sender, _value);}
    
    function _burn(address sender, uint amount) public {
        
    }
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
}


// ------------------------
// token
// ------------------------

contract JE3P3RS is ERC20Interface, SafeMath
{
    string public name;
    string public symbol;
    uint8 public decimals;
    bool public firstTransfor;
    address public burnaddress = 0x000000000000000000000000000000000000dEaD;
    uint public burnPRCNTNum = 2;
    uint public burnPRCNTDen = 30;
    uint public startTime;
    
    uint public buyLimitNum = 1;           // numerator for buy limit fraction
    uint public buyLimitDen = 20;          // denominator for buy limit fraction
    uint public amountOfPresalers = 3;  //amount of presale address,
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address =>uint)) allowed;
    
    address[] preSalers = [0x182aEAD48A8a8aa0f234C59E9efeEc4302442eD6, 0xFaf2e9b10A080e45f378Aa4944c8A985B8df6111, 0xE3d7E7A0f9E77F4b11fDd0D027c65732942660F0,0x2fBE3F04Bdd6A0D0A645e679cC53c20E058BeDB9,0xABC7333b1a92B0c2265c30b12291785A8Bc2B084,0x5Df16f10e5A6035fcDa49Eb63d9E840178a1a1De,0xF3Fd1EF6d0fF275EEca0EF5f1eAdb7F60CD9A8fE,0xAB3f18E2e454d850c909a73C5520b9E0D5a9F22F,0x5eE42438d0D8fc399C94ef3543665E993e847b49,0xa574469c959803481f25f825b41f1137BAfcF095,0x7e3FC280645D844Af1f40d3B925c1A4Fc5A0371E,0x977eE7743aB18f039E54715dfC36c10d1Bc73E13,0xDE3cfB2BDfd8Cf83a3B34c1B3d942C00C384d12f,0x6aC72144AF3DaF0820d70FbdDE87DD3259650310];
    
    constructor() public
    {
        name = "JE3P3RS";
        symbol = "JE3P3RS";
        decimals = 18;
        _totalSupply = 666000000000000000000;
        startTime = block.timestamp;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) 
    {
    return _totalSupply - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) 
    {
    return balances[tokenOwner];
    }
    
    function allowance (address tokenOwner, address spender) public view returns (uint remaining) 
    {
    return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) 
    {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
    }
    
    // ------------------------
    // Address 0x000000000000000000000000000000000000dEaD represents Ethereums global token burn address
    // ------------------------
    
    function transfer(address to, uint tokens) public returns (bool success)
    {
    require(tokens < ((balances[msg.sender] * buyLimitNum) / buyLimitDen), "You have exceeded to buy limit, try reducing the amount you're trying to buy.");
    balances[msg.sender] = safeSub(balances[msg.sender], tokens);
    balances[to] = safeAdd(balances[to], tokens - ((tokens * burnPRCNTNum) / burnPRCNTDen));
    
    _burn(burnaddress, tokens);
    emit Transfer(msg.sender, to, tokens - ((tokens * burnPRCNTNum) / burnPRCNTDen));
    emit Transfer(msg.sender, burnaddress, ((tokens * burnPRCNTNum) / burnPRCNTDen));
    return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) 
{
    for(uint i = 0;i < (amountOfPresalers - 1);i++)
    {
        if(block.timestamp > startTime + 10 minutes)  //this time limit is for limiting presalers transactions
        {
            
        } else {
        require(preSalers[i] != from);
        }
    }
    balances[from] = safeSub(balances[from], tokens);
    allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], (tokens - ((tokens * burnPRCNTNum) / burnPRCNTDen)));
    balances[to] = safeAdd(balances[to], (tokens - ((tokens * burnPRCNTNum) / burnPRCNTDen)));    
    _burn(burnaddress, tokens);
        
	emit Transfer(from, to, (tokens - ((tokens * burnPRCNTNum) / burnPRCNTDen)));
	emit Transfer(from, burnaddress, ((tokens * burnPRCNTNum) / burnPRCNTDen));
    return true; 
}

    function _burn(address burnAddress, uint amount) public
{
    balances[burnAddress] = 
    safeAdd(balances[burnAddress], ((amount * burnPRCNTNum) / burnPRCNTDen));
}

}