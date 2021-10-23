//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
//import './zeppeline/token/ERC20/ERC20Mintable.sol';

import './MSNFT.sol';
import './TokenSale721.sol';

/**
 *  Master Factory
 * @title MasterFactory721
 * @dev This contract is a public interfaceble end-point for users
 * Each time user want to create NFT he/she should cast createMasterItem
 * Each time user want to set up a tokensale he/she should cast createItemSale (with obtained master-id) from creation of Master-Item
 * It will create new tokensale contract and plug it to MSNFT (Master Token contract)
 * This contract doesn't deploy MSNFT itself, only TokenSale
 * 
 * If there is a need to upgrade tokensale mechanism it is required to upgrade and redeploy this factory, but not required to upgrade and redeploy Master (MSNFT) and vice-versa
 * 
 */
contract MasterFactory721 {

// constant
address public master_template;
address payable public treasure_fund;
address public currencies_router;



// event
event SaleCreated(address indexed author, uint price, CurrenciesERC20.CurrencyERC20 indexed currency, uint256 indexed master_id, address it_sale);
event SaleCreatedHuman(address author, uint price, CurrenciesERC20.CurrencyERC20 currency,uint256 master_id, address it_sale);
event CreateMasterItem(string link, string _description, uint256 _supplyType, uint256 master_id, address author);
/**
 * @param msnft_ address of Master token contract
 * @param currencies_router_ address of ERC20 currency router
 */
constructor(address msnft_,address payable _treasure_fund, address currencies_router_)  {
   master_template = msnft_;
   treasure_fund = _treasure_fund;
   currencies_router = currencies_router_;
}

/**
 *  @dev Create Item Sale for obtained master copy id
 */
function createItemSale721(address organizer, uint price, MSNFT token,uint sale_limit, CurrenciesERC20.CurrencyERC20 currency, uint _master_id) internal returns(address ticket_sale) {
    ticket_sale = address(new TokenSale721(organizer, token, sale_limit, treasure_fund, price, currency, _master_id, currencies_router));
    return ticket_sale;
}

/**
    @dev Creates Master copy of item, store its meta in blockchain
     supply type -- how much copies can have
     supplyType --> 1= unique, 0 = common, everything else is rare

    @param link magnet/ipfs link to file 
    @param _description of a file, stored in EVENTS, not in state
    @param _supplyType see above
    @return master_id id of a mastercopy
 */
function createMasterItem(string memory link, string memory _description, uint256 _supplyType) public payable returns (uint256 master_id) {
    address master_adr = master_template;
    address _author = msg.sender;
    MSNFT master = MSNFT(master_adr);
    master_id = master.createMasterCopy(link, _author, _description, _supplyType);
    emit CreateMasterItem(link, _description, _supplyType, master_id, _author);
    return master_id;
}

/**
 @dev deploy new tokensale contract, for specific master_id and plug this sale to Master contract
 @param price in wei or least decimal (check this twice for USDT!)
 @param sale_limit how much tokens we want to sell, will fail if there are no consistency with rarity
 @param currency erc20 currency to set price, set equal price for all stables
 @param f_master_id master copy id, which we got from createMasterItem
 @return item_sale_adr address of deployed tokensale contract
 */
function createItemSale(uint price, uint sale_limit, CurrenciesERC20.CurrencyERC20 currency, uint f_master_id) public returns (address item_sale_adr) {
    address master_adr = master_template;
    address organizer = msg.sender;
    MSNFT item = MSNFT(master_adr);
    uint256 master_id = f_master_id;
    require(organizer == item.get_author(master_id), "you are not own this master to start selling items");
    item_sale_adr = createItemSale721(organizer, price, item,sale_limit, currency, master_id);
   
   // Plug itemsale address to mastersale map
    item.PlugCrowdSale(organizer, master_id, item_sale_adr);
    emit SaleCreated(msg.sender, price, currency, master_id, item_sale_adr);
    emit SaleCreatedHuman(msg.sender, price, currency, master_id, item_sale_adr);
    return item_sale_adr;
}

/**
    @dev return address of Master
 */
function getMasterTemplateAddress() public view returns(address) {
    return master_template;
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

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../../../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../../../node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../../node_modules/@openzeppelin/contracts/utils/Counters.sol";


import './MSNFT.sol';
import './CurrenciesERC20.sol';



/**
 *                  TOKENSALE721
 *  @title TokenSale721
 *  @dev TokenSale721 is a reworked OZ Crowdsale contract (see Crowdsale.sol). Originall contract was designed to sell ERC20 tokens
 *  This contract is defining rules of token (ERC721Enumerable) sell.
 *  This version of contract suppose to accept ERC20 tokens as a currency (instead of ethereum), and support work with stable-coins as a currency
 * 
*/
contract TokenSale721 is Context, ReentrancyGuard {

    using SafeERC20 for IERC20Metadata;
  //  using Counters for Counters.Counter;

    // The token being sold
    MSNFT public _token;

    // Interface to currency token
    IERC20Metadata public _currency_token;

    // Currencies lib
    CurrenciesERC20 _currency_contract;

    //master_id
    uint256 public _master_id;

    // rarity type
    MSNFT.RarityType _rarity_type;

    // maximum amount of tickets to sale
   // Counters.Counter public _current_limit;
    uint _sale_limit;
    // how much have been already sold
    uint public _sold_count = 0;

    // Address where funds are collected
    address public _wallet;

    // Address where we collect comission
    address payable public treasure_fund;

    
    // Supported erc20 currencies: .. to be extended
    //enum CurrencyERC20 {USDT, USDC, DAI, MST, WETH} 
    // CurrenciesERC20.CurrencyERC20 -- enum from above
    // Alternativly use CurrenciesERC20.

    // Map from currency to price
    mapping (CurrenciesERC20.CurrencyERC20 => uint256) public _price;
   
    // balances of this sale contract in those currencies
    mapping (CurrenciesERC20.CurrencyERC20 => uint256) internal currency_balances; 

    // service comission fee
    uint public promille_fee = 25;

    // Creation date
    uint public crDate = block.timestamp;

    // How much time before event start (in seconds)
    // TODO -- delete this
    uint public _timeToStart;

    // Funds, that have been locked
    uint256 public lockedFunds;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event CalculatedFees(uint256 initial_value, uint256 fees, uint256 transfered_amount, address feeAddress);


    /**
     *  
     * @dev Constructor of TokenSale721
     * @param i_wallet Address where collected funds will be forwarded to
     * @param i_token Address of the Master Contract
     * @param i_sale_limit How much we want to sell. Should be consistent with rarity type
     * @param _treasure_fund This is our wallet to collect fees
     * @param sprice Price for 1 token. (in wei/lowest decimal format)
     * @param _currency ERC20 token used as a currency. If it stable then price is setting equal for all stables. 
     * @param c_master_id ID of mastercopy being sold
     * @param currency_contract_ Address of currency registry contract (CurrenciesERC20.sol)
     */
    constructor (address i_wallet, MSNFT i_token, uint i_sale_limit, address payable _treasure_fund, uint256 sprice, CurrenciesERC20.CurrencyERC20 _currency, uint256 c_master_id, address currency_contract_)  {
        require(i_wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(i_token) != address(0), "Crowdsale: token is the zero address");

        // Check if stable
        if (_currency == CurrenciesERC20.CurrencyERC20.DAI || _currency == CurrenciesERC20.CurrencyERC20.USDC) {
           // _price[_currency] = sprice;
            _price[CurrenciesERC20.CurrencyERC20.DAI] = sprice;
            _price[CurrenciesERC20.CurrencyERC20.USDC] = sprice;
            _price[CurrenciesERC20.CurrencyERC20.USDT] = sprice / 1 ether * 1e6;    // USDT have 6 decimals, not 18
        } else if(_currency == CurrenciesERC20.CurrencyERC20.USDT) {
            _price[CurrenciesERC20.CurrencyERC20.USDT] = sprice;
            _price[CurrenciesERC20.CurrencyERC20.USDC] = sprice / 1e6 * 1 ether;
            _price[CurrenciesERC20.CurrencyERC20.DAI] = sprice / 1e6 * 1 ether;
        } 
        else {
            _price[_currency] = sprice;
        }

        _wallet = i_wallet;
        treasure_fund = _treasure_fund;
        _token = i_token;
        _currency_contract = CurrenciesERC20(currency_contract_);
        
        // Get rarity type and check sale_limit
        _rarity_type = _token.get_rarity(c_master_id);
        if (_rarity_type == MSNFT.RarityType.Unique) {
            require(i_sale_limit == 1, "Tokensale: Attempt to create new Tokensale for unique NFT with wrong sale_limit");
        }
        if (_rarity_type == MSNFT.RarityType.Common) {  
            _sale_limit = 0;
        }
        if (_rarity_type == MSNFT.RarityType.Rare) {
            _sale_limit = i_sale_limit;
        }


        _master_id = c_master_id;

        _timeToStart = 0;
    }


    // @todo used to buy tokens for ether (deprecated)
    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     
    fallback() external payable {
        buyTokens(_msgSender());
    }
    */

    /**
     * @return the Master NFT contract.
     */
    function token() public view returns (MSNFT) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address) {
        return _wallet;
    }

    function getBalances(CurrenciesERC20.CurrencyERC20 _currency) public view returns (uint) {
        return currency_balances[_currency];
    }

    function master_id() public view returns (uint256) {
        return _master_id;
    }

    function sale_limit() public view returns (uint) {
        return _sale_limit;
    }

    function sold_count() public view returns (uint) {
        return _sold_count;
    }

    function get_price(CurrenciesERC20.CurrencyERC20 currency) public view returns (uint256) {
        return _price[currency];
    }


    function get_currency(CurrenciesERC20.CurrencyERC20 currency) public view returns (IERC20Metadata) {
        return _currency_contract.get_hardcoded_currency(currency);
      //  return _currencies[currency];
    }

    /**
     * @dev check if sale limit is not exceeded 
     * @param amountToBuy how much of tokens want to buy
     */
    function check_sale_limit(uint256 amountToBuy) public view returns (bool) {
        uint sl = sale_limit();
        if (sl == 0){
            return true;
        }
        if (sl == 1) {
            require(amountToBuy == 1,"TokenSale: exceed sale limit!");
            return true;
        } else {
            require(amountToBuy <= sl,"TokenSale: exceed sale limit!");
            return true;
        }
    }

    // BUY TOKENS FOR ETHER/COIN (DEPRECATED)
    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        _preValidatePurchase(beneficiary, weiAmount, tokens);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);
        _sold_count = _sold_count.add(tokens);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

     //   _forwardFunds();
         _lockFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }
    **/

     /**
     *      @dev Main function to buyTokens
     *      @param beneficiary buyer address
     *      @param tokenAmountToBuy how much tokens we want to buy by one tx
     *      @param currency ERC20 token used as a currency
     */
     function buyTokens(address beneficiary,uint256 tokenAmountToBuy, CurrenciesERC20.CurrencyERC20 currency) public nonReentrant payable {
        uint256 tokens = tokenAmountToBuy;

        // How much is needed to pay
        uint256 weiAmount = getWeiAmount(tokens,currency);  // can be zero if wrong currency set-up to pay. in this case tx will fail under pre-validate purchase check

        _preValidatePurchase(beneficiary, weiAmount, tokens, currency);

        // update state
        currency_balances[currency] = currency_balances[currency] + (weiAmount);
       // If it is unlimited sale then _sale_limit should be always 0   
        _sold_count = _sold_count + tokens;
    
        _processPurchase(beneficiary, tokens,currency, weiAmount);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

     //   _forwardFunds();
    //     _lockFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }



    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     * @param tokens number of tokens we want to buy
     * @param currency ERC20 we use as currency
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount, uint256 tokens, CurrenciesERC20.CurrencyERC20 currency) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: Pre-validate: weiAmount is 0, consider you have choose right currency to pay with");
        uint sc = _sold_count;
        uint limit = sc + tokens;

     // Check sale_limit (including rarity check)
        require(check_sale_limit(limit) == true, "tokens amount should not exceed sale_limit");

     // Check allowance of currency balance
        IERC20Metadata currency_token = get_currency(currency);
        uint256 approved_balance = currency_token.allowance(beneficiary, address(this));
        require(approved_balance >= weiAmount, "Tokensale: ERC20:approved spending limit is not enoght");


        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.buyItem(beneficiary,tokenAmount, _master_id);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     * @param currency ERC20 used as currency
     * @param weiAmount wei amount involved in transaction
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount, CurrenciesERC20.CurrencyERC20 currency, uint256 weiAmount) internal {
        IERC20Metadata currency_token = get_currency(currency);
        require(currency_token.transferFrom(beneficiary, address(this), weiAmount), "TokenSale: ERC20: transferFrom buyer to itemsale contract failed ");
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }


    /** 
    *  @dev How much is needed to pay for this token amount to buy
    *  @param tokenAmountToBuy how much we want to buy
    *  @param currency  ERC20 used as currency
    *  @return weiAmount how much we need to pay, could be zero if wrong currency, but will fail at pre-validation
    */
    function getWeiAmount(uint256 tokenAmountToBuy, CurrenciesERC20.CurrencyERC20 currency) public view returns(uint256){
        uint256 price = get_price(currency);    // @todo: WARNING -- it can be 0 if buyer mismatch currency, but such transaction will fail at pre-validate purchase check!
        uint256 weiAmount = price * tokenAmountToBuy; 
        return weiAmount;
    }

    /**
     * @dev Determines how ERC20 is stored/forwarded on purchases. Here we take our fee. This function can be tethered to buy tx or can be separate from buy flow.
     * @param currency ERC20 currency. Seller should specify what exactly currency he/she want to out
     */
    function _forwardFunds(CurrenciesERC20.CurrencyERC20 currency) internal {
        IERC20Metadata currency_token =  get_currency(currency);
        uint256 amount = currency_token.balanceOf(address(this));
        uint256 scale = 1000;
        uint256 fees = calculateFee(amount,scale);
        amount = amount - fees;
        currency_token.transfer(_wallet,amount);
        currency_token.transfer(treasure_fund,fees);
        uint256 r = amount + fees;
        emit CalculatedFees(r,fees,amount,treasure_fund);
    }


    /**
    *   @dev determine how funds are collected by seller
    *   @param currency ERC20 currency
    */
    function withDrawFunds(CurrenciesERC20.CurrencyERC20 currency) public {
        require(msg.sender == _wallet, "only organaizer can do it");
      /*
        if (block.timestamp >= crDate - _timeToStart) {
            _wallet.transfer(lockedFunds);
            lockedFunds = 0;
        } else {
            revert("event is not started yet, funds are locked");
        }
        */
        _forwardFunds(currency);
    }


    /**
    *   Calculate fee (UnSafeMath) -- use it only if it ^0.8.0
    *   @param amount number from whom we take fee
    *   @param scale scale for rounding. 100 is 1/100 (percent). we can encreace scale if we want better division (like we need to take 0.5% instead of 5%, then scale = 1000)
    */
    function calculateFee(uint256 amount, uint256 scale) internal view returns (uint256) {
        uint a = amount / scale;
        uint b = amount % scale;
        uint c = promille_fee / scale;
        uint d = promille_fee % scale;

        // Calculate fee with ROUND DOWN
        // return a * c * scale + a * d + b * c + b * d / scale;

        // calculate fee with ROUND UP
        // return a * c * scale + a * d + b * c + (b * d + scale - 1) / scale;   // I guess we use this

        //calculate fee with CLOSESTS INTEGER
        // return a * c * scale + a * d + b * c + (b * d + scale / 2) / scale;

       return a * c * scale + a * d + b * c + (b * d + scale - 1) / scale;
    }


    /**
    *   Calculate fee (SafeMath)
    *   @param amount number from whom we take fee
    *   @param scale scale for rounding. 100 is 1/100 (percent). we can encreace scale if we want better division (like we need to take 0.5% instead of 5%, then scale = 1000)
    function calculateFeeSafeMath(uint256 amount, uint256 scale) internal view returns (uint256) {
        uint256 a = SafeMath.div(amount, scale);
        uint256 b = SafeMath.mod(amount, scale);
        uint256 c = SafeMath.div(promille_fee, scale);
        uint256 d = SafeMath.mod(promille_fee, scale);

        uint256 m1 = SafeMath.mul(SafeMath.mul(a,c), scale);
        uint256 m2 = SafeMath.mul(a,d);
        uint256 m3 = SafeMath.mul(b,c);
        uint m4 = SafeMath.mul(b,d);

        uint256 d1 = SafeMath.div(scale,2);

        uint256 a1 = SafeMath.add(m4,d1);
        uint256 d2 = SafeMath.div(a1,scale);
        uint256 a2 = SafeMath.add(m1,m2);
        uint256 a3 = SafeMath.add(a2,m3);
        uint256 a4 = SafeMath.add(a3,d2);
        return a4;
    }
    */

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../../../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "../../../node_modules/@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "../../../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../node_modules/@openzeppelin/contracts/access/Ownable.sol";


