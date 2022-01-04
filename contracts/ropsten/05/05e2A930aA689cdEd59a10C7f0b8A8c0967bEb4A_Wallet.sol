pragma solidity 0.8.11;

contract Wallet {
  address payable public owner;
  address public admin;

  constructor(address payable _owner, address _admin) {
    owner = _owner;
    admin = _admin;
  }

  function withdraw() public {
    require(msg.sender == owner || msg.sender == admin, "Not permitted");
    owner.transfer(address(this).balance);
  }
}