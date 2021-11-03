/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

pragma solidity ^0.4.26;


contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract Owned {
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


contract NvirWorldToken is Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "Nvir";
        name = "NvirWorld";
        decimals = 18;
        _totalSupply = 10700000000000000000000000000;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    function totalSupply() external constant returns (uint256) {
        return _totalSupply  - balances[address(0)];
    }


    function balanceOf(address tokenOwner) external constant returns (uint256 balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint256 tokens) external returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint256 tokens) external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint256 tokens) external returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    function allowance(address tokenOwner, address spender) external constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint256 tokens, bytes data) external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    function () external payable {
        revert();
    }


    function transferAnyERC20Token(uint256 tokens) external onlyOwner returns (bool success) {
        return this.transfer(owner, tokens);
    }
}