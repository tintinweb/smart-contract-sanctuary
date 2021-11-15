// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721Receiver.sol";

contract ERC721ReceiverMock is IERC721Receiver {

    event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);

    constructor () {}

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
        public override returns (bytes4)
    {
     
        emit Received(operator, from, tokenId, data, gasleft());
        //bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")));
        return bytes4(0x150b7a02);
    }
}

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

