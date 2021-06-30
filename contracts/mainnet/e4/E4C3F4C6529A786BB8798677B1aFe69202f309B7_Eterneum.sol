/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// contracts/CollectionItem.sol
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

contract Eterneum is Ownable {
    /**
    *   @dev Contract Properties
    */
    string private _name;   // Token name
    string private _symbol; // Token symbol
    uint private _price;    // Token Payable price
    uint256[] private _allTokens;    // Array with all token ids, used for enumeration
    mapping (uint256 => address) private _owners;       // Mapping from token ID to owner address
    mapping (uint256 => string) private _tokenCIDs;     // Mapping from token ID to CID

     /**
     * @dev Initializes the contract properties by setting a `name`,  a `symbol` and a price to the token collection.
     */
    constructor (string memory name_, string memory symbol_, uint price_) {
        _name = name_;
        _symbol = symbol_;
        _price = price_;
    }

    /**
     * @dev Return contract properties
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
     function price() public view virtual returns (uint) {
        return _price;
    }

    /*
    *   @dev Change price
    */
    function changePrice(uint price_) public onlyOwner {
        _price = price_;
    }

    /**
     * @dev Initialize event and method for payable contract
     */
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
    *   @dev Tranfert amount from the contract
    */
    function withdraw(uint amount) public onlyOwner() {
        address payable owner_pay = payable(owner());
        owner_pay.transfer(amount);
    }
    
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens start existing when they are minted (`mint`),
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    /**
    *   @dev mint the tokenID
    */
    function mint(address to, uint256 tokenId, string memory tokenCid) external payable {
        require(to != address(0), "Mint to the zero address");
        require(!_exists(tokenId), "Token already minted");
        require(bytes(tokenCid).length > 0, "CID is empty");

        /* if not owner of contract, pay the price */
        if (owner() != _msgSender()) {
            require(msg.value == _price, "Value sent not match contract Price");
            address payable owner_pay = payable(owner());
            owner_pay.transfer(msg.value);
        }

        _owners[tokenId] = to;
        _tokenCIDs[tokenId] = tokenCid;
        _allTokens.push(tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    /**
    *   @dev change the tokenCid - only contract Owner
    */
    function cid(uint256 tokenId, string memory tokenCid) public onlyOwner {
        require(_exists(tokenId), "Token not already minted");
        require(bytes(tokenCid).length > 0, "CID is empty");
        _tokenCIDs[tokenId] = tokenCid;
    }


     /**
     * @dev Total number of tokens.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Return the tokenID associated with the index.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalSupply(), "Global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Return the CID associated with the tokenID.
     */
    function tokenCID(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "CID query for nonexistent token");
        return _tokenCIDs[tokenId];
    }
   
}