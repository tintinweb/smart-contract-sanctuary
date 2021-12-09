/**
 *Submitted for verification at polygonscan.com on 2021-12-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256 totalSupply);

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

    function mint(address account, uint256 amount)
        external
        returns (bool);

    function burn(uint256 amount) 
        external
        returns (bool);
}

contract ERC20 is IERC20 {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;
    uint256 private _totalSupply;
    uint256 private _maxSupply;
    string private _v;

    constructor(
        string memory name_,
        uint8 decimals_,
        string memory symbol_,
        uint256 supply,
        uint256 maxSupply,
        string memory v
    ) {
        require(
            _maxSupply <= 0 || supply <= _maxSupply,
            "ERC20: Total supply is greater max supply."
        );
        _name = name_;
        _decimals = decimals_;
        _symbol = symbol_;
        _maxSupply = maxSupply;
        _totalSupply = supply;
        balances[msg.sender] = supply;
        _owner = msg.sender;
        _v = v;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

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

    function balanceOf(address account)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[account];
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

    function allowance(address account, address _spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[account][_spender];
    }

    function mint(address account, uint256 amount)
        public
        override
        returns (bool success)
    {
        require(msg.sender == _owner, "ERC20: you are not the owner");
        require(account != address(0), "ERC20: mint to the zero address");
        require(
            _maxSupply <= 0 || (_totalSupply + amount) <= _maxSupply,
            "Total supply is greater max supply."
        );

        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);

        return true;
    }

    function burn(uint256 amount)
        public
        override
        returns (bool success)
    {
        uint256 accountBalance = balances[msg.sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _totalSupply -= amount;
        balances[msg.sender] = accountBalance - amount;
        emit Transfer(msg.sender, address(0), amount);

        return true;
    }
}

// token supply cố định
// contract TokenSupply is ERC20 {
//     fallback() external {}

//     constructor()
//         ERC20("Test Token 1", 18, "TS3", 10**9 * 10**18, 10**9 * 10**18, "V1.0")
//     {}

//     function approveAndCall(address _spender, uint256 _value)
//         public
//         returns (bool)
//     {
//         allowed[msg.sender][_spender] = _value;
//         emit Approval(msg.sender, _spender, _value);

//         return true;
//     }
// }

// token mint và burn
// contract TokenMintBurn is ERC20 {
//     fallback() external {}

//     constructor() ERC20("Test Token 2", 18, "TS4", 1000 * 10**18, 0, "V1.0") {}

//     function approveAndCall(address _spender, uint256 _value)
//         public
//         returns (bool)
//     {
//         allowed[msg.sender][_spender] = _value;
//         emit Approval(msg.sender, _spender, _value);

//         return true;
//     }
// }

// token supply cố định
contract Token3 is ERC20 {
    fallback() external {}

    constructor()
        ERC20("Test Token 3", 18, "TS3", 1 * 10**18, 10**9 * 10**18, "V1.0")
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