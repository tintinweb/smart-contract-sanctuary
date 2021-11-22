/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

/** 
 *  SourceUnit: d:\Projects\ibl\roulette-contract\contracts\OpenBox.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {
    function burn(uint256 tokenId) external;
}


/** 
 *  SourceUnit: d:\Projects\ibl\roulette-contract\contracts\OpenBox.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Roulette is IERC721Receiver {

    IERC721 public nft;

    constructor(IERC721 _nft) {
        nft = _nft;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4)
    {
        nft.burn(tokenId);

        return IERC721Receiver.onERC721Received.selector;
    }

}