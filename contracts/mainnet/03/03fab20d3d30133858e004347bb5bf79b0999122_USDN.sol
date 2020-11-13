// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.8;

interface Staking {
  function deposit(address account, uint256 amount) external returns (bool);

  function withdraw(address account) external returns (bool);

  function stake(uint256 reward) external returns (bool);

  event Reward(uint256 reward);
}

interface ERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
  address private _owner;
  address private _admin;

  constructor () public {
    _owner = msg.sender;
    _admin = msg.sender;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender || _admin == msg.sender, "Ownable: caller is not the owner or admin");
    _;
  }

  function transferOwnership(address newOwner) external virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _owner = newOwner;
  }
}

abstract contract Deprecateble is Ownable {
  bool internal deprecated;

  modifier onlyNotDeprecated() {
    require(!deprecated, "Deprecateble: contract is deprecated");
    _;
  }

  function deprecate() external onlyOwner {
    deprecated = true;
    emit Deprecate(msg.sender);
  }

  event Deprecate(address indexed account);
}

abstract contract StandartToken is Staking, ERC20, Ownable, Deprecateble {
  uint256[] private percents;
  uint256 private _liquidTotalSupply;
  uint256 private _liquidDeposit;
  uint256 constant private PERCENT_FACTOR = 10 ** 12;

  mapping(address => uint256) private _balances;
  mapping(address => uint256) private _rewardIndexForAccount;
  mapping(address => mapping(address => uint256)) private _allowances;

  constructor () public {
    percents.push(PERCENT_FACTOR);
  }

  function deposit(address account, uint256 amount) external onlyOwner onlyNotDeprecated override virtual returns (bool)  {
    require(amount > 0, "amount should be > 0");
    require(account != address(0), "deposit to the zero address");

    uint256 balance = _balances[account];
    uint256 rewardIndex = _rewardIndexForAccount[account];
    if (balance == 0 || rewardIndex == percents.length) {
      uint256 liquidDeposit = _liquidDeposit;
      require(liquidDeposit + amount >= liquidDeposit, "addition overflow for deposit");
      _liquidDeposit = liquidDeposit + amount;

      _balances[account] = balance + amount;
      _rewardIndexForAccount[account] = percents.length;
    } else {
      uint256 liquidTotalSupply = _liquidTotalSupply;
      require(liquidTotalSupply + amount >= liquidTotalSupply, "addition overflow for deposit");
      _liquidTotalSupply = liquidTotalSupply + amount;

      uint256 diff = amount * percents[rewardIndex] / percents[percents.length - 1];
      require(balance + diff >= balance, "addition overflow for balance");
      _balances[account] = balance + diff;
    }

    emit Transfer(address(0), account, amount);
    return true;
  }

  function stake(uint256 reward) external onlyOwner onlyNotDeprecated override virtual returns (bool) {
    uint256 liquidTotalSupply = _liquidTotalSupply;
    uint256 liquidDeposit = _liquidDeposit;

    if (liquidTotalSupply == 0) {
      percents.push(PERCENT_FACTOR);
    } else {
      uint256 oldPercent = percents[percents.length - 1];
      uint256 percentFactor = PERCENT_FACTOR;
      uint256 percent = reward * percentFactor;

      require(percent / percentFactor == reward, "multiplication overflow for percent init");
      percent /= liquidTotalSupply;
      require(percent + percentFactor >= percent, "addition overflow for percent");
      uint256 newPercent = percent + percentFactor;

      require(newPercent * oldPercent / oldPercent == newPercent, "multiplication overflow for percent");
      percents.push(newPercent * oldPercent / PERCENT_FACTOR);

      require(liquidTotalSupply + reward >= liquidTotalSupply, "addition overflow for total supply + reward");
      liquidTotalSupply = liquidTotalSupply + reward;
    }

    require(liquidTotalSupply + liquidDeposit >= liquidTotalSupply, "addition overflow for total supply");
    _liquidTotalSupply = liquidTotalSupply + liquidDeposit;
    _liquidDeposit = 0;

    emit Reward(reward);
    return true;
  }

  function withdraw(address account) external onlyOwner onlyNotDeprecated override virtual returns (bool) {
    uint256 balance = balanceOf(account);
    uint256 liquidTotalSupply = _liquidTotalSupply;
    uint256 liquidDeposit = _liquidDeposit;

    if (balance > liquidTotalSupply) {
      require(balance - liquidTotalSupply <= liquidDeposit, "subtraction overflow for liquid deposit");
      _liquidDeposit = liquidDeposit - balance - liquidTotalSupply;
      _liquidTotalSupply = 0;
    } else {
      require(balance <= _liquidTotalSupply, "subtraction overflow for total supply");
      _liquidTotalSupply = _liquidTotalSupply - balance;
    }

    _balances[account] = 0;
    emit Transfer(account, address(0), balance);
    return true;
  }

  // ERC20
  function totalSupply() external view override virtual returns (uint256) {
    uint256 liquidTotalSupply = _liquidTotalSupply;
    uint256 liquidDeposit = _liquidDeposit;

    require(liquidTotalSupply + liquidDeposit >= liquidTotalSupply, "addition overflow for total supply");
    return liquidTotalSupply + liquidDeposit;
  }

  function balanceOf(address account) public view override virtual returns (uint256) {
    uint256 balance = _balances[account];
    if (balance == 0) {
      return 0;
    }

    uint256 rewardIndex = _rewardIndexForAccount[account];
    if (rewardIndex == percents.length) {
      return balance;
    }

    uint256 profit = percents[percents.length - 1];
    require(profit * balance / balance == profit, "multiplication overflow");
    return profit * balance / percents[rewardIndex];
  }

  function allowance(address owner, address spender) external view override virtual returns (uint256) {
    return _allowances[owner][spender];
  }

  function _approve(address owner, address spender, uint256 amount) internal onlyNotDeprecated virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function approve(address spender, uint256 amount) external override virtual returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external override virtual returns (bool) {
    uint256 temp = _allowances[msg.sender][spender];
    require(temp + addedValue >= temp, "addition overflow");
    _approve(msg.sender, spender, temp + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external override virtual returns (bool) {
    uint256 temp = _allowances[msg.sender][spender];
    require(subtractedValue <= temp, "ERC20: decreased allowance below zero");
    _approve(msg.sender, spender, temp - subtractedValue);
    return true;
  }

  function transfer(address recipient, uint256 amount) external override virtual returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override virtual returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 temp = _allowances[sender][msg.sender];
    require(amount <= temp, "ERC20: transfer amount exceeds allowance");
    _approve(sender, msg.sender, temp - amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal onlyNotDeprecated virtual {
    require(amount > 0, "amount should be > 0");
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    uint256 senderBalance = balanceOf(sender);
    require(amount <= senderBalance, "ERC20: transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    uint256 rewardIndex = _rewardIndexForAccount[sender];
    if (rewardIndex <= percents.length) {
      _rewardIndexForAccount[sender] = percents.length - 1;
    }

    uint256 recipientBalance = balanceOf(recipient);
    require(amount + recipientBalance >= recipientBalance, "ERC20: addition overflow for recipient balance");
    _balances[recipient] = recipientBalance + amount;
    rewardIndex = _rewardIndexForAccount[recipient];
    if (rewardIndex <= percents.length) {
      _rewardIndexForAccount[recipient] = percents.length - 1;
    }

    emit Transfer(sender, recipient, amount);
  }
}

contract USDN is StandartToken {
  function name() external pure returns (string memory) {
    return "Neutrino USD";
  }

  function symbol() external pure returns (string memory) {
    return "USDN";
  }

  function decimals() external pure returns (uint8) {
    return 18;
  }
}