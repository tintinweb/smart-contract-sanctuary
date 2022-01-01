// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol),
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        delete getApproved[id];

        ownerOf[id] = to;

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


    /*///////////////////////////////////////////////////////////////
                            ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

    function transfer(address to, uint256 tokenId) public virtual returns (bool success) {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");

        // Cannot overflow because because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[msg.sender]--;

            balanceOf[to]++;
        }

        delete getApproved[tokenId];

        ownerOf[tokenId] = to;

        emit Transfer(msg.sender, to, tokenId);

        success = true;
    }


    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            totalSupply++;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            totalSupply--;

            balanceOf[owner]--;
        }

        delete ownerOf[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ownerOf[tokenId] != address(0);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.10;

//  ██████▒▓██   ██▓ ██░ ██  ▄████▄
// ▓██   ▒  ▒██  ██▒▓██░ ██▒▒██▀ ▀█
// ▒████ ░   ▒██ ██░▒██▀▀██░▒▓█    ▄
// ░▓█▒  ░   ░ ▐██▓░░▓█ ░██ ▒▓▓▄ ▄██▒
// ░▒█░      ░ ██▒▓░░▓█▒░██▓▒ ▓███▀ ░
//  ▒ ░       ██▒▒▒  ▒ ░░▒░▒░ ░▒ ▒  ░
//  ░       ▓██ ░▒░  ▒ ░▒░ ░  ░  ▒
//  ░ ░     ▒ ▒ ░░   ░  ░░ ░░
//          ░ ░      ░  ░  ░░ ░
//          ░ ░             ░

import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

error SoldOut();
error SaleClosed();
error WalletLimitReached(uint256 limit);
error InvalidPriceSentForAmount(uint256 sent, uint256 required);
error MintingTooMany();
error NotWhitelisted();
error NotAuthorized();
error TokenDoesNotExist(uint256 tokenId);

contract FineYachtsHarbourClub is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    address private passwordSigner;
    address private ownerAddress;

    bool publicSaleActive;

    string public baseURI;

    uint256 constant PRESALE_MAX_TX = 2;
    uint256 constant PUBLIC_MAX_TX = 5;
    uint256 constant public MAX_SUPPLY = 10000;
    uint256 constant PRICE = 0.088 ether;

    mapping (address => uint256) private presaleMintsPerWallet;
    mapping (address => uint256) private mintsPerWallet;

    mapping (uint256 => string) private tokenNames;

    constructor(string memory _baseURI, address _passwordSigner) ERC721("Fine Yachts Harbour Club", "FYHC"){
        baseURI = _baseURI;
        passwordSigner = _passwordSigner;
    }

    function setPublicSale(bool publicSale) public onlyOwner {
        publicSaleActive = publicSale;
    }

    function setOwnerAddress(address _ownerAddress) public onlyOwner {
        ownerAddress = _ownerAddress;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setPasswordSigner(address signer) public onlyOwner {
        passwordSigner = signer;
    }

    function setTokenName(uint256 id, string memory name) public {
        if (!_exists(id)) revert TokenDoesNotExist(id);
        if (msg.sender != ownerOf[id]) revert NotAuthorized();

        tokenNames[id] = name;
    }

    function tokenName(uint256 id) public view virtual returns (string memory) {
        return tokenNames[id];
    }

    function mint(uint256 amount) public payable {
        if(!publicSaleActive) revert SaleClosed();
        if(totalSupply + amount > MAX_SUPPLY) revert SoldOut();
        if(mintsPerWallet[msg.sender] + amount > PUBLIC_MAX_TX) revert WalletLimitReached(PUBLIC_MAX_TX);
        if(msg.value < PRICE * amount) revert InvalidPriceSentForAmount(msg.value, PRICE * amount);

        for(uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply);
        }
        mintsPerWallet[msg.sender] += amount;
    }

    function presaleMint(uint256 amount, bytes memory signature) public payable {
        //console.log("isWhitelisted: %s", isWhitelisted(msg.sender, signature));

        if(publicSaleActive) revert SaleClosed();
        if(totalSupply + amount > MAX_SUPPLY) revert SoldOut();
        if(!isWhitelisted(msg.sender, signature)) revert NotWhitelisted();
        if(presaleMintsPerWallet[msg.sender] + amount > PRESALE_MAX_TX) revert WalletLimitReached(PRESALE_MAX_TX);
        if(msg.value < PRICE * amount) revert InvalidPriceSentForAmount(msg.value, PRICE * amount);

        for(uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply);
        }
        presaleMintsPerWallet[msg.sender] += amount;
    }

    // Mints tokens as an airdrop. Function used to mint founders reserve and promotional giveaways.
    function gift(address[] calldata toAddresses, uint256 amount) public onlyOwner {
        uint256 len = toAddresses.length;
        for(uint256 i = 0; i < len; i++) {
            for(uint256 j = 0; j < amount; j++) {
                if(totalSupply + j > MAX_SUPPLY) revert SoldOut();
                _mint(toAddresses[i], totalSupply + j);
            }
        }
    }

    function withdraw(address payable recipient) external onlyOwner {
        recipient.transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function isWhitelisted(address user, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encode(user));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == passwordSigner;
    }

    function getEthSignedMessageHash(bytes32 _messageHash) private pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function recoverSignerTest(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "sig invalid");

        assembly {
        /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function burn(uint tokenId) public {
        if(msg.sender != ownerAddress) revert NotAuthorized();
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
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