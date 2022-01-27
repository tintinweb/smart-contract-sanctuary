/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract ERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint256 private _decimals = 18;
    address private _minter;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 1000; // no initial mint needed
        _minter = msg.sender;

        _balances[_minter] = _totalSupply;
        emit Transfer(address(0), _minter, _totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == _minter, "Access resticted to only owner");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_balances[_from] > _value, "Sender balance is too low");
        require(
            _allowances[_from][msg.sender] >= _value,
            "Receipient allowance is below the value needed"
        );

        _allowances[_from][msg.sender] -= _value;
        _balances[_from] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(
            _balances[msg.sender] >= _value,
            "Sender does not have enough funds"
        );
        require(_to != address(0), "Cannot send to zero address");

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function increaseAllowance(address spender, uint256 _addedValue)
        public
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + _addedValue
        );

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function mint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _balances[account] += amount;
        _totalSupply += amount;

        emit Transfer(address(0), account, amount);
        return true;
    }

    function burn(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _balances[account] >= amount,
            "The balance is less than burning amount"
        );

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);

        return true;
    }
}