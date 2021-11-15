// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor () {
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
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

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Base implementation of the Bridge Agent
 *
 * Chain-specific Bridge Agents are meant to extend from this class
 * and also implement deposit() and claim() functions.
 *
 * Besides maximizing code reuse, bridge agents from different chains also
 * implement the same interface. The Bridge Backend uses the ABI of this class
 * to read agent data from blockchain, without relying on chain-specific
 * implementation details of agents.
 */
abstract contract AbstractBridgeAgent is Ownable, Pausable {
	using SafeERC20 for IERC20;
	using ECDSA for bytes32;

	// Each new release of bridge agent would have a new version
	uint8 public constant VERSION = 1;

	// Public key of signer that is used to sign bridge operations
	address public bridgeSigner;
	// Wallet where the bridge fee will be transferred
	address payable public treasurer;

	// Map that holds current token registrations, tokenSigners[token] = signer
	mapping(address => address) public tokenSigners;
	// Stores the list of paused tokens
	mapping(address => bool) public tokenPaused;
	// Remembers used signatures to avoid reuse and re-entry
	mapping(bytes32 => bool) internal signatureUsed;

	// Emitted when bridge signer is changed
	event SetBridgeSigner(
		address indexed previousBridgeSigner,
		address indexed newBridgeSigner
	);

	// Emitted when treasurer is changed
	event SetTreasurer(
		address payable indexed previousTreasurer,
		address payable indexed newTreasurer
	);

	// Emitted when a new token is registered or existing registration is updated
	event Register(
		address indexed token,
		address indexed baseToken,
		address indexed signer
	);

	// Emitted when amount of registered token is deposited
	event Deposit(
		uint256 toChain,
		address indexed token,
		address indexed fromWallet,
		address indexed toWallet,
		uint256 amount,
		uint256 fee
	);

	// Emitted when amount of registered token is claimed
	event Claim(
		bytes32 indexed depositTx,
		address indexed token,
		address indexed toWallet,
		uint256 amount
	);

	// Emitted when a token is migrated to a new agent contract version
	event Migrate(
		address indexed token,
		address indexed newAgent,
		uint256 balance
	);

	// Emitted when token is paused for this agent
	event TokenPaused(address indexed token, address indexed account);

	// Emitted when token is unpaused for this agent
	event TokenUnpaused(address indexed token, address indexed account);

	/**
	 * @dev Initializes the agent
	 * @param _bridgeSigner Public key of signer that is used to sign bridge operations
	 * @param _treasurer Wallet where the bridge fee will be transferred
	 */
	constructor(address _bridgeSigner, address payable _treasurer) Ownable() {
		setBridgeSigner(_bridgeSigner);
		setTreasurer(_treasurer);
	}

	/**
	 * @notice Pauses the whole agent
	 * All user-facing operations are not be possible while the agent is paused.
	 *
	 * Emits {Paused()}
	 *
	 * Requirements:
	 * - The agent should not be paused
	 * - Can only be called by the brigde agent owner
	 */
	function pause() external onlyOwner {
		_pause();
	}

	/**
	 * @notice Unpauses the agent
	 *
	 * Emits {Unpaused()}
	 *
	 * Requirements:
	 * - The agent should be paused
	 * - Can only be called by the brigde agent owner
	 */
	function unpause() external onlyOwner {
		_unpause();
	}

	/**
	 * @notice Pauses a token
	 *
	 * @param token token to be paused
	 *
	 * Emits {TokenPaused()}
	 *
	 * No user-facing operations are available on a token when it's paused.
	 * The token also gets paused when it's being migrated to a newer version
	 * agent contract, see migrate().
	 *
	 * Requirements:
	 * - A token should not be currently paused
	 * - A token _doesn't_ have to be registered to be paused
	 * - Can only be called by the brigde agent owner
	 */
	function pauseToken(address token) external onlyOwner {
		_pauseToken(token);
	}

	/**
	 * @notice Unpauses a token
	 *
	 * @param token token to be unpaused
	 *
	 * Emits {TokenUnpaused()}
	 *
	 * Requirements:
	 * - A token should be paused
	 * - Can only be called by the brigde agent owner
	 */
	function unpauseToken(address token) external onlyOwner {
		_unpauseToken(token);
	}

	/**
	 * @dev Pauses a token – internal calls only
	 */
	function _pauseToken(address token) internal {
		require(!tokenPaused[token], "token is already paused");
		tokenPaused[token] = true;
		emit TokenPaused(token, msg.sender);
	}

	/**
	 * @dev Unpauses a token – internal calls only
	 */
	function _unpauseToken(address token) internal {
		require(tokenPaused[token], "token is not paused");
		tokenPaused[token] = false;
		emit TokenUnpaused(token, msg.sender);
	}

	/**
	 * @notice Sets a new bridge signer
	 *
	 * @param newBrigdeSigner Public key of signer that is used to sign bridge operations
	 *
	 * Emits {SetBridgeSigner()}
	 *
	 * Requirements:
	 * - Can only be called by the brigde agent owner
	 */
	function setBridgeSigner(address newBrigdeSigner) public onlyOwner {
		require(newBrigdeSigner != address(0), "empty bridge signer");
		emit SetBridgeSigner(bridgeSigner, newBrigdeSigner);
		bridgeSigner = newBrigdeSigner;
	}

	/**
	 * @notice Sets a new bridge treasurer
	 *
	 * @param newTreasurer Wallet where the bridge fee will be transferred
	 *
	 * Emits {SetTreasurer()}
	 *
	 * Requirements:
	 * - Can only be called by the brigde agent owner
	 */
	function setTreasurer(address payable newTreasurer) public onlyOwner {
		require(newTreasurer != address(0), "empty treasurer");
		emit SetTreasurer(treasurer, newTreasurer);
		treasurer = newTreasurer;
	}

	/**
	 * @dev Used to prevent signature reuse, re-entry, and check it's not expired
	 *
	 * @param sig signature
	 * @param sigExpire timestamp in milliseconds
	 *
	 * This modifier reverts if a signature is reused or expired
	 */
	modifier useSignature(bytes memory sig, uint256 sigExpire) {
		bytes32 sigHash = keccak256(sig);

		require(!signatureUsed[sigHash], "reused signature");
		signatureUsed[sigHash] = true;

		if (sigExpire > 0) {
			// sigExpire is in millis
			require(sigExpire > block.timestamp * 1000, "expired signature");
		}

		_;
	}

	/**
	 * @notice Registers a token in this agent.
	 *
	 * @param token address of a token to be registered
	 * @param baseToken address of a token in the main chain
	 * @param signer public key of a signer owned by token owner to sign token operations
	 * @param bridgeSig signature issued by the Bridge Service
	 * @param sigExpire nonce/expiration issued by the Bridge Service
	 *
	 * Emits {Register()}
	 *
	 * Prior to cross-chain transfer opertaions been made, a token needs to be
	 * registered in the agent, presumably by its owner. It cannot be called directly
	 * by anyone though. The Bridge Service validates token ownership and issues
	 * a signature {bridgeSig} that allows registration.
	 *
	 * This function can also be used to "re-register" a token that is already
	 * registered. This can be needed in two cases:
	 * 1. To set a new {signer} for a token.
	 * 2. To unregister a token. For this, pass address(0) as a {signer}.
	 *
	 * This function is payable(), receiving service fee in the form of ether.
	 * The actual fee value is obtained from the Bridge Service along with {bridgeSig}
	 * and {sigExpire}.
	 *
	 * NOTE: In the main chain (ETH) the {baseToken} parameter should have the
	 * same value as {token}. This parameter is needed for sub-chains like BSC
	 * so that the Bridge Service can index Register events and make proper routing
	 * for the users.
	 *
	 * Requirements:
	 * - Agent must not be paused.
	 * - {token} must not be paused.
	 * - {token} and {baseToken} cannot be empty addresses.
	 * - {bridgeSig} cannot be reused and {sigExpire} must be after the current block time.
	 */
	function register(
		address token,
		address baseToken,
		address signer,
		bytes memory bridgeSig,
		uint256 sigExpire
	) external payable useSignature(bridgeSig, sigExpire) whenNotPaused {
		require(token != address(0), "token is empty");
		require(baseToken != address(0), "baseToken is empty");
		require(!tokenPaused[token], "token is paused");

		// Check signature
		{
			bytes32 messageHash = keccak256(
				abi.encode(
					address(this),
					_msgSender(),
					token,
					baseToken,
					signer,
					msg.value,
					sigExpire
				)
			);
			bytes32 ethHash = messageHash.toEthSignedMessageHash();
			require(
				ethHash.recover(bridgeSig) == bridgeSigner,
				"invalid bridge signature"
			);
		}

		tokenSigners[token] = signer;

		// User pays fee to the bridge
		if (msg.value > 0) {
			treasurer.transfer(msg.value);
		}

		emit Register(token, baseToken, signer);
	}

	/**
	 * @notice Migrates a token to another agent contract
	 *
	 * @param token registered token to be migrated
	 * @param newAgent address of a new agent to transfer balance to
	 * @param tokenSig signature issued by a token owner
	 * @param bridgeSig signature issued by the Bridge Service
	 * @param sigExpire nonce/expiration issued by the Bridge Service
	 *
	 * Emits {Migrate()}
	 *
	 * This function is mostly needed when a new agent contract version is released.
	 * The token owner is responsible to call this function before registering a
	 * token {register()} on a new agent.
	 *
	 * Any token balance holded by this agent will be transferred to {newAgent}.
	 * Note that there is balance only in the ETH chain – in other subchains the balance
	 * is holded by the represented {SubchainToken}.
	 *
	 * Requirements:
	 * - Agent must not be paused.
	 * - {token} must be registered in this agent.
	 * - {token} must not be paused.
	 * - {tokenSig} and {bridgeSig} cannot be reused.
	 * - {sigExpire} must be after the current block time.
	 */
	function migrate(
		address token,
		address newAgent,
		bytes memory tokenSig,
		bytes memory bridgeSig,
		uint256 sigExpire
	)
		external
		useSignature(tokenSig, sigExpire)
		useSignature(bridgeSig, sigExpire)
		whenNotPaused
	{
		require(!tokenPaused[token], "token is paused");
		require(tokenSigners[token] != address(0), "token not registered");

		// check signature
		{
			bytes32 messageHash = keccak256(
				abi.encode(address(this), token, newAgent, sigExpire)
			);
			bytes32 ethHash = messageHash.toEthSignedMessageHash();
			require(
				ethHash.recover(tokenSig) == tokenSigners[token],
				"invalid token signature"
			);
			require(
				ethHash.recover(bridgeSig) == bridgeSigner,
				"invalid bridge signature"
			);
		}

		_pauseToken(token);

		// Transfer all the withhold balance of token to the new agent
		uint256 amount = IERC20(token).balanceOf(address(this));
		if (amount > 0) {
			IERC20(token).safeTransfer(newAgent, amount);
		}

		emit Migrate(token, newAgent, amount);
	}

	/**
	 * @dev Deposit a given amount to be claimed in another chain
	 *
	 * @param toChain chain ID in which the token amount will be claimed
	 * @param token address of a registered token to be deposited
	 * @param toWallet caller address that will claim the token from the {toChain}
	 * @param amount wei amount of token to be deposited/claimed
	 * @param bridgeSig signature issued by the Bridge Service
	 * @param sigExpire nonce/expiration issued by the Bridge Service
	 *
	 * See chain-specific implementation for more documentation.
	 */
	function deposit(
		uint256 toChain,
		address token,
		address toWallet,
		uint256 amount,
		bytes memory bridgeSig,
		uint256 sigExpire
	) external payable virtual;

	/**
	 * @dev Transfers a given amount of token from agent to a user
	 *
	 * @param depositTx deposit transaction hash from another chain
	 * @param token address of the local token to be claimed
	 * @param amount wei amount of token to be claimed
	 * @param tokenSig signature of the Token Owner (obtained via Bridge Service)
	 * @param bridgeSig signature of the Bridge Service
	 *
	 * See chain-specific implementation for more documentation.
	 */
	function claim(
		bytes32 depositTx,
		address token,
		uint256 amount,
		bytes memory tokenSig,
		bytes memory bridgeSig
	) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./AbstractBridgeAgent.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title ETH implementation of the bridge agent
 *
 * The implementation of this agent is as follows:
 * 1. Token Owner registers a token with this agent (register())
 * 2. Token User deposits a token amount X to the agent contract (deposit())
 * 3. [off chain] Token User claims a token amount X in another chain
 * 4. [off chain] Token User deposits a token amount Y in another chain
 * 5. Token User claims a token amount Y and the balance is being transferred
 *    from the agent back to user (claim())
 *
 * See {AbstractBridgeAgent} documentation for some core concepts description.
 */
contract ETHBridgeAgent is AbstractBridgeAgent {
	using SafeERC20 for IERC20;
	using ECDSA for bytes32;

	/**
	 * @dev Initializes the agent
	 */
	constructor(address _bridgeSigner, address payable _treasurer)
		AbstractBridgeAgent(_bridgeSigner, _treasurer)
	// solhint-disable-next-line no-empty-blocks
	{

	}

	/**
	 * @dev Deposits a given amount of token that can be claimed in another chain.
	 *
	 * @param toChain target chain ID where the token amount will be claimed
	 * @param token address of a registered token to be deposited
	 * @param toWallet caller address that will claim the token from the {toChain}
	 * @param amount wei amount of token to be deposited/claimed
	 * @param bridgeSig signature issued by the Bridge Service
	 * @param sigExpire nonce/expiration issued by the Bridge Service
	 *
	 * This function is payable(), receiving service fee in the form of ether.
	 * The actual fee value is obtained from the Bridge Service along with {bridgeSig}
	 * and {sigExpire}.
	 *
	 * In this ETH-specific implementation, the agent transfers a given amount of
	 * token from a user to itself (agent). The amount is withhold until the user
	 * comes back from the subchain to claim it back.
	 *
	 * The Bridge Service monitors the chain and issue bridge/token signatures
	 * once the deposit transaction gets enough confirmations. The two signatures
	 * can later be obtained from the Bridge Service and used to claim the
	 * token amount in another chain.
	 *
	 * Requirements:
	 * - Agent must not be paused.
	 * - {token} must be registered in this agent.
	 * - {token} must not be paused.
	 * - {bridgeSig} cannot be reused and {sigExpire} must be after the current block time.
	 * - Caller should have enough {token} balance to afford the deposited {amount}.
	 */
	function deposit(
		uint256 toChain,
		address token,
		address toWallet,
		uint256 amount,
		bytes memory bridgeSig,
		uint256 sigExpire
	)
		external
		payable
		override
		useSignature(bridgeSig, sigExpire)
		whenNotPaused
	{
		require(!tokenPaused[token], "token is paused");
		require(tokenSigners[token] != address(0), "token not registered");

		// check signature
		bytes32 messageHash =
			keccak256(
				abi.encode(
					address(this),
					toChain,
					token,
					toWallet,
					amount,
					msg.value,
					sigExpire
				)
			);
		bytes32 ethHash = messageHash.toEthSignedMessageHash();
		require(
			ethHash.recover(bridgeSig) == bridgeSigner,
			"invalid bridge signature"
		);

		// Deposit the amount of token frmo user to the agent contract
		IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);

		// User pays fee to the bridge
		if (msg.value > 0) {
			treasurer.transfer(msg.value);
		}

		emit Deposit(toChain, token, _msgSender(), toWallet, amount, msg.value);
	}

	/**
	 * @dev Transfers a given amount of token from agent to a user
	 *
	 * @param depositTx deposit transaction hash from another chain
	 * @param token address of the local token to be claimed
	 * @param amount wei amount of token to be claimed
	 * @param tokenSig signature of the Token Owner (obtained via Bridge Service)
	 * @param bridgeSig signature of the Bridge Service
	 *
	 * Once the deposit is done in another chain and the Bridge Service has
	 * issued token/bridge signature pair, the user can claim their token
	 * in this chain, by calling this function.
	 *
	 * This ETH-specific implementation transfers the withhold amount from the
	 * agent contract back to a user.
	 *
	 * Requirements:
	 * - Agent must not be paused.
	 * - {token} must be registered in this agent.
	 * - {token} must not be paused.
	 * - Caller should be the wallet that was specified in {toWallet} during {deposit()}
	 * - Valid {tokenSig} and {bridgeSig} obtained from the Bridge Service
	 */
	function claim(
		bytes32 depositTx,
		address token,
		uint256 amount,
		bytes memory tokenSig,
		bytes memory bridgeSig
	)
		external
		override
		useSignature(tokenSig, 0)
		useSignature(bridgeSig, 0)
		whenNotPaused
	{
		require(!tokenPaused[token], "token is paused");
		require(tokenSigners[token] != address(0), "token not registered");

		// check signature
		{
			bytes32 messageHash =
				keccak256(
					abi.encode(
						address(this),
						depositTx,
						token,
						block.chainid,
						_msgSender(),
						amount
					)
				);
			bytes32 ethHash = messageHash.toEthSignedMessageHash();
			require(
				ethHash.recover(tokenSig) == tokenSigners[token],
				"invalid token signature"
			);
			require(
				ethHash.recover(bridgeSig) == bridgeSigner,
				"invalid bridge signature"
			);
		}

		// Transfer the withhold amount of token back to a user
		IERC20(token).safeTransfer(_msgSender(), amount);

		emit Claim(depositTx, token, _msgSender(), amount);
	}
}

