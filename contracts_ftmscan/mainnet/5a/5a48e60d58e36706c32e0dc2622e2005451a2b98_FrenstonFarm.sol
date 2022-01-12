/**
 *Submitted for verification at FtmScan.com on 2022-01-12
*/

// Hello Frens, welcome to the start of Frensland.
/**

  _____    ____    U _____ u _   _    ____     _____   U  ___ u  _   _     
 |" ___|U |  _"\ u \| ___"|/| \ |"|  / __"| u |_ " _|   \/"_ \/ | \ |"|    
U| |_  u \| |_) |/  |  _|" <|  \| |><\___ \/    | |     | | | |<|  \| |>   
\|  _|/   |  _ <    | |___ U| |\  |u u___) |   /| |\.-,_| |_| |U| |\  |u   
 |_|      |_| \_\   |_____| |_| \_|  |____/>> u |_|U \_)-\___/  |_| \_|    
 )(\\,-   //   \\_  <<   >> ||   \\,-.)(  (__)_// \\_     \\    ||   \\,-. 
(__)(_/  (__)  (__)(__) (__)(_")  (_/(__)    (__) (__)   (__)   (_")  (_/  


**/
pragma solidity ^0.4.26;
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
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract FrenstonFarm is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    constructor() public {
        symbol = "CROPS";
        name = "Frenston Farm";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[0x335B7B22ff1deDD32B9689B97f904104695C3d65] = _totalSupply;
        emit Transfer(address(0), 0x335B7B22ff1deDD32B9689B97f904104695C3d65, _totalSupply);
    }
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
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