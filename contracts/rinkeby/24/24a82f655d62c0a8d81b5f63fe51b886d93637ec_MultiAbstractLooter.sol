/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface AbstractLootContract {
    function mintWithLoot(uint256 lootId) external payable;
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

contract MultiAbstractLooter is IERC721Receiver {
    
    
    AbstractLootContract _lootContract = AbstractLootContract(0x229030A2d55439B84568b076C325Ea1B99D25B2f);
    
    function getMultiLoot(uint256[] calldata tokenIds) public payable {
        
        require(tokenIds.length * 0.015 ether == msg.value);
    
        for (uint i; i < tokenIds.length; i++) {
            _lootContract.mintWithLoot{value: 0.015 ether}(tokenIds[i]);
            _lootContract.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            
        }   
            
    }
    
     function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    
    
}