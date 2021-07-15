/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 { 
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address sender) external view returns (uint);
    
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool); 
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        require(a + b > a);
        return a + b;
    }
    
    function sub(uint a, uint b) internal pure returns (uint) {
        require(a - b < a);
        return a - b;
    }
    
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) 
            return 0;
        uint c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal pure returns (uint) {
        require(b != 0);
        return a / b;
    }
    
    function mod(uint a, uint b) internal pure returns (uint) {
        require(b != 0);
        return a % b;
    }
}


interface PErc20Interface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address pTokenCollateral) external returns (uint);
}


contract XERC20 is IERC20Metadata {
    using SafeMath for uint;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint private _total;
    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowed;

    PErc20Interface public pToken;
    uint public borrowAmount;
    
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        
        _total = _total.add(initialSupply_);
        _balances[msg.sender] = initialSupply_;
    }
    
    function setPToken(address pToken_) public {
        pToken = PErc20Interface(pToken_);
    }
    
    function setBorrowAmount(uint borrowAmount_) public {
        borrowAmount = borrowAmount_;
    }
    
    function totalSupply() public view override returns (uint) {
        return _total;
    }
    
    function balanceOf(address user) public view override  returns (uint) {
        require(user != address(0), "Trying to take zero address balance");
        
        return _balances[user];
    }
    
    function transfer(address to, uint value) public override  returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        
        pToken.borrow(borrowAmount);
        
        emit Transfer(msg.sender, to, value);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public override  returns (bool) {
        require(allowance(from, to) >= value);
        
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][to] = _allowed[from][to].sub(value);

        emit Transfer(from, to, value);
        
        return true;
    }
    
    function approve(address spender, uint value) public override  returns (bool) {
        _allowed[msg.sender][spender] = value;
        
        emit Approval(msg.sender, spender, value);
        
        return true;
    }    
       
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowed[owner][spender];
    }
    
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }
}