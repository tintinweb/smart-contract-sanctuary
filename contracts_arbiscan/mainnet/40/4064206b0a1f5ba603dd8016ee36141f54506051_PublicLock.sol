pragma solidity 0.5.17;


import './interfaces/IPublicLock.sol';
import '@openzeppelin/upgrades/contracts/Initializable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/introspection/ERC165.sol';
import './mixins/MixinDisable.sol';
import './mixins/MixinERC721Enumerable.sol';
import './mixins/MixinFunds.sol';
import './mixins/MixinGrantKeys.sol';
import './mixins/MixinKeys.sol';
import './mixins/MixinLockCore.sol';
import './mixins/MixinLockMetadata.sol';
import './mixins/MixinPurchase.sol';
import './mixins/MixinRefunds.sol';
import './mixins/MixinTransfer.sol';
import './mixins/MixinSignatures.sol';
import './mixins/MixinLockManagerRole.sol';
import './mixins/MixinKeyGranterRole.sol';


/**
 * @title The Lock contract
 * @author Julien Genestoux (unlock-protocol.com)
 * @dev ERC165 allows our contract to be queried to determine whether it implements a given interface.
 * Every ERC-721 compliant contract must implement the ERC165 interface.
 * https://eips.ethereum.org/EIPS/eip-721
 */
contract PublicLock is
  IPublicLock,
  Initializable,
  ERC165,
  MixinLockManagerRole,
  MixinKeyGranterRole,
  MixinSignatures,
  MixinFunds,
  MixinDisable,
  MixinLockCore,
  MixinKeys,
  MixinLockMetadata,
  MixinERC721Enumerable,
  MixinGrantKeys,
  MixinPurchase,
  MixinTransfer,
  MixinRefunds
{
  function initialize(
    address _lockCreator,
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string memory _lockName
  ) public
    initializer()
  {
    MixinFunds._initializeMixinFunds(_tokenAddress);
    MixinDisable._initializeMixinDisable();
    MixinLockCore._initializeMixinLockCore(_lockCreator, _expirationDuration, _keyPrice, _maxNumberOfKeys);
    MixinLockMetadata._initializeMixinLockMetadata(_lockName);
    MixinERC721Enumerable._initializeMixinERC721Enumerable();
    MixinRefunds._initializeMixinRefunds();
    MixinLockManagerRole._initializeMixinLockManagerRole(_lockCreator);
    MixinKeyGranterRole._initializeMixinKeyGranterRole(_lockCreator);
    // registering the interface for erc721 with ERC165.sol using
    // the ID specified in the standard: https://eips.ethereum.org/EIPS/eip-721
    _registerInterface(0x80ac58cd);
  }

  /**
   * @notice Allow the contract to accept tips in ETH sent directly to the contract.
   * @dev This is okay to use even if the lock is priced in ERC-20 tokens
   */
  function() external payable {}
}

pragma solidity 0.5.17;

/**
* @title The PublicLock Interface
* @author Nick Furfaro (unlock-protocol.com)
 */


