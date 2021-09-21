// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title 'Chain Future is Coming'
 * The 'Chain Future is Coming' is the initial line of NFT art prepared by BlockAI.art in our 'modifai' technique (more on the BlockAI family homepage - that is www.BlockAI.in).
 * From the mission side - this collection\line serves to commemorate (entering in the blockchain) important events awaiting our generation in the near future, which are connected to the blockchain technology or market or ahich are also generally important and we want to make a data stamp through an unique NFT. 
 * 
 * In the practice of this line, each NFT token is minted as follows:
 * 1. A background image is purchased with full rights of any possible editing (alteration).
 * 2. Keywords about a selected, particularly interesting event in the blockchain ecosystem in a short time are applied to the background.
 * 3. Information is placed about our (BlockAI) Ethereum address of this smart contract, from which we generate all NFT tokens at this under this contract.
 * 4. The final layout is created and an image is generated from it.
 * 5. The image produced is analyzed by the AI ??generator and a custom version of the image in terms of AI is created from it.
 * 6. We combine the initial image (created by us) and the final image (corrected by AI) to an animated GIF file, using fading.
 * 7. The final GIF file is the content of the NFT token along with this description.
 * 
 * This contract is minted (as all other BlockAI contracts) from our main address 0x7CFb46DC2Cc625065AF4d5421C646266D790F3BB.
 * This is not third-party contract, but totally ours.
 * This contract id deployed on Polygon (Matic) network.
 *
 * Practically any income from initially selling any NFT (not on secondary market) from this contract is used for improving liquidity of our BAIme token (more about it on www.BlockAI.site, description soon).

*/

contract ChainFutureisComing is ERC721Tradable {
    
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("ChainFutureisComing", "CFIS", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://blockai.art/assets/API/ChainFutureIsComing/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://blockai.art/assets/API/ChainFutureIsComing/collection.json";
    }
}