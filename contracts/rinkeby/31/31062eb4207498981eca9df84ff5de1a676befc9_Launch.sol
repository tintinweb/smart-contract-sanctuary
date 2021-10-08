// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPresale.sol";

interface IAdmin {
  /** Mutators */

  function changeAdmin(address) external;

  function changeBaseURI(string memory) external;

  function changeLaunchContract(address) external;

  function changePresaleContract(IPresale) external;

  function promoMint(uint256, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPresale {
  /** Events */

  event Purchase(address indexed wallet, uint256 quantity);

  event Redemption(address indexed wallet);

  /** Views */

  function beginTime() external view returns (uint256);

  function endTime() external view returns (uint256);

  function totalVouchers() external view returns (uint256);

  function walletVouchers(address) external view returns (uint256);

  /** Mutators */

  function purchase(uint256) external payable;

  function redeem() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IAdmin.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IPresale.sol";

contract MetafansCollection is IAdmin, IERC165, IERC721, IERC721Metadata, IMinter {
  /** @dev IERC721 Fields */

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  mapping(uint256 => address) private _owners;
  mapping(uint256 => address) private _tokenApprovals;

  /** @dev IAdmin Fields */

  address private _admin;
  string private _baseURI;
  address private _launchContract;
  IPresale private _presaleContract;
  uint256 private immutable _promoQuantity;

  /** @dev IERC721Enumerable */

  uint256 private _totalSupply;
  uint256 private immutable _totalSupplyLimit;

  constructor(
    string memory baseURI_,
    uint256 promoQuantity_,
    uint256 totalSupplyLimit_
  ) {
    _admin = msg.sender;

    _baseURI = baseURI_;
    _promoQuantity = promoQuantity_;
    _totalSupplyLimit = totalSupplyLimit_;

    _totalSupply = promoQuantity_;
  }

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
  function balanceOf(address owner) external view override returns (uint256 balance) {
    return _balances[owner];
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
  function isApprovedForAll(address owner, address operator) external view override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view override returns (address owner) {
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
    address owner = _owners[tokenId];

    require(to != owner, "MFC: caller may not approve themself");
    require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "MFC: unauthorized");

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

    if (tx.origin != to) {
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

    if (tx.origin != to) {
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
    require(operator != msg.sender, "MFC: caller may not approve themself");

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

  /** @dev IAdmin Mutators */

  function changeAdmin(address newAdmin) external override {
    require(msg.sender == _admin, "MFC: unauthorized");

    _admin = newAdmin;
  }

  function changeBaseURI(string memory newURI) external override {
    require(msg.sender == _admin, "MFC: unauthorized");

    _baseURI = newURI;
  }

  function changeLaunchContract(address newContract) external override {
    require(msg.sender == _admin, "MFC: unauthorized");

    _launchContract = newContract;
  }

  function changePresaleContract(IPresale newContract) external override {
    require(msg.sender == _admin, "MFC: unauthorized");

    _presaleContract = newContract;
  }

  function promoMint(uint256 tokenId, address to) external override {
    require(msg.sender == _admin, "MFC: unauthorized");
    require(tokenId < _promoQuantity, "MFC: over promo limit");
    require(_owners[tokenId] == address(0), "MFC: already minted");

    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);
  }

  /** @dev IERC721Metadata Views */

  /**
   * @dev Returns the token collection name.
   */
  function name() external pure override returns (string memory) {
    return "Metafans Collection";
  }

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external pure override returns (string memory) {
    return "MFC";
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view override returns (string memory) {
    return string(abi.encodePacked(_baseURI, toString(tokenId), ".json"));
  }

  /** IMinter Mutators */

  function mint(address to, uint256 quantity) external override {
    require(msg.sender == _launchContract || msg.sender == address(_presaleContract), "MFC: unauthorized");
    require(
      _totalSupply + _presaleContract.totalVouchers() + quantity <= _totalSupplyLimit,
      "MFC: over total supply limit"
    );

    for (uint256 i = 0; i < quantity; i++) {
      _owners[_totalSupply + i] = to;

      emit Transfer(address(0), to, _totalSupply + i);
    }

    _balances[to] += quantity;
    _totalSupply += quantity;
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
    address owner = _owners[tokenId];

    require(
      spender == owner || spender == _tokenApprovals[tokenId] || _operatorApprovals[owner][spender],
      "MFC: unauthorized"
    );
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) private pure returns (string memory) {
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
    require(_owners[tokenId] == from, "MFC: transfer of token that is not own");
    require(to != address(0), "MFC: transfer to the zero address");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
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

interface IMinter {
  /** Mutators */

  function mint(address to, uint256 quantity) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IMinter.sol";
import "./interfaces/IPresale.sol";

contract Presale is IPresale {
  /** @dev Immutable */

  uint256 private immutable _beginTime;
  uint256 private immutable _endTime;
  IMinter private immutable _minter;
  address private immutable _partnerWalletA;
  address private immutable _partnerWalletB;
  uint256 private immutable _price;
  uint256 private immutable _totalWalletLimit;
  uint256 private immutable _walletVoucherLimit;

  /** @dev Fields */

  uint256 private _totalVouchers;
  uint256 private _uniqueWallets;
  mapping(address => uint256) _walletVouchers;

  constructor(
    uint256 beginTime_,
    uint256 endTime_,
    IMinter minter_,
    address partnerWalletA_,
    address partnerWalletB_,
    uint256 price_,
    uint256 totalWalletLimit_,
    uint256 walletVoucherLimit_
  ) {
    _beginTime = beginTime_;
    _endTime = endTime_;
    _minter = minter_;
    _partnerWalletA = partnerWalletA_;
    _partnerWalletB = partnerWalletB_;
    _price = price_;
    _totalWalletLimit = totalWalletLimit_;
    _walletVoucherLimit = walletVoucherLimit_;
  }

  /** Views */

  function beginTime() external view override returns (uint256) {
    return _beginTime;
  }

  function endTime() external view override returns (uint256) {
    return _endTime;
  }

  function totalVouchers() external view override returns (uint256) {
    return _totalVouchers;
  }

  function walletVouchers(address wallet) external view override returns (uint256) {
    return _walletVouchers[wallet];
  }

  /** Mutators */

  function purchase(uint256 quantity) external payable override {
    require(block.timestamp > _beginTime, "PS: presale has not begun");
    require(block.timestamp < _endTime, "PS: presale has ended");
    require(msg.value == _price * quantity, "PS: incorrect ETH");

    if (_walletVouchers[msg.sender] == 0) {
      require((++_uniqueWallets) <= _totalWalletLimit, "PS: over total wallet limit");
    }

    require((_walletVouchers[msg.sender] += quantity) <= _walletVoucherLimit, "PS: over wallet voucher limit");

    uint256 shareB = msg.value / 10;
    uint256 shareA = msg.value - shareB;

    (bool sent, ) = _partnerWalletA.call{value: shareA}("");

    require(sent, "PS: failed to send partner A funds");

    (sent, ) = _partnerWalletB.call{value: shareB}("");

    require(sent, "PS: failed to send partner B funds");

    _totalVouchers += quantity;

    emit Purchase(msg.sender, quantity);
  }

  function redeem() external override {
    require(block.timestamp > _endTime, "PS: presale has not ended");

    uint256 quantity = _walletVouchers[msg.sender];

    require(quantity > 0, "PS: insufficient vouchers");

    delete _walletVouchers[msg.sender];

    emit Redemption(msg.sender);

    _minter.mint(msg.sender, quantity);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ILaunch.sol";
import "./interfaces/IMinter.sol";

contract Launch is ILaunch {
  /** @dev Immutable */

  uint256 private immutable _beginTime;
  IMinter private immutable _minter;
  address private immutable _partnerWalletA;
  address private immutable _partnerWalletB;
  uint256 private immutable _price;
  uint256 private immutable _walletPurchaseLimit;

  /** @dev Fields */

  mapping(address => uint256) _purchases;
  uint256 _totalPurchases;

  constructor(
    uint256 beginTime_,
    IMinter minter_,
    address partnerWalletA_,
    address partnerWalletB_,
    uint256 price_,
    uint256 walletPurchaseLimit_
  ) {
    _beginTime = beginTime_;
    _minter = minter_;
    _partnerWalletA = partnerWalletA_;
    _partnerWalletB = partnerWalletB_;
    _price = price_;
    _walletPurchaseLimit = walletPurchaseLimit_;
  }

  /** Views */

  function totalPurchases() external view override returns (uint256) {
    return _totalPurchases;
  }

  function walletPurchases(address wallet) external view override returns (uint256) {
    return _purchases[wallet];
  }

  /** Mutators */

  function purchase(uint256 quantity) external payable override {
    require(block.timestamp > _beginTime, "L: launch has not begun");
    require(msg.value == _price * quantity, "L: incorrect ETH");
    require((_purchases[msg.sender] += quantity) <= _walletPurchaseLimit, "L: over wallet purchase limit");

    uint256 shareB = msg.value / 10;
    uint256 shareA = msg.value - shareB;

    (bool sent, ) = _partnerWalletA.call{value: shareA}("");

    require(sent, "L: failed to send partner A funds");

    (sent, ) = _partnerWalletB.call{value: shareB}("");

    require(sent, "L: failed to send partner B funds");

    _totalPurchases += quantity;

    emit Purchase(msg.sender, quantity);

    _minter.mint(msg.sender, quantity);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILaunch {
  /** Events */

  event Purchase(address indexed wallet, uint256 quantity);

  /** Views */

  function totalPurchases() external view returns (uint256);

  function walletPurchases(address) external view returns (uint256);

  /** Mutators */

  function purchase(uint256) external payable;
}