pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface targetSC {
  function allowSmartcontractMinting(address to, uint amount) external;
  function preventSmartcontractAccessMint(address to, uint amount) external;
}

contract TestMinterSC is IERC721Receiver{
  targetSC tsc = targetSC(0x166A473c9daf81c3593a2208fCFA5846d45cE183);

  constructor(){
  }

  function mintFromTargetSC(uint amount_) public {
    tsc.allowSmartcontractMinting(address(this), amount_);
  }

  function mintFromTargetSCPreventionFunction(uint amount_) public {
    tsc.preventSmartcontractAccessMint(address(this), amount_);
  }

  function changeTargetSC(address newTSC) public {
    tsc = targetSC(newTSC);
  }

  fallback() external payable {
            // React to receiving ether
        }
  receive() external payable {
            // React to receiving ether
        }

  /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

