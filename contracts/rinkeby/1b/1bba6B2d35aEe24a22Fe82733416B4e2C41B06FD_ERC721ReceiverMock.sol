// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721Receiver.sol";

contract ERC721ReceiverMock is IERC721Receiver {


	function supportsInterface (bytes4 interfaceId) external pure returns (bool) {
		if (
			interfaceId == 0x01ffc9a7 // ERC165
			|| interfaceId == 0x80ac58cd // ERC721
			|| interfaceId == 0x780e9d63 // ERC721Enumerable
			|| interfaceId == 0x5b5e139f // ERC721Metadata
			|| interfaceId == 0x150b7a02 // ERC721TokenReceiver
			|| interfaceId == 0xe8a3d485 // contractURI ()
		) {
			return true;
		} else {
			return false;
		}
	}

	function onERC721Received(
	    address, 
	    address, 
	    uint256, 
	    bytes calldata
	)external override returns(bytes4) {
		//
	    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}