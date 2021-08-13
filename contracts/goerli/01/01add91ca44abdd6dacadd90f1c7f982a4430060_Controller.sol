//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractSweeper.sol";
import "./AbstractSweeperList.sol";
import "./UserWallet.sol";

contract Controller is AbstractSweeperList {
  address public owner;
  address public authorizedCaller;
  address public dev;
  address payable public destination;

  bool public halted;

  address public defaultSweeper = address(new DefaultSweeper(this));
  mapping (address => address) sweepers;

  event LogNewWallet(address receiver);
  event LogSweep(address indexed from, address indexed to, address indexed token, uint amount);
  
  modifier onlyOwner() {
    require(msg.sender == owner, "not owner");
    _;
  }

  modifier onlyAdmins() {
    require(msg.sender == authorizedCaller || msg.sender == owner || msg.sender == dev, "not admin");
    _;
  }

  constructor() {
    owner = msg.sender;
    destination = payable(msg.sender);
    authorizedCaller = msg.sender;
    dev = msg.sender;
  }

  function changeAuthorizedCaller(address _newCaller) public onlyOwner {
    authorizedCaller = _newCaller;
  }

  function changeDestination(address payable _dest) public onlyOwner {
    destination = _dest;
  }

  function changeOwner(address _owner) public onlyOwner {
    owner = _owner;
  }

  function changeDev(address _dev) public onlyOwner {
    dev = _dev;
  }

  function makeWallet() public onlyAdmins returns (address wallet)  {
    wallet = address(new UserWallet(this));
    emit LogNewWallet(wallet);
  }

  function halt() public onlyAdmins {
    halted = true;
  }

  function start() public onlyOwner {
    halted = false;
  }

  function addSweeper(address _token, address _sweeper) public onlyOwner {
    sweepers[_token] = _sweeper;
  }

  function sweeperOf(address _token) override public view returns (address) {
    address sweeper = sweepers[_token];
    if (sweeper == address(0)) sweeper = defaultSweeper;
    return sweeper;
  }

  function logSweep(AbstractSweeper from, address to, address token, uint amount) public {
    emit LogSweep(address(from), to, token, amount);
  }
}