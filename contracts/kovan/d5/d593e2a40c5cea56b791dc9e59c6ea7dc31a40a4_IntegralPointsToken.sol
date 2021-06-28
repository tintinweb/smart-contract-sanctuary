// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM_ADD_OVERFLOW');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM_SUB_UNDERFLOW');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM_MUL_OVERFLOW');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM_DIV_BY_ZERO');
        uint256 c = a / b;
        return c;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (c == mul(a, b)) {
            return c;
        } else {
            return add(c, 1);
        }
    }

    function add96(uint96 a, uint96 b) internal pure returns (uint96 c) {
        c = a + b;
        require(c >= a, 'SM_ADD_OVERFLOW');
    }

    function sub96(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b <= a, 'SM_SUB_UNDERFLOW');
        return a - b;
    }

    function mul96(uint96 x, uint96 y) internal pure returns (uint96 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM_MUL_OVERFLOW');
    }

    function div96(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b > 0, 'SM_DIV_BY_ZERO');
        uint96 c = a / b;
        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'SafeMath.sol';

contract IntegralPointsToken {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event OwnerSet(address indexed owner);
    event MinterSet(address indexed account, bool isMinter);
    event BurnerSet(address indexed account, bool isBurner);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event BlacklistedSet(address indexed account, bool isBlacklisted);

    string public constant name = 'Integral Points';
    string public constant symbol = 'ITGR-P';
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    address public owner;

    mapping(address => bool) public isMinter;
    mapping(address => bool) public isBurner;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => bool) public isBlacklisted;

    constructor(address account, uint256 _initialAmount) {
        owner = msg.sender;
        isMinter[msg.sender] = true;
        isBurner[msg.sender] = true;
        _mint(account, _initialAmount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address account, address spender) external view returns (uint256) {
        return allowances[account][spender];
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, 'IP_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setMinter(address account, bool _isMinter) external {
        require(msg.sender == owner, 'IP_FORBIDDEN');
        isMinter[account] = _isMinter;
        emit MinterSet(account, _isMinter);
    }

    function mint(address to, uint256 _amount) external {
        require(isMinter[msg.sender], 'IP_ONLY_WHITELISTED');
        require(!isBlacklisted[msg.sender] && !isBlacklisted[to], 'IP_BLACKLISTED');
        _mint(to, _amount);
    }

    function _mint(address to, uint256 _amount) internal {
        totalSupply = totalSupply.add(_amount);
        balances[to] = balances[to].add(_amount);
        emit Transfer(address(0), to, _amount);
    }

    function setBurner(address account, bool _isBurner) external {
        require(msg.sender == owner, 'IP_FORBIDDEN');
        isBurner[account] = _isBurner;
        emit BurnerSet(account, _isBurner);
    }

    function burn(uint256 _amount) external {
        require(isBurner[address(0)] || isBurner[msg.sender], 'IP_ONLY_WHITELISTED');
        require(!isBlacklisted[msg.sender], 'IP_BLACKLISTED');
        totalSupply = totalSupply.sub(_amount, 'IP_INVALID_BURN_AMOUNT');
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    function approve(address spender, uint256 _amount) external returns (bool) {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[spender], 'IP_BLACKLISTED');
        _approve(msg.sender, spender, _amount);
        return true;
    }

    function _approve(
        address account,
        address spender,
        uint256 amount
    ) internal {
        require(account != address(0) && spender != address(0), 'IP_ADDRESS_ZERO');
        allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
    }

    function increaseAllowance(address spender, uint256 _extraAmount) external returns (bool) {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[spender], 'IP_BLACKLISTED');
        _approve(msg.sender, spender, allowances[msg.sender][spender].add(_extraAmount));
        return true;
    }

    function decreaseAllowance(address spender, uint256 _subtractedAmount) external returns (bool) {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[spender], 'IP_BLACKLISTED');
        uint256 currentAmount = allowances[msg.sender][spender];
        require(currentAmount >= _subtractedAmount, 'IP_CANNOT_DECREASE');
        _approve(msg.sender, spender, currentAmount.sub(_subtractedAmount));
        return true;
    }

    function transfer(address to, uint256 _amount) external returns (bool) {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[to], 'IP_BLACKLISTED');
        _transferTokens(msg.sender, to, _amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 _amount
    ) external returns (bool) {
        address spender = msg.sender;
        require(!isBlacklisted[spender] && !isBlacklisted[from] && !isBlacklisted[to], 'IP_BLACKLISTED');
        uint256 spenderAllowance = allowances[from][spender];
        if (spender != from && spenderAllowance != uint256(-1)) {
            _approve(from, spender, spenderAllowance.sub(_amount));
        }
        _transferTokens(from, to, _amount);
        return true;
    }

    function _transferTokens(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(to != address(0), 'IP_INVALID_TO');
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function setBlacklisted(address account, bool _isBlacklisted) external {
        require(msg.sender == owner, 'IP_FORBIDDEN');
        isBlacklisted[account] = _isBlacklisted;
        emit BlacklistedSet(account, _isBlacklisted);
    }
}

{
  "libraries": {
    "SafeMath.sol": {},
    "IntegralPointsToken.sol": {}
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
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