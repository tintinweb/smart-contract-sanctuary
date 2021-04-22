/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// File contracts/interfaces/IWhitelist.sol

pragma solidity ^0.8.0;

/**
 * Source: https://raw.githubusercontent.com/simple-restricted-token/reference-implementation/master/contracts/token/ERC1404/ERC1404.sol
 * With ERC-20 APIs removed (will be implemented as a separate contract).
 * And adding authorizeTransfer.
 */
interface IWhitelist {
  /**
   * @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
   * @param from Sending address
   * @param to Receiving address
   * @param value Amount of tokens being transferred
   * @return Code by which to reference message for rejection reasoning
   * @dev Overwrite with your custom transfer restriction logic
   */
  function detectTransferRestriction(
    address from,
    address to,
    uint value
  ) external view returns (uint8);

  /**
   * @notice Returns a human-readable message for a given restriction code
   * @param restrictionCode Identifier for looking up a message
   * @return Text showing the restriction's reasoning
   * @dev Overwrite with your custom message and restrictionCode handling
   */
  function messageForTransferRestriction(uint8 restrictionCode)
    external
    pure
    returns (string memory);

  /**
   * @notice Called by the DAT contract before a transfer occurs.
   * @dev This call will revert when the transfer is not authorized.
   * This is a mutable call to allow additional data to be recorded,
   * such as when the user aquired their tokens.
   */
  function authorizeTransfer(
    address _from,
    address _to,
    uint _value,
    bool _isSell
  ) external;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
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
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}


// File contracts/mixins/OperatorRole.sol

pragma solidity ^0.8.0;

// Original source: openzeppelin's SignerRole

/**
 * @notice allows a single owner to manage a group of operators which may
 * have some special permissions in the contract.
 */
contract OperatorRole is OwnableUpgradeable {
    mapping (address => bool) internal _operators;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    function _initializeOperatorRole() internal {
        __Ownable_init();
        _addOperator(msg.sender);
    }

    modifier onlyOperator() {
        require(
            isOperator(msg.sender),
            "OperatorRole: caller does not have the Operator role"
        );
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators[account];
    }

    function addOperator(address account) public onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) public onlyOwner {
        _removeOperator(account);
    }

    function renounceOperator() public {
        _removeOperator(msg.sender);
    }

    function _addOperator(address account) internal {
        _operators[account] = true;
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators[account] = false;
        emit OperatorRemoved(account);
    }

    uint[50] private ______gap;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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


// File contracts/Whitelist.sol

pragma solidity 0.8.3;



/**
 * @notice whitelist which manages KYC approvals, token lockup, and transfer
 * restrictions for a DAT token.
 */
