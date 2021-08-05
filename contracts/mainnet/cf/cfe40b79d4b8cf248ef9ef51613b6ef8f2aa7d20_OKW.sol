/**
 *Submitted for verification at Etherscan.io on 2020-07-16
*/

/* What is Oberkommando Der Wehrmacht (OKW)?
OKW was the High Command of the Wehrmacht of Nazi Germany. Created in 1938, the OKW replaced the Reich War Ministry
and had nominal oversight over the German Army, the Kriegsmarine, and the Luftwaffe.  OKW was part
of Hitler's brilliant grand design of decentralizing the Wehrmacht to prevent military coups and betrayals. This domineering power solidified Hitler's ultimate power - Through decentralization.
The OKW platform operates similarly - By decentralizing the Ethereum platform, white nationalists and
imperialist egoists such as us are prevented from being further oppressed by the globo-homo left wing satanic agenda.
This is exactly what Hitler wanted, now sublimated on the Ethereum platform.
It is with the same conviction that the OKW team and I stand before you. 
This begins the struggle, first for the soul of White people, and then, on beyond this server, forever more and more followers.
We have no more to give than the faith that if anyone pursues a righteous goal with unchanging and undisturbed loyalty and never lets himself be diverted from it, but puts everything into it, 
then others will be redeemed in the light of our faith.
That from OKW an ever stronger faith must gradually radiate to every white people, and that out of this host the worthiest part of the whole people will one day finally find themselves together.
We promise you faith and the continued existence of the white race. */

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


contract OKW is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public {
        name = "OBERKOMMANDO DER WEHRMACHT";
        symbol = "OKW";
        decimals = 18; //preferrably 18
        _totalSupply = 1488000000000000000000000000;   // 24 decimals 
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
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