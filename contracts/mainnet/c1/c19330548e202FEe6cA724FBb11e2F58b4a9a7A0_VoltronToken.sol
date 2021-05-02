/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VoltronToken {
  
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    event Transfer(address indexed owner, address indexed recipient, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
      address pink_address,
      address black_address,
      address red_address,
      address blue_address,
      address green_address,
      address yellow_address
    ) {
        _balances[pink_address] = 1000000000000000000000000000;
        _balances[black_address] = 1000000000000000000000000000;
        _balances[red_address] = 1000000000000000000000000000;
        _balances[blue_address] = 1000000000000000000000000000;
        _balances[green_address] = 1000000000000000000000000000;
        _balances[yellow_address] = 1000000000000000000000000000;
        emit Transfer(address(0), pink_address, 1000000000000000000000000000);
        emit Transfer(address(0), black_address, 1000000000000000000000000000);
        emit Transfer(address(0), red_address, 1000000000000000000000000000);
        emit Transfer(address(0), blue_address, 1000000000000000000000000000);
        emit Transfer(address(0), green_address, 1000000000000000000000000000);
        emit Transfer(address(0), yellow_address, 1000000000000000000000000000);
    }

    function name() public pure returns (string memory) {
        return "VoltronToken";
    }

    function symbol() public pure returns (string memory) {
        return "VTN";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return 6000000000000000000000000000;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }    
    
    function transfer(address recipient, uint256 amount) public returns (bool) {  
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // msg.sender = (third-party) spender
    function transferFrom(address owner, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowances[owner][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");        
        _transfer(owner, recipient, amount);
        _approve(owner, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address owner, address recipient, uint256 amount) internal {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 ownerBalance = _balances[owner];
        require(ownerBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[owner] = ownerBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(owner, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}