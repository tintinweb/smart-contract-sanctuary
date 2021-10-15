/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: node_modules\@openzeppelin\contracts\utils\Address.sol



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

// File: @openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol



pragma solidity ^0.8.0;



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
        //unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        //}
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

// File: @openzeppelin\contracts\security\ReentrancyGuard.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts\utils\cryptography\ECDSA.sol



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
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
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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

// File: ..\src\AngryMining.sol


pragma solidity ^0.8.4;




contract AngryMining is ReentrancyGuard{
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 reward;
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ANGRYs to distribute per block.
        uint256 lastRewardBlock; // Last block number that ANGRYs distribution occurs.
        uint256 accAngryPerShare; // Accumulated ANGRYs per share, times 1e12. See below.
        uint256 stakeAmount;
    }
    struct PoolItem {
        uint256 pid;
        uint256 allocPoint;
        address lpToken;
    }
    struct BonusPeriod{
        uint256 beginBlock;
        uint256 endBlock;
    }
    struct LpMiningInfo{
        uint256 pid;
        address lpToken;
        uint256 amount;
        uint256 reward;
    }
    bool public bInited;
    bool public bStarted;
    address public owner;
    IERC20 public angryToken;
    // ANGRY tokens created per block.
    uint256 public angryPerBlock;
    // Bonus muliplier for early angry makers.
    uint256 public constant BONUS_MULTIPLIER = 2;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    BonusPeriod[] public bonusPeriods;
    mapping(address => bool) public executorList;
    address[5] public adminList;
    mapping(string => bool) public usedUUIDs;
    
    event ExecutorAdd(address _newAddr);
    event ExecutorDel(address _oldAddr);
    event BonusPeriodAdd(uint256 _beginBlock, uint256 _endBlock);
    event LpDeposit(address indexed user, uint256 indexed pid, uint256 amount);
    event LpWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event PoolAdd(uint256 _allocPoint, address indexed _lpToken, uint256 _pid);
    event PoolChange(uint256 indexed pid, uint256 _allocPoint);
    event LpMiningRewardHarvest(address _user, uint256 _pid, uint256 _amount);
    event AdminChange(address _oldAddr, address _newAddr);
    event RewardsPerBlockChange(uint256 _oldValue, uint256 _newValue);
    event StartFlagChange(bool _bVal);
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyExecutor {
        require(executorList[msg.sender]);
        _;
    }
    
    modifier validPool(uint256 _pid) {
        require( _pid < poolInfo.length, "pool not exists!" );
        _;
    }
    
    modifier checkSig(string memory _uuid, bytes[] memory _sigs) {
        require( !usedUUIDs[_uuid], "UUID exists!" );
        bool[5] memory flags = [false,false,false,false,false];
        bytes32 hash = keccak256(abi.encodePacked(_uuid));
        for(uint256 i = 0;i < _sigs.length; i++){
            address signer = hash.recover(_sigs[i]);
            if(signer == adminList[0]){
                flags[0] = true;
            }else if(signer == adminList[1]){
                flags[1] = true;
            }else if(signer == adminList[2]){
                flags[2] = true;
            }else if(signer == adminList[3]){
                flags[3] = true;
            }else if(signer == adminList[4]){
                flags[4] = true;
            }
        }
        uint256 cnt = 0; 
        for(uint256 i = 0; i < 5; i++){
          if(flags[i]) cnt += 1;
        }
        usedUUIDs[_uuid] = true;
        require( cnt >= 3, "Not enough sigs!" );
        _;
    }
    
    constructor(address _angryTokenAddr, uint256 _angryPerBlock, address _admin1, address _admin2, address _admin3, address _admin4, address _admin5) {
        initialize(_angryTokenAddr, _angryPerBlock, _admin1, _admin2, _admin3, _admin4, _admin5);
    }
    
    function initialize(address _angryTokenAddr, uint256 _angryPerBlock, address _admin1, address _admin2, address _admin3, address _admin4, address _admin5) public {
        require(!bInited, "already Inited!");
        bInited = true;
        bStarted = true;
        owner = msg.sender;
        executorList[msg.sender] = true;
        angryToken = IERC20(_angryTokenAddr);
        angryPerBlock = _angryPerBlock;
        adminList[0] = _admin1;
        adminList[1] = _admin2;
        adminList[2] = _admin3;
        adminList[3] = _admin4;
        adminList[4] = _admin5;
        emit ExecutorAdd(msg.sender);
    }
    
    function addExecutor(address _newExecutor) onlyOwner public {
        executorList[_newExecutor] = true;
        emit ExecutorAdd(_newExecutor);
    }
    
    function delExecutor(address _oldExecutor) onlyOwner public {
        executorList[_oldExecutor] = false;
        emit ExecutorDel(_oldExecutor);
    }
    
    function checkPoolDuplicate(IERC20 _lpToken) internal view {
        uint256 length = poolInfo.length;
        for(uint256 pid = 0; pid < length; ++pid){
            require( poolInfo[pid].lpToken != _lpToken, "duplicate pool!" );
        }
    }
    
    function addBonusPeriod(uint256 _beginBlock, uint256 _endBlock) public onlyExecutor {
        require( _beginBlock < _endBlock );
        uint256 length = bonusPeriods.length;
        for(uint256 i = 0;i < length; i++){
            require(_endBlock < bonusPeriods[i].beginBlock || _beginBlock > bonusPeriods[i].endBlock, "BO");
        }
        massUpdatePools();
        BonusPeriod memory bp;
        bp.beginBlock = _beginBlock;
        bp.endBlock = _endBlock;
        bonusPeriods.push(bp);
        emit BonusPeriodAdd(_beginBlock, _endBlock);
    }
    
    function addPool(
        uint256 _allocPoint,
        address _lpToken,
        string memory _uuid, 
        bytes[] memory _sigs
    ) public checkSig(_uuid, _sigs) {
        checkPoolDuplicate(IERC20(_lpToken));
        massUpdatePools();
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: IERC20(_lpToken),
                allocPoint: _allocPoint,
                lastRewardBlock: block.number,
                accAngryPerShare: 0,
                stakeAmount: 0
            })
        );
        emit PoolAdd(_allocPoint,_lpToken, poolInfo.length-1);
    }
    
    function changePool(
        uint256 _pid,
        uint256 _allocPoint,
        string memory _uuid, 
        bytes[] memory _sigs
    ) public validPool(_pid) checkSig(_uuid, _sigs) {
        require( _allocPoint > 0, "invalid allocPoint!" );
        massUpdatePools();
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit PoolChange(_pid, _allocPoint);
    }
    
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        uint256 bonusBeginBlock = 0;
        uint256 bonusEndBlock = 0;
        uint256 length = bonusPeriods.length;
        uint256 reward = 0;
        uint256 totalBlocks = _to - _from;
        uint256 bonusBlocks = 0;
    
        for(uint256 i = 0;i < length; i++){
            bonusBeginBlock = bonusPeriods[i].beginBlock;
            bonusEndBlock = bonusPeriods[i].endBlock;
            if (_to >= bonusBeginBlock && _from <= bonusEndBlock){
                uint256 a = _from > bonusBeginBlock ? _from : bonusBeginBlock;
                uint256 b = _to > bonusEndBlock ? bonusEndBlock : _to;
                if(b > a){
                    bonusBlocks += (b - a);
                    reward += (b - a) * BONUS_MULTIPLIER;
                }
            }
        }
        if(totalBlocks > bonusBlocks){
            reward += (totalBlocks - bonusBlocks);
        }
        return reward;
    }
    
    function getLpMiningReward(uint256 _pid, address _user)
        public
        validPool(_pid)
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accAngryPerShare = pool.accAngryPerShare;
        uint256 lpSupply = pool.stakeAmount;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 angryReward =
                multiplier * angryPerBlock * pool.allocPoint / totalAllocPoint;
            accAngryPerShare = accAngryPerShare + angryReward * (1e12) / lpSupply;
        }
        return user.amount * accAngryPerShare / (1e12) - user.rewardDebt + user.reward;
    }
    
    function getPoolList() public view returns(PoolItem[] memory _pools){
        uint256 length = poolInfo.length;
        _pools = new PoolItem[](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            _pools[pid].pid = pid;
            _pools[pid].lpToken = address(poolInfo[pid].lpToken);
            _pools[pid].allocPoint = poolInfo[pid].allocPoint;
        }
    }
    
    function getPoolListArr() public view returns(uint256[] memory _pids,address[] memory _tokenAddrs, uint256[] memory _allocPoints){
        uint256 length = poolInfo.length;
        _pids = new uint256[](length);
        _tokenAddrs = new address[](length);
        _allocPoints = new uint256[](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            _pids[pid] = pid;
            _tokenAddrs[pid] = address(poolInfo[pid].lpToken);
            _allocPoints[pid] = poolInfo[pid].allocPoint;
        }
    }
    
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
    function getAccountLpMinings(address _addr) public view returns(LpMiningInfo[] memory _infos){
        uint256 length = poolInfo.length;
        _infos = new LpMiningInfo[](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            UserInfo storage user = userInfo[pid][_addr];
            _infos[pid].pid = pid;
            _infos[pid].lpToken = address(poolInfo[pid].lpToken);
            _infos[pid].amount = user.amount;
            _infos[pid].reward = getLpMiningReward(pid,_addr);
        }
    }
    
    function updatePool(uint256 _pid) public validPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.stakeAmount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 angryReward =
            multiplier * angryPerBlock * pool.allocPoint / totalAllocPoint;
        pool.accAngryPerShare = pool.accAngryPerShare + angryReward * (1e12) / lpSupply;
        pool.lastRewardBlock = block.number;
    }
    
    function depositLP(uint256 _pid, uint256 _amount) public nonReentrant validPool(_pid) {
        require(bStarted, "NS");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount * pool.accAngryPerShare / (1e12) - user.rewardDebt;
            //safeAngryTransfer(msg.sender, pending);
            user.reward += pending;
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        pool.stakeAmount += _amount;
        user.amount = user.amount + _amount;
        user.rewardDebt = user.amount * pool.accAngryPerShare / (1e12);
        emit LpDeposit(msg.sender, _pid, _amount);
    }
    
    function withdrawLP(uint256 _pid, uint256 _amount) public nonReentrant validPool(_pid) {
        require(bStarted, "NS");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "AE");
        updatePool(_pid);
        uint256 pending =
            user.amount * pool.accAngryPerShare / (1e12) - user.rewardDebt;
        //safeAngryTransfer(msg.sender, pending);
        user.reward += pending;
        user.amount = user.amount - _amount;
        user.rewardDebt = user.amount * pool.accAngryPerShare / (1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        pool.stakeAmount -= _amount;
        if(user.amount == 0 && user.reward > 0){
            emit LpMiningRewardHarvest(msg.sender, _pid, user.reward);
            safeAngryTransfer(msg.sender, user.reward);
            user.reward = 0;
        }
        emit LpWithdraw(msg.sender, _pid, _amount);
    }
    
    function harvestLpMiningReward(uint256 _pid) public nonReentrant validPool(_pid){
        require(bStarted, "NS");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending =
            user.amount * pool.accAngryPerShare / (1e12) - user.rewardDebt;
        user.reward += pending;
        user.rewardDebt = user.amount * pool.accAngryPerShare / (1e12);
        safeAngryTransfer(msg.sender, user.reward);
        emit LpMiningRewardHarvest(msg.sender, _pid, user.reward);
        user.reward = 0;
    }
    
    function safeAngryTransfer(address _to, uint256 _amount) internal {
        angryToken.safeTransfer(_to, _amount);
    }
    
    function getAdminList() public view returns (address[] memory _admins){
        _admins = new address[](adminList.length);
        for(uint256 i = 0; i < adminList.length; i++){
            _admins[i] = adminList[i];
        }
    }
    
    function changeAdmin(uint256 _index, address _newAddress, string memory _uuid, bytes[] memory _sigs) public checkSig(_uuid, _sigs) {
        require(_index < adminList.length, "index out of range!");
        emit AdminChange(adminList[_index], _newAddress);
        adminList[_index] = _newAddress;
    }
    
    function changeRewardsPerBlock(uint256 _angryPerBlock, string memory _uuid, bytes[] memory _sigs) public checkSig(_uuid, _sigs){
        emit RewardsPerBlockChange(angryPerBlock,_angryPerBlock);
        angryPerBlock = _angryPerBlock;
    }
    
    function setStartFlag(bool _bVal, string memory _uuid, bytes[] memory _sigs) public checkSig(_uuid, _sigs) {
        bStarted = _bVal;
        emit StartFlagChange(_bVal);
    }
}