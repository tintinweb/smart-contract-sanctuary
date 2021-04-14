/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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

// File: contracts/SignatureVerifier.sol

pragma solidity >=0.4.22 <0.8.0;


contract SignatureVerifier {
    using ECDSAUpgradeable for bytes32;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    //function initialize() internal initializer {}

    function recover(bytes32 _hash, Signature memory _signature) internal pure returns (address) {
        bytes32 eth_msg = _hash.toEthSignedMessageHash();
        return eth_msg.recover(_signature.v, _signature.r, _signature.s);
    }

    function decodeSignature(bytes memory _bytes) internal pure returns (Signature memory) {
        require(_bytes.length==65, "code 0 in monitored log");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_bytes, 32))
            s := mload(add(_bytes, 64))
            v := byte(0, mload(add(_bytes, 96)))
        }
        Signature memory sig;
        sig.r = r;
        sig.s = s;
        sig.v = v;
        return sig;
    }
}

// File: contracts/MonitoredLogVerifier.sol

pragma solidity >=0.4.22 <0.8.0;


contract MonitoredLogVerifier {
    using ECDSAUpgradeable for bytes32;

    uint constant DEVICE_ID_SIZE = 32;
    uint constant UPDATE_HASH_SIZE = 32;
    uint constant MONITORED_LOG_SIZE = DEVICE_ID_SIZE + UPDATE_HASH_SIZE;

    //bytes internal logBytes;

    struct MonitoredLog {
        bytes32 deviceId;
        bytes32 updateHash;
    }

    //function initialize() internal initializer {}

    /*function getLogByte(uint i) internal returns (bytes1) {
        return logBytes[i];
    }*/

    function toBytes(MonitoredLog memory _log) internal pure returns (bytes memory) {
        //byte[] memory decode_bytes = new byte[](MONITORED_LOG_SIZE);
        /*uint16 i=0;
        for(i=0;i<DEVICE_ID_SIZE;i++) {
            //decode_bytes[i] = _log.deviceId[i];
            logBytes.push( _log.deviceId[i]);
        }
        for(i=0;i<UPDATE_HASH_SIZE;i++) {
            //decode_bytes[DEVICE_ID_SIZE+i] = _log.updateHash[i];
            logBytes.push(_log.updateHash[i]);*/
        //}
        bytes memory decodeBytes = abi.encodePacked(_log.deviceId,_log.updateHash);
        require(decodeBytes.length==MONITORED_LOG_SIZE,"toBytes Failed");
        return decodeBytes;

    }

    function decodeMonitoredLog(bytes calldata _bytes, uint _initPointer) internal pure returns (bytes32, bytes32) {
        require(_bytes.length==MONITORED_LOG_SIZE, "code 0 in monitored log");
        bytes32 deviceId = abi.decode(_bytes[_initPointer:_initPointer+DEVICE_ID_SIZE],(bytes32));
        bytes32 updateHash = abi.decode(_bytes[_initPointer+DEVICE_ID_SIZE:_initPointer+DEVICE_ID_SIZE+UPDATE_HASH_SIZE],(bytes32));
        return (deviceId, updateHash);
    }
}

// File: contracts/UpdateMsgVerifier.sol

pragma solidity >=0.4.22 <0.8.0;