contract Whitelist is OwnableUpgradeable, OperatorRole {
    // uint8 status codes as suggested by the ERC-1404 spec
    enum ErrorMessage {
        Success,
        JurisdictionFlow,
        LockUp,
        UserUnknown,
        JurisdictionHalt
    }

    event ConfigWhitelist(
        uint _startDate,
        uint _lockupGranularity,
        address indexed _operator
    );
    event UpdateJurisdictionFlow(
        uint indexed _fromJurisdictionId,
        uint indexed _toJurisdictionId,
        uint _lockupLength,
        address indexed _operator
    );
    event ApproveNewUser(
        address indexed _trader,
        uint indexed _jurisdictionId,
        address indexed _operator
    );
    event AddApprovedUserWallet(
        address indexed _userId,
        address indexed _newWallet,
        address indexed _operator
    );
    event RevokeUserWallet(address indexed _wallet, address indexed _operator);
    event UpdateJurisdictionForUserId(
        address indexed _userId,
        uint indexed _jurisdictionId,
        address indexed _operator
    );
    event AddLockup(
        address indexed _userId,
        uint _lockupExpirationDate,
        uint _numberOfTokensLocked,
        address indexed _operator
    );
    event UnlockTokens(
        address indexed _userId,
        uint _tokensUnlocked,
        address indexed _operator
    );
    event Halt(uint indexed _jurisdictionId, uint _until);
    event Resume(uint indexed _jurisdictionId);
    event MaxInvestorsChanged(uint _limit);
    event MaxInvestorsByJurisdictionChanged(uint indexed _jurisdictionId, uint _limit);

    /**
     * @notice the address of the contract this whitelist manages.
     * @dev this cannot change after initialization
     */
    IERC20 public callingContract;

    /**
     * @notice Merges lockup entries when the time delta between
     * them is less than this value.
     * @dev this can be changed by the owner at any time
     */
    struct Config {
        uint64 startDate;
        uint64 lockupGranularity;
    }

    Config internal config;

    struct InvestorLimit {
        uint128 max;
        uint128 current;
    }

    InvestorLimit public globalInvestorLimit;

    mapping(uint => InvestorLimit) public jurisdictionInvestorLimit;

    /**
     * @notice Maps Jurisdiction Id to it's halt due
     */
    mapping(uint => uint64) public jurisdictionHaltsUntil;

    mapping(uint => mapping(uint => uint64)) internal jurisdictionFlows;

    enum Status {
        Unknown,
        Activated,
        Revoked,
        Counted
    }

    struct UserInfo {
        // to check if user is counted
        Status status;
        // The user's current jurisdictionId or 0 for unknown (the default)
        uint8 jurisdictionId;
        // The first applicable entry in userIdLockups
        uint32 startIndex;
        // The last applicable entry in userIdLockups + 1
        uint32 endIndex;
        // The number of tokens locked, with details tracked in userIdLockups
        uint128 totalTokensLocked;
        // The number of wallet in use
        uint48 walletCount;
    }

    mapping(address => UserInfo) internal userInfo;

    /**
     * info stored for each token lockup.
     */
    struct Lockup {
        // The date/time that this lockup entry has expired and the tokens may be transferred
        uint64 lockupExpirationDate;
        // How many tokens locked until the given expiration date.
        uint128 numberOfTokensLocked;
    }

    mapping(address => mapping(uint => Lockup)) internal userIdLockups;

    struct WalletInfo {
        Status status;
        address userId;
    }

    mapping(address => WalletInfo) public walletInfo;

    bytes32 private constant BEACON_SLOT = keccak256(abi.encodePacked("fairmint.beaconproxy.beacon"));

    modifier onlyBeaconOperator() {
        bytes32 slot = BEACON_SLOT;
        address beacon;
        assembly {
            beacon := sload(slot)
        }
        require(beacon == address(0) || OperatorRole(beacon).isOperator(msg.sender), "!BeaconOperator");
        _;
    }

    /**
     * @notice checks for transfer restrictions between jurisdictions.
     * @return lockupLength if transfers between these jurisdictions are allowed and if a
     * token lockup should apply:
     * - 0 means transfers between these jurisdictions is blocked (the default)
     * - 1 is supported with no token lockup required
     * - >1 is supported and this value defines the lockup length in seconds
     */
    function getJurisdictionFlow(
        uint _fromJurisdictionId,
        uint _toJurisdictionId
    ) external view returns (uint lockupLength) {
        return jurisdictionFlows[_fromJurisdictionId][_toJurisdictionId];
    }

    /**
     * @notice checks details for a given userId.
     */
    function getAuthorizedUserIdInfo(address _userId)
        external
        view
        returns (
            uint jurisdictionId,
            uint totalTokensLocked,
            uint startIndex,
            uint endIndex
        )
    {
        UserInfo memory info = userInfo[_userId];
        return (
            info.jurisdictionId,
            info.totalTokensLocked,
            info.startIndex,
            info.endIndex
        );
    }

    function getInvestorInfo() external view returns(uint256 maxInvestor, uint256 currentInvestor) {
        return (globalInvestorLimit.max, globalInvestorLimit.current);
    }

    function getJurisdictionInfo(uint256 _jurisdictionId) external view returns(uint256 halt, uint256 maxInvestor, uint256 currentInvestor){
        InvestorLimit memory limit = jurisdictionInvestorLimit[_jurisdictionId];
        return (jurisdictionHaltsUntil[_jurisdictionId], limit.max, limit.current);
    }

    /**
     * @notice gets a specific lockup entry for a userId.
     * @dev use `getAuthorizedUserIdInfo` to determine the range of applicable lockupIndex.
     */
    function getUserIdLockup(address _userId, uint _lockupIndex)
        external
        view
        returns (uint lockupExpirationDate, uint numberOfTokensLocked)
    {
        Lockup memory lockup = userIdLockups[_userId][_lockupIndex];
        return (lockup.lockupExpirationDate, lockup.numberOfTokensLocked);
    }

    /**
     * @notice Returns the number of unlocked tokens a given userId has available.
     * @dev this is a `view`-only way to determine how many tokens are still locked
     * (info.totalTokensLocked is only accurate after processing lockups which changes state)
     */
    function getLockedTokenCount(address _userId)
        external
        view
        returns (uint lockedTokens)
    {
        UserInfo memory info = userInfo[_userId];
        lockedTokens = info.totalTokensLocked;
        uint endIndex = info.endIndex;
        for (uint i = info.startIndex; i < endIndex; i++) {
            Lockup memory lockup = userIdLockups[_userId][i];
            if (lockup.lockupExpirationDate > block.timestamp) {
                // no more eligible entries
                break;
            }
            // this lockup entry has expired and would be processed on the next tx
            lockedTokens -= lockup.numberOfTokensLocked;
        }
    }

    /**
     * @notice Checks if there is a transfer restriction for the given addresses.
     * Does not consider tokenLockup. Use `getLockedTokenCount` for that.
     * @dev this function is from the erc-1404 standard and currently in use by the DAT
     * for the `pay` feature.
     */
    function detectTransferRestriction(
        address _from,
        address _to,
        uint /*_value*/
    ) external view returns (uint8 status) {
        WalletInfo memory from = walletInfo[_from];
        WalletInfo memory to = walletInfo[_to];
        if (
            ((from.status == Status.Unknown || from.status == Status.Revoked) && _from != address(0)) ||
            ((to.status == Status.Unknown || to.status == Status.Revoked) && _to != address(0))
        ) {
            return uint8(ErrorMessage.UserUnknown);
        }
        if (from.userId != to.userId) {
            uint fromJurisdictionId = userInfo[from.userId]
                .jurisdictionId;
            uint toJurisdictionId = userInfo[to.userId].jurisdictionId;
            if (_isJurisdictionHalted(fromJurisdictionId) || _isJurisdictionHalted(toJurisdictionId)){
                return uint8(ErrorMessage.JurisdictionHalt);
            }
            if (jurisdictionFlows[fromJurisdictionId][toJurisdictionId] == 0) {
                return uint8(ErrorMessage.JurisdictionFlow);
            }
        }

        return uint8(ErrorMessage.Success);
    }

    function messageForTransferRestriction(uint8 _restrictionCode)
        external
        pure
        returns (string memory)
    {
        if (_restrictionCode == uint8(ErrorMessage.Success)) {
            return "SUCCESS";
        }
        if (_restrictionCode == uint8(ErrorMessage.JurisdictionFlow)) {
            return "DENIED: JURISDICTION_FLOW";
        }
        if (_restrictionCode == uint8(ErrorMessage.LockUp)) {
            return "DENIED: LOCKUP";
        }
        if (_restrictionCode == uint8(ErrorMessage.UserUnknown)) {
            return "DENIED: USER_UNKNOWN";
        }
        if (_restrictionCode == uint8(ErrorMessage.JurisdictionHalt)){
            return "DENIED: JURISDICTION_HALT";
        }
        return "DENIED: UNKNOWN_ERROR";
    }

    /**
     * @notice Called once to complete configuration for this contract.
     * @dev Done with `initialize` instead of a constructor in order to support
     * using this contract via an Upgradable Proxy.
     */
    function initialize(address _callingContract) public onlyBeaconOperator{
        _initializeOperatorRole();
        callingContract = IERC20(_callingContract);
    }

    /**
     * @notice Called by the owner to update the startDate or lockupGranularity.
     */
    function configWhitelist(uint _startDate, uint _lockupGranularity)
        external
        onlyOwner()
    {
        config = Config({
            startDate: uint64(_startDate),
            lockupGranularity: uint64(_lockupGranularity)
        });
        emit ConfigWhitelist(_startDate, _lockupGranularity, msg.sender);
    }

    function startDate() external view returns(uint256) {
        return config.startDate;
    }

    function lockupGranularity() external view returns(uint256) {
        return config.lockupGranularity;
    }

    function authorizedWalletToUserId(address wallet) external view returns(address userId) {
        return walletInfo[wallet].userId;
    }

    /**
     * @notice Called by the owner to define or update jurisdiction flows.
     * @param _lockupLengths defines transfer restrictions where:
     * - 0 is not supported (the default)
     * - 1 is supported with no token lockup required
     * - >1 is supported and this value defines the lockup length in seconds.
     * @dev note that this can be called with a partial list, only including entries
     * to be added or which have changed.
     */
    function updateJurisdictionFlows(
        uint[] calldata _fromJurisdictionIds,
        uint[] calldata _toJurisdictionIds,
        uint[] calldata _lockupLengths
    ) external onlyOwner() {
        uint count = _fromJurisdictionIds.length;
        for (uint i = 0; i < count; i++) {
            uint fromJurisdictionId = _fromJurisdictionIds[i];
            uint toJurisdictionId = _toJurisdictionIds[i];
            require(
                fromJurisdictionId > 0 && toJurisdictionId > 0,
                "INVALID_JURISDICTION_ID"
            );
            jurisdictionFlows[fromJurisdictionId][toJurisdictionId] = uint64(_lockupLengths[i]);
            emit UpdateJurisdictionFlow(
                fromJurisdictionId,
                toJurisdictionId,
                _lockupLengths[i],
                msg.sender
            );
        }
    }

    /**
     * @notice Called by an operator to add new traders.
     * @dev The trader will be assigned a userId equal to their wallet address.
     */
    function approveNewUsers(
        address[] calldata _traders,
        uint[] calldata _jurisdictionIds
    ) external onlyOperator() {
        uint length = _traders.length;
        for (uint i = 0; i < length; i++) {
            address trader = _traders[i];
            require(
                walletInfo[trader].userId == address(0),
                "USER_WALLET_ALREADY_ADDED"
            );

            uint jurisdictionId = _jurisdictionIds[i];
            require(jurisdictionId != 0, "INVALID_JURISDICTION_ID");

            walletInfo[trader] = WalletInfo({
                status: Status.Activated,
                userId: trader
            });
            userInfo[trader] = UserInfo({
                status: Status.Activated,
                jurisdictionId : uint8(jurisdictionId),
                startIndex : 0,
                endIndex : 0,
                totalTokensLocked: 0,
                walletCount : 1
            });
            require(globalInvestorLimit.max == 0 || globalInvestorLimit.max < globalInvestorLimit.current, "EXCEEDING_MAX_INVESTORS");
            InvestorLimit memory limit = jurisdictionInvestorLimit[jurisdictionId];
            require(limit.max == 0 || limit.max < limit.current, "EXCEEDING_JURISDICTION_MAX_INVESTORS");
            jurisdictionInvestorLimit[jurisdictionId].current++;
            globalInvestorLimit.current++;
            emit ApproveNewUser(trader, jurisdictionId, msg.sender);
        }
    }

    /**
     * @notice Called by an operator to add wallets to known userIds.
     */
    function addApprovedUserWallets(
        address[] calldata _userIds,
        address[] calldata _newWallets
    ) external onlyOperator() {
        uint length = _userIds.length;
        for (uint i = 0; i < length; i++) {
            address userId = _userIds[i];
            require(
                userInfo[userId].status != Status.Unknown,
                "USER_ID_UNKNOWN"
            );
            address newWallet = _newWallets[i];
            WalletInfo storage info = walletInfo[newWallet];
            require(
                info.status == Status.Unknown ||
                (info.status == Status.Revoked && info.userId == userId),
                "WALLET_ALREADY_ADDED"
            );
            walletInfo[newWallet] = WalletInfo({
                status: Status.Activated,
                userId: userId
            });
            if(userInfo[userId].walletCount == 0){
                userInfo[userId].status = Status.Activated;
                jurisdictionInvestorLimit[userInfo[userId].jurisdictionId].current++;
                globalInvestorLimit.current++;
            }
            userInfo[userId].walletCount++;
            emit AddApprovedUserWallet(userId, newWallet, msg.sender);
        }
    }

    /**
     * @notice Called by an operator to revoke approval for the given wallets.
     * @dev If this is called in error, you can restore access with `addApprovedUserWallets`.
     */
    function revokeUserWallets(address[] calldata _wallets)
        external
        onlyOperator()
    {
        uint length = _wallets.length;
        for (uint i = 0; i < length; i++) {
            WalletInfo memory wallet = walletInfo[_wallets[i]];
            require(
                wallet.status != Status.Unknown,
                "WALLET_NOT_FOUND"
            );
            userInfo[wallet.userId].walletCount--;
            if(userInfo[wallet.userId].walletCount == 0){
                userInfo[wallet.userId].status = Status.Revoked;
                jurisdictionInvestorLimit[userInfo[wallet.userId].jurisdictionId].current--;
                globalInvestorLimit.current--;
            }
            walletInfo[_wallets[i]].status = Status.Revoked;
            emit RevokeUserWallet(_wallets[i], msg.sender);
        }
    }

    /**
     * @notice Called by an operator to change the jurisdiction
     * for the given userIds.
     */
    function updateJurisdictionsForUserIds(
        address[] calldata _userIds,
        uint[] calldata _jurisdictionIds
    ) external onlyOperator() {
        uint length = _userIds.length;
        for (uint i = 0; i < length; i++) {
            address userId = _userIds[i];
            require(
                userInfo[userId].status != Status.Unknown,
                "USER_ID_UNKNOWN"
            );
            uint jurisdictionId = _jurisdictionIds[i];
            require(jurisdictionId != 0, "INVALID_JURISDICTION_ID");
            jurisdictionInvestorLimit[userInfo[userId].jurisdictionId].current--;
            userInfo[userId].jurisdictionId = uint8(jurisdictionId);
            jurisdictionInvestorLimit[jurisdictionId].current++;
            emit UpdateJurisdictionForUserId(userId, jurisdictionId, msg.sender);
        }
    }

    /**
     * @notice Adds a tokenLockup for the userId.
     * @dev A no-op if lockup is not required for this transfer.
     * The lockup entry is merged with the most recent lockup for that user
     * if the expiration date is <= `lockupGranularity` from the previous entry.
     */
    function _addLockup(
        address _userId,
        uint _lockupExpirationDate,
        uint _numberOfTokensLocked
    ) internal {
        if (
            _numberOfTokensLocked == 0 ||
            _lockupExpirationDate <= block.timestamp
        ) {
            // This is a no-op
            return;
        }
        emit AddLockup(
            _userId,
            _lockupExpirationDate,
            _numberOfTokensLocked,
            msg.sender
        );
        UserInfo storage info = userInfo[_userId];
        require(info.status != Status.Unknown, "USER_ID_UNKNOWN");
        require(info.totalTokensLocked + _numberOfTokensLocked >= _numberOfTokensLocked, "OVERFLOW");
        info.totalTokensLocked = info.totalTokensLocked + uint128(_numberOfTokensLocked);
        if (info.endIndex > 0) {
            Lockup storage lockup = userIdLockups[_userId][info.endIndex - 1];
            if (
                lockup.lockupExpirationDate + config.lockupGranularity >= _lockupExpirationDate
            ) {
                // Merge with the previous entry
                // if totalTokensLocked can't overflow then this value will not either
                lockup.numberOfTokensLocked += uint128(_numberOfTokensLocked);
                return;
            }
        }
        // Add a new lockup entry
        userIdLockups[_userId][info.endIndex] = Lockup(
            uint64(_lockupExpirationDate),
            uint128(_numberOfTokensLocked)
        );
        info.endIndex++;
    }

    /**
     * @notice Operators can manually add lockups for userIds.
     * This may be used by the organization before transfering tokens
     * from the initial supply.
     */
    function addLockups(
        address[] calldata _userIds,
        uint[] calldata _lockupExpirationDates,
        uint[] calldata _numberOfTokensLocked
    ) external onlyOperator() {
        uint length = _userIds.length;
        for (uint i = 0; i < length; i++) {
            _addLockup(
                _userIds[i],
                _lockupExpirationDates[i],
                _numberOfTokensLocked[i]
            );
        }
    }

    /**
     * @notice Checks the next lockup entry for a given user and unlocks
     * those tokens if applicable.
     * @param _ignoreExpiration bypasses the recorded expiration date and
     * removes the lockup entry if there are any remaining for this user.
     */
    function _processLockup(
        UserInfo storage info,
        address _userId,
        bool _ignoreExpiration
    ) internal returns (bool isDone) {
        if (info.startIndex >= info.endIndex) {
            // no lockups for this user
            return true;
        }
        Lockup storage lockup = userIdLockups[_userId][info.startIndex];
        if (lockup.lockupExpirationDate > block.timestamp && !_ignoreExpiration) {
            // no more eligable entries
            return true;
        }
        emit UnlockTokens(_userId, lockup.numberOfTokensLocked, msg.sender);
        info.totalTokensLocked -= lockup.numberOfTokensLocked;
        info.startIndex++;
        // Free up space we don't need anymore
        lockup.lockupExpirationDate = 0;
        lockup.numberOfTokensLocked = 0;
        // There may be another entry
        return false;
    }

    /**
     * @notice Anyone can process lockups for a userId.
     * This is generally unused but may be required if a given userId
     * has a lot of individual lockup entries which are expired.
     */
    function processLockups(address _userId, uint _maxCount) external {
        UserInfo storage info = userInfo[_userId];
        require(info.status != Status.Unknown, "USER_ID_UNKNOWN");
        for (uint i = 0; i < _maxCount; i++) {
            if (_processLockup(info, _userId, false)) {
                break;
            }
        }
    }

    /**
     * @notice Allows operators to remove lockup entries, bypassing the
     * recorded expiration date.
     * @dev This should generally remain unused. It could be used in combination with
     * `addLockups` to fix an incorrect lockup expiration date or quantity.
     */
    function forceUnlockUpTo(address _userId, uint _maxLockupIndex)
        external
        onlyOperator()
    {
        UserInfo storage info = userInfo[_userId];
        require(info.status != Status.Unknown, "USER_ID_UNKNOWN");
        require(_maxLockupIndex > info.startIndex, "ALREADY_UNLOCKED");
        uint maxCount = _maxLockupIndex - info.startIndex;
        for (uint i = 0; i < maxCount; i++) {
            if (_processLockup(info, _userId, true)) {
                break;
            }
        }
    }

    function _isJurisdictionHalted(uint _jurisdictionId) internal view returns(bool){
        uint until = jurisdictionHaltsUntil[_jurisdictionId];
        return until != 0 && until > block.timestamp;
    }

    /**
     * @notice halts jurisdictions of id `_jurisdictionIds` for `_duration` seconds
     * @dev only owner can call this function
     * @param _jurisdictionIds ids of the jurisdictions to halt
     * @param _expirationTimestamps due when halt ends
     **/
    function halt(uint[] calldata _jurisdictionIds, uint[] calldata _expirationTimestamps) external onlyOwner {
        uint length = _jurisdictionIds.length;
        for(uint i = 0; i<length; i++){
            _halt(_jurisdictionIds[i], _expirationTimestamps[i]);
        }
    }

    function _halt(uint _jurisdictionId, uint _until) internal {
        require(_until > block.timestamp, "HALT_DUE_SHOULD_BE_FUTURE");
        jurisdictionHaltsUntil[_jurisdictionId] = uint64(_until);
        emit Halt(_jurisdictionId, _until);
    }

    /**
     * @notice resume halted jurisdiction
     * @dev only owner can call this function
     * @param _jurisdictionIds list of jurisdiction ids to resume
     **/
    function resume(uint[] calldata _jurisdictionIds) external onlyOwner{
        uint length = _jurisdictionIds.length;
        for(uint i = 0; i < length; i++){
            _resume(_jurisdictionIds[i]);
        }
    }

    function _resume(uint _jurisdictionId) internal {
        require(jurisdictionHaltsUntil[_jurisdictionId] != 0, "ATTEMPT_TO_RESUME_NONE_HALTED_JURISDICATION");
        jurisdictionHaltsUntil[_jurisdictionId] = 0;
        emit Resume(_jurisdictionId);
    }

    /**
     * @notice changes max investors limit of the contract to `_limit`
     * @dev only owner can call this function
     * @param _limit new investor limit for contract
     */
    function setInvestorLimit(uint _limit) external onlyOwner {
        require(_limit >= globalInvestorLimit.current, "LIMIT_SHOULD_BE_LARGER_THAN_CURRENT_INVESTORS");
        globalInvestorLimit.max = uint128(_limit);
        emit MaxInvestorsChanged(_limit);
    }

    /**
     * @notice changes max investors limit of the `_jurisdcitionId` to `_limit`
     * @dev only owner can call this function
     * @param _jurisdictionIds jurisdiction id to update
     * @param _limits new investor limit for jurisdiction
     */
    function setInvestorLimitForJurisdiction(uint[] calldata _jurisdictionIds, uint[] calldata _limits) external onlyOwner {
        for(uint i = 0; i<_jurisdictionIds.length; i++){
            uint jurisdictionId = _jurisdictionIds[i];
            uint limit = _limits[i];
            require(limit >= jurisdictionInvestorLimit[jurisdictionId].current, "LIMIT_SHOULD_BE_LARGER_THAN_CURRENT_INVESTORS");
            jurisdictionInvestorLimit[jurisdictionId].max = uint128(limit);
            emit MaxInvestorsByJurisdictionChanged(jurisdictionId, limit);
        }
    }

    /**
     * @notice Called by the callingContract before a transfer occurs.
     * @dev This call will revert when the transfer is not authorized.
     * This is a mutable call to allow additional data to be recorded,
     * such as when the user aquired their tokens.
     **/
    function authorizeTransfer(
        address _from,
        address _to,
        uint _value,
        bool _isSell
    ) external {
        require(address(callingContract) == msg.sender, "CALL_VIA_CONTRACT_ONLY");

        if (_to == address(0) && !_isSell) {
            // This is a burn, no authorization required
            // You can burn locked tokens. Burning will effectively burn unlocked tokens,
            // and then burn locked tokens starting with those that will be unlocked first.
            return;
        }
        WalletInfo memory from = walletInfo[_from];
        require(
            (from.status != Status.Unknown && from.status != Status.Revoked) ||
            _from == address(0),
            "FROM_USER_UNKNOWN"
        );
        WalletInfo memory to = walletInfo[_to];
        require(
            (to.status != Status.Unknown && to.status != Status.Revoked) ||
            _to == address(0),
            "TO_USER_UNKNOWN"
        );

        // A single user can move funds between wallets they control without restriction
        if (from.userId != to.userId) {
            uint fromJurisdictionId = userInfo[from.userId]
            .jurisdictionId;
            uint toJurisdictionId = userInfo[to.userId].jurisdictionId;

            require(!_isJurisdictionHalted(fromJurisdictionId), "FROM_JURISDICTION_HALTED");
            require(!_isJurisdictionHalted(toJurisdictionId), "TO_JURISDICTION_HALTED");

            uint lockupLength = jurisdictionFlows[fromJurisdictionId][toJurisdictionId];
            require(lockupLength > 0, "DENIED: JURISDICTION_FLOW");

            // If the lockupLength is 1 then we interpret this as approved without any lockup
            // This means any token lockup period must be at least 2 seconds long in order to apply.
            if (lockupLength > 1 && _to != address(0)) {
                // Lockup may apply for any action other than burn/sell (e.g. buy/pay/transfer)
                uint lockupExpirationDate = block.timestamp + lockupLength;
                _addLockup(to.userId, lockupExpirationDate, _value);
            }

            if (_from == address(0)) {
                // This is minting (buy or pay)
                require(block.timestamp >= config.startDate, "WAIT_FOR_START_DATE");
            } else {
                // This is a transfer (or sell)
                UserInfo storage info = userInfo[from.userId];
                while (true) {
                    if (_processLockup(info, from.userId, false)) {
                        break;
                    }
                }
                uint balance = callingContract.balanceOf(_from);
                // This first require is redundant, but allows us to provide
                // a more clear error message.
                require(balance >= _value, "INSUFFICIENT_BALANCE");
                require(
                    _isSell ||
                    balance >= info.totalTokensLocked + _value,
                    "INSUFFICIENT_TRANSFERABLE_BALANCE"
                );
            }
        }
    }
}