contract IPublicLock
{

// See indentationissue description here:
// https://github.com/duaraghav8/Ethlint/issues/268
// solium-disable indentation

  /// Functions

  function initialize(
    address _lockCreator,
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName
  ) external;

  /**
   * @notice Allow the contract to accept tips in ETH sent directly to the contract.
   * @dev This is okay to use even if the lock is priced in ERC-20 tokens
   */
  function() external payable;

  /**
   * @dev Never used directly
   */
  function initialize() external;

  /**
  * @notice The version number of the current implementation on this network.
  * @return The current version number.
  */
  function publicLockVersion() public pure returns (uint);

  /**
  * @notice Gets the current balance of the account provided.
  * @param _tokenAddress The token type to retrieve the balance of.
  * @param _account The account to get the balance of.
  * @return The number of tokens of the given type for the given address, possibly 0.
  */
  function getBalance(
    address _tokenAddress,
    address _account
  ) external view
    returns (uint);

  /**
  * @notice Used to disable lock before migrating keys and/or destroying contract.
  * @dev Throws if called by other than a lock manager.
  * @dev Throws if lock contract has already been disabled.
  */
  function disableLock() external;

  /**
   * @dev Called by a lock manager or beneficiary to withdraw all funds from the lock and send them to the `beneficiary`.
   * @dev Throws if called by other than a lock manager or beneficiary
   * @param _tokenAddress specifies the token address to withdraw or 0 for ETH. This is usually
   * the same as `tokenAddress` in MixinFunds.
   * @param _amount specifies the max amount to withdraw, which may be reduced when
   * considering the available balance. Set to 0 or MAX_UINT to withdraw everything.
   *  -- however be wary of draining funds as it breaks the `cancelAndRefund` and `expireAndRefundFor`
   * use cases.
   */
  function withdraw(
    address _tokenAddress,
    uint _amount
  ) external;

  /**
   * @notice An ERC-20 style approval, allowing the spender to transfer funds directly from this lock.
   */
  function approveBeneficiary(
    address _spender,
    uint _amount
  ) external
    returns (bool);

  /**
   * A function which lets a Lock manager of the lock to change the price for future purchases.
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if lock has been disabled
   * @dev Throws if _tokenAddress is not a valid token
   * @param _keyPrice The new price to set for keys
   * @param _tokenAddress The address of the erc20 token to use for pricing the keys,
   * or 0 to use ETH
   */
  function updateKeyPricing( uint _keyPrice, address _tokenAddress ) external;

  /**
   * A function which lets a Lock manager update the beneficiary account,
   * which receives funds on withdrawal.
   * @dev Throws if called by other than a Lock manager or beneficiary
   * @dev Throws if _beneficiary is address(0)
   * @param _beneficiary The new address to set as the beneficiary
   */
  function updateBeneficiary( address _beneficiary ) external;

    /**
   * Checks if the user has a non-expired key.
   * @param _user The address of the key owner
   */
  function getHasValidKey(
    address _user
  ) external view returns (bool);

  /**
   * @notice Find the tokenId for a given user
   * @return The tokenId of the NFT, else returns 0
   * @param _account The address of the key owner
  */
  function getTokenIdFor(
    address _account
  ) external view returns (uint);

  /**
  * A function which returns a subset of the keys for this Lock as an array
  * @param _page the page of key owners requested when faceted by page size
  * @param _pageSize the number of Key Owners requested per page
  * @dev Throws if there are no key owners yet
  */
  function getOwnersByPage(
    uint _page,
    uint _pageSize
  ) external view returns (address[] memory);

  /**
   * Checks if the given address owns the given tokenId.
   * @param _tokenId The tokenId of the key to check
   * @param _keyOwner The potential key owners address
   */
  function isKeyOwner(
    uint _tokenId,
    address _keyOwner
  ) external view returns (bool);

  /**
  * @dev Returns the key's ExpirationTimestamp field for a given owner.
  * @param _keyOwner address of the user for whom we search the key
  * @dev Returns 0 if the owner has never owned a key for this lock
  */
  function keyExpirationTimestampFor(
    address _keyOwner
  ) external view returns (uint timestamp);

  /**
   * Public function which returns the total number of unique owners (both expired
   * and valid).  This may be larger than totalSupply.
   */
  function numberOfOwners() external view returns (uint);

  /**
   * Allows a Lock manager to assign a descriptive name for this Lock.
   * @param _lockName The new name for the lock
   * @dev Throws if called by other than a Lock manager
   */
  function updateLockName(
    string calldata _lockName
  ) external;

  /**
   * Allows a Lock manager to assign a Symbol for this Lock.
   * @param _lockSymbol The new Symbol for the lock
   * @dev Throws if called by other than a Lock manager
   */
  function updateLockSymbol(
    string calldata _lockSymbol
  ) external;

  /**
    * @dev Gets the token symbol
    * @return string representing the token symbol
    */
  function symbol()
    external view
    returns(string memory);

    /**
   * Allows a Lock manager to update the baseTokenURI for this Lock.
   * @dev Throws if called by other than a Lock manager
   * @param _baseTokenURI String representing the base of the URI for this lock.
   */
  function setBaseTokenURI(
    string calldata _baseTokenURI
  ) external;

  /**  @notice A distinct Uniform Resource Identifier (URI) for a given asset.
   * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
   *  3986. The URI may point to a JSON file that conforms to the "ERC721
   *  Metadata JSON Schema".
   * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
   * @param _tokenId The tokenID we're inquiring about
   * @return String representing the URI for the requested token
   */
  function tokenURI(
    uint256 _tokenId
  ) external view returns(string memory);

  /**
   * @notice Allows a Lock manager to add or remove an event hook
   */
  function setEventHooks(
    address _onKeyPurchaseHook,
    address _onKeyCancelHook
  ) external;

  /**
   * Allows a Lock manager to give a collection of users a key with no charge.
   * Each key may be assigned a different expiration date.
   * @dev Throws if called by other than a Lock manager
   * @param _recipients An array of receiving addresses
   * @param _expirationTimestamps An array of expiration Timestamps for the keys being granted
   */
  function grantKeys(
    address[] calldata _recipients,
    uint[] calldata _expirationTimestamps,
    address[] calldata _keyManagers
  ) external;

  /**
  * @dev Purchase function
  * @param _value the number of tokens to pay for this purchase >= the current keyPrice - any applicable discount
  * (_value is ignored when using ETH)
  * @param _recipient address of the recipient of the purchased key
  * @param _referrer address of the user making the referral
  * @param _data arbitrary data populated by the front-end which initiated the sale
  * @dev Throws if lock is disabled. Throws if lock is sold-out. Throws if _recipient == address(0).
  * @dev Setting _value to keyPrice exactly doubles as a security feature. That way if a Lock manager increases the
  * price while my transaction is pending I can't be charged more than I expected (only applicable to ERC-20 when more
  * than keyPrice is approved for spending).
  */
  function purchase(
    uint256 _value,
    address _recipient,
    address _referrer,
    bytes calldata _data
  ) external payable;

  /**
   * @notice returns the minimum price paid for a purchase with these params.
   * @dev this considers any discount from Unlock or the OnKeyPurchase hook.
   */
  function purchasePriceFor(
    address _recipient,
    address _referrer,
    bytes calldata _data
  ) external view
    returns (uint);

  /**
   * Allow a Lock manager to change the transfer fee.
   * @dev Throws if called by other than a Lock manager
   * @param _transferFeeBasisPoints The new transfer fee in basis-points(bps).
   * Ex: 200 bps = 2%
   */
  function updateTransferFee(
    uint _transferFeeBasisPoints
  ) external;

  /**
   * Determines how much of a fee a key owner would need to pay in order to
   * transfer the key to another account.  This is pro-rated so the fee goes down
   * overtime.
   * @dev Throws if _keyOwner does not have a valid key
   * @param _keyOwner The owner of the key check the transfer fee for.
   * @param _time The amount of time to calculate the fee for.
   * @return The transfer fee in seconds.
   */
  function getTransferFee(
    address _keyOwner,
    uint _time
  ) external view returns (uint);

  /**
   * @dev Invoked by a Lock manager to expire the user's key and perform a refund and cancellation of the key
   * @param _keyOwner The key owner to whom we wish to send a refund to
   * @param amount The amount to refund the key-owner
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if _keyOwner does not have a valid key
   */
  function expireAndRefundFor(
    address _keyOwner,
    uint amount
  ) external;

   /**
   * @dev allows the key manager to expire a given tokenId
   * and send a refund to the keyOwner based on the amount of time remaining.
   * @param _tokenId The id of the key to cancel.
   */
  function cancelAndRefund(uint _tokenId) external;

  /**
   * @dev Cancels a key managed by a different user and sends the funds to the keyOwner.
   * @param _keyManager the key managed by this user will be canceled
   * @param _v _r _s getCancelAndRefundApprovalHash signed by the _keyManager
   * @param _tokenId The key to cancel
   */
  function cancelAndRefundFor(
    address _keyManager,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    uint _tokenId
  ) external;

  /**
   * @notice Sets the minimum nonce for a valid off-chain approval message from the
   * senders account.
   * @dev This can be used to invalidate a previously signed message.
   */
  function invalidateOffchainApproval(
    uint _nextAvailableNonce
  ) external;

  /**
   * Allow a Lock manager to change the refund penalty.
   * @dev Throws if called by other than a Lock manager
   * @param _freeTrialLength The new duration of free trials for this lock
   * @param _refundPenaltyBasisPoints The new refund penaly in basis-points(bps)
   */
  function updateRefundPenalty(
    uint _freeTrialLength,
    uint _refundPenaltyBasisPoints
  ) external;

  /**
   * @dev Determines how much of a refund a key owner would receive if they issued
   * @param _keyOwner The key owner to get the refund value for.
   * a cancelAndRefund block.timestamp.
   * Note that due to the time required to mine a tx, the actual refund amount will be lower
   * than what the user reads from this call.
   */
  function getCancelAndRefundValueFor(
    address _keyOwner
  ) external view returns (uint refund);

  function keyManagerToNonce(address ) external view returns (uint256 );

  /**
   * @notice returns the hash to sign in order to allow another user to cancel on your behalf.
   * @dev this can be computed in JS instead of read from the contract.
   * @param _keyManager The key manager's address (also the message signer)
   * @param _txSender The address cancelling cancel on behalf of the keyOwner
   * @return approvalHash The hash to sign
   */
  function getCancelAndRefundApprovalHash(
    address _keyManager,
    address _txSender
  ) external view returns (bytes32 approvalHash);

  function addKeyGranter(address account) external;

  function addLockManager(address account) external;

  function isKeyGranter(address account) external view returns (bool);

  function isLockManager(address account) external view returns (bool);

  function onKeyPurchaseHook() external view returns(address);

  function onKeyCancelHook() external view returns(address);

  function revokeKeyGranter(address _granter) external;

  function renounceLockManager() external;

  ///===================================================================
  /// Auto-generated getter functions from public state variables

  function beneficiary() external view returns (address );

  function expirationDuration() external view returns (uint256 );

  function freeTrialLength() external view returns (uint256 );

  function isAlive() external view returns (bool );

  function keyPrice() external view returns (uint256 );

  function maxNumberOfKeys() external view returns (uint256 );

  function owners(uint256 ) external view returns (address );

  function refundPenaltyBasisPoints() external view returns (uint256 );

  function tokenAddress() external view returns (address );

  function transferFeeBasisPoints() external view returns (uint256 );

  function unlockProtocol() external view returns (address );

  function keyManagerOf(uint) external view returns (address );

  ///===================================================================

  /**
  * @notice Allows the key owner to safely share their key (parent key) by
  * transferring a portion of the remaining time to a new key (child key).
  * @dev Throws if key is not valid.
  * @dev Throws if `_to` is the zero address
  * @param _to The recipient of the shared key
  * @param _tokenId the key to share
  * @param _timeShared The amount of time shared
  * checks if `_to` is a smart contract (code size > 0). If so, it calls
  * `onERC721Received` on `_to` and throws if the return value is not
  * `bytes4(keccak256('onERC721Received(address,address,uint,bytes)'))`.
  * @dev Emit Transfer event
  */
  function shareKey(
    address _to,
    uint _tokenId,
    uint _timeShared
  ) external;

  /**
  * @notice Update transfer and cancel rights for a given key
  * @param _tokenId The id of the key to assign rights for
  * @param _keyManager The address to assign the rights to for the given key
  */
  function setKeyManagerOf(
    uint _tokenId,
    address _keyManager
  ) external;

  /// @notice A descriptive name for a collection of NFTs in this contract
  function name() external view returns (string memory _name);
  ///===================================================================

  /// From ERC165.sol
  function supportsInterface(bytes4 interfaceId) external view returns (bool );
  ///===================================================================

  /// From ERC-721
  /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address _owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address _owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;

    /**
    * @notice Get the approved address for a single NFT
    * @dev Throws if `_tokenId` is not a valid NFT.
    * @param _tokenId The NFT to find the approved address for
    * @return The approved address for this NFT, or the zero address if there is none
    */
    function getApproved(uint256 _tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address _owner, address operator) public view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;

    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);



    /**
     * @notice An ERC-20 style transfer.
     * @param _value sends a token with _value * expirationDuration (the amount of time remaining on a standard purchase).
     * @dev The typical use case would be to call this with _value 1, which is on par with calling `transferFrom`. If the user
     * has more than `expirationDuration` time remaining this may use the `shareKey` function to send some but not all of the token.
     */
    function transfer(
      address _to,
      uint _value
    ) external
      returns (bool success);
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is Initializable, IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function initialize() public initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    uint256[50] private ______gap;
}

pragma solidity 0.5.17;

import './MixinFunds.sol';
import './MixinLockManagerRole.sol';

/**
 * @title Mixin allowing the Lock owner to disable a Lock (preventing new purchases)
 * and then destroy it.
 * @author HardlyDifficult
 * @dev `Mixins` are a design pattern seen in the 0x contracts.  It simply
 * separates logically groupings of code to ease readability.
 */
contract MixinDisable is
  MixinLockManagerRole,
  MixinFunds
{
  // Used to disable payable functions when deprecating an old lock
  bool public isAlive;

  event Disable();

  function _initializeMixinDisable(
  ) internal
  {
    isAlive = true;
  }

  // Only allow usage when contract is Alive
  modifier onlyIfAlive() {
    require(isAlive, 'LOCK_DEPRECATED');
    _;
  }

  /**
  * @dev Used to disable lock before migrating keys and/or destroying contract
   */
  function disableLock()
    external
    onlyLockManager
    onlyIfAlive
  {
    emit Disable();
    isAlive = false;
  }
}

pragma solidity 0.5.17;

import './MixinKeys.sol';
import './MixinLockCore.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Enumerable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/introspection/ERC165.sol';


/**
 * @title Implements the ERC-721 Enumerable extension.
 */
contract MixinERC721Enumerable is
  IERC721Enumerable,
  ERC165,
  MixinLockCore, // Implements totalSupply
  MixinKeys
{
  function _initializeMixinERC721Enumerable() internal
  {
    /**
     * register the supported interface to conform to ERC721Enumerable via ERC165
     * 0x780e9d63 ===
     *     bytes4(keccak256('totalSupply()')) ^
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
     *     bytes4(keccak256('tokenByIndex(uint256)'))
     */
    _registerInterface(0x780e9d63);
  }

  /// @notice Enumerate valid NFTs
  /// @dev Throws if `_index` >= `totalSupply()`.
  /// @param _index A counter less than `totalSupply()`
  /// @return The token identifier for the `_index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(
    uint256 _index
  ) public view
    returns (uint256)
  {
    require(_index < _totalSupply, 'OUT_OF_RANGE');
    return _index;
  }

  /// @notice Enumerate NFTs assigned to an owner
  /// @dev Throws if `_index` >= `balanceOf(_keyOwner)` or if
  ///  `_keyOwner` is the zero address, representing invalid NFTs.
  /// @param _keyOwner An address where we are interested in NFTs owned by them
  /// @param _index A counter less than `balanceOf(_keyOwner)`
  /// @return The token identifier for the `_index`th NFT assigned to `_keyOwner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(
    address _keyOwner,
    uint256 _index
  ) public view
    returns (uint256)
  {
    require(_index == 0, 'ONLY_ONE_KEY_PER_OWNER');
    return getTokenIdFor(_keyOwner);
  }
}

