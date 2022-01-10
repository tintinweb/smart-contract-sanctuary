pragma solidity ^0.8.0;

import "./ERC721.sol";

struct NFTData{
    uint256[] layers;
    uint256 mouldId;
}

contract AnmolNFT is ERC721 {
    address NFTFactory;
    mapping(uint256 => NFTData) public nftData;
    uint256 public nftCounter;



    constructor() ERC721('AnmolNFT', 'anmlNFT') {
    }

    function mint(address to, uint256[] memory _layers, uint256 _mouldId) public {
        _mint(to, nftCounter);
        nftData[nftCounter] = NFTData(_layers, _mouldId);
        nftCounter++;
    }

    function changeNFTFactory(address newNFTFactory) public {
        NFTFactory = newNFTFactory;
    }
}