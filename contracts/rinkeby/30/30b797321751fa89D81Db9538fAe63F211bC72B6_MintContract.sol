//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface INFTContract {
    function nfts(uint256 nftId)
        external
        view
        returns (
            uint256,
            string memory,
            string memory,
            uint256,
            bool,
            uint256
        );

    function nftOwners(uint256 nftId) external view returns (address);

    function mint(
        address _from,
        string memory _name,
        string memory _uri
    ) external;

    function burnNFT(uint256 _nftId) external;

    function transferNFT(address _to, uint256 _nftId) external;

    function getNFTLevelById(uint256 _nftId) external returns (uint256);

    function getNFTById(uint256 _nftId)
        external
        returns (
            uint256,
            string memory,
            string memory,
            uint256
        );

    function setNFTLevelUp(uint256 _nftId) external;

    function setNFTURI(uint256 _nftId, string memory _uri) external;

    function ownerOf(uint256 _nftId) external returns (address);

    function balanceOf(address _from) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTContract.sol";

contract MintContract {
    INFTContract nft_;

    string NFT_NAME = "GamyFi TRITON NFT";
    string NFT_URI =
        "https://ipfs.io/ipfs/bafybeibt65tydbeh5qoyalk2fd7tlkbxbinu5vxrdqotjhpgattroueeii";

    constructor(address _nft) {
        nft_ = INFTContract(_nft);
    }

    function mint() public {
        require(nft_.balanceOf(msg.sender) == 0, "MintContract: You have NFT");

        nft_.mint(
            msg.sender,
            "GamyFi TRITON NFT",
            "https://ipfs.io/ipfs/bafybeibt65tydbeh5qoyalk2fd7tlkbxbinu5vxrdqotjhpgattroueeii"
        );
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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