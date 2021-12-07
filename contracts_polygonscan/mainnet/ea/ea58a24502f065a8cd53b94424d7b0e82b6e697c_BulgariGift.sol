/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/IERC1238.sol

// SPDX-License-Identifier: BSD 3-Clause OR MIT
pragma solidity 0.8.4;

interface IERC1238 {
    // @dev Emitted when `tokenId` token is minted to `to`, an address.
    event Minted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 timestamp
    );

    // @dev Emitted when `tokenId` token is burned.
    event Burned(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 timestamp
    );

    // @dev Returns the badge's name
    function name() external view returns (string memory);

    // @dev Returns the badge's symbol.
    function symbol() external view returns (string memory);

    // @dev Returns the ID of the token owned by `owner`, if it owns one, and 0 otherwise
    function tokenOf(address owner) external view returns (uint256);

    // @dev Returns the owner of the `tokenId` token.
    function ownerOf(uint256 tokenId) external view returns (address);
}


// File contracts/ERC1238.sol

pragma solidity 0.8.4;

contract ERC1238 is IERC1238 {
    // Badge's name
    string private _name;

    // Badge's symbol
    string private _symbol;

    // Mapping from token ID to owner's address
    mapping(uint256 => address) private _owners;

    // Mapping from owner's address to token ID
    mapping(address => uint256) private _tokens;

    // Mapping from token ID to token URI
    mapping(uint256 => string) private _tokenURIs;

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

    // Returns the token ID owned by `owner`, if it exists, and 0 otherwise
    function tokenOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(owner != address(0), 'Invalid owner at zero address');

        return _tokens[owner];
    }

    // Returns the owner of a given token ID, reverts if token does not exist
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(tokenId != 0, 'Invalid tokenId value');

        address owner = _owners[tokenId];

        require(owner != address(0), 'Invalid owner at zero address');

        return owner;
    }

    // Returns token URI of a given tokenID, reverts if token does not exist
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(_exists(tokenId), 'URI query for nonexistent token');

        return _tokenURIs[tokenId];
    }

    // Checks if a token ID exists
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // @dev Mints `tokenId` and transfers it to `to`.
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), 'Invalid owner at zero address');
        require(tokenId != 0, 'Token ID cannot be zero');
        require(!_exists(tokenId), 'Token already minted');
        require(tokenOf(to) == 0, 'Owner already has a token');

        _tokens[to] = tokenId;
        _owners[tokenId] = to;

        emit Minted(to, tokenId, block.timestamp);
    }

    // Sets token URI for a given token ID, reverts if token does not exist
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(_exists(tokenId), 'URI set of nonexistent token');
        _tokenURIs[tokenId] = _tokenURI;
    }

    // @dev Burns `tokenId`.
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC1238.ownerOf(tokenId);

        delete _tokens[owner];
        delete _owners[tokenId];

        emit Burned(owner, tokenId, block.timestamp);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/BulgariGift.sol

pragma solidity 0.8.4;


/**
    @title Bulgari Christmas Gift
    @author Maxim Gaina
    @notice 
        Mints Limited Edition of a Digital Artwork as Non-Transferable
        NFTs that represent gifts for guests invited to a physical event.
        The number of minted tokens can be less than Edition Limit
        (i.e. NFT claiming guests can be less than the invited) 
    @dev No more than a single token can be minted per each guest
 */
contract BulgariGift is ERC1238, Ownable {
    using Counters for Counters.Counter;

    /// @notice Used as token ID
    /// @dev Starts from 1, since 0 can also mean that no token has been minted
    Counters.Counter private _giftCounter;

    /// @notice Maximum number of NFTs
    uint256 private _editionLimit;

    /// @notice For locking in case there are less than `_editionLimit` guests
    bool private _editionEnded;

    constructor(
        string memory tokenName_,
        string memory tokenSymbol_,
        uint256 invitedGuests_
    ) ERC1238(tokenName_, tokenSymbol_) {
        _editionLimit = invitedGuests_;
        _editionEnded = false;
    }

    /// @return Number of minted tokens
    function mintedTokens() public view returns (uint256) {
        return _giftCounter.current();
    }

    /// @return Limit for this token edition
    function editionLimit() public view returns (uint256) {
        return _editionLimit;
    }

    /// @return `true` if minting is closed, `false` otherwise
    function editionEnded() public view returns (bool) {
        return _editionEnded;
    }

    /**
        @notice Contract owner mints token if edition is still open
        @param `_tokenURI` gift artwork identifier
        @param `to` guest address
        @return Number of minted tokens that is also token ID
     */
    function mintToken(address to, string memory tokenURI)
        public
        virtual
        onlyOwner
        returns (uint256)
    {
        require(_editionEnded == false, 'Gift Edition can no longer be minted');
        require(
            _giftCounter.current() < _editionLimit,
            'Maximum number of this Limited Edition has already been minted'
        );

        _giftCounter.increment();

        ERC1238._mint(to, _giftCounter.current());
        ERC1238._setTokenURI(_giftCounter.current(), tokenURI);

        return _giftCounter.current();
    }

    /**
        @notice End minting before edition limit is reached
        @dev Locks the contract forever
        @return `true` if minting is till open, reverts otherwise
     */
    function endEdition() public onlyOwner returns (bool) {
        require(_editionEnded == false, 'Edition has already ended');

        _editionEnded = true;

        return _editionEnded;
    }
}


// File contracts/flat_BulgariGift.sol