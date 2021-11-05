// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20/ERC20.sol";

// ᶘ ◕ᴥ◕ᶅ CatToken
contract CatToken is ERC20 {
    // ᶘ ◕ᴥ◕ᶅ constructor
    constructor() ERC20("CatToken", "CAT", 2) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";

// ᶘ ◕ᴥ◕ᶅ ERC20
contract ERC20 is IERC20 {
    // ᶘ ◕ᴥ◕ᶅ mapping( owner => balance)
    mapping(address => uint256) _balances;
    // ᶘ ◕ᴥ◕ᶅ mapping( owner => mapping(spender => amount))
    mapping(address => mapping(address => uint256)) private _allowances;

    // ᶘ ◕ᴥ◕ᶅ IERC20.name
    string public override name;
    // ᶘ ◕ᴥ◕ᶅ IERC20-symbol
    string public override symbol;
    // ᶘ ◕ᴥ◕ᶅ IERC20.decimals
    uint8 public override decimals;
    // ᶘ ◕ᴥ◕ᶅ IERC20.totalSupply
    uint256 public override totalSupply;

    // ᶘ ◕ᴥ◕ᶅ constructor
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // ᶘ ◕ᴥ◕ᶅ IERC20.balanceOf
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        return _balances[_owner];
    }

    // ᶘ ◕ᴥ◕ᶅ IERC20.transfer
    function transfer(address _to, uint256 _amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    // ᶘ ◕ᴥ◕ᶅ IERC20.transferFrom
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowances[_from][msg.sender];
        require(
            currentAllowance >= _amount,
            "ERC20: transfer amount exceeds allowance"
        );

        unchecked {
            _approve(_from, msg.sender, currentAllowance - _amount);
        }

        _transfer(msg.sender, _to, _amount);

        return true;
    }

    // ᶘ ◕ᴥ◕ᶅ IERC20.approve
    function approve(address _spender, uint256 _amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    // ᶘ ◕ᴥ◕ᶅ IERC20.allowance
    function allowance(address _owner, address _spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    // ᶘ ◕ᴥ◕ᶅ internal._transfer
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(
            msg.sender == _from || _allowances[_from][msg.sender] >= _amount
        );

        uint256 fromBalance = _balances[_from];
        require(fromBalance >= _amount, "ERC20: INSUFFICIENT FUNDS");

        unchecked {
            fromBalance -= _amount;
        }
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);
    }

    // ᶘ ◕ᴥ◕ᶅ internal._approve
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        _allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    // ᶘ ◕ᴥ◕ᶅ
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // ᶘ ◕ᴥ◕ᶅ
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // ᶘ ◕ᴥ◕ᶅ
    function name() external view returns (string memory);

    // ᶘ ◕ᴥ◕ᶅ
    function symbol() external view returns (string memory);

    // ᶘ ◕ᴥ◕ᶅ
    function decimals() external view returns (uint8);

    // ᶘ ◕ᴥ◕ᶅ
    function totalSupply() external view returns (uint256);

    // ᶘ ◕ᴥ◕ᶅ
    function balanceOf(address _owner) external view returns (uint256 balance);

    // ᶘ ◕ᴥ◕ᶅ
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    // ᶘ ◕ᴥ◕ᶅ
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    // ᶘ ◕ᴥ◕ᶅ
    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    // ᶘ ◕ᴥ◕ᶅ
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}