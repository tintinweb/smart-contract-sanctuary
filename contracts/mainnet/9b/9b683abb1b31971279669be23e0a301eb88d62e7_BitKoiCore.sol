/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// File: contracts/common/Initializable.sol



pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// File: contracts/common/EIP712Base.sol



pragma solidity ^0.8.0;


contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// File: contracts/common/ContextMixin.sol



pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}
// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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

// File: contracts/common/NativeMetaTransaction.sol



pragma solidity ^0.8.0;



contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol



pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: contracts/ERC721Tradable.sol



pragma solidity ^0.8.0;








contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

// File: contracts/BitKoi.sol



pragma solidity ^0.8.0;

/**
 * @title BitKoi
 * BitKoi - a blockchain game at scale
 */

/// @title mix up two fish and find out which traits they should have
abstract contract BitKoiTraitInterface {
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isBitKoiTraits() virtual public pure returns (bool);

    ///mix up the "genes" of the fish to see which genes our new fish will have
    function smooshFish(uint256 genes1, uint256 genes2, uint256 targetBlock) virtual public returns (uint256);
}

/// @title A facet of BitKoiCore that manages special access privileges.
/// Based on work from Axiom Zen (https://www.axiomzen.co)
contract BitKoiAccessControl {

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused.
    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address payable _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() virtual public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}


