// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract EventEmitter {
    
    enum TYPE {
        NATIVE_COIN_NFT_721,
        NATIVE_COIN_NFT_1155,
        ERC_20_NFT_721, 
        ERC_20_NFT_1155
    }

    event SporesNFTMint(
        address indexed _to,
        address indexed _nft,
        uint256 _id,
        uint256 _amount
    );

    event SporesNFTMarketTransaction(
        address indexed _buyer,
        address indexed _seller,
        address _paymentReceiver,
        address _contractNFT,
        address _paymentToken,
        uint256 indexed _tokenId,
        uint256 _price,
        uint256 _amount,
        uint256 _fee,
        uint256 _sellId,
        TYPE _tradeType
    );

    constructor() {
    }

    function emitEvent(
        address _to,
        address _nft,
        uint256 _id,
        uint256 _amount
    ) external {
        emit SporesNFTMint(_to, _nft, _id, _amount);
    }

    function emitEvent(
        address _buyer,
        address _seller,
        address _paymentReceiver,
        address _contractNFT,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _price,
        uint256 _amount,
        uint256 _fee,
        uint256 _sellId,
        TYPE _tradeType
    ) external {
        emit SporesNFTMarketTransaction(_buyer, _seller, _paymentReceiver, _contractNFT, _paymentToken, _tokenId, _price, _amount, _fee, _sellId, _tradeType);
    }
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
  },
  "libraries": {}
}