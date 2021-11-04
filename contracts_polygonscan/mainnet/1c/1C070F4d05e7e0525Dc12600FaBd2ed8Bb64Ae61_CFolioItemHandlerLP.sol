// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IERC1155 {
  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256 _id,
    uint256 _amount
  );

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _amounts
  );

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
   * @notice Transfers amount of an _id from the _from address to the _to address specified
   * @dev MUST emit TransferSingle event on success
   * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
   * MUST throw if `_to` is the zero address
   * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
   * MUST throw on any other error
   * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @dev MUST emit TransferBatch event on success
   * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
   * MUST throw if `_to` is the zero address
   * MUST throw if length of `_ids` is not the same as length of `_amounts`
   * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
   * MUST throw on any other error
   * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external
    view
    returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

// SPDX-License-Identifier: MIT AND Apache-2.0

pragma solidity 0.7.6;

import '../interfaces/IERC20.sol';
import '../utils/SafeMath.sol';
import '../utils/Address.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(
      data,
      'SafeERC20: low-level call failed'
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        'SafeERC20: ERC20 operation did not succeed'
      );
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath#mul: OVERFLOW');

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, 'SafeMath#div: DIVISION_BY_ZERO');
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath#sub: UNDERFLOW');
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath#add: OVERFLOW');

    return c;
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'SafeMath#mod: DIVISION_BY_ZERO');
    return a % b;
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

import '../../0xerc1155/interfaces/IERC1155.sol';
import '../../0xerc1155/utils/Context.sol';
import '../../0xerc1155/utils/SafeMath.sol';

import '../investment/interfaces/ICFolioFarm.sol'; // WOWS rewards
import '../token/interfaces/IWOWSERC1155.sol'; // SFT contract
import '../token/interfaces/IWOWSCryptofolio.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';
import '../utils/TokenIds.sol';

import './interfaces/ICFolioItemHandler.sol';
import './interfaces/ISFTEvaluator.sol';

interface ICFolioFarmOld is ICFolioFarm {
  function earned(address account) external view returns (uint256);
}

/**
 * @dev CFolioItemHandlerFarm manages CFolioItems, minted in the SFT contract.
 *
 * Minting CFolioItem SFTs is implemented in the WOWSSFTMinter contract, which
 * mints the SFT in the WowsERC1155 contract and calls setupCFolio in here.
 *
 * Normaly CFolioItem SFTs are locked in the main TradeFloor contract to allow
 * trading or transfer into a Base SFT card's c-folio.
 *
 * CFolioItem SFTs only earn rewards if they are inside the cfolio of a base
 * NFT. We get called from main TradeFloor every time an CFolioItem gets
 * transfered and calculate the new rewardable amount based on the reward %
 * of the base NFT.
 */
