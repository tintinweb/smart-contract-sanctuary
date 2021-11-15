// SPDX-License-Identifier: MIT

/*
  /$$$$$$  /$$$$$$$$ /$$$$$$$$ /$$    /$$ /$$$$$$ /$$$$$$$$ /$$$$$$$
 /$$__  $$|__  $$__/| $$_____/| $$   | $$|_  $$_/| $$_____/| $$__  $$
| $$  \__/   | $$   | $$      | $$   | $$  | $$  | $$      | $$  \ $$
|  $$$$$$    | $$   | $$$$$   |  $$ / $$/  | $$  | $$$$$   | $$$$$$$/
 \____  $$   | $$   | $$__/    \  $$ $$/   | $$  | $$__/   | $$____/
 /$$  \ $$   | $$   | $$        \  $$$/    | $$  | $$      | $$
|  $$$$$$/   | $$   | $$$$$$$$   \  $/    /$$$$$$| $$$$$$$$| $$
 \______/    |__/   |________/    \_/    |______/|________/|__/


*/

import "./IERC20.sol";

pragma solidity ^0.8.2;


contract ImagineCoin is IERC20 {
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  string private _name;
  string private _symbol;
  uint256 private _totalSupply;

  address public owner;

  uint256 constant public pricePerTokenInWei = 100000000000000;
  uint256 constant public maxTokens = 1000000000000000000000000;

  event ImagineMint(address indexed caller, uint256 amount, uint256 transactionValue);
  event ImagineBurn(address indexed caller, uint256 amount);
  event ImagineTransfer(address indexed caller, address indexed from, address indexed to, uint256 value);
  event ImagineApprove(address indexed caller, address indexed spender, uint256 value);

  event ProjectEvent(address indexed poster, string indexed eventType, string content);

  constructor() {
    _name = 'ImagineCoin';
    _symbol = 'IMG';

    owner = msg.sender;
  }

  // Getters

  function name() public view virtual returns (string memory) {
    return _name;
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual returns (uint8) {
    return 18;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  // balanceOf and allowance should be ignored
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  // Contract events

  function mint(uint256 amount) public payable returns (bool) {
    emit ImagineMint(msg.sender, amount, msg.value);
    payable(owner).transfer(msg.value);
    return true;
  }

  function burn(uint256 amount) public returns (bool) {
    emit ImagineBurn(msg.sender, amount);
    return true;
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    emit ImagineTransfer(msg.sender, msg.sender, recipient, amount);
    return true;
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    ImagineApprove(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    emit ImagineTransfer(msg.sender, sender, recipient, amount);
    return true;
  }

  // Administrative Functions

  function transferOwnership(address newOwner) external {
    require(msg.sender == owner, "Only owner can transfer ownership");
    owner = newOwner;
  }

  function emitProjectEvent(string memory _eventType, string memory _content) public {
    require(msg.sender == owner, "Only owner can emit project events");
    emit ProjectEvent(msg.sender, _eventType, _content);
  }

}