/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external  view returns (uint remaining);
    function transfer(address to, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool success);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
    
}

abstract contract Ownable {
	
	address private owner;

	constructor() {
		owner = msg.sender;
	}
	
	function getOwner() public view returns (address) {
	    return owner;
	}

	modifier onlyOwner() {
        require(msg.sender == owner, "ERC20: permission denied");
        _;
    }

	function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        owner = newOwner;
        return true;
	}
}

abstract contract Fee is Ownable{
    
    uint256 private basicFee = 1;
    uint256 private maxFee = 0;
    
    constructor() {
        //basicFee = 1;
    }
    
    function addFee(uint256 fee) public onlyOwner returns (bool) {
        basicFee = basicFee + fee;
        return true;    
    }
    
    function getFee() public view returns (uint256) {
        return basicFee;
    }
    
    function setMaxFee(uint256 fee) public onlyOwner returns (bool) {
        maxFee = fee;
        return true;
    }
    
    function getMaxFee() public view returns (uint256) {
        return maxFee;
    }
    
}

contract OxCoinToken is IERC20, Ownable, Fee {
    
    string public name = "OxCoin Token";
    string public symbol = "OXC";
    uint8 public decimals = 8;
    uint256 private _totalSupply = 10 ** 10 * (10 ** 8);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        super.setMaxFee(10 ** decimals);
        balances[getOwner()] = _totalSupply;
        emit Transfer(address(0), getOwner(), _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function increaseSupply(uint256 amount) public onlyOwner returns (bool) {
        _totalSupply = _totalSupply + amount;
        balances[getOwner()] = balances[getOwner()] + amount;
        emit IncreasedSupply(getOwner(), amount);
        return true;
    }

    function balanceOf(address tokenOwner) public view override returns (uint256) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint256) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        uint256 fee = super.getFee() * amount / (10 ** decimals);
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount - fee;
        balances[getOwner()] = balances[getOwner()] + fee;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        uint256 fee = super.getFee() * amount / (10 ** decimals);
        balances[from] = balances[from] - amount;
        allowed[from][msg.sender] = allowed[from][msg.sender] - amount;
        balances[to] = balances[to] + amount - fee;
        balances[getOwner()] = balances[getOwner()] + fee;
        emit Transfer(from, to, amount);
        return true;
    }
    
    event IncreasedSupply(address owner, uint256 amount);
    
}