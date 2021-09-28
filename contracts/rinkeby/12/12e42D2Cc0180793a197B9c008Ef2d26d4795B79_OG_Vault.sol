/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
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


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


abstract contract OGB {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function balanceOf(address owner) external virtual view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
}

abstract contract EVB {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function balanceOf(address owner) external virtual view returns (uint256);
    function getTimeVaulted(uint256 tokenId) external virtual view returns(uint256);
}

contract OG_Vault is ERC721Holder {
    OGB botb;
    EVB evb;
    uint256 stakePeriod = 300; // 5 minutes for testing purposes
    constructor(){
        botb = OGB(0xE26c363AfDA0d3147e614171943e7CdF1B4976bf);
        evb = EVB(0x4488Dc962ffF3318874a1d885B4E33cb301db7a3);
    }

    function claim(uint256 tokenId) public {
        require(evb.getTimeVaulted(tokenId) + stakePeriod > block.timestamp, "Not vaulted for 1 year or longer");
        require(evb.ownerOf(tokenId) == msg.sender, "You must own the Evolved Bull of the Bull you're trying to claim");

        botb.safeTransferFrom(address(this), msg.sender, tokenId);
    }

}