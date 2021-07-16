pragma solidity ^0.8.4;

/**
* @dev An interface for contracts implementing a DNSSEC (signing) algorithm.
*/
interface Algorithm {
    /**
    * @dev Verifies a signature.
    * @param key The public key to verify with.
    * @param data The signed data to verify.
    * @param signature The signature to verify.
    * @return True iff the signature is valid.
    */
    function verify(bytes calldata key, bytes calldata data, bytes calldata signature) external virtual view returns (bool);
}

pragma solidity ^0.8.4;

import "./Algorithm.sol";

/**
* @dev Implements a dummy DNSSEC (signing) algorithm that approves all
*      signatures, for testing.
*/
contract DummyAlgorithm is Algorithm {
    function verify(bytes calldata, bytes calldata, bytes calldata) external override view returns (bool) { return true; }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
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