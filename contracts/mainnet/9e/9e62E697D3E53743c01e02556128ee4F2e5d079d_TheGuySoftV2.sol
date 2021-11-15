// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

contract TheGuySoftV2 is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Metadata {
        string topText;
        string bottomText;
        string bottomText2;
        string description;
    }

    mapping(uint256 => Metadata) private Metadatas;

    // mainnet
    IERC721 internal BLITMAP_CONTRACT = IERC721(0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63);

    // test
    //IERC721 internal BLITMAP_CONTRACT = IERC721(0x1b4C2BA0c7Ee2AAF7710A11c3a2113C24624852B);

    function withdrawToPayees(uint256 _amount) internal {
        payable(0x3B99E794378bD057F3AD7aEA9206fB6C01f3Ee60).transfer(
            _amount.mul(17).div(100)
        ); // artist

        payable(0x575CBC1D88c266B18f1BB221C1a1a79A55A3d3BE).transfer(
            _amount.mul(17).div(100)
        ); // developer

        payable(0xBF7288346588897afdae38288fff58d2e27dd235).transfer(
            _amount.mul(17).div(100)
        ); // developer

        payable(BLITMAP_CONTRACT.ownerOf(346)).transfer(
            _amount.mul(49).div(100)
        ); // owner of #346
    }

    function mint(
        address _to,
        string memory _description,
        string memory _topText,
        string memory _bottomText,
        string memory _bottomText2
    ) internal {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        Metadatas[tokenId] = Metadata(
            _topText,
            _bottomText,
            _bottomText2,
            _description
        );
        _safeMint(_to, _tokenIdCounter.current());
    }

    function mintCustom(
        address _to,
        string memory _description,
        string memory _topText,
        string memory _bottomText
    ) external payable nonReentrant {
        require(msg.value >= 0.04 ether, "not enough ethers");
        withdrawToPayees(msg.value);
        mint(_to, _description, _topText, _bottomText, "");
    }

    function mintBatch(address _to, uint256 _amount)
        external
        payable
        nonReentrant
    {
        require(msg.value >= _amount.mul(0.02 ether), "not enough ethers");
        withdrawToPayees(msg.value);
        for (uint256 i = 0; i < _amount; i++) {
            mint(
                _to,
                "Your bid is so soft that... ",
                "Your bid is so soft that... ",
                "...you have been visited by",
                "The Guy Soft, King of cucks"
            );
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        Metadata memory _metadata = Metadatas[tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "The Soft Bid Guy", "description": "',
                                _metadata.description,
                                ' | https://yourbidsux.wtf/ | Original Blitmap ID: #346", "image": "data:image/svg+xml;base64,',
                                string(
                                    Base64.encode(
                                        bytes(
                                            abi.encodePacked(
                                                "<svg xmlns='http://www.w3.org/2000/svg' baseProfile='tiny-ps' viewBox='0 0 320 320' width='350' height='350'><style><![CDATA[text{letter-spacing:-0.8px}.B{font-family:press_start_2pregular}.C{word-spacing:-4px}]]></style><path fill='#d57eb1' d='M320 320H0V0h320v320z'/><path fill='#e5acb3' d='M320 290h-30v-10h-20v-10h-30v-10h-10v-10h-30v-10h-40v-10h-30v-10h-20v-10H80v-10H60v-10H50v-10H30v-20H20v-20H10v-20h10V90h10V80h10V70h20V60h20V50h110v10h40v10h10v10h20v10h20v10h10v10h20v10h10v170z'/><path fill='#ba7393' d='M320 110h-10v-10h-10V90h-20V80h-20V70h-20V60h-10V50h-30V40H80v10H50v10H40v10H20v10H10v30H0v40h10v20h10v10h10v10h10v10h10v10h20v10h30v10h30v10h20v10h40v10h30v10h20v10h20v10h30v10h20v10h10v-20h-29l-1-10h-20v-10h-29l-1-10h-10v-10h-30v-10h-40v-10h-29l-1-10h-20v-10H80v-10H60v-10H50v-10H31l-1-20H20v-20H10v-20h10V90h10V80h10l1-10h19V60h20l1-10h109v10h39l1 10h9l1 10h19l1 10h19l1 10h10v10h19l1 10h10v-10zm-100 60v-20h-10v10H60v-10H50v20h10v19l1 1h139v-10H70v-10h130v9l1 1h9v-10h10zm-60-50v20h30v-20h-30zm-90 20h30v-20H70v20zm-30-40v10h70v-10h10V90h-10V70h-10v30H40zm110-30h-10v20h-10v10h10v10h110v-10H150V70z'/><path fill='#e9e9e9' d='M60 140v10h40v-10H60zm0-40V90h40v10H60zm60-10h10v10h10v10h-30v-10h10V90zm0-20v10h10V70h-10zm30 30V90h50v10h-50zm10 40v10h40v-10h-40zm-50 50v10h30v-10h-30zm90-10v10h10v-10h-10zm20 0h-9l-1-1v-9h10v10z'/><text fill='#fff' x='150' y='30' font-size='12' class='B C' dominant-baseline='middle' text-anchor='middle'>",
                                                _metadata.topText,
                                                "</text><text fill='#fff' x='150' y='270' font-size='12' class='B C' dominant-baseline='middle' text-anchor='middle'>",
                                                _metadata.bottomText,
                                                "</text><text fill='#fff' x='150' y='290' font-size='12' class='B C' dominant-baseline='middle' text-anchor='middle'>",
                                                _metadata.bottomText2,
                                                "</text><defs><style>@font-face{font-family:'press_start_2pregular';src:url(data:application/font-woff2;charset=utf-8;base64,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) format('woff'); font-weight:normal;font-style:normal;}</style></defs></svg>"
                                            )
                                        )
                                    )
                                ),
                                '"}'
                            )
                        )
                    ),
                    "#"
                )
            );
    }

    constructor() ERC721("The Soft Bid Guy", "SOFTGUY2") onlyOwner {}
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

