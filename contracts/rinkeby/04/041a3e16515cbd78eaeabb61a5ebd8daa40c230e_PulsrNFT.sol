// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// This is Pulsr www.pulsr.ai 
// This NFT is for airdrop use only
//
// Thanks to Galactic and 0x420 for their gas friendly ERC721S implementation.
//
// -----------------------------------------------------------------------------
//

import "./ERC721S.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract PulsrNFT is
    ERC721Sequential,
    Ownable
{

    uint256 public constant MAX_SUPPLY = 3909;
    string public baseURI = "https://ipfs.io/ipfs/QmRYaUrM9vGvKmm73MxEw55GUqsKDSvWc3XAAoCowWBF2J/";

    constructor() ERC721Sequential("Pulsr Community Badge Special-Edition 001", "PULSR") {
    }

    // Minting by owner only
    function mint(uint256 numTokens) external onlyOwner {

        require(totalMinted() + numTokens <= MAX_SUPPLY, "Sold Out");

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender);
        }
    }

    // return the url path to the metadata used by opensea
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // set the url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    // withdraw ERC20 tokens received by mistake
    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    // withdraw ETH received by mistake
    function withdraw(address payable to) public payable onlyOwner {
        to.transfer(address(this).balance);
    }
}