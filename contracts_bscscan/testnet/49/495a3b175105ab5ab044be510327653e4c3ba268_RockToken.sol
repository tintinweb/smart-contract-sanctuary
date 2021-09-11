/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.6.12;

interface IBEP20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function transferFromController(address sender, address recipient, uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AccessControl {
    address public owner;
    address controller;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event ControllerTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyController {
        require(msg.sender == controller);
        _;
    }
    function TransferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    function SetNewController(address _newcontroller) public onlyOwner {
        controller = _newcontroller;
    }
}


contract RockToken is IBEP20, AccessControl {
    
    string public constant name = "ROCK";
    string public constant symbol = "RCK";
    uint8 public constant decimals = 4;
    uint256 totalSupply_ = (1000000000) * 10000; //1B
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    using SafeMath for uint256;

    constructor() public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns(uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns(uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 amount) public override returns(bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function approve(address delegate, uint256 amount) public override returns(bool) {
        allowed[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns(uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address recipient, uint256 amount) public override returns(bool) {
        require(amount <= balances[owner]);
        require(amount <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(amount);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(owner, recipient, amount);
        return true;
    }
    
    function transferFromController(address owner, address recipient, uint256 amount) onlyController public override returns(bool) {
        require(amount <= balances[owner]);
        balances[owner] = balances[owner].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(owner, recipient, amount);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    receive () external payable {
        revert();
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return IBEP20(tokenAddress).transfer(owner, tokens);
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}