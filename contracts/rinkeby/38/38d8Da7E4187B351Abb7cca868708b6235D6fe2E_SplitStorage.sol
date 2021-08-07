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

    /// @notice Do not forget to change these according to network you are deploying to
    address public immutable wethAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab; //rinkeby
    address public immutable zoraMedia = 0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4;  //rinkeby
    address public immutable zoraAH = 0xE7dd1252f50B3d845590Da0c5eADd985049a03ce; // rinkeby
}

{
  "optimizer": {
    "enabled": true,
    "runs": 750
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