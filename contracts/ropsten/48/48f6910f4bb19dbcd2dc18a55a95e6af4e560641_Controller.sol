pragma solidity ^0.4.25;

/**
 * Contract that exposes the needed erc20 token functions
 */

contract ERC20Interface {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) constant public returns (uint256 balance);
}

/**
 * AbstractForwarder
 */
contract AbstractForwarder {
  Controller controller;

  modifier canFlush() {
    require(msg.sender == controller.authorizedCaller() || msg.sender == controller.owner());
    require(!controller.halted());
    _;
  }

  constructor(address _controller) public {
    controller = Controller(_controller);
  }

  //constructor() public { revert();}
  function () public { revert(); }

  function flush(address token, uint amount) public returns (bool);
}

/**
 * Default Forwarder
 */
contract DefaultForwarder is AbstractForwarder {
  constructor(address controller) AbstractForwarder(controller) public {}

  function flush(address _token, uint _amount) canFlush public returns (bool) {
    bool success = false;
    address destination = controller.destination();

    if (_token != address(0)) {
      ERC20Interface token = ERC20Interface(_token);
      uint amount = _amount;
      if (amount > token.balanceOf(this)) {
        return false;
      }

      success = token.transfer(destination, amount);
    }
    else {
      uint amountInWei = _amount;
      if (amountInWei > address(this).balance) {
        return false;
      }

      success = destination.send(amountInWei);
    }

    if (success) {
      controller.logFlush(this, destination, _token, _amount);
    }
    return success;
  }
}

//-------------------------------------------------------------------------------------------------------
//
contract UserWallet {
  AbstractForwarderList forwarderList;

  constructor(address _forwarderList) public {
    forwarderList = AbstractForwarderList(_forwarderList);
  }

  function () public payable { }

  function tokenFallback(address _from, uint _value, bytes _data) pure public {
    (_from);
    (_value);
    (_data);
  }

  function flush(address _token, uint _amount) public returns (bool) {
    (_amount);
    return forwarderList.forwarderOf(_token).delegatecall(msg.data);
  }
}

//-------------------------------------------------------------------------------------------------------
//
contract AbstractForwarderList {
  function forwarderOf(address _token) public returns (address);
}

//-------------------------------------------------------------------------------------------------------
//
contract Controller is AbstractForwarderList {
  address public owner;
  address public authorizedCaller;

  address public destination;

  bool public halted;

  event LogNewWallet(address receiver);
  event LogFlush(address indexed from, address indexed to, address indexed token, uint amount);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAuthorizedCaller() {
    require(msg.sender == authorizedCaller);
    _;
  }

  modifier onlyAdmins() {
    require(msg.sender == authorizedCaller || msg.sender == owner);
    _;
  }

  constructor() public {
    owner = msg.sender;
    destination = msg.sender;
    authorizedCaller = msg.sender;
  }

  function changeAuthorizedCaller(address _newCaller) onlyOwner public {
    authorizedCaller = _newCaller;
  }

  function changeDestination(address _dest) onlyOwner public {
    destination = _dest;
  }

  function changeOwner(address _owner) onlyOwner public {
    owner = _owner;
  }

  function makeWallet() onlyAdmins public returns (address wallet) {
    wallet = address(new UserWallet(this));
    emit LogNewWallet(wallet);
  }

  function halt() onlyAdmins public {
    halted = true;
  }

  function start() onlyOwner public {
    halted = false;
  }

  address public defaultForwarder = address(new DefaultForwarder(this));
  mapping (address => address) forwarders;

  function addForwarder(address _token, address _forwarder) onlyOwner public {
    forwarders[_token] = _forwarder;
  }

  function forwarderOf(address _token) public returns (address) {
    address forwarder = forwarders[_token];

    if (forwarder == 0) forwarder = defaultForwarder;
    return forwarder;
  }

  function logFlush(address from, address to, address token, uint amount) public {
    emit LogFlush(from, to, token, amount);
  }
}