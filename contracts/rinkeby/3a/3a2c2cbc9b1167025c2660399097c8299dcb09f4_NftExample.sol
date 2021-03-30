pragma solidity 0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract NftExample is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("NathanNFT", "NNFT") {}

    function mintNft(address receiver, string memory tokenURI) external onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI);

        return newNftTokenId;
    }
}