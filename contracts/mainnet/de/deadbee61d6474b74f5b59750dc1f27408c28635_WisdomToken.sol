// SPDX-License-Identifier: MIT

// Author: Grzegorz Kucmierz <gkucmierz@gmail.com>
// Source: https://github.com/gkucmierz/wisdom-contract

pragma solidity ^0.7.2;

contract ERC20 {

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowed;

  function _transfer(address sender, address recipient, uint256 amount) internal virtual returns (bool) {
    require(balanceOf[sender] >= amount);
    balanceOf[sender] -= amount;
    balanceOf[recipient] += amount;
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function transfer(address recipient, uint256 amount) public returns (bool) {
    return _transfer(msg.sender, recipient, amount);
  }

  function allowance(address holder, address spender) public view returns (uint256) {
    return allowed[holder][spender];
  }

  function approve(address spender, uint256 amount) public returns (bool) {
    require(balanceOf[msg.sender] >= amount);
    allowed[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(allowed[sender][msg.sender] >= amount);
    _transfer(sender, recipient, amount);
    allowed[sender][msg.sender] -= amount;
    return true;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed holder, address indexed spender, uint256 value);
}

interface IERC677Receiver {
  function onTokenTransfer(address from, uint256 amount, bytes calldata data) external;
}

contract ERC667 is ERC20 {
  function transferAndCall(address recipient, uint amount, bytes calldata data) public returns (bool) {
    bool success = _transfer(msg.sender, recipient, amount);
    if (success){
      IERC677Receiver(recipient).onTokenTransfer(msg.sender, amount, data);
    }
    return success;
  }
}

contract ERCTransferFrom is ERC667 {
  mapping (address => mapping (address => uint256)) public nonceOf;

  function _transfer(address from, address recipient, uint256 amount, uint256 nonce) private returns (bool) {
    uint256 nextNonce = nonceOf[from][recipient] + 1;
    require(nonce == nextNonce);
    bool success = _transfer(from, recipient, amount);
    if (success) nonceOf[from][recipient] = nextNonce;
    return success;
  }

  function transferFrom(address recipient, uint256 amount, uint256 nonce, uint8 _v, bytes32 _r, bytes32 _s) public returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked('transferFrom', recipient, amount, nonce));
    address from = ecrecover(hash, _v, _r, _s);
    return _transfer(from, recipient, amount, nonce);
  }

  function transferFromUntil(address recipient, uint256 amount, uint256 untilBlock, uint256 nonce, uint8 _v, bytes32 _r, bytes32 _s) public returns (bool) {
    require(untilBlock <= block.number);
    bytes32 hash = keccak256(abi.encodePacked('transferFromUntil', recipient, amount, nonce, untilBlock));
    address from = ecrecover(hash, _v, _r, _s);
    return _transfer(from, recipient, amount, nonce);
  }
}

contract Ownable {
  address owner;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0x0));
    owner = newOwner;
    emit TransferOwnership(newOwner);
  }

  event TransferOwnership(address newOwner);
}

contract Pausable is Ownable {
  bool public paused = true;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

  event Pause();
  event Unpause();
}

contract Issuable is ERC20, Ownable {
  bool locked = false;

  modifier whenUnlocked() {
    require(!locked);
    _;
  }

  function issue(address[] memory addr, uint256[] memory amount) public onlyOwner whenUnlocked {
    require(addr.length == amount.length);
    uint8 i;
    uint256 sum = 0;
    for (i = 0; i < addr.length; ++i) {
      balanceOf[addr[i]] = amount[i];
      emit Transfer(address(0x0), addr[i], amount[i]);
      sum += amount[i];
    }
    totalSupply += sum;
  }

  function lock() internal onlyOwner whenUnlocked {
    locked = true;
  }
}

contract WisdomToken is ERCTransferFrom, Pausable, Issuable {
  constructor() {
    name = 'Wisdom Token';
    symbol = 'WIS';
    decimals = 18;
    totalSupply = 0;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal whenNotPaused override returns (bool) {
    return _transfer(sender, recipient, amount);
  }

  function alive(address owner) public {
    lock();
    unpause();
    transferOwnership(owner);
  }
}