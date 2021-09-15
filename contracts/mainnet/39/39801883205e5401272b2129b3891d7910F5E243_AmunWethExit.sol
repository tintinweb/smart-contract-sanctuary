pragma solidity ^0.8.6;

interface IRootChainManager {
    function exit(bytes calldata inputData) external;
}

contract AmunWethExit {
    IRootChainManager public immutable rootChainManager;

    constructor(address _rootChainManager) {
        rootChainManager = IRootChainManager(_rootChainManager);
    }

    /// @notice This sends eth to user via amun weth
    /// @param inputDataWeth the hash of the bridge exit of weth to amun weth
    /// @param inputDataAmunWeth the hash of the bridge exit of amun weth
    function exit(
        bytes calldata inputDataWeth,
        bytes calldata inputDataAmunWeth
    ) external {
        rootChainManager.exit(inputDataWeth);
        rootChainManager.exit(inputDataAmunWeth);
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
  },
  "libraries": {}
}