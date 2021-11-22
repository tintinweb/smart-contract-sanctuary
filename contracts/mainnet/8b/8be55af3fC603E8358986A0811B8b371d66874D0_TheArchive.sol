// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import "./Archival.sol";

contract TheArchive is ERC721, AccessControl {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public _tokens;

    uint256 public price = 0.25 * 1e18;
    uint256 public rollMintLimit = 2;
    uint256 public mintLimitSize = 36;
    string public baseUri = 'https://ipfs.infura.io/ipfs/';
    string public imageUri = 'https://api.thedigitalarchive.art/image/';
    bool public onchain=true;
    string public description;
    address withdrawalAddress;

    struct Token {
        bool        exists;
        string      cid;
        bool        snippet;
        uint256     rotation;
        string      film;
        string      color;
    }
    mapping (uint256 => Token) public Tokens;

    bool public saleStart;
    bool public requireIncludeList;
    mapping (address => bool) public    IncludeList;
    mapping (uint256 => mapping (address => uint256)) public    RollWallet;

    constructor(address _withdraw) ERC721("TheArchive", "ARCHIVE") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        withdrawalAddress = _withdraw;
    }

    modifier onlyTeam() {
        require(isTeam(msg.sender));
        _;
    }

    function isTeam(address account) public virtual view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function mint(uint256 tokenId) public payable {
        require(saleStart && !_exists(tokenId) && Tokens[tokenId].exists && msg.value == price);
        if(requireIncludeList) {
            require(IncludeList[msg.sender]);
        }
        uint256 roll = tokenId.div(mintLimitSize);
        require(RollWallet[roll][msg.sender]+1 <= rollMintLimit);

        _safeMint(msg.sender, tokenId);
        RollWallet[roll][msg.sender]++;
    }

    function mintTeam(uint256 tokenId, address receiver) public onlyTeam {
        require(!_exists(tokenId) && Tokens[tokenId].exists);
        _safeMint(receiver, tokenId);
    }

    function createToken(string memory cid, uint256 rotation, string memory film, bool exists, string memory color) public onlyTeam {
        _tokens.increment();
        Tokens[_tokens.current()] = Token(exists, cid, true, rotation, film, color);
    }

    function editToken(uint256 tokenId, string memory cid, uint256 rotation, string memory film, bool exists, string memory color) public onlyTeam {
        Tokens[tokenId].exists = exists;
        Tokens[tokenId].cid = cid;
        Tokens[tokenId].rotation = rotation;
        Tokens[tokenId].film = film;
        Tokens[tokenId].color = color;
    }

    function ownerTokenSettings(uint256 tokenId, bool snippet, uint256 rotation) public {
        require(ownerOf(tokenId) == msg.sender && rotation < 4);
        Tokens[tokenId].rotation = rotation;
        Tokens[tokenId].snippet = snippet;
    }

    function tokenExists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    function getTokensForSale() public view returns(uint256[] memory tokens) {
        uint256 saleCount = 0;
        for(uint256 i=1; i<= _tokens.current(); i++) {
            if(Tokens[i].exists && !tokenExists(i)) {
                saleCount++;
            }
        }
        tokens = new uint256[](saleCount);
        uint256 index;
        for(uint256 i=1; i<= _tokens.current(); i++) {
            if(Tokens[i].exists && !tokenExists(i)) {
                tokens[index] = i;
                index++;
            }
        }
    }

    function contractSettings(bool _saleStart, bool _requireIncludeList, uint256 _price, string memory _baseUri, string memory _imageUri, bool _onchain, string memory _description, uint256 _rollMintLimit, uint256 _mintLimitSize) public onlyTeam {
        saleStart = _saleStart;
        requireIncludeList = _requireIncludeList;
        price = _price;
        baseUri = _baseUri;
        imageUri = _imageUri;
        onchain = _onchain;
        description = _description;
        rollMintLimit = _rollMintLimit;
        mintLimitSize = _mintLimitSize;
    }

    function addIncludeListBulk(address[] memory include, uint256 total) public onlyTeam {
        for(uint256 i=0; i<total; i++) {
            IncludeList[include[i]] = true;
        }
    }

    function removeIncludeListBulk(address[] memory include, uint256 total) public onlyTeam {
        for(uint256 i=0; i<total; i++) {
            IncludeList[include[i]] = false;
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory output) {
        if(!onchain) {
            output = string(abi.encodePacked(baseUri, tokenId));
        } else {
            string memory attributes = Archival.makeAttributes(Tokens[tokenId].film);
            string memory svg;
            if(!Tokens[tokenId].snippet) {
                svg = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(Archival.makeSVG(baseUri, Tokens[tokenId].cid, Tokens[tokenId].snippet, Tokens[tokenId].rotation)))));
            } else {
                svg = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(Archival.makeSVGSnippet(baseUri, Tokens[tokenId].cid, Tokens[tokenId].snippet, Tokens[tokenId].rotation, tokenId, Tokens[tokenId].film, Tokens[tokenId].color)))));
            }
            string memory image = string(abi.encodePacked(imageUri, Archival.toString(tokenId)));
            string memory json = Base64.encode(bytes(Archival.makeJson(Archival.tokenName(tokenId), description, image, svg, attributes)));
            output = string(abi.encodePacked('data:application/json;base64,', json));
        }
    }

    /**
    *   External function for getting all tokens by a specific owner.
    */
    function getByOwner(address _owner) view public returns(uint256[] memory result) {
        result = new uint256[](balanceOf(_owner));
        uint256 resultIndex = 0;
        for (uint256 t = 1; t <= _tokens.current(); t++) {
            if (_exists(t) && ownerOf(t) == _owner) {
                result[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IAccessControl).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function withdraw() public payable onlyTeam {
        require(payable(withdrawalAddress).send(address(this).balance));
    }

}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

library Archival {
    using SafeMath for uint256;

    function tokenName(uint256 tokenId) public pure returns (string memory name) {
        uint256 number = tokenId.mod(36);
        if(number == 0) {
            number = 36;
        }
        name = string(abi.encodePacked(toString(36), rollCode(tokenId), toString(number)));
    }

    function rollCode(uint256 tokenId) public pure returns (string memory code) {
        uint256 roll = tokenId.sub(1).div(36);
        uint256 rollPrefix = roll.div(26);
        uint256 rollSuffix = roll.mod(26);
        code = string(abi.encodePacked(letterMap(rollPrefix), letterMap(rollSuffix)));
    }

    function letterMap(uint256 num) public pure returns (string memory letter) {
        string[26] memory letters;
        letters[0] = 'A';
        letters[1] = 'B';
        letters[2] = 'C';
        letters[3] = 'D';
        letters[4] = 'E';
        letters[5] = 'F';
        letters[6] = 'G';
        letters[7] = 'H';
        letters[8] = 'I';
        letters[9] = 'J';
        letters[10] = 'K';
        letters[11] = 'L';
        letters[12] = 'M';
        letters[13] = 'N';
        letters[14] = 'O';
        letters[15] = 'P';
        letters[16] = 'Q';
        letters[17] = 'R';
        letters[18] = 'S';
        letters[19] = 'T';
        letters[20] = 'U';
        letters[21] = 'V';
        letters[22] = 'W';
        letters[23] = 'X';
        letters[24] = 'Y';
        letters[25] = 'Z';
        letter = letters[num];
    }

    function getDefaultSizes() public pure returns (uint256 default_width, uint256 default_height) {
        default_width = 10200;
        default_height = 6900;
    }

    function getWidthAndHeight(bool snippet, uint256 rotation) public pure returns (uint256 s_width, uint256 s_height) {
        (uint256 default_width, uint256 default_height) = getDefaultSizes();
        s_width = default_width;
        s_height = default_height;
        if(snippet) {
            s_height = (default_width / 38) * 35;
            if(rotation == 1 || rotation == 3) {
                s_width = s_height;
                s_height = default_width;
            }
        } else if(rotation == 1 || rotation == 3) {
            s_width = s_height;
            s_height = default_width;
        }
    }

    function makeSVG(string memory baseUri, string memory cid, bool snippet, uint256 rotation) public pure returns (string memory svg){
        (uint256 default_width, uint256 default_height) = getDefaultSizes();
        (uint256 s_width, uint256 s_height) = getWidthAndHeight(snippet, rotation);
        string memory transform;
        if(rotation == 1) {
            transform = string(abi.encodePacked('transform="rotate(90, ', toString(s_width / 2), ', ', toString(s_width / 2), ')"'));
        } else if(rotation == 2) {
            transform = string(abi.encodePacked('transform="rotate(180, ', toString(s_width / 2), ', ', toString(s_height / 2), ')"'));
        } else if(rotation == 3) {
            transform = string(abi.encodePacked('transform="rotate(270, ', toString(s_height / 2), ', ', toString(s_height / 2), ')"'));
        }
        svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ';
        svg = string(abi.encodePacked(svg, toString(s_width), ' ', toString(s_height), '"><image href="', baseUri, cid, '" height="', toString(default_height), '" width="', toString(default_width), '" ', transform, ' /></svg>'));
    }

    function makeSVGSnippet(string memory baseUri, string memory cid, bool snippet, uint256 rotation, uint256 tokenId, string memory film, string memory color) public pure returns (string memory svg){
        (uint256 default_width, uint256 default_height) = getDefaultSizes();
        (uint256 s_width, uint256 s_height) = getWidthAndHeight(snippet, rotation);
        uint256 number = tokenId.mod(36);
        if(number == 0) {
            number = 36;
        }
        string[11] memory parts;
        parts[0] = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ', toString(s_width), ' ', toString(s_height), '"><g '));
        if(rotation == 1) {
            parts[1] = string(abi.encodePacked('transform="rotate(90, ', toString(s_width / 2), ', ', toString(s_width / 2), ')"'));
        } else if(rotation == 2) {
            parts[1] = string(abi.encodePacked('transform="rotate(180, ', toString(s_width / 2), ', ', toString(s_height / 2), ')"'));
        } else if(rotation == 3) {
            parts[1] = string(abi.encodePacked('transform="rotate(270, ', toString(s_height / 2), ', ', toString(s_height / 2), ')"'));
        }
        parts[2] = string(abi.encodePacked('><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 3800 3500" height="', toString((default_width / 38) * 35), '" width="', toString(default_width), '"><path fill="#', color, '" d="M-8.2,3510.8V-8.6h3812.7v3519.4H-8.2z M849.9,343.4c-1.6-34.6,3.6-70-2.9-104.1c-18-59.1-90.5-37.1-136.9-41c-38.5-3.6-67.7,28.1-65.8,63.8c2.3,61.6-4.7,124.5,3.1,185.6c18.4,61.8,96.6,37,145,41.6C870.2,485.1,846.4,396.4,849.9,343.4z M849.9,3154.6c-0.1-30,0.3-60.1-0.2-90.1c-0.8-27.8-22.7-54.3-51.4-55.1c-30-0.8-59.9-0.1-89.9-0.3c-28.8-2.6-55.2,14.7-61.7,43.6c-6,59-0.6,119.2-2.4,178.6c-2.8,33.1,19.9,68.3,55.6,67.8c48.3-5.3,126.5,21.1,146.7-39C854.1,3225.8,848.1,3189.6,849.9,3154.6z M2034.9,343.7c-0.1,30.5,0.3,61.1,0,91.6c-0.2,33.7,32,56.6,64.1,54.2c49.2-2.4,135.5,17.1,139.3-54.7c0.1-60.6-0.2-121.2,0.1-181.7c0-31.2-28.6-56.2-59.3-54.9c-35.4,1.9-72.1-4.4-106.7,3.4c-28.6,9.2-40.6,38-37.5,66.4C2034.9,293.2,2034.9,318.5,2034.9,343.7z M2960.8,342.1c0.2,32.9-0.6,65.8,0.5,98.6c3,28.9,30.8,50,59.3,48.6c34.9-1.4,70.9,3.9,105.3-3.1c24.6-7.2,40.7-33.1,38.6-58.5c0-55.8,0-111.5,0-167.3c2.2-26.1-13-50.3-38.1-58.9c-34.2-7.4-70.3-1.5-105.2-3.3C2940.4,198.8,2964.1,288.2,2960.8,342.1L2960.8,342.1z M1312.4,343.6c-0.7-33.8,1.5-67.8-1.1-101.4c-16.7-62.7-92.7-39.8-140.8-43.9c-32.3-2.4-62.7,23.1-61.8,56.5c0.1,60.1,0.2,120.1,0,180.2c0,24.1,17.7,46.7,41.1,52.1c32.3,5.4,65.6,1.1,98.3,2.4C1334.3,490.2,1308.7,401.2,1312.4,343.6z M2702.2,343.5L2702.2,343.5c-3.2-50.4,18.8-136.9-52.7-144.8c-28.5-1.1-57.1-0.2-85.6-0.5c-37.3-3.7-68.1,24.8-66.7,59.4c0.1,58.6,0.1,117.2,0,175.9c0.5,13.5,5.7,26.4,14.6,36.6c11.8,14.7,30.6,19.5,48.7,19.4c28.5-0.4,57.1,0.4,85.6-0.2C2722.1,484.2,2698.7,395.7,2702.2,343.5z M386.3,345.2c-0.1-31.4,0.2-62.9-0.2-94.4c-1.5-31.8-30.4-54.4-61.4-52.6c-38,3.8-101.5-12.4-127.5,18.6c-11.6,12.2-15.8,27.9-14.4,44.8c0,58.2,0,116.3,0,174.4c0.4,20.6,13.2,38.5,31.4,47.6c35.5,12.1,75,3.1,111.9,5.8c29.8,1.4,59.1-21.8,59.8-52.7C386.6,406.2,386.2,375.7,386.3,345.2L386.3,345.2z M1776.1,344.8c-2.9-58,20.3-149.7-67.1-146.5c-34.8,3.1-91.9-9.8-117.9,14c-13.8,12.1-20,27.5-20.1,45.6c0,57.2-0.1,114.4-0.1,171.6c-1,36.7,30.4,63,66.3,60c33.4-1.9,68.2,4.3,100.9-3.6C1794.9,464.2,1771.3,391.8,1776.1,344.8L1776.1,344.8z M3423.3,343.4c2.7,81.4-22.6,155.1,91.5,146.1c24.8-1.3,51.1,3.4,75.2-3.6c25.4-8.4,38.8-33.3,38.2-59.3c-0.1-55.3-0.1-110.6,0-165.8c-0.2-80.3-86-60.2-141-62.4C3402.4,197.4,3426.7,288.5,3423.3,343.4L3423.3,343.4z M386.3,3155.1c-0.9-34.7,2-69.8-1.5-104.2c-6-21.2-24.9-40.1-47.7-41.3c-29.9-1-59.9-0.3-89.9-0.5c-32.7-3.6-65.1,19.7-64.4,54.5c-0.2,60.5,0,121.1-0.2,181.6c0.8,29.1,24.3,54,53.9,53.7c37.6-1.6,76.9,4.8,113.7-3.3c26.8-9.4,38.8-37.8,36-64.7C386.3,3205.6,386.3,3180.4,386.3,3155.1z M1108.9,3153.8c0.8,34.2-1.7,68.8,1,102.9c6.4,23.7,27.8,42.6,52.9,42.4c31.9,0.1,63.8,0,95.6,0c29.1,0.2,54.2-26.4,53.9-55.5c-0.2-60.1-0.2-120.1,0-180.2c-0.3-33.2-30.8-58.1-63.5-54.3c-25.7,0-51.4,0-77.1,0c-16.2-0.6-32.9,2.2-44.8,14.2c-11.9,11.4-18.3,25-18.1,41.8C1109.1,3094.7,1108.9,3124.3,1108.9,3153.8z M2034.9,3153.9L2034.9,3153.9c-0.1,30.5,0.4,61,0,91.5c0.3,28.9,25,53.9,54,53.5c37.2-1.7,75.8,4.3,112.3-3c21.9-7.6,37-29.2,37.1-52.5c-0.2-60.1-0.2-120.1,0-180.2c-0.4-28.1-23.4-53.4-52.1-54c-29.5-0.6-59-0.1-88.5-0.3c-31.6-3.5-62.8,20.2-62.7,53.3C2034.8,3092.9,2035,3123.4,2034.9,3153.9z M2497.2,3153.4L2497.2,3153.4c1.9,51.3-17.1,146,57.2,145.9c34.1-1.5,68.7,1.6,102.7-1c29.8-6.8,46.9-34.5,45.1-64.4c-0.2-56.2,0.2-112.5-0.1-168.8c-0.8-12.6-4.3-24.4-12.3-34.4c-12-16.2-30.2-22.8-50.2-21.6c-31.4,0.4-62.8-0.8-94.2,0.6C2477.3,3019.4,2501.4,3105,2497.2,3153.4z M1571,3153.3L1571,3153.3c1.2,34.2-2.6,68.9,2,102.8c17.2,64.5,98.6,37.7,147.9,43c33.5,0,57-31.3,55.2-63.6c-0.2-57.2,0.2-114.4-0.1-171.6c-1.5-32.3-29.7-58.3-62.2-54.8c-32.3,0.4-64.7-1-97,0.8C1551.3,3023.7,1575.4,3104.8,1571,3153.3z M2960.8,3153.8c1.8,35.9-4,73.1,3.1,108.2c23.4,58.7,97,30.7,145.2,37.2c33.5,0.7,59.2-31.7,55.3-64.1c-0.4-8.5,0.4-171.7-0.1-175.9c-1-13.9-8.3-26.6-18.4-36c-11.8-11.6-27.4-14.7-43.4-14.1c-30.4,0.2-60.9-0.5-91.3,0.4c-27.1,1-49.8,25.7-50.1,52.8C2960.4,3092.8,2960.9,3123.3,2960.8,3153.8z M3423.3,3153.6L3423.3,3153.6c1.6,35-3.6,71,2.8,105.5c19,60.1,95.4,35.2,143.1,40c36.8,2.4,62.1-31.7,59.1-66.8c-0.1-55.8,0.2-111.5-0.1-167.3c-0.7-9.6-2.6-18.9-7.6-27.3c-11.6-21.1-32.6-30.3-56.3-28.6c-31.4,0.4-62.8-0.9-94.1,0.7C3403.6,3022.6,3427.5,3104.9,3423.3,3153.6z"/></svg>'));
        parts[3] = '<style type="text/css"> @font-face { font-family: Teletactile; src: url("https://archive-app.netlify.app/Teletactile.ttf"); } .t0{font:300px "Teletactile", sans-serif;} </style>';
        parts[4] = '<text x="1850" y="400" class="t0" fill="orange">LH / ARCH</text>';
        parts[5] = string(abi.encodePacked('<text x="9150" y="400" class="t0" fill="orange">', toString(number), '</text>'));
        parts[6] = string(abi.encodePacked('<text x="9150" y="9250" class="t0" fill="orange">', toString(number), '</text>'));
        parts[7] = string(abi.encodePacked('<text x="1850" y="9250" class="t0" fill="orange">36', rollCode(tokenId), '</text>'));
        parts[8] = string(abi.encodePacked('<text x="3650" y="9250" class="t0" fill="orange">', film, '</text>'));
        parts[9] = string(abi.encodePacked('<image href="', baseUri, cid, '" height="6697" width="9900" x="150" y="1341" />'));
        parts[10] = '<g transform="scale(0.049)"><svg xmlns="http://www.w3.org/2000/svg" x="61500" y="181500" viewBox="0 0 130 70" style="enable-background:new 0 0 130 70;" xml:space="preserve"><style type="text/css">.st0{fill:none;stroke:orange;stroke-width:5;stroke-miterlimit:10;}</style><g><line class="st0" x1="3.5" y1="3.4" x2="3.5" y2="68.3"/><line class="st0" x1="5.9" y1="65.8" x2="19.1" y2="65.8"/><line class="st0" x1="19.1" y1="60.7" x2="39.2" y2="60.7"/><line class="st0" x1="5.9" y1="5.9" x2="19" y2="5.9"/><line class="st0" x1="19" y1="10.9" x2="39.1" y2="10.9"/><line class="st0" x1="39.2" y1="55.8" x2="59.3" y2="55.8"/><line class="st0" x1="39.2" y1="15.9" x2="59.2" y2="15.9"/><line class="st0" x1="59.3" y1="50.8" x2="79.4" y2="50.8"/><line class="st0" x1="59.2" y1="20.8" x2="79.3" y2="20.8"/><line class="st0" x1="79.3" y1="45.8" x2="99.4" y2="45.8"/><line class="st0" x1="79.3" y1="25.8" x2="99.4" y2="25.8"/><line class="st0" x1="99.4" y1="30.8" x2="114.4" y2="30.8"/><line class="st0" x1="99.4" y1="40.8" x2="114.4" y2="40.8"/><line class="st0" x1="114.4" y1="35.8" x2="129.3" y2="35.8"/></g></svg></g>';
        svg = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10], '</g></svg>'));
    }

    function makeAttributes(string memory film) public pure returns (string memory attributes) {
        attributes = string(abi.encodePacked('{"trait_type":"Film Type","value":"', film, '"}'));
    }

    function makeJson(string memory name, string memory description, string memory image, string memory svg, string memory attributes) public pure returns (string memory) {
        return string(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "', image, '", "svg": "', svg, '", "attributes": [', attributes, ']}'));
    }

    function toString(uint256 value) public pure returns (string memory) {
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