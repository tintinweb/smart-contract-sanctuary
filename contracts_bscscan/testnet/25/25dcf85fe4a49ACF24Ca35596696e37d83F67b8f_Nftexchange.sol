/**
 *Submitted for verification at BscScan.com on 2021-11-27
*/

pragma solidity ^0.8.0;

//import './TransferHelper.sol';

contract Nftexchange {

    uint256 public ERC721Received;
    uint256 public ERC1155Received;
    //0xb88d4fde
    bytes4 private constant IERC721Received = bytes4(keccak256(bytes('onERC721Received(address,address,uint256,bytes)')));
    bytes4 private constant IERC1155BatchReceived = bytes4(keccak256(bytes('onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)')));

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        ERC721Received = 1000;
        return IERC721Received;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        ERC1155Received = 1000;
        return IERC1155BatchReceived;
    }
}