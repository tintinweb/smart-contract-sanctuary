// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

interface IERC20 {
  /** @dev Events */

  event Approval(address indexed account, address indexed trust, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /** @dev Views */

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function allowance(address account, address trust) external view returns (uint256);

  /** @dev Mutators */

  function approve(address trust, uint256 amount) external returns (bool);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "./interfaces/IERC20.sol";

contract ARCH is IERC20 {
  /** @dev Contants */

  uint256 private constant _totalSupply = 50_000_000 ether;

  /** @dev Fields */

  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => uint256) private _balances;

  constructor() {
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /** @dev Views */

  function name() external pure override returns (string memory) {
    return "Arch DeFi";
  }

  function symbol() external pure override returns (string memory) {
    return "ARCH";
  }

  function decimals() external pure override returns (uint8) {
    return 18;
  }

  function totalSupply() external pure override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  function allowance(address account, address trust) external view override returns (uint256) {
    return _allowances[account][trust];
  }

  /** @dev Mutators */

  function approve(address trust, uint256 amount) external override returns (bool) {
    _allowances[msg.sender][trust] = amount;

    emit Approval(msg.sender, trust, amount);

    return true;
  }

  function transfer(address to, uint256 amount) external override returns (bool) {
    return _transfer(msg.sender, to, amount);
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external override returns (bool) {
    uint256 a = _allowances[from][msg.sender];

    if (a != type(uint256).max) {
      require(amount <= a, "ARCH: insufficient allowance");
      _allowances[from][msg.sender] = a - amount;
    }

    return _transfer(from, to, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private returns (bool) {
    uint256 balance = _balances[from];

    require(amount <= balance, "ARCH: insufficient balance");

    _balances[from] = balance - amount;
    _balances[to] += amount;

    emit Transfer(from, to, amount);

    return true;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 10000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}