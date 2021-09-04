/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface LootContract {
    function claim(uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}


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

contract MultiMap is IERC721Receiver {
    
    
    LootContract _lootContract = LootContract(0x1dfe7Ca09e99d10835Bf73044a23B73Fc20623DF);
    
    function getMultiLoot(uint256[] calldata tokenIds) public {
    
        uint256 mintedAmount = 0;
        
        for (uint i = 0; i < tokenIds.length; i++) {

            try _lootContract.claim(tokenIds[i]) {
                _lootContract.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
                mintedAmount++;
            } catch {
            }
        }
    }
    
     function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
}