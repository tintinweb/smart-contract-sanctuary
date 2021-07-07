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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./interfaces/IFulfillHelper.sol";
import "./interfaces/ITransactionManager.sol";
import "./lib/LibAsset.sol";
import "./lib/LibERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Outstanding qs:
// - what happens if you have unique user data, but duplicate tx ids?
//   no requires here would catch this, the tx would be properly prepared
//
// - we validate all the inputs but the amount, bidSignature, and encodedBid.
//   bidSignature and encodedBid could be used as slashing later, and their
//   validation is out of scope of this function. But, do we want to be able
//   to use this to send 0-value amounts? basically as some incentivized
//   relayer? would that break bidding?


/// @title TransactionManager
/// @author Connext <[email protected]>
/// @notice This contract holds the logic to facilitate crosschain transactions.
///         Transactions go through three phases:
///
///         1. Route Auction: User broadcasts to our network signalling their 
///         desired route. Routers respond with sealed bids containing 
///         commitments to fulfilling the transaction within a certain time and 
///         price range.
///
///         2. Prepare: Once the auction is completed, the transaction can be 
///         prepared. The user submits a transaction to `TransactionManager` 
///         contract on sender-side chain containing router's signed bid. This 
///         transaction locks up the users funds on the sending chiain. Upon 
///         detecting an event containing their signed bid from the chain, 
///         router submits the same transaction to `TransactionManager` on the 
///         receiver-side chain, and locks up a corresponding amount of 
///         liquidity. The amount locked on the receiving chain is `sending 
///         amount - auction fee` so the router is incentivized to complete the 
///         transaction.
///
///         3. Fulfill: Upon detecting the `TransactionPrepared` event on the 
///         receiver-side chain, the user signs a message and sends it to a 
///         relayer, who will earn a fee for submission. The relayer (which may 
///         be the router) then submits the message to the `TransactionManager` 
///         to complete their transaction on receiver-side chain and claim the 
///         funds locked by the router. A relayer is used here to allow users 
///         to submit transactions with arbitrary calldata on the receiving 
///         chain without needing gas to do so. The router then submits the 
///         same signed message and completes transaction on sender-side, 
///         unlocking the original `amount`.
///
///         If a transaction is not fulfilled within a fixed timeout, it 
///         reverts and can be reclaimed by the party that called `prepare` on 
///         each chain (initiator). Additionally, transactions can be cancelled 
///         unilaterally by the person owed funds on that chain (router for 
///         sending chain, user for receiving chain) prior to expiry.

