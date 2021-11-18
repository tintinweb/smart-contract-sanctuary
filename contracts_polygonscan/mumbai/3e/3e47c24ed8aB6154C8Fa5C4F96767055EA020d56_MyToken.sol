/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;


interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // 发行数量
    function totalSupply() external view returns (uint256);

    // 账户金额查询
    function balanceOf(address owner) external view returns (uint256);

    // 向目标用户转账
    function transfer(address to, uint256 amount) external returns (bool);

    // 使用授权金额转账
    function transferFrom(address form, address to, uint256 amount) external returns (bool);

    // 授权信息查询
    function allowance(address form, address to) external view returns (uint256);

    // 当前用户授权给目标用户 to 指定金额 amount
    function approve(address to, uint256 amount) external returns (bool);

    // 广播交易信息
    event Transfer(address indexed from, address indexed to, uint256 amount);

    // 广播授权信息
    event Approval(address indexed from, address indexed to, uint256 amount);
}

// 0xdd0af31F552D7443ba11b0524b9E97422AEb0309
contract MyToken is IERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;


    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private _allowances;


    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address owner) public view virtual override returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _allowances[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }


    function approve(address to, uint256 amount) public virtual override returns (bool) {
        _allowances[msg.sender][to] = amount;

        emit Approval(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0));
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}