// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Multi Send Call Only - Allows to batch multiple transactions into one, but only calls
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
/// @notice The guard logic is not required here as this contract doesn't support nested delegate calls
contract MultiSendCallOnly {
    /// @dev Sends multiple transactions and reverts all if one fails.
    /// @param transactions Encoded transactions. Each transaction is encoded as a packed bytes of
    ///                     operation has to be uint8(0) in this version (=> 1 byte),
    ///                     to as a address (=> 20 bytes),
    ///                     value as a uint256 (=> 32 bytes),
    ///                     data length as a uint256 (=> 32 bytes),
    ///                     data as bytes.
    ///                     see abi.encodePacked for more information on packed encoding
    /// @notice The code is for most part the same as the normal MultiSend (to keep compatibility),
    ///         but reverts if a transaction tries to use a delegatecall.
    /// @notice This method is payable as delegatecalls keep the msg.value from the previous call
    ///         If the calling method (e.g. execTransaction) received ETH this would revert otherwise
    function multiSend(bytes memory transactions) public payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let length := mload(transactions)
            let i := 0x20
            for {
                // Pre block is not used in "while mode"
            } lt(i, length) {
                // Post block is not used in "while mode"
            } {
                // First byte of the data is the operation.
                // We shift by 248 bits (256 - 8 [operation byte]) it right since mload will always load 32 bytes (a word).
                // This will also zero out unused data.
                let operation := shr(0xf8, mload(add(transactions, i)))
                // We offset the load address by 1 byte (operation byte)
                // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align the data and zero out unused data.
                let to := shr(0x60, mload(add(transactions, add(i, 0x01))))
                // We offset the load address by 21 byte (operation byte + 20 address bytes)
                let value := mload(add(transactions, add(i, 0x15)))
                // We offset the load address by 53 byte (operation byte + 20 address bytes + 32 value bytes)
                let dataLength := mload(add(transactions, add(i, 0x35)))
                // We offset the load address by 85 byte (operation byte + 20 address bytes + 32 value bytes + 32 data length bytes)
                let data := add(transactions, add(i, 0x55))
                let success := 0
                switch operation
                    case 0 {
                        success := call(gas(), to, value, data, dataLength, 0, 0)
                    }
                    // This version does not allow delegatecalls
                    case 1 {
                        revert(0, 0)
                    }
                if eq(success, 0) {
                    revert(0, 0)
                }
                // Next entry starts at 85 byte + data length
                i := add(i, add(0x55, dataLength))
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "./interfaces/ITransactionManager.sol";
import "./lib/LibAsset.sol";
import "./lib/LibERC20.sol";
import "./lib/LibIterableMapping.sol";
import "@gnosis.pm/safe-contracts/contracts/libraries/MultiSendCallOnly.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TransactionManager is ReentrancyGuard, ITransactionManager {

    using LibIterableMapping for LibIterableMapping.IterableMapping;

    // Mapping of router to balance specific to asset
    mapping(address => mapping(address => uint256)) public routerBalances;

    /// @notice  Contains all the variable parts of a transaction, and a block
    ///          number to look up the rest of the data via events. The 
    ///          variable parts of the transaction data cannot be signed in the 
    ///          digest, since then the digest and signature would be different 
    ///          for sending and receiving chains. Must be iterable so user can
    ///          always pull their pending transactions without knowing the 
    ///          digest.
    LibIterableMapping.IterableMapping activeTransactions;

    /// @dev The chain id of the contract, is passed in to avoid any evm issues
    uint24 public immutable chainId;

    /// @dev Address of the deployed multisending helper contract
    address public immutable multisend;

    // TODO: determine min timeout
    uint256 public constant MIN_TIMEOUT = 0;

    constructor(address _multisend, uint24 _chainId) {
        multisend = _multisend;
        chainId = _chainId;
    }

    /// @dev returns all active transactions for a given user
    function getActiveTransactionsByUser(address user) external view override returns (VariableTransactionData[] memory) {
      return activeTransactions.getTransactionsByUser(user);
    }

    /// @param amount The amount of liquidity to add for the router
    /// @param assetId The address (or `address(0)` if native asset) of the
    ///                asset you're adding liquidity for
    function addLiquidity(uint256 amount, address assetId)
        external  
        payable 
        override 
        nonReentrant
    {
        // Validate correct amounts are transferred
        if (LibAsset.isEther(assetId)) {
            require(msg.value == amount, "addLiquidity: VALUE_MISMATCH");
        } else {
            require(msg.value == 0, "addLiquidity: ETH_WITH_ERC_TRANSFER");
            require(
                LibERC20.transferFrom(
                    assetId,
                    msg.sender,
                    address(this),
                    amount
                ),
                "addLiquidity: ERC20_TRANSFER_FAILED"
            );
        }

        // Update the router balances
        routerBalances[msg.sender][assetId] += amount;

        // Emit event
        emit LiquidityAdded(msg.sender, assetId, amount);
    }

    function removeLiquidity(uint256 amount, address assetId, address payable recipient)
        external
        override
        nonReentrant
    {
        // Check that the amount can be deducted for the router
        // TODO is this check worth the extra gas?
        require(routerBalances[msg.sender][assetId] >= amount, "removeLiquidity: INSUFFICIENT_FUNDS");

        // Update router balances
        routerBalances[msg.sender][assetId] -= amount;

        // Transfer from contract to router
        require(LibAsset.transferAsset(assetId, recipient, amount), "removeLiquidity: TRANSFER_FAILED");

        // Emit event
        emit LiquidityRemoved(msg.sender, assetId, amount, recipient);
    }

    function prepare(
        InvariantTransactionData calldata txData,
        uint256 amount,
        uint256 expiry
    ) external payable override nonReentrant returns (InvariantTransactionData memory) {
        // Make sure the expiry is greater than min
        require((expiry - block.timestamp) >= MIN_TIMEOUT, "prepare: TIMEOUT_TOO_LOW");

        // Make sure the chains are different
        require(txData.sendingChainId != txData.receivingChainId, "prepare: SAME_CHAINIDS");

        // Make sure the chains are relevant
        require(txData.sendingChainId == chainId || 
            txData.receivingChainId == chainId, "prepare: INVALID_CHAINIDS");

        // Sanity check: valid fallback
        require(txData.receivingAddress != address(0), "prepare: INVALID_RECEIVING_ADDRESS");
        
        // Make sure the hash is not a duplicate
        bytes32 digest = hashTransactionData(txData);
        require(!activeTransactions.digestExists(digest), "prepare: DUPLICATE_DIGEST");

        // First determine if this is sender side or receiver side
        if (txData.sendingChainId == chainId) {
            // This is sender side prepare

            // Validate correct amounts and transfer
            if (LibAsset.isEther(txData.sendingAssetId)) {
                require(msg.value == amount, "prepare: VALUE_MISMATCH");
            } else {
                require(msg.value == 0, "prepare: ETH_WITH_ERC_TRANSFER");
                require(
                    LibERC20.transferFrom(
                        txData.sendingAssetId,
                        msg.sender,
                        address(this),
                        amount
                    ),
                    "prepare: ERC20_TRANSFER_FAILED"
                );
            }
        } else {
            // This is receiver side prepare

            // Check that the caller is the router
            require(msg.sender == txData.router, "prepare: ROUTER_MISMATCH");
            require(msg.value == 0, "prepare: ETH_WITH_ROUTER_PREPARE");

            // Check that router has liquidity
            // TODO do we need explicit check vs implicit from safemath below?
            require(routerBalances[txData.router][txData.receivingAssetId] >= amount, "prepare: INSUFFICIENT_LIQUIDITY");

            // NOTE: Timeout and amounts should have been decremented offchain

            // NOTE: after some consideration, it feels like it's better to leave amount/fee
            // validation *outside* the contracts as we likely want the logic to be flexible

            // Pull funds from router balance (use msg.sender here to mitigate 3rd party attack)

            // What would happen if some router tried to swoop in and steal another router's spot?
            // - 3rd party router could EITHER use original txData or replace txData.router with itself
            // - if original txData, 3rd party router would basically be paying for original router
            // - if relaced router address, user sig on digest would not unlock sender side
            routerBalances[txData.router][txData.receivingAssetId] -= amount;
        }

        // Store the transaction variants
        activeTransactions.addTransaction(
          VariableTransactionData({ amount: amount, expiry: expiry, digest: digest, user: txData.user, blockNumber: block.number })
        );

        // Emit event
        emit TransactionPrepared(txData, amount, expiry, block.number, msg.sender);
        return txData;
    }

    function fulfill(
        InvariantTransactionData calldata txData,
        uint256 relayerFee,
        bytes calldata signature // signature on fee + digest
    ) external override nonReentrant returns (InvariantTransactionData memory) {
        // Make sure params match against stored data
        // Also checks that there is an active transfer here
        // Also checks that sender or receiver chainID is this chainId (bc we 
        // checked it previously)
        bytes32 digest = hashTransactionData(txData);

        // Retrieving this will revert if the record does not exist by the
        // digest (which asserts all but tx.amount, tx.expiry)
        VariableTransactionData memory record = activeTransactions.getTransactionByDigest(digest);

        require(record.expiry > block.timestamp, "fulfill: EXPIRED");

        // Validate signature
        require(recoverFulfillSignature(txData, relayerFee, signature) == txData.user, "fulfill: INVALID_SIGNATURE");

        // Sanity check: fee < amount
        // TODO: Do we need this check? Safemath would catch it below
        require(relayerFee < record.amount, "fulfill: INVALID_RELAYER_FEE");

        // Remove the active transaction
        activeTransactions.removeTransaction(digest);
    
        if (txData.sendingChainId == chainId) {
            // Complete tx to router
            // NOTE: there is no fee taken on the sending side for the relayer
            routerBalances[txData.router][txData.sendingAssetId] += record.amount;
        } else {
            // Complete tx to user
            // Get the amount to send
            uint256 toSend = record.amount - relayerFee;

            // Send the relayer the fee
            if (relayerFee > 0) {
                require(LibAsset.transferAsset(txData.receivingAssetId, payable(msg.sender), relayerFee), "fulfill: FEE_TRANSFER_FAILED");
            }

            if (keccak256(txData.callData) == keccak256(new bytes(0))) {
                // No external calls, send directly to receiving address
                require(LibAsset.transferAsset(txData.receivingAssetId, payable(txData.receivingAddress), toSend), "fulfill: TRANSFER_FAILED");
            } else {
                // Handle external calls with a fallback to the receiving
                // address
                // TODO: This would allow us to execute an arbitrary transfer to drain the contracts
                // We'll need to change this to use vector pattern with *explicit* amount.
                try MultiSendCallOnly(multisend).multiSend(txData.callData) {
                } catch {
                  require(LibAsset.transferAsset(txData.receivingAssetId, payable(txData.receivingAddress), toSend), "fulfill: TRANSFER_FAILED");
                }
            }
        }

        // Emit event
        emit TransactionFulfilled(txData, record.amount, record.expiry, record.blockNumber, relayerFee, signature, msg.sender);

        return txData;
    }

    // Tx can be "collaboratively" cancelled by the receiver at any time and by the sender after expiry
    function cancel(
        InvariantTransactionData calldata txData,
        bytes calldata signature
    ) external override nonReentrant returns (InvariantTransactionData memory) {     
        // Make sure params match against stored data
        // Also checks that there is an active transfer here
        // Also checks that sender or receiver chainID is this chainId (bc we checked it previously)
        bytes32 digest = hashTransactionData(txData);
        
        // Retrieving this will revert if the record does not exist by the
        // digest (which asserts all but tx.amount, tx.expiry)
        VariableTransactionData memory record = activeTransactions.getTransactionByDigest(digest);

        if (txData.sendingChainId == chainId) {
            // Sender side --> funds go back to user
            if (record.expiry >= block.timestamp) {
                // Timeout has not expired and tx may only be cancelled by router
                require(msg.sender == txData.router, "cancel: ROUTER_MUST_CANCEL");
            }
            // Return to user
            require(LibAsset.transferAsset(txData.sendingAssetId, payable(txData.user), record.amount), "cancel: TRANSFER_FAILED");

        } else {
            // Receiver side --> funds go back to router
            if (record.expiry >= block.timestamp) {
                // Timeout has not expired and tx may only be cancelled by user
                // Validate signature
                require(recoverCancelSignature(txData, signature) == txData.user, "cancel: INVALID_SIGNATURE");
            }
            // Return to router
            routerBalances[txData.router][txData.receivingAssetId] += record.amount;
        }

        // Remove the active transaction
        activeTransactions.removeTransaction(digest);

        // Emit event
        emit TransactionCancelled(txData, record.amount, record.expiry, record.blockNumber, msg.sender);

        // Return
        return txData;
    }

    // Private functions
    function recoverFulfillSignature(
      InvariantTransactionData calldata txData,
      uint256 relayerFee,
      bytes calldata signature
    ) internal pure returns (address) {
      // Create the digest
      bytes32 txDigest = hashTransactionData(txData);

      // Create the signed payload
      SignedFulfillData memory payload = SignedFulfillData({
        txDigest: txDigest,
        relayerFee: relayerFee
      });

      bytes32 signed = keccak256(abi.encode(payload));
      // Recover
      return ECDSA.recover(ECDSA.toEthSignedMessageHash(signed), signature);
    }

    function recoverCancelSignature(
      InvariantTransactionData calldata txData,
      bytes calldata signature
    ) internal pure returns (address) {
      // Create the digest
      bytes32 txDigest = hashTransactionData(txData);

      // Create the signed payload
      SignedCancelData memory payload = SignedCancelData({
        txDigest: txDigest,
        cancel: "cancel"
      });

      // Recover
      bytes32 signed = keccak256(abi.encode(payload));
      // Recover
      return ECDSA.recover(ECDSA.toEthSignedMessageHash(signed), signature);
    }

    function hashTransactionData(InvariantTransactionData calldata txData)
        internal
        pure
        returns (bytes32)
    {
        InvariantTransactionData memory data = InvariantTransactionData({
          user: txData.user,
          router: txData.router,
          sendingAssetId: txData.sendingAssetId,
          receivingAssetId: txData.receivingAssetId,
          sendingChainId: txData.sendingChainId,
          receivingChainId: txData.receivingChainId,
          receivingAddress: txData.receivingAddress,
          callData: txData.callData,
          transactionId: txData.transactionId
        });
        return keccak256(abi.encode(data));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;


struct VariableTransactionData {
  address user;
  uint256 amount;
  uint256 expiry;
  uint256 blockNumber;
  bytes32 digest;
}

interface ITransactionManager {
  // Structs
  // TODO: Add bid data if needed?
  // TODO: make this structure invariant *only* (consolidate with below)
  // Then, we can pass in amount/expiry explicitly and use only the record values
  // which will reduce duplication/confusion
  struct InvariantTransactionData {
    address user;
    address router;
    address sendingAssetId;
    address receivingAssetId;
    address receivingAddress;
    uint24 sendingChainId;
    uint24 receivingChainId;
    bytes callData;
    bytes32 transactionId;
  }

  struct SignedCancelData {
    bytes32 txDigest;
    string cancel;
  }

  struct SignedFulfillData {
    bytes32 txDigest;
    uint256 relayerFee;
  }

  // Liquidity events
  event LiquidityAdded(
    address router,
    address assetId,
    uint256 amount
  );

  event LiquidityRemoved(
    address router,
    address assetId,
    uint256 amount,
    address recipient
  );

  // Transaction events
  // TODO: structure
  event TransactionPrepared(
    InvariantTransactionData txData,
    uint256 amount,
    uint256 expiry,
    uint256 blockNumber,
    address caller
  );

  event TransactionFulfilled(
    InvariantTransactionData txData,
    uint256 amount,
    uint256 expiry,
    uint256 blockNumber,
    uint256 relayerFee,
    bytes signature,
    address caller
  );

  event TransactionCancelled(
    InvariantTransactionData txData,
    uint256 amount,
    uint256 expiry,
    uint256 blockNumber,
    address caller
  );

  // Getters
  function getActiveTransactionsByUser(address user) external view returns (VariableTransactionData[] memory);

  // Router only methods
  function addLiquidity(uint256 amount, address assetId) external payable;

  function removeLiquidity(uint256 amount, address assetId, address payable recipient) external;

  // Transaction methods
  function prepare(InvariantTransactionData calldata txData, uint256 amount, uint256 expiry) external payable returns (InvariantTransactionData memory);

  function fulfill(InvariantTransactionData calldata txData, uint256 relayerFee, bytes calldata signature) external returns (InvariantTransactionData memory);

  function cancel(InvariantTransactionData calldata txData, bytes calldata signature) external returns (InvariantTransactionData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "./LibERC20.sol";
import "./LibUtils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title LibAsset
/// @author Connext <[email protected]>
/// @notice This library contains helpers for dealing with onchain transfers
///         of in-channel assets. It is designed to safely handle all asset
///         transfers out of channel in the event of an onchain dispute. Also
///         safely handles ERC20 transfers that may be non-compliant
library LibAsset {
    address constant ETHER_ASSETID = address(0);

    function isEther(address assetId) internal pure returns (bool) {
        return assetId == ETHER_ASSETID;
    }

    function getOwnBalance(address assetId) internal view returns (uint256) {
        return
            isEther(assetId)
                ? address(this).balance
                : IERC20(assetId).balanceOf(address(this));
    }

    function transferEther(address payable recipient, uint256 amount)
        internal
        returns (bool)
    {
        (bool success, bytes memory returnData) =
            recipient.call{value: amount}("");
        LibUtils.revertIfCallFailed(success, returnData);
        return true;
    }

    function transferERC20(
        address assetId,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        return LibERC20.transfer(assetId, recipient, amount);
    }

    // This function is a wrapper for transfers of Ether or ERC20 tokens,
    // both standard-compliant ones as well as tokens that exhibit the
    // missing-return-value bug.
    function transferAsset(
        address assetId,
        address payable recipient,
        uint256 amount
    ) internal returns (bool) {
        return
            isEther(assetId)
                ? transferEther(recipient, amount)
                : transferERC20(assetId, recipient, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "./LibUtils.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title LibERC20
/// @author Connext <[email protected]>
/// @notice This library provides several functions to safely handle
///         noncompliant tokens (i.e. does not return a boolean from
///         the transfer function)

library LibERC20 {
    function wrapCall(address assetId, bytes memory callData)
        internal
        returns (bool)
    {
        require(Address.isContract(assetId), "LibERC20: NO_CODE");
        (bool success, bytes memory returnData) = assetId.call(callData);
        LibUtils.revertIfCallFailed(success, returnData);
        return returnData.length == 0 || abi.decode(returnData, (bool));
    }

    function approve(
        address assetId,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        return
            wrapCall(
                assetId,
                abi.encodeWithSignature(
                    "approve(address,uint256)",
                    spender,
                    amount
                )
            );
    }

    function transferFrom(
        address assetId,
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        return
            wrapCall(
                assetId,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    sender,
                    recipient,
                    amount
                )
            );
    }

    function transfer(
        address assetId,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        return
            wrapCall(
                assetId,
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    recipient,
                    amount
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "../interfaces/ITransactionManager.sol";

/// @title LibIterableMapping
/// @author Connext <[email protected]>
/// @notice This library provides an efficient way to store and retrieve
///         VariableTransactionData. This contract is used to manage the 
///         transactions stored by `TransactionManager.sol`
library LibIterableMapping {
    struct VariableTransactionDataWithIndex {
        VariableTransactionData transaction;
        uint256 index;
    }

    struct IterableMapping {
        mapping(bytes32 => VariableTransactionDataWithIndex) transactions;
        bytes32[] digests;
    }

    function digestEqual(bytes32 s, bytes32 t)
        internal
        pure
        returns (bool)
    {
        return s == t;
    }

    function isEmptyString(bytes32 s) internal pure returns (bool) {
        return digestEqual(s, bytes32(0));
    }

    function digestExists(IterableMapping storage self, bytes32 digest)
        internal
        view
        returns (bool)
    {
        return
            !isEmptyString(digest) &&
            self.digests.length != 0 &&
            digestEqual(self.digests[self.transactions[digest].index], digest);
    }

    function length(IterableMapping storage self)
        internal
        view
        returns (uint256)
    {
        return self.digests.length;
    }

    function getTransactionByDigest(
        IterableMapping storage self,
        bytes32 digest
    ) internal view returns (VariableTransactionData memory) {
        require(digestExists(self, digest), "LibIterableMapping: DIGEST_NOT_FOUND");
        return self.transactions[digest].transaction;
    }

    function getTransactionByIndex(
        IterableMapping storage self,
        uint256 index
    ) internal view returns (VariableTransactionData memory) {
        require(index < self.digests.length, "LibIterableMapping: INVALID_INDEX");
        return self.transactions[self.digests[index]].transaction;
    }

    // DO NOT USE THIS IN A WRITE OPERATION
    // Two for loops make this very expensive
    function getTransactionsByUser(
        IterableMapping storage self,
        address user
    ) internal view returns (VariableTransactionData[] memory) {
        uint256 l = self.digests.length;

        // First determine how many user txs there are for array length
        uint256 userTxs = 0;
        for (uint256 i = 0; i < l; i++) {
            if (self.transactions[self.digests[i]].transaction.user == user) {
              userTxs += 1;
            }
        }

        // Add each user tx to array at index
        VariableTransactionData[] memory userTransactions = new VariableTransactionData[](userTxs);
        uint256 idx = 0;
        for (uint256 i = 0; i < l; i++) {
            if (self.transactions[self.digests[i]].transaction.user == user) {
              userTransactions[idx] = self.transactions[self.digests[i]].transaction;
              idx += 1;
            }
        }

        return userTransactions;
    }

    function getTransactions(IterableMapping storage self)
        internal
        view
        returns (VariableTransactionData[] memory)
    {
        uint256 l = self.digests.length;
        VariableTransactionData[] memory transactions = new VariableTransactionData[](l);
        for (uint256 i = 0; i < l; i++) {
            transactions[i] = self.transactions[self.digests[i]].transaction;
        }
        return transactions;
    }

    function addTransaction(
        IterableMapping storage self,
        VariableTransactionData memory transaction
    ) internal {
        bytes32 digest = transaction.digest;
        require(!isEmptyString(digest), "LibIterableMapping: EMPTY_DIGEST");
        require(!digestExists(self, digest), "LibIterableMapping: DIGEST_ALREADY_ADDED");
        self.transactions[digest] = VariableTransactionDataWithIndex({
            transaction: transaction,
            index: self.digests.length
        });
        self.digests.push(digest);
    }

    function removeTransaction(
        IterableMapping storage self,
        bytes32 digest
    ) internal {
        require(!isEmptyString(digest), "LibIterableMapping: EMPTY_DIGEST");
        require(digestExists(self, digest), "LibIterableMapping: DIGEST_NOT_FOUND");
        uint256 index = self.transactions[digest].index;
        bytes32 lastDigest = self.digests[self.digests.length - 1];
        self.transactions[lastDigest].index = index;
        self.digests[index] = lastDigest;
        delete self.transactions[digest];
        self.digests.pop();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

/// @title LibUtils
/// @author Connext <[email protected]>
/// @notice Contains a helper to revert if a call was not successfully
///         made
library LibUtils {
    // If success is false, reverts and passes on the revert string.
    function revertIfCallFailed(bool success, bytes memory returnData)
        internal
        pure
    {
        if (!success) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}