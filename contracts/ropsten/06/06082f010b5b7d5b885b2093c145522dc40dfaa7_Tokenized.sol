pragma solidity ^0.5.2;
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
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}
contract Tokenized {
    using SafeMath for uint;
    address public owner;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    constructor () public {
        owner = address(0);
        symbol = "ERC20 of Ether";
        name = "EoE";
        decimals = 18;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        if (to == address(this)) {
            msg.sender.transfer(tokens);
            _totalSupply = _totalSupply.sub(tokens);
            emit Transfer(msg.sender, address(0), tokens);
        } else {
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
        }
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        if (spender == address(this)) revert();
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
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    function () external payable {
        if (msg.value > 0) tokenize();
    }
    function tokenize() public payable {
        require(msg.value > 0);
        _totalSupply = _totalSupply.add(msg.value);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit Transfer(address(0), msg.sender, msg.value);
    }
}