pragma solidity 0.5.17;

import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol';


/**
 * @title An implementation of the money related functions.
 * @author HardlyDifficult (unlock-protocol.com)
 */
contract MixinFunds
{
  using Address for address payable;
  using SafeERC20 for IERC20;

  /**
   * The token-type that this Lock is priced in.  If 0, then use ETH, else this is
   * a ERC20 token address.
   */
  address public tokenAddress;

  function _initializeMixinFunds(
    address _tokenAddress
  ) internal
  {
    tokenAddress = _tokenAddress;
    require(
      _tokenAddress == address(0) || IERC20(_tokenAddress).totalSupply() > 0,
      'INVALID_TOKEN'
    );
  }

  /**
   * Gets the current balance of the account provided.
   */
  function getBalance(
    address _tokenAddress,
    address _account
  ) public view
    returns (uint)
  {
    if(_tokenAddress == address(0)) {
      return _account.balance;
    } else {
      return IERC20(_tokenAddress).balanceOf(_account);
    }
  }

  /**
   * Transfers funds from the contract to the account provided.
   *
   * Security: be wary of re-entrancy when calling this function.
   */
  function _transfer(
    address _tokenAddress,
    address _to,
    uint _amount
  ) internal
  {
    if(_amount > 0) {
      if(_tokenAddress == address(0)) {
        // https://diligence.consensys.net/blog/2019/09/stop-using-soliditys-transfer-now/
        address(uint160(_to)).sendValue(_amount);
      } else {
        IERC20 token = IERC20(_tokenAddress);
        token.safeTransfer(_to, _amount);
      }
    }
  }
}

pragma solidity 0.5.17;

import './MixinKeys.sol';
import './MixinKeyGranterRole.sol';


/**
 * @title Mixin allowing the Lock owner to grant / gift keys to users.
 * @author HardlyDifficult
 * @dev `Mixins` are a design pattern seen in the 0x contracts.  It simply
 * separates logically groupings of code to ease readability.
 */
contract MixinGrantKeys is
  MixinKeyGranterRole,
  MixinKeys
{
  /**
   * Allows the Lock owner to give a collection of users a key with no charge.
   * Each key may be assigned a different expiration date.
   */
  function grantKeys(
    address[] calldata _recipients,
    uint[] calldata _expirationTimestamps,
    address[] calldata _keyManagers
  ) external
    onlyKeyGranterOrManager
  {
    for(uint i = 0; i < _recipients.length; i++) {
      address recipient = _recipients[i];
      uint expirationTimestamp = _expirationTimestamps[i];
      address keyManager = _keyManagers[i];

      require(recipient != address(0), 'INVALID_ADDRESS');

      Key storage toKey = keyByOwner[recipient];
      require(expirationTimestamp > toKey.expirationTimestamp, 'ALREADY_OWNS_KEY');

      uint idTo = toKey.tokenId;

      if(idTo == 0) {
        _assignNewTokenId(toKey);
        idTo = toKey.tokenId;
        _recordOwner(recipient, idTo);
      }
      // Set the key Manager
      _setKeyManagerOf(idTo, keyManager);
      emit KeyManagerChanged(idTo, keyManager);

      toKey.expirationTimestamp = expirationTimestamp;
      // trigger event
      emit Transfer(
        address(0), // This is a creation.
        recipient,
        idTo
      );
    }
  }
}

pragma solidity 0.5.17;

import './MixinLockCore.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';


/**
 * @title Mixin for managing `Key` data, as well as the * Approval related functions needed to meet the ERC721
 * standard.
 * @author HardlyDifficult
 * @dev `Mixins` are a design pattern seen in the 0x contracts.  It simply
 * separates logically groupings of code to ease readability.
 */
