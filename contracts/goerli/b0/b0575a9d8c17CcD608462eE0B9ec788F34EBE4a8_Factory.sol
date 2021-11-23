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
  event Deployed(address addr, bytes32 salt, bytes32 initCodeHash);

  function deploy(uint256 arg) public{
    bytes32 salt;
    Account acc = new Account{salt: salt}(arg);

    bytes32 initCodeHash = keccak256(abi.encodePacked(type(Account).creationCode, arg));

    emit Deployed(address(acc), salt, initCodeHash);
  }
}