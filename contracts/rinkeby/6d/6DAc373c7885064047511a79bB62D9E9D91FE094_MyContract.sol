/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
contract MyContract is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}