/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// SPDX-License-Identifier: GPL-3.0-or-later

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity 0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity 0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]



pragma solidity 0.8.0;


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


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity 0.8.0;

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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
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


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity 0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File @openzeppelin/contracts/security/[email protected]



pragma solidity 0.8.0;

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

    constructor () {
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


// File contracts/interface/IExchangeQuoter.sol


pragma solidity 0.8.0;


/**
 * @title IExchangeQuoter
 * @author solace.fi
 * @notice Calculates exchange rates for trades between ERC20 tokens.
 */
interface IExchangeQuoter {
    /**
     * @notice Calculates the exchange rate for an _amount of _token to eth.
     * @param _token The token to give.
     * @param _amount The amount to give.
     * @return The amount of eth received.
     */
    function tokenToEth(address _token, uint256 _amount) external view returns (uint256);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]



pragma solidity 0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]



pragma solidity 0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]



pragma solidity 0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]



pragma solidity 0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File contracts/interface/IPolicyManager.sol


pragma solidity 0.8.0;


interface IPolicyManager /*is IERC721Enumerable, IERC721Metadata*/ {
    event ProductAdded(address product);
    event ProductRemoved(address product);
    event PolicyCreated(uint256 tokenID);
    event PolicyBurned(uint256 tokenID);
    // Emitted when Governance is set
    event GovernanceTransferred(address _newGovernance);

    /// @notice Governance.
    function governance() external view returns (address);

    /// @notice Governance to take over.
    function newGovernance() external view returns (address);

    /**
     * @notice Transfers the governance role to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Adds a new product.
     * Can only be called by the current governor.
     * @param _product the new product
     */
    function addProduct(address _product) external;

    /**
     * @notice Removes a product.
     * Can only be called by the current governor.
     * @param _product the product to remove
     */
    function removeProduct(address _product) external;

    /**
     * @notice Checks is an address is an active product.
     * @param _product The product to check.
     * @return True if the product is active.
     */
    function productIsActive(address _product) external view returns (bool);

    /**
     * @notice Returns the number of products.
     * @return The number of products.
     */
    function numProducts() external view returns (uint256);

    /**
     * @notice Returns the product at the given index.
     * @param _productNum The index to query.
     * @return The address of the product.
     */
    function getProduct(uint256 _productNum) external view returns (address);

    /*** POLICY VIEW FUNCTIONS
    View functions that give us data about policies
    ****/
    function getPolicyInfo(uint256 _policyID) external view returns (address policyholder, address product, address positionContract, uint256 coverAmount, uint64 expirationBlock, uint24 price);
    function getPolicyholder(uint256 _policyID) external view returns (address);
    function getPolicyProduct(uint256 _policyID) external view returns (address);
    function getPolicyPositionContract(uint256 _policyID) external view returns (address);
    function getPolicyExpirationBlock(uint256 _policyID) external view returns (uint64);
    function getPolicyCoverAmount(uint256 _policyID) external view returns (uint256);
    function getPolicyPrice(uint256 _policyID) external view returns (uint24);
    function listPolicies(address _policyholder) external view returns (uint256[] memory);
    function exists(uint256 _policyID) external view returns (bool);
    function policyIsActive(uint256 _policyID) external view returns (bool);
    function policyHasExpired(uint256 _policyID) external view returns (bool);

    /*** POLICY MUTATIVE FUNCTIONS
    Functions that create, modify, and destroy policies
    ****/
    /**
     * @notice Creates new ERC721 policy `tokenID` for `to`.
     * The caller must be a product.
     * @param _policyholder receiver of new policy token
     * @param _positionContract contract address where the position is covered
     * @param _expirationBlock policy expiration block number
     * @param _coverAmount policy coverage amount (in wei)
     * @param _price coverage price
     * @return policyID (aka tokenID)
     */
    function createPolicy(
        address _policyholder,
        address _positionContract,
        uint256 _coverAmount,
        uint64 _expirationBlock,
        uint24 _price
    ) external returns (uint256 policyID);
    function setPolicyInfo(uint256 _policyId, address _policyholder, address _positionContract, uint256 _coverAmount, uint64 _expirationBlock, uint24 _price) external;
    function burn(uint256 _tokenId) external;

