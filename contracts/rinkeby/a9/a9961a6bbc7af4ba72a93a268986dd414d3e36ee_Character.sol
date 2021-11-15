pragma solidity ^0.5.16;

contract Character {
  string public name = "Sonic";
  address admin;

  constructor(address _admin) public {
    admin = _admin;
  }

  function changeName(string calldata _name) external {
    require(msg.sender == admin);
    name = _name;
  }
}

