/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

// builder
contract BuilderShop {
    address factory = 0x66863edadF1218624129C092EA968e52464117B1;
    address owner = 0xa5EDeaeCF39E0D4bD9295c9F840c49ACFE9D6691;

    event Minted(address contractAddress);
    event ReceivedData(string name, string pieceId, string symbol, string artistName, string tokenURI, uint256 tokens, address recipient);

    constructor() {

    }

    function setFactory(address newFactory) public {
        require(msg.sender == owner);
        factory = newFactory;
    }

    function mintACryptoArtistContractWithCheck(
        string memory name,
        string memory pieceId,
        string memory symbol,
        string memory artistName,
        string memory tokenURI,
        uint256 num_tokens,
        address firstRecipient
    )
    public {
        bytes memory payload = abi.encodeWithSignature(
            "createNewCryptoArtistsInstance(string,string,string,string,string,uint256,address)",
            name,pieceId,symbol,artistName,tokenURI,num_tokens,firstRecipient);
        (bool success, bytes memory result) = factory.call(payload);

        require(success, "Minting failed");

        // Decode data
        address mintedNftAddress = abi.decode(result, (address));
        emit Minted(mintedNftAddress);
    }

    function mintACryptoArtistContractWithoutCheck(
        string memory name,
        string memory pieceId,
        string memory symbol,
        string memory artistName,
        string memory tokenURI,
        uint256 num_tokens,
        address firstRecipient
    )
    public {
        bytes memory payload = abi.encodeWithSignature(
            "createNewCryptoArtistsInstance(string,string,string,string,string,uint256,address)",
            name,pieceId,symbol,artistName,tokenURI,num_tokens,firstRecipient);
        (bool success, bytes memory result) = factory.call(payload);

        require(success, "Minting failed");

        // Decode data
        address mintedNftAddress = abi.decode(result, (address));
        emit Minted(mintedNftAddress);
    }

    function createNewCryptoArtistsInstance(
        string memory name,
        string memory pieceId,
        string memory symbol,
        string memory artistName,
        string memory tokenURI,
        uint256 num_tokens,
        address firstRecipient
    )
    public {
        emit ReceivedData(name, pieceId, symbol, artistName, tokenURI, num_tokens, firstRecipient);
    }
}