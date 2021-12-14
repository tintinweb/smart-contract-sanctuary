pragma solidity >=0.5.0 <0.6.0;

import "./zombieownership.sol";

contract CryptoZombies is ZombieOwnership {
  function kill() public onlyOwner {
    selfdestruct(address(uint160(owner())));
  }
}