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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {
  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(
    address _operator,
    address _from,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external returns (bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(
    address _operator,
    address _from,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '../../interfaces/IERC1155TokenReceiver.sol';
import '../../utils/ERC165.sol';

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC165, IERC1155TokenReceiver {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    override
    returns (bool)
  {
    if (_interfaceID == type(IERC1155TokenReceiver).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: MIT AND Apache-2.0
pragma solidity 0.7.6;

/**
 * Utility library of inline functions on addresses
 */
library Address {
  // Default hash for EOA accounts returned by extcodehash
  bytes32 internal constant ACCOUNT_HASH =
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly {
      codehash := extcodehash(_address)
    }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call(data);

    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

abstract contract ERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID)
    public
    pure
    virtual
    returns (bool)
  {
    return _interfaceID == this.supportsInterface.selector;
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';
import '../../0xerc1155/utils/Address.sol';
import '../../0xerc1155/utils/Context.sol';

import '../token/interfaces/IWOWSCryptofolio.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../token/interfaces/IERC1155BurnMintable.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

import './interfaces/ICFolioItemBridge.sol';
import './interfaces/ICFolioItemHandler.sol';

/**
 * @dev Minimalistic ERC1155 Holder for use only with WOWSCryptofolio
 *
 * This contract receives CFIs from the sftHolder contract for a
 * CFolio and performs all required Handle actions.
 */
contract CFolioItemBridge is ICFolioItemBridge, Context, ERC1155Holder {
  using TokenIds for uint256;
  using Address for address;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // SFT contract
  IAddressRegistry private immutable _addressRegistry;

  // SFT contract
  IWOWSERC1155 private immutable _sftHolder;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Our balances
  mapping(uint256 => address) private _owners;

  // Operator Functions
  mapping(address => mapping(address => bool)) private _operators;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event BridgeTransfer(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _amounts
  );

  /**
   * @dev MUST emit when an approval is updated
   */
  event BridgeApproval(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Construct the contract
   *
   * @param addressRegistry Registry containing our system addresses
   *
   */
  constructor(IAddressRegistry addressRegistry) {
    _addressRegistry = addressRegistry;

    // The SFTHolder contract
    _sftHolder = IWOWSERC1155(
      addressRegistry.getRegistryEntry(AddressBook.SFT_HOLDER)
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of minimal IERC1155
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemBridge-safeBatchTransferFrom}
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory
  ) external override {
    // Validate parameters
    require(
      (_msgSender() == from) || isApprovedForAll(from, _msgSender()),
      'CFIB: Not approved'
    );
    require(to != address(0), 'CFIB: Invalid recipient');
    require(tokenIds.length == amounts.length, 'CFIB: Length mismatch');

    // Transfer
    uint256 length = tokenIds.length;
    for (uint256 i = 0; i < length; ++i) {
      require(_owners[tokenIds[i]] == from, 'CFIB: Not owner');
      _owners[tokenIds[i]] = to;
    }
    _onTransfer(_msgSender(), from, to, tokenIds, amounts);
  }

  /**
   * @dev See {ICFolioItemBridge-burnBatch}
   */
  function burnBatch(
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external override {
    // Validate parameters
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      'CFIB: Not approved'
    );
    require(tokenIds.length == amounts.length, 'CFIB: Length mismatch');

    // Transfer
    uint256 length = tokenIds.length;
    uint256 newLength = 0;
    for (uint256 i = 0; i < length; ++i) {
      if (amounts[i] > 0) {
        require(_owners[tokenIds[i]] == from, 'CFIB: Not owner');
        _owners[tokenIds[i]] = address(0);
        ++newLength;
      }
    }
    if (newLength < length) {
      uint256[] memory newTokenIds = new uint256[](newLength);
      uint256[] memory newAmounts = new uint256[](newLength);
      newLength = 0;
      for (uint256 i = 0; i < length; ++i) {
        if (amounts[i] > 0) {
          newTokenIds[newLength] = tokenIds[i];
          newAmounts[newLength++] = amounts[i];
        }
      }
      _onTransfer(_msgSender(), from, address(0), newTokenIds, newAmounts);
    } else {
      _onTransfer(_msgSender(), from, address(0), tokenIds, amounts);
    }
  }

  /**
   * @dev See {ICFolioItemBridge-setApprovalForAll}
   */
  function setApprovalForAll(address _operator, bool _approved)
    external
    override
  {
    // Update operator status
    _operators[_msgSender()][_operator] = _approved;
    emit BridgeApproval(_msgSender(), _operator, _approved);
  }

  /**
   * @dev See {ICFolioItemBridge-isApprovedForAll}
   */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator)
  {
    return _operators[_owner][_operator];
  }

  /**
   * @dev See {ICFolioItemBridge-balanceOf}
   */
  function balanceOf(address account, uint256 tokenId)
    external
    view
    override
    returns (uint256)
  {
    return _owners[tokenId] == account ? 1 : 0;
  }

  /**
   * @dev See {ICFolioItemBridge-balanceOfBatch}
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory tokenIds)
    external
    view
    override
    returns (uint256[] memory)
  {
    require(accounts.length == tokenIds.length, 'CFIB: Length mismatch');

    // Variables
    uint256[] memory batchBalances = new uint256[](accounts.length);

    // Iterate over each account and token ID
    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = _owners[tokenIds[i]] == accounts[i] ? 1 : 0;
    }

    return batchBalances;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IERC1155TokenReceiver} via {ERC1155Holder}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155Received}
   */
  function onERC1155Received(
    address operator,
    address from,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) public override returns (bytes4) {
    // Handle tokens
    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = tokenId;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = amount;
    _onTokensReceived(operator, tokenIds, amounts, data);

    // Call ancestor
    return super.onERC1155Received(operator, from, tokenId, amount, data);
  }

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155BatchReceived}
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes calldata data
  ) public override returns (bytes4) {
    // Handle tokens
    _onTokensReceived(operator, tokenIds, amounts, data);

    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  function _onTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) private {
    uint256 tokenId;
    // Verify that recipient is null or a cFolio
    if (to != address(0)) {
      tokenId = _sftHolder.addressToTokenId(to);
      require(
        tokenId != uint256(-1) && tokenId.isBaseCard(),
        'CFIB: Only baseCard'
      );
    }

    // Count SFT tokenIds
    uint256 length = tokenIds.length;
    uint256 numUniqueCFolioHandlers = 0;
    address[] memory uniqueCFolioHandlers = new address[](length);
    address[] memory cFolioHandlers = new address[](length);

    // Invoke callbacks / count SFTs
    for (uint256 i = 0; i < length; ++i) {
      tokenId = tokenIds[i];
      require(tokenId.isCFolioCard(), 'CFIB: Only cfolioItems');

      // CFolio SFTs always have one tradefloor / 1 CFolio dummy
      // which is needed to notify the CFolioHandler on SFT burn
      address cfolio = _sftHolder.tokenIdToAddress(tokenId.toSftTokenId());
      require(cfolio != address(0), 'CFIB: Invalid cfolio');

      address cFolioHandler = IWOWSCryptofolio(cfolio)._tradefloors(0);

      uint256 iter = numUniqueCFolioHandlers;
      while (iter > 0 && uniqueCFolioHandlers[iter - 1] != cFolioHandler)
        --iter;
      if (iter == 0) {
        require(cFolioHandler != address(0), 'Invalid CFH address');
        uniqueCFolioHandlers[numUniqueCFolioHandlers++] = cFolioHandler;
      }
      cFolioHandlers[i] = cFolioHandler;
    }

    // On Burn we need to transfer SFT ownership back
    // In case the call originates from cfolio itself, we burn the token
    if (to == address(0)) {
      if (from == operator) {
        // The call origins from Cryptofolio burn, don't transfer
        IERC1155BurnMintable(address(_sftHolder)).burnBatch(
          address(this),
          tokenIds,
          amounts
        );
      } else {
        IERC1155BurnMintable(address(_sftHolder)).safeBatchTransferFrom(
          address(this),
          from,
          tokenIds,
          amounts,
          ''
        );
      }
    } else if (to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(
        _msgSender(),
        from,
        tokenIds,
        amounts,
        ''
      );
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, 'CFIB: CallOn failed');
    }

    // Handle CFolioItem transfers only if we are not migrating
    // Migration takes place if we are called from tradeFloor.
    // Remove the following condition if everything is migrated
    if (
      operator !=
      _addressRegistry.getRegistryEntry(AddressBook.TRADE_FLOOR_PROXY)
    )
      for (uint256 i = 0; i < numUniqueCFolioHandlers; ++i) {
        ICFolioItemHandler(uniqueCFolioHandlers[i]).onCFolioItemsTransferedFrom(
            from,
            to,
            tokenIds,
            cFolioHandlers
          );
      }

    emit BridgeTransfer(_msgSender(), from, to, tokenIds, amounts);
  }

  /**
   * @dev SFT token arrived, provide an NFT
   */
  function _onTokensReceived(
    address operator,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    // We only support tokens from our SFT Holder contract
    require(_msgSender() == address(_sftHolder), 'CFIB: Invalid');

    // Validate parameters
    require(tokenIds.length == amounts.length, 'CFIB: Lengths mismatch');
    require(data.length == 20, 'CFIB: Destination invalid');

    address sftRecipient = _getAddress(data);
    require(sftRecipient != address(0), 'CFIB: Invalid data address');

    // Update state
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      // Validate params
      require(amounts[i] == 1, 'CFIB: Amount invalid');
      uint256 tokenId = tokenIds[i];
      // Mint a token
      require(_owners[tokenId] == address(0), 'CFIB: already minted');
      _owners[tokenId] = sftRecipient;
    }
    _onTransfer(operator, address(0), sftRecipient, tokenIds, amounts);
  }

  /**
   * @dev Get the address from the user data parameter
   *
   * @param data Per ERC-1155, the data parameter is additional data with no
   * specified format, and is sent unaltered in the call to
   * {IERC1155Receiver-onERC1155Received} on the receiver of the minted token.
   */
  function _getAddress(bytes memory data) public pure returns (address addr) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      addr := mload(add(data, 20))
    }
  }
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to C-folio item bridge
 */
interface ICFolioItemBridge {
  /**
   * @notice Send multiple types of tokens from the _from address to the _to address (with safety call)
   * @param from     Source addresses
   * @param to       Target addresses
   * @param tokenIds IDs of each token type
   * @param amounts  Transfer amounts per token type
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bytes memory
  ) external;

  /**
   * @notice Burn multiple types of tokens from the from
   * @param from     Source addresses
   * @param tokenIds IDs of each token type
   * @param amounts  Transfer amounts per token type
   */
  function burnBatch(
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external;

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool isOperator);

  /**
   * @notice Get the balance of single account/token pair
   * @param account The address of the token holders
   * @param tokenId ID of the token
   * @return        The account's balance (0 or 1)
   */
  function balanceOf(address account, uint256 tokenId)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param accounts The addresses of the token holders
   * @param tokenIds ID of the Tokens
   * @return         The accounts's balances (0 or 1)
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory tokenIds)
    external
    view
    returns (uint256[] memory);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../token/interfaces/ICFolioItemCallback.sol';

/**
 * @dev Interface to C-folio item contracts
 */
interface ICFolioItemHandler is ICFolioItemCallback {
  /**
   * @dev Called when a SFT tokens grade needs re-evaluation
   *
   * @param tokenId The ERC-1155 token ID. Rate is in 1E6 convention: 1E6 = 100%
   * @param newRate The new value rate
   */
  function sftUpgrade(uint256 tokenId, uint32 newRate) external;

  /**
   * @dev Called from SFTMinter after an Investment SFT is minted
   *
   * @param payer The approved address to get investment from
   * @param sftTokenId The sftTokenId whose c-folio is the owner of investment
   * @param amounts The amounts of invested assets
   */
  function setupCFolio(
    address payer,
    uint256 sftTokenId,
    uint256[] calldata amounts
  ) external;

  //////////////////////////////////////////////////////////////////////////////
  // Asset access
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Adds investments into a cFolioItem SFT
   *
   * Transfers amounts of assets from users wallet to the contract. In general,
   * an Approval call is required before the function is called.
   *
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param amounts Investment amounts, implementation specific
   */
  function deposit(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Removes investments from a cFolioItem SFT
   *
   * Withdrawn token are transfered back to msg.sender.
   *
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param amounts Investment amounts, implementation specific
   */
  function withdraw(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Get the rewards collected by an SFT base card
   *
   * Calls only allowed from sftMinter.
   *
   * @param owner The owner of the NFT token
   * @param recipient Recipient of the rewards (- fees)
   * @param tokenId SFT base card tokenId, must be unlocked
   */
  function getRewards(
    address owner,
    address recipient,
    uint256 tokenId
  ) external;

  /**
   * @dev Get amounts (handler specific) for a cfolioItem
   *
   * @param cfolioItem address of CFolioItem contract
   */
  function getAmounts(address cfolioItem)
    external
    view
    returns (uint256[] memory);

  /**
   * @dev Get information obout the rewardFarm
   *
   * @param tokenIds List of basecard tokenIds
   * @return bytes of uint256[]: total, rewardDur, rewardRateForDur, [share, earned]
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    returns (bytes memory);
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface to receive callbacks when minted tokens are burnt
 */
interface ICFolioItemCallback {
  /**
   * @dev Called when a TradeFloor CFolioItem is transfered
   *
   * In case of mint `from` is address(0).
   * In case of burn `to` is address(0).
   *
   * cfolioHandlers are passed to let each cfolioHandler filter for its own
   * token. This eliminates the need for creating separate lists.
   *
   * @param from The account sending the token
   * @param to The account receiving the token
   * @param tokenIds The ERC-1155 token IDs
   * @param cfolioHandlers cFolioItem handlers
   */
  function onCFolioItemsTransferedFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    address[] calldata cfolioHandlers
  ) external;

  /**
   * @dev Append data we use later for hashing
   *
   * @param cfolioItem The token ID of the c-folio item
   * @param current The current data being hashes
   *
   * @return The current data, with internal data appended
   */
  function appendHash(address cfolioItem, bytes calldata current)
    external
    view
    returns (bytes memory);
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
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
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
    uint256[] calldata tokenIds,
    uint256[] calldata values
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
   * @dev Return tradefloor at given index
   *
   * @param index The 0-based index in the tradefloor array
   *
   * @return The address of the tradefloor and position index
   */
  function _tradefloors(uint256 index) external view returns (address);

  /**
   * @dev Return array of cryptofolio item token IDs
   *
   * The token IDs belong to the contract TradeFloor.
   *
   * @param tradefloor The TradeFloor that items belong to
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
   * @param owner The new owner of the underlying NFT, or address(0) if the
   * underlying NFT is being burned
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
   * @param cardId The ID of the card
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

  /**
   * @dev Return the level and the mint timestamp of tokenId
   *
   * @param tokenId The tokenId to query
   *
   * @return mintTimestamp The timestamp token was minted
   * @return level The level token belongs to
   */
  function getTokenData(uint256 tokenId)
    external
    view
    returns (uint64 mintTimestamp, uint8 level);

  /**
   * @dev Return all tokenIds owned by account
   */
  function getTokenIds(address account)
    external
    view
    returns (uint256[] memory);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the base URI for either predefined cards or custom cards
   * which don't have it's own URI.
   *
   * The resulting uri is baseUri+[hex(tokenId)] + '.json'. where
   * tokenId will be reduces to upper 16 bit (>> 16) before building the hex string.
   *
   */
  function setBaseMetadataURI(string memory baseContractMetadata) external;

  /**
   * @dev Set the contracts metadata URI
   *
   * @param contractMetadataURI The URI which point to the contract metadata file.
   */
  function setContractMetadataURI(string memory contractMetadataURI) external;

  /**
   * @dev Set the URI for a custom card
   *
   * @param tokenId The token ID whose URI is being set.
   * @param customURI The URI which point to an unique metadata file.
   */
  function setCustomURI(uint256 tokenId, string memory customURI) external;

  /**
   * @dev Each custom card has its own level. Level will be used when
   * calculating rewards and raiding power.
   *
   * @param tokenId The ID of the token whose level is being set
   * @param cardLevel The new level of the specified token
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

library AddressBook {
  bytes32 public constant DEPLOYER = 'DEPLOYER';
  bytes32 public constant TEAM_WALLET = 'TEAM_WALLET';
  bytes32 public constant MARKETING_WALLET = 'MARKETING_WALLET';
  bytes32 public constant UNISWAP_V2_ROUTER02 = 'UNISWAP_V2_ROUTER02';
  bytes32 public constant WETH_WOWS_STAKE_FARM = 'WETH_WOWS_STAKE_FARM';
  bytes32 public constant WOWS_TOKEN = 'WOWS_TOKEN';
  bytes32 public constant UNISWAP_V2_PAIR = 'UNISWAP_V2_PAIR';
  bytes32 public constant WOWS_BOOSTER_PROXY = 'WOWS_BOOSTER_PROXY';
  bytes32 public constant REWARD_HANDLER = 'REWARD_HANDLER';
  bytes32 public constant SFT_MINTER = 'SFT_MINTER';
  bytes32 public constant SFT_HOLDER = 'SFT_HOLDER';
  bytes32 public constant CFOLIOITEM_BRIDGE_PROXY = 'CFOLIOITEM_BRIDGE_PROXY';
  bytes32 public constant BOIS_REWARDS = 'BOIS_REWARDS';
  bytes32 public constant WOLVES_REWARDS = 'WOLVES_REWARDS';
  bytes32 public constant SFT_EVALUATOR_PROXY = 'SFT_EVALUATOR_PROXY';
  bytes32 public constant TRADE_FLOOR_PROXY = 'TRADE_FLOOR_PROXY';
  bytes32 public constant CURVE_Y_TOKEN = 'CURVE_Y_TOKEN';
  bytes32 public constant CURVE_Y_DEPOSIT = 'CURVE_Y_DEPOSIT';
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSE.txt for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

library TokenIds {
  // 128 bit underlying hash
  uint256 public constant HASH_MASK = (1 << 128) - 1;

  function isBaseCard(uint256 tokenId) internal pure returns (bool) {
    return (tokenId & HASH_MASK) < (1 << 64);
  }

  function isStockCard(uint256 tokenId) internal pure returns (bool) {
    return (tokenId & HASH_MASK) < (1 << 32);
  }

  function isCFolioCard(uint256 tokenId) internal pure returns (bool) {
    return
      (tokenId & HASH_MASK) >= (1 << 64) && (tokenId & HASH_MASK) < (1 << 128);
  }

  function toSftTokenId(uint256 tokenId) internal pure returns (uint256) {
    return tokenId & HASH_MASK;
  }

  function maskHash(uint256 tokenId) internal pure returns (uint256) {
    return tokenId & ~HASH_MASK;
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

interface IAddressRegistry {
  /**
   * @dev Set an abitrary key / address pair into the registry
   */
  function setRegistryEntry(bytes32 _key, address _location) external;

  /**
   * @dev Get a registry enty with by key, returns 0 address if not existing
   */
  function getRegistryEntry(bytes32 _key) external view returns (address);
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}