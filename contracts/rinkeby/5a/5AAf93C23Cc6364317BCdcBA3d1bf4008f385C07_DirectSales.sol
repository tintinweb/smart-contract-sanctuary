// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./derived/OwnableClone.sol";
import "./ISaleable.sol";

contract DirectSales is OwnableClone {
    
    struct Listing {
        address tokenAddress;
        uint256 offeringId;
        uint256 price;
    }

    mapping(uint256 => Listing) public listingsById;
    uint256 internal nextListingId;
    string public name;

    event ListingPurchased( uint256 indexed listingId );
    event ListingAdded(uint256 indexed listingId, address tokenAddress, uint256 offeringId, uint256 price);
    event ListingUpdated(uint256 indexed listingsById, uint256 price);
    event ListingRemoved(uint256 indexed listingId);

 	constructor(string memory _name, address _owner) {
        _init(_name, _owner);
    }

    function _init(string memory _name, address _owner) internal {
        name = _name;
        nextListingId = 0;
        transferOwnership(_owner);
    }

    function init(string memory _name, address _owner) public {
        require(owner() == address(0), "already initialized");
        OwnableClone.init(msg.sender);
        _init(_name, _owner);
    }

    function purchase(uint256 listingId, address _recipient) public payable {
        Listing memory listing = listingsById[listingId];

        require(listingsById[listingId].tokenAddress != address(0), "No such listing");
    	require(msg.value == listing.price);
        ISaleable(listing.tokenAddress).processSale(listing.offeringId, _recipient);

        emit ListingPurchased(listingId);
	}

    function addListing(address tokenAddress, uint256 offeringId, uint256 price) public onlyOwner {
        uint256 idx = nextListingId++;
        listingsById[idx].tokenAddress = tokenAddress;
        listingsById[idx].offeringId = offeringId;
        listingsById[idx].price = price;

        emit ListingAdded(idx, tokenAddress, offeringId, price);
    }

    function updateListing(uint256 listingId, uint256 price ) public onlyOwner {
        require(listingsById[listingId].tokenAddress != address(0), "No such listing");
        listingsById[listingId].price = price;

        emit ListingUpdated(listingId, price);
    }

    function removeListing(uint256 listingId) public onlyOwner {
        delete(listingsById[listingId]);
        
        emit ListingRemoved(listingId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISaleable.sol";

interface ISaleable {
    function processSale( uint256 offeringId, address buyer ) external;
    function getSellersFor( uint256 offeringId ) external view returns ( address [] memory sellers);
 
    event SaleProcessed(address indexed seller, uint256 indexed offeringId, address buyer);
    event SellerAdded(address indexed seller, uint256 indexed offeringId);
    event SellerRemoved(address indexed seller, uint256 indexed offeringId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
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
abstract contract OwnableClone is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function init ( address initialOwner ) internal {
        require(_owner == address(0), "Contract is already initialized");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        init(msgSender);
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
        require(owner() == _msgSender(), "OwnableClone: caller is not the owner");
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

// SPDX-License-Identifier: MIT

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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