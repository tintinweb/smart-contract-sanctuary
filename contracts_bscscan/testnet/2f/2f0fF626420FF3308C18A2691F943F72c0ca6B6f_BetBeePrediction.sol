/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.7;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.7;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity ^0.8.7;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.7;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.7;

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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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

pragma solidity ^0.8.7;


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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.7;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity ^0.8.7;

contract PriceManager {

    AggregatorV3Interface public oracle;
    uint256 oracleUpdateAllowance = 300;
    string public assetPair; // BTCUSDT or ETHUSDT or BNBUSDT
    uint256 public oracleLatestRoundId;

    constructor(address _oracleAddress, string memory _assetPair) {
        require(_oracleAddress != address(0), "Invalid oracle address");
        oracle = AggregatorV3Interface(_oracleAddress);
        assetPair = _assetPair;
    }

    function _getLatestPrice() internal view returns(uint256, int256) { 
        uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;
        (uint80 roundId, int256 price, , uint256 timestamp, ) = oracle.latestRoundData();
        require(timestamp <= leastAllowedTimestamp, "Oracle update exceeded max timestamp allowance");
        require(uint256(roundId) > oracleLatestRoundId, "Oracle roundId must be larger than oracleLatestRoundId");
        return (roundId, price);
    }
}


pragma solidity ^0.8.7;

/**
 * @title PredictionAdministrator
 */