    function updateActivePolicies(uint256[] calldata _policyIDs) external;
}


// File contracts/interface/ITreasury.sol


pragma solidity 0.8.0;


/**
 * @title ITreasury
 * @author solace.fi
 * @notice The interface of the war chest of Castle Solace.
 */
interface ITreasury {

    // events
    // Emitted when eth is deposited
    event EthDeposited(uint256 _amount);
    // Emitted when a token is deposited
    event TokenDeposited(address _token, uint256 _amount);
    // Emitted when a token is spent
    event FundsSpent(address _token, uint256 _amount, address _recipient);
    // Emitted when Governance is set
    event GovernanceTransferred(address _newGovernance);

    /**
     * Receive function. Deposits eth.
     */
    receive() external payable;

    /**
     * Fallback function. Deposits eth.
     */
    fallback () external payable;

    /// @notice Governance.
    function governance() external view returns (address);

    /// @notice Governance to take over.
    function newGovernance() external view returns (address);

    /**
     * @notice Transfers the governance role to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Deposits some ether.
     */
    function depositEth() external payable;

    /**
     * @notice Deposit some ERC20 token.
     * @param _token The address of the token to deposit.
     * @param _amount The amount of the token to deposit.
     */
    function depositToken(address _token, uint256 _amount) external;

    /**
     * @notice Spends some tokens.
     * Can only be called by the current governor.
     * @param _token The address of the token to spend.
     * @param _amount The amount of the token to spend.
     * @param _recipient The address of the token receiver.
     */
    function spend(address _token, uint256 _amount, address _recipient) external;

    /**
     * @notice Manually swaps a token.
     * Can only be called by the current governor.
     * @dev Swaps the entire balance in case some tokens were unknowingly received.
     * Reverts if the swap was unsuccessful.
     * @param _path The path of pools to take.
     * @param _amountIn The amount to swap.
     * @param _amountOutMinimum The minimum about to receive.
     */
    function swap(bytes memory _path, uint256 _amountIn, uint256 _amountOutMinimum) external;

    /**
     * @notice Sets the premium recipients and their weights.
     * Can only be called by the current governor.
     * @param _recipients The premium recipients.
     * @param _weights The recipient weights.
     */
    function setPremiumRecipients(address payable[] calldata _recipients, uint32[] calldata _weights) external;

    /**
     * @notice Routes the premiums to the recipients
     */
    function routePremiums() external payable;

    /**
     * @notice Wraps some eth into weth.
     * Can only be called by the current governor.
     * @param _amount The amount to wrap.
     */
    function wrap(uint256 _amount) external;

    /**
     * @notice Unwraps some weth into eth.
     * Can only be called by the current governor.
     * @param _amount The amount to unwrap.
     */
    function unwrap(uint256 _amount) external;

    // used in Product
    function refund(address _user, uint256 _amount) external;

    /**
     * @notice The amount of eth that a user is owed if any.
     * @param _user The user.
     * @return The amount.
     */
    function unpaidRewards(address _user) external view returns (uint256);

    /**
     * @notice Pull any unpaid rewards.
     */
    function withdraw() external;
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]



pragma solidity 0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File contracts/interface/IVault.sol



pragma solidity 0.8.0;