/// @title Base contract for KoiPond. Holds all common structs, events and base variables.
/// based on code written for CK by Axiom Zen (https://www.axiomzen.co)
abstract contract BitKoiBase is BitKoiAccessControl, ERC721Tradable {
    /*** EVENTS ***/

    /// @dev The Spawn event is fired whenever a new fish comes into existence. This obviously
    ///  includes any time a fish is created through the spawnFish method, but it is also called
    ///  when a new gen0 fish is created.
    event Spawn(address owner, uint256 koiFishId, uint256 parent1Id, uint256 parent2Id, uint256 genes, uint16 generation, uint64 timestamp);

    event BreedingSuccessful(address owner, uint256 newFishId, uint256 parent1Id, uint256 parent2Id, uint64 cooldownEndBlock);

    /*** DATA TYPES ***/

    struct BitKoi {
        // The fish's genetic code - this will never change for any fish.
        uint256 genes;

        // The timestamp from the block when this fish came into existence.
        uint64 spawnTime;

        // The minimum timestamp after which this fish can engage in spawning
        // activities again.
        uint64 cooldownEndBlock;

        // The ID of the parents of this fish, set to 0 for gen0 fish.
        // With uint32 there's a limit of 4 billion fish
        uint32 parent1Id;
        uint32 parent2Id;

        // Set to the index in the cooldown array (see below) that represents
        // the current cooldown duration for this fish. This starts at zero
        // for gen0 fish, and is initialized to floor(generation/2) for others.
        // Incremented by one for each successful breeding action.
        uint16 cooldownIndex;

        // The "generation number" of this fish. Fish minted by the KP contract
        // for sale are called "gen0" and have a generation number of 0. The
        // generation number of all other fish is the larger of the two generation
        // numbers of their parents, plus one.
        uint16 generation;
    }

    /*** CONSTANTS ***/

    /// @dev A lookup table indicating the cooldown duration after any successful
    ///  breeding action, called "cooldown" Designed such that the cooldown roughly
    ///  doubles each time a fish is bred, encouraging owners not to just keep breeding the same fish over
    ///  and over again. Caps out at one week (a fish can breed an unbounded number
    ///  of times, and the maximum cooldown is always seven days).
    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    // An approximation of currently how many seconds are in between blocks.
    uint256 public secondsPerBlock = 15;

    /*** STORAGE ***/

    /// @dev An array containing the KoiFish struct for all KoiFish in existence. The ID
    /// of each fish is actually an index into this array. Fish 0 has an invalid genetic
    /// code and can't be used to produce offspring.
    BitKoi[] bitKoi;

    /// @dev A mapping from fish IDs to the address that owns them. All fish have
    ///  some valid owner address, even gen0 fish are created with a non-zero owner.
    mapping (uint256 => address) bitKoiIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from KoiFishIDs to an address that has been approved to call
    ///  transferFrom(). Each KoiFish can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) bitKoiIndexToApproved;

    // /// @dev Assigns ownership of a specific KoiFish to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) override internal {
        require(ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");
        // Since the number of fish is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;
        ownershipTokenCount[_from]--;

        _beforeTokenTransfer(_from, _to, _tokenId);

        // actually transfer ownership
        bitKoiIndexToOwner[_tokenId] = _to;

        // Clear approvals from the previous owner
        _approve(address(0), _tokenId);

        emit Transfer(_from, _to, _tokenId);

    }

    /// @notice Returns the address currently assigned ownership of a given BitKoi.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        override
        public
        view
        returns (address owner)
    {
        owner = bitKoiIndexToOwner[_tokenId];
        require(owner != address(0));
    }

     function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return ownershipTokenCount[owner];
    }

    /// @notice Returns a list of all KoiFish IDs assigned to an address.
    /// @param _owner The owner whose KoiFish we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive (it walks the entire KoiFish array looking for fish belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalBitKoi = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all fish have IDs starting at 1 and increasing
            // sequentially up to the totalKoi count.
            uint256 bitKoiId;

            for (bitKoiId = 1; bitKoiId <= totalBitKoi; bitKoiId++) {
                if (bitKoiIndexToOwner[bitKoiId] == _owner) {
                    result[resultIndex] = bitKoiId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function _mintNewKoi(address _to, uint256 _tokenId) internal {
        _mint(_to, _tokenId);

        // Since the number of fish is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;

        // transfer ownership
        bitKoiIndexToOwner[_tokenId] = _to;
    }

    // Any C-level can fix how many seconds per blocks are currently observed.
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}

abstract contract BitKoiOwnership is BitKoiBase {
    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(
        address _claimant,
        uint256 _tokenId
    )
        internal
        view
        returns (bool) {

        return (ownerOf(_tokenId) == _claimant);
    }

    /// @dev Checks if a given address currently has transferApproval for a particular KoiFish.
    /// @param _claimant the address we are confirming fish is approved for.
    /// @param _tokenId fish id, only valid when > 0
    function _approvedFor(
        address _claimant,
        uint256 _tokenId
    )
        internal
        view
        returns (bool) {

        return bitKoiIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting KoiFish on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(
        uint256 _tokenId,
        address _approved
    )
        internal {

        bitKoiIndexToApproved[_tokenId] = _approved;
    }

    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any fish (except very briefly
        // after a gen0 fish is created and before it goes on auction).
        require(_to != address(this));
        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Auction contracts should only take ownership of fish
        // through the allow + transferFrom flow.

        // You can only send your own fish
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

}

abstract contract BitKoiBreeding is BitKoiOwnership {
    event Hatch(address owner, uint256 fishId, uint256 genes);

    uint256 public breedFee = 0 wei;

    uint256 public hatchFee = 0 wei;

    /// @dev The address of the sibling contract that is used to implement the genetic combination algorithm.
    BitKoiTraitInterface public bitKoiTraits;

    /// @dev Update the address of the genetic contract, can only be called by the CEO.
    /// @param _address An address of a GeneScience contract instance to be used from this point forward.
    function setBitKoiTraitAddress(address _address) external onlyCEO {
        BitKoiTraitInterface candidateContract = BitKoiTraitInterface(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isBitKoiTraits());

        // Set the new contract address
        bitKoiTraits = candidateContract;
    }

    /// @dev Checks to see if a given fish is ready to hatch after the gestation period has passed.
    function _isReadyToHatch(uint256 _fishId) private view returns (bool) {
        BitKoi storage fishToHatch = bitKoi[_fishId];
        return fishToHatch.cooldownEndBlock <= uint64(block.number);
    }

    /// @dev Checks that a given fish is able to breed. Requires that the
    ///  current cooldown is finished

    function _isReadyToBreed(BitKoi storage _fish) internal view returns (bool) {
        // In addition to checking the cooldownEndBlock, we also need to check to see if
        // the fish has a pending birth; there can be some period of time between the end
        // of the pregnacy timer and the spawn event.
        return _fish.cooldownEndBlock <= uint64(block.number);
    }

    /// @dev Set the cooldownEndTime for the given fish based on its current cooldownIndex.
    ///  Also increments the cooldownIndex (unless it has hit the cap).
    /// @param _koiFish A reference to the KoiFish in storage which needs its timer started.
    function _triggerCooldown(BitKoi storage _koiFish) internal {
        // Compute an estimation of the cooldown time in blocks (based on current cooldownIndex).
        _koiFish.cooldownEndBlock = uint64((cooldowns[_koiFish.cooldownIndex]/secondsPerBlock) + block.number);

        // Increment the breeding count, clamping it at 13, which is the length of the
        // cooldowns array. We could check the array size dynamically, but hard-coding
        // this as a constant saves gas. Yay, Solidity!
        if (_koiFish.cooldownIndex < 13) {
            _koiFish.cooldownIndex += 1;
        }
    }

    // @dev Updates the minimum payment required for calling breedWith(). Can only
    ///  be called by the COO address. (This fee is used to offset the gas cost incurred
    ///  by the autobirth daemon).
    function setBreedFee(uint256 val) external onlyCEO {
        breedFee = val;
    }

    // @dev Updates the minimum payment required for calling hatchFish(). Can only
    ///  be called by the COO address. (This fee is used to offset the gas cost incurred
    ///  by the autobirth daemon).
    function setHatchFee(uint256 val) external onlyCEO {
        hatchFee = val;
    }

    /// @notice Checks that a given fish is able to breed (i.e. it is not
    ///  in the middle of a siring cooldown).
    /// @param _koiId reference the id of the fish, any user can inquire about it
    function isReadyToBreed(uint256 _koiId)
        public
        view
        returns (bool)
    {
        require(_koiId > 0);
        BitKoi storage fish = bitKoi[_koiId];
        return _isReadyToBreed(fish);
    }

    /// @notice Checks that a given fish is able to breed (i.e. it is not
    ///  in the middle of a siring cooldown).
    /// @param _koiId reference the id of the fish, any user can inquire about it
    function isReadyToHatch(uint256 _koiId)
        public
        view
        returns (bool)
    {
        require(_koiId > 0);
        return _isReadyToHatch(_koiId);
    }

    /// @dev Internal check to see if a the parents are a valid mating pair. DOES NOT
    ///  check ownership permissions (that is up to the caller).
    /// @param _parent1 A reference to the Fish struct of the potential first parent
    /// @param _parent1Id The first parent's ID.
    /// @param _parent2 A reference to the Fish struct of the potential second parent
    /// @param _parent2Id The second parent's ID.
    function _isValidMatingPair(
        BitKoi storage _parent1,
        uint256 _parent1Id,
        BitKoi storage _parent2,
        uint256 _parent2Id
    )
        private
        view
        returns(bool)
    {
        // A Fish can't breed with itself!
        if (_parent1Id == _parent2Id) {
            return false;
        }

        //the fish have to have genes
        if (_parent1.genes == 0 || _parent2.genes == 0) {
            return false;
        }

        // Fish can't breed with their parents.
        if (_parent1.parent1Id == _parent1Id || _parent1.parent2Id == _parent2Id) {
            return false;
        }
        if (_parent2.parent1Id == _parent1Id || _parent2.parent2Id == _parent2Id) {
            return false;
        }

        // OK the tx if either fish is gen zero (no parent found).
        if (_parent2.parent1Id == 0 || _parent1.parent1Id == 0) {
            return true;
        }

        // Fish can't breed with full or half siblings.
        if (_parent2.parent1Id == _parent1.parent1Id || _parent2.parent1Id == _parent1.parent2Id) {
            return false;
        }
        if (_parent2.parent1Id == _parent1.parent1Id || _parent2.parent2Id == _parent1.parent2Id) {
            return false;
        }

        // gtg
        return true;
    }

    /// @notice Checks to see if two BitKoi can breed together, including checks for
    ///     ownership and siring approvals. Doesn't check that both BitKoi are ready for
    ///     breeding (i.e. breedWith could still fail until the cooldowns are finished).
    /// @param _parent1Id The ID of the proposed first parent.
    /// @param _parent2Id The ID of the proposed second parent.
    function canBreedWith(uint256 _parent1Id, uint256 _parent2Id)
        external
        view
        returns(bool)
    {
        require(_parent1Id > 0);
        require(_parent2Id > 0);
        BitKoi storage parent1 = bitKoi[_parent1Id];
        BitKoi storage parent2 = bitKoi[_parent2Id];
        return _isValidMatingPair(parent1, _parent1Id, parent2, _parent2Id);
    }

    /// @dev Internal utility function to initiate breeding, assumes that all breeding
    ///     requirements have been checked.
    function _breedWith(uint256 _parent1Id, uint256 _parent2Id) internal returns(uint256) {
        // Grab a reference to the Koi from storage.
        BitKoi storage parent1 = bitKoi[_parent1Id];
        BitKoi storage parent2 = bitKoi[_parent2Id];

        // Determine the higher generation number of the two parents
        uint16 parentGen = parent1.generation;
        if (parent2.generation > parent1.generation) {
            parentGen = parent2.generation;
        }

        uint256 bitKoiCoProceeds = msg.value;

        //transfer the breed fee less the pond cut to the CFO contract
        payable(address(cfoAddress)).transfer(bitKoiCoProceeds);

        // Make the new fish!
        address owner = bitKoiIndexToOwner[_parent1Id];
        uint256 newFishId = _createBitKoi(_parent1Id, _parent2Id, parentGen + 1, 0, owner);

        // Trigger the cooldown for both parents.
        _triggerCooldown(parent1);
        _triggerCooldown(parent2);

        // Emit the breeding event.
        emit BreedingSuccessful(bitKoiIndexToOwner[_parent1Id], newFishId, _parent1Id, _parent2Id, parent1.cooldownEndBlock);

        return newFishId;
    }

    function breedWith(uint256 _parent1Id, uint256 _parent2Id)
        external
        payable
        whenNotPaused
    {
        // Checks for payment.
        require(msg.value >= breedFee);

        ///check to see if the caller owns both fish
        require(_owns(msg.sender, _parent1Id));
        require(_owns(msg.sender, _parent2Id));

        // Grab a reference to the first parent
        BitKoi storage parent1 = bitKoi[_parent1Id];

        // Make sure enough time has passed since the last time this fish was bred
        require(_isReadyToBreed(parent1));

        // Grab a reference to the second parent
        BitKoi storage parent2 = bitKoi[_parent2Id];

        // Make sure enough time has passed since the last time this fish was bred
        require(_isReadyToBreed(parent2));

        // Test that these fish are a valid mating pair.
        require(_isValidMatingPair(
            parent2,
            _parent2Id,
            parent1,
            _parent1Id
        ));

        // All checks passed, make a new fish!!
        _breedWith(_parent1Id, _parent2Id);
    }

    /// @dev An internal method that creates a new fish and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Birth event
    ///  and a Transfer event.
    /// @param _parent1Id The fish ID of the first parent (zero for gen0)
    /// @param _parent2Id The fish ID of the second parent (zero for gen0)
    /// @param _generation The generation number of this fish, must be computed by caller.
    /// @param _genes The fish's genetic code.
    /// @param _owner The inital owner of this fish, must be non-zero (except for fish ID 0)
    function _createBitKoi(
        uint256 _parent1Id,
        uint256 _parent2Id,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        // These requires are not strictly necessary, our calling code should make
        // sure that these conditions are never broken. However! _createKoiFish() is already
        // an expensive call (for storage), and it doesn't hurt to be especially careful
        // to ensure our data structures are always valid.
        require(_parent1Id == uint256(uint32(_parent1Id)));
        require(_parent2Id == uint256(uint32(_parent2Id)));
        require(_generation == uint256(uint16(_generation)));

        // New fish starts with the same cooldown as parent gen/2
        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        BitKoi memory _bitKoi = BitKoi({
            genes: _genes,
            spawnTime: uint64(block.timestamp),
            cooldownEndBlock: 0,
            parent1Id: uint32(_parent1Id),
            parent2Id: uint32(_parent2Id),
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
        });

        uint256 newBitKoiId = bitKoi.length;
        bitKoi.push(_bitKoi);

        // It's probably never going to happen, 4 billion fish is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newBitKoiId == uint256(uint32(newBitKoiId)));

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _mintNewKoi(_owner, newBitKoiId);

        // emit the spawn event
        emit Spawn(
            _owner,
            newBitKoiId,
            uint256(_bitKoi.parent1Id),
            uint256(_bitKoi.parent2Id),
            _bitKoi.genes,
            uint16(_generation),
            uint64(block.timestamp)
        );

        BitKoi storage brandNewKoi = bitKoi[newBitKoiId];

        _triggerCooldown(brandNewKoi);

        return newBitKoiId;
    }


    function hatchFish(uint256 _fishId, uint256 _geneSet1, uint256 _geneSet2)
        external
        payable
        whenNotPaused
    {
        // Checks for payment.
        require(msg.value >= hatchFee);

        //ensure the caller owns the egg they want to hatch
        require(_owns(msg.sender, _fishId));

        _hatchFish(_fishId, _geneSet1, _geneSet2);
    }

    function _hatchFish(uint256 _fishId, uint256 _geneSet1, uint256 _geneSet2) internal {
        BitKoi storage fishToHatch = bitKoi[_fishId];

        BitKoi storage parent1 = bitKoi[fishToHatch.parent1Id];
        BitKoi storage parent2 = bitKoi[fishToHatch.parent2Id];

        uint256 genes1 = 0;
        uint256 genes2 = 0;

        if (fishToHatch.parent1Id > 0){
            genes1 = parent1.genes;
        } else {
            genes1 = _geneSet1;
        }

        if (fishToHatch.parent2Id > 0){
            genes2 = parent2.genes;
        } else {
            genes2 = _geneSet2;
        }

        // Check that the parent is a valid fish
        require(parent1.spawnTime != 0 && parent2.spawnTime != 0);

        // Check to see if the fish is ready to hatch
        require(_isReadyToHatch(_fishId));

        // Make sure this fish doesn't already have genes
        require(fishToHatch.genes == 0);

        // next, let's get new genes for the fish we're about to hatch
        uint256 newFishGenes = bitKoiTraits.smooshFish(genes1, genes2, fishToHatch.cooldownEndBlock - 1);

        fishToHatch.genes = uint256(newFishGenes);

        //transfer the hatch fee less the pond cut to the CFO contract
        payable(address(cfoAddress)).transfer(msg.value);

        emit Hatch(msg.sender, _fishId, newFishGenes);
    }

}

abstract contract BitKoiAuction is BitKoiBreeding {
        // Tracks last 5 sale price of gen0 fish sales
        uint256 public gen0SaleCount;
        uint256[5] public lastGen0SalePrices;

        struct Auction {
            // Current owner of NFT
            address seller;
            // Price (in wei) at beginning of auction
            uint128 startingPrice;
            // Price (in wei) at end of auction
            uint128 endingPrice;
            // Duration (in seconds) of auction
            uint64 duration;
            // Time when auction started
            // NOTE: 0 if this auction has been concluded
            uint64 startedAt;
        }

        // Cut contract owner takes on each auction, measured in basis points (1/100 of a percent).
        // Values 0-10,000 map to 0%-100%
        uint256 public ownerCut = 250;

        /// @param _ownerCut - update the percent cut the contract owner takes on each breed or hatch event, must be
        ///  between 0-10,000.
        function setOwnerCut(uint256 _ownerCut) external onlyCEO {
            require(_ownerCut <= 10000);
            ownerCut = _ownerCut;
        }

        // Map from token ID to their corresponding auction.
        mapping (uint256 => Auction) tokenIdToAuction;

        event AuctionCreated(address sellerId, uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt);
        event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
        event AuctionCancelled(uint256 tokenId);

        /// @dev adds an auction to the list of open auctions. Also fires the AuctionCreated event.
        /// @param _tokenId The ID of the token to be put on auction.
        /// @param _auction Auction to add.
        function _addAuction(address _sellerId, uint256 _tokenId, Auction memory _auction, uint256 _auctionStarted) internal {
            // Require that all auctions have a duration of
            // at least one minute. (Keeps our math from getting hairy!)
            require(_auction.duration >= 0 minutes);

            tokenIdToAuction[_tokenId] = _auction;

            emit AuctionCreated(
                address(_sellerId),
                uint256(_tokenId),
                uint256(_auction.startingPrice),
                uint256(_auction.endingPrice),
                uint256(_auction.duration),
                uint256(_auctionStarted)
            );
        }

        /// @dev Cancels an auction unconditionally.
        function _cancelAuction(uint256 _tokenId) internal {
            _removeAuction(_tokenId);
            emit AuctionCancelled(_tokenId);
        }

        /// @dev Computes the price and transfers winnings.
        /// Does NOT transfer ownership of token.
        function _bid(uint256 _tokenId, uint256 _bidAmount)
            internal
            returns (uint256)
        {
            // Get a reference to the auction struct
            Auction storage auction = tokenIdToAuction[_tokenId];

            // Explicitly check that this auction is currently live.
            // (Because of how Ethereum mappings work, we can't just count
            // on the lookup above failing. An invalid _tokenId will just
            // return an auction object that is all zeros.)
            require(_isOnAuction(auction));

            // Check that the bid is greater than or equal to the current price
            uint256 price = _currentPrice(auction);
            require(_bidAmount >= price);

            address seller = address(uint160(auction.seller));


            // The bid is good! Remove the auction before sending the fees
            // to the sender so we can't have a reentrancy attack.
            _removeAuction(_tokenId);

            // Transfer proceeds to seller (if there are any!)
            if (price > 0) {
                // Calculate the auctioneer's cut.
                // (NOTE: _computeCut() is guaranteed to return a
                // value <= price, so this subtraction can't go negative.)
                uint256 contractCut = _computeCut(price);
                uint256 sellerProceeds = price - contractCut;

                // NOTE: Doing a transfer() in the middle of a complex
                // method like this is generally discouraged because of
                // reentrancy attacks and DoS attacks if the seller is
                // a contract with an invalid fallback function. We explicitly
                // guard against reentrancy attacks by removing the auction
                // before calling transfer(), and the only thing the seller
                // can DoS is the sale of their own asset! (And if it's an
                // accident, they can call cancelAuction(). )

                payable(cfoAddress).transfer(contractCut);

                payable(seller).transfer(sellerProceeds);
            }


            // Calculate any excess funds included with the bid. If the excess
            // is anything worth worrying about, transfer it back to bidder.
            // NOTE: We checked above that the bid amount is greater than or
            // equal to the price so this cannot underflow.
            uint256 bidExcess = _bidAmount - price;

            // Return the funds. Similar to the previous transfer, this is
            // not susceptible to a re-entry attack because the auction is
            // removed before any transfers occur.

            payable(msg.sender).transfer(bidExcess);

            // Tell the world!
            emit AuctionSuccessful(_tokenId, price, msg.sender);

            return price;
        }

        /// @dev Removes an auction from the list of open auctions.
        /// @param _tokenId - ID of NFT on auction.
        function _removeAuction(uint256 _tokenId) internal {
            delete tokenIdToAuction[_tokenId];
        }

        /// @dev Returns true if the NFT is on auction.
        /// @param _auction - Auction to check.
        function _isOnAuction(Auction storage _auction) internal view returns (bool) {
            return (_auction.startedAt > 0);
        }

        /// @dev Returns current price of an NFT on auction. Broken into two
        ///  functions (this one, that computes the duration from the auction
        ///  structure, and the other that does the price computation) so we
        ///  can easily test that the price computation works correctly.
        function _currentPrice(Auction storage _auction)
            internal
            view
            returns (uint256)
        {
            uint256 secondsPassed = 0;

            // A bit of insurance against negative values (or wraparound).
            // Probably not necessary (since Ethereum guarnatees that the
            // now variable doesn't ever go backwards).
            if (block.timestamp > _auction.startedAt) {
                secondsPassed = block.timestamp - _auction.startedAt;
            }

            return _computeCurrentPrice(
                _auction.startingPrice,
                _auction.endingPrice,
                _auction.duration,
                secondsPassed
            );
        }

        /// @dev Computes the current price of an auction. Factored out
        ///  from _currentPrice so we can run extensive unit tests.
        ///  When testing, make this function public and turn on
        ///  `Current price computation` test suite.
        function _computeCurrentPrice(
            uint256 _startingPrice,
            uint256 _endingPrice,
            uint256 _duration,
            uint256 _secondsPassed
        )
            internal
            pure
            returns (uint256)
        {
            // NOTE: We don't use SafeMath (or similar) in this function because
            //  all of our public functions carefully cap the maximum values for
            //  time (at 64-bits) and currency (at 128-bits). _duration is
            //  also known to be non-zero (see the require() statement in
            //  _addAuction())
            if (_secondsPassed >= _duration) {
                // We've reached the end of the dynamic pricing portion
                // of the auction, just return the end price.
                return _endingPrice;
            } else {
                // Starting price can be higher than ending price (and often is!), so
                // this delta can be negative.
                int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

                // This multiplication can't overflow, _secondsPassed will easily fit within
                // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
                // will always fit within 256-bits.
                int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

                // currentPriceChange can be negative, but if so, will have a magnitude
                // less that _startingPrice. Thus, this result will always end up positive.
                int256 currentPrice = int256(_startingPrice) + currentPriceChange;

                return uint256(currentPrice);
            }
        }

        /// @dev Computes owner's cut of a sale.
        /// @param _price - Sale price of NFT.
        function _computeCut(uint256 _price) internal view returns (uint256) {
            // NOTE: We don't use SafeMath (or similar) in this function because
            //  all of our entry functions carefully cap the maximum values for
            //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
            //  statement in the ClockAuction constructor). The result of this
            //  function is always guaranteed to be <= _price.
            return _price * ownerCut / 10000;
        }

        /// @dev Creates and begins a new auction.
        /// @param _tokenId - ID of token to auction, sender must be owner.
        /// @param _startingPrice - Price of item (in wei) at beginning of auction.
        /// @param _endingPrice - Price of item (in wei) at end of auction.
        /// @param _duration - Length of auction (in seconds).
        /// @param _seller - Seller, if not the message sender
        function createAuction(
            uint256 _tokenId,
            uint256 _startingPrice,
            uint256 _endingPrice,
            uint256 _duration,
            address _seller
        )
            external
            whenNotPaused
        {
            // Sanity check that no inputs overflow how many bits we've allocated
            // to store them in the auction struct.
            require(_startingPrice == uint256(uint128(_startingPrice)));
            require(_endingPrice == uint256(uint128(_endingPrice)));
            require(_duration == uint256(uint64(_duration)));
            require(_startingPrice >= _endingPrice);
            require(msg.sender == bitKoiIndexToOwner[_tokenId]);

            Auction memory auction = Auction(
                address(_seller),
                uint128(_startingPrice),
                uint128(_endingPrice),
                uint64(_duration),
                uint64(block.timestamp)
            );
            _addAuction(_seller, _tokenId, auction, block.timestamp);
        }

        function bid(uint256 _tokenId)
            external
            payable
            whenNotPaused
        {
            // _bid will throw if the bid or funds transfer fails
            // _bid verifies token ID size
            address seller = tokenIdToAuction[_tokenId].seller;
            uint256 price = _bid(_tokenId, msg.value);

            //If not a gen0 auction, exit
            if (seller == address(this)) {
                // Track gen0 sale prices
                lastGen0SalePrices[gen0SaleCount % 5] = price;
                gen0SaleCount++;
            }

            _transfer(seller, msg.sender, _tokenId);
        }

        function averageGen0SalePrice() external view returns (uint256) {
            uint256 sum = 0;
            for (uint256 i = 0; i < 5; i++) {
                sum += lastGen0SalePrices[i];
            }
            return sum / 5;
        }

        /// @dev Cancels an auction that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on auction
    function cancelAuction(uint256 _tokenId)
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId);
    }

    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }
}

