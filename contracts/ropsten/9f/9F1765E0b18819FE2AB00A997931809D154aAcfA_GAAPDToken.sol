/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GAAPDToken is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply = 10000000000;
    string private _name;
    string private _symbol;
    
    constructor() {
        _name = "GAAPDToken1";
        _symbol = "GAAPD1"; 
        _balances[msg.sender] = _totalSupply;
    }

    function name() public view returns (string memory) {
        return _name;
    } 

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns(uint8) {
        return 6;
    }

    function balanceOf(address account) public override view returns(uint256) {
        return _balances[account];
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

         _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
        
    }

    function transfer(address to, uint256 amount) public override returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns(uint256) {
        return _allowances[owner][spender];
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns(bool) {
        _transfer(from, to, amount);
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

         _approve(from, msg.sender, currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);


        return true;
    }


}