contract PredictionAdministrator is Ownable, Pausable, ReentrancyGuard {

    address private admin;
    address public operator;
    uint256 public treasuryFee;
    uint256 public constant MAX_TREASURY_FEE = 5; // 5%
    uint256 public minBetAmount; // minimum betting amount (denominated in wei)
    uint256 public treasuryAmount; // funds in treasury collected from fee
    uint256 public claimableTreasuryPercent = 80; //80%

    event NewMinBetAmount(uint256 minBetAmount);
    event NewTreasuryFee(uint256 treasuryFee);
    event NewAdmin(address indexed admin);
    event NewOperator(address indexed operator);
    event NewClaimableTreasuryPercent(uint256 claimableTreasuryPercent);
    event TreasuryClaim(address indexed admin, uint256 amount);

    constructor(address _adminAddress, uint256 _minBetAmount, uint256 _treasuryFee) {
        require(_minBetAmount > 0, "Invalid Min bet amount");
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee is too high");
        require(_adminAddress != address(0), "Invalid admin address");
        admin = _adminAddress;
        operator = _adminAddress;
        minBetAmount = _minBetAmount;
        treasuryFee = _treasuryFee;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Set minBetAmount
     * @dev Callable by admin
     * @param _minBetAmount: minimum bet amount to be set
     */
    function setMinBetAmount(uint256 _minBetAmount) external whenPaused onlyAdmin {
        require(_minBetAmount != 0, "Must be superior to 0");
        minBetAmount = _minBetAmount;

        emit NewMinBetAmount(_minBetAmount);
    }

    /**
     * @notice Set Treasury Fee
     * @dev Callable by admin
     * @param _treasuryFee: new treasury fee
     */
    function setTreasuryFee(uint256 _treasuryFee) external whenPaused onlyAdmin {
        require(_treasuryFee < MAX_TREASURY_FEE, "Treasury fee is too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(_treasuryFee);
    }

    /**
     * @notice Set admin
     * @dev callable by Owner of the contract
     * @param _admin: new admin address
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;

        emit NewAdmin(_admin);
    }

    /**
     * @notice Set operator
     * @dev callable by Owner of the contract
     * @param _operator: new operator address
     */
    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Cannot be zero address");
        operator = _operator;

        emit NewOperator(_operator);
    }
    
    /**
    * @notice Add funds
    */
    receive() external payable {
    }

    /**
    * @notice Set Claimabble Treasury Percent
    * @dev callable by Admin
    * @param _claimableTreasuryPercent: claimable percent
    */
    function setClaimableTreasuryPercent(uint256 _claimableTreasuryPercent)  external onlyAdmin {
        require(_claimableTreasuryPercent > 0, "Amount cannot be zero or less");
        claimableTreasuryPercent = _claimableTreasuryPercent;

        emit NewClaimableTreasuryPercent(claimableTreasuryPercent);
    }

    /**
     * @notice Claim 80% of treasury fund - collected as fee
     * @dev Callable by admin
     */
    function claimTreasury() external nonReentrant onlyAdmin notContract {
        uint256 claimableTreasuryAmount = ((treasuryAmount * claimableTreasuryPercent) / 100);
        treasuryAmount -= claimableTreasuryAmount;
        (bool success, ) = admin.call{value: claimableTreasuryAmount}("");
        require(success, "TransferHelper: TRANSFER_FAILED");

        emit TreasuryClaim(admin, claimableTreasuryAmount);
    }

    /**
    * @notice get admin address
    * @return admin address
    */
    function getAdmin() public view returns(address) {
        return admin;
    }
}

pragma solidity ^0.8.7;

/**
 * @title BetBeePrediction
 */
contract BetBeePrediction is PredictionAdministrator, PriceManager {

    uint256 public currentRoundId;
    uint256 public roundTime = 300; //5 mintues of round
    uint256 public genesisStartTimestamp;
    //string public assetPair;

    bool public genesisStartOnce = false;
    bool public genesisCreateOnce = false;

    enum RoundState {UNKNOWN, CREATED, STARTED, ENDED, DISPERSED}

    struct Round 
    {
        uint256 roundId;
        RoundState roundState;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 totalAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        int256 startPrice;
        int256 endPrice;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    struct BetInfo {
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 amountDispersed;
    }

    mapping(uint256 => Round) rounds;
    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(address => uint256[]) public userRounds;
    mapping(uint256 => address[]) public usersInRounds;

    event Paused(uint256 currentRoundId);
    event UnPaused(uint256 currentRoundId);

    event CreateRound(uint256 indexed roundId);
    event StartRound(uint256 indexed roundId);
    event EndRound(uint256 indexed roundId);
    event DisperseUser(uint256 indexed roundId, address indexed recipient, uint256 amountDispersed, uint256 timestamp);
    event Disperse(uint256 indexed roundId);
    event BetBull(address indexed sender, uint256 indexed roundId, uint256 amount);
    event BetBear(address indexed sender, uint256 indexed roundId, uint256 amount);
    event RewardsCalculated(uint256 indexed roundId, uint256 rewardBaseCalAmount, uint256 rewardAmount, uint256 treasuryAmount);
    event Refund(uint256 indexed roundId, address indexed recipient, uint256 refundDispersed, uint256 timestamp);

    /**
     * @notice Constructor
     * @param _adminAddress: admin address
     * @param _minBetAmount: minimum bet amounts (in wei)
     * @param _treasuryFee: treasury fee 3 (3%)
     * @param _assetPair: asset pair
     */
    constructor(address _adminAddress, uint256 _minBetAmount, uint256 _treasuryFee, address _oracleAddress, string memory _assetPair) 
    PredictionAdministrator(_adminAddress, _minBetAmount, _treasuryFee) 
    PriceManager(_oracleAddress, _assetPair) {
    }

    /**
     * @notice Pause the contract
     * @dev Callable by admin
     */
    function pause() external whenNotPaused onlyAdmin {
        _pause();

        emit Paused(currentRoundId);
    }

    /**
     * @notice Unpuase the contract
     * @dev Callable by admin
     */
    function unPause() external whenPaused onlyAdmin {
        genesisCreateOnce = false;
        genesisStartOnce = false;
        _unpause();

        emit Paused(currentRoundId);
    }

    /**
    * @notice Create Round
    * @param roundId: round Id 
    */
    function _createRound(uint256 roundId) internal {
        require(rounds[roundId].roundId == 0, "Round already exists");
        Round storage round = rounds[roundId];
        round.roundId = roundId;
        round.startTimestamp = (genesisStartTimestamp + (roundTime * roundId));
        round.endTimestamp = round.startTimestamp + roundTime;
        round.roundState = RoundState.CREATED;

        emit CreateRound(roundId);
    }

    /**
    * @notice Start Round
    * @param roundId: round Id 
    */
   function _startRound(uint256 roundId, int256 price) internal {
       require(rounds[roundId].roundState == RoundState.CREATED, "Round should be created");
       require(rounds[roundId].startTimestamp >= block.timestamp, "Too late to start the round");
       Round storage round = rounds[roundId];
       round.startPrice = price;
       round.roundState = RoundState.STARTED;

       emit StartRound(roundId);
    }

    /**
    * @notice End Round
    * @param roundId: round Id 
    */
    function _endRound(uint256 roundId, int256 price) internal {
        require(rounds[roundId].roundState == RoundState.STARTED, "Round is not started or ended already");
        require(rounds[roundId].endTimestamp <= block.timestamp, "Too early to end the round");
        Round storage round = rounds[roundId];
        round.endPrice = price;
        round.roundState = RoundState.ENDED;

        emit EndRound(roundId);
    }

    /**
    * @notice Calculate Rewards for the round
    * @param roundId: round Id 
    */
    function _calculateRewards(uint256 roundId) internal {
        require(rounds[roundId].roundState == RoundState.ENDED, "Round is not ended or already dispersed");
        Round storage round = rounds[roundId];
        uint256 rewardBaseCalAmount;
        uint256 treasuryAmt;
        uint256 rewardAmount;

        treasuryAmt = (round.totalAmount * treasuryFee) / 100;

        // Bull wins
        if (round.endPrice > round.startPrice) {
            rewardBaseCalAmount = round.bullAmount;
            rewardAmount = round.totalAmount - treasuryAmt;
            treasuryAmount += treasuryAmt;
        }
        // Bear wins
        else if (round.endPrice < round.startPrice) {
            rewardBaseCalAmount = round.bearAmount;
            rewardAmount = round.totalAmount - treasuryAmt;
            treasuryAmount += treasuryAmt;
        }
        // draw or tie
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            treasuryAmount += treasuryAmt;
        }
        
        round.rewardAmount = rewardAmount;
        round.rewardBaseCalAmount = rewardBaseCalAmount;

        emit RewardsCalculated(roundId, rewardBaseCalAmount, rewardAmount, treasuryAmount);
    }

    /**
    * @notice Transfer 
    * @param to: recipient address
    * @param value: value 
    */
    function _safeTransfer(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: TRANSFER_FAILED");
    }

    /**
    * @notice Check whether the round is refundable
    * @param roundId: round Id 
    */
    function _refundable(uint256 roundId) internal view returns(bool) {
        return rounds[roundId].rewardBaseCalAmount == 0 &&
               rounds[roundId].rewardAmount == 0 &&
               rounds[roundId].startPrice == rounds[roundId].endPrice;
    }

    /**
    * @notice Disperse Rewards for the round
    * @param roundId: round Id 
    */
    function _disperse(uint256 roundId) internal whenNotPaused {
        require(rounds[roundId].roundState == RoundState.ENDED, "Round is not ended or already dispersed");
        require(rounds[roundId].totalAmount > 0, "No bets in the round");
        
        //calculate rewards before disperse
        _calculateRewards(roundId);

        address[] storage usersInRound = usersInRounds[roundId];
        Round storage round = rounds[roundId];
        uint256 reward = 0;

        round.roundState = RoundState.DISPERSED;

        //bull disperse
        if(round.rewardBaseCalAmount == round.bullAmount && round.rewardBaseCalAmount > 0) {
            for (uint256 i =0; i < usersInRound.length; i++) {
                if(ledger[roundId][usersInRound[i]].bullAmount > 0) {
                    reward = (ledger[roundId][usersInRound[i]].bullAmount * round.rewardAmount) / round.rewardBaseCalAmount;
                    ledger[roundId][usersInRound[i]].amountDispersed = reward;
                    _safeTransfer(usersInRound[i], reward);

                    emit DisperseUser(roundId, usersInRound[i], reward, block.timestamp);
                }
            }
        }

        //bear disperse
        else if(round.rewardBaseCalAmount == round.bearAmount && round.rewardBaseCalAmount > 0) {
            for (uint256 i =0; i < usersInRound.length; i++) {
                if(ledger[roundId][usersInRound[i]].bearAmount > 0) {
                    reward = (ledger[roundId][usersInRound[i]].bearAmount * round.rewardAmount) / round.rewardBaseCalAmount;
                    ledger[roundId][usersInRound[i]].amountDispersed = reward;
                    _safeTransfer(usersInRound[i], reward);

                    emit DisperseUser(roundId, usersInRound[i], reward, block.timestamp);
                }
            }
        }

        //refund if tied round
        else if(_refundable(roundId)) {
            uint256 userTotalBetAmount = 0;
            uint256 userTotalRefund = 0;
            for (uint256 i =0; i < usersInRound.length; i++) {
                userTotalBetAmount = ledger[roundId][usersInRound[i]].bullAmount + ledger[roundId][usersInRound[i]].bearAmount;

                if(userTotalBetAmount > 0) {
                    userTotalRefund = userTotalBetAmount - ((userTotalBetAmount * treasuryFee) / 100);
                    ledger[roundId][usersInRound[i]].amountDispersed = userTotalRefund;
                    _safeTransfer(usersInRound[i], userTotalRefund);

                    emit Refund(roundId, usersInRound[i], userTotalRefund, block.timestamp);
                }
            }
        }

        //house wins
        else {
            treasuryAmount += round.rewardAmount;
        }

        emit Disperse(roundId);
    }

    /**
    * @notice Bet Bull position
    * @param roundId: Round Id 
    */
    function betBull(uint256 roundId) external payable whenNotPaused nonReentrant notContract {
        require(rounds[roundId].roundState == RoundState.CREATED, "Bet is too early/late");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");

        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[roundId];
        BetInfo storage betInfo = ledger[roundId][msg.sender];

        round.totalAmount = round.totalAmount + amount;
        round.bullAmount = round.bullAmount + amount;

        // Update user data
        if(ledger[roundId][msg.sender].bullAmount == 0 && ledger[roundId][msg.sender].bearAmount == 0) {
            userRounds[msg.sender].push(roundId);
            usersInRounds[roundId].push(msg.sender);
        }

        betInfo.bullAmount = betInfo.bullAmount + amount;

        emit BetBull(msg.sender, roundId, msg.value);
    }

    /**
    * @notice Bet Bear position
    * @param roundId: Round Id 
    */
    function betBear(uint256 roundId) external payable whenNotPaused nonReentrant notContract {
        require(rounds[roundId].roundState == RoundState.CREATED, "Bet is too early/late");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");

        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[roundId];
        round.totalAmount = round.totalAmount + amount;
        round.bearAmount = round.bearAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[roundId][msg.sender];
        if(ledger[roundId][msg.sender].bullAmount == 0 && ledger[roundId][msg.sender].bearAmount == 0) {
            userRounds[msg.sender].push(roundId);
            usersInRounds[roundId].push(msg.sender);
        }

        betInfo.bearAmount = betInfo.bearAmount + amount;

        emit BetBear(msg.sender, roundId, msg.value);
    }

    /**
    * @notice Create Genesis round
    * @dev callable by Operator
    * @param _genesisStartTimestamp: genesis round start timestamp
    */
    function genesisCreateRound(uint256 _genesisStartTimestamp) external whenNotPaused onlyOperator notContract {
        require(!genesisCreateOnce, "Can only run genesisCreateRound once");
        currentRoundId = 0;
        genesisStartTimestamp = _genesisStartTimestamp;
        _createRound(currentRoundId);
        genesisCreateOnce = true;
    }

    /**
    * @notice Start Genesis round
    * @dev callable by Operator
    */
    function genesisStartRound() external whenNotPaused onlyOperator notContract {
        require(genesisCreateOnce, "Can only run after genesisCreateRound is triggered");
        require(!genesisStartOnce, "Can only run genesisStartRound once");
        (,int256 price) = _getLatestPrice();
        _startRound(currentRoundId, price);

        //create next 3 rounds to be able to bet by users
        _createRound(currentRoundId+1);
        _createRound(currentRoundId+2);
        _createRound(currentRoundId+3);

        genesisStartOnce = true;
    }

    /**
    * @notice Execute round
    * @dev Callable by Operator
    */
    function executeRound() external whenNotPaused onlyOperator notContract {
        require(genesisCreateOnce && genesisStartOnce, "Can only run after genesisStartRound and genesisLockRound is triggered");

        // currentRoundId refers to current round n
        //get price
        (uint256 currentOracleRoundId,int256 price) = _getLatestPrice();

        oracleLatestRoundId = uint256(currentOracleRoundId);

        // Start next round
        _startRound(currentRoundId+1, price);
        
        // End and Disperse current round
        _endRound(currentRoundId, price);
        _disperse(currentRoundId);

        // Create a new round n+4
        _createRound(currentRoundId+4);

        // Point currentRoundId to next round
        currentRoundId = currentRoundId + 1;
    }
}