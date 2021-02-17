// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "./utils/DistributedOwnable.sol";
import "./interfaces/IBridge.sol";
import "./utils/Nonce.sol";
import "./utils/RedButton.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";


/**
    @title Basic smart contract for implementing Bridge logic.
    @dev Uses DistributedOwnable contract for storing list of relays.
**/
contract Bridge is Initializable, DistributedOwnable, RedButton, Nonce, IBridge {
    using SafeMath for uint;

    BridgeConfiguration bridgeConfiguration;

    /**
        @notice Bridge initializer
        @param owners Initial list of owners addresses
        @param admin Red button caller, probably multisig
        @param _bridgeConfiguration Bridge configuration
    **/
    function initialize(
        address[] memory owners,
        address admin,
        BridgeConfiguration memory _bridgeConfiguration
    ) public initializer {
        for (uint i=0; i < owners.length; i++) {
            grantOwnership(owners[i]);
        }

        _setAdmin(admin);

        bridgeConfiguration = _bridgeConfiguration;
    }

    /*
        Is address relay or not.
        Handy wrapper around ownership functionality + Bridge specific names.
        @param candidate Address
        @returns Boolean is relay or not
    */
    function isRelay(
        address candidate
    ) override public view returns(bool) {
        return isOwner(candidate);
    }

    /**
     * @notice Count how much signatures are made by owners.
     * @param payload Bytes payload, which was signed
     * @param signatures Bytes array with payload signatures
    */
    function countRelaysSignatures(
        bytes memory payload,
        bytes[] memory signatures
    ) public override view returns(uint) {
        uint ownersConfirmations = 0;

        for (uint i=0; i<signatures.length; i++) {
            address signer = recoverSignature(payload, signatures[i]);

            if (isOwner(signer)) ownersConfirmations++;
        }

        return ownersConfirmations;
    }

    /*
        Update Bridge configuration
        @dev Check enough owners signed and apply update
        @param payload Bytes encoded BridgeConfiguration structure
    */
    function updateBridgeConfiguration(
        bytes memory payload,
        bytes[] memory signatures
    ) public {
        require(
            countRelaysSignatures(
                payload,
                signatures
            ) >= bridgeConfiguration.bridgeUpdateRequiredConfirmations,
            'Not enough confirmations'
        );

        (BridgeConfiguration memory _bridgeConfiguration) = abi.decode(payload, (BridgeConfiguration));

        require(nonceNotUsed(_bridgeConfiguration.nonce), 'Nonce already used');

        bridgeConfiguration = _bridgeConfiguration;

        rememberNonce(_bridgeConfiguration.nonce);
    }

    /*
        Update Bridge relay
        @dev Check enough owners signed and apply update
        @param payload Bytes encoded BridgeRelay structure
    */
    function updateBridgeRelay(
        bytes memory payload,
        bytes[] memory signatures
    ) public {
        require(
            countRelaysSignatures(
                payload,
                signatures
            ) >= bridgeConfiguration.bridgeUpdateRequiredConfirmations,
            'Not enough confirmations'
        );

        (BridgeRelay memory bridgeRelay) = abi.decode(payload, (BridgeRelay));

        require(nonceNotUsed(bridgeRelay.nonce), 'Nonce already used');

        if (bridgeRelay.action) {
            grantOwnership(bridgeRelay.account);
        } else {
            removeOwnership(bridgeRelay.account);
        }

        rememberNonce(bridgeRelay.nonce);
    }

    /*
        Get current bridge configuration
        @return Bridge configuration structure
    */
    function getConfiguration() public view override returns (BridgeConfiguration memory) {
        return bridgeConfiguration;
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;

import "./../libraries/ECDSA.sol";
import "./../libraries/Array.sol";


contract DistributedOwnable {
    using ECDSA for bytes32;
    using Array for address[];

    mapping (address => bool) private _owners;
    address[] private _ownersList;

    event OwnershipGranted(address indexed newOwner);
    event OwnershipRemoved(address indexed removedOwner);

    /**
     * @notice Check if account has ownership
     * @param checkAddr Address to be checked
     * @return Boolean status of the address
     */
    function isOwner(address checkAddr) public view returns (bool) {
        return _owners[checkAddr];
    }

    /**
     * @notice Get the list of owners
     * @return List of addresses
     */
    function getOwners() public view returns(address[] memory) {
        return _ownersList;
    }

    /**
     * @dev Handy wrapper for Solidity recover function. Returns signature author address.
     * @param payload - payload which was signed
     * @param signature - payload signature
    */
    function recoverSignature(
        bytes memory payload,
        bytes memory signature
    ) public pure returns(address) {
        return keccak256(payload).toBytesPrefixed().recover(signature);
    }

    /**
     * @dev Internal ownership granting.
     * @param newOwner - Account to grant ownership
    */
    function grantOwnership(address newOwner) internal {
        require(!_owners[newOwner], 'Already owner');

        _owners[newOwner] = true;
        _ownersList.push(newOwner);

        emit OwnershipGranted(newOwner);
    }

    /**
     * @dev Internal ownership removing.
     * @param ownerToRemove - Account to remove ownership
    */
    function removeOwnership(address ownerToRemove) internal {
        require(_owners[ownerToRemove], 'Not an owner');

        _owners[ownerToRemove] = false;
        _ownersList.removeByValue(ownerToRemove);

        emit OwnershipRemoved(ownerToRemove);
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


interface IBridge {
    function isRelay(address candidate) external view returns (bool);
    function countRelaysSignatures(
        bytes calldata payload,
        bytes[] calldata signatures
    ) external view returns(uint);

    struct BridgeConfiguration {
        uint16 nonce;
        uint16 bridgeUpdateRequiredConfirmations;
    }

    struct BridgeRelay {
        uint16 nonce;
        address account;
        bool action;
    }

    function getConfiguration() external view returns (BridgeConfiguration memory);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;


/*
    Handy contract for remembering already used nonces.
*/
contract Nonce {
    mapping(uint16 => bool) public nonce;

    event NonceUsed(uint16 _nonce);

    function nonceNotUsed(uint16 _nonce) public view returns(bool) {
        return !nonce[_nonce];
    }

    function rememberNonce(uint16 _nonce) internal {
        nonce[_nonce] = true;

        emit NonceUsed(_nonce);
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/*
    Naturally Red Button functionality.
    Creates special role - admin. He's allowed to perform the list of any
    external calls.
*/
contract RedButton {
    address public admin;

    /*
        Internal function for transferring admin ownership
    */
    function _setAdmin(address _admin) internal {
        admin = _admin;
    }

    /*
        Transfer admin ownership
        @dev Only called by
        @param _newAdmin New admin address
    */
    function transferAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), 'Cant set admin to zero address');
        _setAdmin(_newAdmin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Sender not admin');
        _;
    }

    /*
        Execute list of calls. Any calls allowed - transfer ETH, call any contract any function.
        @param _to List of addresses to which make a calls
        @param _data List of call data, may be empty for ETH transfer
        @param weiAmount List of ETH amounts to send on each call
        @dev All params should be same length
    */
    function externalCallEth(
        address payable[] memory  _to,
        bytes[] memory _data,
        uint256[] memory weiAmount
    ) onlyAdmin public payable {
        require(
            _to.length == _data.length && _data.length == weiAmount.length,
            "Parameters should be equal length"
        );

        for (uint16 i = 0; i < _to.length; i++) {
            _cast(_to[i], _data[i], weiAmount[i]);
        }
    }

    function _cast(
        address payable _to,
        bytes memory _data,
        uint256 weiAmount
    ) internal {
        bytes32 response;

        assembly {
            let succeeded := call(sub(gas(), 5000), _to, weiAmount, add(_data, 0x20), mload(_data), 0, 32)
            response := mload(0)
            switch iszero(succeeded)
            case 1 {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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
library SafeMath {
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;

library ECDSA {

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
      * toBytesPrefixed
      * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
      * and hash the result
      */
    function toBytesPrefixed(bytes32 hash)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.7.0;


library Array {
    function indexOf(address[] storage values, address value) internal view returns(uint) {
        uint i = 0;

        while (values[i] != value) {
            i++;
        }

        return i;
    }

    /** Removes the given value in an array. */
    function removeByValue(address[] storage values, address value) internal {
        uint i = indexOf(values, value);

        removeByIndex(values, i);
    }

    /** Removes the value at the given index in an array. */
    function removeByIndex(address[] storage values, uint i) internal {
        while (i<values.length-1) {
            values[i] = values[i+1];
            i++;
        }

        values.pop();
    }
}

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