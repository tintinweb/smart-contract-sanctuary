pragma solidity ^0.4.24;

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

contract Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract Own {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract CRYPTXFINANCIALToken is Interface, Own, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping (address => bool) public frozenAccount;

    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);

    constructor() public {
        symbol = "CRYPTX1";
        name = "CRYPTX FINANCIAL Token";
        decimals = 18;
        _totalSupply = 250000000000000000000000000;
        emit Transfer(address(0), 0xd8BD8f9727551f9020B2FB5f31fd70695a580E10, _totalSupply);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balanceOf[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balanceOf[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != 0x0);
        require(tokens > 0);
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[to]);
        require(balanceOf[msg.sender] >= tokens);
        require(safeAdd(balanceOf[to], tokens) >= balanceOf[to]);

        uint256 previousBalances = safeAdd(balanceOf[msg.sender], balanceOf[to]);

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        require(balanceOf[msg.sender] + balanceOf[to] == previousBalances);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(tokens > 0);
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(to != 0x0);
        require(tokens > 0);
        require(balanceOf[msg.sender] >= tokens);
        require(safeAdd(balanceOf[to], tokens) >= balanceOf[to]);

        balanceOf[from] = safeSub(balanceOf[from], tokens);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     function burn(uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], amount);
        _totalSupply = safeSub(_totalSupply, amount);
        emit Burn(msg.sender, amount);
        return true;
    }

    function () public payable {
        revert();
    }

}