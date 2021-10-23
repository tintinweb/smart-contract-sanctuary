pragma solidity ^0.8.4;

//implement erc721 safeTransferFrom

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPPB {
  function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

contract StakeForCharity {

  IERC721 immutable erc721;

  mapping(address => depositInfo) public accounts;
  mapping(uint => address) public tokenOwners;

  uint256 public charityBal;
  string public charityName;

  struct depositInfo {
    uint256 pointsBalance;
    uint256 totalPoints;
    uint64 settleTime;
    uint16 bearsDeposited;
  }

  constructor (address _erc721, string memory _charityName) {
    erc721 = IERC721(_erc721);
    charityName = _charityName;
  }

  function enterStaking (uint tokenId) external {
    require(erc721.ownerOf(tokenId) != address(this), "Already deposited");
    require(erc721.ownerOf(tokenId) == msg.sender, "You are not owner");
    settlePoints(msg.sender);
    accounts[msg.sender].bearsDeposited += 1;
    tokenOwners[tokenId] = msg.sender;
    erc721.safeTransferFrom(msg.sender, address(this), tokenId);
  }

  function multiEnterStaking (uint[] memory tokenIds) external {
    settlePoints(msg.sender);
    for (uint i = 0; i<tokenIds.length; i++){
      require(erc721.ownerOf(tokenIds[i]) != address(this), "Already deposited");
      require(erc721.ownerOf(tokenIds[i]) == msg.sender, "You are not owner");
      tokenOwners[tokenIds[i]] = msg.sender;
      erc721.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
    }
    accounts[msg.sender].bearsDeposited += uint16(tokenIds.length);
  }

  function exitStaking (uint tokenId) external {
    require(tokenOwners[tokenId] == msg.sender, "No NFT deposited"); // Will also return if attempting to call enterStaking and exitStaking on same block
    settlePoints(msg.sender);
    accounts[msg.sender].bearsDeposited -= 1;
    delete(tokenOwners[tokenId]);
    erc721.safeTransferFrom(address(this), msg.sender, tokenId);
  }

  function multiExitStaking (uint[] memory tokenIds) external {
    settlePoints(msg.sender);
    for (uint i = 0; i<tokenIds.length; i++){
      require(tokenOwners[tokenIds[i]] == msg.sender, "No NFT deposited"); // Will also return if attempting to call enterStaking and exitStaking on same block
      delete(tokenOwners[tokenIds[i]]);
      erc721.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
    }
    accounts[msg.sender].bearsDeposited -= uint16(tokenIds.length);
  }

  function settlePoints(address user) public {
    uint deltaPts = calculateAccruedPoints(user);
    charityBal += deltaPts;
    accounts[user].pointsBalance += deltaPts;
    accounts[user].settleTime = uint64(block.timestamp);
  }

  function calculateAccruedPoints(address user) internal view returns (uint) {
    return accounts[user].bearsDeposited * (block.timestamp - accounts[user].settleTime);
  }

  function calculateGrossPoints() public view returns(uint) {
    IPPB ippb = IPPB(address(erc721));
    uint[] memory tokenIdList = ippb.walletOfOwner(address(this));
    uint grossPts = charityBal;
    address owner;
    for (uint i=0; i<tokenIdList.length; i++){
      address user = tokenOwners[tokenIdList[i]];
      grossPts += block.timestamp - accounts[user].settleTime;
    }
    return grossPts;
  }

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4){
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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