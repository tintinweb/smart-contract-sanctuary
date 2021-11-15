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
    // solhint-disable-next-line no-inline-assembly
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
    require(isContract(target), 'Address: No contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: No contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
  // MessageTunnel on L1 will get data from this event
  event MessageSent(bytes message);

  // fx child
  address public immutable fxChild;

  // fx root tunnel
  address public fxRootTunnel;

  constructor(address _fxChild) {
    fxChild = _fxChild;
  }

  // Sender must be fxRootTunnel in case of ERC20 tunnel
  modifier validateSender(address sender) {
    require(
      sender == fxRootTunnel,
      'FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT'
    );
    _;
  }

  // set fxRootTunnel if not set already
  function setFxRootTunnel(address _fxRootTunnel) external {
    require(
      fxRootTunnel == address(0x0),
      'FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET'
    );
    fxRootTunnel = _fxRootTunnel;
  }

  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external override {
    require(msg.sender == fxChild, 'FxBaseChildTunnel: INVALID_SENDER');
    _processMessageFromRoot(stateId, rootMessageSender, data);
  }

  /**
   * @notice Emit message that can be received on Root Tunnel
   * @dev Call the internal function when need to emit message
   * @param message bytes message that will be sent to Root Tunnel
   * some message examples -
   *   abi.encode(tokenId);
   *   abi.encode(tokenId, tokenMetadata);
   *   abi.encode(messageType, messageData);
   */
  function _sendMessageToRoot(bytes memory message) internal {
    emit MessageSent(message);
  }

  /**
   * @notice Process message received from Root Tunnel
   * @dev function needs to be implemented to handle message as per requirement
   * This is called by onStateReceive function.
   * Since it is called via a system call, any event will not be emitted during its execution.
   * @param stateId unique state id
   * @param sender root message sender
   * @param message bytes message that was sent from Root Tunnel
   */
  function _processMessageFromRoot(
    uint256 stateId,
    address sender,
    bytes memory message
  ) internal virtual;
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
 * @dev Interface to C-folio item contracts
 */
interface IBooster {
  /**
   * @dev return current rewardHandler
   */
  function rewardHandler() external view returns (address);

  /**
   * @dev return current sftHolder
   */
  function sftHolder() external view returns (address);

  /**
   * @dev Return information about the reward state in Booster
   *
   * @param tokenIds The SFT or TF tokenId
   *
   * @return locked The total amounts locked
   * @return pending The pending amounts claimable
   * @return apr The APR of this lock pool
   * @return secsLeft Numbers of seconds until unlock, or -1 if unlocked
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    returns (
      uint256[] memory locked,
      uint256[] memory pending,
      uint256[] memory apr,
      uint256[] memory secsLeft
    );

  /**
   * @dev Create a booster pool from v1 specs
   *
   * @param tokenId The SFT tokenId
   * @param data list of uint256's: total, pending, provided, apr, end, fee
   */
  function migrateCreatePool(
    uint256 tokenId,
    bytes memory data,
    uint256 dataIndex
  ) external returns (uint256);

  /**
   * @dev Handles farm distribution, only callable from controller
   *
   * If recipient is booster contract, amount is temporarily stored and locked
   * in a second call.
   *
   * @param farm The reward farm that the call originates from
   * @param recipient The recipient of the rewards
   * @param amount The amount to distribute
   * @param fee The fee in 6 decimal notation
   */
  function distributeFromFarm(
    address farm,
    address recipient,
    uint256 amount,
    uint32 fee
  ) external;

  /**
   * @dev Locks temporary tokens owned by recipient for a specific duration
   * of seconds.
   *
   * @param recipient The recipient of the rewards
   * @param lockPeriod The lock period in seconds
   */
  function lock(address recipient, uint256 lockPeriod) external;

  /**
   * @dev Claim rewards either into wallet or re-lock them
   *
   * @param sftTokenId The tokenId that manages the rewards
   * @param reLock True to re-lock existing rewards to earn more
   */
  function claimRewards(uint256 sftTokenId, bool reLock) external;

  /**
   * @dev Set sftHolder contract which is deployed after Booster
   */
  function setSftHolder(address sftHolder_) external;

  /**
   * @dev Set reward handler in case it will be upgraded
   */
  function setRewardHandler(address rewardHandler_) external;
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
 * @dev Interface to WOWS SFT minter item contracts
 */
interface IWOWSSftMinter {
  /**
   * @dev Mint a CFolioItem token
   *
   * Approval of WOWS token required before the call.
   *
   * @param cfolioItemType The item type of the SFT
   * @param sftTokenId If <> -1 recipient is the SFT c-folio / handler must be called
   * @param investAmounts Arguments needed for the handler (in general investments).
   * Investments may be zero if the user is just buying an SFT.
   */
  function mintCFolioItemSFT(
    address recipient,
    uint256 cfolioItemType,
    uint256 sftTokenId,
    uint256[] calldata investAmounts
  ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { ERC1155Holder } from '../../0xerc1155/tokens/ERC1155/ERC1155Holder.sol';

import { Address } from '../../0xerc1155/utils/Address.sol';
import { IWOWSERC1155 } from '../token/interfaces/IWOWSERC1155.sol';
import { FxBaseChildTunnel } from '../../polygonFx/tunnel/FxBaseChildTunnel.sol';
import { IBooster } from '../booster/interfaces/IBooster.sol';

import { IChildTunnel } from './interfaces/IChildTunnel.sol';

import '../crowdsale/interfaces/IWOWSSftMinter.sol';
import '../utils/TokenIds.sol';

contract WOWSERC1155ChildTunnel is
  FxBaseChildTunnel,
  ERC1155Holder,
  IChildTunnel
{
  using Address for address;
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  bytes32 public constant DEPOSIT = keccak256('DEPOSIT');
  bytes32 public constant DEPOSIT_BATCH = keccak256('DEPOSIT_BATCH');
  bytes32 private constant MIGRATE = keccak256('MIGRATE');
  bytes32 private constant MIGRATE_BATCH = keccak256('MIGRATE_BATCH');
  bytes32 private constant DISTRIBUTE = keccak256('DISTRIBUTE');
  bytes32 public constant WITHDRAW = keccak256('WITHDRAW');
  bytes32 public constant WITHDRAW_BATCH = keccak256('WITHDRAW_BATCH');
  bytes32 public constant MAP_TOKEN = keccak256('MAP_TOKEN');

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  IWOWSERC1155 private immutable childToken_;
  IWOWSSftMinter private immutable sftMinter_;
  IBooster private immutable booster_;
  address private immutable admin_;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  address public rootToken;
  address public rewardHandler;

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    require(msg.sender == admin_, 'CT: Only admin');
    _;
  }

  modifier onlyChildToken() {
    require(msg.sender == address(childToken_), 'CT: Only child');
    _;
  }

  modifier onlyRewardHandler() {
    require(msg.sender == rewardHandler, 'CT: Only rewardHandler');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event TokenMapped(address indexed rootToken, address indexed childToken);

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  constructor(
    address _fxChild,
    address _token,
    address _sftMinter,
    address _booster,
    address _admin
  ) FxBaseChildTunnel(_fxChild) {
    require(_token.isContract(), 'CT: Not a contract');
    childToken_ = IWOWSERC1155(_token);
    sftMinter_ = IWOWSSftMinter(_sftMinter);
    booster_ = IBooster(_booster);
    admin_ = _admin;
  }

  /**
   * @dev Called from proxy
   */
  function initialize(address _rewardHandler) external {
    require(rewardHandler == address(0), 'CT: Initialized');

    rewardHandler = _rewardHandler;
  }

  /**
   * @dev Destruct implementation
   */
  function destructContract() external onlyAdmin {
    // slither-disable-next-line suicidal
    selfdestruct(payable(admin_));
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation
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
  ) public override onlyChildToken returns (bytes4) {
    require(rootToken != address(0x0), 'CT: Token not mapped');
    require(tokenId.isBaseCard(), 'CT: Only basecards');

    bytes memory message = abi.encode(
      WITHDRAW,
      abi.encode(rootToken, childToken_, from, tokenId, data)
    );
    _sendMessageToRoot(message);

    // Call ancestor
    return super.onERC1155Received(operator, from, tokenId, amount, data);
  }

  /**
   * @dev See {IERC1155TokenReceiver-onERC1155BatchReceived}
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata data
  ) public override onlyChildToken returns (bytes4) {
    require(rootToken != address(0x0), 'CT: Token not mapped');

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      require(tokenIds[i].isBaseCard(), 'CT: Only basecards');
    }

    bytes memory message = abi.encode(
      WITHDRAW_BATCH,
      abi.encode(rootToken, childToken_, from, tokenIds, data)
    );
    _sendMessageToRoot(message);

    // Call ancestor
    return
      super.onERC1155BatchReceived(operator, from, tokenIds, amounts, data);
  }

  /**
   * @dev See {IChildTunnel-distribute}
   */
  function distribute(uint256 amount) external override onlyRewardHandler {
    bytes memory message = abi.encode(
      DISTRIBUTE,
      abi.encode(rootToken, childToken_, amount)
    );
    _sendMessageToRoot(message);
  }

  function setRewardHandler(address newRewardHandler) external onlyAdmin {
    require(newRewardHandler != address(0), 'CT: Zero address');

    rewardHandler = newRewardHandler;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal
  //////////////////////////////////////////////////////////////////////////////

  function _processMessageFromRoot(
    uint256, /* stateId */
    address sender,
    bytes memory data
  ) internal override validateSender(sender) {
    (bytes32 syncType, bytes memory syncData) = abi.decode(
      data,
      (bytes32, bytes)
    );

    if (syncType == MAP_TOKEN) {
      _mapToken(syncData);
    } else if (syncType == DEPOSIT) {
      _syncDeposit(syncData);
    } else if (syncType == DEPOSIT_BATCH) {
      _syncDepositBatch(syncData);
    } else if (syncType == MIGRATE) {
      _syncMigrate(syncData);
    } else if (syncType == MIGRATE_BATCH) {
      _syncMigrateBatch(syncData);
    } else {
      revert('CT: Invalid sync type');
    }
  }

  function _mapToken(bytes memory syncData) internal {
    address _rootToken = abi.decode(syncData, (address));

    require(rootToken == address(0), 'CT: Already mapped');

    rootToken = _rootToken;

    emit TokenMapped(rootToken, address(childToken_));
  }

  function _syncDeposit(bytes memory syncData) internal {
    (
      address _rootToken, /*address depositor*/
      ,
      address user,
      uint256 tokenId,
      bytes memory data
    ) = abi.decode(syncData, (address, address, address, uint256, bytes));

    require(_rootToken == rootToken, 'CT: Invalid rootToken');

    if (childToken_.balanceOf(address(this), tokenId) == 1)
      childToken_.safeTransferFrom(address(this), user, tokenId, 1, '');
    else {
      uint256[] memory tokenIds = new uint256[](1);
      tokenIds[0] = tokenId;
      childToken_.mintBatch(user, tokenIds, data);
    }
  }

  function _syncDepositBatch(bytes memory syncData) internal {
    (
      address _rootToken, /*address depositor */
      ,
      address user,
      uint256[] memory tokenIds,
      bytes memory data
    ) = abi.decode(syncData, (address, address, address, uint256[], bytes));

    require(_rootToken == rootToken, 'CT: Invalid rootToken');
    uint256[] memory oneTokenIds = new uint256[](1);
    uint256 dataIndex = 0;

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      require(data.length > 0, 'CT: Length mismatch (DB)');
      if (childToken_.balanceOf(address(this), tokenIds[i]) == 1) {
        childToken_.safeTransferFrom(address(this), user, tokenIds[i], 1, '');
      } else {
        oneTokenIds[0] = tokenIds[i];
        childToken_.mintBatch(
          user,
          oneTokenIds,
          abi.encodePacked(_getUint256(data, dataIndex++))
        );
      }
    }
  }

  function _syncMigrate(bytes memory syncData) public {
    (
      address _rootToken, /*address depositor*/
      ,
      ,
      uint256 tokenId,
      bytes memory data
    ) = abi.decode(syncData, (address, address, address, uint256, bytes));
    require(_rootToken == rootToken, 'CT: Invalid rootToken');

    address user = address(_getUint256(data, 0));
    _migrateTokenId(tokenId, user, data, 1);
  }

  function _syncMigrateBatch(bytes memory syncData) public {
    (
      address _rootToken, /*address depositor */
      ,
      ,
      uint256[] memory tokenIds,
      bytes memory data
    ) = abi.decode(syncData, (address, address, address, uint256[], bytes));
    require(_rootToken == rootToken, 'CT: Invalid rootToken');

    uint256 dataIndex = 0;
    address user = address(_getUint256(data, dataIndex++));
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      dataIndex = _migrateTokenId(tokenIds[i], user, data, dataIndex);
    }
  }

  function _migrateTokenId(
    uint256 tokenId,
    address user,
    bytes memory data,
    uint256 dataIndex
  ) private returns (uint256) {
    uint256[] memory noInvest = new uint256[](0);

    if (tokenId.isBaseCard()) {
      uint256[] memory oneTokenIds = new uint256[](1);
      oneTokenIds[0] = tokenId;
      childToken_.mintBatch(
        user,
        oneTokenIds,
        abi.encodePacked(uint256(0), _getUint256(data, dataIndex++))
      );

      uint256 numCfis = _getUint256(data, dataIndex++);
      for (uint256 i = 0; i < numCfis; ++i) {
        uint256 cfiType = _getUint256(data, dataIndex++);
        tokenId = sftMinter_.mintCFolioItemSFT(
          user,
          cfiType,
          tokenId,
          noInvest
        );
      }
      uint256 hasBooster = _getUint256(data, dataIndex++);
      if (hasBooster > 0) {
        dataIndex = booster_.migrateCreatePool(tokenId, data, dataIndex);
      }
    } else {
      uint256 cfiType = _getUint256(data, dataIndex++);
      tokenId = sftMinter_.mintCFolioItemSFT(
        user,
        cfiType,
        uint256(-1),
        noInvest
      );
    }
    return dataIndex;
  }

  /**
   * @dev Get the uint256 from the user data parameter
   */
  function _getUint256(bytes memory data, uint256 index)
    private
    pure
    returns (uint256 val)
  {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      val := mload(add(data, mul(0x20, add(index, 1))))
    }
  }
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

/**
 * @title ICChildTunnel
 */
interface IChildTunnel {
  // distribute internal rewards on root chain
  function distribute(uint256 amount) external;
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