contract TransactionManager is ReentrancyGuard, ITransactionManager {
  /// @dev Mapping of router to balance specific to asset
  mapping(address => mapping(address => uint256)) public routerBalances;

  /// @dev Mapping of user address to blocks where active transfers
  ///      were created.
  mapping(address => uint256[]) public activeTransactionBlocks;

  /// @dev Mapping of hash of `InvariantTransactionData` to the hash
  //       of the `VariantTransactionData`
  mapping(bytes32 => bytes32) public variantTransactionData;

  /// @dev The chain id of the contract, is passed in to avoid any evm issues
  uint256 public immutable chainId;

  /// @dev Minimum timeout (will be the lowest on the receiving chain)
  uint256 public constant MIN_TIMEOUT = 24 hours;

  constructor(uint256 _chainId) {
    chainId = _chainId;
  }

  /// @notice This is used by any router to increase their available
  ///         liquidity for a given asset.
  /// @param amount The amount of liquidity to add for the router
  /// @param assetId The address (or `address(0)` if native asset) of the
  ///                asset you're adding liquidity for
  function addLiquidity(uint256 amount, address assetId) external payable override nonReentrant {
    // Sanity check: nonzero amounts
    require(amount > 0, "addLiquidity: AMOUNT_IS_ZERO");

    // Validate correct amounts are transferred
    if (LibAsset.isEther(assetId)) {
      require(msg.value == amount, "addLiquidity: VALUE_MISMATCH");
    } else {
      require(msg.value == 0, "addLiquidity: ETH_WITH_ERC_TRANSFER");
      require(LibERC20.transferFrom(assetId, msg.sender, address(this), amount), "addLiquidity: ERC20_TRANSFER_FAILED");
    }

    // Update the router balances
    routerBalances[msg.sender][assetId] += amount;

    // Emit event
    emit LiquidityAdded(msg.sender, assetId, amount);
  }

  /// @notice This is used by any router to decrease their available
  ///         liquidity for a given asset.
  /// @param amount The amount of liquidity to remove for the router
  /// @param assetId The address (or `address(0)` if native asset) of the
  ///                asset you're removing liquidity for
  /// @param recipient The address that will receive the liquidity being removed
  function removeLiquidity(
    uint256 amount,
    address assetId,
    address payable recipient
  ) external override nonReentrant {
    // Sanity check: nonzero amounts
    require(amount > 0, "removeLiquidity: AMOUNT_IS_ZERO");

    // Sanity check: amount can be deducted for the router
    require(routerBalances[msg.sender][assetId] >= amount, "removeLiquidity: INSUFFICIENT_FUNDS");

    // Update router balances
    routerBalances[msg.sender][assetId] -= amount;

    // Transfer from contract to specified recipient
    require(LibAsset.transferAsset(assetId, recipient, amount), "removeLiquidity: TRANSFER_FAILED");

    // Emit event
    emit LiquidityRemoved(msg.sender, assetId, amount, recipient);
  }

  /// @notice This function creates a crosschain transaction. When called on
  ///         the sending chain, the user is expected to lock up funds. When
  ///         called on the receiving chain, the router deducts the transfer
  ///         amount from the available liquidity. The majority of the
  ///         information about a given transfer does not change between chains,
  ///         with three notable exceptions: `amount`, `expiry`, and 
  ///         `preparedBlock`. The `amount` and `expiry` are decremented
  ///         between sending and receiving chains to provide an incentive for 
  ///         the router to complete the transaction and time for the router to
  ///         fulfill the transaction on the sending chain after the unlocking
  ///         signature is revealed, respectively.
  /// @param invariantData The data for a crosschain transaction that will
  ///                      not change between sending and receiving chains.
  ///                      The hash of this data is used as the key to store 
  ///                      the inforamtion that does change between chains 
  ///                      (amount, expiry,preparedBlock) for verification
  /// @param amount The amount of the transaction on this chain
  /// @param expiry The block.timestamp when the transaction will no longer be
  ///               fulfillable and is freely cancellable on this chain
  /// @param encryptedCallData The calldata to be executed when the tx is
  ///                          fulfilled. Used in the function to allow the user
  ///                          to reconstruct the tx from events. Hash is stored
  ///                          onchain to prevent shenanigans.
  /// @param encodedBid The encoded bid that was accepted by the user for this
  ///                   crosschain transfer. It is supplied as a param to the
  ///                   function but is only used in event emission
  /// @param bidSignature The signature of the bidder on the encoded bid for
  ///                     this transaction. Only used within the function for
  ///                     event emission. The validity of the bid and
  ///                     bidSignature are enforced offchain
  function prepare(
    InvariantTransactionData calldata invariantData,
    uint256 amount,
    uint256 expiry,
    bytes calldata encryptedCallData,
    bytes calldata encodedBid,
    bytes calldata bidSignature
  ) external payable override nonReentrant returns (TransactionData memory) {
    // Sanity check: user is sensible
    require(invariantData.user != address(0), "prepare: USER_EMPTY");

    // Sanity check: router is sensible
    require(invariantData.router != address(0), "prepare: ROUTER_EMPTY");

    // Sanity check: valid fallback
    require(invariantData.receivingAddress != address(0), "prepare: RECEIVING_ADDRESS_EMPTY");

    // Make sure the chains are different
    require(invariantData.sendingChainId != invariantData.receivingChainId, "prepare: SAME_CHAINIDS");

    // Make sure the chains are relevant
    require(invariantData.sendingChainId == chainId || invariantData.receivingChainId == chainId, "prepare: INVALID_CHAINIDS");

    // Make sure the expiry is greater than min
    require((expiry - block.timestamp) >= MIN_TIMEOUT, "prepare: TIMEOUT_TOO_LOW");

    // Sanity check: amount is sensible
    require(amount > 0, "prepare: AMOUNT_IS_ZERO");

    // Make sure the hash is not a duplicate
    bytes32 digest = keccak256(abi.encode(invariantData));
    require(variantTransactionData[digest] == bytes32(0), "prepare: DIGEST_EXISTS");

    // NOTE: the `encodedBid` and `bidSignature` are simply passed through
    //       to the contract emitted event to ensure the availability of
    //       this information. Their validity is asserted offchain, and
    //       is out of scope of this contract. They are used as inputs so
    //       in the event of a router or user crash, they may recover the
    //       correct bid information without requiring an offchain store.

    // Store the transaction variants
    variantTransactionData[digest] = keccak256(abi.encode(VariantTransactionData({
      amount: amount,
      expiry: expiry,
      preparedBlockNumber: block.number
    })));

    // Store active blocks
    activeTransactionBlocks[invariantData.user].push(block.number);

    // First determine if this is sender side or receiver side
    if (invariantData.sendingChainId == chainId) {
      // This is sender side prepare. The user is beginning the process of 
      // submitting an onchain tx after accepting some bid. They should
      // lock their funds in the contract for the router to claim after
      // they have revealed their signature on the receiving chain via
      // submitting a corresponding `fulfill` tx

      // Validate correct amounts on msg and transfer from user to
      // contract
      if (LibAsset.isEther(invariantData.sendingAssetId)) {
        require(msg.value == amount, "prepare: VALUE_MISMATCH");
      } else {
        require(msg.value == 0, "prepare: ETH_WITH_ERC_TRANSFER");
        require(
          LibERC20.transferFrom(invariantData.sendingAssetId, msg.sender, address(this), amount),
          "prepare: ERC20_TRANSFER_FAILED"
        );
      }
    } else {
      // This is receiver side prepare. The router has proposed a bid on the
      // transfer which the user has accepted. They can now lock up their
      // own liquidity on th receiving chain, which the user can unlock by
      // calling `fulfill`. When creating the `amount` and `expiry` on the
      // receiving chain, the router should have decremented both. The
      // expiry should be decremented to ensure the router has time to
      // complete the sender-side transaction after the user completes the
      // receiver-side transactoin. The amount should be decremented to act as
      // a fee to incentivize the router to complete the transaction properly.

      // Check that the caller is the router
      require(msg.sender == invariantData.router, "prepare: ROUTER_MISMATCH");

      // Check that the router isnt accidentally locking funds in the contract
      require(msg.value == 0, "prepare: ETH_WITH_ROUTER_PREPARE");

      // Check that router has liquidity
      require(
        routerBalances[invariantData.router][invariantData.receivingAssetId] >= amount,
        "prepare: INSUFFICIENT_LIQUIDITY"
      );

      // Decrement the router liquidity
      routerBalances[invariantData.router][invariantData.receivingAssetId] -= amount;
    }

    // Emit event
    TransactionData memory txData = TransactionData({
      user: invariantData.user,
      router: invariantData.router,
      sendingAssetId: invariantData.sendingAssetId,
      receivingAssetId: invariantData.receivingAssetId,
      sendingChainFallback: invariantData.sendingChainFallback,
      callTo: invariantData.callTo,
      receivingAddress: invariantData.receivingAddress,
      callDataHash: invariantData.callDataHash,
      transactionId: invariantData.transactionId,
      sendingChainId: invariantData.sendingChainId,
      receivingChainId: invariantData.receivingChainId,
      amount: amount,
      expiry: expiry,
      preparedBlockNumber: block.number
    });
    emit TransactionPrepared(txData.user, txData.router, txData.transactionId, txData, msg.sender, encryptedCallData, encodedBid, bidSignature);
    return txData;
  }



  /// @notice This function completes a crosschain transaction. When called on
  ///         the receiving chain, the user reveals their signature on the
  ///         invariant parts of the transaction data and is sent the 
  ///         appropriate amount. The router then uses this signature to
  ///         unlock the corresponding funds on the receiving chain, which are
  ///         then added back to their available liquidity. The user includes a
  ///         relayer fee since it is not assumed they will have gas on the
  ///         receiving chain. This function *must* be called before the
  ///         transaction expiry has elapsed.
  /// @param txData All of the data (invariant and variant) for a crosschain
  ///               transaction. The variant data provided is checked against
  ///               what was stored when the `prepare` function was called.
  /// @param relayerFee The fee that should go to the relayer when they are
  ///                   calling the function on the receiving chain for the user
  /// @param signature The users signature on the invariant data + fee that
  ///                  can be used by the router to unlock the transaction on 
  ///                  the sending chain
  function fulfill(
    TransactionData calldata txData,
    uint256 relayerFee,
    bytes calldata signature, // signature on fee + digest
    bytes calldata callData
  ) external override nonReentrant returns (TransactionData memory) {
    // Get the hash of the invariant tx data. This hash is the same
    // between sending and receiving chains. The variant data is stored
    // in the contract when `prepare` is called within the mapping.
    bytes32 digest = hashInvariantTransactionData(txData);

    // Make sure that the variant data matches what was stored
    require(variantTransactionData[digest] == hashVariantTransactionData(txData), "fulfill: INVALID_VARIANT_DATA");

    // Make sure the expiry has not elapsed
    require(txData.expiry > block.timestamp, "fulfill: EXPIRED");

    // Make sure the transaction wasn't already completed
    require(txData.preparedBlockNumber > 0, "fulfill: ALREADY_COMPLETED");

    // Validate the user has signed
    require(recoverFulfillSignature(txData, relayerFee, signature) == txData.user, "fulfill: INVALID_SIGNATURE");

    // Sanity check: fee < amount
    require(relayerFee < txData.amount, "fulfill: INVALID_RELAYER_FEE");

    // Check provided callData matches stored hash
    require(keccak256(callData) == txData.callDataHash, "fulfill: INVALID_CALL_DATA");

    // To prevent `fulfill` / `cancel` from being called multiple times, the
    // preparedBlockNumber is set to 0 before being hashed. The value of the
    // mapping is explicitly *not* zeroed out so users who come online without
    // a store can tell the difference between a transaction that has not been
    // prepared, and a transaction that was already completed on the receiver
    // chain.
    variantTransactionData[digest] = keccak256(abi.encode(VariantTransactionData({
      amount: txData.amount,
      expiry: txData.expiry,
      preparedBlockNumber: 0
    })));

    // Remove the transaction prepared block from the active blocks
    removeUserActiveBlocks(txData.user, txData.preparedBlockNumber);

    if (txData.sendingChainId == chainId) {
      // The router is completing the transaction, they should get the
      // amount that the user deposited credited to their liquidity
      // reserves.

      // Make sure that the user is not accidentally fulfilling the transaction
      // on the sending chain
      require(msg.sender == txData.router, "fulfill: ROUTER_MISMATCH");

      // Complete tx to router for original sending amount
      routerBalances[txData.router][txData.sendingAssetId] += txData.amount;
    } else {
      // The user is completing the transaction, they should get the
      // amount that the router deposited less fees for relayer.

      // Get the amount to send
      uint256 toSend = txData.amount - relayerFee;

      // Send the relayer the fee
      if (relayerFee > 0) {
        require(
          LibAsset.transferAsset(txData.receivingAssetId, payable(msg.sender), relayerFee),
          "fulfill: FEE_TRANSFER_FAILED"
        );
      }

      // Handle receiver chain external calls if needed
      if (txData.callTo == address(0)) {
        // No external calls, send directly to receiving address
        require(
          LibAsset.transferAsset(txData.receivingAssetId, payable(txData.receivingAddress), toSend),
          "fulfill: TRANSFER_FAILED"
        );
      } else {
        // Handle external calls with a fallback to the receiving
        // address in case the call fails so the funds dont remain
        // locked.

        // First, approve the funds to the helper if needed
        if (LibAsset.isEther(txData.receivingAssetId) && toSend > 0) {
          require(LibERC20.approve(txData.receivingAssetId, txData.callTo, toSend), "fulfill: APPROVAL_FAILED");
        }

        // Next, call `addFunds` on the helper. Helpers should internally
        // track funds to make sure no one user is able to take all funds
        // for tx
        if (toSend > 0) {
          try
            IFulfillHelper(txData.callTo).addFunds{ value: LibAsset.isEther(txData.receivingAssetId) ? toSend : 0}(
              txData.user,
              txData.transactionId,
              txData.receivingAssetId,
              toSend
            )
          {} catch {
            // Regardless of error within the callData execution, send funds
            // to the predetermined fallback address
            require(
              LibAsset.transferAsset(txData.receivingAssetId, payable(txData.receivingAddress), toSend),
              "fulfill: TRANSFER_FAILED"
            );
          }
        }

        // Call `execute` on the helper
        try
          IFulfillHelper(txData.callTo).execute(
            txData.user,
            txData.transactionId,
            txData.receivingAssetId,
            toSend,
            callData
          )
        {} catch {
          // Regardless of error within the callData execution, send funds
          // to the predetermined fallback address
          require(
            LibAsset.transferAsset(txData.receivingAssetId, payable(txData.receivingAddress), toSend),
            "fulfill: TRANSFER_FAILED"
          );
        }
      }
    }

    // Emit event
    emit TransactionFulfilled(txData.user, txData.router, txData.transactionId, txData, relayerFee, signature, callData, msg.sender);

    return txData;
  }

  /// @notice Any crosschain transaction can be cancelled after it has been
  ///         created to prevent indefinite lock up of funds. After the
  ///         transaction has expired, anyone can cancel it. Before the
  ///         expiry, only the recipient of the funds on the given chain is
  ///         able to cancel. On the sending chain, this means only the router
  ///         is able to cancel before the expiry, while only the user can
  ///         prematurely cancel on the receiving chain.
  /// @param txData All of the data (invariant and variant) for a crosschain
  ///               transaction. The variant data provided is checked against
  ///               what was stored when the `prepare` function was called.
  /// @param relayerFee The fee that should go to the relayer when they are
  ///                   calling the function for the user
  /// @param signature The user's signature that allows a transaction to be
  ///                  cancelled on the receiving chain.
  function cancel(TransactionData calldata txData, uint256 relayerFee, bytes calldata signature)
    external
    override
    nonReentrant
    returns (TransactionData memory)
  {
    // Make sure params match against stored data
    // Also checks that there is an active transfer here
    // Also checks that sender or receiver chainID is this chainId (bc we checked it previously)

    // Get the hash of the invariant tx data. This hash is the same
    // between sending and receiving chains. The variant data is stored
    // in the contract when `prepare` is called within the mapping.
    bytes32 digest = hashInvariantTransactionData(txData);

    // Verify the variant data is correct
    require(variantTransactionData[digest] == hashVariantTransactionData(txData), "cancel: INVALID_VARIANT_DATA");

    // Make sure the transaction wasn't already completed
    require(txData.preparedBlockNumber > 0, "cancel: ALREADY_COMPLETED");

    // To prevent `fulfill` / `cancel` from being called multiple times, the
    // preparedBlockNumber is set to 0 before being hashed. The value of the
    // mapping is explicitly *not* zeroed out so users who come online without
    // a store can tell the difference between a transaction that has not been
    // prepared, and a transaction that was already completed on the receiver
    // chain.
    variantTransactionData[digest] = keccak256(abi.encode(VariantTransactionData({
      amount: txData.amount,
      expiry: txData.expiry,
      preparedBlockNumber: 0
    })));

    // Remove active blocks
    removeUserActiveBlocks(txData.user, txData.preparedBlockNumber);

    // Return the appropriate locked funds
    if (txData.sendingChainId == chainId) {
      // Sender side, funds must be returned to the user
      if (txData.expiry >= block.timestamp) {
        // Timeout has not expired and tx may only be cancelled by router
        // NOTE: no need to validate the signature here, since you are requiring
        // the router must be the sender when the cancellation is during the
        // fulfill-able window
        require(msg.sender == txData.router, "cancel: ROUTER_MUST_CANCEL");

        // Return totality of locked funds to provided fallbacl
        require(
          LibAsset.transferAsset(txData.sendingAssetId, payable(txData.sendingChainFallback), txData.amount),
          "cancel: TRANSFER_FAILED"
        );
      } else {
        // When the user could be unlocking funds through a relayer, validate
        // their signature and payout the relayer.
        if (relayerFee > 0) {
          require(recoverCancelSignature(txData, relayerFee, signature) == txData.user, "cancel: INVALID_SIGNATURE");

          require(
            LibAsset.transferAsset(txData.receivingAssetId, payable(msg.sender), relayerFee),
            "cancel: FEE_TRANSFER_FAILED"
          );
        }

        // Get the amount to refund the user
        uint256 toRefund = txData.amount - relayerFee;

        // Return locked funds to sending chain fallback
        require(
          LibAsset.transferAsset(txData.sendingAssetId, payable(txData.sendingChainFallback), toRefund),
          "cancel: TRANSFER_FAILED"
        );
      }

    } else {
      // Receiver side, router liquidity is returned
      if (txData.expiry >= block.timestamp) {
        // Timeout has not expired and tx may only be cancelled by user
        // Validate signature
        require(recoverCancelSignature(txData, relayerFee, signature) == txData.user, "cancel: INVALID_SIGNATURE");

        // NOTE: there is no incentive here for relayers to submit this on
        // behalf of the user (i.e. fee not respected) because the user has not
        // locked funds on this contract.
      }

      // Return liquidity to router
      routerBalances[txData.router][txData.receivingAssetId] += txData.amount;
    }

    // Emit event
    emit TransactionCancelled(txData.user, txData.router, txData.transactionId, txData, relayerFee, msg.sender);

    // Return
    return txData;
  }

  //////////////////////////
  /// Private functions ///
  //////////////////////////

  /// @notice Removes a given block from the tracked activeTransactionBlocks
  ///         array for the user. Called when transactions are completed.
  /// @param user User who has completed a transaction
  /// @param preparedBlock The TransactionData.preparedBlockNumber to remove
  function removeUserActiveBlocks(address user, uint256 preparedBlock) internal {
    // Remove active blocks
    uint256 newLength = activeTransactionBlocks[user].length - 1;
    uint256[] memory updated = new uint256[](newLength);
    bool removed = false;
    uint256 updatedIdx = 0;
    for (uint256 i; i < newLength + 1; i++) {
      // Handle case where there could be more than one tx added in a block
      // And only one should be removed
      if (!removed && activeTransactionBlocks[user][i] == preparedBlock) {
        removed = true;
        continue;
      }
      updated[updatedIdx] = activeTransactionBlocks[user][i];
      updatedIdx++;
    }
    activeTransactionBlocks[user] = updated;
  }

  /// @notice Recovers the signer from the signature provided to the `fulfill`
  ///         function. Returns the address recovered
  /// @param txData TransactionData of the transaction being fulfilled
  /// @param relayerFee The fee paid to the relayer for submitting the fulfill
  ///                   tx on behalf of the user.
  /// @param signature The signature you are recovering the signer from
  function recoverFulfillSignature(
    TransactionData calldata txData,
    uint256 relayerFee,
    bytes calldata signature
  ) internal pure returns (address) {
    // Create the digest
    bytes32 invariantDigest = hashInvariantTransactionData(txData);

    // Create the signed payload
    SignedFulfillData memory payload = SignedFulfillData({invariantDigest: invariantDigest, relayerFee: relayerFee});

    // Recover
    return ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(payload))), signature);
  }

  /// @notice Recovers the signer from the signature provided to the `cancel`
  ///         function. Returns the address recovered
  /// @param txData TransactionData of the transaction being fulfilled
  /// @param relayerFee The fee paid to the relayer for submitting the cancel
  ///                   tx on behalf of the user.
  /// @param signature The signature you are recovering the signer from
  function recoverCancelSignature(TransactionData calldata txData, uint256 relayerFee, bytes calldata signature)
    internal
    pure
    returns (address)
  {
    // Create the digest
    bytes32 invariantDigest = hashInvariantTransactionData(txData);

    // Create the signed payload
    SignedCancelData memory payload = SignedCancelData({invariantDigest: invariantDigest, cancel: "cancel", relayerFee: relayerFee});

    // Recover
    return ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(payload))), signature);
  }

  /// @notice Returns the hash of only the invariant portions of a given
  ///         crosschain transaction
  /// @param txData TransactionData to hash
  function hashInvariantTransactionData(TransactionData calldata txData) internal pure returns (bytes32) {
    InvariantTransactionData memory invariant = InvariantTransactionData({
      user: txData.user,
      router: txData.router,
      sendingAssetId: txData.sendingAssetId,
      receivingAssetId: txData.receivingAssetId,
      sendingChainFallback: txData.sendingChainFallback,
      callTo: txData.callTo,
      receivingAddress: txData.receivingAddress,
      sendingChainId: txData.sendingChainId,
      receivingChainId: txData.receivingChainId,
      callDataHash: txData.callDataHash,
      transactionId: txData.transactionId
    });
    return keccak256(abi.encode(invariant));
  }

  /// @notice Returns the hash of only the variant portions of a given
  ///         crosschain transaction
  /// @param txData TransactionData to hash
  function hashVariantTransactionData(TransactionData calldata txData) internal pure returns (bytes32) {
    return keccak256(abi.encode(VariantTransactionData({
      amount: txData.amount,
      expiry: txData.expiry,
      preparedBlockNumber: txData.preparedBlockNumber
    })));
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IFulfillHelper {
  function addFunds(
    address user,
    bytes32 transactionId,
    address assetId,
    uint256 amount
  ) external payable;

  function execute(
    address user,
    bytes32 transactionId,
    address assetId,
    uint256 amount,
    bytes calldata callData
  ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface ITransactionManager {
  // Structs

  // Holds all data that is constant between sending and
  // receiving chains. The hash of this is what gets signed
  // to ensure the signature can be used on both chains.
  struct InvariantTransactionData {
    address user;
    address router;
    address sendingAssetId;
    address receivingAssetId;
    address sendingChainFallback; // funds sent here on cancel
    address receivingAddress;
    address callTo;
    uint256 sendingChainId;
    uint256 receivingChainId;
    bytes32 callDataHash; // hashed to prevent free option
    bytes32 transactionId;
  }

  // Holds all data that varies between sending and receiving
  // chains. The hash of this is stored onchain to ensure the
  // information passed in is valid.
  struct VariantTransactionData {
    uint256 amount;
    uint256 expiry;
    uint256 preparedBlockNumber;
  }

  // All Transaction data, constant and variable
  struct TransactionData {
    address user;
    address router;
    address sendingAssetId;
    address receivingAssetId;
    address sendingChainFallback;
    address receivingAddress;
    address callTo;
    bytes32 callDataHash;
    bytes32 transactionId;
    uint256 sendingChainId;
    uint256 receivingChainId;
    uint256 amount;
    uint256 expiry;
    uint256 preparedBlockNumber; // Needed for removal of active blocks on fulfill/cancel
  }

  // The structure of the signed data for cancellations
  struct SignedCancelData {
    bytes32 invariantDigest;
    uint256 relayerFee;
    string cancel; // just the string "cancel"
  }

  // The structure of the signed data for cancellations
  struct SignedFulfillData {
    bytes32 invariantDigest;
    uint256 relayerFee;
  }

  // Liquidity events
  event LiquidityAdded(address router, address assetId, uint256 amount);

  event LiquidityRemoved(address router, address assetId, uint256 amount, address recipient);

  // Transaction events
  event TransactionPrepared(
    address user,
    address router,
    bytes32 transactionId,
    TransactionData txData,
    address caller,
    bytes encryptedCallData,
    bytes encodedBid,
    bytes bidSignature
  );

  event TransactionFulfilled(
    address user,
    address router,
    bytes32 transactionId,
    TransactionData txData,
    uint256 relayerFee,
    bytes signature,
    bytes callData,
    address caller
  );

  event TransactionCancelled(
    address user,
    address router,
    bytes32 transactionId,
    TransactionData txData,
    uint256 relayerFee,
    address caller
  );

  // Router only methods
  function addLiquidity(uint256 amount, address assetId) external payable;

  function removeLiquidity(
    uint256 amount,
    address assetId,
    address payable recipient
  ) external;

  // Methods for crosschain transfers
  // called in the following order (in happy case)
  // 1. prepare by user on sending chain
  // 2. prepare by router on receiving chain
  // 3. fulfill by user on receiving chain
  // 4. fulfill by router on sending chain
  function prepare(
    InvariantTransactionData calldata txData,
    uint256 amount,
    uint256 expiry,
    bytes calldata encryptedCallData,
    bytes calldata encodedBid,
    bytes calldata bidSignature
  ) external payable returns (TransactionData memory);

  function fulfill(
    TransactionData calldata txData,
    uint256 relayerFee,
    bytes calldata signature,
    bytes calldata callData
  ) external returns (TransactionData memory);

  function cancel(TransactionData calldata txData, uint256 relayerFee, bytes calldata signature) external returns (TransactionData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./LibERC20.sol";
import "./LibUtils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title LibAsset
/// @author Connext <[email protected]>
/// @notice This library contains helpers for dealing with onchain transfers
///         of assets, including accounting for the native asset `assetId`
///         conventions and any noncompliant ERC20 transfers

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
pragma solidity 0.8.4;

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
pragma solidity 0.8.4;

/// @title LibUtils
/// @author Connext <[email protected]>
/// @notice Contains a helper to revert if a call was not successfully
///         made
library LibUtils {
    /// @notice If success is false, reverts and passes on the revert string.
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
    "enabled": true,
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