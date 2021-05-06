/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

/* 
--------------------------

fomoswap.on.fleek.co
Where apes are together strong

You can directly buy with 99% slippage, without a slow interface like Uniswap / Pancake.
Ethereum version has been used alot already!

Check the transactions of the contract:
https://etherscan.io/address/0x601ce3bb299e4ee04218fdbcd5660d35f777760b

Be first be early, get the most profit!

Working on BSC (new!) & ETH.

Upcoming: 
Bytecode Contract published on ETH (maybe BSC), and displayed on the site (see the most potential)
Multibuys (for limit tokens ;-))

If you wanna check out good projects:
$munch
$pepelon -> like wallstreetbets pepelon.finance (JK i'm shilling my bags)


FOMOSWAP WILL NOT HAVE A TOKEN IN THE FORSEEABLE FUTURE, THIS IS GUERILLA MARKETING!

There is no TG / Discord yet, maybe the community will make one.
The contract publisher of fomoswap will always be right, nobody can claim fomoswap is theirs (:

--------------------------
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


contract fomoswap_on_fleek_co is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "fomoswap.on.fleek.co";
        symbol = "FOMOSWAP";
        decimals = 9;
        _totalSupply = 1;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
        
    }
}