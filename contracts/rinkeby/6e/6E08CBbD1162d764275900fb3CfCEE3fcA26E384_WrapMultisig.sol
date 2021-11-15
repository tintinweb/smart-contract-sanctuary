// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./base/WrapManager.sol";
import "./interfaces/ERC721TokenReceiver.sol";

/// @title Wrap protocol locking contract, based on Gnosis Safe contract work
contract WrapMultisig is MultisigManager, ERC721TokenReceiver {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    string public constant NAME = "Wrap multisig";
    string public constant VERSION = "1.0.0";

    bytes4 private constant ERC20_TRANSFER_SELECTOR =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    bytes4 private constant ERC721_SAFE_TRANSFER_SELECTOR =
        bytes4(keccak256(bytes("safeTransferFrom(address,address,uint256)")));

    //keccak256(
    //    "EIP712Domain(address verifyingContract)"
    //);
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

    //keccak256(
    //    "WrapTx(address to,uint256 value,bytes data,string tezosOperation)"
    //);
    bytes32 private constant UNWRAP_TX_TYPEHASH =
        0x987804e036e2c4c5e32f45ccae87d65fb92de3f7d16998a7fa3910a01da2ab53;

    mapping(string => bool) internal tezosOperations;

    event ExecutionFailure(bytes32 txHash);
    event ExecutionSuccess(bytes32 txHash);
    event ERC20WrapAsked(
        address user,
        address token,
        uint256 amount,
        string tezosDestinationAddress
    );
    event ERC721WrapAsked(
        address user,
        address token,
        uint256 tokenId,
        string tezosDestinationAddress
    );

    bytes32 public domainSeparator;

    /// @notice The administrator will be allowed to modify multisig members and quorum
    /// @param _administrator Administrator of the multisig
    constructor(address _administrator) {
        require(
            _administrator != address(0),
            "WRAP: INVALID_ADMINISTRATOR_PROVIDED"
        );
        administrator = _administrator;
    }

    /// @notice Initialize multisig members and threshold
    /// @dev This function can only be called once and set the domain separator
    /// @param owners Initial members of the multisig
    /// @param threshold Threshold of the multisig
    function setup(address[] calldata owners, uint256 threshold)
        external
        authorized
    {
        require(domainSeparator == 0, "WRAP: DOMAIN_SEPARATOR_ALREADY_SET");
        domainSeparator = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this)
        );
        _setup(owners, threshold);
    }

    /// @notice Transfer ERC20 tokens to the custody on behalf of the user
    /// @param token Token contract address
    /// @param amount Amount to put in custody
    /// @param tezosAddress Destination address of the wrap on Tezos blockchain
    function wrapERC20(
        address token,
        uint256 amount,
        string calldata tezosAddress
    ) external returns (bool success) {
        require(amount > 0, "WRAP: INVALID_AMOUNT");
        _erc20SafeTransferFrom(token, msg.sender, address(this), amount);
        emit ERC20WrapAsked(msg.sender, token, amount, tezosAddress);
        return true;
    }

    function _erc20SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(ERC20_TRANSFER_SELECTOR, from, to, value)
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "WRAP: ERC20_TRANSFER_FAILED"
        );
    }

    /// @notice Transfer ERC721 tokens to the custody on behalf of the user
    /// @param token Token contract address
    /// @param tokenId Id of the NFT to transfer
    /// @param tezosAddress Destination address of the wrap on Tezos blockchain
    function wrapERC721(
        address token,
        uint256 tokenId,
        string calldata tezosAddress
    ) external returns (bool success) {
        _erc721SafeTransferFrom(token, msg.sender, address(this), tokenId);
        emit ERC721WrapAsked(msg.sender, token, tokenId, tezosAddress);
        return true;
    }

    function _erc721SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) private {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(
                    ERC721_SAFE_TRANSFER_SELECTOR,
                    from,
                    to,
                    tokenId
                )
            );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "WRAP: ERC721_TRANSFER_FAILED"
        );
    }

    /// @notice Allow to execute an unwrap transaction signed by multisig members
    /// @dev tezosOperation is used as a nonce to protect against replay attacks
    /// @param to Destination address of the transaction
    /// @param value Ether value
    /// @param data Data paylaod
    /// @param tezosOperation Identifier of the tezos operation used to burn corresponding wrapped assets
    /// @param signatures Packed signature data
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        string calldata tezosOperation,
        bytes calldata signatures
    ) external returns (bool success) {
        require(
            tezosOperations[tezosOperation] == false,
            "WRAP: TRANSACTION_ALREADY_PROCESSED"
        );
        tezosOperations[tezosOperation] = true;
        bytes memory txHashData =
            encodeTransactionData(to, value, data, tezosOperation);
        bytes32 txHash = keccak256(txHashData);
        _checkSignatures(txHash, signatures);
        success = _execute(to, value, data, gasleft());
        if (success) emit ExecutionSuccess(txHash);
        else emit ExecutionFailure(txHash);
    }

    function _execute(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := call(
                txGas,
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    /// @return v v
    /// @return r r
    /// @return s s
    function _signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    /// @dev Checks whether the signature provided is valid for the provided hash. Will revert otherwise.
    /// @param dataHash Hash of the data
    /// @param signatures Signature data that should be verified.
    function _checkSignatures(bytes32 dataHash, bytes memory signatures)
        internal
        view
    {
        uint256 _threshold = threshold;
        require(_threshold > 0, "WRAP: THRESHOLD_NOT_DEFINED");
        require(
            signatures.length >= _threshold.mul(65),
            "WRAP: SIGNATURES_DATA_TOO_SHORT"
        );
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < _threshold; i++) {
            (v, r, s) = _signatureSplit(signatures, i);
            currentOwner = dataHash.toEthSignedMessageHash().recover(v, r, s);
            require(
                currentOwner > lastOwner &&
                    owners[currentOwner] != address(0) &&
                    currentOwner != SENTINEL_OWNERS,
                "WRAP: INVALID_OWNER_PROVIDED"
            );
            lastOwner = currentOwner;
        }
    }

    /// @notice Returns the bytes that are hashed to be signed by owners
    /// @param to Destination address
    /// @param value Ether value
    /// @param data Data payload
    /// @param tezosOperation Identifier of the tezos operation used to burn corresponding wrapped assets
    /// @return Transaction hash bytes
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        string memory tezosOperation
    ) public view returns (bytes memory) {
        bytes32 wrapTxHash =
            keccak256(
                abi.encode(
                    UNWRAP_TX_TYPEHASH,
                    to,
                    value,
                    keccak256(data),
                    tezosOperation
                )
            );
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator,
                wrapTxHash
            );
    }

    /// @notice Returns hash to be signed by owners
    /// @param to Destination address
    /// @param value Ether value
    /// @param data Data payload
    /// @param tezosOperation Identifier of the tezos operation used to burn corresponding wrapped assets
    /// @return Transaction hash
    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        string memory tezosOperation
    ) public view returns (bytes32) {
        return
            keccak256(encodeTransactionData(to, value, data, tezosOperation));
    }

    /// @notice Check if an unwrap were already processed
    /// @param tezosOperation Identifier to check
    /// @return true if already processed, false otherwise
    function isTezosOperationProcessed(string memory tezosOperation)
        public
        view
        returns (bool)
    {
        return tezosOperations[tezosOperation];
    }

    /// @notice Allow ERC721 safe transfers
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0x150b7a02;
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;

