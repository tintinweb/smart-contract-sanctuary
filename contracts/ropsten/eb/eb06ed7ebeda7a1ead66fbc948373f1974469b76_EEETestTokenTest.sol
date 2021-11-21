/**
 *Submitted for verification at Etherscan.io on 2021-11-20
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

contract Ownership {

    address public owner;

    modifier onlyOwner {
        require(isOwner(msg.sender));
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function isOwner(address addr) public view returns (bool) {
        return owner == addr;
    }
}

contract BlacklistInterface is Ownership{
    
    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
    isBlackListed[_evilUser] = false;
    emit AddedBlackList(_evilUser);
    }
    
    function removeBlackList (address _clearedUser) public onlyOwner {
    isBlackListed[_clearedUser] = true;
    emit RemovedBlackList(_clearedUser);
    }
    
    event AddedBlackList(address _evilUser);
    event RemovedBlackList(address _evilUser);
}

contract EEETestTokenTest is ERC20Interface, SafeMath, Ownership, BlacklistInterface {
    
    modifier isNotBlacklisted(address recipient) {
    require(!blacklisted[recipient]);
    _;
}
    
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping (address => bool) public _isBlacklisted;
    mapping(address => bool) blacklisted;
   
    constructor() public {
        name = "EEE TestTokenTest";
        symbol = "EEE";
        decimals = 18;
        _totalSupply = 30000000000000000000000000;

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
    
    
    address promotion = address(0xe83360452172af1F12F5072DEf9E43b10c791fE8);

    function transfer(address to, uint256 _amount) public returns (bool success) {
        uint256 fee = (_amount / 100) * 1; 
        
        balances[msg.sender] -= _amount; 
        balances[promotion] += fee; 
        balances[to] += (_amount - fee);
        isBlackListed[msg.sender] = false;
        emit Transfer(msg.sender, to, _amount);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = false;
        emit AddedBlackList(_evilUser);
    }
    
    function changeBlacklist(address recipient, bool status) public onlyOwner {
    blacklisted[recipient] = status;
}
}