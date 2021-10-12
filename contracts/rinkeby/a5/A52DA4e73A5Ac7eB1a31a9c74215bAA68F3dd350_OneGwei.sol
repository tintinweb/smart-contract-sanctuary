// SPDX-License-Identifier: MIT

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

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract OneGwei is IERC721Receiver {

    uint256 constant AMOUNT_PER_TX = 1 gwei;

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        require(address(this).balance > AMOUNT_PER_TX, "Not enough ether in contract.");

        (bool sent, bytes memory data) = payable(operator).call{ value: AMOUNT_PER_TX }("");
        require(sent, "Failed to send ether.");

        return this.onERC721Received.selector;
    }

    receive () external payable { }
}