/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: IBadge

interface IBadge {
    struct Token {
        uint32 id;
        uint256 timestamp;
    }

    /**
     * @dev Emitted when a token is minted to `to` with an id of `tokenId`.
     * @param to The address that received the token
     * @param tokenId The id of the token that was minted
     * @param timestamp Block timestamp from when the token was minted
     */
    event Minted(address indexed to, uint32 indexed tokenId, uint256 timestamp);

    /**
     * @dev Emitted when a token is updated with a new timestamp.
     * @param owner The address that owns the token
     * @param tokenId The id of the token
     * @param timestamp Block timestamp from when the token was "re-issued"
     */
    event Updated(
        address indexed owner,
        uint32 indexed tokenId,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a token is burned.
     * @param owner The address that used to own the token
     * @param tokenId The id of the token that was burned
     * @param timestamp Block timestamp from when the token was burned
     */
    event Burned(
        address indexed owner,
        uint32 indexed tokenId,
        uint256 timestamp
    );

    /**
     * @dev Returns the badge's name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the badge's symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for the badge.
     */
    function URI() external view returns (string memory);

    /**
     * @dev Returns the token owned by `owner`, if they own one, and an empty Token otherwise
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     */
    function tokenOf(address owner) external view returns (Token memory);

    /**
     * @dev Returns the owner of the token with given `tokenId`.
     *
     * Requirements:
     *
     * - A token with `tokenId` must exist.
     */
    function ownerOf(uint32 tokenId) external view returns (address);
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: Badge

contract Badge is IBadge {
    // Badge's name
    string private _name;

    // Badge's symbol
    string private _symbol;

    // Badge's URI
    string private _URI;

    // Mapping from token ID to owner's address
    mapping(uint32 => address) private _owners;

    // Mapping from owner's address to Token
    mapping(address => Token) private _tokens;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // Returns the badge's name
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // Returns the badge's symbol
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // Returns the badge's URI
    function URI() public view virtual override returns (string memory) {
        return _URI;
    }

    // Returns the token owned by `owner`, if it exists, and an empty Token otherwise
    function tokenOf(address owner)
        public
        view
        virtual
        override
        returns (Token memory)
    {
        require(owner != address(0), "Invalid owner at zero address");

        return _tokens[owner];
    }

    // Returns the owner of a given token ID, reverts if the token does not exist
    function ownerOf(uint32 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(tokenId != 0, "Invalid tokenId value");

        address owner = _owners[tokenId];

        require(owner != address(0), "Invalid owner at zero address");

        return owner;
    }

    // Sets a new badge URI
    function _setURI(string memory newURI) internal virtual {
        _URI = newURI;
    }

    // Checks if a token ID exists
    function _exists(uint32 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Minted} event.
     */
    function _mint(address to, uint32 tokenId) internal virtual {
        require(to != address(0), "Invalid owner at zero address");
        require(!_exists(tokenId), "Token already minted");
        require(tokenOf(to).id == 0, "Owner already has a token");
        require(tokenId != 0, "Token ID can't be zero");

        Token memory newToken;
        newToken.id = tokenId;
        newToken.timestamp = block.timestamp;

        _tokens[to] = newToken;
        _owners[tokenId] = to;

        emit Minted(to, tokenId, block.timestamp);
    }

    /**
     * @dev Updates the token's timestamp owned by `owner`
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `owner` must have a token.
     *
     * Emits a {Updated} event.
     */
    function _updateTimestamp(address owner) internal virtual {
        require(owner != address(0), "Invalid owner at zero address");
        require(tokenOf(owner).id != 0, "Owner does not have a token");

        Token storage token = _tokens[owner];
        token.timestamp = block.timestamp;

        emit Updated(owner, token.id, token.timestamp);
    }

    /**
     * @dev Burns `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Burned} event.
     */
    function _burn(uint32 tokenId) internal virtual {
        address owner = Badge.ownerOf(tokenId);

        delete _tokens[owner];
        delete _owners[tokenId];

        emit Burned(owner, tokenId, block.timestamp);
    }
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: BadgeToken.sol

contract BadgeToken is Badge, Ownable {
    struct TokenParameters {
        address owner;
        uint32 tokenId;
    }

    constructor(string memory badgeName_, string memory badgeSymbol_)
        Badge(badgeName_, badgeSymbol_)
    {}

    function exists(uint32 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function mint(address to, uint32 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function batchMint(TokenParameters[] memory tokensToMint)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokensToMint.length; i++) {
            _mint(tokensToMint[i].owner, tokensToMint[i].tokenId);
        }
    }

    function burn(uint32 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}