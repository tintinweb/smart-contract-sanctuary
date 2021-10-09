/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
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


contract WHeC is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    uint256 public _totalSupply;
    address public owner;
    string public constant description = "PrivateA Heroes Chained Token Sale \n Private ICO tokens are issued as Wrapped HeC (WHeC) tokens which will be swapped one to one by the same amount of HeC tokens after the HeC token generation event.";
    string public constant website = "https://www.inventuna.com/game/heroes-chained-2";
    string public constant image = "https://tinypng.com/web/output/db5tw8zrgghr7fzj6j0pp6yg7yax49ky/Logo_HeC.png";
    
// ----------------------------------------------------------------------------
// Social Profiles
// Instagram: https://www.instagram.com/inventunagames
// Twitter:   https://twitter.com/Inventuna_Games
// Youtube:   https://www.youtube.com/channel/UCjBYy0kTNFsUP2wVxjPx8hw
// Facebook:  https://www.facebook.com/InventunaGames
// Linkedin:  https://www.linkedin.com/company/inventuna-games
// ----------------------------------------------------------------------------

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "Wrapped HeC";
        symbol = "WHeC";
        decimals = 0;
        _totalSupply = 3125000;
        owner = msg.sender;
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
    
    function destroySmartContract(address payable _to) public { 
        require(msg.sender == owner, "You are not the owner"); 
        selfdestruct(_to); 
        
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}