//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./CloneFactory.sol";
import "./Token.sol";

contract UserWalletV2 {

  address controller;
  constructor(address _controller) {
    controller = _controller;
  }

  function init(address _controller) public {
    require(controller == 0x0000000000000000000000000000000000000000, "already initialized"); // ensure not init'd already.
    
    controller = _controller;
  }

  function sweep(address _token, address _destination, uint _amount) public returns (bool) {
    require(msg.sender == controller, "Not called from controller");
    Token token = Token(_token);
    if (_amount > token.balanceOf(address(this))) {
      return false;
    }
    token.transfer(_destination, _amount);
    return true;
  }
}

contract ControllerV2 is CloneFactory {
  address public owner;
  address public authorizedCaller;
  address payable public destination;

  address public libraryAddress;

  modifier onlyOwner() {
    require(msg.sender == owner, "not owner");
    _;
  }

  modifier onlyAdmins() {
    require(msg.sender == authorizedCaller || msg.sender == owner, "not admin");
    _;
  }

  event LogNewWallet(address receiver);
  event LogSweep(address indexed from, address indexed to, address indexed token, uint amount);

  constructor() {
    owner = msg.sender;
    destination = payable(msg.sender);
    authorizedCaller = msg.sender;
    libraryAddress = address(new UserWalletV2(address(this)));
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

  function sweep(address _wallet, address _token, uint _amount) public onlyAdmins returns (bool) {
    UserWalletV2 wallet = UserWalletV2(_wallet);
    return wallet.sweep(_token, destination, _amount);
  }

  function makeWallet() public onlyAdmins returns (address wallet)  {
    wallet = createClone(libraryAddress);
    UserWalletV2(wallet).init(address(this));
    emit LogNewWallet(wallet);
  }

  function logSweep(address from, address to, address token, uint amount) public {
    emit LogSweep(from, to, token, amount);
  }

}