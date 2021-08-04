// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title SplitStorage
 * @author MirrorXYZ
 * @notice Modified by NA. Use at your own risk
 */
contract SplitStorage {
    bytes32 public merkleRoot;
    uint256 public currentWindow;
    address internal _splitter;
    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal claimed;
    uint256 internal depositedInWindow;
    
    address public owner;

    /// @notice Do not forget to change these according to network you are deploying to
    address internal immutable wethAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //rinkeby
    address internal immutable zoraMedia = 0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4;  //rinkeby
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