/// @title MultisigManager - Manages a set of owners and a threshold to perform actions
/// @notice Owners and threshold is managed by the administrator
contract MultisigManager {
    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    address administrator;
    mapping(address => address) internal owners;
    uint256 ownerCount;
    uint256 internal threshold;

    modifier authorized() {
        require(
            msg.sender == administrator,
            "WRAP: METHOD_CAN_ONLY_BE_CALLED_BY_ADMINISTRATOR"
        );
        _;
    }

    /// @dev Setup function sets initial storage of contract
    /// @param _owners List of owners
    /// @param _threshold Number of required confirmations for a Wrap transaction
    function _setup(address[] memory _owners, uint256 _threshold) internal {
        require(threshold == 0, "WRAP: CONTRACT_ALREADY_SETUP");
        require(
            _threshold <= _owners.length,
            "WRAP: THRESHOLD_CANNOT_EXCEED_OWNER_COUNT"
        );
        require(_threshold >= 1, "WRAP: THRESHOLD_NEEED_TO_BE_GREETER_THAN_0");
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(
                owner != address(0) && owner != SENTINEL_OWNERS,
                "WRAP: INVALID_OWNER_PROVIDED"
            );
            require(
                owners[owner] == address(0),
                "WRAP: DUPLICATE_OWNER_ADDRESS_PROVIDED"
            );
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev Allows to add a new owner and update the threshold at the same time
    /// @notice Adds the owner `owner` and updates the threshold to `_threshold`
    /// @param owner New owner address
    /// @param _threshold New threshold
    function addOwnerWithThreshold(address owner, uint256 _threshold)
        public
        authorized
    {
        require(
            owner != address(0) && owner != SENTINEL_OWNERS,
            "WRAP: INVALID_OWNER_ADDRESS_PROVIDED"
        );
        require(
            owners[owner] == address(0),
            "WRAP: ADDRESS_IS_ALREADY_AN_OWNER"
        );
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to remove an owner and update the threshold at the same time
    /// @notice Removes the owner `owner` and updates the threshold to `_threshold`
    /// @param prevOwner Owner that pointed to the owner to be removed in the linked list
    /// @param owner Owner address to be removed
    /// @param _threshold New threshold
    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) public authorized {
        require(
            ownerCount - 1 >= _threshold,
            "WRAP: NEW_OWNER_COUNT_NEEDS_TO_BE_LONGER_THAN_THRESHOLD"
        );
        require(
            owner != address(0) && owner != SENTINEL_OWNERS,
            "WRAP: INVALID_OWNER_ADDRESS_PROVIDED"
        );
        require(
            owners[prevOwner] == owner,
            "WRAP: INVALID_PREV_OWNER_OWNER_PAIR_PROVIDED"
        );
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to swap/replace an owner with another address
    /// @notice Replaces the owner `oldOwner` with `newOwner`
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced
    /// @param newOwner New owner address
    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    ) public authorized {
        require(
            newOwner != address(0) && newOwner != SENTINEL_OWNERS,
            "WRAP: INVALID_OWNER_ADDRESS_PROVIDED"
        );
        require(
            owners[newOwner] == address(0),
            "WRAP: ADDRESS_IS_ALREADY_AN_OWNER"
        );
        require(
            oldOwner != address(0) && oldOwner != SENTINEL_OWNERS,
            "WRAP: INVALID_OWNER_ADDRESS_PROVIDED"
        );
        require(
            owners[prevOwner] == oldOwner,
            "WRAP: INVALID_PREV_OWNER_OWNER_PAIR_PROVIDED"
        );
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev Allows to update the number of required confirmations
    /// @notice Changes the threshold to `_threshold`
    /// @param _threshold New threshold
    function changeThreshold(uint256 _threshold) public authorized {
        require(
            _threshold <= ownerCount,
            "WRAP: THRESHOLD_CANNOT_EXCEED_OWNER_COUNT"
        );
        require(_threshold >= 1, "WRAP: THRESHOLD_NEEED_TO_BE_GREETER_THAN_0");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    /// @notice Get multisig threshold
    /// @return Threshold
    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    /// @notice Allow to check if an address is owner of the multisig
    /// @return True if owner, false otherwise
    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /// @notice Get multisig members
    /// @return Owners list
    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }

    /// @notice Get current multisig administrator
    /// @return Administrator address
    function getAdministrator() public view returns (address) {
        return administrator;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;

interface ERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

