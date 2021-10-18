/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity ^0.8.0;

/**
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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity ^0.8.0;

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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


// Dependency file: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: @openzeppelin/contracts/security/ReentrancyGuard.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/security/Pausable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/utils/Strings.sol


// pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// Dependency file: contracts/TestLotoLoto.sol


// pragma solidity 0.8.4;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

/// @notice TestLoto Loto
contract TestLotoLoto is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public storageAddress;
    address public teamAddress;

    uint256 internal constant MIN_BET = 0.01 ether;
    uint256 internal constant MAX_BET = 0.5 ether;
    uint256 internal constant PRECISION = 1 ether;

    uint256 internal constant TEAM_PERCENT = 10;
    uint256 internal constant JACKPOT_PERCENT = 40;
    uint256 internal constant STORAGE_PERCENT = 50;

    uint256 internal constant WIN_MATCHES = 6;
    uint256 internal constant PROMO_MATCHES = 5;

    struct BetLimits {
        uint256 min;
        uint256 max;
    }

    uint256 public jackpotAmount;

    uint256 public promoPeriod = 86400; //24 hour
    uint256 public lastPromoTime;

    BetLimits public betLimits;

    event Received(address sender, uint256 value);
    event PayoutBet(bytes16 id, uint256 amount, address gamer);
    event ProcessBet(bytes16 id, address gamer, uint256 amount, uint256 reward, bytes6 bet, bytes hash);
    event SetBetLimits(uint256 _min, uint256 _max);

    event WithdrawToken(address token, address recipient, uint256 amount);
    event Withdraw(address recipient, uint256 amount);
    event ActivatedPromo(uint256 lastPromoTime);
    event UpdateStorageAddress(address storageAddress);
    event UpdateTeamAddress(address teamAddress);
    event UpdatePromoPeriod(uint256 promoPeriod);

    struct Bet {
        uint256 blockNumber;
        uint256 amount;
        uint256 reward;
        bytes6 bet;
        bytes hash;
    }

    mapping(address => mapping(bytes16 => Bet)) public bets;
    mapping(bytes16 => bool) public tickets;

    constructor(address _storage, address _team) {
        require(_storage != address(0x0) && _team != address(0x0), "TestLoto Loto: address is zero");

        storageAddress = _storage;
        teamAddress = _team;

        betLimits.min = MIN_BET;
        betLimits.max = MAX_BET;
    }

    /// Receive BNB
    receive() external payable {
        jackpotAmount += msg.value;
        emit Received(msg.sender, msg.value);
    }

    ///@notice place bet
    ///@param _params, 16 bytes of id, and 6 bytes for places [0...9, A...F]
    function placeBet(bytes22 _params) external payable virtual nonReentrant whenNotPaused {
        require(!msg.sender.isContract(), "TestLoto Loto: sender cannot be a contract");
        require(tx.origin == msg.sender, "TestLoto Loto: msg sender is not original user");
        require(
            msg.value >= betLimits.min && msg.value <= betLimits.max,
            string(
                abi.encodePacked(
                    "TestLoto Loto: Bet amount should be greater or equal than ",
                    Strings.toString(betLimits.min),
                    " and less or equal than ",
                    Strings.toString(betLimits.max),
                    " WEI"
                )
            )
        );
        require(bytes16(_params) != 0, "TestLoto Loto: Id should not be 0");

        bytes16 id = bytes16(_params);

        require(!tickets[id], "TestLoto Loto: this ticket already exists");

        bytes6 bet = bytes6(_params << 128);

        _beforeProcessBet(msg.value);

        bytes memory b = new bytes(6);

        Bet memory betStruct = Bet(block.number - 1, msg.value, 0, bet, b);

        bets[msg.sender][id] = betStruct;
        tickets[id] = true;

        //process bet
        _processBet(msg.sender, id);
    }

    function setBetLimits(uint256 _min, uint256 _max) external onlyOwner {
        betLimits.min = _min;
        betLimits.max = _max;

        emit SetBetLimits(_min, _max);
    }

    ///@notice activate promo period, when win matches == 5 mathes in order
    function activatePromoPeriod() external onlyOwner whenNotPaused {
        lastPromoTime = block.timestamp + promoPeriod;

        emit ActivatedPromo(lastPromoTime);
    }

    ///@notice update promo period, default 24 hours
    ///@param _promoPeriod promo period in seconds
    function updatePromoPeriod(uint256 _promoPeriod) external onlyOwner {
        promoPeriod = _promoPeriod;

        emit UpdatePromoPeriod(promoPeriod);
    }

    ///@notice update address of storage contract
    ///@param _storageAddress storage contract address
    function updateStorageAddress(address _storageAddress) external onlyOwner {
        storageAddress = _storageAddress;

        emit UpdateStorageAddress(storageAddress);
    }

    ///@notice update team address
    ///@param _teamAddress team address
    function updateTeamAddress(address _teamAddress) external onlyOwner {
        teamAddress = _teamAddress;

        emit UpdateTeamAddress(teamAddress);
    }

    /// @notice management function. Withdraw all tokens in emergency mode only when contract paused
    function withdrawToken(address _token, address _recipient) public virtual onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));

        _withdrawToken(_token, _recipient, amount);
        _afterWithdrawToken(_token, _recipient, amount);
    }

    /// @notice management function. Withdraw  some tokens in emergency mode only when contract paused
    function withdrawSomeToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) public virtual onlyOwner {
        _withdrawToken(_token, _recipient, _amount);
        _afterWithdrawToken(_token, _recipient, _amount);
    }

    ///@notice withdraw all BNB. Withdraw in emergency mode only when contract paused
    function withdraw() public virtual onlyOwner whenPaused {
        _withdraw(msg.sender, address(this).balance);
    }

    ///@notice withdraw some BNB. Withdraw in emergency mode only when contract paused
    function withdrawSome(address _recipient, uint256 _amount) public virtual onlyOwner whenPaused {
        _withdraw(_recipient, _amount);
    }

    /// @notice pause contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause contract
    function unpause() external onlyOwner {
        _unpause();
    }

    function isActivePromo() external view returns (bool) {
        return block.timestamp <= lastPromoTime ? true : false;
    }

    function _beforeProcessBet(uint256 _amount) internal virtual {
        uint256 jackpotFee = (_amount * JACKPOT_PERCENT * PRECISION) / 100 / PRECISION;
        uint256 storageFee = (_amount * STORAGE_PERCENT * PRECISION) / 100 / PRECISION;
        uint256 teamFee = (_amount * TEAM_PERCENT * PRECISION) / 100 / PRECISION;

        // increase jackpot
        jackpotAmount += jackpotFee;

        _deliverFunds(storageAddress, storageFee, "TestLoto Loto: failed transfer BNB to Staking Storage");

        _deliverFunds(teamAddress, teamFee, "TestLoto Loto: failed transfer BNB to Team");
    }

    function _processBet(address _gamer, bytes16 _id) internal virtual {
        Bet storage bet = bets[_gamer][_id];

        bytes32 blockHash = _getBlockHash();

        bytes1 field;
        bytes memory b = new bytes(6);
        uint8 matchesCount;
        uint8 startHash = blockHash.length - bet.bet.length;

        for (uint8 j = 0; j < _winMatches(); j++) {
            //get symbol from blockchash

            field = blockHash[startHash + j] >> 4;

            //correct position
            if (bet.bet[j] < 0x10) {
                if (field == bet.bet[j]) {
                    matchesCount++;
                }
            }

            b[j] = field;
        }

        bet.hash = b;

        //more than winMatches, default 6
        if (matchesCount >= _winMatches()) {
            uint256 prize = (jackpotAmount * bet.amount) / PRECISION;

            if (prize > address(this).balance) {
                prize = address(this).balance;
            }

            jackpotAmount -= prize;

            bet.reward = prize;

            //sent to gamer prize
            _deliverFunds(_gamer, prize, "TestLoto Loto: failed transfer BNB to Gamer");

            emit PayoutBet(_id, prize, _gamer);
        }

        emit ProcessBet(_id, _gamer, bet.amount, bet.reward, bet.bet, bet.hash);
    }

    function _getBlockHash() internal view virtual returns (bytes32 _hash) {
        return keccak256(abi.encode(blockhash(block.number - 1), block.timestamp, msg.data));
    }

    function _winMatches() internal view returns (uint256 _matches) {
        if (block.timestamp <= lastPromoTime) {
            _matches = PROMO_MATCHES;
        } else {
            _matches = WIN_MATCHES;
        }
    }

    function _deliverFunds(
        address _recipient,
        uint256 _value,
        string memory _message
    ) internal {
        (bool sent, ) = payable(_recipient).call{value: _value}("");

        if (!sent) {
            require(sent, _message);
        }
    }

    function _withdraw(address _recipient, uint256 _amount) internal virtual {
        require(_recipient != address(0x0), "TestLoto Loto: address is zero");
        require(_amount <= address(this).balance, "TestLoto Loto: not enought BNB balance");

        if (_amount > jackpotAmount) {
            jackpotAmount = 0;
        } else {
            jackpotAmount -= _amount;
        }

        _deliverFunds(_recipient, _amount, "TestLoto Loto: Can't send BNB");
        emit Withdraw(_recipient, _amount);
    }

    function _withdrawToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal virtual {
        require(_recipient != address(0x0), "TestLoto Loto: address is zero");
        require(_amount <= IERC20(_token).balanceOf(address(this)), "TestLoto Loto: not enought token balance");

        IERC20(_token).safeTransfer(_recipient, _amount);
    }

    function _afterWithdrawToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal virtual {}
}


// Root file: contracts/v2/TestLotoLotoV2.sol


pragma solidity 0.8.4;

// import "contracts/TestLotoLoto.sol";

/// @notice TestLoto Loto with support partnership tokens

contract TestLotoLotoV2 is TestLotoLoto {
    using SafeERC20 for IERC20;
    using Address for address;

    mapping(address => bool) public partnershipTokens;
    mapping(address => uint256) public partnershipJackpots;
    mapping(address => BetLimits) public betLimitsWithToken;

    event AddPartnershipToken(address token, bool isActive, uint256 _min, uint256 _max);
    event SetPartnershipJackpot(address token, uint256 jackpot);
    event SetBetLimitsWithToken(address _token, uint256 _min, uint256 _max);
    event PayoutBetWithToken(address token, bytes16 id, uint256 amount, address gamer);
    event ProcessBetWithToken(address token, bytes16 id, address gamer, uint256 amount, uint256 reward, bytes6 bet, bytes hash);

    constructor(address _storage, address _team) TestLotoLoto(_storage, _team) {}

    function addPartnershipToken(
        address _token,
        bool _isActive,
        uint256 _min,
        uint256 _max
    ) external onlyOwner {
        partnershipTokens[_token] = _isActive;

        betLimitsWithToken[_token].min = _min;
        betLimitsWithToken[_token].max = _max;

        emit AddPartnershipToken(_token, _isActive, _min, _max);
    }

    function setPartnershipJackpot(address _token, uint256 _jackpot) external onlyOwner {
        require(partnershipTokens[_token], "TestLoto Loto: token is not active");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _jackpot);

        partnershipJackpots[_token] += _jackpot;

        emit SetPartnershipJackpot(_token, _jackpot);
    }

    function setBetLimitsWithToken(
        address _token,
        uint256 _min,
        uint256 _max
    ) external onlyOwner {
        require(partnershipTokens[_token], "TestLoto Loto: token is not active");

        betLimitsWithToken[_token].min = _min;
        betLimitsWithToken[_token].max = _max;

        emit SetBetLimitsWithToken(_token, _min, _max);
    }

    function placeBetWithToken(
        address _token,
        uint256 _amount,
        bytes22 _params
    ) external virtual nonReentrant whenNotPaused {
        require(partnershipTokens[_token], "TestLoto Loto: token is not active");
        require(!msg.sender.isContract(), "TestLoto Loto: sender cannot be a contract");
        require(tx.origin == msg.sender, "TestLoto Loto: msg sender is not original user");
        require(
            _amount >= betLimitsWithToken[_token].min && _amount <= betLimitsWithToken[_token].max,
            string(
                abi.encodePacked(
                    "TestLoto Loto: Bet amount should be greater or equal than ",
                    Strings.toString(betLimits.min),
                    " and less or equal than ",
                    Strings.toString(betLimits.max),
                    " WEI"
                )
            )
        );

        require(bytes16(_params) != 0, "TestLoto Loto: Id should not be 0");

        bytes16 id = bytes16(_params);

        require(!tickets[id], "TestLoto Loto: this ticket already exists");

        bytes6 bet = bytes6(_params << 128);

        _beforeProcessBetWithToken(_token, _amount);

        bytes memory b = new bytes(6);

        Bet memory betStruct = Bet(block.number - 1, _amount, 0, bet, b);

        bets[msg.sender][id] = betStruct;
        tickets[id] = true;

        //process bet
        _processBetWithToken(_token, msg.sender, id);
    }

    function _beforeProcessBetWithToken(address _token, uint256 _amount) internal {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 jackpotFee = (_amount * JACKPOT_PERCENT * PRECISION) / 100 / PRECISION;
        uint256 storageFee = (_amount * STORAGE_PERCENT * PRECISION) / 100 / PRECISION;
        uint256 teamFee = (_amount * TEAM_PERCENT * PRECISION) / 100 / PRECISION;

        // increase jackpot
        partnershipJackpots[_token] += jackpotFee;

        _deliverTokens(_token, storageAddress, storageFee);

        _deliverTokens(_token, teamAddress, teamFee);
    }

    function _processBetWithToken(
        address _token,
        address _gamer,
        bytes16 _id
    ) internal virtual {
        Bet storage bet = bets[_gamer][_id];

        bytes32 blockHash = _getBlockHash();

        bytes1 field;
        bytes memory b = new bytes(6);
        uint8 matchesCount;
        uint8 startHash = blockHash.length - bet.bet.length;

        for (uint8 j = 0; j < _winMatches(); j++) {
            //get symbol from blockchash

            field = blockHash[startHash + j] >> 4;

            //correct position
            if (bet.bet[j] < 0x10) {
                if (field == bet.bet[j]) {
                    matchesCount++;
                }
            }

            b[j] = field;
        }

        bet.hash = b;

        //more than winMatches, default 6
        if (matchesCount >= _winMatches()) {
            uint256 prize = (partnershipJackpots[_token] * bet.amount) / PRECISION;

            if (prize > IERC20(_token).balanceOf(address(this))) {
                prize = IERC20(_token).balanceOf(address(this));
            }

            partnershipJackpots[_token] -= prize;

            bet.reward = prize;

            //sent to gamer prize
            _deliverTokens(_token, _gamer, prize);

            emit PayoutBetWithToken(_token, _id, prize, _gamer);
        }

        emit ProcessBetWithToken(_token, _id, _gamer, bet.amount, bet.reward, bet.bet, bet.hash);
    }

    function withdrawSomeToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) public override onlyOwner {
        super.withdrawSomeToken(_token, _recipient, _amount);
    }

    function _afterWithdrawToken(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal override {
        if (_amount > partnershipJackpots[_token]) {
            partnershipJackpots[_token] = 0;
        } else {
            partnershipJackpots[_token] -= _amount;
        }
    }

    function _deliverTokens(
        address _token,
        address _recipient,
        uint256 _value
    ) internal {
        IERC20(_token).safeTransfer(_recipient, _value);
    }
}