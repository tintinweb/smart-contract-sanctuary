/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    
    struct UserInfo {
        uint256 rewardDebt;
        uint256 reward;
        uint256 amount;
    }
    uint8 private _decimals;
    address public _owner;
	bool public burnSwitch;
    bool public lockSwitch;
    uint256 public totalReward;
    uint256 public accTokenPerShare;
    uint256 public createTime;
    uint256 public finalSupply;
    
    address public oldTokenAddr;
    
    bool public tradeSwitch;
    uint256 public tradeTime;
    
    bool public gameSwitch;
    uint256 public gameTime;
    
    address public LpTokenAddress;
    address public UsdtAddress;
    
    address public returnPoolAddress;
    address public nodeAddress;
    
    /* organization */
    uint256 public OrgRatio = 5;
    uint256 public OrgLockAmount;
    address public OrgAddress;
    
    /* public offer */
    uint256 public publicOfferRatio = 10;
    uint256 public publicOfferLockAmount;
    address public publicOfferAddress;
    /* game lab */
    uint256 public gameLabRatio = 5;
    uint256 public gameLabLockAmount;
    address public gameLabAddress;
    /* foundation */
    uint256 public foundationRatio = 5;
    uint256 public foundationLockAmount;
    address public foundationAddress;
    /* air drop */
    address public airDropAddress;
    
    mapping(address => UserInfo) public userInfos;
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    mapping(address => bool) public executorList;
    mapping(string => bool) public usedInvoiceIds;
    
    event GetToken(address indexed user, string indexed invoiceId, uint256 amount);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint8 decimals_, address oldTokenAddr_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        _decimals = decimals_;
        oldTokenAddr = oldTokenAddr_;
		burnSwitch = false;
        lockSwitch = true;
        createTime = block.timestamp;
        executorList[msg.sender] = true;
    }
    
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    
    function exchangeToken() public{
        IERC20 oldToken = IERC20(oldTokenAddr);
        uint256 amount = oldToken.balanceOf(msg.sender);
        uint256 approveAmount = oldToken.allowance(msg.sender, address(this));
        uint256 exchangeAmount = approveAmount >= amount ? amount : approveAmount;
        require( exchangeAmount > 0, "invalid exchangeAmount!" );
        oldToken.safeTransferFrom(msg.sender,address(this),exchangeAmount);
        _transfer(address(this),msg.sender,exchangeAmount,false);
    }
    
    function setAddresses(address orgAddr,address publicOfferAddr,address gameLabAddr, address foundationAddr, address airDropAddr, address returnPoolAddr, address nodeAddr, address LpTokenAddr, address usdtAddr) public onlyExecutor {
        if(orgAddr != address(0x0)){
            OrgAddress = orgAddr;
        }
        if(publicOfferAddr != address(0x0)){
            publicOfferAddress = publicOfferAddr;
        }
        if(gameLabAddr != address(0x0)){
            gameLabAddress = gameLabAddr;
        }
        if(foundationAddr != address(0x0)){
            foundationAddress = foundationAddr;
        }
        if(airDropAddr != address(0x0)){
            airDropAddress = airDropAddr;
        }
        if(returnPoolAddr != address(0x0)){
            returnPoolAddress = returnPoolAddr;
        }
        if(nodeAddr != address(0x0)){
            nodeAddress = nodeAddr;
        }
        if(LpTokenAddr != address(0x0)){
            LpTokenAddress = LpTokenAddr;
        }
        if(usdtAddr != address(0x0)){
            UsdtAddress = usdtAddr;
        }
    }
    
    function getTokens(string calldata _invoiceId, uint256 _amount, bytes memory _sig) public {
        require( !usedInvoiceIds[_invoiceId], "invoiceId exists!" );
        usedInvoiceIds[_invoiceId] = true;
        bytes32 hash = getHash(msg.sender,_invoiceId, _amount);
        address signer = hash.recover(_sig);
        require( executorList[signer], "invalid signer" );
        _transfer(address(this),msg.sender,_amount, true);
        emit GetToken(msg.sender, _invoiceId, _amount);
    }
    
    function getLockAmount(address account, uint256 timestamp) public view returns (uint256){
        if(timestamp == 0){
            timestamp = block.timestamp;
        }
        require(timestamp >= createTime, "invalid timestamp!");
        uint256 unlockAmount = 0;
        if(lockSwitch){
            if(account == publicOfferAddress){
                if(!tradeSwitch) return publicOfferLockAmount;
                unlockAmount = publicOfferLockAmount * 15 / 100;
                if(!gameSwitch || timestamp <= gameTime) return (publicOfferLockAmount - unlockAmount);
                uint256 diff = timestamp - gameTime;
                if(diff >= (10 days)){
                    unlockAmount += publicOfferLockAmount * 10 / 100;
                    diff -= (10 days);
                    uint256 periods = diff / (30 days);
                    unlockAmount += publicOfferLockAmount * periods * 50 / 1000;
                }
                if(unlockAmount >= publicOfferLockAmount) return 0;
                return (publicOfferLockAmount - unlockAmount);
            }else if(account == OrgAddress){
                if(!tradeSwitch) return OrgLockAmount;
                unlockAmount = OrgLockAmount * 15 / 100;
                if(!gameSwitch || timestamp <= gameTime) return (OrgLockAmount - unlockAmount);
                uint256 diff = timestamp - gameTime;
                if(diff >= (10 days)){
                    unlockAmount += OrgLockAmount * 10 / 100;
                    diff -= (10 days);
                    uint256 periods = diff / (30 days);
                    unlockAmount += OrgLockAmount * periods * 50 / 1000;
                }
                if(unlockAmount >= OrgLockAmount) return 0;
                return (OrgLockAmount - unlockAmount);
            }else if(account == gameLabAddress){
                if(!gameSwitch || timestamp < (gameTime+(90 days))) return gameLabLockAmount;
                unlockAmount = gameLabLockAmount * 9 / 100;
                uint256 diff = timestamp - gameTime - (90 days);
                uint256 periods = diff / (30 days);
                unlockAmount += gameLabLockAmount * periods * 35 / 1000;
                if(unlockAmount >= gameLabLockAmount) return 0;
                return (gameLabLockAmount - unlockAmount);
            }else if(account == foundationAddress){
                if(!gameSwitch || timestamp < (gameTime+(90 days))) return foundationLockAmount;
                unlockAmount = foundationLockAmount * 9 / 100;
                uint256 diff = timestamp - gameTime - (90 days);
                uint256 periods = diff / (30 days);
                unlockAmount += foundationLockAmount * periods * 35 / 1000;
                if(unlockAmount >= foundationLockAmount) return 0;
                return (foundationLockAmount - unlockAmount);
            }else if(account == airDropAddress){
                if((createTime + (90 days)) <= timestamp) return _balances[airDropAddress];
                return 0;
            }
        }
        return 0;
    }
    
    modifier checkLockAccount(address account, uint256 amount) {
        uint256 lockAmount = getLockAmount(account, 0);
        if(lockAmount > 0){
            uint256 currAmount = _balances[account];
            require( (lockAmount+amount) <= currAmount, "Lock!");
        }
        _;
    }
    
    function getFee() public view returns(uint256){
        if(LpTokenAddress == address(0x0) || UsdtAddress == address(0x0)) return 6;
        IERC20 usdt = IERC20(UsdtAddress);
        uint256 usdtAmount = usdt.balanceOf(LpTokenAddress);
        if(usdtAmount >= 50000000 * (10 ** 18)) return 1;
        else if(usdtAmount >= 20000000 * (10 ** 18)) return 2;
        else if(usdtAmount >= 10000000 * (10 ** 18)) return 3;
        else if(usdtAmount >= 5000000 * (10 ** 18)) return 4;
        else if(usdtAmount >= 2000000 * (10 ** 18)) return 5;
        return 6;
    }
    
    function getHash(address _userAddr, string calldata _invoiceId, uint256 _amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_userAddr,_invoiceId, _amount));
    }
    
    function transferOwnerShip(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }
	
	function setBurnSwitch(bool _v) public onlyExecutor {
		burnSwitch = _v;
	}
    
    function setLockSwitch(bool _v) public onlyExecutor {
		lockSwitch = _v;
	}
    
    function startTrade() public onlyExecutor {
		tradeSwitch = true;
        tradeTime = block.timestamp;
	}
    
    function startGame() public onlyExecutor {
		gameSwitch = true;
        gameTime = block.timestamp;
	}

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account] + getAccountRewards(account);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount, true);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, true);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount, bool takeFee) checkLockAccount(sender, amount) internal virtual {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        withdrawRewards(sender);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "transfer amount exceeds balance");
        uint256 feeAmount = 0;
        uint256 burnAmount = 0;
        uint256 poolAmount = 0;
        uint256 rewardAmount = 0;
        uint256 nodeAmount = 0;
        if(takeFee && burnSwitch && _totalSupply > finalSupply){
            uint256 fee = getFee();
            feeAmount = amount * fee / 100;
            poolAmount = feeAmount / 3;
            rewardAmount = feeAmount / 6;
            nodeAmount = feeAmount / 6;
            uint256 t = poolAmount + rewardAmount + nodeAmount;
            if(t < feeAmount){
                burnAmount = feeAmount - t;
            }
        }
        withdrawLP(sender,amount);
        _balances[sender] = senderBalance - (amount - burnAmount);
        if(rewardAmount > 0){
            _balances[address(this)] += rewardAmount;
            addRewards(rewardAmount);
        }
        _balances[recipient] += (amount - feeAmount);
        depositLP(recipient, (amount - feeAmount));
        _balances[returnPoolAddress] += poolAmount;
        depositLP(returnPoolAddress, poolAmount);
        _balances[nodeAddress] += nodeAmount;
        depositLP(nodeAddress, nodeAmount);
        if(burnAmount > 0){
            _burn(sender, burnAmount);
        }

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        OrgLockAmount = amount * OrgRatio / 100;
        publicOfferLockAmount = amount * publicOfferRatio / 100;
        gameLabLockAmount = amount * gameLabRatio / 100;
        foundationLockAmount = amount * foundationRatio / 100;
        
        _totalSupply += amount;
        finalSupply = finalSupply + (amount * 10) / 100;
        _balances[account] += amount;
        depositLP(account, amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    function addRewards(uint256 _amount) private {
        uint256 lpSupply = totalSupply();
        if(lpSupply == 0){
            return;
        }
        totalReward += _amount;
        accTokenPerShare = accTokenPerShare + _amount * (1e12) / lpSupply;
    }
    
    function getAccountRewards(address _user)
        private
        view
        returns (uint256)
    {
        UserInfo storage user = userInfos[_user];
        return user.amount * accTokenPerShare / (1e12) - user.rewardDebt + user.reward;
    }
    
    function depositLP(address _user, uint256 _amount) private{
        UserInfo storage user = userInfos[_user];
        if (user.amount > 0) {
            uint256 pending =
                user.amount * accTokenPerShare / (1e12) - user.rewardDebt;
            user.reward += pending;
        }
        user.amount = user.amount + _amount;
        user.rewardDebt = user.amount * accTokenPerShare / (1e12);
    }
    
    function withdrawLP(address _user, uint256 _amount) private {
        UserInfo storage user = userInfos[_user];
        require(user.amount >= _amount, "withdrawLP : amount??");
        uint256 pending =
            user.amount * accTokenPerShare / (1e12) - user.rewardDebt;
        user.reward += pending;
        user.amount = user.amount - _amount;
        user.rewardDebt = user.amount * accTokenPerShare / (1e12);
        if(user.amount == 0){
            require(totalReward >= user.reward, "totalReward ??");
            _balances[address(this)] -= user.reward;
            _balances[_user] += user.reward;
            depositLP(_user, user.reward);
            totalReward -= user.reward;
            user.reward = 0;
        }
    }
    
    function withdrawRewards(address _user) private{
        UserInfo storage user = userInfos[_user];
        uint256 pending =
            user.amount * accTokenPerShare / (1e12) - user.rewardDebt;
        user.reward += pending;
        user.rewardDebt = user.amount * accTokenPerShare / (1e12);
        require(totalReward >= user.reward, "totalReward ??");
        _balances[address(this)] -= user.reward;
        _balances[_user] += user.reward;
        depositLP(_user, user.reward);
        totalReward -= user.reward;
        user.reward = 0;
    }
    
    function transferToken(address _tokenAddr, address _toAddr, uint256 _amount) public onlyOwner {
        if(_tokenAddr != address(0)){
            IERC20 token = IERC20(_tokenAddr);
            token.safeTransfer(_toAddr, _amount);
        }else{
            payable(_toAddr).transfer(_amount);
        }
    }
    
    function addExecutor(address _newExecutor) onlyOwner public {
        executorList[_newExecutor] = true;
    }
    
    function delExecutor(address _oldExecutor) onlyOwner public {
        executorList[_oldExecutor] = false;
    }
    
    modifier onlyExecutor {
        require(executorList[msg.sender]);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}

contract Token is ERC20 {
    constructor (uint256 _initialSupply, string memory _tokenName, string memory _tokenSymbol, uint8 _tokenDecimals, address _oldToken)
        ERC20(_tokenName,_tokenSymbol, _tokenDecimals, _oldToken) {
        _mint(msg.sender, _initialSupply * 10 ** uint256(_tokenDecimals));
    }
}