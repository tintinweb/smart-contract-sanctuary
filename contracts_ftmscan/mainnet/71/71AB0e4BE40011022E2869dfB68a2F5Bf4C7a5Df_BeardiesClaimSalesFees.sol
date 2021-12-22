//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract BeardiesClaimSalesFees {
  address public beardiesAddress; // The beardies NFT contract address

  uint[] public beardiesClaimsAccumulated;
  mapping(uint => uint) public beardiesHolderClaims; // The number of claims each beardies id has done

  uint public numberTotalClaims = 0; // The total number of claims
  uint private totalBeardies = 2048;

  constructor(address _beardiesNFTAddress) {
    beardiesAddress = _beardiesNFTAddress;
    beardiesClaimsAccumulated.push(0);
  }

  function _finalAccumulatedClaim() private view returns (uint) {
    return beardiesClaimsAccumulated[numberTotalClaims];
  }

  function _getClaimable(uint _tokenId) private view returns (uint) {
    return _finalAccumulatedClaim() - beardiesClaimsAccumulated[beardiesHolderClaims[_tokenId]];
  }

  function ftmClaimable(address _owner) external view returns (uint) {
    if (numberTotalClaims == 0) {
      return 0;
    }

    uint balance = IERC721(beardiesAddress).balanceOf(_owner);
    uint amount = 0;
    for (uint i = 0; i < balance; ++i) {
      uint tokenId = IERC721Enumerable(beardiesAddress).tokenOfOwnerByIndex(_owner, i);
      amount += _getClaimable(tokenId);
    }

    return amount;
  }

  function ftmClaimableTokenIds(uint[] memory _tokenIds) external view returns (uint) {
    if (numberTotalClaims == 0) {
      return 0;
    }

    uint amount = 0;
    for (uint i = 0; i < _tokenIds.length; ++i) {
      amount += _getClaimable(_tokenIds[i]);
    }

    return amount;
  }

  function claim(uint _tokenId) external returns (uint) {
    require(IERC721(beardiesAddress).ownerOf(_tokenId) == msg.sender, "You are not the owner");
    require(numberTotalClaims > 0, "No claims available yet");
    uint amount = _getClaimable(_tokenId);
    beardiesHolderClaims[_tokenId] = numberTotalClaims;
    safeTransferFromUs(msg.sender, amount);
    return amount;
  }

  function claimMany(uint[] memory _tokenIds) external returns (uint) {
    require(numberTotalClaims > 0, "No claims available yet");

    // Checks that you own them
    uint amount = 0;
    for (uint i = 0; i < _tokenIds.length; ++i) {
      uint tokenId = _tokenIds[i];
      require(IERC721(beardiesAddress).ownerOf(tokenId) == msg.sender, "You are not the owner");
      amount += _getClaimable(tokenId);
      beardiesHolderClaims[tokenId] = numberTotalClaims;
    }
    safeTransferFromUs(msg.sender, amount);
    return amount;
  }

  // Return the amount claimed
  function claimAll() external returns (uint) {
    require(numberTotalClaims > 0, "No claims available yet");

    uint balance = IERC721(beardiesAddress).balanceOf(msg.sender);
    uint amount = 0;
    for (uint i = 0; i < balance; ++i) {
      uint tokenId = IERC721Enumerable(beardiesAddress).tokenOfOwnerByIndex(msg.sender, i);
      amount += _getClaimable(tokenId);
      beardiesHolderClaims[tokenId] =  numberTotalClaims;
    }
    safeTransferFromUs(msg.sender, amount);
    return amount;
  }

  function safeTransferFromUs(address _owner, uint _amount) private {
    // Do an FTM transfer
    uint balance = address(this).balance;
    uint amountToSend = balance > _amount ? _amount : balance;
    _owner.call{value: amountToSend}(""); // Don't care if it fails
  }

  receive() external payable {
    ++numberTotalClaims;

    beardiesClaimsAccumulated.push(
      beardiesClaimsAccumulated[beardiesClaimsAccumulated.length - 1] + msg.value / totalBeardies
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}