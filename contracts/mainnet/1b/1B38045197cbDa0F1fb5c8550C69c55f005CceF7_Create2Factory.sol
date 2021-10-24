// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Create2Factory {
  
  address private constant owner = 0xfda123b830A46e7C235d2E383aA3536DDC7564A3;
  
  function deploy(
    bytes32 salt,
    bytes memory initializationCode
  ) external payable {
    require(owner == msg.sender);
    assembly {
      let addr := create2(                    // call CREATE2 with 4 arguments.
        callvalue(),                          // forward any attached value.
        add(0x20, initializationCode),        // pass in initialization code.
        mload(initializationCode),            // pass in init code's length.
        salt                                  // pass in the salt value.
      )
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }
  }
  
}