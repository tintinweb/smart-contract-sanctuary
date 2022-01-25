//SPDX-License-Identifier: No-License
//No usage in any form allowed.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
* This is NEITHER a security nor a utility token of any kind.
* This token CANNOT be traded, transferred or used for anything.
* People will receive this token FREE OF CHARGE as this is a simple AD CAMPAIGN.
*
* This is more or less a prototype for evaluating a new business model in the blockchain space.
*
* (c) Wavect® (trademark registered in Austria), https://wavect.io
* Software agency specialized on Blockchain (Smart-Contracts, Web3, ..).
* All project partners are fully doxxed and try to comply with Austrian law, as Wavect is a registered company in Austria.
*/
contract AirdropAds is Context {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
    * Nobody is allowed to transfer this ERC721 as it's not a token per se, but
    * rather just a marketing campaign to be able to show the token on specific wallets on Etherscan, OpenSea, etc.
    *
    * This method should always fail, so there is no way to trade this token. Making it basically useless.
    */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(false);
        // NFT cannot be transferred, traded or anything else. It's just here to be indexed by Etherscan, etc.
    }

    /**
    * This method enables people to remove the token from their wallet.
    * We've added this in case someone doesn't want to "own" this token.
    */
    function burn() external {
        // might not hide it from OpenSea
        emit Transfer(_msgSender(), address(0xdead), uint256(uint160(_msgSender())));
        // remove token from etherscan balance
    }

    function balanceOf(address owner) external pure returns (uint256) {
        return 1;
        // non transferable, so everyone basically just gets one token (even without having emitted a transfer event).
    }

    function airdrop(address[] calldata wallets) external {
        for (uint i = 0; i < wallets.length; i++) {
            emit Transfer(address(0), wallets[i], uint256(uint160(wallets[i])));
            // become indexed by Etherscan, OpenSea etc.
        }
    }

    function tokenURI(uint256 tokenId) external pure returns (string memory) {
        return "https://wavect.io/airdrop-ad/metadata.json?ref=";
    }

    function contractURI() external pure returns (string memory) {
        return "https://wavect.io/airdrop-ad/contract-metadata.json";
    }

    /**
   * @dev See {IERC721Metadata-name}.
     */
    function name() external pure returns (string memory) {
        return "www.wavect.io - Blockchain agency AD";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external pure returns (string memory) {
        return "Wavect.io";
    }

    /**
    * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external pure returns (address) {
        return address(uint160(tokenId));
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external {
        require(false);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) external pure returns (address) {
        return address(uint160(tokenId));
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) external pure returns (bool) {
        return true;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(false);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(false);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external {
        require(false);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        require(false);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}