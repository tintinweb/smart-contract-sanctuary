pragma solidity ^0.4.24;

contract Voting {
  address public admin;

  mapping(address=>bool) internal registration;

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

  function register() public payable {
    require(msg.value == 0.1 ether);
    require(!registration[msg.sender]);
    registration[msg.sender] = true;
  }
}