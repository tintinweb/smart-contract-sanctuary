pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
  function ownerOf(uint) external view returns(address);
  function totalSupply() external view returns(uint);
  function getApproved(uint) external view returns(address);
  function isApprovedForAll(address,address) external view returns(bool);
  function transferFrom(address,address,uint) external ;
}

contract GhostMarketplace is Ownable {
  IERC721 public ghostsContract;
  bool private _Lock = false; // reentrancyGuard
  mapping(uint => uint) public priceOf;


  constructor() {
      ghostsContract = IERC721(0xb8442A7af10d202b0b27FBe34DD9fF0BE328b470);
  }

  event ListingUpdated( uint ghostID,address account, uint newPrice );
  event GhostPurchased(address indexed buyer,address indexed seller,uint indexed ghostId,uint price);

  modifier reentrancyGuard {
    require( !_Lock, "Reentrancy attack!");
    _Lock = true;
    _;
    _Lock = false;
  }
  modifier ownerOrApproved(uint tokenId) {
    address subject = msg.sender;
    require(
      subject==ghostsContract.ownerOf(tokenId) ||
      subject==ghostsContract.getApproved(tokenId) ||
      ghostsContract.isApprovedForAll(ghostsContract.ownerOf(tokenId),subject)
    ,"neither owner nor approved");
    _;
  }
  modifier ghostOnSale(uint ghostID) {
    require(priceOf[ghostID]!=0,"This Ghost is not on sale");
    _;
  }

  function getAllGhostsOnSale() public view returns(uint[] memory){
    uint totalSupply = ghostsContract.totalSupply();
    uint ghostsOnSale;
    for (uint i = 0;i<totalSupply;i++) {
      if (isListed(i)) {
        ghostsOnSale++;
      }
    }
    uint[] memory ghosts = new uint[](ghostsOnSale);
    uint counter;
    for (uint i = 0;i<totalSupply;i++) {
      if (isListed(i)) {
        ghosts[counter] = i;
        counter++;
      }
    }
    return ghosts;
  }
  function getAmountOfListings() public view returns(uint){
    uint totalSupply = ghostsContract.totalSupply();
    uint ghostsOnSale;
    for (uint i = 0;i<totalSupply;i++) {
      if (isListed(i)) {
        ghostsOnSale++;
      }
    }
  
    uint counter;
    for (uint i = 0;i<totalSupply;i++) {
      if (isListed(i)) {
        counter++;
      }
    }
    return counter;
  }
  function getAllListers() external view returns(address[] memory) {
    address[] memory owners = new address[](getAmountOfListings());
    uint[] memory ghosts = new uint[](owners.length);
    ghosts = getAllGhostsOnSale();
    for (uint i = 0;i < owners.length ; i++ ) {
      owners[i] = ghostsContract.ownerOf(ghosts[i]);
    }
    return owners;
  }
  function getPrices() external view returns(uint[] memory) {
    uint[] memory prices = new uint[](getAmountOfListings());
    uint[] memory ghosts = new uint[](prices.length);
    ghosts = getAllGhostsOnSale();
    for (uint i = 0;i < prices.length ; i++ ) {
      prices[i] = priceOf[ghosts[i]];
    }
    return prices;
  }
  function isOwnerOrApproved(uint tokenId,address subject) public view returns(bool) {
    return(
      subject==ghostsContract.ownerOf(tokenId) ||
      subject==ghostsContract.getApproved(tokenId) ||
      ghostsContract.isApprovedForAll(ghostsContract.ownerOf(tokenId),subject)
    );
  }
  function updateListing(uint ghostID, uint newPrice) external ownerOrApproved(ghostID) {
    priceOf[ghostID]=newPrice;
    emit ListingUpdated(ghostID,msg.sender,newPrice);
  }
  function isListed(uint ghostID) public view returns(bool) {
    return priceOf[ghostID]!=0;
  }
  function purchaseGhost(uint ghostID) external payable ghostOnSale(ghostID) reentrancyGuard {
    uint price = priceOf[ghostID];
    address beneficiery = ghostsContract.ownerOf(ghostID);
    require(msg.value==price,"Incorrect msg.value");
    ghostsContract.transferFrom(beneficiery,msg.sender,ghostID);
    payable(beneficiery).transfer(msg.value);
    priceOf[ghostID] = 0;
    emit GhostPurchased(msg.sender,beneficiery,ghostID, price);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        return msg.data;
    }
}