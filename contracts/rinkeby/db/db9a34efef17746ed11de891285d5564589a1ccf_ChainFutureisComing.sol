// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Chain Future is Coming
 * Chain Future is Coming is the initial line of NFT art prepared by BlockAI.art in our 'modifai' technique (more on the BlockAI homepage - that is www.BlockAI.in).
 * From the mission side - it serves to commemorate (entering in the blockchain) important events awaiting the blockchain market in the near future.
 * Practically any income from initially selling the NFT (not on secondary market) is used for improving liquidity of our BAIme token (more about it on www.BlockAI.site).
 * 
 * In the practice of this line, each NFT token is minted as follows:
 * 1. A background image is purchased with full rights of any possible editing (alteration).
 * 2. Keywords about a selected, particularly interesting event in the blockchain ecosystem in a short time are applied to the background.
 * 3. Information is placed about our (BlockAI) Ethereum address, from which we generate all our smart contratcs, including this NFT line, and thus also each of the NFT tokens generated under this contract.
 * 4. The final layout is created and an image is generated from it.
 * 5. The image produced is analyzed by the AI ??generator and a custom version of the image in terms of AI is created from it.
 * 6. We combine the initial image (created by us) and the final image (corrected by AI) to an animated GIF file, using fading.
 * 7. The final GIF file is the content of the NFT token along with this description.
*/

contract ChainFutureisComing is ERC721Tradable {
    
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("ChainFutureisComing", "FCOL", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://blockai.art/assets/API/ChainFutureIsComing/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://blockai.art/assets/API/ChainFutureIsComing/collection.json";
    }
}