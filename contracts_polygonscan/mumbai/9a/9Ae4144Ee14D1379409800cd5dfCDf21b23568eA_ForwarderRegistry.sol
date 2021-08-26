/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File _lib/openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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


// File _lib/openzeppelin/contracts/cryptography/ECDSA.sol


pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
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
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


// File src/solc_0.7/ERC2771/IERC2771.sol

pragma solidity ^0.7.0;

interface IERC2771 {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}


// File src/solc_0.7/ERC2771/UsingAppendedCallData.sol

pragma solidity ^0.7.0;

abstract contract UsingAppendedCallData {
    function _lastAppendedDataAsSender() internal pure virtual returns (address payable sender) {
        // Copied from openzeppelin : https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9d5f77db9da0604ce0b25148898a94ae2c20d70f/contracts/metatx/ERC2771Context.sol1
        // The assembly code is more direct than the Solidity version using `abi.decode`.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    function _msgDataAssuming20BytesAppendedData() internal pure virtual returns (bytes calldata) {
        return msg.data[:msg.data.length - 20];
    }
}


// File src/ForwarderRegistry.sol

pragma solidity 0.7.6;




interface ERC1271 {
    function isValidSignature(bytes calldata data, bytes calldata signature) external view returns (bytes4 magicValue);
}

interface ERC1654 {
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}

