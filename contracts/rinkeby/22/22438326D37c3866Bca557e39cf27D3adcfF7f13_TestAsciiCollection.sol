//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "base64-sol/base64.sol";
import "./AsciiArt.sol";

contract TestAsciiCollection is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    using SafeMath for uint256;

    address _asciiArtContractAddress;

    uint private constant maxTokensPerTransaction = 1;
    uint256 private constant nftsNumber = 10;

    constructor(address asciiArtContractAddress)
    ERC721("TestAsciiCollection", "TACNFT")
    {
        _asciiArtContractAddress = asciiArtContractAddress;
    }

    function mint(uint tokensAmount) public {
        require(tokensAmount > 0, "Wrong amount");
        require(tokensAmount <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_tokenIdCounter.current().add(tokensAmount) <= nftsNumber, "Tokens number to mint exceeds number of available tokens");

        for (uint i = 0; i < tokensAmount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory artPiece = AsciiArt(_asciiArtContractAddress).getArtForId(tokenId - 1);
        string memory finalSvg = string(abi.encodePacked("<svg width='320' height='320' viewBox='0 0 320 320' xmlns='http://www.w3.org/2000/svg'>"));
        finalSvg = string(abi.encodePacked(finalSvg, "<rect width='100%' height='100%' fill='#000'></rect>"));
        for (uint i = 0; i < 32; i++) {
            string memory yString = Strings.toString(i == 0 ? 0 : i * 11 - 2);
            finalSvg = string(abi.encodePacked(finalSvg, "<text x='0' y='", i == 0 ? "-2" : yString, "' width='100%' dominant-baseline='middle' textLength='319' font-size='8px' font-family='monospace' fill='#fff'>"));
            uint startIndex32 = i == 0 ? 0 : i * 64;
            finalSvg = string(abi.encodePacked(finalSvg, substring(artPiece, startIndex32, startIndex32 + 64)));
            finalSvg = string(abi.encodePacked(finalSvg, "</text>"));
        }
        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));

        return formatTokenURI(svgToImageURI(finalSvg));
    }

    function svgToImageURI(string memory svg) private pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function formatTokenURI(string memory imageURI) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            "Test Ascii Collection",
                            '", "description":"Just a test Ascii collection to check on chain ASCII art.", "attributes":"", "image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function substring(string memory str, uint startIndex, uint endIndex) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function withdraw() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AsciiArt {
    function getArtForId(uint id) public view returns (string memory) {
        string[10] memory asciiChars = ["[email protected]@[email protected]@@@[email protected]@@@[email protected]@[email protected]@@@@@@@[email protected]@[email protected]@@@@@@@[email protected]@@@@@[email protected]@@@@@[email protected]@880000GG00GGGGGGLLtt11iiiiii111111iiiiii11ttttCC0000000000GGGG000000000000GGCCCCff11iiii11ttffLLLLff11iiii1111ttCC0000GGGGGGGG0000000000GGLLLLffttiiii11ffLLLLLLLLLLff11iiii1111ttGG00GGGGGGGG00888800CCCCGGLLtt11ii11LLCCCCCCCCLLLLffttiiiiii1111ff000000GGCC8800GGCCCC0000ff11iiiiffCCCCCCCCCCCCCCLLff11iiii111111CC0000GGGG00GGGGGG0088GG1111iittCCCCCCCCCCCCLLLLLLffttiiiiii1111tt0000GG00GGGGGGGG0088LL11ii11fftt11ttLLLLLLtt1111111111iiiiii1111LL000000GGGGGGGGGG00ff11iiffLLLLffffffLLffttttffffffttiiiiiiii11tt000000GGGGGG0000GGttiiiiCCfftt11ttffCCfftttt111111tt11iiiiiiii11CC0000GGGG888800CC11iittLL11ii11ttLLCCfffftt1111ii11ttiiiiiiiiiitt0000CC00880000CC11iiffCCLLffffLLCCCCffffffffffffffff11;;iiiiiiiiCCGGGG00888800ff11iiCCGGCCCCCCCCGGCCffffLLCCCCLLLLffttiiiiiiiiiittGG0000008800ttiiiiGGGGGGCCCCCCLLLLffffLLCCCCLLLLffttiiiiiiiiiiiiLL00000088GGttiiiiGGGGCCCCLLLLttffttttffLLLLLLLLffttiiiiiiiiiiiitt00000000CC11iiiiCCCCCCLLLLCCLLffffffffLLffffffff11iiiiiiiiiiiiii00000000ff11iiiiLLCCLLLLLLLLfffffffffffffffffftt11ii;;iiiiiiiiii000000GGff11iiiiLLLLLLffttttfftttttt11ttfffffftt11iiiiiiiiiiiiiiGG0000GGff11ii11LLCCCCLLLLLLffffttttttffffffffff11iiii;;;;iiiiiiGG0000GGff11ii;;ttCCLLLLLLLLffffffffffffffffffttiiiiii;;;;iiiiiiGGGGGGGGLL11ii;;;;LLLLLLCCCCLLLLLLfffffffftttt11ii;;;;;;;;;;iiiiGGGGGGGGLL11iiii;;iiLLLLLLCCCCLLLLfffftttttt11ii;;;;;;;;;;;;iiiiGGGGGG00LLtt11ii;;;;11ffLLLLLLfffffftt111111iiii;;;;;;;;;;iiiiiiGGGGGG00CCtt11iiii;;;;iitttttttttt1111111111iiii;;;;;;;;;;iiiiiiGGGGGGGGCCttiiiiii;;;;;;11tttttttt111111111111ii;;;;;;;;;;;;iiiiGGGGGGGGCCff11iiii;;;;;;iitttttttttttt11111111ii;;;;;;;;;;;;iiii0000GGGGCCLL11iiiiii;;;;ii11fffftttttttttttt11ii;;;;;;;;ii;;iiii","tttttttttttt111111111111ii11111111111111111111111111111111111111tttttttttttt1111111111111111111111tttttttttttt111111111111111111fftttttttttt1111111111111111ttffLLLLttttttffttfftt11111111111111GGLLtttttttt1111tt11111111ttfftttttt11111111ii111111tt111111111188GGLLtttttttttttttt1111ttfffffffftt11111111iiii11iitttttt1111118800GGfftttttttttttt11ttttffffLLLLCCCCLLffttiiiiii;;;;111111tttt888800CCttttttttttttttttffGG88888800GGGGGGLLtt11ii;;;;;;[email protected]@@@888800GGGGCCLLtt11ii;;;;;;;;iittGG000000LLttttttttttttGG0088888888GGGGCCLLLLLLff1111ii;;;;;;;;ttGGGGGGGGCCffttttttttLL00008888000000GGCCLLLLLLtt1111ii;;;;;;;;;;GGGGGGGGCCffttttttffGG00888888888800GGCCCCCCfftt1111ii;;;;;;;;;;GGCCCCCCCCLLttttttLLGG0088000000GGCCCCCCGGCCLLffttiiii;;;;;;;;;;GGCCCCCCLLLLffttttffGGCCLLLLCCCCLLtt1111ttfffffftt11ii;;;;;;;;;;CCCCCCLLLLfffftt11ffLLff11ttffCCtt11tttttttt11tttt11ii;;;;;;;;;;CCCCLLLLffffttttLLCCCCtt11ttffCCtt11iiiiii11tt;;;;iiii;;;;;;;;;;LLLLLLffffttttttCCLLtt11ii11CCCCtt11iiiiii11tttttt11iiii;;;;;;;;LLfffftttttttt11ffffCCffttCC88CCffLLLLLLfffffffftt11ttiiiiii1111LLfftttttttttttt11008800008800LLffffCCGGGGCCttttttttttii11111111LLtt1111ttttttfftt0000GGGGGGLLttLLttCCGGfftttttt11tttt11tt111111LLttii11ttttffttff00CCffLLfftt111111ttfffftttttttttttt11ttii11ttLLtt1111ttffffttttCCffttLLtttt111111ttttttfffftttttttttt1111ttttLLff1111fffftt1111LLttttGGGGtt1111ttttttttttfftttttttttt1111ttffLLffttttffff111111LLttttffffttttttttttttttffffttttttttttttttttffLLfffffffftt111111LLLL1111LLLLLLffttii11ttttttttttttttttii;;ffffLLfffffftt111111ttLLCCLLGGGGGGff1111ttttttttttttttttttttii11ffffLLffLLff11111111ttttCCGGGGLLfftttttttttttttttttttttttt11iifffffffffffftt111111ttttttLLGG00LLtttttttttttttttttttttttt111111fffffffffftt11111111ttttttttCC0000GGLLtttttttttttttttttttt1111fffffffffftt11111111tttttt11ttffGGGGCCLLffttttttttfffftttt1111ttffffffffff1111111111tttt1111ttttLLLLfffffffffffffftttttttt111111LLffffffff1111ii11tttttt11ttttffLLLLfffffffffffftttttttt11111111G[email protected]@LLffff",";;;;iiiiiiii1111iiii11ttttttfftttttttttttt1111ii11111111ttffLLLL;;;;iiii;;ii111111tttttttttttttt11tttttttttt11iiii111111ttffLLLL;;;;ii;;;;;;ii11111111tt11ii1111111111fftttt1111iiii1111ttffLLLL;;;;;;;;;;;;ii11iiiittttii111111iiiiiitttttttt11ii111111ttffLLCC;;;;;;;;;;;;iiiiiiiiii11111111111111iiii11tt11111111ii11ttffLLLL;;;;;;;;;;;;ii;;;;;;ii1111ffLLGGCCLLtt11iiii11111111iiii11ffffLL;;;;ii;;;;ii;;;;[email protected]@@@8800GGCCffii11tttt1111iiii11ffff;;;;iiiiiiii;;iittCCCCGG008888888800GGGGCCtt11tttttt11ii11tttttt;;iiiiiiiiii;;iiLLCCCCCCGG0000000000GGCCLLffiitttt1111ii11tttt11;;iiiiiiiiii;;ttLLCCCCCCCCGGGG00GGGGCCCCLLffii1111111111tttttt11;;iiiiiiii;;ii11LLCCCCCCGG0000GGGGGGGGCCLLff11iiii11ttfffftt1111;;iiiiiiii;;;;11LLCCGGGG00000000000000GGCCLL11iiiiiittLLLLtt11ii;;iiiiii;;;;;;ttLLCCCCCCLLLLCCGGGGGGCCLLLLLL11iiiiii11fftt1111ii;;iiii;;;;tt;;ffLLfftt11iiii11ttfftt11iiii1111iiiiiiiiii11111111;;iiii;;iitt11CCff1111iiiiiiiittLLiiii;;ii1111iiii;;;;ii11tttt11;;;;ii;;iitt11CCCCff11iiiiiiiiCC0011iiiiii11tt11iiiiiiii11tt1111;;iiii;;iiLL11CCGGGGCCttttffCCGG88LLffttttLLCC11iiiiiiii11111111;;iiii;;iiCCttLLCCGG00GGGGGGGGGG88GGCCLLCCCCLL11iiii;;;;11tttt11;;iiii;;iiffCCffLLCCGGGG00CCCC0088GGLLGGCCCCff11iiii;;;;iitttttt;;iiiiiiiiiiCCttffLLCCGGCCCCGGGG00GGCCCCLLffttiiiiii;;;;iitttttt;;iiiiiiiiiiiittttffLLCCGGGG1111tt11ffLLfftttt1111ii11iiiittfftt;;iiiiiiiiiiii11ttttffCCGGGGtt11iiiiffCCffttttttttttttiittLLCCCCiiii;;;;iiiiiiiittffffLLCCCCGGtt11ttffffffttLLLLLLLLLLLLCCGGGGGGii;;;;;;iiiiiiiittttttff11tttt11111111ttttffCCGGGG00000000000000;;;;;;;;iiiiiiii11ttttttttffLLLLfftttt11ttttttffCC00000000000000;;;;;;iiiiiiii11tttttttttttt111111111111tt11ttLLCCGG000000000000iiiiiiiiii1111fftt11tttttttttt11111111tttt11iiLLffffLLGG0000GGGGiiiiiiiiii1111LL111111tttttttt1111tttttt111111ttLLLLLLLLCC0000001111iiiiiiiiffCCiitt111111tttttttttttt111111ttttCCCCCCCCGG000088111111111111000011tt111111111111111111111111ttLLLLCCLLLLLLGG0000111111ttttLL888[email protected]@88GGtt11111111111111111111ttCC00CCCCLLffLLCCGG00","1111iiiiii11ii1111ffCC000000GGGGCCLLLLCCLLfftt111111111111tttttt111111iiii1111ttLLGG00GGGGGGCCGGCCffttLLCCGGLLtttttttttttttttttt111111111111ffGGGGGGCCCCGGCCCCCCLLLLffffCCGGGGLLttttttttttffffff111111ii11ffGGGGCCLLCCGGCCCCCCffffLLffLLLLCCGGGGfftttttttttttttt11111111ffGGGGCCCCCCCCCCCCCCLLffLLLLLLffCCLLCC00GGfftttttttttttt111111ffGGGGCCLLLLLLLLLLLLCCLLffLLLLCCLLCCCCCCGG00CCtttt11111111ttttffCCCCCCLLffffffffffffLLffLLCCCCGGGGCCGGCCCCGGGGff1111111111ffffLLCCCCCCffffttffttttffffffffLLLLCCCCCCCCCCCCCCGGff1111111111ffLLLLLLLLffttfftttt11ttffttttffffffLLCCCCffLLLLffGGCCtt11111111LLLLLLLLLLtttttt111111tttt11ttLLffttffCCGGLLffLLffLLGGtttt111111LLLLffffLLtttttt11ii11111111ffLLtt11ttLLGGLLffttffffGGLLtt111111LLffffffff11tt1111ii111111ttCCLLff11ttCC00LLffttttttCCCCttttttttLLffffffff11tt11iiiiiiiittCCCCfftt11ffCCCCffLLff11ttLLGGLLttttttLLffttttffiitt11iiiiii1111ttffLLLLfftt11ttLLLLLLiittLLCCLLttttttLLffffttttii11iiii1111111111ffCCGGLLtt1111ffCCCCii11ffCCCCfftt11ffttffffff1111iitt1111iiffttffGG00CCtt11ffffLLGG11iittLLCCff1111ffttffffff1111ttLLCCLLLLLLCCCCGG8800GGLLCCGG0000ttii11LLCCLL1111ttfffffffftt11ttGGGG00000000GGGG8888880088888800ttiittLLCCLLff11ttfffffffftt11ffGG0000000000GG008888008888888800ff11ttLLCCLLLLttffffffffffttttttCCGG0000GGLLGG008888GGCCGG000000ttttttLLCCCCLLffttffffttffttttttLLCCCCLLffLLLLCCGGGGGGffLLCCGGGGffttttLLLLCCLLLLffffffttffttffffttLLffttffCCLLffffGG00CCffLLCCCCffttttLLLLCCCCLLffttffttff11ffttttffffttttffLLffLLCCCCffffLLGGffffttttffLLCCCCLLffffffttffiittttttffCCCCLLLLCCGGGGGGGGCCCCGGGG11ttffffffLLCCCCLLffffLLffffiitttt11ttLLCCCCCCCCCCCCGG0000GGCCLL;;11ffffLLCCCCLLLLffffLLLLtt11ttttii11ffCCGGCCCCLLCCCC0000GGCCii;;11ffffLLCCGGLLLLffffLLLLtt11tttt11iittLLCCGGGG0000000000CCii;;iittffttLLCCGGCCLLffffCCLLtt11ttff11iiiittffCCGGGGGG0000CCii;;;;iittffffffCCGGCCLLLLLLLLLLtt11ttff1111;;ii11ttffLLLLLLLL11;;;;;;iittffffffCCGGCCLLLLCCLLLLff11ffff1111iiii11ttttttffffff11;;;;;;11ttffLLLLLLGGGGCCCCCCLLLLff11fffftt11111111ttffffffffff11ii;;;;11ttffLLLLffGGGGCCCCLLLLLLtt11ffffttii1111ttffffLLLLLLff11ii;;;;1111ttLLLLffCCGGGG","ffLLCCLLCCGGGGGGGGCCLLfftt11111111ffttffffttffLLCCCCCCCCLLLLLLffttLLCCCCGG000000GGLLff11111111iiiiii1111ttttttffCCCCCCGGCCLLLLffttLLGGGG00000000GGffiiii11111111ii;;iiii11tt1111LLCCCCCCCCCCCCffttGG00GG0000GGGGff11111111iiiiiiiiiiiiiiii11iittLLCCCCCCCCCCLLffLL0000GGCCCCCCLL11iiiiii11iiiiiiiiiiiiiiii;;;;iittLLCCCCCCLLLLffGG00GGLLLLCCLLttiiiiiiiiiiii11;;iiii11iiiiiiiiii11ttLLCCCCLLLLLL0000CCLLLLCCLLii;;iiiiiiii11iiiiii11tt11iiiiiiii1111LLCCCCLLLLff0000GGLLLLLLff;;;;iiiiii11iiiiii11ffLLLLff11ii;;ii11ffCCCCCCLLLL0000GGLLLLff11;;;;iiiiiiiiiiii11ttLLCCCCLLCC11iiiiiiffCCCCCCLLLL0000GGCCCCLL11;;;;;;ii;;iiii11ttffLLCCLLLLCCffii;;ii11CCCCCCLLLL00GGCCCCCCCCtt;;;;;;;;;;;;iittttLLLLLLLLLLCCCC11;;;;iiCCCCCCLLLLGGffLLCCCCCC11;;;;;;;;;;;;ttffffCCCCCCCCLLCCCCffii;;iiCCCCLLLLLLCCttffCCGGGG11;;1111iiii11LLLLLLCCCCLLLLLLCCGGCCttiiiiLLLLLLLLLLCCttttCCGGGGttiiffffLLffttttLLCCLLLLttttffffLLGGLLiiiiCCLLffffLLGGCCLLLLCCCCffttffffffffttttffLLLLffttttffffLLGGCCttttLLLLffffffGGGGGGGGGGLLLL1111fftttt11tttt11iifftttt1111ffffGGffffLLLLffffffGGGGGGGGGGLLLLtt11CCLLLLLLLLttCCLLffLLffLLLLLLffGGLLLLCCLLttttffGGGGGGGGGGCCLLffffLLGGGGCCLLffGGGGLLLLCCCCCCCCGGGGCCffCCffttttffCCCCCCCCGGGGLLLLLLCCCCLLffffCCGGGGCCLLLLCCCCGGGGGGCCLLLLttttttffCCCCCCCCGGGGCCLLLLCCCCLLffLLCCCCCCCCLLffCCCCCCGGGGCCCCffttttttttCCGGGGGGGGCCCCCCLLLLLLffLLLLttffffffLLffffLLCCCCGGCCCCffttttttttCCGGGGGGGGLLffLLLLLLffffLLLLLLLLLLLLCCLLffffLLCCGGCCCCffttttffffLLGGGGGGGGCCttttLLLLLLff11LLCCCCCCCCLLttffLLLLCCCCGGLLffffffffLLCCGGGGGGGGCCffttLLLLCCLLLLCCGGGGGGGGCCLLLLCCLLCCCCLLGGLLLLffLLffGGGGGGGGGGCCffffffLLLLCCCCCCCCCCCCCCCCCCCCCCLLCCCCLLCCGGffffffffGGGGGGGGGGGGffffttffLLCCCCCCCCCCCCCCCCCCCCLLLLLLCCCCLLGGff1111ttGGGGGGGGGGGGffttttLLffLLCCCCCCGGGGCCGGCCCCLLffffLLCCCCCCGG11ttffGGGGGGGGGGGGffttttLLffffLLCCCCCCCCCCCCCCLLLLttLLLLLLCCLLGGffffffGGGGCCGGGGGGffttttLLLLffttffLLLLLLLLLLLLffff11LLCCffGGLLffttttttCCGGCCCCCCCCffttttLLLLffffttttttttffffffffffttffGGffCCCCff11ttffLLGGCCCCCCCCLLttLLffLLLLffttttttffffffffffttttffCCffLLCCGGffffffLLGGGGCCGGGGLLttCCffLLffffffffffffffffffffttttffCCLLffLLCCLLLLff","CCCCCCCCCCCCGGGGGGLLii;;;;;;;;;;;;;;;;;;;;ii11CCGGGGCCCCCCCCCCCCCCCCCCCCCCCCGGCCff;;;;;;;;;;;;;;;;;;;;;;;;;;;;ffCCCCCCCCCCCCCCCCCCCCCCCCCCGGGGtt;;;;;;;;;;;;;;;;ii;;;;;;;;;;;;;;LLCCCCCCCCCCCCCCCCCCCCCCGGGGLLii;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;iiLLCCCCCCCCCCCCCCCCCCCCCCCC11;;;;;;ii;;;;;;;;;;;;;;;;;;;;iiiiiiii11CCCCCCCCCCCCCCCCCCCCCCffii;;;;iiiiiiiiiiiiii;;iiiiiiiiiiiiiiiiiiLLCCCCCCCCCCCCCCCCCCCCttii;;;;;;;;;;;;;;iiiittLLLLffff11;;ii11iiffCCCCCCCCCCCCCCCCCCCC11ii;;;;iiii111111ttLLGG00GGGGCCCCtt;;;;iittCCCCCCCCCCCCCCCCCCCCii;;;;ii11ttffLLLLCCGGGGGGGGCCCCCCLLttiiii11CCCCCCCCCCCCCCCCCCCCii;;;;iittffffLLLLCCCCGGGGCCCCCCCCLLttiiii11CCCCCCCCCCCCCCCCCCCCii;;;;iittffffLLCCCCGGGGGGGGGGCCCCLL11;;;;iiCCCCCCCCCCCCCCCCCCCCii;;;;iittffLLCCCCGGGGGGGGGGGGCCCCLLtt;;;;11CCCCCCLLCCCCCCCCCCCCii;;;;11ttLLLLLLLLLLCCCCCCCCCCCCLLLLtt;;;;ttCCCCCCLLLLCCCCLLCCCC11;;ii111111iiii11ttffLLtt11111111ttffii;;ffLLLLLLLLLLLLCCCCCCLLtt;;ii1111iiiiiiiiiittff11iiiiii11ttff1111LLLLLLLLLLLLLLCCCCCCttiiii111111iiii11iiiiLLGGff1111tt11ffLLttffttLLLLLLLLLLLLLLCCCCff11ii1111tt11ttttffffCCGGCCLLttttffCCCCttffLLLLLLCCLLLLLLLLCCLLLLttii11ttLLCCGGGGCCLLCC00GGGGGGGGGGGGCCttffCCLLLLLLLLLLLLLLLLLLLLffii11ttLLGGGGGGLLffGG00CCCCGGGGGGCCLLLLGGCCLLLLLLLLLLLLLLLLLLLLfftt11ttffCCGGGGLLLLCCGGCCCCCCGGCCCCffLLGGLLLLLLLLLLLLLLLLLLLLLLLLff11tt11ffLLCCff11tttt11LLCCLLCCLLffCCCCLLffLLLLLLLLLLLLLLLLLLLLLLffff11ttLLLL11iiiiiittCCGGCCLLffffLLLLLLffLLLLLLLLLLLLLLLLLLffLLLLffttttffff111111ffCCCCCCCCLLffffLLLLLLLLLLLLffLLLLLLLLLLLLffLLLLLLttttff11ii11ttttttttttLLffffLLLLLLLLLLLLLLffLLffffffLLLLLLLLLLLLffttttffttffLLLLLLCCCCLLffttLLLLffLLLLLLLLLLLLLLffLLLLffLLffLLLLffttttffffttttttffCCLLffttttLLLLLLffLLLLLLLLLLLLLLLLLLLLLLLLCCLLff11ttttLLLLCCCCCCCCLLffttffLLLLLLffffLLLLffffLLLLLLLLLLLLLLLLLLLL1111ttffffLLCCCCLLffttttffLLLLLLLLffffffLLffLLLLLLLLLLLLLLLLLLLL111111ttttffffffttttttffffLLLLLLffLLffffffffffffLLLLffLLLLLLLLCCtt1111111111ttttttttttffffttffLLffffLLffLLffffffLLLLffLLLLffLL111111111111111111ttttffLLfftt11CCffffLLffLLLLLLLLLLffLLLLLLLLffii1111111111111111ttttLLLLLLLLttCCCCLLffffffLL","GGGG0000GGGG000000GGGGGGCCCCff11iiii1111ffGGGGGGGGGGCCCCGGGGGGGGGGGGGGGG00GGGGGG00GGGGCC11iiii;;;;;;;;;;;;11LLGGGGGGGGGGCCCCCCCCGGGGGGGGGGGGGGGGGGGGffii;;;;;;;;;;;;;;;;;;;;iittGGGGGGGGGGCCCCCCGGGGGGGGGGGGGGGGGG11;;;;;;;;ii;;;;;;;;;;;;;;;;;;ttGGGGGGGGGGGGCCGGGGGGGGGGGGGGGGttiiiiiiiiiiiiiiiiiiiiiiii;;;;;;iiCCGGCCCCCCGGCCCCCCGGCCGGGGGGLLiiii11111111ttfffffffftttt11ii;;;;11GGCCCCCCGGCCCCCCCCCCCCGGGGffiittCCCCCCCCCCCCLLLLLLffffttttii;;iiGGGGGGCCGGCCCCCCGGGGGGGGGG11iiLLCCCCCCCCCCCCCCLLLLfffftttt11iiiiCCGGGGGGGGCCGGGG00GGGG00GG11ttCCCCGGGGGGGGGGCCCCLLLLfffftt11iiiiLLGGGGGGCCCCGGGGGGGG0000GG11ffCCGGGGGGGGGGGGCCCCLLLLffffttttiiiiLLGGGGGGGGCCCCGGGG0000000011LLGGGGGGGGGGGGGGCCLLLLfffftttttt11iiLLGGGGGGCCCCCC00GG000000GGttLLCCGGGGGGGGGGGGGGCCLLLLfffftttt11iiLLGGGGCCCCCCCC00GG00000000ffCCCCCCGGGGGGGGGGGGCCLLffffttttffttiiCCGGGGCCCCGGLLGGGG000000GGLLCCLLffffttffCCGGCCff11ii111111ffttiiffGGGGCCGGGGCCGGGG000000GGLLCCCCLLff11ffCCGGLL1111tt1111tttttt1111LLGGCCCCCCLLGGGG000000GGCCCCCCLLLLttLLCCGGff11ffff111111tttt1111LLGGCCCCCCCC0000000000GGCCCCGGGGCCLLCCCCCCff11fffffffftttttt1111LLGGCCCCCCLLGGGGGG000000GGCCGGGGGGGGGGCCGGffttffLLLLLLfftttt1111GGGGGGCCCCLLGGGGGG000000GGCCGGGGGGGGGGCCGGffttttLLLLLLffttttttttGGGGGGCCCCCCGGCCGG000000GGCCGGGGGGGGCCGGGGLLttttLLCCLLfftttt11ffGGGGCCCCCCLLGGGGGG000000GGCCGGGGGGCCCCLLCCtt1111ffLLffttttttLLCCGGGGCCCCGGCCGGGGGGGG0000GGCCCCGGCCCCCCCCLLffttttttfffftttttt00GGGGGGCCCCCCLLGGGG00GGGG00GGCCCCCCCCCCCCCCLLCCffttttffffttttttGGGGGGGGCCCCCCCCGGGGGGGGGGGGGGGGCCCCLLLLLLLLLLfftt11ttLLffttttffGGGGGGGGCCCCCCCCGGGG000000GGGGGGCCCCCCGGCCCCCCLLffttffLLttttttttLLGGGGGGCCCCCCCCGGGG000000GGGGGGGGCCCCCCGGCCLLfffffffftttttttttt11ffGGGGCCCCCCCCGGGG0000000000GGGGCCCCCCGGGGCCCCLLfffftttttt11tt1111CCGGCCCCCCCCGGGGGG0000000000GGGGLLCCGGGGCCCCLLfftttt11111111tt11ttCCCCCCCCCC0000000000000000GGGGCCLLCCCCCCLLfftttt1111111111111111ttLLCCCCLLGGGGGG00000000GGGGGGCCCCLLfffffftt111111111111tt111111ttttttLLLLGGGGGG00000000GGGGGGLLCCCCCCLLfffftt11111111tttt1111tttt11ttttLLGGGGGGGG0000GGCCLLCCffCCCCCCCCCCLLtttttttttttt1111tttttttttttt","1111111111tttttttttt11111111111111ii;;iiiiii1111111111ii;;;;iiii11111111tttttttttt1111ii111111ii11iiiiiiii111111tt111111iiii;;ii111111ttttttttttttiiii111111iiiiiiii11111111ii1111tt111111iiii;;111111tttttttt1111iiii11111111ii11111111111111111111111111iiii;;11111111tttttt11iiii11tt11ttttttffLLfffffffffftt11iiii111111iiii111111tttttttt11iiii1111ttLLLLLLLLCCCCCCCCLLLLLLtt11iiii1111iiii111111tttttttt11ii1111ttffLLLLCCCCCCCCCCCCCCCCLLLLttiiii11ttiiii1111111111tttt1111tt11ffLLCCCCCCCCCCGGGGGGCCCCLLLLff111111tt11iiiiiiiiii111111iittttttffLLCCCCCCCCGGGGGGGGCCCCCCLLfftt11111111iiiiiiiiiiii111111ttttffffLLCCCCCCCCCCGGGGGGGGCCCCLLfftt111111iiiiiiiiiiiiii111111ttttffLLLLCCCCCCCCGGGGGGGGCCCCCCLLfftt111111iiii11ii;;;;ii11iiii11ttffLLCCCCGGCCGGGGGGGGCCCCCCCCCCffttff1111iiiiLLttii;;ii11iiii11ttttffCCCCGGGGGGCCLLLLffLLLLLLLLLLttttttttiiiiCCLLffii;;iiiiiiii11ffLLffLLCCGGCCLLLLCCGGCCLLLLLLLLff11111111iiCCLLLL11;;;;ii;;iittffffffLLLLGGCCLLLLLLttffCCCCCCLLLL11ii1111iiCCLLLL11;;;;ii;;iiffffLLffCCLLCCCCLLLLCCLLLLCCCCCCLLLLtt11ttLL11CCLLffii;;;;;;;;iiLLLLCCCCLLLLCCCCCCCCCCGGGGCCCCCCLLLL11ttLLCC11LLffttii;;;;;;;;iiLLLLLLLLffCCCCCCGGGGCCCCCCGGGGCCLLff11ffGGLLiiffffffiiii;;;;;;iiLLLLLLCCLLCCCCCCGGGGCCGGGGCCCCCCLLff11LLCCLLiiffttff11ff;;;;;;iiffLLCCLLCCGGCCCCCCCCGGGGGGCCCCCCLLffttLLCCffiiLLffttttLL;;;;;;iiffCCCCLLffLLLLLLLLCCCCGGGGCCCCCCLLffffLLCC11;;LLffttLLff;;;;;;iiffCCCCffttLLCCLLCCCCCCGGGGCCCCCCLLffffLLffii;;LLffffLL11iiiiiiiiffCCLLffffLLLLCCCCLLCCCCCCCCCCCCLLffffLLii11ttLLttttiiiiiiiiiiiiffCCLLffffLLCCCCCCLLLLLLCCCCCCCCLLffffff11ttffffiiiiiiiiiiiiiiiittLLLLLLffLLLLLLLLLLLLLLCCCCCCCCLLffffff11ttffiiiiiiiiiiiiii11ff11ffLLLLffLLLLCCCCCCCCCCCCCCCCCCLLLLffffttffCCiiiiiiiiiiiittLLLLttffffLLLLLLLLCCCCCCCCLLCCCCCCLLLLLLffffttLLCCiiiiiiiittffLLLLLLLLttttLLLLLLCCCCCCCCCCLLCCCCCCLLLLLLffffLLCCCCiiii11ffLLLLLLLLLLLLttttffLLCCCCCCCCCCLLffLLCCCCLLLLffffffCCCCCCiittLLLLLLCCCCCCCCLLffttttffLLLLCCLLLLffLLCCLLLLLLffffffLLCCCCCCttLLLLLLCCCCCCCCCCCCLL11ffffffffLLffffLLCCLLLLffffttttLLCCCCCCCCffLLCCCCCCCCCCCCCCCCLL1111ffLLffffLLLLLLLLfftt1111ttLLLLCCCCCCCC","ffffffffLLLLLLLLCC000000GGCCLLLLLLLLLLLLGGGGGGCCCCCCGGCCLLLLLLCCffffffffLLLLLLCC0000GGffii11ffttffffffLLCCLLCCCCLLLLCCGGCCCCCCCCffffffffLLLLCCGG0000LL11ttffffffffffffffffffffffCCffLLGGGGCCCCCCffffffffLLLLCC00GGGGffLLCCGGGGCCCCCCCCCCCCLLffttffLLffCCGGCCCCCCffffffffLLLLGGGGGGCCCC00000000000000000000GGCCtt11ffffttGGGGCCCCffffffffLLCCGGGGCCGG008888880000000000000000GGLLttttttffCCGGCCCCffffffLLLLGGCCCCCCGG008800000000000000000000GGCCffttttttLLGGCCCCffffLLLLCCCCGGLLCC000000000000000000000000GGGGGGLLtt11ttLLCCCCCCffffLLLLCCGGCCLLGG0000GGGGGGGGGGGGGGGGGGGGGGGGGGCCtt11ttLLCCCCCCffLLLLLLCCCCLLttGG00GGGGGGGGGGGGGGGGGGGGGGGGGGGGCCffii11ffLLGGCCLLLLLLCCCCLLtt11CC00GGGGGGGGGGGGGGGGGGGGGGGGGGGGCCffiiiiffffCCCCLLLLCCCCCCff1111GG0000000000GGGGGGGGGGGGGGGGGGGGCCLL11ii11ffCCCCCCLLCCGGff11ii11GG00GGGGGGGGGGGGGGGGGGGGGGGGGGGGCCCC11iiiiffCCCCCCCCCCCCffiiiittGGGGCCLLffLLCCCCCCLLffffLLCCCCCCCCCCtt111111LLGGCCCCCCLL11;;iiLLGGLLtt1111ttLLGGCCfftt1111ttLLCCGGGGfftt1111ffCCCCGGGGLL11;;11CC00CCLLffttffCCGGCCffffffttffLLCCGGGGLLttttiittLLGGGGCCLL11iiiiCC0000GGLLLLLLGG00GGCCLLLLLLCCGGGGGGCCCCttffiittLLGGCCCCff11iiiiff000000GGGGGG0000GGGGGGGGGG0000GGGGCCLLLLtt11ttLLCCCCCCtt11iiiiffGG00000000000000GGGGGG000000GGGGCCCCCCCC1111ffLLCCCCLLttiiiiiiiiGGGGGGGGGGGG0000GGCCGGGGGGGGGGCCCCCCLLttii11ffLLCCCCLLttii11iiiiCCCCCCCCCCGG0000GGCCLLCCGGGGGGCCCCtt;;ii1111ffLLCCCCLLtt1111iiiiLLCCCCCCCCCCLLLLLLLLCCCCCCCCCCCCCCii;;ii11ttffLLCCCCfftt11ttiiiiffCCCCCCGGGGCCLLLLCCGGCCCCCCCCCCCC;;;;1111ttffLLCCCCfftttttt11iittCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCff;;ii1111ttffLLCCCCLLfftttt11iiiiCCCCCCCCLLLLffffffLLLLCCCCCCCC11;;ii111111ffLLCCCCLLffffff11ii;;LLCCCCGGCCLLLLLLCCCCCCCCCCCCLLii;;ii1111ttttLLCCCCLLLLfftt11iiiiCCCCCCGGGGCCCCCCCCCCCCCCLLLLLL;;;;ii1111ttttLLCCCCCCLLLLfftt11ttCCCCCCGGGGGGGGGGGGCCCCLLLLLLLL;;;;ii1111ttttLLCCCCLLff11ttffttCCGGCCLLCCCCCCCCCCCCCCLLffLLLLff;;;;ii111111ttLLLLLLff11ffGGCCffGGGGGGCCLLLLLLLLLLffffffLLLLLLtt;;;;ii111111ttLLfftttt11ffGGCCLLGGGGGGCCCCLLLLffffffLLLLLLLLLL11;;;;11111111ttLLfffftt1111CCCCCCCCGGGGCCCCCCLLLLLLLLLLCCLLLLLLtt;;;;ii1111ttffLL","tt111111fftttttt11iiiiii;;;;;;;;;;ii11ttffffffttiiii11tt11ii11ii1111iittffttttii;;;;;;;;ii;;;;;;;;;;;;;;ffffffff111111tttt11iiii111111ttffttii;;;;;;;;iiiiiiii;;;;;;;;;;iifffffftt1111111111iiii111111ffLLii;;;;;;iiiiiiiiiiiiiiiiii;;;;;;;;ffffff1111111111111111ii11fftt;;;;;;;;;;ii1111tttttt1111ii;;;;;;ttffLLtt1111111111ttiiii11ffii;;;;iiii11ttffLLLLLLLLLLfftt11ii;;iiffffttii11111111ttii11tttt;;;;ii11ttffLLLLLLCCCCCCLLLLffff11;;;;11ff11iiiiii111111;;ttLL11;;;;ii11ffLLLLCCCCCCCCCCCCLLLLfftt11;;iiffff1111iiii1111iiLLLLii;;ii11ttffLLLLCCGGGGGGGGCCLLLLfffftt;;iiffLLff11iiii1111iiLLLLii;;ii11ttLLLLCCCCCCGGGGGGCCLLLLLLffttii;;ttLLLLtt11iiii11iiLLff;;;;;;11ttLLLLCCCCCCGGGGCCCCCCLLLLfftt11;;ttLLffff11iiii11iittff;;;;;;11ffffLLLLCCGGGGGGGGGGGGCCLLLLtt11;;ttfffffftt11iiiiii11ff;;;;iittffffffttffttffCCGGGGCCLLtt1111ii;;ffffffffff11iiiiii11tt;;;;iiffffttffCCCCLLffLLCCCCLLffttffffttiifffffffffffffftt11tttt11;;iiffffLLLLttttttttffLLCCfftttt1111ttiiffffffffffffffffttttffff;;iiffffLLttttttffffffLLCCffLLtttt11tt11ffffffffffffffffttttffLL1111ffLLLLLLLLLLLLLLLLLLLLffffLLffffffttffffffffffffffffttffffCCLLttffffLLCCCCLLLLCCLLLLLLffffLLLLLLffttffffffffffffffffttffffLLLLttttffLLCCCCCCCCCCLLLLLLLLffLLLLLLffttffffffffffffffffttffLLffLLttttffLLCCGGGGCCLLffLLCCCCffLLLLLLffttffffffffffffffffttffLLffLLffttffLLCCCCCCLLLLffLLLLCCttffLLLLffttffffffffffffffffttffLLLLffLLttffffLLLLLLLLCCLLLLffttffffffffttttffffffffffffttffttttLLLLff11ttffffffffLLLLLLLLCCLLLLffttfffftt11ffffffffffttffffttttLLLLff11ttttffLLLLffffLLLLLLLLLLff11ffff1111fffffffffffffffftttttttttt11ttttffffLLLLffffLLCCGGLLttttLLttiiiiffffffffffffffff11111111iiiittttffLLLLLLLLffffLLLLffttttff11;;11ffffffffffffffff11111111iiiittttttffLLLLLLLLLLffffffffffttii;;11ffffffffffffffff11tt1111ii;;11ffttttffLLLLLLCCLLLLLLffff11;;11ttttfffffffffffffftttt11111111ttffffttttffLLCCCCCCCCLLfftt11iittttttttttffffffffffttttttttttttttfffffftt11ffLLLLCCLLLLffiittffttttttttLLttffttttttttttttffffffttfffffffffftt11ttfffftt1111ttLLffttttffCCLLffffttttttttffffffffttttfffffffffftttt1111ii11ttffffCCffttLLCCfffffftttt"];

        return asciiChars[id];
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

