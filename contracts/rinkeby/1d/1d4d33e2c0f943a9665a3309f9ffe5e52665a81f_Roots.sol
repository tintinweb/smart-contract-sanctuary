//SPDX-License-Identifier: Unlicense
/// @title: Roots by Sam King
/// @author: Sam King (samking.eth)

pragma solidity ^0.8.0;

import {ERC721} from "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Roots is ERC721, Ownable {
    uint256 public price = 0.1 ether;
    string private _baseTokenURI;

    error IncorrectPaymentAmount();
    error InvalidTokenId();
    error NotAuthorized();
    error TransferFailed();

    constructor(string memory baseTokenURI) ERC721("Roots by Sam King", "ROOTS") {
        _baseTokenURI = baseTokenURI;
    }

    function mint(uint256 tokenId) public payable {
        if (tokenId == 0 || tokenId > 40) revert InvalidTokenId();
        if (price != msg.value) revert IncorrectPaymentAmount();
        _safeMint(msg.sender, tokenId);
    }

    function burn(uint256 tokenId) public {
        if (ownerOf[tokenId] != msg.sender) revert NotAuthorized();
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (ownerOf[tokenId] == address(0)) revert InvalidTokenId();
        return string(abi.encodePacked(_baseTokenURI, toString(tokenId)));
    }

    function updatePrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdrawAvailableBalance() public payable onlyOwner {
        uint256 bal = address(this).balance;
        (bool success, ) = msg.sender.call{value: bal}(new bytes(0));
        if (!success) revert TransferFailed();
    }

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Fork of Rari-Capital Solmate that reverts on `balanceOf` if passed zero address
///         https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol
/// @author samking.eth
abstract contract ERC721 {
    /**************************************************************************
     * STORAGE
     *************************************************************************/

    string public name;
    string public symbol;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public _balances;

    mapping(uint256 => address) public _tokenApprovals;
    mapping(address => mapping(address => bool)) public _operatorApprovals;

    /**************************************************************************
     * EVENTS
     *************************************************************************/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**************************************************************************
     * CONSTRUCTOR
     *************************************************************************/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /**************************************************************************
     * ERC721
     *************************************************************************/

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function approve(address approved, uint256 id) public virtual {
        address owner = ownerOf[id];
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "NOT_AUTHORIZED");
        _tokenApprovals[id] = approved;
        emit Approval(owner, approved, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public virtual returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function getApproved(uint256 tokenId) public virtual returns (address) {
        require(ownerOf[tokenId] != address(0), "NON_EXISTANT");
        return _tokenApprovals[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");
        require(
            msg.sender == from ||
                msg.sender == _tokenApprovals[id] ||
                _operatorApprovals[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balances[from]--;
            _balances[to]++;
        }

        ownerOf[id] = to;

        delete _tokenApprovals[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /**************************************************************************
     * ERC165
     *************************************************************************/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /**************************************************************************
     * INTERNAL MINT AND BURN
     *************************************************************************/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");
        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balances[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];
        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balances[owner]--;
        }

        delete ownerOf[id];
        delete _tokenApprovals[id];

        emit Transfer(owner, address(0), id);
    }

    /**************************************************************************
     * SAFE MINT
     *************************************************************************/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
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