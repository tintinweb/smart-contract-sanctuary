/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface LootContract {
    function claim(uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
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

contract MultiLoot is IERC721Receiver {
    
    
    LootContract _lootContract = LootContract(0x97f05390de212B8D9104D3b64C5916Ea56f713fB);
    
    function getMultiLoot(uint256[] calldata tokenIds) public {
    
        for (uint i; i < tokenIds.length; i++) {
            _lootContract.claim(tokenIds[i]);
            _lootContract.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            
        }   
            
    }
    
     function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    
    
}