contract MixinKeys is
  MixinLockCore
{
  using SafeMath for uint;

  // The struct for a key
  struct Key {
    uint tokenId;
    uint expirationTimestamp;
  }

  // Emitted when the Lock owner expires a user's Key
  event ExpireKey(uint indexed tokenId);

  // Emitted when the expiration of a key is modified
  event ExpirationChanged(
    uint indexed _tokenId,
    uint _amount,
    bool _timeAdded
  );

  event KeyManagerChanged(uint indexed _tokenId, address indexed _newManager);


  // Keys
  // Each owner can have at most exactly one key
  // TODO: could we use public here? (this could be confusing though because it getter will
  // return 0 values when missing a key)
  mapping (address => Key) internal keyByOwner;

  // Each tokenId can have at most exactly one owner at a time.
  // Returns 0 if the token does not exist
  // TODO: once we decouple tokenId from owner address (incl in js), then we can consider
  // merging this with totalSupply into an array instead.
  mapping (uint => address) internal _ownerOf;

  // Addresses of owners are also stored in an array.
  // Addresses are never removed by design to avoid abuses around referals
  address[] public owners;

  // A given key has both an owner and a manager.
  // If keyManager == address(0) then the key owner is also the manager
  // Each key can have at most 1 keyManager.
  mapping (uint => address) public keyManagerOf;

    // Keeping track of approved transfers
  // This is a mapping of addresses which have approved
  // the transfer of a key to another address where their key can be transferred
  // Note: the approver may actually NOT have a key... and there can only
  // be a single approved address
  mapping (uint => address) private approved;

    // Keeping track of approved operators for a given Key manager.
  // This approves a given operator for all keys managed by the calling "keyManager"
  // The caller may not currently be the keyManager for ANY keys.
  // These approvals are never reset/revoked automatically, unlike "approved",
  // which is reset on transfer.
  mapping (address => mapping (address => bool)) private managerToOperatorApproved;

    // Ensure that the caller is the keyManager of the key
  // or that the caller has been approved
  // for ownership of that key
  modifier onlyKeyManagerOrApproved(
    uint _tokenId
  )
  {
    require(
      _isKeyManager(_tokenId, msg.sender) ||
      _isApproved(_tokenId, msg.sender) ||
      isApprovedForAll(_ownerOf[_tokenId], msg.sender),
      'ONLY_KEY_MANAGER_OR_APPROVED'
    );
    _;
  }

  // Ensures that an owner owns or has owned a key in the past
  modifier ownsOrHasOwnedKey(
    address _keyOwner
  ) {
    require(
      keyByOwner[_keyOwner].expirationTimestamp > 0, 'HAS_NEVER_OWNED_KEY'
    );
    _;
  }

  // Ensures that an owner has a valid key
  modifier hasValidKey(
    address _user
  ) {
    require(
      getHasValidKey(_user), 'KEY_NOT_VALID'
    );
    _;
  }

  // Ensures that a key has an owner
  modifier isKey(
    uint _tokenId
  ) {
    require(
      _ownerOf[_tokenId] != address(0), 'NO_SUCH_KEY'
    );
    _;
  }

  // Ensure that the caller owns the key
  modifier onlyKeyOwner(
    uint _tokenId
  ) {
    require(
      isKeyOwner(_tokenId, msg.sender), 'ONLY_KEY_OWNER'
    );
    _;
  }

  /**
   * In the specific case of a Lock, each owner can own only at most 1 key.
   * @return The number of NFTs owned by `_keyOwner`, either 0 or 1.
  */
  function balanceOf(
    address _keyOwner
  )
    public
    view
    returns (uint)
  {
    require(_keyOwner != address(0), 'INVALID_ADDRESS');
    return getHasValidKey(_keyOwner) ? 1 : 0;
  }

  /**
   * Checks if the user has a non-expired key.
   */
  function getHasValidKey(
    address _keyOwner
  )
    public
    view
    returns (bool)
  {
    return keyByOwner[_keyOwner].expirationTimestamp > block.timestamp;
  }

  /**
   * @notice Find the tokenId for a given user
   * @return The tokenId of the NFT, else returns 0
  */
  function getTokenIdFor(
    address _account
  ) public view
    returns (uint)
  {
    return keyByOwner[_account].tokenId;
  }

 /**
  * A function which returns a subset of the keys for this Lock as an array
  * @param _page the page of key owners requested when faceted by page size
  * @param _pageSize the number of Key Owners requested per page
  */
  function getOwnersByPage(uint _page, uint _pageSize)
    public
    view
    returns (address[] memory)
  {
    uint pageSize = _pageSize;
    uint _startIndex = _page * pageSize;
    uint endOfPageIndex;

    if (_startIndex + pageSize > owners.length) {
      endOfPageIndex = owners.length;
      pageSize = owners.length - _startIndex;
    } else {
      endOfPageIndex = (_startIndex + pageSize);
    }

    // new temp in-memory array to hold pageSize number of requested owners:
    address[] memory ownersByPage = new address[](pageSize);
    uint pageIndex = 0;

    // Build the requested set of owners into a new temporary array:
    for (uint i = _startIndex; i < endOfPageIndex; i++) {
      ownersByPage[pageIndex] = owners[i];
      pageIndex++;
    }

    return ownersByPage;
  }

  /**
   * Checks if the given address owns the given tokenId.
   */
  function isKeyOwner(
    uint _tokenId,
    address _keyOwner
  ) public view
    returns (bool)
  {
    return _ownerOf[_tokenId] == _keyOwner;
  }

  /**
  * @dev Returns the key's ExpirationTimestamp field for a given owner.
  * @param _keyOwner address of the user for whom we search the key
  * @dev Returns 0 if the owner has never owned a key for this lock
  */
  function keyExpirationTimestampFor(
    address _keyOwner
  ) public view
    returns (uint)
  {
    return keyByOwner[_keyOwner].expirationTimestamp;
  }

  /**
   * Public function which returns the total number of unique owners (both expired
   * and valid).  This may be larger than totalSupply.
   */
  function numberOfOwners()
    public
    view
    returns (uint)
  {
    return owners.length;
  }
  // Returns the owner of a given tokenId
  function ownerOf(
    uint _tokenId
  ) public view
    returns(address)
  {
    return _ownerOf[_tokenId];
  }

  /**
  * @notice Public function for updating transfer and cancel rights for a given key
  * @param _tokenId The id of the key to assign rights for
  * @param _keyManager The address with the manager's rights for the given key.
  * Setting _keyManager to address(0) means the keyOwner is also the keyManager
   */
  function setKeyManagerOf(
    uint _tokenId,
    address _keyManager
  ) public
    isKey(_tokenId)
  {
    require(
      _isKeyManager(_tokenId, msg.sender) ||
      isLockManager(msg.sender),
      'UNAUTHORIZED_KEY_MANAGER_UPDATE'
    );
    _setKeyManagerOf(_tokenId, _keyManager);
  }

  function _setKeyManagerOf(
    uint _tokenId,
    address _keyManager
  ) internal
  {
    if(keyManagerOf[_tokenId] != _keyManager) {
      keyManagerOf[_tokenId] = _keyManager;
      _clearApproval(_tokenId);
      emit KeyManagerChanged(_tokenId, address(0));
    }
  }

    /**
   * This approves _approved to get ownership of _tokenId.
   * Note: that since this is used for both purchase and transfer approvals
   * the approved token may not exist.
   */
  function approve(
    address _approved,
    uint _tokenId
  )
    public
    onlyIfAlive
    onlyKeyManagerOrApproved(_tokenId)
  {
    require(msg.sender != _approved, 'APPROVE_SELF');

    approved[_tokenId] = _approved;
    emit Approval(_ownerOf[_tokenId], _approved, _tokenId);
  }

    /**
   * @notice Get the approved address for a single NFT
   * @dev Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for
   * @return The approved address for this NFT, or the zero address if there is none
   */
  function getApproved(
    uint _tokenId
  ) public view
    isKey(_tokenId)
    returns (address)
  {
    address approvedRecipient = approved[_tokenId];
    return approvedRecipient;
  }

    /**
   * @dev Tells whether an operator is approved by a given keyManager
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view
    returns (bool)
  {
    uint tokenId = keyByOwner[_owner].tokenId;
    address keyManager = keyManagerOf[tokenId];
    if(keyManager == address(0)) {
      return managerToOperatorApproved[_owner][_operator];
    } else {
      return managerToOperatorApproved[keyManager][_operator];
    }
  }

  /**
  * Returns true if _keyManager is the manager of the key
  * identified by _tokenId
   */
  function _isKeyManager(
    uint _tokenId,
    address _keyManager
  ) internal view
    returns (bool)
  {
    if(keyManagerOf[_tokenId] == _keyManager ||
      (keyManagerOf[_tokenId] == address(0) && isKeyOwner(_tokenId, _keyManager))) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * Assigns the key a new tokenId (from totalSupply) if it does not already have
   * one assigned.
   */
  function _assignNewTokenId(
    Key storage _key
  ) internal
  {
    if (_key.tokenId == 0) {
      // This is a brand new owner
      // We increment the tokenId counter
      _totalSupply++;
      // we assign the incremented `_totalSupply` as the tokenId for the new key
      _key.tokenId = _totalSupply;
    }
  }

  /**
   * Records the owner of a given tokenId
   */
  function _recordOwner(
    address _keyOwner,
    uint _tokenId
  ) internal
  {
    if (_ownerOf[_tokenId] != _keyOwner) {
      // TODO: this may include duplicate entries
      owners.push(_keyOwner);
      // We register the owner of the tokenID
      _ownerOf[_tokenId] = _keyOwner;
    }
  }

  /**
  * @notice Modify the expirationTimestamp of a key
  * by a given amount.
  * @param _tokenId The ID of the key to modify.
  * @param _deltaT The amount of time in seconds by which
  * to modify the keys expirationTimestamp
  * @param _addTime Choose whether to increase or decrease
  * expirationTimestamp (false == decrease, true == increase)
  * @dev Throws if owner does not have a valid key.
  */
  function _timeMachine(
    uint _tokenId,
    uint256 _deltaT,
    bool _addTime
  ) internal
  {
    address tokenOwner = _ownerOf[_tokenId];
    require(tokenOwner != address(0), 'NON_EXISTENT_KEY');
    Key storage key = keyByOwner[tokenOwner];
    uint formerTimestamp = key.expirationTimestamp;
    bool validKey = getHasValidKey(tokenOwner);
    if(_addTime) {
      if(validKey) {
        key.expirationTimestamp = formerTimestamp.add(_deltaT);
      } else {
        key.expirationTimestamp = block.timestamp.add(_deltaT);
      }
    } else {
      key.expirationTimestamp = formerTimestamp.sub(_deltaT);
    }
    emit ExpirationChanged(_tokenId, _deltaT, _addTime);
  }

    /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(
    address _to,
    bool _approved
  ) public
    onlyIfAlive
  {
    require(_to != msg.sender, 'APPROVE_SELF');
    managerToOperatorApproved[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

    /**
   * @dev Checks if the given user is approved to transfer the tokenId.
   */
  function _isApproved(
    uint _tokenId,
    address _user
  ) internal view
    returns (bool)
  {
    return approved[_tokenId] == _user;
  }

    /**
   * @dev Function to clear current approval of a given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function _clearApproval(
    uint256 _tokenId
  ) internal
  {
    if (approved[_tokenId] != address(0)) {
      approved[_tokenId] = address(0);
    }
  }
}

pragma solidity 0.5.17;

import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Enumerable.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol';
import './MixinDisable.sol';
import './MixinLockManagerRole.sol';
import '../interfaces/IUnlock.sol';
import './MixinFunds.sol';
import '../interfaces/hooks/ILockKeyCancelHook.sol';
import '../interfaces/hooks/ILockKeyPurchaseHook.sol';


/**
 * @title Mixin for core lock data and functions.
 * @author HardlyDifficult
 * @dev `Mixins` are a design pattern seen in the 0x contracts.  It simply
 * separates logically groupings of code to ease readability.
 */
contract MixinLockCore is
  IERC721Enumerable,
  MixinLockManagerRole,
  MixinFunds,
  MixinDisable
{
  using Address for address;

  event Withdrawal(
    address indexed sender,
    address indexed tokenAddress,
    address indexed beneficiary,
    uint amount
  );

  event PricingChanged(
    uint oldKeyPrice,
    uint keyPrice,
    address oldTokenAddress,
    address tokenAddress
  );

  // Unlock Protocol address
  // TODO: should we make that private/internal?
  IUnlock public unlockProtocol;

  // Duration in seconds for which the keys are valid, after creation
  // should we take a smaller type use less gas?
  // TODO: add support for a timestamp instead of duration
  uint public expirationDuration;

  // price in wei of the next key
  // TODO: allow support for a keyPriceCalculator which could set prices dynamically
  uint public keyPrice;

  // Max number of keys sold if the keyReleaseMechanism is public
  uint public maxNumberOfKeys;

  // A count of how many new key purchases there have been
  uint internal _totalSupply;

  // The account which will receive funds on withdrawal
  address public beneficiary;

  // The denominator component for values specified in basis points.
  uint internal constant BASIS_POINTS_DEN = 10000;

  ILockKeyPurchaseHook public onKeyPurchaseHook;
  ILockKeyCancelHook public onKeyCancelHook;

  // Ensure that the Lock has not sold all of its keys.
  modifier notSoldOut() {
    require(maxNumberOfKeys > _totalSupply, 'LOCK_SOLD_OUT');
    _;
  }

  modifier onlyLockManagerOrBeneficiary()
  {
    require(
      isLockManager(msg.sender) || msg.sender == beneficiary,
      'ONLY_LOCK_MANAGER_OR_BENEFICIARY'
    );
    _;
  }

  function _initializeMixinLockCore(
    address _beneficiary,
    uint _expirationDuration,
    uint _keyPrice,
    uint _maxNumberOfKeys
  ) internal
  {
    require(_expirationDuration <= 100 * 365 * 24 * 60 * 60, 'MAX_EXPIRATION_100_YEARS');
    unlockProtocol = IUnlock(msg.sender); // Make sure we link back to Unlock's smart contract.
    beneficiary = _beneficiary;
    expirationDuration = _expirationDuration;
    keyPrice = _keyPrice;
    maxNumberOfKeys = _maxNumberOfKeys;
  }

  // The version number of the current implementation on this network
  function publicLockVersion(
  ) public pure
    returns (uint)
  {
    return 8;
  }

  /**
   * @dev Called by owner to withdraw all funds from the lock and send them to the `beneficiary`.
   * @param _tokenAddress specifies the token address to withdraw or 0 for ETH. This is usually
   * the same as `tokenAddress` in MixinFunds.
   * @param _amount specifies the max amount to withdraw, which may be reduced when
   * considering the available balance. Set to 0 or MAX_UINT to withdraw everything.
   *
   * TODO: consider allowing anybody to trigger this as long as it goes to owner anyway?
   *  -- however be wary of draining funds as it breaks the `cancelAndRefund` and `expireAndRefundFor`
   * use cases.
   */
  function withdraw(
    address _tokenAddress,
    uint _amount
  ) external
    onlyLockManagerOrBeneficiary
  {
    uint balance = getBalance(_tokenAddress, address(this));
    uint amount;
    if(_amount == 0 || _amount > balance)
    {
      require(balance > 0, 'NOT_ENOUGH_FUNDS');
      amount = balance;
    }
    else
    {
      amount = _amount;
    }

    emit Withdrawal(msg.sender, _tokenAddress, beneficiary, amount);
    // Security: re-entrancy not a risk as this is the last line of an external function
    _transfer(_tokenAddress, beneficiary, amount);
  }

  /**
   * A function which lets the owner of the lock change the pricing for future purchases.
   * This consists of 2 parts: The token address and the price in the given token.
   * In order to set the token to ETH, use 0 for the token Address.
   */
  function updateKeyPricing(
    uint _keyPrice,
    address _tokenAddress
  )
    external
    onlyLockManager
    onlyIfAlive
  {
    uint oldKeyPrice = keyPrice;
    address oldTokenAddress = tokenAddress;
    require(
      _tokenAddress == address(0) || IERC20(_tokenAddress).totalSupply() > 0,
      'INVALID_TOKEN'
    );
    keyPrice = _keyPrice;
    tokenAddress = _tokenAddress;
    emit PricingChanged(oldKeyPrice, keyPrice, oldTokenAddress, tokenAddress);
  }

  /**
   * A function which lets the owner of the lock update the beneficiary account,
   * which receives funds on withdrawal.
   */
  function updateBeneficiary(
    address _beneficiary
  ) external
  {
    require(msg.sender == beneficiary || isLockManager(msg.sender), 'ONLY_BENEFICIARY_OR_LOCKMANAGER');
    require(_beneficiary != address(0), 'INVALID_ADDRESS');
    beneficiary = _beneficiary;
  }

  /**
   * @notice Allows a lock manager to add or remove an event hook
   */
  function setEventHooks(
    address _onKeyPurchaseHook,
    address _onKeyCancelHook
  ) external
    onlyLockManager()
  {
    require(_onKeyPurchaseHook == address(0) || _onKeyPurchaseHook.isContract(), 'INVALID_ON_KEY_SOLD_HOOK');
    require(_onKeyCancelHook == address(0) || _onKeyCancelHook.isContract(), 'INVALID_ON_KEY_CANCEL_HOOK');
    onKeyPurchaseHook = ILockKeyPurchaseHook(_onKeyPurchaseHook);
    onKeyCancelHook = ILockKeyCancelHook(_onKeyCancelHook);
  }

  function totalSupply()
    public
    view returns(uint256)
  {
    return _totalSupply;
  }

  /**
   * @notice An ERC-20 style approval, allowing the spender to transfer funds directly from this lock.
   */
  function approveBeneficiary(
    address _spender,
    uint _amount
  ) public
    onlyLockManagerOrBeneficiary
    returns (bool)
  {
    return IERC20(tokenAddress).approve(_spender, _amount);
  }
}

pragma solidity 0.5.17;

import '@openzeppelin/contracts-ethereum-package/contracts/introspection/ERC165.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Enumerable.sol';
import '../UnlockUtils.sol';
import './MixinKeys.sol';
import './MixinLockCore.sol';
import './MixinLockManagerRole.sol';

/**
 * @title Mixin for metadata about the Lock.
 * @author HardlyDifficult
 * @dev `Mixins` are a design pattern seen in the 0x contracts.  It simply
 * separates logically groupings of code to ease readability.
 */
contract MixinLockMetadata is
  IERC721Enumerable,
  ERC165,
  MixinLockManagerRole,
  MixinLockCore,
  MixinKeys
{
  using UnlockUtils for uint;
  using UnlockUtils for address;
  using UnlockUtils for string;

  /// A descriptive name for a collection of NFTs in this contract.Defaults to "Unlock-Protocol" but is settable by lock owner
  string public name;

  /// An abbreviated name for NFTs in this contract. Defaults to "KEY" but is settable by lock owner
  string private lockSymbol;

  // the base Token URI for this Lock. If not set by lock owner, the global URI stored in Unlock is used.
  string private baseTokenURI;

  event NewLockSymbol(
    string symbol
  );

  function _initializeMixinLockMetadata(
    string memory _lockName
  ) internal
  {
    ERC165.initialize();
    name = _lockName;
    // registering the optional erc721 metadata interface with ERC165.sol using
    // the ID specified in the standard: https://eips.ethereum.org/EIPS/eip-721
    _registerInterface(0x5b5e139f);
  }

  /**
   * Allows the Lock owner to assign a descriptive name for this Lock.
   */
  function updateLockName(
    string calldata _lockName
  ) external
    onlyLockManager
  {
    name = _lockName;
  }

  /**
   * Allows the Lock owner to assign a Symbol for this Lock.
   */
  function updateLockSymbol(
    string calldata _lockSymbol
  ) external
    onlyLockManager
  {
    lockSymbol = _lockSymbol;
    emit NewLockSymbol(_lockSymbol);
  }

  /**
    * @dev Gets the token symbol
    * @return string representing the token name
    */
  function symbol()
    external view
    returns(string memory)
  {
    if(bytes(lockSymbol).length == 0) {
      return unlockProtocol.globalTokenSymbol();
    } else {
      return lockSymbol;
    }
  }

  /**
   * Allows the Lock owner to update the baseTokenURI for this Lock.
   */
  function setBaseTokenURI(
    string calldata _baseTokenURI
  ) external
    onlyLockManager
  {
    baseTokenURI = _baseTokenURI;
  }

  /**  @notice A distinct Uniform Resource Identifier (URI) for a given asset.
   * @param _tokenId The iD of the token  for which we want to retrieve the URI.
   * If 0 is passed here, we just return the appropriate baseTokenURI.
   * If a custom URI has been set we don't return the lock address.
   * It may be included in the custom baseTokenURI if needed.
   * @dev  URIs are defined in RFC 3986. The URI may point to a JSON file
   * that conforms to the "ERC721 Metadata JSON Schema".
   * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
   */
  function tokenURI(
    uint256 _tokenId
  ) external
    view
    returns(string memory)
  {
    string memory URI;
    string memory tokenId;
    string memory lockAddress = address(this).address2Str();
    string memory seperator;

    if(_tokenId != 0) {
      tokenId = _tokenId.uint2Str();
    } else {
      tokenId = '';
    }

    if(bytes(baseTokenURI).length == 0) {
      URI = unlockProtocol.globalBaseTokenURI();
      seperator = '/';
    } else {
      URI = baseTokenURI;
      seperator = '';
      lockAddress = '';
    }

    return URI.strConcat(
        lockAddress,
        seperator,
        tokenId
      );
  }
}

pragma solidity 0.5.17;

import './MixinDisable.sol';
import './MixinKeys.sol';
import './MixinLockCore.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import './MixinFunds.sol';


/**
 * @title Mixin for the purchase-related functions.
 * @author HardlyDifficult
 * @dev `Mixins` are a design pattern seen in the 0x contracts.  It simply
 * separates logically groupings of code to ease readability.
 */
contract MixinPurchase is
  MixinFunds,
  MixinDisable,
  MixinLockCore,
  MixinKeys
{
  using SafeMath for uint;

  event RenewKeyPurchase(address indexed owner, uint newExpiration);

  /**
  * @dev Purchase function
  * @param _value the number of tokens to pay for this purchase >= the current keyPrice - any applicable discount
  * (_value is ignored when using ETH)
  * @param _recipient address of the recipient of the purchased key
  * @param _referrer address of the user making the referral
  * @param _data arbitrary data populated by the front-end which initiated the sale
  * @dev Setting _value to keyPrice exactly doubles as a security feature. That way if the lock owner increases the
  * price while my transaction is pending I can't be charged more than I expected (only applicable to ERC-20 when more
  * than keyPrice is approved for spending).
  */
  function purchase(
    uint256 _value,
    address _recipient,
    address _referrer,
    bytes calldata _data
  ) external payable
    onlyIfAlive
    notSoldOut
  {
    require(_recipient != address(0), 'INVALID_ADDRESS');

    // Assign the key
    Key storage toKey = keyByOwner[_recipient];
    uint idTo = toKey.tokenId;
    uint newTimeStamp;

    if (idTo == 0) {
      // Assign a new tokenId (if a new owner or previously transferred)
      _assignNewTokenId(toKey);
      // refresh the cached value
      idTo = toKey.tokenId;
      _recordOwner(_recipient, idTo);
      newTimeStamp = block.timestamp + expirationDuration;
      toKey.expirationTimestamp = newTimeStamp;

      // trigger event
      emit Transfer(
        address(0), // This is a creation.
        _recipient,
        idTo
      );
    } else if (toKey.expirationTimestamp > block.timestamp) {
      // This is an existing owner trying to extend their key
      newTimeStamp = toKey.expirationTimestamp.add(expirationDuration);
      toKey.expirationTimestamp = newTimeStamp;
      emit RenewKeyPurchase(_recipient, newTimeStamp);
    } else {
      // This is an existing owner trying to renew their expired key
      // SafeAdd is not required here since expirationDuration is capped to a tiny value
      // (relative to the size of a uint)
      newTimeStamp = block.timestamp + expirationDuration;
      toKey.expirationTimestamp = newTimeStamp;

      // reset the key Manager to 0x00
      _setKeyManagerOf(idTo, address(0));

      emit RenewKeyPurchase(_recipient, newTimeStamp);
    }

    (uint inMemoryKeyPrice, uint discount, uint tokens) = _purchasePriceFor(_recipient, _referrer, _data);
    if (discount > 0)
    {
      unlockProtocol.recordConsumedDiscount(discount, tokens);
    }

    // Record price without any tips
    unlockProtocol.recordKeyPurchase(inMemoryKeyPrice, _referrer);

    // We explicitly allow for greater amounts of ETH or tokens to allow 'donations'
    uint pricePaid;
    if(tokenAddress != address(0))
    {
      pricePaid = _value;
      IERC20 token = IERC20(tokenAddress);
      token.safeTransferFrom(msg.sender, address(this), _value);
    }
    else
    {
      pricePaid = msg.value;
    }
    require(pricePaid >= inMemoryKeyPrice, 'INSUFFICIENT_VALUE');

    if(address(onKeyPurchaseHook) != address(0))
    {
      onKeyPurchaseHook.onKeyPurchase(msg.sender, _recipient, _referrer, _data, inMemoryKeyPrice, pricePaid);
    }
  }

  /**
   * @notice returns the minimum price paid for a purchase with these params.
   * @dev minKeyPrice considers any discount from Unlock or the OnKeyPurchase hook
   */
  function purchasePriceFor(
    address _recipient,
    address _referrer,
    bytes calldata _data
  ) external view
    returns (uint minKeyPrice)
  {
    (minKeyPrice, , ) = _purchasePriceFor(_recipient, _referrer, _data);
  }

  /**
   * @notice returns the minimum price paid for a purchase with these params.
   * @dev minKeyPrice considers any discount from Unlock or the OnKeyPurchase hook
   * unlockDiscount and unlockTokens are the values returned from `computeAvailableDiscountFor`
   */
  function _purchasePriceFor(
    address _recipient,
    address _referrer,
    bytes memory _data
  ) internal view
    returns (uint minKeyPrice, uint unlockDiscount, uint unlockTokens)
  {
    if(address(onKeyPurchaseHook) != address(0))
    {
      minKeyPrice = onKeyPurchaseHook.keyPurchasePrice(msg.sender, _recipient, _referrer, _data);
    }
    else
    {
      minKeyPrice = keyPrice;
    }

    if(minKeyPrice > 0)
    {
      (unlockDiscount, unlockTokens) = unlockProtocol.computeAvailableDiscountFor(_recipient, minKeyPrice);
      require(unlockDiscount <= minKeyPrice, 'INVALID_DISCOUNT_FROM_UNLOCK');
      minKeyPrice -= unlockDiscount;
    }
  }
}

pragma solidity 0.5.17;

import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';
import './MixinSignatures.sol';
import './MixinKeys.sol';
import './MixinLockCore.sol';
import './MixinLockManagerRole.sol';
import './MixinFunds.sol';


contract MixinRefunds is
  MixinLockManagerRole,
  MixinSignatures,
  MixinFunds,
  MixinLockCore,
  MixinKeys
{
  using SafeMath for uint;

  // CancelAndRefund will return funds based on time remaining minus this penalty.
  // This is calculated as `proRatedRefund * refundPenaltyBasisPoints / BASIS_POINTS_DEN`.
  uint public refundPenaltyBasisPoints;

  uint public freeTrialLength;

  /// @notice The typehash per the EIP-712 standard
  /// @dev This can be computed in JS instead of read from the contract
  bytes32 private constant CANCEL_TYPEHASH = keccak256('cancelAndRefundFor(address _keyOwner)');

  event CancelKey(
    uint indexed tokenId,
    address indexed owner,
    address indexed sendTo,
    uint refund
  );

  event RefundPenaltyChanged(
    uint freeTrialLength,
    uint refundPenaltyBasisPoints
  );

  function _initializeMixinRefunds() internal
  {
    // default to 10%
    refundPenaltyBasisPoints = 1000;
  }

  /**
   * @dev Invoked by the lock owner to destroy the user's ket and perform a refund and cancellation
   * of the key
   */
  function expireAndRefundFor(
    address _keyOwner,
    uint amount
  ) external
    onlyLockManager
    hasValidKey(_keyOwner)
  {
    _cancelAndRefund(_keyOwner, amount);
  }

  /**
   * @dev Destroys the key and sends a refund based on the amount of time remaining.
   * @param _tokenId The id of the key to cancel.
   */
  function cancelAndRefund(uint _tokenId)
    external
    onlyKeyManagerOrApproved(_tokenId)
  {
    address keyOwner = ownerOf(_tokenId);
    uint refund = _getCancelAndRefundValue(keyOwner);

    _cancelAndRefund(keyOwner, refund);
  }

  /**
   * @dev Cancels a key managed by a different user and sends the funds to the msg.sender.
   * @param _keyManager the key managed by this user will be canceled
   * @param _v _r _s getCancelAndRefundApprovalHash signed by the _keyOwner
   * @param _tokenId The key to cancel
   */
  function cancelAndRefundFor(
    address _keyManager,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    uint _tokenId
  ) external
    consumeOffchainApproval(
      getCancelAndRefundApprovalHash(_keyManager, msg.sender),
      _keyManager,
      _v,
      _r,
      _s
    )
  {
    address keyOwner = ownerOf(_tokenId);
    uint refund = _getCancelAndRefundValue(keyOwner);
    _cancelAndRefund(keyOwner, refund);
  }

  /**
   * Allow the owner to change the refund penalty.
   */
  function updateRefundPenalty(
    uint _freeTrialLength,
    uint _refundPenaltyBasisPoints
  ) external
    onlyLockManager
  {
    emit RefundPenaltyChanged(
      _freeTrialLength,
      _refundPenaltyBasisPoints
    );

    freeTrialLength = _freeTrialLength;
    refundPenaltyBasisPoints = _refundPenaltyBasisPoints;
  }

  /**
   * @dev Determines how much of a refund a key owner would receive if they issued
   * a cancelAndRefund block.timestamp.
   * Note that due to the time required to mine a tx, the actual refund amount will be lower
   * than what the user reads from this call.
   */
  function getCancelAndRefundValueFor(
    address _keyOwner
  )
    external view
    returns (uint refund)
  {
    return _getCancelAndRefundValue(_keyOwner);
  }

  /**
   * @notice returns the hash to sign in order to allow another user to cancel on your behalf.
   * @dev this can be computed in JS instead of read from the contract.
   * @param _keyManager The key manager's address (also the message signer)
   * @param _txSender The address cancelling cancel on behalf of the keyOwner
   * @return approvalHash The hash to sign
   */
  function getCancelAndRefundApprovalHash(
    address _keyManager,
    address _txSender
  ) public view
    returns (bytes32 approvalHash)
  {
    return keccak256(
      abi.encodePacked(
        // Approval is specific to this Lock
        address(this),
        // The specific function the signer is approving
        CANCEL_TYPEHASH,
        // Approval enables only one cancel call
        keyManagerToNonce[_keyManager],
        // Approval allows only one account to broadcast the tx
        _txSender
      )
    );
  }

  /**
   * @dev cancels the key for the given keyOwner and sends the refund to the msg.sender.
   */
  function _cancelAndRefund(
    address _keyOwner,
    uint refund
  ) internal
  {
    Key storage key = keyByOwner[_keyOwner];

    emit CancelKey(key.tokenId, _keyOwner, msg.sender, refund);
    // expirationTimestamp is a proxy for hasKey, setting this to `block.timestamp` instead
    // of 0 so that we can still differentiate hasKey from hasValidKey.
    key.expirationTimestamp = block.timestamp;

    if (refund > 0) {
      // Security: doing this last to avoid re-entrancy concerns
      _transfer(tokenAddress, _keyOwner, refund);
    }

    // inform the hook if there is one registered
    if(address(onKeyCancelHook) != address(0))
    {
      onKeyCancelHook.onKeyCancel(msg.sender, _keyOwner, refund);
    }
  }

  /**
   * @dev Determines how much of a refund a key owner would receive if they issued
   * a cancelAndRefund now.
   * @param _keyOwner The owner of the key check the refund value for.
   */
  function _getCancelAndRefundValue(
    address _keyOwner
  )
    private view
    hasValidKey(_keyOwner)
    returns (uint refund)
  {
    Key storage key = keyByOwner[_keyOwner];
    // Math: safeSub is not required since `hasValidKey` confirms timeRemaining is positive
    uint timeRemaining = key.expirationTimestamp - block.timestamp;
    if(timeRemaining + freeTrialLength >= expirationDuration) {
      refund = keyPrice;
    } else {
      // Math: using safeMul in case keyPrice or timeRemaining is very large
      refund = keyPrice.mul(timeRemaining) / expirationDuration;
    }

    // Apply the penalty if this is not a free trial
    if(freeTrialLength == 0 || timeRemaining + freeTrialLength < expirationDuration)
    {
      uint penalty = keyPrice.mul(refundPenaltyBasisPoints) / BASIS_POINTS_DEN;
      if (refund > penalty) {
        // Math: safeSub is not required since the if confirms this won't underflow
        refund -= penalty;
      } else {
        refund = 0;
      }
    }
  }
}

pragma solidity 0.5.17;

import './MixinLockManagerRole.sol';
import './MixinDisable.sol';
import './MixinKeys.sol';
import './MixinFunds.sol';
import './MixinLockCore.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol';

/**
 * @title Mixin for the transfer-related functions needed to meet the ERC721
 * standard.
 * @author Nick Furfaro
 * @dev `Mixins` are a design pattern seen in the 0x contracts.  It simply
 * separates logically groupings of code to ease readability.
 */

contract MixinTransfer is
  MixinLockManagerRole,
  MixinFunds,
  MixinLockCore,
  MixinKeys
{
  using SafeMath for uint;
  using Address for address;

  event TransferFeeChanged(
    uint transferFeeBasisPoints
  );

  // 0x150b7a02 == bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'))
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // The fee relative to keyPrice to charge when transfering a Key to another account
  // (potentially on a 0x marketplace).
  // This is calculated as `keyPrice * transferFeeBasisPoints / BASIS_POINTS_DEN`.
  uint public transferFeeBasisPoints;

  /**
  * @notice Allows the key owner to safely share their key (parent key) by
  * transferring a portion of the remaining time to a new key (child key).
  * @param _to The recipient of the shared key
  * @param _tokenId the key to share
  * @param _timeShared The amount of time shared
  */
  function shareKey(
    address _to,
    uint _tokenId,
    uint _timeShared
  ) public
    onlyIfAlive
    onlyKeyManagerOrApproved(_tokenId)
  {
    require(transferFeeBasisPoints < BASIS_POINTS_DEN, 'KEY_TRANSFERS_DISABLED');
    require(_to != address(0), 'INVALID_ADDRESS');
    address keyOwner = _ownerOf[_tokenId];
    require(getHasValidKey(keyOwner), 'KEY_NOT_VALID');
    Key storage fromKey = keyByOwner[keyOwner];
    Key storage toKey = keyByOwner[_to];
    uint idTo = toKey.tokenId;
    uint time;
    // get the remaining time for the origin key
    uint timeRemaining = fromKey.expirationTimestamp - block.timestamp;
    // get the transfer fee based on amount of time wanted share
    uint fee = getTransferFee(keyOwner, _timeShared);
    uint timePlusFee = _timeShared.add(fee);

    // ensure that we don't try to share too much
    if(timePlusFee < timeRemaining) {
      // now we can safely set the time
      time = _timeShared;
      // deduct time from parent key, including transfer fee
      _timeMachine(_tokenId, timePlusFee, false);
    } else {
      // we have to recalculate the fee here
      fee = getTransferFee(keyOwner, timeRemaining);
      time = timeRemaining - fee;
      fromKey.expirationTimestamp = block.timestamp; // Effectively expiring the key
      emit ExpireKey(_tokenId);
    }

    if (idTo == 0) {
      _assignNewTokenId(toKey);
      idTo = toKey.tokenId;
      _recordOwner(_to, idTo);
      emit Transfer(
        address(0), // This is a creation or time-sharing
        _to,
        idTo
      );
    } else if (toKey.expirationTimestamp <= block.timestamp) {
      // reset the key Manager for expired keys
      _setKeyManagerOf(idTo, address(0));
    }

    // add time to new key
    _timeMachine(idTo, time, true);
    // trigger event
    emit Transfer(
      keyOwner,
      _to,
      idTo
    );

    require(_checkOnERC721Received(keyOwner, _to, _tokenId, ''), 'NON_COMPLIANT_ERC721_RECEIVER');
  }

  function transferFrom(
    address _from,
    address _recipient,
    uint _tokenId
  )
    public
    onlyIfAlive
    hasValidKey(_from)
    onlyKeyManagerOrApproved(_tokenId)
  {
    require(isKeyOwner(_tokenId, _from), 'TRANSFER_FROM: NOT_KEY_OWNER');
    require(transferFeeBasisPoints < BASIS_POINTS_DEN, 'KEY_TRANSFERS_DISABLED');
    require(_recipient != address(0), 'INVALID_ADDRESS');
    uint fee = getTransferFee(_from, 0);

    Key storage fromKey = keyByOwner[_from];
    Key storage toKey = keyByOwner[_recipient];

    uint previousExpiration = toKey.expirationTimestamp;
    // subtract the fee from the senders key before the transfer
    _timeMachine(_tokenId, fee, false);

    if (toKey.tokenId == 0) {
      toKey.tokenId = _tokenId;
      _recordOwner(_recipient, _tokenId);
      // Clear any previous approvals
      _clearApproval(_tokenId);
    }

    if (previousExpiration <= block.timestamp) {
      // The recipient did not have a key, or had a key but it expired. The new expiration is the sender's key expiration
      // An expired key is no longer a valid key, so the new tokenID is the sender's tokenID
      toKey.expirationTimestamp = fromKey.expirationTimestamp;
      toKey.tokenId = _tokenId;

      // Reset the key Manager to the key owner
      _setKeyManagerOf(_tokenId, address(0));

      _recordOwner(_recipient, _tokenId);
    } else {
      // The recipient has a non expired key. We just add them the corresponding remaining time
      // SafeSub is not required since the if confirms `previousExpiration - block.timestamp` cannot underflow
      toKey.expirationTimestamp = fromKey
        .expirationTimestamp.add(previousExpiration - block.timestamp);
    }

    // Effectively expiring the key for the previous owner
    fromKey.expirationTimestamp = block.timestamp;

    // Set the tokenID to 0 for the previous owner to avoid duplicates
    fromKey.tokenId = 0;

    // trigger event
    emit Transfer(
      _from,
      _recipient,
      _tokenId
    );
  }

  /**
   * @notice An ERC-20 style transfer.
   * @param _value sends a token with _value * expirationDuration (the amount of time remaining on a standard purchase).
   * @dev The typical use case would be to call this with _value 1, which is on par with calling `transferFrom`. If the user
   * has more than `expirationDuration` time remaining this may use the `shareKey` function to send some but not all of the token.
   */
  function transfer(
    address _to,
    uint _value
  ) public
    returns (bool success)
  {
    uint maxTimeToSend = _value * expirationDuration;
    Key storage fromKey = keyByOwner[msg.sender];
    uint timeRemaining = fromKey.expirationTimestamp.sub(block.timestamp);
    if(maxTimeToSend < timeRemaining)
    {
      shareKey(_to, fromKey.tokenId, maxTimeToSend);
    }
    else
    {
      transferFrom(msg.sender, _to, fromKey.tokenId);
    }

    // Errors will cause a revert
    return true;
  }

  /**
  * @notice Transfers the ownership of an NFT from one address to another address
  * @dev This works identically to the other function with an extra data parameter,
  *  except this function just sets data to ''
  * @param _from The current owner of the NFT
  * @param _to The new owner
  * @param _tokenId The NFT to transfer
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId
  )
    public
  {
    safeTransferFrom(_from, _to, _tokenId, '');
  }

  /**
  * @notice Transfers the ownership of an NFT from one address to another address.
  * When transfer is complete, this functions
  *  checks if `_to` is a smart contract (code size > 0). If so, it calls
  *  `onERC721Received` on `_to` and throws if the return value is not
  *  `bytes4(keccak256('onERC721Received(address,address,uint,bytes)'))`.
  * @param _from The current owner of the NFT
  * @param _to The new owner
  * @param _tokenId The NFT to transfer
  * @param _data Additional data with no specified format, sent in call to `_to`
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint _tokenId,
    bytes memory _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
    require(_checkOnERC721Received(_from, _to, _tokenId, _data), 'NON_COMPLIANT_ERC721_RECEIVER');

  }

  /**
   * Allow the Lock owner to change the transfer fee.
   */
  function updateTransferFee(
    uint _transferFeeBasisPoints
  )
    external
    onlyLockManager
  {
    emit TransferFeeChanged(
      _transferFeeBasisPoints
    );
    transferFeeBasisPoints = _transferFeeBasisPoints;
  }

  /**
   * Determines how much of a fee a key owner would need to pay in order to
   * transfer the key to another account.  This is pro-rated so the fee goes down
   * overtime.
   * @param _keyOwner The owner of the key check the transfer fee for.
   */
  function getTransferFee(
    address _keyOwner,
    uint _time
  )
    public view
    returns (uint)
  {
    if(! getHasValidKey(_keyOwner)) {
      return 0;
    } else {
      Key storage key = keyByOwner[_keyOwner];
      uint timeToTransfer;
      uint fee;
      // Math: safeSub is not required since `hasValidKey` confirms timeToTransfer is positive
      // this is for standard key transfers
      if(_time == 0) {
        timeToTransfer = key.expirationTimestamp - block.timestamp;
      } else {
        timeToTransfer = _time;
      }
      fee = timeToTransfer.mul(transferFeeBasisPoints) / BASIS_POINTS_DEN;
      return fee;
    }
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

}

pragma solidity 0.5.17;

import '@openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol';


contract MixinSignatures
{
  /// @notice emits anytime the nonce used for off-chain approvals changes.
  event NonceChanged(
    address indexed keyManager,
    uint nextAvailableNonce
  );

  // Stores a nonce per user to use for signed messages
  mapping(address => uint) public keyManagerToNonce;

  /// @notice Validates an off-chain approval signature.
  /// @dev If valid the nonce is consumed, else revert.
  modifier consumeOffchainApproval(
    bytes32 _hash,
    address _keyManager,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  )
  {
    require(
      ecrecover(
        ECDSA.toEthSignedMessageHash(_hash),
        _v,
        _r,
        _s
      ) == _keyManager, 'INVALID_SIGNATURE'
    );
    keyManagerToNonce[_keyManager]++;
    emit NonceChanged(_keyManager, keyManagerToNonce[_keyManager]);
    _;
  }

  /**
   * @notice Sets the minimum nonce for a valid off-chain approval message from the
   * senders account.
   * @dev This can be used to invalidate a previously signed message.
   */
  function invalidateOffchainApproval(
    uint _nextAvailableNonce
  ) external
  {
    require(_nextAvailableNonce > keyManagerToNonce[msg.sender], 'NONCE_ALREADY_USED');
    keyManagerToNonce[msg.sender] = _nextAvailableNonce;
    emit NonceChanged(msg.sender, _nextAvailableNonce);
  }
}

pragma solidity 0.5.17;

// This contract mostly follows the pattern established by openzeppelin in
// openzeppelin/contracts-ethereum-package/contracts/access/roles

import '@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol';


contract MixinLockManagerRole {
  using Roles for Roles.Role;

  event LockManagerAdded(address indexed account);
  event LockManagerRemoved(address indexed account);

  Roles.Role private lockManagers;

  function _initializeMixinLockManagerRole(address sender) internal {
    if (!isLockManager(sender)) {
      lockManagers.add(sender);
    }
  }

  modifier onlyLockManager() {
    require(isLockManager(msg.sender), 'MixinLockManager: caller does not have the LockManager role');
    _;
  }

  function isLockManager(address account) public view returns (bool) {
    return lockManagers.has(account);
  }

  function addLockManager(address account) public onlyLockManager {
    lockManagers.add(account);
    emit LockManagerAdded(account);
  }

  function renounceLockManager() public {
    lockManagers.remove(msg.sender);
    emit LockManagerRemoved(msg.sender);
  }
}

pragma solidity 0.5.17;

// This contract mostly follows the pattern established by openzeppelin in
// openzeppelin/contracts-ethereum-package/contracts/access/roles

import '@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol';
import './MixinLockManagerRole.sol';


contract MixinKeyGranterRole is MixinLockManagerRole {
  using Roles for Roles.Role;

  event KeyGranterAdded(address indexed account);
  event KeyGranterRemoved(address indexed account);

  Roles.Role private keyGranters;

  function _initializeMixinKeyGranterRole(address sender) internal {
    if (!isKeyGranter(sender)) {
      keyGranters.add(sender);
    }
  }

  modifier onlyKeyGranterOrManager() {
    require(isKeyGranter(msg.sender) || isLockManager(msg.sender), 'MixinKeyGranter: caller does not have the KeyGranter or LockManager role');
    _;
  }

  function isKeyGranter(address account) public view returns (bool) {
    return keyGranters.has(account);
  }

  function addKeyGranter(address account) public onlyLockManager {
    keyGranters.add(account);
    emit KeyGranterAdded(account);
  }

  function revokeKeyGranter(address _granter) public onlyLockManager {
    keyGranters.remove(_granter);
    emit KeyGranterRemoved(_granter);
  }
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is Initializable, IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

pragma solidity 0.5.17;


/**
 * @title The Unlock Interface
 * @author Nick Furfaro (unlock-protocol.com)
**/

interface IUnlock
{
  // Use initialize instead of a constructor to support proxies(for upgradeability via zos).
  function initialize(address _unlockOwner) external;

  /**
  * @dev Create lock
  * This deploys a lock for a creator. It also keeps track of the deployed lock.
  * @param _tokenAddress set to the ERC20 token address, or 0 for ETH.
  * @param _salt an identifier for the Lock, which is unique for the user.
  * This may be implemented as a sequence ID or with RNG. It's used with `create2`
  * to know the lock's address before the transaction is mined.
  */
  function createLock(
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName,
    bytes12 _salt
  ) external returns(address);

    /**
   * This function keeps track of the added GDP, as well as grants of discount tokens
   * to the referrer, if applicable.
   * The number of discount tokens granted is based on the value of the referal,
   * the current growth rate and the lock's discount token distribution rate
   * This function is invoked by a previously deployed lock only.
   */
  function recordKeyPurchase(
    uint _value,
    address _referrer // solhint-disable-line no-unused-vars
  )
    external;

    /**
   * This function will keep track of consumed discounts by a given user.
   * It will also grant discount tokens to the creator who is granting the discount based on the
   * amount of discount and compensation rate.
   * This function is invoked by a previously deployed lock only.
   */
  function recordConsumedDiscount(
    uint _discount,
    uint _tokens // solhint-disable-line no-unused-vars
  )
    external;

    /**
   * This function returns the discount available for a user, when purchasing a
   * a key from a lock.
   * This does not modify the state. It returns both the discount and the number of tokens
   * consumed to grant that discount.
   */
  function computeAvailableDiscountFor(
    address _purchaser, // solhint-disable-line no-unused-vars
    uint _keyPrice // solhint-disable-line no-unused-vars
  )
    external
    view
    returns(uint discount, uint tokens);

  // Function to read the globalTokenURI field.
  function globalBaseTokenURI()
    external
    view
    returns(string memory);

  /**
   * @dev Redundant with globalBaseTokenURI() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalBaseTokenURI()
    external
    view
    returns (string memory);

  // Function to read the globalTokenSymbol field.
  function globalTokenSymbol()
    external
    view
    returns(string memory);

  // Function to read the chainId field.
  function chainId()
    external
    view
    returns(uint);

  /**
   * @dev Redundant with globalTokenSymbol() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalTokenSymbol()
    external
    view
    returns (string memory);

  /**
   * @notice Allows the owner to update configuration variables
   */
  function configUnlock(
    address _udt,
    address _weth,
    uint _estimatedGasForPurchase,
    string calldata _symbol,
    string calldata _URI,
    uint _chainId
  )
    external;

  /**
   * @notice Upgrade the PublicLock template used for future calls to `createLock`.
   * @dev This will initialize the template and revokeOwnership.
   */
  function setLockTemplate(
    address payable _publicLockAddress
  ) external;

  // Allows the owner to change the value tracking variables as needed.
  function resetTrackedValue(
    uint _grossNetworkProduct,
    uint _totalDiscountGranted
  ) external;

  function grossNetworkProduct() external view returns(uint);

  function totalDiscountGranted() external view returns(uint);

  function locks(address) external view returns(bool deployed, uint totalSales, uint yieldedDiscountTokens);

  // The address of the public lock template, used when `createLock` is called
  function publicLockAddress() external view returns(address);

  // Map token address to exchange contract address if the token is supported
  // Used for GDP calculations
  function uniswapOracles(address) external view returns(address);

  // The WETH token address, used for value calculations
  function weth() external view returns(address);

  // The UDT token address, used to mint tokens on referral
  function udt() external view returns(address);

  // The approx amount of gas required to purchase a key
  function estimatedGasForPurchase() external view returns(uint);

  // The version number of the current Unlock implementation on this network
  function unlockVersion() external pure returns(uint16);

  /**
   * @notice allows the owner to set the oracle address to use for value conversions
   * setting the _oracleAddress to address(0) removes support for the token
   * @dev This will also call update to ensure at least one datapoint has been recorded.
   */
  function setOracle(
    address _tokenAddress,
    address _oracleAddress
  ) external;

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() external view returns(bool);

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns(address);

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() external;

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;
}

pragma solidity 0.5.17;


/**
 * @notice Functions to be implemented by a keyCancelHook.
 * @dev Lock hooks are configured by calling `setEventHooks` on the lock.
 */
interface ILockKeyCancelHook
{
  /**
   * @notice If the lock owner has registered an implementer
   * then this hook is called with every key cancel.
   * @param operator the msg.sender issuing the cancel
   * @param to the account which had the key canceled
   * @param refund the amount sent to the `to` account (ETH or a ERC-20 token)
   */
  function onKeyCancel(
    address operator,
    address to,
    uint256 refund
  ) external;
}

pragma solidity 0.5.17;


/**
 * @notice Functions to be implemented by a keyPurchaseHook.
 * @dev Lock hooks are configured by calling `setEventHooks` on the lock.
 */
interface ILockKeyPurchaseHook
{
  /**
   * @notice Used to determine the purchase price before issueing a transaction.
   * This allows the hook to offer a discount on purchases.
   * This may revert to prevent a purchase.
   * @param from the msg.sender making the purchase
   * @param recipient the account which will be granted a key
   * @param referrer the account which referred this key sale
   * @param data arbitrary data populated by the front-end which initiated the sale
   * @return the minimum value/price required to purchase a key with these settings
   * @dev the lock's address is the `msg.sender` when this function is called via
   * the lock's `purchasePriceFor` function
   */
  function keyPurchasePrice(
    address from,
    address recipient,
    address referrer,
    bytes calldata data
  ) external view
    returns (uint minKeyPrice);

  /**
   * @notice If the lock owner has registered an implementer then this hook
   * is called with every key sold.
   * @param from the msg.sender making the purchase
   * @param recipient the account which will be granted a key
   * @param referrer the account which referred this key sale
   * @param data arbitrary data populated by the front-end which initiated the sale
   * @param minKeyPrice the price including any discount granted from calling this
   * hook's `keyPurchasePrice` function
   * @param pricePaid the value/pricePaid included with the purchase transaction
   * @dev the lock's address is the `msg.sender` when this function is called
   */
  function onKeyPurchase(
    address from,
    address recipient,
    address referrer,
    bytes calldata data,
    uint minKeyPrice,
    uint pricePaid
  ) external;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is Initializable, IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity 0.5.17;

// This contract provides some utility methods for use with the unlock protocol smart contracts.
// Borrowed from:
// https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol#L943

library UnlockUtils {

  function strConcat(
    string memory _a,
    string memory _b,
    string memory _c,
    string memory _d
  ) internal pure
    returns (string memory _concatenatedString)
  {
    return string(abi.encodePacked(_a, _b, _c, _d));
  }

  function uint2Str(
    uint _i
  ) internal pure
    returns (string memory _uintAsString)
  {
    // make a copy of the param to avoid security/no-assign-params error
    uint c = _i;
    if (_i == 0) {
      return '0';
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (c != 0) {
      bstr[k--] = byte(uint8(48 + c % 10));
      c /= 10;
    }
    return string(bstr);
  }

  function address2Str(
    address _addr
  ) internal pure
    returns(string memory)
  {
    bytes32 value = bytes32(uint256(_addr));
    bytes memory alphabet = '0123456789abcdef';
    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint i = 0; i < 20; i++) {
      str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
      str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }
}

pragma solidity ^0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}