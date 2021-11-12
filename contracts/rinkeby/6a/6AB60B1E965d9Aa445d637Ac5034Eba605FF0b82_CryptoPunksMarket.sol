// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoPunksMarket is Ownable {
  // You can use this hash to verify the image file containing all the punks
  string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

  string public standard = "CryptoPunks";
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  uint256 public nextPunkIndexToAssign = 0;

  bool public allPunksAssigned = false;
  uint256 public punksRemainingToAssign = 0;

  //mapping (address => uint) public addressToPunkIndex;
  mapping(uint256 => address) public punkIndexToAddress;

  /* This creates an array with all balances */
  mapping(address => uint256) public balanceOf;

  struct Offer {
    bool isForSale;
    uint256 punkIndex;
    address seller;
    uint256 minValue; // in ether
    address onlySellTo; // specify to sell only to a specific person
  }

  struct Bid {
    bool hasBid;
    uint256 punkIndex;
    address bidder;
    uint256 value;
  }

  // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
  mapping(uint256 => Offer) public punksOfferedForSale;

  // A record of the highest punk bid
  mapping(uint256 => Bid) public punkBids;

  mapping(address => uint256) public pendingWithdrawals;

  event Assign(address indexed to, uint256 punkIndex);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
  event PunkOffered(uint256 indexed punkIndex, uint256 minValue, address indexed toAddress);
  event PunkBidEntered(uint256 indexed punkIndex, uint256 value, address indexed fromAddress);
  event PunkBidWithdrawn(uint256 indexed punkIndex, uint256 value, address indexed fromAddress);
  event PunkBought(uint256 indexed punkIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
  event PunkNoLongerForSale(uint256 indexed punkIndex);

  /* Initializes contract with initial supply tokens to the creator of the contract */
  constructor() {
    //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
    totalSupply = 10000; // Update total supply
    punksRemainingToAssign = totalSupply;
    name = "CRYPTOPUNKS"; // Set the name for display purposes
    symbol = "\x3FE"; // Set the symbol for display purposes Ͼ
    decimals = 0; // Amount of decimals for display purposes
  }

  function setInitialOwner(address to, uint256 punkIndex) public onlyOwner {
    require(allPunksAssigned, "CryptoPunksMarket:  allPunksAssigned");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    if (punkIndexToAddress[punkIndex] != to) {
      if (punkIndexToAddress[punkIndex] != address(0)) {
        balanceOf[punkIndexToAddress[punkIndex]]--;
      } else {
        punksRemainingToAssign--;
      }
      punkIndexToAddress[punkIndex] = to;
      balanceOf[to]++;
      emit Assign(to, punkIndex);
    }
  }

  function setInitialOwners(address[] calldata addresses, uint256[] calldata indices) public onlyOwner {
    uint256 n = addresses.length;
    for (uint256 i = 0; i < n; i++) {
      setInitialOwner(addresses[i], indices[i]);
    }
  }

  function allInitialOwnersAssigned() public onlyOwner {
    allPunksAssigned = true;
  }

  function getPunk(uint256 punkIndex) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punksRemainingToAssign != 0, "CryptoPunksMarket: empty punksRemainingToAssign");
    require(punkIndexToAddress[punkIndex] == address(0), "CryptoPunksMarket: already got");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    punkIndexToAddress[punkIndex] = msg.sender;
    balanceOf[msg.sender]++;
    punksRemainingToAssign--;

    emit Assign(msg.sender, punkIndex);
  }

  // Transfer ownership of a punk to another user without requiring payment
  function transferPunk(address to, uint256 punkIndex) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] == msg.sender, "CryptoPunksMarket: not owner");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    if (punksOfferedForSale[punkIndex].isForSale) {
      punkNoLongerForSale(punkIndex);
    }
    punkIndexToAddress[punkIndex] = to;
    balanceOf[msg.sender]--;
    balanceOf[to]++;

    emit Transfer(msg.sender, to, 1);
    emit PunkTransfer(msg.sender, to, punkIndex);

    // Check for the case where there is a bid from the new owner and refund it.
    // Any other bid can stay in place.
    Bid memory bid = punkBids[punkIndex];
    if (bid.bidder == to) {
      // Kill bid and refund value
      pendingWithdrawals[to] += bid.value;
      punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
    }
  }

  function punkNoLongerForSale(uint256 punkIndex) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] == msg.sender, "CryptoPunksMarket: not owner");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0));

    emit PunkNoLongerForSale(punkIndex);
  }

  function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] == msg.sender, "CryptoPunksMarket: not owner");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, address(0));

    emit PunkOffered(punkIndex, minSalePriceInWei, address(0));
  }

  function offerPunkForSaleToAddress(
    uint256 punkIndex,
    uint256 minSalePriceInWei,
    address toAddress
  ) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] == msg.sender, "CryptoPunksMarket: not owner");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);

    emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
  }

  function buyPunk(uint256 punkIndex) public payable {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    Offer memory offer = punksOfferedForSale[punkIndex];
    require(offer.isForSale, "CryptoPunksMarket: punk not actually for sale");
    require(
      offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender,
      "CryptoPunksMarket: punk not supposed to be sold to this user"
    );

    require(msg.value >= offer.minValue, "CryptoPunksMarket: Didn't send enough ETH");
    require(offer.seller == punkIndexToAddress[punkIndex], "CryptoPunksMarket: Seller no longer owner of punk");

    address seller = offer.seller;

    punkIndexToAddress[punkIndex] = msg.sender;
    balanceOf[seller]--;
    balanceOf[msg.sender]++;

    emit Transfer(seller, msg.sender, 1);

    punkNoLongerForSale(punkIndex);
    pendingWithdrawals[seller] += msg.value;

    emit PunkBought(punkIndex, msg.value, seller, msg.sender);

    // Check for the case where there is a bid from the new owner and refund it.
    // Any other bid can stay in place.
    Bid memory bid = punkBids[punkIndex];
    if (bid.bidder == msg.sender) {
      // Kill bid and refund value
      pendingWithdrawals[msg.sender] += bid.value;
      punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
    }
  }

  function withdraw() public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");

    uint256 amount = pendingWithdrawals[msg.sender];
    // Remember to zero the pending refund before
    // sending to prevent re-entrancy attacks
    pendingWithdrawals[msg.sender] = 0;

    _safeTransferETH(msg.sender, amount);
  }

  function enterBidForPunk(uint256 punkIndex) public payable {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");
    require(punkIndexToAddress[punkIndex] != msg.sender, "CryptoPunksMarket: can not buy your own punk");
    require(punkIndexToAddress[punkIndex] != address(0), "CryptoPunksMarket: can not buy unassigned punk");
    require(msg.value > 0, "CryptoPunksMarket: should send eth value");

    Bid memory existing = punkBids[punkIndex];
    require(msg.value > existing.value, "CryptoPunksMarket: should send more eth value");

    if (existing.value > 0) {
      // Refund the failing bid
      pendingWithdrawals[existing.bidder] += existing.value;
    }
    punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);

    emit PunkBidEntered(punkIndex, msg.value, msg.sender);
  }

  function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] == msg.sender, "CryptoPunksMarket: not owner");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    address seller = msg.sender;

    Bid memory bid = punkBids[punkIndex];
    require(bid.value >= minPrice, "CryptoPunksMarket: bid value to small");

    punkIndexToAddress[punkIndex] = bid.bidder;
    balanceOf[seller]--;
    balanceOf[bid.bidder]++;

    emit Transfer(seller, bid.bidder, 1);

    punksOfferedForSale[punkIndex] = Offer(false, punkIndex, bid.bidder, 0, address(0));
    uint256 amount = bid.value;
    punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
    pendingWithdrawals[seller] += amount;

    emit PunkBought(punkIndex, bid.value, seller, bid.bidder);
  }

  function withdrawBidForPunk(uint256 punkIndex) public {
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] != address(0), "CryptoPunksMarket: punk not assigned");
    require(punkIndexToAddress[punkIndex] != msg.sender, "CryptoPunksMarket: can not withdraw self");

    Bid memory bid = punkBids[punkIndex];
    require(bid.bidder == msg.sender, "CryptoPunksMakrket: not bid bidder");

    emit PunkBidWithdrawn(punkIndex, bid.value, msg.sender);

    uint256 amount = bid.value;

    punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);

    // Refund the bid money
    _safeTransferETH(msg.sender, amount);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "ETH_TRANSFER_FAILED");
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