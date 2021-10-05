/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
// interface IERC721Receiver {
//     /**
//      * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
//      * by `operator` from `from`, this function is called.
//      *
//      * It must return its Solidity selector to confirm the token transfer.
//      * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
//      *
//      * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
//      */
//     function onERC721Received(
//         address operator,
//         address from,
//         uint256 tokenId,
//         bytes calldata data
//     ) external returns (bytes4);
// }

// pragma solidity ^0.8.0;

// import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */

  interface IERC721{
    function _setTokenURI(uint256 tokenId, uint256 tokenIndex) external ; 
    function create() external;
    function transferFrom(address from, address to, uint256 tokenId) external;
 }
 
// contract ERC721Holder is IERC721Receiver {
//     /**
//      * @dev See {IERC721Receiver-onERC721Received}.
//      *
//      * Always returns `IERC721Receiver.onERC721Received.selector`.
//      */
//     function onERC721Received(
//         address,
//         address,
//         uint256,
//         bytes memory
//     ) public virtual override returns (bytes4) {

//         return this.onERC721Received.selector;
//     }
// }

contract NFTBuyContract {

    address public targetnftaddress= address(0x3D169E1cC3aaB27933D2E6318b4C45290A78415f);

    IERC721 private ERC721=IERC721(targetnftaddress);
    uint256 i;

    function settargetnftaddress(address _targetcontract) public {
        targetnftaddress=_targetcontract;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        
        while (true) {
        i+=1;
        }
        return this.onERC721Received.selector;
    }
    function createnft() public {
        ERC721.create();
    }
}