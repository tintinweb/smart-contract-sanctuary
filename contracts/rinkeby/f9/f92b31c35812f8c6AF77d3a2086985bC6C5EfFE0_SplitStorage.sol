// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title SplitStorage
 * @author MirrorXYZ
 *
 * Modified to store:
 * address of the deployed Minter Contract
 */
contract SplitStorage {
    //======== Constants =========
    address public constant _zoraMedia =
        0x7C2668BD0D3c050703CEcC956C11Bd520c26f7d4;
    address public constant _zoraMarket =
        0x85e946e1Bd35EC91044Dc83A5DdAB2B6A262ffA6;
    address public constant _zoraAuctionHouse =
        0xE7dd1252f50B3d845590Da0c5eADd985049a03ce;
    //0x835F86fF1670917A786b72D1FD8DcC385E27DD77 mainnet
    address public constant _mirrorAH =
        0x2D5c022fd4F81323bbD1Cc0Ec6959EC8CC1C5A11;
    //idk 0x517bab7661C315C63C6465EEd1b4248e6f7FE183 maybe
    address public constant _mirrorCrowdfundFactory =
        0xeac226B370D77f436b5780b4DD4A49E59e8bEA37;
    //0x3725CA6034bcDBc3c9aDa649d49Df68527661175 mainnet
    address public constant _mirrorEditions =
        0xa8b8F7cC0C64c178ddCD904122844CBad0021647;
    //0xD96Ff9e48f095f5a22Db5bDFFCA080bCC3B98c7f mainnet
    address public constant _partyBidFactory =
        0xB725682D5AdadF8dfD657f8e7728744C0835ECd9;
    address public constant wethAddress =
        0xc778417E063141139Fce010982780140Aa0cD5Ab;

    bytes32 public merkleRoot;
    uint256 public currentWindow;

    address internal _splitter;
    address internal _minter;
    address internal _owner;

    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal claimed;
    uint256 internal depositedInWindow;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2000
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