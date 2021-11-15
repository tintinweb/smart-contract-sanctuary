// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

contract Create2Deployer {

  event Deployed(address addr, uint256 salt);
  address public deployedAddress;
  address public owner;

  constructor(address payable _owner) public {
    owner = _owner;
  }
  function deploy(bytes memory code, uint256 salt) public {
    address addr;
    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }emit Deployed(addr, salt);
    deployedAddress = addr;

  }
  
}

