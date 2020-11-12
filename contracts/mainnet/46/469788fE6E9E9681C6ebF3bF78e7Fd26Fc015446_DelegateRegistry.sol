{{
  "language": "Solidity",
  "sources": {
    "/contracts/DelegateRegistry.sol": {
      "content": "// SPDX-License-Identifier: LGPL-3.0-only\npragma solidity >=0.7.0 <0.8.0;\n\ncontract DelegateRegistry {\n    \n    // The first key is the delegator and the second key a id. \n    // The value is the address of the delegate \n    mapping (address => mapping (bytes32 => address)) public delegation;\n    \n    // Using these events it is possible to process the events to build up reverse lookups.\n    // The indeces allow it to be very partial about how to build this lookup (e.g. only for a specific delegate).\n    event SetDelegate(address indexed delegator, bytes32 indexed id, address indexed delegate);\n    event ClearDelegate(address indexed delegator, bytes32 indexed id, address indexed delegate);\n    \n    /// @dev Sets a delegate for the msg.sender and a specific id.\n    ///      The combination of msg.sender and the id can be seen as a unique key.\n    /// @param id Id for which the delegate should be set\n    /// @param delegate Address of the delegate\n    function setDelegate(bytes32 id, address delegate) public {\n        require (delegate != msg.sender, \"Can't delegate to self\");\n        require (delegate != address(0), \"Can't delegate to 0x0\");\n        address currentDelegate = delegation[msg.sender][id];\n        require (delegate != currentDelegate, \"Already delegated to this address\");\n        \n        // Update delegation mapping\n        delegation[msg.sender][id] = delegate;\n        \n        if (currentDelegate != address(0)) {\n            emit ClearDelegate(msg.sender, id, currentDelegate);\n        }\n\n        emit SetDelegate(msg.sender, id, delegate);\n    }\n    \n    /// @dev Clears a delegate for the msg.sender and a specific id.\n    ///      The combination of msg.sender and the id can be seen as a unique key.\n    /// @param id Id for which the delegate should be set\n    function clearDelegate(bytes32 id) public {\n        address currentDelegate = delegation[msg.sender][id];\n        require (currentDelegate != address(0), \"No delegate set\");\n        \n        // update delegation mapping\n        delegation[msg.sender][id] = address(0);\n        \n        emit ClearDelegate(msg.sender, id, currentDelegate);\n    }\n}"
    }
  },
  "settings": {
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
}}