// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract GANMasks is Ownable, ERC721 {

    using SafeMath for uint256;

    // Provenance Hash of all GANMASKS
    string public constant PROVENANCE_HASH = "bbbe617ba4cc4a581350472f8a05cff398828e03ab5623646886652c4e01184f";

    // Maximum supply of tokens
    uint256 public constant MAX_SUPPLY = 10500;

    // Base URI to get metadata of all GAN Masks (will be changed to ipfs link after the sale)
    string internal baseURI = "https://ganmasks.com/api/";

    constructor() ERC721("GANMasks", "GM") {
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Get price of the token
     */
    function getTokenPrice() public view returns (uint256) {
        uint tokenId = totalSupply();
        require(tokenId < MAX_SUPPLY, "All tokens sold out");

        if (tokenId < 4000) {
          return 125000000000000000;
        }
        else if (tokenId < 7000) {
          return 250000000000000000;
        }
        else if (tokenId < 9000) {
          return 500000000000000000;
        }
        else {
          return 1000000000000000000;
        }
    }

    /**
     * @dev Mint a token
     */
    function mintToken(uint256 numTokens) public payable {
        require(numTokens > 0 && numTokens <= 20, "You can only mint between 1 and 20 tokens at a time");
        require(getTokenPrice().mul(numTokens) == msg.value, "Ether value sent is incorrect");

        for (uint i = 0; i < numTokens; i++) {
            uint tokenId = totalSupply() ;
            require(tokenId < MAX_SUPPLY, "Cannot mint more tokens than the maximum limit");
            _safeMint(msg.sender, tokenId);
        }
    }

    /**
     * @dev Set the Base URI of tokens
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Withdraw ether from the contract
     */
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}