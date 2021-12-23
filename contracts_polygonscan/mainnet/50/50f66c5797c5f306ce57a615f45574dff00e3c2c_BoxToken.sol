/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

// SPDX-License-Identifier: TokenBox
pragma solidity ^0.8.0;

contract BoxToken {
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor(){
        uint one = 1000000;
        totalSupply = one * 100000000;
        _balances[msg.sender] = one * (10000000-1000);//for master chef
        _balances[0xBD1ab0344c060C238FB8F4Bc32120cE5A5DC5FF7] = one * 90000000;//multisig
        _balances[0x7674bce4Ada3590Fe0F8b6a9E6CC43948c863D24] = one * 1000;//for first liquidity
        emit Transfer(address(0), 0xBD1ab0344c060C238FB8F4Bc32120cE5A5DC5FF7, one * 90000000);
        emit Transfer(address(0), 0x7674bce4Ada3590Fe0F8b6a9E6CC43948c863D24, one * 1000);
        emit Transfer(address(0), msg.sender, one * (10000000-1000));
    }
    function name() public pure returns (string memory) {
        return 'TokenBox Token';
    }
    function symbol() public pure returns (string memory) {
        return 'Box';
    }
    function decimals() public pure returns (uint8) {
        return 6;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}