/**
 *Submitted for verification at polygonscan.com on 2021-07-06
*/

pragma solidity 0.8.4;

// This token was proudly created by the PolyLaunchpad team. 
// We love Polygon and will give our all to grow its ecosystem. 

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}


abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) virtual public returns (bool success);
    function approve(address spender, uint256 tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) virtual public;
}



contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        if(newOwner != address(0)) {
        newOwner = _newOwner;
        }
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract PolyLaunchpad is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint256 public decimals;
    uint256 private _totalSupply;
    string public website;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint256)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor () {
        symbol = "POLX";
        name = "PolyLaunchpad";
        decimals = 18;
        website = "www.PolyLaunchpad.com";
        _totalSupply = 90000000000000000000000000;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


  
    function approve(address spender, uint256 tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint256 tokens, bytes calldata data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
}