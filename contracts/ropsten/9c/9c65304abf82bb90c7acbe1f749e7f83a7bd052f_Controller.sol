pragma solidity ^0.4.24;

//import "github.com/OpenZeppelin/openzeppelin-solidity/blob/v1.12.0/contracts/token/ERC20/ERC20Basic.sol";

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

//-------------------------------------------------------------------------------------------------------
//
contract AbstractSweeper {
  Controller controller;

  modifier canSweep() {
    require(msg.sender == controller.authorizedCaller() || msg.sender == controller.owner());
    require(!controller.halted());
    _;
  }

  constructor(address _controller) public {
    controller = Controller(_controller);
  }

  function () public { revert(); }

  function sweep(address token, uint amount) public returns (bool);
}

//-------------------------------------------------------------------------------------------------------
//
contract DefaultSweeper is AbstractSweeper {
  constructor(address controller) AbstractSweeper(controller) public {}

  function sweep(address _token, uint _amount) canSweep public returns (bool) {
    bool success = false;
    address destination = controller.destination();

    if (_token != address(0)) {
      ERC20Basic token = ERC20Basic(_token);
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
      controller.logSweep(this, destination, _token, _amount);
    }
    return success;
  }
}

//-------------------------------------------------------------------------------------------------------
//
contract UserWallet {
  AbstractSweeperList sweeperList;

  constructor(address _sweeperList) public {
    sweeperList = AbstractSweeperList(_sweeperList);
  }

  function () public payable { }

  uint public value;
  function tokenFallback(address _from, uint _value, bytes _data) public {
    (_from);
    value = _value;
    //(_value);
    (_data);
  }

  function sweep(address _token, uint _amount) public returns (bool) {
    (_amount);
    return sweeperList.sweeperOf(_token).delegatecall(msg.data);
  }
}

//-------------------------------------------------------------------------------------------------------
//
contract AbstractSweeperList {
  function sweeperOf(address _token) public returns (address);
}

//-------------------------------------------------------------------------------------------------------
//
contract Controller is AbstractSweeperList {
  address public owner;
  address public authorizedCaller;

  address public destination;

  bool public halted;

  event LogNewWallet(address receiver);
  event LogSweep(address indexed from, address indexed to, address indexed token, uint amount);

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

  address public defaultSweeper = address(new DefaultSweeper(this));
  mapping (address => address) sweepers;

  function addSweeper(address _token, address _sweeper) onlyOwner public {
    sweepers[_token] = _sweeper;
  }

  function sweeperOf(address _token) public returns (address) {
    address sweeper = sweepers[_token];

    if (sweeper == 0) sweeper = defaultSweeper;
    return sweeper;
  }

  function logSweep(address from, address to, address token, uint amount) public {
    emit LogSweep(from, to, token, amount);
  }
}