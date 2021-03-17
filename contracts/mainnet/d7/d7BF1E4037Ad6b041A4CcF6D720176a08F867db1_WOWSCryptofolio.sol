// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import './interfaces/IERC1155BurnMintable.sol';
import './interfaces/IWOWSCryptofolio.sol';
import './interfaces/IWOWSERC1155.sol';

contract WOWSCryptofolio is IWOWSCryptofolio {
  // Our NFT token parent
  IWOWSERC1155 private _deployer;
  // The owner of the NFT token parent
  address private _owner;
  // Mapping of cryptofolio items owned by this
  mapping(address => uint256[]) private _cryptofolios;
  // List of all known tradefloors
  address[] public _tradefloors;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Triggered if sft receives new tokens from operator
   */
  event CryptoFolioAdded(
    address indexed sft,
    address indexed operator,
    uint256[] tokenIds,
    uint256[] amounts
  );

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IWOWSCryptofolio-initialize}.
   */
  function initialize() external override {
    require(address(_deployer) == address(0), 'CF: Already initialized');
    _deployer = IWOWSERC1155(msg.sender);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IWOWSCryptofolio}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IWOWSCryptofolio-getCryptofolio}.
   */
  function getCryptofolio(address tradefloor)
    external
    view
    override
    returns (uint256[] memory tokenIds, uint256 idsLength)
  {
    uint256[] storage opIds = _cryptofolios[tradefloor];
    uint256[] memory result = new uint256[](opIds.length);
    uint256 newLength = 0;

    if (opIds.length > 0) {
      address[] memory accounts = new address[](opIds.length);
      for (uint256 i = 0; i < opIds.length; ++i) accounts[i] = address(this);
      uint256[] memory balances =
        IERC1155(tradefloor).balanceOfBatch(accounts, opIds);

      for (uint256 i = 0; i < opIds.length; ++i)
        if (balances[i] > 0) result[newLength++] = opIds[i];
    }
    return (result, newLength);
  }

  /**
   * @dev See {IWOWSCryptofolio-setOwner}.
   */
  function setOwner(address newOwner) external override {
    require(msg.sender == address(_deployer), 'CF: Only deployer');
    for (uint256 i = 0; i < _tradefloors.length; ++i) {
      if (_owner != address(0))
        IERC1155(_tradefloors[i]).setApprovalForAll(_owner, false);
      if (newOwner != address(0))
        IERC1155(_tradefloors[i]).setApprovalForAll(newOwner, true);
    }
    _owner = newOwner;
  }

  /**
   * @dev See {IWOWSCryptofolio-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool allow) external override {
    require(msg.sender == _owner, 'CF: Only owner');
    for (uint256 i = 0; i < _tradefloors.length; ++i) {
      IERC1155(_tradefloors[i]).setApprovalForAll(operator, allow);
    }
  }

  /**
   * @dev See {IWOWSCryptofolio-burn}.
   */
  function burn() external override {
    require(msg.sender == address(_deployer), 'CF: Only deployer');
    for (uint256 i = 0; i < _tradefloors.length; ++i) {
      IERC1155BurnMintable tradefloor = IERC1155BurnMintable(_tradefloors[i]);
      uint256[] storage opIds = _cryptofolios[address(tradefloor)];
      if (opIds.length > 0) {
        address[] memory accounts = new address[](opIds.length);
        for (uint256 j = 0; j < opIds.length; ++j) accounts[j] = address(this);
        uint256[] memory balances = tradefloor.balanceOfBatch(accounts, opIds);
        tradefloor.burnBatch(address(this), opIds, balances);
      }
      delete _cryptofolios[address(tradefloor)];
    }
    delete _tradefloors;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Hooks
  //////////////////////////////////////////////////////////////////////////////

  function onERC1155Received(
    address,
    address,
    uint256 tokenId,
    uint256 amount,
    bytes memory
  ) external returns (bytes4) {
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;
    _onTokensReceived(tokenIds, amounts);
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory
  ) external returns (bytes4) {
    _onTokensReceived(tokenIds, amounts);
    return this.onERC1155BatchReceived.selector;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal functionality
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Update our collection of tradeable cryptofolio items
   *
   * This function is only allowed to be called from one of our pseudo
   * TokenReceiver contracts.
   */
  function _onTokensReceived(
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) internal {
    address tradefloor = msg.sender;
    require(_deployer.isTradeFloor(tradefloor), 'CF: Only tradefloor');
    require(tokenIds.length == amounts.length, 'CF: Input lengths differ');

    uint256[] storage currentIds = _cryptofolios[tradefloor];
    if (currentIds.length == 0) {
      IERC1155(tradefloor).setApprovalForAll(_owner, true);
      _tradefloors.push(tradefloor);
    }

    for (uint256 iIds = 0; iIds < tokenIds.length; ++iIds) {
      if (amounts[iIds] > 0) {
        uint256 tokenId = tokenIds[iIds];
        // Search tokenId
        uint256 i = 0;
        for (; i < currentIds.length && currentIds[i] != tokenId; ++i) i;
        // If token was not found, insert it
        if (i == currentIds.length) currentIds.push(tokenId);
      }
    }
    emit CryptoFolioAdded(address(this), tradefloor, tokenIds, amounts);
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IERC1155BurnMintable is IERC1155 {
  /**
   * @dev Mint amount new tokens at ID `tokenId` (MINTER_ROLE required)
   */
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) external;

  /**
   * @dev Mint new token amounts at IDs `tokenIds` (MINTER_ROLE required)
   */
  function mintBatch(
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) external;

  /**
   * @dev Burn value amount of tokens with ID `tokenId`.
   *
   * Caller must be approvedForAll.
   */
  function burn(
    address account,
    uint256 tokenId,
    uint256 value
  ) external;

  /**
   * @dev Burn `values` amounts of tokens with IDs `tokenIds`.
   *
   * Caller must be approvedForAll.
   */
  function burnBatch(
    address account,
    uint256[] memory tokenIds,
    uint256[] memory values
  ) external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Cryptofolio interface
 *
 * TODO: Describe cryptofolios
 */
interface IWOWSCryptofolio {
  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Initialize the deployed contract after creation
   *
   * This is a one time call which sets _deployer to msg.sender.
   * Subsequent calls reverts.
   */
  function initialize() external;

  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Return array of cryptofolio token IDs
   *
   * The token IDs belong to the contract tradefloor.
   *
   * @param tradefloor The tradefloor items belong to
   *
   * @return tokenIds The token IDs in scope of operator
   * @return idsLength The number of valid token IDs
   */
  function getCryptofolio(address tradefloor)
    external
    view
    returns (uint256[] memory tokenIds, uint256 idsLength);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the owner of the underlying NFT
   *
   * This function is called if ownership of the parent NFT has changed.
   *
   * The new owner gets allowance to transfer cryptofolio items. The new owner
   * is allowed to transfer / burn cryptofolio items. Make sure that allowance
   * is removed from previous owner.
   *
   * @param owner The new owner of the underlying NFT
   */
  function setOwner(address owner) external;

  /**
   * @dev Allow owner (of parent NFT) to approve external operators to transfer
   * our cryptofolio items
   *
   * The NFT owner is allowed to approve operator to handle cryptofolios.
   *
   * @param operator The operator
   * @param allow True to approve for all NFTs, false to revoke approval
   */
  function setApprovalForAll(address operator, bool allow) external;

  /**
   * @dev Burn all cryptofolio items
   *
   * In case an underlying NFT is burned, we also burn the cryptofolio.
   */
  function burn() external;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @notice Cryptofolio interface
 *
 * TODO: Describe cryptofolios
 */
interface IWOWSERC1155 {
  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Check if the specified address is a known tradefloor
   *
   * @param account The address to check
   *
   * @return True if the address is a known tradefloor, false otherwise
   */
  function isTradeFloor(address account) external view returns (bool);

  /**
   * @dev Get the token ID of a given address
   *
   * A cross check is required because token ID 0 is valid.
   *
   * @param tokenAddress The address to convert to a token ID
   *
   * @return The token ID on success, or uint256(-1) if `tokenAddress` does not
   * belong to a token ID
   */
  function addressToTokenId(address tokenAddress)
    external
    view
    returns (uint256);

  /**
   * @dev Get the address for a given token ID
   *
   * @param tokenId The token ID to convert
   *
   * @return The address, or address(0) in case the token ID does not belong
   * to an NFT
   */
  function tokenIdToAddress(uint256 tokenId) external view returns (address);

  /**
   * @dev Get the next mintable token ID for the specified card
   *
   * @param level The level of the card
   * @param cardId The token ID of the card
   *
   * @return bool True if a free token ID was found, false otherwise
   * @return uint256 The first free token ID if one was found, or invalid otherwise
   */
  function getNextMintableTokenId(uint8 level, uint8 cardId)
    external
    view
    returns (bool, uint256);

  /**
   * @dev Return the next mintable custom token ID
   */
  function getNextMintableCustomToken() external view returns (uint256);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the URI for either predefined cards or custom cards
   *
   * For changing the default URI for predefined cards, token ID 0 must be
   * passed. Custom token ID's (> 32-bit range) get their own URI per token ID.
   *
   * @param tokenId The token ID whose URI is being set. Use `tokenId` == 0 to
   * set the default URI. `tokenId` >= 0xFFFFFFFF is for custom URIs.
   * @param _uri The URI, also allowing for the ERC-1155 {id} mechanism.
   */
  function setURI(uint256 tokenId, string memory _uri) external;

  /**
   * @dev Set the URI which is returned for custom cards without specific URI
   *
   * @param _uri The URI, also allowing for the ERC-1155 {id} mechanism.
   */
  function setCustomDefaultURI(string memory _uri) external;

  /**
   * @dev Each custom card has its own level. Level will be used when
   * calculating rewards and raiding power.
   *
   * @param tokenId The ID of the token whose level is being set
   * @param cardLevel The new level of the specified token
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel) external;
}