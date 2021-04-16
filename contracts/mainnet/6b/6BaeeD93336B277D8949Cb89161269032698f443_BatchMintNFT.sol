// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IRockstar {
  /**
   * @dev mints a unique NFT
   */
  function safeMint(address recipient, string memory metadata) external returns (bool);

  /**
   * @dev renounces ownership
   */
  function renounceOwnership() external;
}

/**
 * @title Rockstar
 * @dev Script to deploy batch transactions of NFTs
 */
contract BatchMintNFT {

  constructor() public {}

  /**
   * @notice Mass produces NFTs in a batched transaction
   * @param token the address of the NFT token that needs to be mintedd
   * @param recipients the array of address of recipients who will receive these tokens
   * @param metadatas the array of metadata associated with each NFT
   * @param startpos the start position in NFT order
   * @param num the number of tokens to be minted
   */
  function produceNFTs(address token, address[] memory recipients, string[] memory metadatas, uint8 startpos, uint8 num) public {
    require(recipients.length == 100, "BatchDeploy::batchDeployNFTs: Needs exact 100 recipients");
    require(recipients.length == metadatas.length, "BatchDeploy::batchDeployNFTs: recipients and metaddata count mismatch");

    IRockstar rockstar = IRockstar(token);

    for (uint i=startpos; i<num; i++) {
      // Deploy NFTs
      rockstar.safeMint(recipients[i], metadatas[i]);
    }
  }

  /**
   * @notice revokes ownership from the NFT Smart Contract
   * @param token The address of the token from which ownership needs to be revoked
   */
  function revokeOwnership(address token) external {
    IRockstar rockstar = IRockstar(token);
    rockstar.renounceOwnership();
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