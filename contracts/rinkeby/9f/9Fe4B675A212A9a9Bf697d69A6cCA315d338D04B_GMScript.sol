// SPDX-License-Identifier: CC BY-NC-SA 3.0

pragma solidity =0.8.6;

contract GMScript {
    
    string public license = "CC BY-NC-SA 3.0";
    
    string public usedLibrary = "p5.js";
    
    string public libraryVersion = "1.3.1";
    
    string public creator = "takawo";
    
    string public breakLineTest = "hoge\nfoo\n\nbar";
    

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}