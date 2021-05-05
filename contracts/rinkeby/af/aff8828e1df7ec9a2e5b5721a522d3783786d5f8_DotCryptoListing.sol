/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

// File: contracts/1_DotCryptoListing.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface Registry {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;
    function ownerOf(uint256 _tokenId) external view returns (address);
    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        returns (bool);
}

/**
 * @title DotCryptoListing
 * @dev List .crypto domains for sale
 */
contract DotCryptoListing is Ownable {
    event PriceChanged(uint256 indexed tokenId, uint256 value);
    event Purchase(
        uint256 indexed tokenId,
        uint256 value,
        address indexed purchaser
    );
    Registry public registry;
    mapping(uint256 => uint256) internal _prices;
    // Double check fallback function
    constructor(Registry _registry) {
        registry = _registry;
    }
    function priceOf(uint256 tokenId) external view returns (uint256) {
        return
            registry.isApprovedOrOwner(address(this), tokenId)
                ? _prices[tokenId]
                : 0;
    }
    function setPrice(uint256 tokenId, uint256 price) external {
        require(
            registry.isApprovedOrOwner(msg.sender, tokenId),
            "sender must be approved or owner"
        );
        _prices[tokenId] = price;
        emit PriceChanged(tokenId, price);
    }
    function purchase(uint256 tokenId) external payable {
        require(_prices[tokenId] > 0, "domain must be listed");
        require(
            _prices[tokenId] == msg.value,
            "insufficiant funds for purchase"
        );
        delete _prices[tokenId];
        registry.transferFrom(registry.ownerOf(tokenId), msg.sender, tokenId);
        payable(owner()).transfer(msg.value);
        emit Purchase(tokenId, msg.value, msg.sender);
    }
}