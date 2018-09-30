pragma solidity ^0.4.24;

contract Voting {
  address public admin;

  constructor(address _admin) public {
    admin = _admin;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function setAdmin(address _newAdmin) public onlyAdmin {
    admin = _newAdmin;
  }
}