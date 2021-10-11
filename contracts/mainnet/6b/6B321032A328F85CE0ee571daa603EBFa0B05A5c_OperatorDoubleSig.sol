// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OperatorDoubleSig is Ownable {
    using SafeMath for uint256;
    uint256 BUNDLE_MAXIMUM = 50;

    // Events
    event SafeModeActivated(address msgSender);
    event SafeModeDeactivated(address msgSender);

    event Transacted(
        address msgSender, // Address of the sender of the message initiating the transaction
        address[2] signers, // Address of the signers
        bytes32 operation, // Operation hash (see Data Formats)
        address toAddress, // The address the transaction was sent to
        uint256 value, // Amount of Wei sent to the address
        bytes data // Data sent when invoking the transaction
    );
    event DailyLimitChange(uint256 origin, uint256 current);

    // Public fields
    address[] public signers; // The addresses that can co-sign transactions on the wallet
    bool public safeMode = false; // When active, wallet may only send to signer addresses

    // Internal fields
    mapping(bytes32 => bool) historyTransactions;

    uint public txDailyLimit;
    uint lastDay;
    uint txToday;

    /**
     * Set up a simple multi-sig wallet by specifying the signers allowed to be used on this wallet.
     * 2 signers will be required to send a transaction from this wallet.
     * Note: The sender is NOT automatically added to the list of signers.
     * Signers CANNOT be changed once they are set
     *
     * @param allowedSigners An array of signers on the wallet
     */
    constructor(address[] memory allowedSigners, uint256 txDailyLimit_) {
        if (allowedSigners.length != 3) {
            // Invalid number of signers
            revert();
        }
        signers = allowedSigners;
        txDailyLimit = txDailyLimit_;
    }

    receive() external payable {
        if (msg.value > 0) {
            revert("can't receive value");
        }
    }

    modifier underLimit()
    {
        if (block.timestamp > lastDay + 24 hours) {
            lastDay = block.timestamp;
            txToday = 0;
        }
        txToday = txToday.add(1);
        require(txToday <= txDailyLimit, "Exceed daily limit");
        _;
    }

    modifier notInSafeMode() {
        require(!safeMode, "In safe mode!");
        _;
    }

    function changeDailyLimit(uint256 limit_) external onlyOwner returns (uint256) {
        uint256 preDailyLimit = txDailyLimit;
        txDailyLimit = limit_;
        emit DailyLimitChange(preDailyLimit, txDailyLimit);
        return txDailyLimit;
    }

    /**
     * Determine if an address is a signer on this wallet
     * @param signer address to check
     * returns boolean indicating whether address is signer or not
     */
    function isSigner(address signer) public view returns (bool) {
        // Iterate through all signers on the wallet and
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                return true;
            }
        }
        return false;
    }

    /**
     * get all signers
     * returns all signers
     */
    function getSigners() external view returns (address[] memory) {
        return signers;
    }

    /**
     * Execute a multi-signature transaction from this wallet using 2 signers.
     * Salt are used to prevent replay attacks and may not be repeated.
     *
     * @param toAddress the destination address to send an outgoing transaction
     * @param value the amount in Wei to be sent
     * @param data the data to send to the toAddress when invoking the transaction
     * @param expireTime the number of seconds since 1970 for which this transaction is valid
     * @param salt salt used to prevent duplicate hashes
     * @param signature1 see Data Formats
     * @param signature2 see Data Formats
     */
    function sendMultiSig(
        address toAddress,
        uint256 value,
        bytes memory data,
        uint256 expireTime,
        uint256 salt,
        bytes memory signature1,
        bytes memory signature2
    ) external underLimit notInSafeMode {
        // Verify that the transaction has not expired
        require(expireTime > block.timestamp, "transaction expired");

        // Verify the other signer
        bytes32 operationHash = keccak256(abi.encodePacked("ETHER", address(this), block.chainid, toAddress, value, data, expireTime, salt));

        address[2] memory signerSet;
        signerSet[0] = verifyMultiSig(operationHash, signature1);
        signerSet[1] = verifyMultiSig(operationHash, signature2);

        require(signerSet[0] != signerSet[1], "can't sign by same signer");

        require(!historyTransactions[operationHash], "Transaction has been executed");
        // Try to insert operationHash
        historyTransactions[operationHash] = true;

        // Success, send the transaction
        if (!external_call(toAddress, value, data)) {
            // Failed executing transaction
            revert("execution failed");
        }
        emit Transacted(msg.sender, signerSet, operationHash, toAddress, value, data);
    }

    /**
     * Execute a multi-signature transaction from this wallet using 2 signers.
     * Salt are used to prevent replay attacks and may not be repeated.
     *
     * @param toAddresses the destination address to send an outgoing transaction
     * @param values the amount in Wei to be sent
     * @param datas the data to send to the toAddress when invoking the transaction
     * @param expireTime the number of seconds since 1970 for which this transaction is valid
     * @param salts salt used to prevent duplicate hashes
     * @param signature1 see Data Formats
     * @param signature2 see Data Formats
     */
    function sendMultiSigBundle(
        address[] memory toAddresses,
        uint256[] memory values,
        bytes[] memory datas,
        uint256 expireTime,
        uint256[] memory salts,
        bytes memory signature1,
        bytes memory signature2
    ) external underLimit notInSafeMode {
        require(toAddresses.length <= BUNDLE_MAXIMUM && values.length <= BUNDLE_MAXIMUM && datas.length <= BUNDLE_MAXIMUM && salts.length <= BUNDLE_MAXIMUM, "Exceed limit");
        require(toAddresses.length == datas.length && toAddresses.length == values.length && toAddresses.length == salts.length);
        // Verify that the transaction has not expired
        require(expireTime > block.timestamp, "transaction expired");

        address[2] memory signerSet;
        bytes32 bundleHash;

        // "{  }" for avoid stack too deep errors
        {
            bytes memory packedData;
            bytes memory packedAddress;
            bytes memory packedValues;
            bytes memory packedSalt;
            for (uint256 i = 0; i < datas.length; i++) {
                packedData = abi.encodePacked(packedData, datas[i]);
                packedValues = abi.encodePacked(packedValues, values[i]);
                packedAddress = abi.encodePacked(packedAddress, toAddresses[i]);
                packedSalt = abi.encodePacked(packedSalt, salts[i]);
            }
            bytes32[4] memory hashes = [keccak256(packedAddress), keccak256(packedValues), keccak256(packedData), keccak256(packedSalt)];

            // Verify the other signer
            bundleHash = keccak256(abi.encodePacked("ETHER", address(this), block.chainid, hashes[0], hashes[1], hashes[2], expireTime, hashes[3]));
        }

        {
            signerSet[0] = verifyMultiSig(bundleHash, signature1);
            signerSet[1] = verifyMultiSig(bundleHash, signature2);

            require(signerSet[0] != signerSet[1], "can't sign by same signer");

            // Success, send all transaction
            for (uint256 i = 0; i < datas.length; i++) {
                bytes32 operationHash = keccak256(abi.encodePacked("ETHER", address(this), block.chainid, toAddresses[i], values[i], datas[i], expireTime, salts[i]));
                require(!historyTransactions[operationHash], string(abi.encodePacked("[#", toString(i) ,"]Transaction has been executed")));
                // Try to insert operationHash
                historyTransactions[operationHash] = true;

                if (!external_call(toAddresses[i], values[i], datas[i])) {
                    // Failed executing transaction
                    revert(string(abi.encodePacked("[#", toString(i) ,"]execution failed")));
                }
                emit Transacted(msg.sender, signerSet, operationHash, toAddresses[i], values[i], datas[i]);
            }
        }
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(
        address destination,
        uint256 value,
        bytes memory data
    ) internal returns (bool) {
        bool result;
        assembly {
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
            gas(),
            destination,
            value,
            d,
            mload(data), // Size of the input (in bytes)
            0,
            0 // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    function calcMaxWithdraw()
    external
    view
    returns (uint)
    {
        if (block.timestamp > lastDay + 24 hours)
            return txDailyLimit;
        return txDailyLimit - txToday;
    }

    /**
     * Do common multisig verification for both eth sends and erc20token transfers
     *
     * @param operationHash see Data Formats
     * @param signature see Data Formats
     */
    function verifyMultiSig(
        bytes32 operationHash,
        bytes memory signature
    ) private view returns (address) {
        address signer = recoverAddressFromSignature(operationHash, signature);
        require(signer != address(0) && isSigner(signer), "invalid signer");
        return signer;
    }

    /**
     * puts contract into safe mode.
     */
    function activateSafeMode() external onlyOwner {
        safeMode = true;
        emit SafeModeActivated(msg.sender);
    }

    function deactivateSafeMode() external onlyOwner {
        safeMode = false;
        emit SafeModeDeactivated(msg.sender);
    }

    /**
     * Gets signer's address using ecrecover
     * @param operationHash see Data Formats
     * @param signature see Data Formats
     * returns address recovered from the signature
     */
    function recoverAddressFromSignature(
        bytes32 operationHash,
        bytes memory signature
    ) private pure returns (address) {
        if (signature.length != 65) {
            revert("invalid signature length");
        }
        // We need to unpack the signature, which is given as an array of 65 bytes (like eth.sign)
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }
        if (v < 27) {
            v += 27;
            // Ethereum versions are 27 or 28 as opposed to 0 or 1 which is submitted by some signing libs
        }
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedProof =
        keccak256(abi.encodePacked(prefix, operationHash));
        return ecrecover(prefixedProof, v, r, s);
    }
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}

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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}