/**
 * @title Vault interface
 * @author solace.fi
 * @notice Interface for Vault contract
 */

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface IVault is IERC20, IERC20Permit {

    /// @notice Governance.
    function governance() external view returns (address);

    /// @notice Governance to take over.
    function newGovernance() external view returns (address);

    // Emitted when Governance is set
    event GovernanceTransferred(address _newGovernance);

    function deposit() external payable;
    function depositWeth(uint256 amount) external;
    function withdraw(uint256 _amount, uint256 _maxLoss) external returns (uint256);
    function token() external view returns (IERC20);
    function debtOutstanding(address) external view returns (uint256);
    function revokeStrategy(address) external;
    function strategies(address) external view returns (StrategyParams memory);
    function processClaim(address claimant, uint256 amount) external;
    function report(
        uint256 gain,
        uint256 loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * @notice Transfers the governance role to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;
}


// File contracts/interface/IRegistry.sol


pragma solidity 0.8.0;


/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts in the Solaverse.
 */
interface IRegistry {

    /// @notice Governance.
    function governance() external view returns (address);

    /// @notice Governance to take over.
    function newGovernance() external view returns (address);

    /// Protocol contract address getters
    function master() external view returns (address);
    function vault() external view returns (address);
    function treasury() external view returns (address);
    function solace() external view returns (address);
    function locker() external view returns (address);
    function claimsEscrow() external view returns (address);
    function policyManager() external view returns (address);

    // events
    // Emitted when Governance is set
    event GovernanceTransferred(address _newGovernance);
    // Emitted when Solace Token is set
    event SolaceSet(address _solace);
    // Emitted when Master is set
    event MasterSet(address _master);
    // Emitted when Vault is set
    event VaultSet(address _vault);
    // Emitted when Treasury is set
    event TreasurySet(address _treasury);
    // Emitted when Locker is set
    event LockerSet(address _locker);
    // Emitted when ClaimsEscrow is set
    event ClaimsEscrowSet(address _claimsEscrow);
    // Emitted when PolicyManager is set
    event PolicyManagerSet(address _policyManager);

    /**
     * @notice Transfers the governance role to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Sets the solace token contract.
     * Can only be called by the current governor.
     * @param _solace The solace token address.
     */
    function setSolace(address _solace) external;

    /**
     * @notice Sets the master contract.
     * Can only be called by the current governor.
     * @param _master The master contract address.
     */
    function setMaster(address _master) external;

    /**
     * @notice Sets the vault contract.
     * Can only be called by the current governor.
     * @param _vault The vault contract address.
     */
    function setVault(address _vault) external;

    /**
     * @notice Sets the treasury contract.
     * Can only be called by the current governor.
     * @param _treasury The treasury contract address.
     */
    function setTreasury(address _treasury) external;

    /**
     * @notice Sets the locker contract.
     * Can only be called by the current governor.
     * @param _locker The locker address.
     */
    function setLocker(address _locker) external;

    /**
     * @notice Sets the Claims Escrow contract.
     * Can only be called by the current governor.
     * @param _claimsEscrow The Claims Escrow address.
     */
    function setClaimsEscrow(address _claimsEscrow) external;

    /**
     * @notice Sets the PolicyManager contract.
     * Can only be called by the current governor.
     * @param _policyManager The PolicyManager address.
     */
    function setPolicyManager(address _policyManager) external;
}


// File contracts/interface/IProduct.sol


pragma solidity 0.8.0;

/**
 * @title Interface for product contracts
 * @author solace.fi
 */
interface IProduct {
    event PolicyCreated(uint256 policyID);
    event PolicyExtended(uint256 policyID);
    event PolicyCanceled(uint256 policyID);
    event PolicyUpdated(uint256 policyID);
    event GovernanceTransferred(address _newGovernance);

    /**** GETTERS + SETTERS
    Functions which get and set important product state variables
    ****/
    function governance() external view returns (address);
    function newGovernance() external view returns (address);
    function price() external view returns (uint24);
    function minPeriod() external view returns (uint64);
    function maxPeriod() external view returns (uint64);
    function manageFee() external view returns (uint64);
    function maxCoverAmount() external view returns (uint256);
    function maxCoverPerUser() external view returns (uint256);
    function coveredPlatform() external view returns (address);
    function productPolicyCount() external view returns (uint256);
    function activeCoverAmount() external view returns (uint256);

    function setGovernance(address _governance) external;
    function acceptGovernance() external;
    function setPrice(uint24 _price) external;
    function setManageFee(uint64 _manageFee) external;
    function setMinPeriod(uint64 _minPeriod) external;
    function setMaxPeriod(uint64 _maxPeriod) external;
    function setMaxCoverAmount(uint256 _maxCoverAmount) external;
    function setMaxCoverPerUser(uint256 _maxCoverPerUser) external;

    /**** UNIMPLEMENTED FUNCTIONS
    Functions that are only implemented by child product contracts
    ****/
    function appraisePosition(address _policyholder, address _positionContract) external view returns (uint256 positionAmount);

    /**** QUOTE VIEW FUNCTIONS
    View functions that give us quotes regarding a policy
    ****/
    function getQuote(address _policyholder, address _positionContract, uint256 _coverLimit, uint64 _blocks) external view returns (uint256);

    /**** MUTATIVE FUNCTIONS
    Functions that deploy and change policy contracts
    ****/
    function updateActiveCoverAmount(int256 _coverDiff) external;
    function buyPolicy(address _policyholder, address _positionContract, uint256 _coverLimit, uint64 _blocks) external payable returns (uint256 policyID);
    function updateCoverLimit(uint256 _policyID, uint256 _coverLimit) external payable;
    function extendPolicy(uint256 _policyID, uint64 _blocks) external payable;
    function cancelPolicy(uint256 _policyID) external;
}


// File contracts/products/BaseProduct.sol


pragma solidity 0.8.0;








/* TODO
 * - implement transferPolicy() so a user can transfer their LP tokens somewhere else and update that on their policy
 */

/**
 * @title BaseProduct
 * @author solace.fi
 * @notice To be inherited by individual Product contracts.
 */
abstract contract BaseProduct is IProduct, ReentrancyGuard {
    using Address for address;

    /// @notice Governor.
    address public override governance;
    /// @notice Governance to take over.
    address public override newGovernance;

    // Policy Manager
    IPolicyManager public policyManager; // Policy manager ERC721 contract

    IRegistry public registry;

    // Product Details
    address public override coveredPlatform; // a platform contract which locates contracts that are covered by this product
                                    // (e.g., UniswapProduct will have Factory as coveredPlatform contract, because
                                    // every Pair address can be located through getPool() function)
    uint256 public override maxCoverAmount; // maximum amount of coverage (in wei) this product can sell
    uint256 public override maxCoverPerUser;
    uint64 public override minPeriod; // minimum policy period in blocks
    uint64 public override maxPeriod; // maximum policy period in blocks
    uint64 public override manageFee; // policy cancelation fee
    uint24 public override price; // cover price (in wei) per block per wei (multiplied by 1e12 to avoid underflow upon construction or setter)

    // Book-keeping variables
    uint256 public override productPolicyCount; // total policy count this product sold
    uint256 public override activeCoverAmount; // current amount covered (in wei)

    mapping(address => bool) public isAuthorizedSigner;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IExchangeQuoter public quoter;
    bool public paused; // = false

    event SignerAdded(address _signer);
    event SignerRemoved(address _signer);
    event ClaimSubmitted(uint256 indexed policyId);

    constructor (
        IPolicyManager _policyManager,
        IRegistry _registry,
        address _coveredPlatform,
        uint256 _maxCoverAmount,
        uint256 _maxCoverPerUser,
        uint64 _minPeriod,
        uint64 _maxPeriod,
        uint64 _manageFee,
        uint24 _price,
        address _quoter
    ) {
        governance = msg.sender;
        policyManager = _policyManager;
        registry = _registry;
        coveredPlatform = _coveredPlatform;
        maxCoverAmount = _maxCoverAmount;
        maxCoverPerUser = _maxCoverPerUser;
        minPeriod = _minPeriod;
        maxPeriod = _maxPeriod;
        manageFee = _manageFee;
        price = _price;
        quoter = IExchangeQuoter(_quoter);
        productPolicyCount = 0;
        activeCoverAmount = 0;
    }

    /**** GETTERS + SETTERS
    Functions which get and set important product state variables
    ****/

    /**
     * @notice Allows governance to be transferred to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external override {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        newGovernance = _governance;
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external override {
        // can only be called by new governor
        require(msg.sender == newGovernance, "!governance");
        governance = newGovernance;
        newGovernance = address(0x0);
        emit GovernanceTransferred(msg.sender);
    }

    /**
     * @notice Sets the price for this product
     * @param _price cover price (in wei) per ether per block
     */
    function setPrice(uint24 _price) external override {
        require(msg.sender == governance, "!governance");
        price = _price;
    }

    /**
     * @notice Sets the fee that user must pay upon updating the policy
     * @param _manageFee policy management fee
     */
    function setManageFee(uint64 _manageFee) external override {
        require(msg.sender == governance, "!governance");
        manageFee = _manageFee;
    }

    /**
     * @notice Sets the minimum number of blocks a policy can be purchased for
     * @param _minPeriod minimum number of blocks
     */
    function setMinPeriod(uint64 _minPeriod) external override {
        require(msg.sender == governance, "!governance");
        minPeriod = _minPeriod;
    }

    /**
     * @notice Sets the maximum number of blocks a policy can be purchased for
     * @param _maxPeriod maximum number of blocks
     */
    function setMaxPeriod(uint64 _maxPeriod) external override {
        require(msg.sender == governance, "!governance");
        maxPeriod = _maxPeriod;
    }

    /**
     * @notice Sets the maximum coverage amount this product can provide to all users
     * @param _maxCoverAmount maximum coverage amount (in wei)
     */
    function setMaxCoverAmount(uint256 _maxCoverAmount) external override {
        require(msg.sender == governance, "!governance");
        maxCoverAmount = _maxCoverAmount;
    }

    /**
     * @notice Sets the maximum coverage amount this product can provide to a single user
     * @param _maxCoverPerUser maximum coverage amount (in wei)
     */
    function setMaxCoverPerUser(uint256 _maxCoverPerUser) external override {
        require(msg.sender == governance, "!governance");
        maxCoverPerUser = _maxCoverPerUser;
    }

    /**
     * @notice Sets a new ExchangeQuoter.
     * Can only be called by the current governor.
     * @param _quoter The new quoter address.
     */
    function setExchangeQuoter(address _quoter) external {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        quoter = IExchangeQuoter(_quoter);
    }

    function addSigner(address _signer) external {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        isAuthorizedSigner[_signer] = true;
        emit SignerAdded(_signer);
    }

    function removeSigner(address _signer) external {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        isAuthorizedSigner[_signer] = false;
        emit SignerRemoved(_signer);
    }

    /**
     * @notice Pauses or unpauses buying and extending policies.
     * Cancelling policies and submitting claims are unaffected by pause.
     * Can only be called by the current governor.
     * @dev Used for security and to gracefully phase out old products.
     */
    function setPaused(bool _pause) external {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        paused = _pause;
    }


    /**** UNIMPLEMENTED FUNCTIONS
    Functions that are only implemented by child product contracts
    ****/

    /**
     * @notice
     *  Provide the user's total position in the product's protocol.
     *  This total should be denominated in eth.
     * @dev
     *  Every product will have a different mechanism to read and determine
     *  a user's total position in that product's protocol. This method will
     *  only be implemented in the inheriting product contracts
     * @param _policyholder buyer requesting the coverage quote
     * @param _positionContract address of the exact smart contract the buyer has their position in (e.g., for UniswapProduct this would be Pair's address)
     * @return positionAmount The user's total position in wei in the product's protocol.
     */
    function appraisePosition(address _policyholder, address _positionContract) public view override virtual returns (uint256 positionAmount);

    /**** QUOTE VIEW FUNCTIONS
    View functions that give us quotes regarding a policy purchase
    ****/

    /**
     * @notice
     *  Provide a premium quote.
     * @param _coverLimit percentage (in BPS) of cover for total position
     * @param _blocks length for policy
     * @return premium The quote for their policy in wei.
     */
    function _getQuote(uint256 _coverLimit, uint64 _blocks, uint256 _positionAmount) internal view returns (uint256 premium){
        premium = _positionAmount * _coverLimit * _blocks * price / 1e16;
        return premium;
    }

    function getQuote(address _policyholder, address _positionContract, uint256 _coverLimit, uint64 _blocks) external view override returns (uint256){
        uint256 positionAmount = appraisePosition(_policyholder, _positionContract);
        return _getQuote(_coverLimit, _blocks, positionAmount);
    }

    /**** MUTATIVE FUNCTIONS
    Functions that change state variables, deploy and change policy contracts
    ****/


    /**
     * @notice Updates the product's book-keeping variables.
     * @param _coverDiff change in active cover amount
     */
    function updateActiveCoverAmount(int256 _coverDiff) external override {
        require(msg.sender == address(policyManager), "!policymanager");
        activeCoverAmount = add(activeCoverAmount, _coverDiff);
    }

    /**
     * @notice
     *  Purchase and deploy a policy on the behalf of the policyholder
     * @param _coverLimit percentage (in BPS) of cover for total position
     * @param _blocks length (in blocks) for policy
     * @param _policyholder who's liquidity is being covered by the policy
     * @param _positionContract contract address where the policyholder has a position to be covered
     * @return policyID The contract address of the policy
     */
    function buyPolicy(address _policyholder, address _positionContract, uint256 _coverLimit, uint64 _blocks) external payable override nonReentrant returns (uint256 policyID){
        require(!paused, "cannot buy when paused");
        // check that the buyer has a position in the covered protocol
        uint256 positionAmount = appraisePosition(_policyholder, _positionContract);
        require(positionAmount != 0, "zero position value");

        // check that the product can provide coverage for this policy
        uint256 coverAmount = _coverLimit * positionAmount / 1e4;
        require(activeCoverAmount + coverAmount <= maxCoverAmount, "max covered amount is reached");
        require(coverAmount <= maxCoverPerUser, "over max cover single user");

        // check that the buyer has paid the correct premium
        uint256 premium = _getQuote(_coverLimit, _blocks, positionAmount);
        require(msg.value >= premium && premium != 0, "insufficient payment or premium is zero");
        if(msg.value > premium) payable(msg.sender).transfer(msg.value - premium);

        // check that the buyer provided valid period and coverage limit
        require(_blocks >= minPeriod && _blocks <= maxPeriod, "invalid period");
        require(_coverLimit > 0 && _coverLimit <= 1e4, "invalid cover limit percentage");

        // transfer premium to the treasury

        ITreasury(payable(registry.treasury())).routePremiums{value: premium}();
        // create the policy
        uint64 expirationBlock = uint64(block.number + _blocks);
        policyID = policyManager.createPolicy(_policyholder, _positionContract, coverAmount, expirationBlock, price);

        // update local book-keeping variables
        activeCoverAmount += coverAmount;
        productPolicyCount++;

        emit PolicyCreated(policyID);

        return policyID;
    }

    /**
     * @notice
     *  Increase or decrease the cover limit for the policy
     * @param _policyID id number of the existing policy
     * @param _coverLimit new cover percentage
     */
    function updateCoverLimit(uint256 _policyID, uint256 _coverLimit) external payable override nonReentrant {
        require(!paused, "cannot buy when paused");
        (address policyholder, address product, address positionContract, uint256 previousCoverAmount, uint64 expirationBlock, uint24 previousPrice) = policyManager.getPolicyInfo(_policyID);
        // check msg.sender is policyholder, check for correct product, and that the coverageLimit is valid
        require(policyholder == msg.sender, "!policyholder");
        require(product == address(this), "wrong product");
        require(expirationBlock >= block.number, "policy is expired");
        require(_coverLimit > 0 && _coverLimit <= 1e4, "invalid cover limit percentage");

        //appraise the position
        uint256 positionAmount = appraisePosition(policyholder, positionContract);

        //calculate new coverAmount and check that the product can still provide coverage
        uint256 newCoverAmount = _coverLimit * positionAmount / 1e4;
        require(newCoverAmount <= maxCoverPerUser, "over max cover single user");
        require(activeCoverAmount + newCoverAmount - previousCoverAmount <= maxCoverAmount, "max covered amount is reached");

        //calculate premium needed for new cover amount as if policy is bought now
        uint256 remainingBlocks = expirationBlock - block.number;
        uint256 newPremium = newCoverAmount * remainingBlocks * price / 1e12;

        //calculate premium already paid based on current policy
        uint256 paidPremium = previousCoverAmount * remainingBlocks * previousPrice / 1e12;

        if (newPremium >= paidPremium) {
            uint256 premium = newPremium - paidPremium;
            // check that the buyer has paid the correct premium
            require(msg.value >= premium && premium != 0, "payment does not match the quote");
            // transfer premium to the treasury
            ITreasury(payable(registry.treasury())).routePremiums{value: premium}();
        } else {
            uint256 refundAmount = paidPremium - newPremium;
            require(refundAmount > manageFee, "refund amount > manage fee");
            ITreasury(payable(registry.treasury())).refund(msg.sender, refundAmount - manageFee);
        }
        // update policy's URI and emit event
        policyManager.setPolicyInfo(_policyID, policyholder, positionContract, newCoverAmount, expirationBlock, price);
        emit PolicyUpdated(_policyID);
    }

    /**
     * @notice
     *  Extend a policy contract
     * @param _policyID id number of the existing policy
     * @param _blocks length of extension
     */
    function extendPolicy(uint256 _policyID, uint64 _blocks) external payable override nonReentrant {
        require(!paused, "cannot extend when paused");
        // check that the msg.sender is the policyholder
        (address policyholder, address product, address positionContract, uint256 coverAmount, uint64 expirationBlock, uint24 price) = policyManager.getPolicyInfo(_policyID);
        require(policyholder == msg.sender,"!policyholder");
        require(product == address(this), "wrong product");
        require(expirationBlock >= block.number, "policy is expired");

        // compute the premium
        uint256 premium = coverAmount * _blocks * price / 1e12;
        // check that the buyer has paid the correct premium
        require(msg.value >= premium && premium != 0, "insufficient payment or premium is zero");
        if(msg.value > premium) payable(msg.sender).transfer(msg.value - premium);
        // transfer premium to the treasury
        ITreasury(payable(registry.treasury())).routePremiums{value: premium}();
        // check that the buyer provided valid period
        uint64 newExpirationBlock = expirationBlock + _blocks;
        uint64 duration = newExpirationBlock - uint64(block.number);
        require(duration >= minPeriod && duration <= maxPeriod, "invalid period");
        // update the policy's URI
        policyManager.setPolicyInfo(_policyID, policyholder, positionContract, coverAmount, newExpirationBlock, price);
        emit PolicyExtended(_policyID);
    }

    /**
     * @notice
     *  Cancel and destroy a policy.
     * @param _policyID id number of the existing policy
     */
    function cancelPolicy(uint256 _policyID) external override nonReentrant {
        (address policyholder, address product, , uint256 coverAmount, uint64 expirationBlock, uint24 price) = policyManager.getPolicyInfo(_policyID);
        require(policyholder == msg.sender,"!policyholder");
        require(product == address(this), "wrong product");

        uint64 blocksLeft = expirationBlock - uint64(block.number);
        uint256 refundAmount = blocksLeft * coverAmount * price / 1e12;
        require(refundAmount > manageFee, "refund amount less than cancelation fee");
        policyManager.burn(_policyID);
        ITreasury(payable(registry.treasury())).refund(msg.sender, refundAmount - manageFee);
        emit PolicyCanceled(_policyID);
    }

    /**
     * @notice Adds two numbers.
     * @param _a The first number as a uint256.
     * @param _b The second number as an int256.
     * @return _c The sum as a uint256.
     */
    function add(uint256 _a, int256 _b) internal pure returns (uint256 _c) {
        _c = (_b > 0)
            ? _a + uint256(_b)
            : _a - uint256(-_b);
    }
}


// File contracts/products/CompoundProductRinkeby.sol


pragma solidity 0.8.0;



interface IComptrollerRinkeby {
    function markets(address market) external view returns (bool isListed, uint256 collateralFactorMantissa);
}

interface ICToken {
    function balanceOf(address owner) external view returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function symbol() external view returns (string memory);
    function underlying() external view returns (address);
}

contract CompoundProductRinkeby is BaseProduct, EIP712 {
    using SafeERC20 for IERC20;

    IComptrollerRinkeby public comptroller;
    bytes32 private immutable _EXCHANGE_TYPEHASH = keccak256("CompoundProductExchange(uint256 policyId,address tokenIn,uint256 amountIn,address tokenOut,uint256 amountOut,uint256 deadline)");

    constructor (
        IPolicyManager _policyManager,
        IRegistry _registry,
        address _coveredPlatform,
        uint256 _maxCoverAmount,
        uint256 _maxCoverPerUser,
        uint64 _minPeriod,
        uint64 _maxPeriod,
        uint64 _cancelFee,
        uint24 _price,
        address _quoter
    ) BaseProduct(
        _policyManager,
        _registry,
        _coveredPlatform,
        _maxCoverAmount,
        _maxCoverPerUser,
        _minPeriod,
        _maxPeriod,
        _cancelFee,
        _price,
        _quoter
    ) EIP712("solace.fi compound product", "1") {
        comptroller = IComptrollerRinkeby(_coveredPlatform);
    }

    /**
     * @notice Sets a new Comptroller.
     * Can only be called by the current governor.
     * @param _comptroller The new comptroller address.
     */
    function setComptroller(address _comptroller) external {
        // can only be called by governor
        require(msg.sender == governance, "!governance");
        comptroller = IComptrollerRinkeby(_comptroller);
    }

    // _positionContract must be a cToken including cETH
    // see https://compound.finance/markets
    // and https://etherscan.io/accounts/label/compound
    function appraisePosition(address _policyholder, address _positionContract) public view override returns (uint256 positionAmount) {
        // verify _positionContract
        (bool isListed, ) = comptroller.markets(_positionContract);
        require(isListed, "Invalid position contract");
        // swap math
        ICToken token = ICToken(_positionContract);
        uint256 balance = token.balanceOf(_policyholder);
        uint256 exchangeRate = token.exchangeRateStored();
        balance = balance * exchangeRate / 1e18;
        if(compareStrings(token.symbol(), "cETH")) return balance;
        return quoter.tokenToEth(token.underlying(), balance);
    }

    // TODO: allow for multiple tokens in and out
    function submitClaim(
        uint256 policyId,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        uint256 deadline,
        bytes calldata signature
    ) external payable {
        // TODO: check for duplicate claim
        // validate inputs
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "expired deadline");
        (address policyholder, address product, , , , ) = policyManager.getPolicyInfo(policyId);
        require(policyholder == msg.sender, "!policyholder"); // TODO: allow submit by paclas?
        require(product == address(this), "wrong product");
        // verify signature
        {
        bytes32 structHash = keccak256(abi.encode(_EXCHANGE_TYPEHASH, policyId, tokenIn, amountIn, tokenOut, amountOut, deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        require(isAuthorizedSigner[signer], "invalid signature");
        }
        // pull tokens
        if(tokenIn == ETH_ADDRESS) {
            require(msg.value >= amountIn);
            ITreasury(payable(registry.treasury())).routePremiums{value: msg.value}();
        }
        else IERC20(tokenIn).safeTransferFrom(msg.sender, registry.treasury(), amountIn);
        // submit claim to ClaimsEscrow
        // TODO: only allowed tokenOut is eth, allow for others
        IVault(registry.vault()).processClaim(policyholder, amountOut);
        emit ClaimSubmitted(policyId);
    }

    /**
     * @notice String equality.
     * @param a The first string.
     * @param b The second string.
     * @return True if equal.
     */
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}