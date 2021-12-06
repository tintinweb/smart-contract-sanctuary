/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

// File: openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/DAONFT.sol

pragma solidity ^0.5.16;


/**
 * @title Custom NFT contract based off ERC721 but restricted by access control.
 * @dev made for https://sips.synthetix.io/sips/sip-93
 */
contract DAONFT is Ownable {
    // Event that is emitted when a new token is minted
    event Mint(uint256 indexed tokenId, address to);
    // Event that is emitted when an existing token is burned
    event Burn(uint256 indexed tokenId);
    // Event that is emitted when an existing token is Transferred
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // Event that is emitted when an existing token uri is altered
    event TokenURISet(uint256 tokenId, string tokenURI);

    // Array of token ids
    uint256[] public tokens;
    // Map between an owner and their tokens
    mapping(address => uint256) public tokenOwned;
    // Maps a token to the owner address
    mapping(uint256 => address) public ownerOf;
    // Optional mapping for token URIs
    mapping(uint256 => string) private tokenURIs;
    // Token name
    string public name;
    // Token symbol
    string public symbol;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     * @param _name the name of the token
     * @param _symbol the symbol of the token
     */
    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev Modifier to check that an address is not the "0" address
     * @param to address the address to check
     */
    modifier isValidAddress(address to) {
        require(to != address(0), "Method called with the zero address");
        _;
    }

    /**
     * @dev Function to retrieve whether an address owns a token
     * @param owner address the address to check the balance of
     */
    function balanceOf(address owner) public view isValidAddress(owner) returns (uint256) {
        return tokenOwned[owner] > 0 ? 1 : 0;
    }

    /**
     * @dev Transfer function to assign a token to another address
     * Reverts if the address already owns a token
     * @param from address the address that currently owns the token
     * @param to address the address to assign the token to
     * @param tokenId uint256 ID of the token to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public isValidAddress(to) isValidAddress(from) onlyOwner {
        require(tokenOwned[to] == 0, "Destination address already owns a token");
        require(ownerOf[tokenId] == from, "From address does not own token");

        tokenOwned[from] = 0;
        tokenOwned[to] = tokenId;

        ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Mint function to mint a new token given a tokenId and assign it to an address
     * Reverts if the tokenId is 0 or the token already exist
     * @param to address the address to assign the token to
     * @param tokenId uint256 ID of the token to mint
     */
    function mint(address to, uint256 tokenId) public onlyOwner isValidAddress(to) {
        _mint(to, tokenId);
    }

    /**
     * @dev Mint function to mint a new token given a tokenId and assign it to an address
     * Reverts if the tokenId is 0 or the token already exist
     * @param to address the address to assign the token to
     * @param tokenId uint256 ID of the token to mint
     */
    function mintWithTokenURI(
        address to,
        uint256 tokenId,
        string memory uri
    ) public onlyOwner isValidAddress(to) {
        require(bytes(uri).length > 0, "URI must be supplied");

        _mint(to, tokenId);

        tokenURIs[tokenId] = uri;
        emit TokenURISet(tokenId, uri);
    }

    function _mint(address to, uint256 tokenId) private {
        require(tokenOwned[to] == 0, "Destination address already owns a token");
        require(ownerOf[tokenId] == address(0), "ERC721: token already minted");
        require(tokenId != 0, "Token ID must be greater than 0");

        tokens.push(tokenId);
        tokenOwned[to] = tokenId;
        ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
        emit Mint(tokenId, to);
    }

    /**
     * @dev Burn function to remove a given tokenId
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to burn
     */
    function burn(uint256 tokenId) public onlyOwner {
        address previousOwner = ownerOf[tokenId];
        require(previousOwner != address(0), "ERC721: token does not exist");

        delete tokenOwned[previousOwner];
        delete ownerOf[tokenId];

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                break;
            }
        }

        tokens.pop();

        if (bytes(tokenURIs[tokenId]).length != 0) {
            delete tokenURIs[tokenId];
        }

        emit Burn(tokenId);
    }

    /**
     * @dev Function to get the total supply of tokens currently available
     */
    function totalSupply() public view returns (uint256) {
        return tokens.length;
    }

    /**
     * @dev Function to get the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to retrieve the uri for
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(ownerOf[tokenId] != address(0), "ERC721: token does not exist");
        string memory _tokenURI = tokenURIs[tokenId];
        return _tokenURI;
    }

    /**
     * @dev Function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        require(ownerOf[tokenId] != address(0), "ERC721: token does not exist");
        tokenURIs[tokenId] = uri;
        emit TokenURISet(tokenId, uri);
    }
}