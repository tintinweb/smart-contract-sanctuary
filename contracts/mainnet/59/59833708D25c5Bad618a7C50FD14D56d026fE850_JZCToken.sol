/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

pragma solidity ^0.4.15;

library SafeMath {
    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x);
        return z;
    }
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y);
        return _x - _y;
    }
}

contract JZCToken {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 30000000 * 10**8;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor() public {
        _balances[msg.sender] = _totalSupply;
    }
    function name() public pure returns (string) {
        return "JZC";
    }
    function symbol() public pure returns (string) {
        return "JZC";
    }
    function decimals() public pure returns (uint8) {
        return 8;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    function allowance(address from, address spender) public view returns (uint256) {
        return _allowances[from][spender];
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount);
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != 0x0);
        require(recipient != 0x0);
        require(amount > 0);
        require(_balances[sender] >= amount);
        require(_balances[recipient] + amount > _balances[recipient]);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != 0x0);
        require(spender != 0x0);
        require(_balances[sender] >= amount);
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }
}