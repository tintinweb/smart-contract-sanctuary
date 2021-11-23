/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

contract Account {
  uint256 public owner;

  constructor(uint256 arg) public {
    owner = arg;
  }
}


contract Factory {
  event Deployed(address addr, bytes32 salt, uint256 arg);

  function deploy(uint256 arg) public{
    bytes32 salt;
    Account acc = new Account{salt: salt}(arg);

    emit Deployed(address(acc), salt, arg);
  }
}