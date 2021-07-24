pragma solidity ^0.5.16;

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


/**
 * @title Custom NFT contract based off ERC721 but restricted by access control.
 * @dev made for https://sips.synthetix.io/sips/sip-93
 */
contract ThalesCouncil is Ownable {
    // Event that is emitted when a new SpartanCouncil token is minted
    event Mint(uint256 indexed tokenId, address to);
    // Event that is emitted when an existing SpartanCouncil token is burned
    event Burn(uint256 indexed tokenId);
    // Event that is emitted when an existing SpartanCouncil token is transfer
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // Event that is emitted when an metadata is added
    event MetadataChanged(uint256 tokenId, string tokenURI);

    // Array of token ids
    uint256[] public tokens;
    // Map between a owner and their token
    mapping(address => uint256) public tokenOwned;
    // Maps a token to the owner address
    mapping(uint256 => address) public tokenOwner;
    // Optional mapping for token URIs
    mapping(uint256 => string) public tokenURIs;
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
        if (tokenOwned[owner] > 0) {
            return 1;
        } else {
            return 0;
        }
    }

    /**
     * @dev Function to check the owner of a token
     * @param tokenId uint256 ID of the token to retrieve the owner for
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return tokenOwner[tokenId];
    }

    /**
     * @dev Transfer function to assign a token to another address
     * Reverts if the address already owns a token
     * @param from address the address that currently owns the token
     * @param to address the address to assign the token to
     * @param tokenId uint256 ID of the token to transfer
     */
    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) public isValidAddress(to) onlyOwner {
        require(tokenOwned[to] == 0, "Destination address already owns a token");

        tokenOwned[from] = 0;
        tokenOwned[to] = tokenId;

        tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Mint function to mint a new token given a tokenId and assign it to an address
     * Reverts if the tokenId is 0 or the token already exist
     * @param to address the address to assign the token to
     * @param tokenId uint256 ID of the token to mint
     */
    function mint(address to, uint256 tokenId) public onlyOwner isValidAddress(to) {
        require(tokenId != 0, "Token ID must be greater than 0");
        require(tokenOwner[tokenId] == address(0), "ERC721: token already minted");

        tokens.push(tokenId);
        tokenOwned[to] = tokenId;
        tokenOwner[tokenId] = to;

        emit Mint(tokenId, to);
    }

    /**
     * @dev Burn function to remove a given tokenId
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to burn
     */
    function burn(uint256 tokenId) public onlyOwner {
        require(tokenOwner[tokenId] != address(0), "ERC721: token does not exist");

        address previousOwner = tokenOwner[tokenId];

        tokenOwned[previousOwner] = 0;
        tokenOwner[tokenId] = address(0);

        uint256 lastElement = tokens[tokens.length - 1];

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = lastElement;
            }
        }

        tokens.pop;

        // Clear metadata (if any)
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
        require(tokenOwner[tokenId] != address(0), "ERC721: token does not exist");
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
        require(tokenOwner[tokenId] != address(0), "ERC721: token does not exist");
        tokenURIs[tokenId] = uri;
        emit MetadataChanged(tokenId, uri);
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}