/// @title all functions related to creating fish (and their eggs)
abstract contract BitKoiMinting is BitKoiAuction {

    // Limits the number of fish the contract owner can ever create.
    uint256 public constant PROMO_CREATION_LIMIT = 5000;
    uint256 public constant GEN0_EGG_CREATION_LIMIT = 45000;

    // Counts the number of fish the contract owner has created.
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    // Direct sale is not live to start
    bool public directSalePaused = true;

    //determine the price for minting a new BitKoi gen0 egg
    uint256 public gen0PromoPrice = 5000000000000000000 wei;

    uint256 public currentGen0Cap = 100;

    // allow direct sales of gen0 eggs
    function pauseDirectSale() external onlyCLevel {
        directSalePaused = true;
    }

    // stop direct sales of gen0 eggs
    function unpauseDirectSale() external onlyCLevel {
        directSalePaused = false;
    }

    // set current cap for sale - this can be raised later so new sales can be started w/ limits
    function setCurrentGen0Cap(uint256 val) external onlyCEO {
        currentGen0Cap = val;
    }

    // @dev Updates the minimum payment required for calling mintGen0Egg(). Can only
    ///  be called by the CEO address.
    function setGen0PromoPrice(uint256 val) external onlyCEO {
        gen0PromoPrice = val;
    }

    function mintGen0Egg(address _owner) external payable {
        require (!directSalePaused);
        require (msg.value >= gen0PromoPrice);
        require (gen0CreatedCount < currentGen0Cap);
        require (gen0CreatedCount < GEN0_EGG_CREATION_LIMIT);

        //transfer the sale price less the pond cut to the CFO contract
        payable(address(cfoAddress)).transfer(msg.value);

        address bitKoiOwner = _owner;

        gen0CreatedCount++;

        _createBitKoi(0, 0, 0, 0, bitKoiOwner);

    }

    /// @dev we can create promo fish, up to a limit. Only callable by COO
    /// @param _genes the encoded genes of the fish to be created, any value is accepted
    /// @param _owner the future owner of the created fish. Default to contract COO
    function createPromoFish(uint256 _genes, address _owner) external onlyCOO {
        address bitKoiOwner = _owner;

        if (bitKoiOwner == address(0)) {
             bitKoiOwner = cooAddress;
        }

        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createBitKoi(0, 0, 0, _genes, bitKoiOwner);
    }

}