contract UpdateMsgVerifier is SignatureVerifier, MonitoredLogVerifier {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint32;
    using SafeMathUpgradeable for uint64;

    uint64 constant UPDATE_PERIOD = 120;
    uint constant PREVIOUS_HASH_SIZE = 32;
    uint constant STATE_HASH_SIZE = 32;
    uint constant INDEX_SIZE = 4;
    uint constant TIMESTAMP_SIZE = 8;
    uint constant PUBLIC_KEY_SIZE = 64;
    uint constant MAX_MONITOR_NUMBER = 50;
    uint constant UPDATE_MSG_SIZE = DEVICE_ID_SIZE + PREVIOUS_HASH_SIZE + STATE_HASH_SIZE + INDEX_SIZE + TIMESTAMP_SIZE + PUBLIC_KEY_SIZE + MAX_MONITOR_NUMBER*MONITORED_LOG_SIZE;

    struct UpdateMsg {
        bytes32 deviceId;
        bytes32 previousHash;
        bytes32 stateHash;
        bytes4 index;
        bytes8 timestamp;
        bytes publicKey;
        MonitoredLog[MAX_MONITOR_NUMBER] monitoredLogs;
    }

    //bytes msgBytes;

    function toBytes(UpdateMsg memory _msg) private pure returns (bytes memory) {
        //bytes memory decode_bytes;
        //uint lastIndex = 0;
        /*uint16 i=0;
        for(i=0;i<DEVICE_ID_SIZE;i++) {
            //decode_bytes[lastIndex+i] = _msg.deviceId[i];
            msgBytes.push(_msg.deviceId[i]);
        }
        //lastIndex += DEVICE_ID_SIZE;
        for(i=0;i<PREVIOUS_HASH_SIZE;i++) {
            //decode_bytes[lastIndex+i] = _msg.previousHash[i];
            msgBytes.push(_msg.previousHash[i]);
        }
        //lastIndex += PREVIOUS_HASH_SIZE;
        for(i=0;i<STATE_HASH_SIZE;i++) {
            //decode_bytes[lastIndex+i] = _msg.stateHash[i];
            msgBytes.push(_msg.stateHash[i]);
        }
        //lastIndex += STATE_HASH_SIZE;
        for(i=0;i<INDEX_SIZE;i++) {
            //decode_bytes[lastIndex+i] = _msg.index[i];
            msgBytes.push(_msg.index[i]);
        }
        //lastIndex += INDEX_SIZE;
        for(i=0;i<TIMESTAMP_SIZE;i++) {
            //decode_bytes[lastIndex+i] = _msg.timestamp[i];
            msgBytes.push(_msg.timestamp[i]);
        }
        //lastIndex += TIMESTAMP_SIZE;
        for(i=0;i<PUBLIC_KEY_SIZE;i++) {
            //decode_bytes[lastIndex+i] = _msg.publicKey[i];
            msgBytes.push(_msg.publicKey[i]);
        }
        //lastIndex += PUBLIC_KEY_SIZE;
        for(i=0;i<MAX_MONITOR_NUMBER;i++) {
            MonitoredLogVerifier.toBytes(_msg.monitoredLogs[i]);
            uint16 j=0;
            for(j=0;j<MonitoredLogVerifier.MONITORED_LOG_SIZE;j++){
                msgBytes.push(MonitoredLogVerifier.logBytes[j]);
            }
        }*/
        //bytes memory bytesMemory = new bytes(UPDATE_MSG_SIZE);
        //bytesMemory = msgBytes;
        //return bytesMemory;
        bytes memory msgBytes1 = abi.encodePacked(_msg.deviceId,_msg.previousHash,_msg.stateHash,_msg.index,_msg.timestamp,_msg.publicKey);
        bytes memory msgBytes2 = msgBytes1;
        bytes memory logBytes;
        for(uint16 i=0;i<MAX_MONITOR_NUMBER;i++) {
            logBytes = MonitoredLogVerifier.toBytes(_msg.monitoredLogs[i]);
            msgBytes2 = abi.encodePacked(msgBytes2,logBytes);
        }
        require(msgBytes2.length==UPDATE_MSG_SIZE,"Invalid MsgSize");
        return msgBytes2;
    }

    function hasher(UpdateMsg memory _msg) internal pure returns (bytes32) {
        bytes memory inputBytes = toBytes(_msg);
        bytes32 hashed = sha256(inputBytes);
        return hashed;
    }

    function verify(UpdateMsg memory _old_msg, UpdateMsg memory _new_msg, Signature memory _updateSignature) internal returns (bool) {
        bool idOk = uint256(_old_msg.deviceId) == uint256(_new_msg.deviceId);
        require(idOk,"invalid id");
        bytes32 validPreviousHash = hasher(_old_msg);
        bool previousHashOk = validPreviousHash==_new_msg.previousHash;
        require(previousHashOk,"invalid previousHash");
        bool indexOk = uint32(_old_msg.index).add(1) == uint32(_new_msg.index);
        require(indexOk,"invalid index");
        bool timestampOk = uint64(_old_msg.timestamp).add(UPDATE_PERIOD) <= uint64(_new_msg.timestamp) && uint64(_new_msg.timestamp) <  uint64(_old_msg.timestamp).add(2*UPDATE_PERIOD);
        require(timestampOk,"invalid timestamp");
        address oldAddress = address(uint160(uint256(keccak256(_old_msg.publicKey))));//_old_msg.publicKey != _new_msg.publicKey;
        address newAddress = address(uint160(uint256(keccak256(_new_msg.publicKey))));
        bool publicKeyOk = oldAddress!=newAddress;
        require(publicKeyOk,"invalid publicKey");
        bytes32 updateHash = hasher(_new_msg);
        address validAddress = SignatureVerifier.recover(updateHash,_updateSignature);
        bool signatureOk = oldAddress == validAddress;
        require(signatureOk,"invalid signature");
        return true;
    }
}

// File: contracts/Radoa.sol

pragma solidity >=0.4.22 <0.8.0;






