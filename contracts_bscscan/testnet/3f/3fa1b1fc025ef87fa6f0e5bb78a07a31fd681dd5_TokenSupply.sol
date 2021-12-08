/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

interface Token {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);
}

contract StandardToken is Token {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 public totalSupply;
    uint256 private maxSupply;
    string public name;
    uint8 public decimals;
    string public symbol;
    string public _v;

    constructor(
        string memory name_,
        uint8 decimals_,
        string memory symbol_,
        uint256 supply,
        uint256 maxSupply_,
        string memory v
    ) {
        require(
            maxSupply <= 0 || supply <= maxSupply,
            "Total supply is greater max supply."
        );
        maxSupply = maxSupply_;
        totalSupply = supply;
        name = name_;
        decimals = decimals_;
        symbol = symbol_;
        balances[msg.sender] = supply;
        _v = v;
    }

    // function name() public view returns (string memory) {
    //     return _name;
    // }

    // function decimals() public view returns (uint8) {
    //     return _decimals;
    // }

    // function symbol() public view returns (string memory) {
    //     return _symbol;
    // }

    // function totalSupply() public view override returns (uint256) {
    //     return _totalSupply;
    // }

    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool success)
    {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        if (
            balances[_from] >= _value &&
            allowed[_from][msg.sender] >= _value &&
            _value > 0
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function mint(address account, uint256 amount)
        public
        returns (bool success)
    {
        require(account != address(0), "ERC20: mint to the zero address");
        require(
            maxSupply <= 0 || (totalSupply + amount) <= maxSupply,
            "Total supply is greater max supply."
        );

        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);

        return true;
    }

    function burn(address account, uint256 amount)
        public
        returns (bool success)
    {
        require(account != address(0), "ERC20: mint from the zero address");

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        totalSupply -= amount;
        balances[account] = accountBalance - amount;
        emit Transfer(account, address(0), amount);

        return true;
    }
}

// token supply cố định
contract TokenSupply is StandardToken {
    fallback() external {}

    constructor()
        StandardToken("Test Token 1", 18, "TS1", 10**9 * 10**18, 10**9 * 10**18, "V1.0")
    {}

    function approveAndCall(address _spender, uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
}