// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// This is the main building block for smart contracts.
contract Registry is IERC721Receiver {
    // Some string type variables to identify the token.
    // The `public` modifier makes a variable readable from outside the contract.
    string public name = "NFTRegistry";
    address private _owner;

    struct NFT {
        address c;
        uint256 tokenId;
    }

    struct Wishlist {
        address owner;
        string data;
        string name;
    }

    // Mapping from owner to token
    mapping(address => NFT[]) _tokens;
    mapping(address => mapping(uint256 => address)) _owners;

    // A mapping is a key/value map. Here we store the wishlist for an address
    mapping(string => Wishlist) _wishlists; // list name to wishlist
    mapping(string => NFT[]) _wishlistCurrent; // current items
    mapping(address => string[]) _wishlistsByOwner; // owner to list names
    uint256 public createPrice;
    uint256 public updatePrice;
    bool public disabled;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        createPrice = 10000000000000000;
        updatePrice = 5000000000000000;
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    function setCreatePrice(uint256 price) onlyOwner external {
        createPrice = price;
    }

    function setUpdatePrice(uint256 price) onlyOwner external {
        updatePrice = price;
    }

    function setDisabled(bool d) onlyOwner public {
        disabled = d;
    }

     function withdraw() onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
     }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) public override returns (bytes4) {
        _tokens[from].push(NFT(msg.sender, tokenId));
        _owners[msg.sender][tokenId] = from;
        return this.onERC721Received.selector;
    }

    function updateWishlist(string memory listName, string memory displayName, string memory data) payable external {
        require (!disabled);
        address _currentOwner = _wishlists[listName].owner;
        require(_currentOwner == address(0) || _currentOwner == msg.sender);
        if (_currentOwner == address(0)) {
            require(msg.value >= createPrice);
            _wishlistsByOwner[msg.sender].push(listName);
        } else {
            require(msg.value >= updatePrice);
        }
        Wishlist memory w;
        w.owner = msg.sender;
        w.data = data;
        w.name = displayName;
        _wishlists[listName] = w;
    }

    // return wishlist data ipfs address
    function getWishlistWanted(string memory listName) external view returns (string memory) {
        return _wishlists[listName].data;
    }

    function getWishlistCurrent(string memory listName) external view returns (NFT[] memory) {
        return _wishlistCurrent[listName];
    }

    function transferOut(address account, address tokenContractAddress, uint256 tokenId) external {
        require(_owners[tokenContractAddress][tokenId] == msg.sender);
        IERC721 tokenContract = IERC721(tokenContractAddress);
        delete _owners[tokenContractAddress][tokenId];
        removeToken(tokenContractAddress, tokenId);
        tokenContract.safeTransferFrom(address(this), account, tokenId);
    }

    function claimAll() external {
        for (uint256 i = 0; i < _tokens[msg.sender].length; i++) {
            NFT memory token = _tokens[msg.sender][i];
            IERC721 tokenContract = IERC721(token.c);
            tokenContract.safeTransferFrom(address(this), msg.sender, token.tokenId);
            delete _owners[token.c][token.tokenId];
        }
        delete _tokens[msg.sender];
    }

    function transferToWishlist(string memory listName, address tokenContractAddress, uint256 tokenId) external {
        require(_owners[tokenContractAddress][tokenId] == msg.sender);
        delete _owners[tokenContractAddress][tokenId];
        _wishlistCurrent[listName].push(NFT(tokenContractAddress, tokenId));
        removeToken(tokenContractAddress, tokenId);
    }

    function removeToken(address tokenContractAddress, uint256 tokenId) private {
        uint256 index = _tokens[msg.sender].length;
        for (uint256 i = 0; i<_tokens[msg.sender].length; i++){
            if (_tokens[msg.sender][i].c == tokenContractAddress && _tokens[msg.sender][i].tokenId == tokenId) {
                index = i;
                break;
            }
        }

        if (index >= _tokens[msg.sender].length) {
            return;
        }
        _tokens[msg.sender][index] = _tokens[msg.sender][_tokens[msg.sender].length-1];
        _tokens[msg.sender].pop();
    }

    function claimFromWishlist(string memory listName) external {
        require(_wishlists[listName].owner == msg.sender);
        for (uint256 i=0; i < _wishlistCurrent[listName].length; i++) {
            NFT memory token = _wishlistCurrent[listName][i];
            IERC721 tokenContract = IERC721(token.c);
            tokenContract.safeTransferFrom(address(this), msg.sender, token.tokenId);
        }
        delete _wishlistCurrent[listName];
    }

    function getTokens() external view returns (NFT[] memory) {
        return _tokens[msg.sender];
    }

    function getWishlistOwner(string memory listName) external view returns (address) {
        return _wishlists[listName].owner;
    }

    function getWishlists() external view returns (string[] memory) {
        return _wishlistsByOwner[msg.sender];
    }

    function getWishlistName(string memory listName) external view returns (string memory) {
        return _wishlists[listName].name;
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