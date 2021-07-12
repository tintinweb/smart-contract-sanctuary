/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity 0.6.0;

contract Account {
  address public owner;

  constructor() public {
    owner = 0x9fB29AAc15b9A4B7F17c3385939b007540f4d791;
  }

  function setOwner(address _owner) public {
    require(msg.sender == owner);
    owner = _owner;
  }

  function destroy(address payable recipient) public {
    require(msg.sender == owner);
    selfdestruct(recipient);
  }
}

contract Factory {
  event Deployed(address addr, bytes32 salt);

  function deploy(uint256 _salt) public {
    address addr;
    bytes memory bytecode = type(Account).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(_salt));
    assembly {
        addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    emit Deployed(addr, salt);
  }
}