/**
 *      MoonShard Non-fungible Token
 *  @title MSNFT
 *  @author JackBekket
 *  @dev MSNFT is a ERC721Enumerable token contract
 *  ERC721Enumerable stand for singletone pattern, which mean each created NFT is NOT a separate contract, but record in this single contract
 * When user want's to create NFT -- he creates MasterCopy first (with link to a file), then he can emit items(tokens) or start crowdsale of them
 * Each token is ITEM. Each item is a link to a MasterCopy
 * Each NFT have a rarity type (Unique -- only one exist, Rare -- limited edition, Common -- unlimited edition)
 * createMasterCopy, plugSale, buyItem -- external intefaces to be called from factory contract 
*/
contract MSNFT is ERC721Enumerable, Ownable {
   using SafeMath for uint256;
   using Counters for Counters.Counter;

    // Master -- Mastercopy, abstraction
    // Item -- originate from mastercopy (nft-token)
    
    //events
    /**
     * @dev Events about buying item. events named *Human stands for human readability
     * @param buyer -- user who buy item
     * @param master_id -- unique id of mastercopy
     * @param item_id -- unique id of item
     */
    event ItemBought(address indexed buyer,uint256 indexed master_id, uint256 indexed item_id);
    event ItemBoughtHuman(address buyer,uint256 master_id, uint256 item_id);

    //Mint new token
    event MintNewToken(address to, uint m_master_id, uint item_id);


    // Service event for debug
    event MasterIdReserved(address indexed author, uint256 indexed master_id);
    event MasterIdReservedHuman(address author, uint256 master_id);

    // MasterCopyCreation
    /**
     * @dev event about master-copy creation
     * @param master_id -- unique master id 
     * @param description -- indexed description, which can be key for search. we do not store description info in state, only in event
     * @param link -- link to a file in CDN
     */
    event MaterCopyCreated(address indexed author, uint256 master_id, string indexed description, string indexed link);
    event MasterCopyCreatedHuman(address author, uint256 indexed master_id, string description, string link);

    
    /**
     * @dev Global counters for item_id and master_id. They are replacing atomic lock algo for reserving id
     */
    Counters.Counter _item_id_count;
    Counters.Counter _master_id_count;


    // Motherland
    address private factory_address;    // ITS A VERY IMPORTANT TO KEEP THIS SAFE!!  THIS CONTRACT DO NOT KNOW ABOUT FACTORY CODE SO IT COULD BE REPLACED BY UNKNOWN CONTRACT AND GET ACCESS TO SERVICE FUNCTIONS
    // HOWEVER IT'S THE ONLY WAY TO MAKE THIS CONTRACT UPGRADABLE AND INDEPENDENT FROM FACTORY.



    // Ticket lifecycle @TODO: Maybe useful for migration in future
    //enum TicketState {Non_Existed, Paid, Fulfilled, Cancelled}

    // Rarity type
    /**
     * @dev Rarity type of token
     * @param Unique -- only one token can exist
     * @param Rare -- there are limited number of tokens
     * @param Common -- there are unlimited number of tokens
     */
    enum RarityType {Unique, Rare, Common}

    // map from mastercopy_id  to itemsale address
    mapping(uint256 => address) public mastersales;



     /*
                    @NOTE
            if we mint 3rd item for some master (and already have two minted items) then
            item_id is global counter and can't be determine (think of it as random). let's assume that we have our third token item_id = 245, and we minting for master_id = 18
            itemIndex[245] = itemIds[18].lenght // = 2
            itemIds[18] = itemIds[18].push(245) // = [x , y, 245] (3 elements array)
            
            itemIds is a map which return you array of items tethered to specific master
            arrays starts with 0, so item 245 will be stored as third element of array from itemIds[18] and can be getted from there 

        */

    // map from master_id to item ids
    mapping (uint256 => uint256[]) public itemIds; // -- length of this array can be used as totalSupply!  (total number of specific token (items) can be getted as itemIds[master].length)

    // map from token ID to its index in itemIds
    mapping (uint256 => uint256) itemIndex;         // -- each token have a position in itemIds array. itemIndex is help to track where exactly stored itemId in itemIds array. 

    
    // map from sale address to organizer -- TODO: this can be double info from factory
    mapping(address => address) retailers;
    
    // map from masterId to author address
    mapping(uint256 => address) public authors;

    // map from author address to masterIds array
    mapping(address => uint[]) public author_masterids; // can be used to get all objects created by one author

    // map from itemId to masterId
    mapping(uint256 => uint256) public ItemToMaster;

    // map from from link to master_id
    mapping(string => uint256) public links;

    // map from MasterCopyId to Meta info
    mapping(uint256 => ItemInfo) public MetaInfo;

    /**
   *                                                            Item information
   *    @dev ItemInfo contains meta information about Master/Item. 
   *    @param magnet_link -- unique link to a torrent
   *    @param author -- address of author
   *    @param rarity -- rarity of an item, see RarityType
   *    @param i_totalSupply -- it is not a total supply. total supply of a token is itemIds[mater_id].lenght
   */
    struct ItemInfo 
    {
    // TODO: is this really nececcary to write it as string?
    // this is link to torrent 
    // @todo: *WARNING -- should be unique!!*
    string magnet_link;

    // TODO: rework this for searching functionality (case when user seacrh nft item at marketplace by name (or ticker?))
    string description;
    address author;
    RarityType rarity;
  
    // @todo rename it
    uint i_totalSupply; // 0 means infinite, so it not be actually considered as usual totalSupply(!!)
    // ACTUAL total supply for specific mastercopy can be getted as itemIds[master_id].lenght

    }

    constructor(string memory name_, string memory smbl_) ERC721(name_,smbl_) ERC721Enumerable() {}

    // @todo should be changed visibility to external?
    /**
     *  @dev This function 'plug' itemsale contract from factory to mastersales map (works only for MoonShard NFT, should be called after MasterCopy creation)
     *  @param organizer -- address of seller (author)
     *  @param _masterId -- Id of mastercopy, which has been created by CreateMasterCopy
     *  @param _sale -- address of crowdsale contract. Note that this function can be called only from factory.
     */
    function PlugCrowdSale(address organizer, uint256 _masterId, address _sale) public {
        // only factory knows about crowdsale contracts and only she should have access to this
        require(msg.sender == factory_address, "MSNFT: only factory contract can plug crowdsale");
        // only author of asset can plug crowdsale
        ItemInfo memory meta;
        meta = MetaInfo[_masterId];
        address author = meta.author;
        require(author == organizer, "you don't own to this master id");
        require(mastersales[_masterId] == address(0), "MSNFT: you already have plugged sale ");
        mastersales[_masterId] = _sale;
    }

    /**
     * @dev safely reserve master_id
     * @param _author -- address of author
     * @return _master_id 
     */
    function _reserveMasterId(address _author) internal returns(uint256 _master_id) {
        _master_id_count.increment();
        _master_id = _master_id_count.current();

        emit MasterIdReserved(_author,_master_id);
        emit MasterIdReservedHuman(_author,_master_id);

        return _master_id;
    }


    // 
    /**
     * @dev create Master Copy of item (without starting sale). It wraps file info into nft and create record in blockchain. Other items(tokens) are just links to master record
     * @param link -- link to a file
     * @param _author -- address of author
     * @param _description -- indexed description to be stored in events
     * @param _supplyType -- type of supply, where 1 is for unique nft, 0 for common nft, anything else is rare. Used to check inside mint func
     * @return c_master_id reserved mastercopy id
     */
    function createMasterCopy(string memory link, address _author ,string memory _description, uint256 _supplyType) public returns(uint256 c_master_id){

        require(msg.sender == factory_address, "MSNFT: only factory contract can create mastercopy");

        uint256 mid = _reserveMasterId(_author);
        require(links[link] == 0, "MSNFT: file with that link already have been tethered");

        RarityType _rarity = set_rarity(_supplyType);
        uint m_totalSupply;
        if (_rarity == RarityType.Rare){
            m_totalSupply = _supplyType;
        } if (_rarity == RarityType.Unique) {
            m_totalSupply = 1;
        } if (_rarity == RarityType.Common) {
            m_totalSupply = 0;  // infinite. which means it is not really totalSupply
        }
        MetaInfo[mid] = ItemInfo(link, _description,_author,_rarity, m_totalSupply);
        authors[mid] = _author;
        links[link] = mid;
        author_masterids[_author].push(mid);
        emit MaterCopyCreated(_author, mid, _description, link);
        emit MasterCopyCreatedHuman(_author,mid,_description,link);
        // return mastercopy id
        return mid;
    }

     /**
     * @dev setting rarity for token
     * @param _supplyType type of supply, see createMasterCopy
     * @return _rarity type of rarity based at supplyType
     */
     function set_rarity(uint256 _supplyType) private pure returns(RarityType _rarity) {

        if (_supplyType == 1) {         // Only one token exist
            _rarity = RarityType.Unique;
        }
        if (_supplyType == 0) {         // Unlimited sale
            _rarity = RarityType.Common;
        } else {
            _rarity = RarityType.Rare;  // Limited sale
        }
        
        return _rarity;
    }


    /**
     *  @dev get rarity of specific master
     *  @param _masterId master copy id
     *  @return RarityType 
     */
    function get_rarity(uint256 _masterId) public view returns (RarityType) {
        
        ItemInfo memory meta;
        meta = MetaInfo[_masterId];
        RarityType _rarity_type = meta.rarity;
        return _rarity_type;
    }


   

    /**
     *  @dev Mint new token. Require master_id and item_id
     *  @param to whom address should mint
     *  @param m_master_id master copy of item
     *  @param item_id counter of item. There are no incrementation of this counter here, so make sure this function is purely internal(!)
     */
    function Mint(address to, uint m_master_id, uint item_id) internal {

        ItemInfo memory meta;
        meta = MetaInfo[m_master_id];
     
        // Check rarity vs itemAmount
        if (meta.rarity == RarityType.Unique) {
            require(itemIds[m_master_id].length == 0 , "MSNFT: MINT: try to mint more than one of Unique Items");
        }
        if (meta.rarity == RarityType.Rare) {
            require(itemIds[m_master_id].length < meta.i_totalSupply," MSNFT: MINT: try to mint more than totalSupply of Rare token");
        }
        
        _mint(to,item_id);

        /*
            
            if we mint 3rd item for some master (and already have two minted items) then
            item_id is global counter and can't be determine (think of it as random). let's assume that we have our third token item_id = 245, and we minting for master_id = 18
            itemIndex[245] = itemIds[18].lenght // = 2
            itemIds[18] = itemIds[18].push(245) // = [x , y, 245] (3 elements array)
            
            itemIds is a map which return you array of items tethered to specific master
            arrays starts with 0, so item 245 will be stored as third element of array from itemIds[18] and can be getted from there 

        */
        itemIndex[item_id] = itemIds[m_master_id].length;   // this item_id will be stored at itemIds[m_master_id] at this *position order*.  
        itemIds[m_master_id].push(item_id);               // this item is stored at itemIds and tethered to master_id
        ItemToMaster[item_id] = m_master_id;            // here we can store and obtain what mid is tethered to specific token id, so we can get MetaInfo for specific token fast
        emit MintNewToken(to, m_master_id, item_id);
    }


    /**
     * @dev this function emit item outside of buying mechanism, only owner of master can call it
     * @param to whom minted token will be sent
     * @param m_master_id id of mastercopy
     */
    function EmitItem(address to, uint m_master_id) public {
        ItemInfo memory meta;
        meta = MetaInfo[m_master_id];
        require(msg.sender == meta.author, "MSNFT: only author can emit items outside of sale");

        _item_id_count.increment();
        uint256 item_id = _item_id_count.current();
        Mint(to, m_master_id, item_id);
    }

    // @todo -- make external instead of public?
    /**
     *  @dev external function for buying items, should be invoked from tokensale contract
     *  @param buyer address of buyer
     *  @param itemAmount how much of tokens we want to buy if possible
     *  @param master_id Master copy id 
     */
    function buyItem(address buyer, uint256 itemAmount, uint256 master_id) public{
        address _sale = mastersales[master_id];
        require(_sale == msg.sender, "MSNFT: you should call buyItem from itemsale contract");

        for (uint256 i = 0; i < itemAmount; i++ ){
            _item_id_count.increment();
            uint256 item_id = _item_id_count.current();

            Mint(buyer, master_id, item_id);
            
            emit ItemBought(buyer,master_id,item_id);
            emit ItemBoughtHuman(buyer,master_id,item_id);
        }

    }

    // This function is burning tokens. 
    // @deprecated
    /*
    function redeemTicket(address owner,uint256 tokenId, uint256 event_id) public{
        require(eventsales[event_id] == msg.sender, "caller doesn't match with event_id");
        super._burn(owner,tokenId); 

       // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
       // then delete the last slot (swap and pop).


        uint256 ticket_index = ticketIndex[tokenId];
        uint256 lastTicketIndex = ticketIds[event_id].length.sub(1);

      //  uint256[] storage ticketIdArray = ticketIds[event_id];
      //  uint256 lastTicketId = ticketIdArray[lastTicketIndex];

        uint256 lastTicketId = ticketIds[event_id][lastTicketIndex];


        ticketIds[event_id][ticket_index] = lastTicketId; // Move the last token to the slot of the to-delete token
        ticketIndex[lastTicketId] = ticket_index;         // Update the moved token's index

        ticketIds[event_id].length--;  // remove last element in array
        ticketIndex[tokenId] = 0;


    }
    */



    //                  @FIXME: fix get items of owner
    /*
  //  Gets the list of token IDs of the requested owner.
     function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return super._ownedTokens[owner];
    }



    function getTicketByOwner(address _owner) public view returns(uint256[] memory) {
        uint256[] storage tickets = _tokensOfOwner(_owner);
        return tickets;
    }
    */



    /**
     * @dev get itemSale contract address tethered to this master_id
     */
    function getItemSale(uint256 master_id) public view returns(address) {
        address sale = mastersales[master_id];
        return sale;
    }



     /**
     *  @dev get author of master
     */
    function get_author(uint256 _masterId) public view returns (address _author) {
        _author = authors[_masterId];
        return _author;
    }

    function get_master_id_by_link (string memory link_) public view returns (uint256 _masterId) {
        _masterId = links[link_];
        return _masterId;
    }

    function get_author_by_link(string memory link_) public view returns (address author_) {
        uint256 _masterId = get_master_id_by_link(link_);
        author_ = authors[_masterId];
        return author_;
    }

    /**
     *  @dev get masterIds array for specific author address
     */
    function getMasterIdByAuthor(address _creator) public view returns (uint[] memory) {
        return author_masterids[_creator];
    }

    /**
     *  @dev get ItemInfo by item id
     *  @param item_id item id (equal to tokenid)
     */
    function getInfobyItemId(uint item_id) public view returns (ItemInfo memory){
        uint master_id = ItemToMaster[item_id];
        ItemInfo memory _itemInfo = MetaInfo[master_id];
        return _itemInfo;
    }

    /**
     *  @dev get MetaInfo by master id
     *  @param master_id master id
     */
    function getInfoByMasterId(uint master_id) public view returns (ItemInfo memory){
        return MetaInfo[master_id];
    }

    /**
     *  @dev get Master sale address by master id
     *  @param master_id master id
     */
    function getSaleAddress(uint master_id) public view returns (address) {
        return mastersales[master_id];
    }


    /*      
    function getTicketStatus(uint item_id) public view returns (TicketState status) {
        ItemInfo memory info = itemInfoStorage[item_id];
        status = info.state;
        return status;
    }
    */


    /**
     *  @dev update factory address. as we deploy separately this contract, then factory contract, then we need to update factory address outside of MSNFT constructor
     *  also, it may be useful if we would need to upgrade tokensale contract (which include upgrade of a factory contract), so it can be used when rollup new versions of factory and sale
     */
    function updateFactoryAdress(address factory_address_) public onlyOwner() {
        factory_address = factory_address_;
    }

    function getFactoryAddress() public view returns(address) {
        return factory_address;
    }


    /*
    Usefull tips:
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    Gets the list of token IDs of the requested owner.
     function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }
    */

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//import "../../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../node_modules/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
//import "../../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "../../../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../../../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "../../../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../../../node_modules/@openzeppelin/contracts/access/Ownable.sol";


/**
 *      CurrenciesERC20
 * @title CurrenciesERC20
 * @dev This contract allow to use erc20 tokens as a currency in crowdsale-like contracts
 *
 */
contract CurrenciesERC20 is ReentrancyGuard, Ownable {


    using SafeMath for uint256;
  //  using SafeERC20 for IERC20;

    // Interface to currency token
    //IERC20 public _currency_token;

    // Supported erc20 currencies: .. to be extended.  This is hard-coded values
    /**
     * @dev Hardcoded (not-extetiable after deploy) erc20 currencies
     */
    enum CurrencyERC20 {USDT, USDC, DAI, MST, WETH} 

    struct CurrencyERC20_Custom {
        address contract_address;
        IERC20Metadata itoken; // contract interface
    }


    // map currency contract addresses
    mapping (CurrencyERC20 => IERC20Metadata) public _currencies_hardcoded; // should be internal?

    // mapping from name to currency contract (protected)
    mapping (string => CurrencyERC20_Custom) public _currencies_custom;


    // mapping from name to currency contract defined by users (not protected against scum)
    mapping (string => CurrencyERC20_Custom) public _currencies_custom_user;


    // @TODO: Investigate how to add different types of ERC20.  Old type have name as public string and no getter, new type have name as private sting and getter for it.
    function AddCustomCurrency(address _token_contract) public {

      IERC20Metadata _currency_contract = IERC20Metadata(_token_contract);
    
       // if (_currency_contract.name != '0x0')


        string memory _name_c = _currency_contract.name();  // @note -- some contracts just have name as public string, but do not have name() function!!! see difference between 0.4.0 and 0.8.0 OZ standarts need future consideration
      //  uint8 _dec = _currency_contract.decimals();
        


        address _owner_c = owner();
        if(msg.sender == _owner_c) {
            require(_currencies_custom[_name_c].contract_address == address(0), "AddCustomCurrency[admin]: Currency token contract with this address is already exists");
            _currencies_custom[_name_c].itoken = _currency_contract;
         //   _currencies_custom[_name_c].decimals = _dec;
            _currencies_custom[_name_c].contract_address = _token_contract;
        }
        else {
            require(_currencies_custom_user[_name_c].contract_address == address(0), "AddCustomCurrency[user]: Currency token contract with this address is already exists");
            _currencies_custom_user[_name_c].itoken = _currency_contract;
          //  _currencies_custom_user[_name_c].decimals = _dec;
            _currencies_custom_user[_name_c].contract_address = _token_contract;
        }
    }


    constructor(address US_Tether, address US_Circle, address DAI, address W_Ethereum, address MST) {

       
       require(US_Tether != address(0), "USDT contract address is zero!");
       require(US_Circle != address(0), "US_Circle contract address is zero!");
       require(DAI != address(0), "DAI contract address is zero!");
       require(W_Ethereum != address(0), "W_Ethereum contract address is zero!");
       require(MST != address(0), "MST contract address is zero!");
       
       
       
       
        _currencies_hardcoded[CurrencyERC20.USDT] = IERC20Metadata(US_Tether);
        _currencies_hardcoded[CurrencyERC20.USDT] == IERC20Metadata(US_Tether);
        _currencies_hardcoded[CurrencyERC20.USDC] = IERC20Metadata(US_Circle);
        _currencies_hardcoded[CurrencyERC20.DAI] = IERC20Metadata(DAI);
        _currencies_hardcoded[CurrencyERC20.WETH] = IERC20Metadata(W_Ethereum);
        _currencies_hardcoded[CurrencyERC20.MST] = IERC20Metadata(MST);



       // AddCustomCurrency(US_Tether);
       // AddCustomCurrency(US_Circle);
       // AddCustomCurrency(DAI);
       // AddCustomCurrency(W_Ethereum);
        AddCustomCurrency(MST);

          


    }


  function get_hardcoded_currency(CurrencyERC20 currency) public view returns (IERC20Metadata) {
       return _currencies_hardcoded[currency];
    }

}