contract Radoa is Initializable, UpdateMsgVerifier {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using ECDSAUpgradeable for bytes32;

    uint256 constant SUBMISSION_PERIOD = 10800;

    mapping (address=>bytes32) deviceIdOfAddress;
    mapping (bytes32=>bool) isInitializedOfDeviceId;
    mapping (bytes32=>UpdateMsgVerifier.UpdateMsg) lastMsgOfDeviceId;
    mapping (bytes32=>bytes4) lastIndexOfDeviceId;
    mapping (bytes4=>uint64) openTimeOfIndex;
    mapping (bytes4=>uint64) closeTimeOfIndex;
    uint32 lastOpenedIndex;
    uint32 lastClosedIndex;
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
        lastClosedIndex = 0;
        lastOpenedIndex = 1;
        //uint initOpenTime = block.timestamp.add(uint(UPDATE_PERIOD));
        openTimeOfIndex[bytes4(lastOpenedIndex)] = uint64(block.timestamp);
        closeTimeOfIndex[bytes4(lastClosedIndex)] = uint64(block.timestamp);
    }

    function getDeviceIdOfAddress(address _address) public view returns (bytes32) {
        bytes32 deviceId =  deviceIdOfAddress[_address];
        require(isInitializedOfDeviceId[deviceId],"code 0 in getDeviceIdOfAddress");
        return deviceId;
    }

    function getLastIndex(bytes32 _deviceId) public view returns (bytes4) {
        require(isInitializedOfDeviceId[_deviceId],"code 0 in getLastIndex");
        return lastIndexOfDeviceId[_deviceId];
    }

    function getStateHash(bytes32 _deviceId) public view returns (bytes32) {
        return lastMsgOfDeviceId[_deviceId].stateHash;
    }

    function getLastOpenedIndex() public view returns (uint32) {
        return lastOpenedIndex;
    }

    function getLastClosedIndex() public view returns (uint32) {
        return lastClosedIndex;
    }

    function getOpenTime(bytes4 _index) public view returns (uint64) {
        return openTimeOfIndex[_index];
    }

    function getCloseTime(bytes4 _index) public view returns (uint64) {
        return closeTimeOfIndex[_index];
    }
    

    function isHealthDevice(bytes32 _deviceId) public view returns (bool) {
        require(isInitializedOfDeviceId[_deviceId],"code 0 in isHealthyDevice");
        bytes4 lastIndexOfDevice = lastMsgOfDeviceId[_deviceId].index;
        return lastClosedIndex <= uint32(lastIndexOfDevice);
    }

    function pubHasher(bytes32 _newDeviceId, bytes32 _newPreviousHash, bytes32 _newStateHash, bytes4 _newIndex, bytes8 _newTimestamp, bytes memory _newPublicKey) public view returns (bytes32) {
        UpdateMsg memory _msg;
        _msg.deviceId = _newDeviceId;
        _msg.previousHash = _newPreviousHash;
        _msg.index = _newIndex;
        _msg.stateHash = _newStateHash;
        _msg.timestamp = _newTimestamp;
        _msg.publicKey = _newPublicKey;
        return UpdateMsgVerifier.hasher(_msg);
    }

    function puSignbHasher(bytes32 _newDeviceId, bytes32 _newPreviousHash, bytes32 _newStateHash, bytes4 _newIndex, bytes8 _newTimestamp, bytes memory _newPublicKey) public view returns (bytes32) {
        bytes32 rawHash = pubHasher(_newDeviceId,_newPreviousHash,_newStateHash,_newIndex,_newTimestamp,_newPublicKey);
        bytes32 signedMsg = rawHash.toEthSignedMessageHash();
        return signedMsg;
    }

    function openAttestation() public {
        uint64 lastOpenTime = openTimeOfIndex[bytes4(lastOpenedIndex)];
        //uint nextOpenTime = uint256(lastOpenTime).add(uint(UPDATE_PERIOD));
        require(block.timestamp>=lastOpenTime,"code 0 in openAttestation");
        lastOpenedIndex ++;
        openTimeOfIndex[bytes4(lastOpenedIndex)] = uint64(block.timestamp);
    }

    function closeAttestation() public {
        uint64 lastOpenTime = openTimeOfIndex[bytes4(lastClosedIndex)];
        uint closeLimitTime = uint256(lastOpenTime).add(uint(SUBMISSION_PERIOD));
        require(block.timestamp>=closeLimitTime,"code 0 in closeAttestation");
        lastClosedIndex ++;
        closeTimeOfIndex[bytes4(lastClosedIndex)] = uint64(block.timestamp);
    }


    function registerDevice(address _deviceAddress, bytes32 _deviceId, bytes memory _publicKey, bytes8 _timestamp) public onlyOwner {
        require(!isInitializedOfDeviceId[_deviceId],"code 0 in registerDevice");
        deviceIdOfAddress[_deviceAddress] = _deviceId;
        isInitializedOfDeviceId[_deviceId] = true;
        lastMsgOfDeviceId[_deviceId].deviceId = _deviceId;
        lastMsgOfDeviceId[_deviceId].previousHash = bytes32(0);
        lastMsgOfDeviceId[_deviceId].stateHash = bytes32(0);
        lastMsgOfDeviceId[_deviceId].index = bytes4(lastClosedIndex);
        lastMsgOfDeviceId[_deviceId].timestamp = _timestamp;
        lastMsgOfDeviceId[_deviceId].publicKey = _publicKey;
        lastIndexOfDeviceId[_deviceId] = bytes4(lastClosedIndex);
    }

    function addUpdateMsg(bytes32 _newDeviceId, bytes32 _newPreviousHash, bytes32 _newStateHash, bytes4 _newIndex, bytes8 _newTimestamp, bytes memory _newPublicKey, bytes memory _signature) public {
        require(isInitializedOfDeviceId[_newDeviceId],"code 0 in registerDevice");
        require(deviceIdOfAddress[msg.sender]==_newDeviceId,"code 1 in addUpdateMsg");
        require(isHealthDevice(_newDeviceId),"code 2 in addUpdateMsg");
        uint limitTime = uint256(openTimeOfIndex[_newIndex]).add(SUBMISSION_PERIOD);
        require(block.timestamp<=limitTime,"code 3 in addUpdateMsg");
        UpdateMsgVerifier.UpdateMsg memory lastMsg = lastMsgOfDeviceId[_newDeviceId];
        UpdateMsg memory newMsg;
        newMsg.deviceId = _newDeviceId;
        newMsg.previousHash = _newPreviousHash;
        newMsg.index = _newIndex;
        newMsg.stateHash = _newStateHash;
        newMsg.timestamp = _newTimestamp;
        newMsg.publicKey = _newPublicKey;
        Signature memory updateSignature = SignatureVerifier.decodeSignature(_signature);
        bool isValidMsg = UpdateMsgVerifier.verify(lastMsg,newMsg,updateSignature);
        require(isValidMsg,"code 4 in addUpdateMsg");
        lastMsgOfDeviceId[_newDeviceId].deviceId = _newDeviceId;
        lastMsgOfDeviceId[_newDeviceId].previousHash = _newPreviousHash;
        lastMsgOfDeviceId[_newDeviceId].index = _newIndex;
        lastMsgOfDeviceId[_newDeviceId].stateHash = _newStateHash;
        lastMsgOfDeviceId[_newDeviceId].timestamp = _newTimestamp;
        lastMsgOfDeviceId[_newDeviceId].publicKey = _newPublicKey;
        lastIndexOfDeviceId[_newDeviceId] = _newIndex;
    }

    function getAddressFromPubKey( bytes memory _publicKey) public view returns (address) {
        return address(uint160(uint256(keccak256(_publicKey))));
    } 


    function recoverAddress(bytes32 _msg, bytes32 r, bytes32 s, uint8 v) public view returns (address) {
        Signature memory signature;
        signature.r = r;
        signature.s = s;
        signature.v = v;
        return SignatureVerifier.recover(_msg,signature);
    }
}

