/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}

/**
 * @title Context
 */
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
/**
 * @title Ownable
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
/**
 * @title ERC721
 */
contract ERC721 is Context {
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;
    // Mapping from tokenID to tokenURI
    mapping (uint256 => string) private _tokenURIs;
    // Emitted when `tokenId` token is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;
    }
    /**
     * @dev {ERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0), "ERC721: owner query for nonexistent token");
        return tokenOwner;
    }
    /**
     * @dev {ERC721-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }
    /**
     * @dev {ERC721-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    /**
     * @dev {ERC721-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return toString(tokenId);
    }
    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    /**
     * @dev Returns whether `tokenId` exists.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
    /**
     * @dev Destroys `tokenId`.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        delete _owners[tokenId];

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        emit Transfer(owner, address(0), tokenId);
    }
    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    /**
    * @dev Converts a `uint256` to its ASCII `string` decimal representation.
    * Inspired by OraclizeAPI's implementation - MIT licence
    * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    */
    function toString(uint256 value) internal pure returns (string memory) {
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
/**
 * @title ERC721
 */
contract ZoFactory is Ownable, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _baseTokenURI;
    string private _baseContractURI;
    uint256 private _totalSupplyLimit;
    uint256 _baseBurningFee = 1 ether;

    struct Zombie {
        uint256 id;
        string name;
        uint256 burningFee;
    }

    Zombie[] private zombies;
    mapping (uint256 => Zombie) private tokenToZombie;
    mapping (uint256 => uint256) private tokenToBurnFee;

    constructor(string memory _tokenURI, string memory _contractURI, uint256 _supplyLimit) ERC721("NFTZombieFinal", "ZOMB") {
        _baseTokenURI = _tokenURI;
        _baseContractURI = _contractURI;
        _totalSupplyLimit = _supplyLimit;
    }

    modifier burnable(uint256 _tokenId) {
        require(msg.value >= tokenToBurnFee[_tokenId], "ZoFactory: Burn`s fee not allowed");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI();
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return _baseContractURI;
    }

    function totalSupply() public view returns (uint256) {
        return zombies.length;
    }

    function totalSupplyLimit() public view returns (uint256) {
        return _totalSupplyLimit;
    }

    function createZombie(
        string memory name,
        uint256 burningFee
    ) public onlyOwner returns (Zombie memory) {
        require(totalSupply() < _totalSupplyLimit, "ZoFactory: total supply limit reached.");

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        Zombie memory newZombie = Zombie(newItemId, name, burningFee);

        zombies.push(newZombie);
        tokenToZombie[newItemId] = newZombie;
        tokenToBurnFee[newItemId] = burningFee * _baseBurningFee;

        _mint(owner(), newItemId);
        _setTokenURI(newItemId, toString(newItemId));

        return newZombie;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    function setbaseContractURI(string memory uri) public onlyOwner {
        _baseContractURI = uri;
    }

    function tokenData(uint256 _tokenId) public view returns (Zombie memory) {
        require(_exists(_tokenId), "ZoFactory: URI query for nonexistent token");
        Zombie memory data = tokenToZombie[_tokenId];

        return data;
    }

    function transferToken(address to, uint256 tokenId) public returns (uint256) {
        _transfer(owner(), to, tokenId);
        return tokenId;
    }

    function destroyToken(uint256 _tokenId) public payable burnable(_tokenId) returns (uint256) {
        _burn(_tokenId);
        return _tokenId;
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        address payable recipient = payable(owner());

        if (amount <= balance) {
            recipient.transfer(amount);
        } else {
            recipient.transfer(balance);
        }
    }
}