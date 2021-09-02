pragma solidity >=0.4.22 <0.7.0;

import "./aLib.sol";

contract sampleContract {
    function get () public {
        aLib.doStuff();
    }
}

pragma solidity >=0.4.22 <0.7.0;

library aLib {
    function doStuff()  public {
    }
}

{
  "optimizer": {
    "enabled": true,
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