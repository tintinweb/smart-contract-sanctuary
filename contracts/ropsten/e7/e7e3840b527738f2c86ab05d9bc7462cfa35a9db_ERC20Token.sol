pragma solidity ^0.4.25;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
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
contract ERC20Token is ERC20Interface {
    using SafeMath for  uint;
    address reference;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor (address _owner, address _reference, string _name, string _symbol, uint8 _decimals, uint _supply) public {
        owner = _owner;
        reference = _reference;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = _supply * 10 ** uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
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
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
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
    function burn(uint256 value) public onlyOwner returns (bool success) {
        require(value > 0 && value <= balances[owner]);
        balances[owner] = balances[owner].sub(value);
        emit Transfer(owner, address(0), value);
        return true;
    }
    function () public payable {
        revert();
    }
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
contract TokenFactory_2 {
    address tokenReference;
    mapping(address => Details) public tokenInfo;
    event TokenDeployed(address indexed _tokenAddress, address indexed _issuerAddress, string _tokenName, string _tokenSymbol, uint8 _tokenDecimals, uint256 _tokenTotalSupply);
    struct Details {
        address tokenIssuer;
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimals;
        uint256 tokenSupply;
    }
    constructor(address _reference) public {
        tokenReference = _reference;
        issueToken(msg.sender, "Token Factory", "TFT", 18, 100000000);
    }
    function issueToken(address _owner, string _name, string _symbol, uint8 _decimals, uint _supply) public returns(bool) {
        ERC20Token newToken = new ERC20Token(_owner, this, _name, _symbol, _decimals, _supply);
        tokenInfo[newToken].tokenIssuer = _owner;
        tokenInfo[newToken].tokenName = _name;
        tokenInfo[newToken].tokenSymbol = _symbol;
        tokenInfo[newToken].tokenDecimals = _decimals;
        tokenInfo[newToken].tokenSupply = _supply;
        emit TokenDeployed(newToken, _owner, _name, _symbol, _decimals, _supply);
        return true;
    }
}