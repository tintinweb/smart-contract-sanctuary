pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract MintABI {
    function mint(address to, uint256 tokenId) public virtual {}

}

contract Withdrawal {
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {}
}

contract TestMiddleware is IERC721Receiver{

    event TokenFreezed (address indexed from, uint256 indexed tokenId);
    event TokenWithDrawn (address indexed to, uint256 indexed tokenId);

    MintABI private tokenMinter;
    Withdrawal private nftContract;

    address private nft = 0x38E6AE4EfC676EfeCaCeA4a2ff36Ef6E35c4AeFc;

    function setMintABI(address _contractAddress) public {
        tokenMinter = MintABI(_contractAddress);
    }

    function getMintABI() public view returns(address) {
        return address(tokenMinter);
    }

    function setNftContract(address _contractAddress) public {
        nftContract = Withdrawal(_contractAddress);
    }

    function getNftContract() public view returns(address) {
        return address(nftContract);
    }


    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override external returns (bytes4){
        require(nft == msg.sender,"Item from unknown contract");        
        tokenMinter.mint(from,tokenId);
        emit TokenFreezed(from,tokenId);
        return this.onERC721Received.selector;
    }


    function withdrawItem(address to, uint256 tokenId) public {
        nftContract.safeTransferFrom(address(this),to,tokenId);
        emit TokenWithDrawn(to,tokenId);
    }

}

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

