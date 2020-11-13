pragma solidity ^0.4.24;

import "./Rootex.sol";

contract Exet is Rootex {
  address public owner;

  address[] public adminsList;
  mapping (address => bool) public listedAdmins;
  mapping (address => bool) public activeAdmins;

  string[] public symbolsList;
  mapping (bytes32 => bool) public listedCoins;
  mapping (bytes32 => bool) public lockedCoins;
  mapping (bytes32 => uint256) public coinPrices;

  string constant ETH = "ETH";
  bytes32 constant ETHEREUM = 0xaaaebeba3810b1e6b70781f14b2d72c1cb89c0b2b320c43bb67ff79f562f5ff4;
  address constant PROJECT = 0x537ca62B4c232af1ef82294BE771B824cCc078Ff;

  event Admin (address user, bool active);
  event Coin (string indexed coinSymbol, string coinName, address maker, uint256 rate);
  event Deposit (string indexed coinSymbol, address indexed maker, uint256 value);
  event Withdraw (string indexed coinSymbol, address indexed maker, uint256 value);

  constructor (uint sysCost, uint ethCost) public {
    author = "ASINERUM INTERNATIONAL";
    name = "ETHEREUM CRYPTO EXCHANGE TOKEN";
    symbol = "EXET";
    owner = msg.sender;
    newadmin (owner, true);
    SYMBOL = tocoin(symbol);
    newcoin (symbol, name, sysCost*PPT);
    newcoin (ETH, "ETHEREUM", ethCost*PPT);
  }

  function newadmin (address user, bool active)
  internal {
    if (!listedAdmins[user]) {
      listedAdmins[user] = true;
      adminsList.push (user);
    }
    activeAdmins[user] = active;
    emit Admin (user, active);
  }

  function newcoin (string memory coinSymbol, string memory coinName, uint256 rate)
  internal {
    bytes32 coin = tocoin (coinSymbol);
    if (!listedCoins[coin]) {
      listedCoins[coin] = true;
      symbolsList.push (coinSymbol);
    }
    coinPrices[coin] = rate;
    emit Coin (coinSymbol, coinName, msg.sender, rate);
  }

  // GOVERNANCE FUNCTIONS

  function adminer (address user, bool active) public {
    require (msg.sender==owner, "#owner");
    newadmin (user, active);
  }

  function coiner (string memory coinSymbol, string memory coinName, uint256 rate) public {
    require (activeAdmins[msg.sender], "#admin");
    newcoin (coinSymbol, coinName, rate);
  }

  function lock (bytes32 coin) public {
    require (msg.sender==owner, "#owner");
    require (!lockedCoins[coin], "#coin");
    lockedCoins[coin] = true;
  }

  function lim (bytes32 coin, uint256 value) public {
    require (activeAdmins[msg.sender], "#admin");
    require (limits[coin]==0, "#coin");
    limits[coin] = value;
  }

  // PUBLIC METHODS

  function () public payable {
    deposit (ETH);
  }

  function deposit () public payable returns (bool success) {
    return deposit (symbol);
  }

  function deposit (string memory coinSymbol) public payable returns (bool success) {
    return deposit (coinSymbol, msg.sender);
  }

  function deposit (string memory coinSymbol, address to) public payable returns (bool success) {
    bytes32 coin = tocoin (coinSymbol);
    uint256 crate = coinPrices[coin];
    uint256 erate = coinPrices[ETHEREUM];
    require (!lockedCoins[coin], "#coin");
    require (crate>0, "#token");
    require (erate>0, "#ether");
    require (msg.value>0, "#value");
    uint256 value = msg.value*erate/crate;
    mint (coin, to, value);
    mint (SYMBOL, PROJECT, value);
    emit Deposit (coinSymbol, to, value);
    return true;
  }

  function withdraw (string memory coinSymbol, uint256 value) public returns (bool success) {
    bytes32 coin = tocoin (coinSymbol);
    uint256 crate = coinPrices[coin];
    uint256 erate = coinPrices[ETHEREUM];
    require (crate>0, "#token");
    require (erate>0, "#ether");
    require (value>0, "#value");
    burn (coin, msg.sender, value);
    mint (SYMBOL, PROJECT, value);
    msg.sender.transfer (value*crate/erate);
    emit Withdraw (coinSymbol, msg.sender, value);
    return true;
  }

  function swap (bytes32 coin1, uint256 value1, bytes32 coin2) public returns (bool success) {
    require (!lockedCoins[coin2], "#target");
    uint256 price1 = coinPrices[coin1];
    uint256 price2 = coinPrices[coin2];
    require (price1>0, "#coin1");
    require (price2>0, "#coin2");
    require (value1>0, "#input");
    uint256 value2 = value1*price1/price2;
    swap (coin1, value1, coin2, value2);
    mint (SYMBOL, PROJECT, value2);
    return true;
  }

  function lens () public view returns (uint admins, uint symbols) {
    admins = adminsList.length;
    symbols = symbolsList.length;
  }
}