contract BitKoiCore is BitKoiMinting {
    constructor(address _proxyRegistryAddress) ERC721Tradable("BitKoi", "BITKOI", _proxyRegistryAddress) {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cfoAddress = msg.sender;

        //start with an initial fish
        _createBitKoi(0, 0, 0, type(uint256).max, address(this));

    }

    string baseURI = "https://www.bitkoi.co/api/nft/";
    string contractMainURI = "https://www.bitkoi.co";

    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function setBaseTokenURI(string memory _newBaseURI) public onlyCEO {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _newContractURI) public onlyCEO {
        contractMainURI = _newContractURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return contractMainURI;
    }

    function unpause() override public onlyCEO whenPaused {
        require(address(bitKoiTraits) != address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    /// @notice Returns all the relevant information about a specific fish.
    /// @param _id The ID of the fish we're looking up
    function getBitKoi(uint256 _id)
        external
        view
        returns (
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 spawnTime,
        uint256 parent1Id,
        uint256 parent2Id,
        uint256 generation,
        uint256 cooldownEndBlock,
        uint256 genes
    ) {
        BitKoi storage fish = bitKoi[_id];
        isReady = (fish.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(fish.cooldownIndex);
        nextActionAt = uint256(fish.cooldownEndBlock);
        spawnTime = uint256(fish.spawnTime);
        parent1Id = uint256(fish.parent1Id);
        parent2Id = uint256(fish.parent2Id);
        generation = uint256(fish.generation);
        cooldownEndBlock = uint256(fish.cooldownEndBlock);
        genes = fish.genes;
    }
}