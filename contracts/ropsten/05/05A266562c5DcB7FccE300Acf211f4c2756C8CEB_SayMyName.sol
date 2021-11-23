pragma solidity 0.8.3;

contract SayMyName {
  mapping (uint256 => string) public names;

  function registerName(uint256 _id, string memory _name) external {
      require(bytes(names[_id]).length == 0, "ID is already taken");
      names[_id] = _name;
  }
}