/// @notice Universal Meta Transaction Forwarder Registry.
/// Users can record specific forwarder that will be allowed to forward meta transactions on their behalf.
contract ForwarderRegistry is UsingAppendedCallData, IERC2771 {
    using Address for address;
    using ECDSA for bytes32;

    enum SignatureType {DIRECT, EIP1654, EIP1271}
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;
    bytes4 internal constant ERC1654_MAGICVALUE = 0x1626ba7e;

    bytes32 internal constant EIP712DOMAIN_NAME = keccak256("ForwarderRegistry");
    bytes32 internal constant APPROVAL_TYPEHASH =
        keccak256("ApproveForwarder(address forwarder,bool approved,uint256 nonce)");

    uint256 private immutable _deploymentChainId;
    bytes32 private immutable _deploymentDomainSeparator;

    struct Forwarder {
        uint248 nonce;
        bool approved;
    }
    mapping(address => mapping(address => Forwarder)) internal _forwarders;

    /// @notice emitted for each Forwarder Approval or Disaproval.
    event ForwarderApproved(address indexed signer, address indexed forwarder, bool approved, uint256 nonce);

    constructor() {
        uint256 chainId;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        _deploymentChainId = chainId;
        _deploymentDomainSeparator = _calculateDomainSeparator(chainId);
    }

    /// @notice The ForwarderRegistry supports every EIP-2771 compliant forwarder.
    function isTrustedForwarder(address) external pure override returns (bool) {
        return true;
    }

    /// @notice Forward the meta tx (assuming caller has been approved by the signer as forwarder).
    /// @param target destination of the call (that will receive the meta transaction).
    /// @param data the content of the call (the signer address will be appended to it).
    function forward(address target, bytes calldata data) external payable {
        address signer = _lastAppendedDataAsSender();
        require(_forwarders[signer][msg.sender].approved, "NOT_AUTHORIZED_FORWARDER");
        target.functionCallWithValue(abi.encodePacked(data, signer), msg.value);
    }

    /// @notice return the current nonce for the signer/forwarder pair.
    function getNonce(address signer, address forwarder) external view returns (uint256) {
        return uint256(_forwarders[signer][forwarder].nonce);
    }

    /// @notice return whether a forwarder is approved by a particular signer.
    /// @param signer signer who authorized or not the forwarder.
    /// @param forwarder meta transaction forwarder contract address.
    function isForwarderFor(address signer, address forwarder) external view returns (bool) {
        return forwarder == address(this) || _forwarders[signer][forwarder].approved;
    }

    /// @notice approve forwarder using the forwarder (which is msg.sender).
    /// @param approved whether to approve or disapprove (if previously approved) the forwarder.
    /// @param signature signature by signer for approving forwarder.
    function approveForwarder(
        bool approved,
        bytes calldata signature,
        SignatureType signatureType
    ) external {
        _approveForwarder(_lastAppendedDataAsSender(), approved, signature, signatureType);
    }

    /// @notice approve and forward the meta transaction in one call.
    /// @param signature signature by signer for approving forwarder.
    /// @param target destination of the call (that will receive the meta transaction).
    /// @param data the content of the call (the signer address will be appended to it).
    function approveAndForward(
        bytes calldata signature,
        SignatureType signatureType,
        address target,
        bytes calldata data
    ) external payable {
        address signer = _lastAppendedDataAsSender();
        _approveForwarder(signer, true, signature, signatureType);
        target.functionCallWithValue(abi.encodePacked(data, signer), msg.value);
    }

    /// @notice check approval (but do not record it) and forward the meta transaction in one call.
    /// @param signature signature by signer for approving forwarder.
    /// @param target destination of the call (that will receive the meta transaction).
    /// @param data the content of the call (the signer address will be appended to it).
    function checkApprovalAndForward(
        bytes calldata signature,
        SignatureType signatureType,
        address target,
        bytes calldata data
    ) external payable {
        address signer = _lastAppendedDataAsSender();
        address forwarder = msg.sender;
        _requireValidSignature(
            signer,
            forwarder,
            true,
            uint256(_forwarders[signer][forwarder].nonce),
            signature,
            signatureType
        );
        target.functionCallWithValue(abi.encodePacked(data, signer), msg.value);
    }

    /// @dev Return the DOMAIN_SEPARATOR.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _DOMAIN_SEPARATOR();
    }

    // -------------------------------------------------------- INTERNAL --------------------------------------------------------------------

    /// @dev Return the DOMAIN_SEPARATOR.
    function _DOMAIN_SEPARATOR() internal view returns (bytes32) {
        uint256 chainId;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        // in case a fork happen, to support the chain that had to change its chainId,, we compue the domain operator
        return chainId == _deploymentChainId ? _deploymentDomainSeparator : _calculateDomainSeparator(chainId);
    }

    /// @dev Calculate the DOMAIN_SEPARATOR.
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"),
                    EIP712DOMAIN_NAME,
                    chainId,
                    address(this)
                )
            );
    }

    function _encodeMessage(
        address forwarder,
        bool approved,
        uint256 nonce
    ) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR(),
                keccak256(abi.encode(APPROVAL_TYPEHASH, forwarder, approved, nonce))
            );
    }

    function _requireValidSignature(
        address signer,
        address forwarder,
        bool approved,
        uint256 nonce,
        bytes memory signature,
        SignatureType signatureType
    ) internal view {
        bytes memory dataToHash = _encodeMessage(forwarder, approved, nonce);
        if (signatureType == SignatureType.EIP1271) {
            require(
                ERC1271(signer).isValidSignature(dataToHash, signature) == ERC1271_MAGICVALUE,
                "SIGNATURE_1271_INVALID"
            );
        } else if (signatureType == SignatureType.EIP1654) {
            require(
                ERC1654(signer).isValidSignature(keccak256(dataToHash), signature) == ERC1654_MAGICVALUE,
                "SIGNATURE_1654_INVALID"
            );
        } else {
            address actualSigner = keccak256(dataToHash).recover(signature);
            require(signer == actualSigner, "SIGNATURE_WRONG_SIGNER");
        }
    }

    function _approveForwarder(
        address signer,
        bool approved,
        bytes memory signature,
        SignatureType signatureType
    ) internal {
        address forwarder = msg.sender;
        Forwarder storage forwarderData = _forwarders[signer][forwarder];
        uint256 nonce = uint256(forwarderData.nonce);

        _requireValidSignature(signer, forwarder, approved, nonce, signature, signatureType);

        forwarderData.approved = approved;
        forwarderData.nonce = uint248(nonce + 1);
        emit ForwarderApproved(signer, forwarder, approved, nonce);
    }
}