abstract contract CFolioItemHandlerFarm is ICFolioItemHandler, Context {
  using SafeMath for uint256;
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // Route to SFT Minter. Only setup from SFT Minter allowed.
  address private immutable _sftMinter;

  // SFT evaluator
  ISFTEvaluator private immutable _sftEvaluator;

  // Reward emitter
  ICFolioFarmOwnable internal immutable _cfolioFarm;

  // Admin
  address private immutable _admin;

  // The SFT contract needed to check if the address is a c-folio
  IWOWSERC1155 internal immutable _sftHolder;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /*
   * @dev Emitted when the contract is contstructed
   *
   * @param admin The immutable admin address
   * @param sftHolder The immutable sftHolder address
   * @param sftMinter The immutable sftMinter address
   * @param sftEvaluator The immutable sftEvaluator address
   * @param cfolioFarm The immutable cfolioFarm address
   */
  event Constructed(
    address admin,
    address sftHolder,
    address sftMinter,
    address sftEvaluator,
    address cfolioFarm
  );

  /**
   * @dev Emitted when a new minter is set by the admin
   *
   * @param minter The new minter
   */
  event NewMinter(address minter);

  /**
   * @dev Emitted when the contract is destructed
   *
   * @param thisContract The address of this contract
   */
  event CFolioItemHandlerDestructed(address thisContract);

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlySFTHolder() {
    require(_msgSender() == address(_sftHolder), 'CFHI: Only SFTH');
    _;
  }

  modifier onlyAdmin() {
    require(_msgSender() == _admin, 'CFIH: Only admin');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructs the CFolioItemHandlerFarm
   *
   * We gather all current addresses from address registry into immutable vars.
   * If one of the relevant addresses changes, the contract has to be updated.
   * There is little state here, user state is completely handled in CFolioFarm.
   */
  constructor(IAddressRegistry addressRegistry, address farm) {
    // Admin
    address admin = addressRegistry.getRegistryEntry(AddressBook.ADMIN_ACCOUNT);
    _admin = admin;

    // The SFT holder
    address sftHolder = addressRegistry.getRegistryEntry(
      AddressBook.SFT_HOLDER_PROXY
    );
    _sftHolder = IWOWSERC1155(sftHolder);

    // The SFT minter
    address sftMinter = addressRegistry.getRegistryEntry(
      AddressBook.SFT_MINTER_PROXY
    );
    _sftMinter = sftMinter;

    // SFT evaluator
    address sftEvaluator = addressRegistry.getRegistryEntry(
      AddressBook.SFT_EVALUATOR_PROXY
    );
    _sftEvaluator = ISFTEvaluator(sftEvaluator);

    // WOWS rewards
    _cfolioFarm = ICFolioFarmOwnable(farm);

    emit Constructed(admin, sftHolder, sftMinter, sftEvaluator, farm);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemCallback} via {ICFolioItemHandler}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemCallback-onCFolioItemsTransferedFrom}
   */
  function onCFolioItemsTransferedFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    address[] calldata cfolioHandlers
  ) external override onlySFTHolder {
    // In case of transfer verify the target
    uint256 sftTokenId;

    if (
      to != address(0) &&
      (sftTokenId = _sftHolder.addressToTokenId(to)) != uint256(-1)
    ) {
      _verifyTransferTarget(sftTokenId);
      _updateRewards(to, _sftEvaluator.rewardRate(sftTokenId));
    }
    if (
      from != address(0) &&
      (sftTokenId = _sftHolder.addressToTokenId(from)) != uint256(-1)
    ) {
      _updateRewards(from, _sftEvaluator.rewardRate(sftTokenId));
    }
    // Validate that cfolioItems are empty before we burn them
    if (to == address(0)) {
      require(
        tokenIds.length == cfolioHandlers.length,
        'CFIH: Length mismatch'
      );
      for (uint256 i = 0; i < tokenIds.length; ++i) {
        if (cfolioHandlers[i] == address(this)) {
          address cfolio = _sftHolder.tokenIdToAddress(tokenIds[i]);
          require(cfolio != address(0), 'CFIH: Invalid cfolio');
          uint256[] memory balances = _cfolioFarm.balancesOf(cfolio);
          for (uint256 slotId = 0; slotId < balances.length; ++slotId)
            require(balances[slotId] == 0, 'CFIH: Not empty');
        }
      }
    }
  }

  /**
   * @dev See {ICFolioItemCallback-appendHash}
   */
  function appendHash(address cfolioItem, bytes calldata current)
    external
    view
    override
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        current,
        address(this),
        _cfolioFarm.balancesOf(cfolioItem)
      );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemHandler}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemHandler-sftUpgrade}
   */
  function sftUpgrade(uint256 tokenId, uint32 newRate) external override {
    // Validate access
    require(_msgSender() == address(_sftEvaluator), 'CFIH: Invalid caller');
    require(tokenId.isBaseCard(), 'CFIH: Invalid token');

    // CFolio address
    address cfolio = _sftHolder.tokenIdToAddress(tokenId);

    // Update state
    _updateRewards(cfolio, newRate);
  }

  /**
   * @dev See {ICFolioItemHandler-deposit}
   *
   * Note: tokenId can be owned by a base SFT
   * In this case base SFT cannot be locked
   *
   * There is only need to update rewards if tokenId
   * is part of an unlocked base SFT
   */
  function deposit(
    address from,
    uint256 baseTokenId,
    uint256 tokenId,
    uint256 slotId,
    uint256[] calldata amounts
  ) external override {
    // allow fast lane from sftMinter
    if (_msgSender() != _sftMinter) {
      require(from == _msgSender(), 'CFIH: Invalid from');
    }

    // Validate parameters
    (address baseCFolio, address itemCFolio) = _verifyAssetAccess(
      from,
      baseTokenId,
      tokenId
    );

    // Call the implementation
    _deposit(itemCFolio, from, slotId, amounts);

    // Update rewards if CFI is inside cfolio
    if (baseCFolio != address(0))
      _updateRewards(baseCFolio, _sftEvaluator.rewardRate(baseTokenId));
  }

  /**
   * @dev See {ICFolioItemHandler-withdraw}
   *
   * Note: tokenId can be owned by a base SFT. In this case, the base SFT
   * cannot be locked.
   *
   * There is only need to update rewards if tokenId is part of an unlocked
   * base SFT.
   */
  function withdraw(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256 slotId,
    uint256[] calldata amounts
  ) external override {
    // Validate parameters
    (address baseCFolio, address itemCFolio) = _verifyAssetAccess(
      _msgSender(),
      baseTokenId,
      tokenId
    );

    // Call the implementation
    _withdraw(itemCFolio, slotId, amounts);

    // Update rewards if CFI is inside cfolio
    if (baseCFolio != address(0))
      _updateRewards(baseCFolio, _sftEvaluator.rewardRate(baseTokenId));
  }

  /**
   * @dev See {ICFolioItemHandler-update}
   */
  function update(
    uint256, /* tokenId*/
    uint256[] calldata /* amounts*/
  ) external pure override {
    revert('CFIH: Not implemented');
  }

  /**
   * @dev See {ICFolioItemHandler-getRewards}
   *
   * Note: tokenId must be a base SFT card
   *
   * We allow reward pull only for unlocked SFTs.
   */
  function getRewards(
    address owner,
    address recipient,
    uint256 tokenId
  ) external override {
    // Validate parameters
    require(recipient != address(0), 'CFIH: Invalid recipient');
    require(tokenId.isBaseCard(), 'CFIH: Invalid tokenId');

    // Verify that tokenId has a valid cFolio address
    uint256 sftTokenId = tokenId.toSftTokenId();
    address cfolio = _sftHolder.tokenIdToAddress(sftTokenId);
    require(cfolio != address(0), 'CFHI: No cfolio');

    // Verify that the tokenId is owned by owner and caller is sftMinter.
    // This also verifies that the token is not locked in TradeFloor.
    require(
      _msgSender() == _sftMinter &&
        IERC1155(address(_sftHolder)).balanceOf(owner, sftTokenId) == 1,
      'CFHI: Forbidden'
    );

    // Get rewards from all slots
    _cfolioFarm.getRewards(cfolio, recipient, new uint256[](0));
  }

  /**
   * @dev See {ICFolioItemHandler-getRewardInfo}
   */
  function getRewardInfo(uint256[] calldata tokenIds)
    external
    view
    override
    returns (bytes memory result)
  {
    uint256 slotCount = _cfolioFarm.slotCount();
    result = abi.encodePacked(_cfolioFarm.rewardsDuration(), slotCount);

    for (uint256 slotId = 0; slotId < slotCount; ++slotId) {
      result = abi.encodePacked(
        result,
        _cfolioFarm.totalSupply(slotId),
        _cfolioFarm.getRewardsForDuration(slotId)
      );
      // Iterate through all tokenIds and collect reward info
      for (uint256 i = 0; i < tokenIds.length; ++i) {
        (uint256 share, uint256 earned) = tokenIds[i].isBaseCard()
          ? _cfolioFarm.getShareAndEarned(
            _sftHolder.tokenIdToAddress(tokenIds[i].toSftTokenId()),
            slotId
          )
          : (0, 0);
        result = abi.encodePacked(result, share, earned);
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal interface
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Deposit amounts
   */
  function _deposit(
    address itemCFolio,
    address payer,
    uint256 slotId,
    uint256[] calldata amounts
  ) internal virtual;

  /**
   * @dev Withdraw amounts
   */
  function _withdraw(
    address itemCFolio,
    uint256 slotId,
    uint256[] calldata amounts
  ) internal virtual;

  /**
   * @dev Verify if target base SFT is allowed
   */
  function _verifyTransferTarget(uint256 baseSftTokenId) internal virtual;

  //////////////////////////////////////////////////////////////////////////////
  // Maintanace
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Destruct implementation
   */
  function selfDestruct() external onlyAdmin {
    // Dispatch event
    emit CFolioItemHandlerDestructed(address(this));

    // Disable high-impact Slither detector "suicidal" here. Slither explains
    // that "CFolioItemHandlerFarm.selfDestruct() allows anyone to destruct the
    // contract", which is not the case due to the onlyAdmin modifier.
    //
    // slither-disable-next-line suicidal
    selfdestruct(payable(_admin));
  }

  /**
   * @dev Migrate set of addresses from an old Farm into the current one
   */
  function migrateFromFarm(
    ICFolioFarmOld from,
    uint256 slotIdFrom,
    uint256 slotIdTo,
    address[] memory sfts
  ) external onlyAdmin {
    for (uint256 i = 0; i < sfts.length; ++i) {
      uint256 tokenId = _sftHolder.addressToTokenId(sfts[i]);
      require(tokenId != uint256(-1), 'CFIH: No SFT');

      uint256 amount = from.balanceOf(sfts[i], slotIdFrom);
      if (tokenId.isBaseCard()) {
        _cfolioFarm.migrateShares(
          sfts[i],
          amount,
          slotIdTo,
          from.earned(sfts[i])
        );
      } else if (amount > 0) {
        _cfolioFarm.addAssets(sfts[i], amount, slotIdTo);
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Run through all cFolioItems collected in cFolio and select the amount
   * of tokens. Update cfolioFarm.
   */
  function _updateRewards(address cfolio, uint32 rate) private {
    // Get c-folio items of this base cFolio
    uint256[] memory tokenIds = _sftHolder.getTokenIds(cfolio);
    uint256 length = tokenIds.length;

    // Marginal increase in gas per item is around 25K. Bounding items to 100
    // fits in sensible gas limits.
    require(length <= 100, 'CFIH: Too many items');

    // Get number of existing slots
    uint256 farmSlots = _cfolioFarm.slotCount();

    // Calculate new reward amount
    uint256[] memory newRewardAmount = new uint256[](farmSlots);
    for (uint256 i = 0; i < length; ++i) {
      address secondaryCFolio = _sftHolder.tokenIdToAddress(tokenIds[i]);
      require(secondaryCFolio != address(0), 'CFIH: Invalid tokenId');
      if (IWOWSCryptofolio(secondaryCFolio).handler() == address(this)) {
        uint256[] memory amounts = _cfolioFarm.balancesOf(secondaryCFolio);
        for (uint256 slotId = 0; slotId < farmSlots; ++slotId)
          newRewardAmount[slotId] = newRewardAmount[slotId].add(
            amounts[slotId]
          );
      }
    }

    for (uint256 slotId = 0; slotId < farmSlots; ++slotId) {
      newRewardAmount[slotId] = newRewardAmount[slotId].mul(rate).div(1E6);

      // Calculate existing reward amount
      uint256 exitingRewardAmount = _cfolioFarm.balanceOf(cfolio, slotId);

      // Compare amounts and add/remove shares
      if (newRewardAmount[slotId] > exitingRewardAmount) {
        // Update state
        _cfolioFarm.addShares(
          cfolio,
          newRewardAmount[slotId].sub(exitingRewardAmount),
          slotId
        );
      } else if (newRewardAmount[slotId] < exitingRewardAmount) {
        // Update state
        _cfolioFarm.removeShares(
          cfolio,
          exitingRewardAmount.sub(newRewardAmount[slotId]),
          slotId
        );
      }
    }
  }

  /**
   * @dev Verifies if an asset access operation is allowed
   *
   * @param baseTokenId Base card tokenId or uint(-1)
   * @param cfolioItemTokenId CFolioItem tokenId handled by this contract
   *
   * A tokenId is "unlocked" if msg.sender is the owner of a tokenId in SFT
   * contract. If baseTokenId is uint(-1), cfolioItemTokenId has to be be
   * unlocked, otherwise baseTokenId has to be unlocked and the locked
   * cfolioItemTokenId has to be inside its c-folio.
   */
  function _verifyAssetAccess(
    address from,
    uint256 baseTokenId,
    uint256 cfolioItemTokenId
  ) private view returns (address, address) {
    // Verify it's a cfolioItemTokenId
    require(cfolioItemTokenId.isCFolioCard(), 'CFHI: Not cFolioCard');

    // Verify that the tokenId is one of ours
    address cFolio = _sftHolder.tokenIdToAddress(
      cfolioItemTokenId.toSftTokenId()
    );
    require(cFolio != address(0), 'CFIH: Invalid cFolioTokenId');
    require(
      IWOWSCryptofolio(cFolio).handler() == address(this),
      'CFIH: Not our SFT'
    );

    address baseCFolio = address(0);

    if (baseTokenId != uint256(-1)) {
      // Verify it's a c-folio base card
      require(baseTokenId.isBaseCard(), 'CFHI: Not baseCard');
      baseCFolio = _sftHolder.tokenIdToAddress(baseTokenId.toSftTokenId());
      require(baseCFolio != address(0), 'CFIH: Invalid baseCFolioTokenId');

      // Verify that the tokenId is owned by msg.sender in SFT contract.
      // This also verifies that the token is not locked in TradeFloor.
      require(
        IERC1155(address(_sftHolder)).balanceOf(from, baseTokenId) == 1,
        'CFHI: Access denied (B)'
      );

      // Verify that the cfiTokenId is owned by given baseCFolio.
      // In V2 we have unlocked CFIs in baseCfolio in contrast to V1

      require(
        IERC1155(address(_sftHolder)).balanceOf(
          baseCFolio,
          cfolioItemTokenId
        ) == 1,
        'CFHI: Access denied (CF)'
      );
    } else {
      // Verify that the tokenId is owned by msg.sender in SFT contract.
      // This also verifies that the token is not locked in TradeFloor.
      require(
        IERC1155(address(_sftHolder)).balanceOf(from, cfolioItemTokenId) == 1,
        'CFHI: Access denied'
      );
    }
    return (baseCFolio, cFolio);
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

import '../../0xerc1155/interfaces/IERC20.sol';
import '../../0xerc1155/utils/SafeERC20.sol';

import './CFolioItemHandlerFarm.sol';

/**
 * @dev CFolioItemHandlerLP manages CFolioItems, minted in the SFT contract.
 *
 * See {CFolioItemHandlerFarm}.
 */
contract CFolioItemHandlerLP is CFolioItemHandlerFarm {
  using SafeERC20 for IERC20;

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // Slot 0 token (WOWS/WETH UniV2 Pair)
  IERC20 public immutable stakingToken0;
  // Slot 1 token (WOWS/Native UniV2 Pair)
  IERC20 public immutable stakingToken1;

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructs the CFolioItemHandlerLP
   *
   * We gather all current addresses from address registry into immutable vars.
   * If one of the relevant addresses changes, the contract has to be updated.
   * There is little state here, user state is completely handled in CFolioFarm.
   */
  constructor(IAddressRegistry addressRegistry, address farm)
    CFolioItemHandlerFarm(addressRegistry, farm)
  {
    // WOWS/WETH staking token
    stakingToken0 = IERC20(
      addressRegistry.getRegistryEntry(AddressBook.UNISWAP_V2_PAIR)
    );
    // WOWS/NATIVE staking token
    stakingToken1 = IERC20(
      addressRegistry.getRegistryEntry(AddressBook.UNISWAP_V2_PAIR_NATIVE)
    );
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {CFolioItemHandlerFarm}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {CFolioItemHandlerFarm-_deposit}.
   */
  function _deposit(
    address itemCFolio,
    address payer,
    uint256 slotId,
    uint256[] calldata amounts
  ) internal override {
    // Validate parameters
    require(amounts.length == 1 && amounts[0] > 0, 'CFIHLP: invalid amount');
    // Transfer LP token to this contract
    (slotId == 0 ? stakingToken0 : stakingToken1).safeTransferFrom(
      payer,
      address(this),
      amounts[0]
    );

    // Record assets in the Farm contract. They don't earn rewards.
    //
    // NOTE: {addAssets} must only be called from investment CFolios.
    _cfolioFarm.addAssets(itemCFolio, amounts[0], slotId);
  }

  /**
   * @dev See {CFolioItemHandlerFarm-_withdraw}.
   */
  function _withdraw(
    address itemCFolio,
    uint256 slotId,
    uint256[] calldata amounts
  ) internal override {
    // Validate parameters
    require(amounts.length == 1 && amounts[0] > 0, 'CFIHLP: invalid amount');

    // Record assets in Farm contract. They don't earn rewards.
    //
    // NOTE: {removeAssets} must only be called from Investment CFolios.
    _cfolioFarm.removeAssets(itemCFolio, amounts[0], slotId);

    // Transfer LP token from this contract.
    (slotId == 0 ? stakingToken0 : stakingToken1).safeTransfer(
      _msgSender(),
      amounts[0]
    );
  }

  /**
   * @dev Verify if target base SFT is allowed
   */
  function _verifyTransferTarget(uint256 baseSftTokenId)
    internal
    view
    override
  {
    (, uint8 level) = _sftHolder.getTokenData(baseSftTokenId);

    require((LEVEL2WOLF & (uint256(1) << level)) > 0, 'CFIHLP: Wolves only');
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {ICFolioItemHandler} via {CFolioItemHandlerFarm}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {ICFolioItemHandler-getAmounts}
   */
  function getAmounts(address cfolioItem)
    external
    view
    override
    returns (uint256[] memory result)
  {
    result = _cfolioFarm.balancesOf(cfolioItem);
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

  //////////////////////////////////////////////////////////////////////////////
  // Asset access
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Adds investments into a cFolioItem SFT
   *
   * Transfers amounts of assets from users wallet to the contract. In general,
   * an Approval call is required before the function is called.
   *
   * @param from must be msg.sender for calls not from sftMinter
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param slotId The slot in the rewardFarm to deposit funds
   * @param amounts Investment amounts, implementation specific
   */
  function deposit(
    address from,
    uint256 baseTokenId,
    uint256 tokenId,
    uint256 slotId,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Removes investments from a cFolioItem SFT
   *
   * Withdrawn token are transfered back to msg.sender.
   *
   * @param baseTokenId cFolio tokenId, must be unlocked, or -1
   * @param tokenId cFolioItem tokenId, must be unlocked if not in unlocked cFolio
   * @param slotId The slot in the rewardFarm to withdraw funds
   * @param amounts Investment amounts, implementation specific
   */
  function withdraw(
    uint256 baseTokenId,
    uint256 tokenId,
    uint256 slotId,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Update investment values from sidechain
   *
   * Must be called from a registered root tunnel
   *
   * @param tokenId cFolioItem tokenId
   * @param amounts Investment amounts, implementation specific
   */
  function update(uint256 tokenId, uint256[] calldata amounts) external;

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

// BOIS feature bitmask
uint256 constant LEVEL2BOIS = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000F;
uint256 constant LEVEL2WOLF = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000F0;

interface ISFTEvaluator {
  /**
   * @dev Returns the reward in 1e6 factor notation (1e6 = 100%)
   */
  function rewardRate(uint256 sftTokenId) external view returns (uint32);

  /**
   * @dev Calculate the current reward rate, and notify TFC in case of change
   *
   * Optional revert on unchange to save gas on external calls.
   */
  function setRewardRate(uint256 tokenId, bool revertUnchanged) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import './IFarm.sol';

/**
 * @title ICFolioFarm
 *
 * @dev ICFolioFarm is the business logic interface to c-folio farms.
 */
interface ICFolioFarm is IFarm {
  /**
   * @dev Return number of slots
   */
  function slotCount() external view returns (uint256);

  /**
   * @dev Return total invested balance
   */
  function totalSupply(uint256 slotId) external view returns (uint256);

  /**
   * @dev Return invested balance of account
   */
  function balanceOf(address account, uint256 slotId)
    external
    view
    returns (uint256);

  /**
   * @dev Return invested balances per slot of account
   */
  function balancesOf(address account) external view returns (uint256[] memory);

  /**
   * @dev Return absolute amount of rewards during duration
   */
  function getRewardsForDuration(uint256 slotId)
    external
    view
    returns (uint256);

  /**
   * @dev Return share and earned amounts
   */
  function getShareAndEarned(address account, uint256 slotId)
    external
    view
    returns (uint256 share, uint256 earned);

  /**
   * @dev Increase amount of non-rewarded asset
   */
  function addAssets(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Remove amount of previous added assets
   */
  function removeAssets(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Increase amount of shares and earn rewards
   */
  function addShares(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Migrate amount of shares and rewards
   */
  function migrateShares(
    address account,
    uint256 amount,
    uint256 slotId,
    uint256 reward
  ) external;

  /**
   * @dev Remove amount of previous added shares, rewards will not be claimed
   */
  function removeShares(
    address account,
    uint256 amount,
    uint256 slotId
  ) external;

  /**
   * @dev Claim rewards harvested during reward time
   * @notice Empty slotIds get all rewards
   */
  function getRewards(
    address account,
    address rewardRecipient,
    uint256[] memory slotIds
  ) external;
}

/**
 * @title ICFolioFarmOwnable
 */

interface ICFolioFarmOwnable is ICFolioFarm {
  /**
   * @dev Transfer ownership
   */
  function transferOwnership(address newOwner) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

interface IController {
  /**
   * @dev Used to control fees and accessibility instead having an implementation
   * in each farm contract
   *
   * Deposit is only allowed if farm is open and not not paused. Must revert on
   * failure.
   *
   * @param amount Number of tokens the user wants to deposit
   *
   * @return fee The deposit fee (1e18 factor) on success
   */
  function onDeposit(uint256 amount) external view returns (uint256 fee);

  /**
   * @dev Used to control fees and accessibility instead having an
   * implementation in each farm contract
   *
   * Withdraw is only allowed if farm is not paused. Must revert on failure
   *
   * @param amount Number of tokens the user wants to withdraw
   *
   * @return fee The withdrawal fee (1e18 factor) on success
   */
  function onWithdraw(uint256 amount) external view returns (uint256 fee);

  /**
   * @dev Returns the paused state of the calling farm
   */
  function paused() external view returns (bool);

  /**
   * @dev Distribute rewards to sender and fee to internal contracts
   */
  function payOutRewards(address recipient, uint256 amount) external;
}

/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import './IController.sol';

interface IFarm {
  /**
   * @dev Return the farm's controller
   */
  function controller() external view returns (IController);

  /**
   * @dev Return a unique, case-sensitive farm name
   */
  function farmName() external view returns (string memory);

  /**
   * @dev Return when reward period is finished (UTC timestamp)
   */
  function periodFinish() external view returns (uint256);

  /**
   * @dev Return the rewards duration in seconds
   */
  function rewardsDuration() external view returns (uint256);

  /**
   * @dev Sets a new controller, can only be called by current controller
   */
  function setController(address newController) external;

  /**
   * @dev This function must be called initially and close at the time the
   * reward period ends
   */
  function notifyRewardAmount(uint256 reward) external;

  /**
   * @dev Set the duration of farm rewards, to continue rewards,
   * notifyRewardAmount() has to called for the next period
   */
  function setRewardsDuration(uint256 _rewardsDuration) external;

  /**
   * @dev Set the weight of investment token relative to 0
   */
  function weightSlot(uint256 slotId, uint256 weight) external;
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

/**
 * @notice Cryptofolio interface
 */
interface IWOWSCryptofolio {
  //////////////////////////////////////////////////////////////////////////////
  // Getter
  //////////////////////////////////////////////////////////////////////////////
  /**
   * @dev Return the handler (CFIH) of the underlying NFT
   */
  function handler() external view returns (address);

  //////////////////////////////////////////////////////////////////////////////
  // State modifiers
  //////////////////////////////////////////////////////////////////////////////
  /**
   * @dev Set the handler of the underlying NFT
   *
   * This function is called during I-NFT setup
   *
   * @param newHandler The new handler of the underlying NFT,
   */
  function setHandler(address newHandler) external;
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
  bytes32 public constant ADMIN_ACCOUNT = 'ADMIN_ACCOUNT';
  bytes32 public constant UNISWAP_V2_ROUTER02 = 'UNISWAP_V2_ROUTER02';
  bytes32 public constant WETH_WOWS_STAKE_FARM = 'WETH_WOWS_STAKE_FARM';
  bytes32 public constant WOWS_TOKEN = 'WOWS_TOKEN';
  bytes32 public constant UNISWAP_V2_PAIR = 'UNISWAP_V2_PAIR';
  bytes32 public constant UNISWAP_V2_PAIR_NATIVE = 'UNISWAP_V2_PAIR_NATIVE';
  bytes32 public constant WOWS_BOOSTER_PROXY = 'WOWS_BOOSTER_PROXY';
  bytes32 public constant REWARD_HANDLER = 'REWARD_HANDLER';
  bytes32 public constant SFT_MINTER_PROXY = 'SFT_MINTER_PROXY';
  bytes32 public constant SFT_HOLDER_PROXY = 'SFT_HOLDER_PROXY';
  bytes32 public constant SFT_EVALUATOR_PROXY = 'SFT_EVALUATOR_PROXY';
  bytes32 public constant TRADE_FLOOR_PROXY = 'TRADE_FLOOR_PROXY';
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