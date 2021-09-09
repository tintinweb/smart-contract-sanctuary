/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MintBot {
    function boot(address s, address to) external {
        ITheSevens seven = ITheSevens(s);
        seven.mintTokens{value : 0.07 ether}(1);
        seven.safeTransferFrom(address(this), to, seven.nextTokenId() - 1);
    }
}

// File contracts/TheSevens.sol

pragma solidity =0.8.7;

interface ITheSevens {
    function nextTokenId() external returns (uint256);

    function mintTokens(uint256 count) external payable;

    /**
 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
 *
 * Requirements:
 *
 * - `from` cannot be the zero address.
 * - `to` cannot be the zero address.
 * - `tokenId` token must exist and be owned by `from`.
 * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
 *
 * Emits a {Transfer} event.
 */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}