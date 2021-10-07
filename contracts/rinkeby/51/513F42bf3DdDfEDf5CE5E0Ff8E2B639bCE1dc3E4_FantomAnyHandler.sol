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
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import { ERC1155Holder } from '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';
import { IWOWSERC1155 } from '../token/interfaces/IWOWSERC1155.sol';

import '../utils/TokenIds.sol';
import './interfaces/IERC1155Transfer.sol';
import './interfaces/IAnyNftRouter.sol';

contract FantomAnyHandler is IERC1155Transfer, ERC1155Holder {
  using TokenIds for uint256;
  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  address private immutable _admin;
  address private immutable _sftHolder;
  address private immutable _nftRouter;
  uint256 private immutable _destChain;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  uint256 private constant CHILD_CHAIN_ID = 250;

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    require(msg.sender == _admin, 'FAH: Only admin');
    _;
  }

  modifier onlyNftRouter() {
    require(msg.sender == _nftRouter, 'FAH: Only router');
    _;
  }

  modifier onlySftHolder() {
    require(msg.sender == _sftHolder, 'FAH: Only from SFT');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(
    address admin,
    address sftHolder,
    address nftRouter,
    uint256 destChain
  ) {
    _admin = admin;
    _sftHolder = sftHolder;
    _nftRouter = nftRouter;
    _destChain = destChain;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation
  //////////////////////////////////////////////////////////////////////////////

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata
  ) external override onlyNftRouter {
    _handleTransfer(from, to, _toArray(tokenId), _toArray(amount));
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata
  ) external override onlyNftRouter {
    _handleTransfer(from, to, tokenIds, amounts);
  }

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155BatchReceived}
   *
   * @notice sftHolder only calls batch version
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) public override onlySftHolder returns (bytes4) {
    uint256[] memory newAmounts = amounts;
    if (_destChain != CHILD_CHAIN_ID) {
      // Root chain, put timestamp into amount
      newAmounts = new uint256[](amounts.length);
      for (uint256 i = 0; i < tokenIds.length; ++i) {
        (uint64 timestamp, ) = IWOWSERC1155(_sftHolder).getTokenData(
          tokenIds[i]
        );
        newAmounts[i] = uint256(timestamp);
      }
    }

    // ToDo: pass fees
    IAnyNftRouter(_nftRouter).nft1155BatchSwapOut(
      address(this),
      from,
      tokenIds,
      newAmounts,
      data,
      _destChain
    );

    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }

  /**
   * @dev Destruct implementation
   */
  function destructContract() external onlyAdmin {
    // slither-disable-next-line suicidal
    selfdestruct(payable(_admin));
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Handle transfer swapIn calls only
   */
  function _handleTransfer(
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) private {
    if (from == _nftRouter) {
      if (_destChain != CHILD_CHAIN_ID) {
        // Root chain
        IWOWSERC1155(_sftHolder).safeBatchTransferFrom(
          address(this),
          to,
          tokenIds,
          amounts,
          ''
        );
      } else {
        // Child chain, amounts are mint timestamps, token may has to be minted
        require(tokenIds.length == amounts.length, 'FAH: Length mismatch');
        uint256 numMints = 0;
        uint256[] memory mints = new uint256[](tokenIds.length);
        uint256 numTransfers = 0;
        uint256[] memory transfers = new uint256[](tokenIds.length);
        bytes memory mintData;

        for (uint256 i = 0; i < tokenIds.length; ++i) {
          if (
            IWOWSERC1155(_sftHolder).balanceOf(address(this), tokenIds[i]) == 0
          ) {
            mints[numMints++] = tokenIds[i];
            mintData = abi.encodePacked(mintData, amounts[i]);
          } else transfers[numTransfers++] = tokenIds[i];
        }

        if (numTransfers > 0) {
          // solhint-disable-next-line no-inline-assembly
          assembly {
            mstore(transfers, numTransfers)
          }
          IWOWSERC1155(_sftHolder).safeBatchTransferFrom(
            address(this),
            to,
            transfers,
            new uint256[](0),
            ''
          );
        }
        if (numMints > 0) {
          // solhint-disable-next-line no-inline-assembly
          assembly {
            mstore(mints, numMints)
          }
          IWOWSERC1155(_sftHolder).mintBatch(to, mints, mintData);
        }
      }
    }
  }

  /**
   * @dev Convert uint to uint[](1)
   */
  function _toArray(uint256 value)
    private
    pure
    returns (uint256[] memory result)
  {
    result = new uint256[](1);
    result[0] = value;
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

interface IAnyNftRouter {
  function nft1155SwapOut(
    address token,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data,
    uint256 toChainID
  ) external payable;

  function nft1155BatchSwapOut(
    address token,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data,
    uint256 toChainID
  ) external payable;
}

/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

interface IERC1155Transfer {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) external;

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
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
 * @notice Sft holder contract
 */
interface IWOWSERC1155 {
  //////////////////////////////////////////////////////////////////////////////
  // Getters
  //////////////////////////////////////////////////////////////////////////////

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

  /**
   * @dev Returns the cFolioItemType of a given cFolioItem tokenId
   */
  function getCFolioItemType(uint256 tokenId) external view returns (uint256);

  /**
   * @notice Get the balance of an account's Tokens
   * @param owner  The address of the token holder
   * @param tokenId ID of the Token
   * @return The _owner's balance of the token type requested
   */
  function balanceOf(address owner, uint256 tokenId)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param owners The addresses of the token holders
   * @param tokenIds ID of the Tokens
   * @return       The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(
    address[] calldata owners,
    uint256[] calldata tokenIds
  ) external view returns (uint256[] memory);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @notice Mints tokenIds into 'to' account
   * @dev Emits SftTokenTransfer Event
   *
   * Throws if sender has no MINTER_ROLE
   * 'data' holds the CFolioItemHandler if CFI's are minted
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    bytes calldata data
  ) external;

  /**
   * @notice Burns tokenIds owned by 'account'
   * @dev Emits SftTokenTransfer Event
   *
   * Burns all owned CFolioItems
   * Throws if CFolioItems have assets
   */
  function burnBatch(address account, uint256[] calldata tokenIds) external;

  /**
   * @notice Transfers amount of an id from the from address to the 'to' address specified
   * @dev Emits SftTokenTransfer Event
   * Throws if 'to' is the zero address
   * Throws if 'from' is not the current owner
   * If 'to' is a smart contract, ERC1155TokenReceiver interface will checked
   * @param from    Source address
   * @param to      Target address
   * @param tokenId ID of the token type
   * @param amount  Transfered amount
   * @param data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes calldata data
  ) external;

  /**
   * @dev Batch version of {safeTransferFrom}
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;

  /**
   * @dev Each custom card has its own level. Level will be used when
   * calculating rewards and raiding power.
   *
   * @param tokenId The ID of the token whose level is being set
   * @param cardLevel The new level of the specified token
   */
  function setCustomCardLevel(uint256 tokenId, uint8 cardLevel) external;

  /**
   * @dev Sets the cfolioItemType of a cfolioItem tokenId, not yet used
   * sftHolder tokenId expected (without hash)
   */
  function setCFolioItemType(uint256 tokenId, uint256 cfolioItemType_) external;

  /**
   * @dev Sets external NFT for display tokenId
   * By default NFT is rendered using our internal metadata
   *
   * Throws if not called from MINTER role
   */
  function setExternalNft(
    uint256 tokenId,
    address externalCollection,
    uint256 externalTokenId
  ) external;

  /**
   * @dev Deletes external NFT settings
   *
   * Throws if not called from MINTER role
   */
  function deleteExternalNft(uint256 tokenId) external;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  // Fired on each transfer operation
  event SftTokenTransfer(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] tokenIds
  );

  // Fired if the type of a CFolioItem is set
  event UpdatedCFolioType(uint256 indexed tokenId, uint256 cfolioItemType);

  // Fired if a Cryptofolio clone was set
  event CryptofolioSet(address cryptofolio);

  // Fired if a SidechainTunnel was set
  event SidechainTunnelSet(address sidechainTunnel);

  // Fired if we selfdestruct contract
  event Destruct();
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

  function isCustomCard(uint256 tokenId) internal pure returns (bool) {
    return
      (tokenId & HASH_MASK) >= (1 << 32) && (tokenId & HASH_MASK) < (1 << 64);
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
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}