// File: contracts/CameraWatcher.sol

pragma solidity >=0.4.22 <0.8.0;




contract CameraWatcher is Initializable {
    using SafeMathUpgradeable for uint256;

    event RegisteredPicture (
        bytes32 indexed deviceId,
        bytes4 indexed authedIndex,
        bytes32 indexed pictureHash
    );

    address owner;
    Radoa radoa;
    mapping (bytes32=>bytes4) lastIndexOfDeviceId;
    mapping (bytes32=>bool) isRegisteredPicture;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function initialize(address _radoaAddress) public initializer {
        owner = msg.sender;
        radoa = Radoa(_radoaAddress);
    }

    function recordPicture() public {
        bytes32 deviceId = radoa.getDeviceIdOfAddress(msg.sender);
        bytes4 lastAuthedIndex = radoa.getLastIndex(deviceId);
        require(uint256(uint32(lastAuthedIndex))==uint256(uint32(lastIndexOfDeviceId[deviceId])).add(1),"code 0 in recordState");
        require(radoa.isHealthDevice(deviceId),"code 1 in recordState");
        bytes32 stateHash = radoa.getStateHash(deviceId);
        lastIndexOfDeviceId[deviceId] = lastAuthedIndex;
        isRegisteredPicture[stateHash] = true;
        emit RegisteredPicture(deviceId, lastAuthedIndex, stateHash);
    }
}