// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract AccessControl {
  address internal _admin;
  address internal _owner;

  modifier onlyAdmin() {
    require(msg.sender == _admin, "unauthorized");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner, "unauthorized");
    _;
  }

  function changeAdmin(address newAdmin) external onlyOwner {
    _admin = newAdmin;
  }

  function changeOwner(address newOwner) external onlyOwner {
    _owner = newOwner;
  }

  function owner() external view returns (address) {
    return _owner;
  }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
  /** Events */

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

  /** Views */

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /** Mutators */

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
  function setApprovalForAll(address operator, bool approved) external;

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721Receiver.sol";

abstract contract NFTCollectionV2 is AccessControl, IERC165, IERC721, IERC721Metadata {
  /** @dev IERC721 Fields */

  mapping(address => uint256) internal _balances;
  mapping(address => mapping(address => bool)) internal _operatorApprovals;
  mapping(uint256 => address) internal _owners;
  mapping(uint256 => address) internal _tokenApprovals;

  /** @dev IERC721Enumerable */

  uint256 internal _totalSupply;

  string internal _baseURI;

  /** @dev IERC165 Views */

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId;
  }

  /** @dev IERC721 Views */

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner_) external view override returns (uint256 balance) {
    return _balances[owner_];
  }

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view override returns (address operator) {
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner_, address operator) external view override returns (bool) {
    return _operatorApprovals[owner_][operator];
  }

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view override returns (address) {
    return _owners[tokenId];
  }

  /** @dev IERC721 Mutators */

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
  function approve(address to, uint256 tokenId) external override {
    address owner_ = _owners[tokenId];

    require(to != owner_, "caller may not approve themself");
    require(msg.sender == owner_ || _operatorApprovals[owner_][msg.sender], "unauthorized");

    _approve(to, tokenId);
  }

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
  ) external override {
    _ensureApprovedOrOwner(msg.sender, tokenId);
    _transfer(from, to, tokenId);

    if (_isContract(to)) {
      IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, "");
    }
  }

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
  ) external override {
    _ensureApprovedOrOwner(msg.sender, tokenId);
    _transfer(from, to, tokenId);

    if (_isContract(to)) {
      IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
    }
  }

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
  function setApprovalForAll(address operator, bool approved) external override {
    require(operator != msg.sender, "caller may not approve themself");

    _operatorApprovals[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

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
  ) external override {
    _ensureApprovedOrOwner(msg.sender, tokenId);
    _transfer(from, to, tokenId);
  }

  /** IERC721Metadata Views */

  function tokenURI(uint256 tokenId) external view override returns (string memory) {
    return string(abi.encodePacked(_baseURI, _toString(tokenId), ".json"));
  }

  /** Useful Methods */

  function changeBaseURI(string memory newURI) external onlyAdmin {
    _baseURI = newURI;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /** Helpers */

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) private {
    _tokenApprovals[tokenId] = to;

    emit Approval(_owners[tokenId], to, tokenId);
  }

  function _ensureApprovedOrOwner(address spender, uint256 tokenId) private view {
    address owner_ = _owners[tokenId];

    require(
      spender == owner_ || spender == _tokenApprovals[tokenId] || _operatorApprovals[owner_][spender],
      "unauthorized"
    );
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function _toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function _isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;

    assembly {
      size := extcodesize(account)
    }

    return size > 0;
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    require(_owners[tokenId] == from, "transfer of token that is not own");
    require(to != address(0), "transfer to the zero address");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./AuthorizedV2.sol";
import "./NFTCollectionV2.sol";

contract FanEpackCollection is AuthorizedV2, NFTCollectionV2 {
  /** Fields */

  bytes32 private immutable _claimSeparator;

  mapping(address => uint256) private _claimed;

  constructor(address authority_, string memory baseURI_) {
    _admin = msg.sender;
    _owner = msg.sender;

    _authority = authority_;
    _baseURI = baseURI_;

    _claimSeparator = keccak256("Claim(address account,uint256 earned)");
  }

  /** @dev IERC721Metadata Views */

  /**
   * @dev Returns the token collection name.
   */
  function name() external pure override returns (string memory) {
    return "FanEpack Collection";
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external pure override returns (string memory) {
    return "FEC";
  }

  /** @dev Admin */

  function changeAuthority(address newAuthority) external onlyAdmin {
    _authority = newAuthority;
  }

  /** @dev Claim */

  function claimed(address wallet) external view returns (uint256) {
    return _claimed[wallet];
  }

  function claim(
    uint256 quantity,
    uint256 earned,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(verify(keccak256(abi.encode(_claimSeparator, msg.sender, earned)), v, r, s), "invalid message");
    require(quantity + _claimed[msg.sender] <= earned, "more than earned");

    for (uint256 i = 1; i <= quantity; i++) {
      _owners[_totalSupply + i] = msg.sender;

      emit Transfer(address(0), msg.sender, _totalSupply + i);
    }

    _balances[msg.sender] += quantity;
    _claimed[msg.sender] += quantity;
    _totalSupply += quantity;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract AuthorizedV2 {
  bytes32 internal immutable _domainSeparator;

  address internal _authority;

  constructor() {
    bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    _domainSeparator = keccak256(
      abi.encode(typeHash, keccak256(bytes("MetaFans")), keccak256(bytes("1.0.0")), block.chainid, address(this))
    );
  }

  function verify(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal view returns (bool) {
    return _authority == ecrecover(keccak256(abi.encodePacked("\x19\x01", _domainSeparator, hash)), v, r, s);
  }
}