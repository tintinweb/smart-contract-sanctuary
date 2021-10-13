pragma solidity 0.6.12;

import "../Governable.sol";

contract ProxyRegistry is Governable {
  mapping(address => address) public proxies;

  constructor(address _storage) public Governable(_storage) {}

  function addOperator(address _owner, address _operator) public onlyGovernance {
    proxies[_owner] = _operator;
  }

  function removeOperator(address _owner) public onlyGovernance {
    delete proxies[_owner];
  }
}

pragma solidity 0.6.12;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

pragma solidity 0.6.12;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}