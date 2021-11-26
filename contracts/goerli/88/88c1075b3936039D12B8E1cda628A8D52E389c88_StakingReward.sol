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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract Pauser is Ownable, Pausable {
    mapping(address => bool) public pausers;

    event PauserAdded(address account);
    event PauserRemoved(address account);

    constructor() {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "Caller is not pauser");
        _;
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function isPauser(address account) public view returns (bool) {
        return pausers[account];
    }

    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    function removePauser(address account) public onlyOwner {
        _removePauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) private {
        require(!isPauser(account), "Account is already pauser");
        pausers[account] = true;
        emit PauserAdded(account);
    }

    function _removePauser(address account) private {
        require(isPauser(account), "Account is not pauser");
        pausers[account] = false;
        emit PauserRemoved(account);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import "./interfaces/ISigsVerifier.sol";
import "./libraries/PbStaking.sol";
import "./Whitelist.sol";
import "./Pauser.sol";

/**
 * @title A Staking contract shared by all external sidechains and apps
 */
contract Staking is ISigsVerifier, Pauser, Whitelist {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    IERC20 public immutable CELER_TOKEN;

    uint256 public bondedTokens;
    uint256 public nextBondBlock;
    address[] public valAddrs;
    address[] public bondedValAddrs;
    mapping(address => dt.Validator) public validators; // key is valAddr
    mapping(address => address) public signerVals; // signerAddr -> valAddr
    mapping(uint256 => bool) public slashNonces;

    mapping(dt.ParamName => uint256) public params;
    address public govContract;
    address public rewardContract;
    uint256 public forfeiture;

    /* Events */
    event ValidatorNotice(address indexed valAddr, string key, bytes data, address from);
    event ValidatorStatusUpdate(address indexed valAddr, dt.ValidatorStatus indexed status);
    event DelegationUpdate(
        address indexed valAddr,
        address indexed delAddr,
        uint256 valTokens,
        uint256 delShares,
        int256 tokenDiff
    );
    event Undelegated(address indexed valAddr, address indexed delAddr, uint256 amount);
    event Slash(address indexed valAddr, uint64 nonce, uint256 slashAmt);
    event SlashAmtCollected(address indexed recipient, uint256 amount);

    /**
     * @notice Staking constructor
     * @param _celerTokenAddress address of Celer Token Contract
     * @param _proposalDeposit required deposit amount for a governance proposal
     * @param _votingPeriod voting timeout for a governance proposal
     * @param _unbondingPeriod the locking time for funds locked before withdrawn
     * @param _maxBondedValidators the maximum number of bonded validators
     * @param _minValidatorTokens the global minimum token amount requirement for bonded validator
     * @param _minSelfDelegation minimal amount of self-delegated tokens
     * @param _advanceNoticePeriod the wait time after the announcement and prior to the effective date of an update
     * @param _validatorBondInterval min interval between bondValidator
     * @param _maxSlashFactor maximal slashing factor (1e6 = 100%)
     */
    constructor(
        address _celerTokenAddress,
        uint256 _proposalDeposit,
        uint256 _votingPeriod,
        uint256 _unbondingPeriod,
        uint256 _maxBondedValidators,
        uint256 _minValidatorTokens,
        uint256 _minSelfDelegation,
        uint256 _advanceNoticePeriod,
        uint256 _validatorBondInterval,
        uint256 _maxSlashFactor
    ) {
        CELER_TOKEN = IERC20(_celerTokenAddress);

        params[dt.ParamName.ProposalDeposit] = _proposalDeposit;
        params[dt.ParamName.VotingPeriod] = _votingPeriod;
        params[dt.ParamName.UnbondingPeriod] = _unbondingPeriod;
        params[dt.ParamName.MaxBondedValidators] = _maxBondedValidators;
        params[dt.ParamName.MinValidatorTokens] = _minValidatorTokens;
        params[dt.ParamName.MinSelfDelegation] = _minSelfDelegation;
        params[dt.ParamName.AdvanceNoticePeriod] = _advanceNoticePeriod;
        params[dt.ParamName.ValidatorBondInterval] = _validatorBondInterval;
        params[dt.ParamName.MaxSlashFactor] = _maxSlashFactor;
    }

    receive() external payable {}

    /*********************************
     * External and Public Functions *
     *********************************/

    /**
     * @notice Initialize a validator candidate
     * @param _signer signer address
     * @param _minSelfDelegation minimal amount of tokens staked by the validator itself
     * @param _commissionRate the self-declaimed commission rate
     */
    function initializeValidator(
        address _signer,
        uint256 _minSelfDelegation,
        uint64 _commissionRate
    ) external whenNotPaused onlyWhitelisted {
        address valAddr = msg.sender;
        dt.Validator storage validator = validators[valAddr];
        require(validator.status == dt.ValidatorStatus.Null, "Validator is initialized");
        require(validators[_signer].status == dt.ValidatorStatus.Null, "Signer is other validator");
        require(signerVals[valAddr] == address(0), "Validator is other signer");
        require(signerVals[_signer] == address(0), "Signer already used");
        require(_commissionRate <= dt.COMMISSION_RATE_BASE, "Invalid commission rate");
        require(_minSelfDelegation >= params[dt.ParamName.MinSelfDelegation], "Insufficient min self delegation");
        validator.signer = _signer;
        validator.status = dt.ValidatorStatus.Unbonded;
        validator.minSelfDelegation = _minSelfDelegation;
        validator.commissionRate = _commissionRate;
        valAddrs.push(valAddr);
        signerVals[_signer] = valAddr;

        delegate(valAddr, _minSelfDelegation);
        emit ValidatorNotice(valAddr, "init", abi.encode(_signer, _minSelfDelegation, _commissionRate), address(0));
    }

    /**
     * @notice Update validator signer address
     * @param _signer signer address
     */
    function updateValidatorSigner(address _signer) external {
        address valAddr = msg.sender;
        dt.Validator storage validator = validators[valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator not initialized");
        require(signerVals[_signer] == address(0), "Signer already used");
        if (_signer != valAddr) {
            require(validators[_signer].status == dt.ValidatorStatus.Null, "Signer is other validator");
        }

        delete signerVals[validator.signer];
        validator.signer = _signer;
        signerVals[_signer] = valAddr;

        emit ValidatorNotice(valAddr, "signer", abi.encode(_signer), address(0));
    }

    /**
     * @notice Candidate claims to become a bonded validator
     * @dev caller can be either validator owner or signer
     */
    function bondValidator() external {
        address valAddr = msg.sender;
        if (signerVals[msg.sender] != address(0)) {
            valAddr = signerVals[msg.sender];
        }
        dt.Validator storage validator = validators[valAddr];
        require(
            validator.status == dt.ValidatorStatus.Unbonded || validator.status == dt.ValidatorStatus.Unbonding,
            "Invalid validator status"
        );
        require(block.number >= validator.bondBlock, "Bond block not reached");
        require(block.number >= nextBondBlock, "Too frequent validator bond");
        nextBondBlock = block.number + params[dt.ParamName.ValidatorBondInterval];
        require(hasMinRequiredTokens(valAddr, true), "Not have min tokens");

        uint256 maxBondedValidators = params[dt.ParamName.MaxBondedValidators];
        // if the number of validators has not reached the max_validator_num,
        // add validator directly
        if (bondedValAddrs.length < maxBondedValidators) {
            _bondValidator(valAddr);
            _decentralizationCheck(validator.tokens);
            return;
        }
        // if the number of validators has already reached the max_validator_num,
        // add validator only if its tokens is more than the current least bonded validator tokens
        uint256 minTokens = dt.MAX_INT;
        uint256 minTokensIndex;
        for (uint256 i = 0; i < maxBondedValidators; i++) {
            if (validators[bondedValAddrs[i]].tokens < minTokens) {
                minTokensIndex = i;
                minTokens = validators[bondedValAddrs[i]].tokens;
                if (minTokens == 0) {
                    break;
                }
            }
        }
        require(validator.tokens > minTokens, "Insufficient tokens");
        _replaceBondedValidator(valAddr, minTokensIndex);
        _decentralizationCheck(validator.tokens);
    }

    /**
     * @notice Confirm validator status from Unbonding to Unbonded
     * @param _valAddr the address of the validator
     */
    function confirmUnbondedValidator(address _valAddr) external {
        dt.Validator storage validator = validators[_valAddr];
        require(validator.status == dt.ValidatorStatus.Unbonding, "Validator not unbonding");
        require(block.number >= validator.unbondBlock, "Unbond block not reached");

        validator.status = dt.ValidatorStatus.Unbonded;
        delete validator.unbondBlock;
        emit ValidatorStatusUpdate(_valAddr, dt.ValidatorStatus.Unbonded);
    }

    /**
     * @notice Delegate CELR tokens to a validator
     * @dev Minimal amount per delegate operation is 1 CELR
     * @param _valAddr validator to delegate
     * @param _tokens the amount of delegated CELR tokens
     */
    function delegate(address _valAddr, uint256 _tokens) public whenNotPaused {
        address delAddr = msg.sender;
        require(_tokens >= dt.CELR_DECIMAL, "Minimal amount is 1 CELR");

        dt.Validator storage validator = validators[_valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        uint256 shares = _tokenToShare(_tokens, validator.tokens, validator.shares);

        dt.Delegator storage delegator = validator.delegators[delAddr];
        delegator.shares += shares;
        validator.shares += shares;
        validator.tokens += _tokens;
        if (validator.status == dt.ValidatorStatus.Bonded) {
            bondedTokens += _tokens;
            _decentralizationCheck(validator.tokens);
        }
        CELER_TOKEN.safeTransferFrom(delAddr, address(this), _tokens);
        emit DelegationUpdate(_valAddr, delAddr, validator.tokens, delegator.shares, int256(_tokens));
    }

    /**
     * @notice Undelegate shares from a validator
     * @dev Tokens are delegated by the msgSender to the validator
     * @param _valAddr the address of the validator
     * @param _shares undelegate shares
     */
    function undelegateShares(address _valAddr, uint256 _shares) external {
        require(_shares >= dt.CELR_DECIMAL, "Minimal amount is 1 share");
        dt.Validator storage validator = validators[_valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        uint256 tokens = _shareToToken(_shares, validator.tokens, validator.shares);
        _undelegate(validator, _valAddr, tokens, _shares);
    }

    /**
     * @notice Undelegate shares from a validator
     * @dev Tokens are delegated by the msgSender to the validator
     * @param _valAddr the address of the validator
     * @param _tokens undelegate tokens
     */
    function undelegateTokens(address _valAddr, uint256 _tokens) external {
        require(_tokens >= dt.CELR_DECIMAL, "Minimal amount is 1 CELR");
        dt.Validator storage validator = validators[_valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        uint256 shares = _tokenToShare(_tokens, validator.tokens, validator.shares);
        _undelegate(validator, _valAddr, _tokens, shares);
    }

    /**
     * @notice Complete pending undelegations from a validator
     * @param _valAddr the address of the validator
     */
    function completeUndelegate(address _valAddr) external {
        address delAddr = msg.sender;
        dt.Validator storage validator = validators[_valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        dt.Delegator storage delegator = validator.delegators[delAddr];

        uint256 unbondingPeriod = params[dt.ParamName.UnbondingPeriod];
        bool isUnbonded = validator.status == dt.ValidatorStatus.Unbonded;
        // for all pending undelegations
        uint32 i;
        uint256 undelegationShares;
        for (i = delegator.undelegations.head; i < delegator.undelegations.tail; i++) {
            if (isUnbonded || delegator.undelegations.queue[i].creationBlock + unbondingPeriod <= block.number) {
                // complete undelegation when the validator becomes unbonded or
                // the unbondingPeriod for the pending undelegation is up.
                undelegationShares += delegator.undelegations.queue[i].shares;
                delete delegator.undelegations.queue[i];
                continue;
            }
            break;
        }
        delegator.undelegations.head = i;

        require(undelegationShares > 0, "No undelegation ready to be completed");
        uint256 tokens = _shareToToken(undelegationShares, validator.undelegationTokens, validator.undelegationShares);
        validator.undelegationShares -= undelegationShares;
        validator.undelegationTokens -= tokens;
        CELER_TOKEN.safeTransfer(delAddr, tokens);
        emit Undelegated(_valAddr, delAddr, tokens);
    }

    /**
     * @notice Update commission rate
     * @param _newRate new commission rate
     */
    function updateCommissionRate(uint64 _newRate) external {
        address valAddr = msg.sender;
        dt.Validator storage validator = validators[valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        require(_newRate <= dt.COMMISSION_RATE_BASE, "Invalid new rate");
        validator.commissionRate = _newRate;
        emit ValidatorNotice(valAddr, "commission", abi.encode(_newRate), address(0));
    }

    /**
     * @notice Update minimal self delegation value
     * @param _minSelfDelegation minimal amount of tokens staked by the validator itself
     */
    function updateMinSelfDelegation(uint256 _minSelfDelegation) external {
        address valAddr = msg.sender;
        dt.Validator storage validator = validators[valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        require(_minSelfDelegation >= params[dt.ParamName.MinSelfDelegation], "Insufficient min self delegation");
        if (_minSelfDelegation < validator.minSelfDelegation) {
            require(validator.status != dt.ValidatorStatus.Bonded, "Validator is bonded");
            validator.bondBlock = uint64(block.number + params[dt.ParamName.AdvanceNoticePeriod]);
        }
        validator.minSelfDelegation = _minSelfDelegation;
        emit ValidatorNotice(valAddr, "min-self-delegation", abi.encode(_minSelfDelegation), address(0));
    }

    /**
     * @notice Slash a validator and its delegators
     * @param _slashRequest slash request bytes coded in protobuf
     * @param _sigs list of validator signatures
     */
    function slash(bytes calldata _slashRequest, bytes[] calldata _sigs) external whenNotPaused {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "Slash"));
        verifySignatures(abi.encodePacked(domain, _slashRequest), _sigs);

        PbStaking.Slash memory request = PbStaking.decSlash(_slashRequest);
        require(block.timestamp < request.expireTime, "Slash expired");
        require(request.slashFactor <= dt.SLASH_FACTOR_DECIMAL, "Invalid slash factor");
        require(request.slashFactor <= params[dt.ParamName.MaxSlashFactor], "Exceed max slash factor");
        require(!slashNonces[request.nonce], "Used slash nonce");
        slashNonces[request.nonce] = true;

        address valAddr = request.validator;
        dt.Validator storage validator = validators[valAddr];
        require(
            validator.status == dt.ValidatorStatus.Bonded || validator.status == dt.ValidatorStatus.Unbonding,
            "Invalid validator status"
        );

        // slash delegated tokens
        uint256 slashAmt = (validator.tokens * request.slashFactor) / dt.SLASH_FACTOR_DECIMAL;
        validator.tokens -= slashAmt;
        if (validator.status == dt.ValidatorStatus.Bonded) {
            bondedTokens -= slashAmt;
            if (request.jailPeriod > 0 || !hasMinRequiredTokens(valAddr, true)) {
                _unbondValidator(valAddr);
            }
        }
        if (validator.status == dt.ValidatorStatus.Unbonding && request.jailPeriod > 0) {
            validator.bondBlock = uint64(block.number + request.jailPeriod);
        }
        emit DelegationUpdate(valAddr, address(0), validator.tokens, 0, -int256(slashAmt));

        // slash pending undelegations
        uint256 slashUndelegation = (validator.undelegationTokens * request.slashFactor) / dt.SLASH_FACTOR_DECIMAL;
        validator.undelegationTokens -= slashUndelegation;
        slashAmt += slashUndelegation;

        uint256 collectAmt;
        for (uint256 i = 0; i < request.collectors.length; i++) {
            PbStaking.AcctAmtPair memory collector = request.collectors[i];
            if (collectAmt + collector.amount > slashAmt) {
                collector.amount = slashAmt - collectAmt;
            }
            if (collector.amount > 0) {
                collectAmt += collector.amount;
                if (collector.account == address(0)) {
                    CELER_TOKEN.safeTransfer(msg.sender, collector.amount);
                    emit SlashAmtCollected(msg.sender, collector.amount);
                } else {
                    CELER_TOKEN.safeTransfer(collector.account, collector.amount);
                    emit SlashAmtCollected(collector.account, collector.amount);
                }
            }
        }
        forfeiture += slashAmt - collectAmt;
        emit Slash(valAddr, request.nonce, slashAmt);
    }

    function collectForfeiture() external {
        require(forfeiture > 0, "Nothing to collect");
        CELER_TOKEN.safeTransfer(rewardContract, forfeiture);
        forfeiture = 0;
    }

    /**
     * @notice Validator notice event, could be triggered by anyone
     */
    function validatorNotice(
        address _valAddr,
        string calldata _key,
        bytes calldata _data
    ) external {
        dt.Validator storage validator = validators[_valAddr];
        require(validator.status != dt.ValidatorStatus.Null, "Validator is not initialized");
        emit ValidatorNotice(_valAddr, _key, _data, msg.sender);
    }

    function setParamValue(dt.ParamName _name, uint256 _value) external {
        require(msg.sender == govContract, "Caller is not gov contract");
        if (_name == dt.ParamName.MaxBondedValidators) {
            require(bondedValAddrs.length <= _value, "invalid value");
        }
        params[_name] = _value;
    }

    function setGovContract(address _addr) external onlyOwner {
        govContract = _addr;
    }

    function setRewardContract(address _addr) external onlyOwner {
        rewardContract = _addr;
    }

    /**
     * @notice Set max slash factor
     */
    function setMaxSlashFactor(uint256 _maxSlashFactor) external onlyOwner {
        params[dt.ParamName.MaxSlashFactor] = _maxSlashFactor;
    }

    /**
     * @notice Owner drains tokens when the contract is paused
     * @dev emergency use only
     * @param _amount drained token amount
     */
    function drainToken(uint256 _amount) external whenPaused onlyOwner {
        CELER_TOKEN.safeTransfer(msg.sender, _amount);
    }

    /**************************
     *  Public View Functions *
     **************************/

    /**
     * @notice Validate if a message is signed by quorum tokens
     * @param _msg signed message
     * @param _sigs list of validator signatures
     */
    function verifySignatures(bytes memory _msg, bytes[] memory _sigs) public view returns (bool) {
        bytes32 hash = keccak256(_msg).toEthSignedMessageHash();
        uint256 signedTokens;
        address prev = address(0);
        uint256 quorum = getQuorumTokens();
        for (uint256 i = 0; i < _sigs.length; i++) {
            address signer = hash.recover(_sigs[i]);
            require(signer > prev, "Signers not in ascending order");
            prev = signer;
            dt.Validator storage validator = validators[signerVals[signer]];
            if (validator.status != dt.ValidatorStatus.Bonded) {
                continue;
            }
            signedTokens += validator.tokens;
            if (signedTokens >= quorum) {
                return true;
            }
        }
        revert("Quorum not reached");
    }

    /**
     * @notice Verifies that a message is signed by a quorum among the validators.
     * @param _msg signed message
     * @param _sigs the list of signatures
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata,
        uint256[] calldata
    ) public view override {
        require(verifySignatures(_msg, _sigs), "Failed to verify sigs");
    }

    /**
     * @notice Get quorum amount of tokens
     * @return the quorum amount
     */
    function getQuorumTokens() public view returns (uint256) {
        return (bondedTokens * 2) / 3 + 1;
    }

    /**
     * @notice Get validator info
     * @param _valAddr the address of the validator
     * @return Validator token amount
     */
    function getValidatorTokens(address _valAddr) public view returns (uint256) {
        return validators[_valAddr].tokens;
    }

    /**
     * @notice Get validator info
     * @param _valAddr the address of the validator
     * @return Validator status
     */
    function getValidatorStatus(address _valAddr) public view returns (dt.ValidatorStatus) {
        return validators[_valAddr].status;
    }

    /**
     * @notice Check the given address is a validator or not
     * @param _addr the address to check
     * @return the given address is a validator or not
     */
    function isBondedValidator(address _addr) public view returns (bool) {
        return validators[_addr].status == dt.ValidatorStatus.Bonded;
    }

    /**
     * @notice Get the number of validators
     * @return the number of validators
     */
    function getValidatorNum() public view returns (uint256) {
        return valAddrs.length;
    }

    /**
     * @notice Get the number of bonded validators
     * @return the number of bonded validators
     */
    function getBondedValidatorNum() public view returns (uint256) {
        return bondedValAddrs.length;
    }

    /**
     * @return addresses and token amounts of bonded validators
     */
    function getBondedValidatorsTokens() public view returns (dt.ValidatorTokens[] memory) {
        dt.ValidatorTokens[] memory infos = new dt.ValidatorTokens[](bondedValAddrs.length);
        for (uint256 i = 0; i < bondedValAddrs.length; i++) {
            address valAddr = bondedValAddrs[i];
            infos[i] = dt.ValidatorTokens(valAddr, validators[valAddr].tokens);
        }
        return infos;
    }

    /**
     * @notice Check if min token requirements are met
     * @param _valAddr the address of the validator
     * @param _checkSelfDelegation check self delegation
     */
    function hasMinRequiredTokens(address _valAddr, bool _checkSelfDelegation) public view returns (bool) {
        dt.Validator storage v = validators[_valAddr];
        uint256 valTokens = v.tokens;
        if (valTokens < params[dt.ParamName.MinValidatorTokens]) {
            return false;
        }
        if (_checkSelfDelegation) {
            uint256 selfDelegation = _shareToToken(v.delegators[_valAddr].shares, valTokens, v.shares);
            if (selfDelegation < v.minSelfDelegation) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Get the delegator info of a specific validator
     * @param _valAddr the address of the validator
     * @param _delAddr the address of the delegator
     * @return DelegatorInfo from the given validator
     */
    function getDelegatorInfo(address _valAddr, address _delAddr) public view returns (dt.DelegatorInfo memory) {
        dt.Validator storage validator = validators[_valAddr];
        dt.Delegator storage d = validator.delegators[_delAddr];
        uint256 tokens = _shareToToken(d.shares, validator.tokens, validator.shares);

        uint256 undelegationShares;
        uint256 withdrawableUndelegationShares;
        uint256 unbondingPeriod = params[dt.ParamName.UnbondingPeriod];
        bool isUnbonded = validator.status == dt.ValidatorStatus.Unbonded;
        uint256 len = d.undelegations.tail - d.undelegations.head;
        dt.Undelegation[] memory undelegations = new dt.Undelegation[](len);
        for (uint256 i = 0; i < len; i++) {
            undelegations[i] = d.undelegations.queue[i + d.undelegations.head];
            undelegationShares += undelegations[i].shares;
            if (isUnbonded || undelegations[i].creationBlock + unbondingPeriod <= block.number) {
                withdrawableUndelegationShares += undelegations[i].shares;
            }
        }
        uint256 undelegationTokens = _shareToToken(
            undelegationShares,
            validator.undelegationTokens,
            validator.undelegationShares
        );
        uint256 withdrawableUndelegationTokens = _shareToToken(
            withdrawableUndelegationShares,
            validator.undelegationTokens,
            validator.undelegationShares
        );

        return
            dt.DelegatorInfo(
                _valAddr,
                tokens,
                d.shares,
                undelegations,
                undelegationTokens,
                withdrawableUndelegationTokens
            );
    }

    /**
     * @notice Get the value of a specific uint parameter
     * @param _name the key of this parameter
     * @return the value of this parameter
     */
    function getParamValue(dt.ParamName _name) public view returns (uint256) {
        return params[_name];
    }

    /*********************
     * Private Functions *
     *********************/

    function _undelegate(
        dt.Validator storage validator,
        address _valAddr,
        uint256 _tokens,
        uint256 _shares
    ) private {
        address delAddr = msg.sender;
        dt.Delegator storage delegator = validator.delegators[delAddr];
        delegator.shares -= _shares;
        validator.shares -= _shares;
        validator.tokens -= _tokens;
        if (validator.tokens != validator.shares && delegator.shares <= 2) {
            // Remove residual share caused by rounding error when total shares and tokens are not equal
            validator.shares -= delegator.shares;
            delegator.shares = 0;
        }
        require(delegator.shares == 0 || delegator.shares >= dt.CELR_DECIMAL, "not enough remaining shares");

        if (validator.status == dt.ValidatorStatus.Unbonded) {
            CELER_TOKEN.safeTransfer(delAddr, _tokens);
            emit Undelegated(_valAddr, delAddr, _tokens);
            return;
        } else if (validator.status == dt.ValidatorStatus.Bonded) {
            bondedTokens -= _tokens;
            if (!hasMinRequiredTokens(_valAddr, delAddr == _valAddr)) {
                _unbondValidator(_valAddr);
            }
        }
        require(
            delegator.undelegations.tail - delegator.undelegations.head < dt.MAX_UNDELEGATION_ENTRIES,
            "Exceed max undelegation entries"
        );

        uint256 undelegationShares = _tokenToShare(_tokens, validator.undelegationTokens, validator.undelegationShares);
        validator.undelegationShares += undelegationShares;
        validator.undelegationTokens += _tokens;
        dt.Undelegation storage undelegation = delegator.undelegations.queue[delegator.undelegations.tail];
        undelegation.shares = undelegationShares;
        undelegation.creationBlock = block.number;
        delegator.undelegations.tail++;

        emit DelegationUpdate(_valAddr, delAddr, validator.tokens, delegator.shares, -int256(_tokens));
    }

    /**
     * @notice Set validator to bonded
     * @param _valAddr the address of the validator
     */
    function _setBondedValidator(address _valAddr) private {
        dt.Validator storage validator = validators[_valAddr];
        validator.status = dt.ValidatorStatus.Bonded;
        delete validator.unbondBlock;
        bondedTokens += validator.tokens;
        emit ValidatorStatusUpdate(_valAddr, dt.ValidatorStatus.Bonded);
    }

    /**
     * @notice Set validator to unbonding
     * @param _valAddr the address of the validator
     */
    function _setUnbondingValidator(address _valAddr) private {
        dt.Validator storage validator = validators[_valAddr];
        validator.status = dt.ValidatorStatus.Unbonding;
        validator.unbondBlock = uint64(block.number + params[dt.ParamName.UnbondingPeriod]);
        bondedTokens -= validator.tokens;
        emit ValidatorStatusUpdate(_valAddr, dt.ValidatorStatus.Unbonding);
    }

    /**
     * @notice Bond a validator
     * @param _valAddr the address of the validator
     */
    function _bondValidator(address _valAddr) private {
        bondedValAddrs.push(_valAddr);
        _setBondedValidator(_valAddr);
    }

    /**
     * @notice Replace a bonded validator
     * @param _valAddr the address of the new validator
     * @param _index the index of the validator to be replaced
     */
    function _replaceBondedValidator(address _valAddr, uint256 _index) private {
        _setUnbondingValidator(bondedValAddrs[_index]);
        bondedValAddrs[_index] = _valAddr;
        _setBondedValidator(_valAddr);
    }

    /**
     * @notice Unbond a validator
     * @param _valAddr validator to be removed
     */
    function _unbondValidator(address _valAddr) private {
        uint256 lastIndex = bondedValAddrs.length - 1;
        for (uint256 i = 0; i < bondedValAddrs.length; i++) {
            if (bondedValAddrs[i] == _valAddr) {
                if (i < lastIndex) {
                    bondedValAddrs[i] = bondedValAddrs[lastIndex];
                }
                bondedValAddrs.pop();
                _setUnbondingValidator(_valAddr);
                return;
            }
        }
        revert("Not bonded validator");
    }

    /**
     * @notice Check if one validator as too much power
     * @param _valTokens token amounts of the validator
     */
    function _decentralizationCheck(uint256 _valTokens) private view {
        uint256 bondedValNum = bondedValAddrs.length;
        if (bondedValNum == 2 || bondedValNum == 3) {
            require(_valTokens < getQuorumTokens(), "Single validator should not have quorum tokens");
        } else if (bondedValNum > 3) {
            require(_valTokens < bondedTokens / 3, "Single validator should not have 1/3 tokens");
        }
    }

    /**
     * @notice Convert token to share
     */
    function _tokenToShare(
        uint256 tokens,
        uint256 totalTokens,
        uint256 totalShares
    ) private pure returns (uint256) {
        if (totalTokens == 0) {
            return tokens;
        }
        return (tokens * totalShares) / totalTokens;
    }

    /**
     * @notice Convert share to token
     */
    function _shareToToken(
        uint256 shares,
        uint256 totalTokens,
        uint256 totalShares
    ) private pure returns (uint256) {
        if (totalShares == 0) {
            return shares;
        }
        return (shares * totalTokens) / totalShares;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import "./Staking.sol";
import "./Pauser.sol";

contract StakingReward is Pauser {
    using SafeERC20 for IERC20;

    Staking public immutable staking;

    // recipient => CELR reward amount
    mapping(address => uint256) public claimedRewardAmounts;

    event StakingRewardClaimed(address indexed recipient, uint256 reward);
    event StakingRewardContributed(address indexed contributor, uint256 contribution);

    constructor(Staking _staking) {
        staking = _staking;
    }

    /**
     * @notice Claim reward
     * @dev Here we use cumulative reward to make claim process idempotent
     * @param _rewardRequest reward request bytes coded in protobuf
     * @param _sigs list of validator signatures
     */
    function claimReward(bytes calldata _rewardRequest, bytes[] calldata _sigs) external whenNotPaused {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "StakingReward"));
        staking.verifySignatures(abi.encodePacked(domain, _rewardRequest), _sigs);
        PbStaking.StakingReward memory reward = PbStaking.decStakingReward(_rewardRequest);

        uint256 cumulativeRewardAmount = reward.cumulativeRewardAmount;
        uint256 newReward = cumulativeRewardAmount - claimedRewardAmounts[reward.recipient];
        require(newReward > 0, "No new reward");
        claimedRewardAmounts[reward.recipient] = cumulativeRewardAmount;
        staking.CELER_TOKEN().safeTransfer(reward.recipient, newReward);
        emit StakingRewardClaimed(reward.recipient, newReward);
    }

    /**
     * @notice Contribute CELR tokens to the reward pool
     * @param _amount the amount of CELR token to contribute
     */
    function contributeToRewardPool(uint256 _amount) external whenNotPaused {
        address contributor = msg.sender;
        IERC20(staking.CELER_TOKEN()).safeTransferFrom(contributor, address(this), _amount);

        emit StakingRewardContributed(contributor, _amount);
    }

    /**
     * @notice Owner drains CELR tokens when the contract is paused
     * @dev emergency use only
     * @param _amount drained CELR token amount
     */
    function drainToken(uint256 _amount) external whenPaused onlyOwner {
        IERC20(staking.CELER_TOKEN()).safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    bool public whitelistEnabled;

    event WhitelistedAdded(address account);
    event WhitelistedRemoved(address account);

    modifier onlyWhitelisted() {
        if (whitelistEnabled) {
            require(isWhitelisted(msg.sender), "Caller is not whitelisted");
        }
        _;
    }

    /**
     * @notice Set whitelistEnabled
     */
    function setWhitelistEnabled(bool _whitelistEnabled) external onlyOwner {
        whitelistEnabled = _whitelistEnabled;
    }

    /**
     * @notice Add an account to whitelist
     */
    function addWhitelisted(address account) external onlyOwner {
        require(!isWhitelisted(account), "Already whitelisted");
        whitelist[account] = true;
        emit WhitelistedAdded(account);
    }

    /**
     * @notice Remove an account from whitelist
     */
    function removeWhitelisted(address account) external onlyOwner {
        require(isWhitelisted(account), "Not whitelisted");
        whitelist[account] = false;
        emit WhitelistedRemoved(account);
    }

    /**
     * @return is account whitelisted
     */
    function isWhitelisted(address account) public view returns (bool) {
        return whitelist[account];
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface ISigsVerifier {
    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

library DataTypes {
    uint256 constant CELR_DECIMAL = 1e18;
    uint256 constant MAX_INT = 2**256 - 1;
    uint256 constant COMMISSION_RATE_BASE = 10000; // 1 commissionRate means 0.01%
    uint256 constant MAX_UNDELEGATION_ENTRIES = 10;
    uint256 constant SLASH_FACTOR_DECIMAL = 1e6;

    enum ValidatorStatus {
        Null,
        Unbonded,
        Unbonding,
        Bonded
    }

    enum ParamName {
        ProposalDeposit,
        VotingPeriod,
        UnbondingPeriod,
        MaxBondedValidators,
        MinValidatorTokens,
        MinSelfDelegation,
        AdvanceNoticePeriod,
        ValidatorBondInterval,
        MaxSlashFactor
    }

    struct Undelegation {
        uint256 shares;
        uint256 creationBlock;
    }

    struct Undelegations {
        mapping(uint256 => Undelegation) queue;
        uint32 head;
        uint32 tail;
    }

    struct Delegator {
        uint256 shares;
        Undelegations undelegations;
    }

    struct Validator {
        ValidatorStatus status;
        address signer;
        uint256 tokens; // sum of all tokens delegated to this validator
        uint256 shares; // sum of all delegation shares
        uint256 undelegationTokens; // tokens being undelegated
        uint256 undelegationShares; // shares of tokens being undelegated
        mapping(address => Delegator) delegators;
        uint256 minSelfDelegation;
        uint64 bondBlock; // cannot become bonded before this block
        uint64 unbondBlock; // cannot become unbonded before this block
        uint64 commissionRate; // equal to real commission rate * COMMISSION_RATE_BASE
    }

    // used for external view output
    struct ValidatorTokens {
        address valAddr;
        uint256 tokens;
    }

    // used for external view output
    struct ValidatorInfo {
        address valAddr;
        ValidatorStatus status;
        address signer;
        uint256 tokens;
        uint256 shares;
        uint256 minSelfDelegation;
        uint64 commissionRate;
    }

    // used for external view output
    struct DelegatorInfo {
        address valAddr;
        uint256 tokens;
        uint256 shares;
        Undelegation[] undelegations;
        uint256 undelegationTokens;
        uint256 withdrawableUndelegationTokens;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

// runtime proto sol library
library Pb {
    enum WireType {
        Varint,
        Fixed64,
        LengthDelim,
        StartGroup,
        EndGroup,
        Fixed32
    }

    struct Buffer {
        uint256 idx; // the start index of next read. when idx=b.length, we're done
        bytes b; // hold serialized proto msg, readonly
    }

    // create a new in-memory Buffer object from raw msg bytes
    function fromBytes(bytes memory raw) internal pure returns (Buffer memory buf) {
        buf.b = raw;
        buf.idx = 0;
    }

    // whether there are unread bytes
    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }

    // decode current field number and wiretype
    function decKey(Buffer memory buf) internal pure returns (uint256 tag, WireType wiretype) {
        uint256 v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }

    // count tag occurrences, return an array due to no memory map support
    // have to create array for (maxtag+1) size. cnts[tag] = occurrences
    // should keep buf.idx unchanged because this is only a count function
    function cntTags(Buffer memory buf, uint256 maxtag) internal pure returns (uint256[] memory cnts) {
        uint256 originalIdx = buf.idx;
        cnts = new uint256[](maxtag + 1); // protobuf's tags are from 1 rather than 0
        uint256 tag;
        WireType wire;
        while (hasMore(buf)) {
            (tag, wire) = decKey(buf);
            cnts[tag] += 1;
            skipValue(buf, wire);
        }
        buf.idx = originalIdx;
    }

    // read varint from current buf idx, move buf.idx to next read, return the int value
    function decVarint(Buffer memory buf) internal pure returns (uint256 v) {
        bytes10 tmp; // proto int is at most 10 bytes (7 bits can be used per byte)
        bytes memory bb = buf.b; // get buf.b mem addr to use in assembly
        v = buf.idx; // use v to save one additional uint variable
        assembly {
            tmp := mload(add(add(bb, 32), v)) // load 10 bytes from buf.b[buf.idx] to tmp
        }
        uint256 b; // store current byte content
        v = 0; // reset to 0 for return value
        for (uint256 i = 0; i < 10; i++) {
            assembly {
                b := byte(i, tmp) // don't use tmp[i] because it does bound check and costs extra
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert(); // i=10, invalid varint stream
    }

    // read length delimited field and return bytes
    function decBytes(Buffer memory buf) internal pure returns (bytes memory b) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        b = new bytes(len);
        bytes memory bufB = buf.b; // get buf.b mem addr to use in assembly
        uint256 bStart;
        uint256 bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint256 i = 0; i < len; i += 32) {
            assembly {
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }

    // return packed ints
    function decPacked(Buffer memory buf) internal pure returns (uint256[] memory t) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        // array in memory must be init w/ known length
        // so we have to create a tmp array w/ max possible len first
        uint256[] memory tmp = new uint256[](len);
        uint256 i = 0; // count how many ints are there
        while (buf.idx < end) {
            tmp[i] = decVarint(buf);
            i++;
        }
        t = new uint256[](i); // init t with correct length
        for (uint256 j = 0; j < i; j++) {
            t[j] = tmp[j];
        }
        return t;
    }

    // move idx pass current value field, to beginning of next tag or msg end
    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) {
            decVarint(buf);
        } else if (wire == WireType.LengthDelim) {
            uint256 len = decVarint(buf);
            buf.idx += len; // skip len bytes value data
            require(buf.idx <= buf.b.length); // avoid overflow
        } else {
            revert();
        } // unsupported wiretype
    }

    // type conversion help utils
    function _bool(uint256 x) internal pure returns (bool v) {
        return x != 0;
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32); // b's length must be smaller than or equal to 32
        assembly {
            v := mload(add(b, 32))
        } // load all 32bytes to v
        v = v >> (8 * (32 - b.length)); // only first b.length is valid
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(bytes memory b) internal pure returns (address payable v) {
        require(b.length == 20);
        //load 32bytes then shift right 12 bytes
        assembly {
            v := div(mload(add(b, 32)), 0x1000000000000000000000000)
        }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly {
            v := mload(add(b, 32))
        }
    }

    // uint[] to uint8[]
    function uint8s(uint256[] memory arr) internal pure returns (uint8[] memory t) {
        t = new uint8[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint8(arr[i]);
        }
    }

    function uint32s(uint256[] memory arr) internal pure returns (uint32[] memory t) {
        t = new uint32[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint32(arr[i]);
        }
    }

    function uint64s(uint256[] memory arr) internal pure returns (uint64[] memory t) {
        t = new uint64[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint64(arr[i]);
        }
    }

    function bools(uint256[] memory arr) internal pure returns (bool[] memory t) {
        t = new bool[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = arr[i] != 0;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: contracts/libraries/proto/staking.proto
pragma solidity 0.8.9;
import "./Pb.sol";

library PbStaking {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct StakingReward {
        address recipient; // tag: 1
        uint256 cumulativeRewardAmount; // tag: 2
    } // end struct StakingReward

    function decStakingReward(bytes memory raw) internal pure returns (StakingReward memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.recipient = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.cumulativeRewardAmount = Pb._uint256(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder StakingReward

    struct Slash {
        address validator; // tag: 1
        uint64 nonce; // tag: 2
        uint64 slashFactor; // tag: 3
        uint64 expireTime; // tag: 4
        uint64 jailPeriod; // tag: 5
        AcctAmtPair[] collectors; // tag: 6
    } // end struct Slash

    function decSlash(bytes memory raw) internal pure returns (Slash memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256[] memory cnts = buf.cntTags(6);
        m.collectors = new AcctAmtPair[](cnts[6]);
        cnts[6] = 0; // reset counter for later use

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.validator = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.nonce = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.slashFactor = uint64(buf.decVarint());
            } else if (tag == 4) {
                m.expireTime = uint64(buf.decVarint());
            } else if (tag == 5) {
                m.jailPeriod = uint64(buf.decVarint());
            } else if (tag == 6) {
                m.collectors[cnts[6]] = decAcctAmtPair(buf.decBytes());
                cnts[6]++;
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder Slash

    struct AcctAmtPair {
        address account; // tag: 1
        uint256 amount; // tag: 2
    } // end struct AcctAmtPair

    function decAcctAmtPair(bytes memory raw) internal pure returns (AcctAmtPair memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.account = Pb._address(buf.decBytes());
            } else if (tag == 2) {
                m.amount = Pb._uint256(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder AcctAmtPair
}