/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/security/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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



pragma solidity 0.8.7;
contract Auction is Ownable, Pausable {
  using Counters for Counters.Counter;

  uint256[] public minimumUnitPrice;
  uint256 public immutable minimumBidIncrement;
  uint256 public immutable unitPriceStepSize;
  uint256 public immutable minimumQuantity;
  uint256 public immutable maximumQuantity;
  uint256 public immutable numberOfAuctions;
  uint256[] public itemsPerDay;
  address payable public immutable beneficiaryAddress;

  Counters.Counter private _auctionIDCounter;
  Counters.Counter private _bidPlacedCounter;

  bool private _allowWithdrawals;

  event AuctionStarted(uint256 auctionID);
  event AuctionEnded(uint256 auctionID);
  event BidPlaced(uint256 indexed auctionID, address indexed bidder, uint256 bidIndex, uint256 unitPrice, uint256 quantity);
  event WinnerSelected(uint256 indexed auctionID, address indexed bidder, uint256 unitPrice, uint256 quantity);
  event BidderRefunded(address indexed bidder, uint256 refundAmount);

  struct Bid {
    uint256 unitPrice;
    uint256 quantity;
  }

  struct AuctionStatus {
    bool started;
    bool ended;
  }


  mapping (uint256 => AuctionStatus) private _auctionStatus;

  mapping (address => Bid) private _bids;

  mapping (uint256 => uint256) private _remainingItemsPerAuction;


  constructor(
    address _contractOwner,
    address payable _beneficiaryAddress,

    uint256 _minimumBidIncrement,
    uint256 _unitPriceStepSize,
    uint256 _minimumQuantity,
    uint256 _maximumQuantity,
    uint256 _numberOfAuctions,
    uint256[] memory _itemsPerDay
  ) {
    beneficiaryAddress = _beneficiaryAddress;
    transferOwnership(_contractOwner);
    
    minimumBidIncrement = _minimumBidIncrement;
    unitPriceStepSize = _unitPriceStepSize;
    minimumQuantity = _minimumQuantity;
    maximumQuantity = _maximumQuantity;
    numberOfAuctions = _numberOfAuctions;

    for(uint256 i = 0; i < _numberOfAuctions; i++) {
      itemsPerDay.push(_itemsPerDay[i]);
      _remainingItemsPerAuction[i] = _itemsPerDay[i];
    }
    minimumUnitPrice = [40000000000000000,60000000000000000,80000000000000000];
    pause();
  }

  modifier whenAuctionActive() {
    require(!currentAuctionStatus().ended, "Auction has already ended.");
    require(currentAuctionStatus().started, "Auction hasn't started yet.");
    _;
  }

  modifier whenPreAuction() {
    require(!currentAuctionStatus().ended, "Auction has already ended.");
    require(!currentAuctionStatus().started, "Auction has already started.");
    _;
  }

  modifier whenAuctionEnded() {
    require(currentAuctionStatus().ended, "Auction hasn't ended yet.");
    require(currentAuctionStatus().started, "Auction hasn't started yet.");
    _;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setAllowWithdrawals(bool allowWithdrawals_) public onlyOwner {
    _allowWithdrawals = allowWithdrawals_;
  }

  function getAllowWithdrawals() public view returns (bool) {
    return _allowWithdrawals;
  }

  function auctionStatus(uint256 _auctionID) public view returns (AuctionStatus memory) {
    return _auctionStatus[_auctionID];
  }

  function currentAuctionStatus() public view returns (AuctionStatus memory) {
    return _auctionStatus[getCurrentAuctionID()];
  }


  function contractBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function bidsPlacedCount() external view returns (uint256) {
    return _bidPlacedCounter.current();
  }

  function getCurrentAuctionID() public view returns (uint) {
    return _auctionIDCounter.current();
  }

  function incrementAuctionID() public onlyOwner whenPaused whenAuctionEnded {
    _auctionIDCounter.increment();
    require(_auctionIDCounter.current() < numberOfAuctions, "Max number of auctions reached.");
  }
  
  function finalizeAuctions() public onlyOwner whenPaused whenAuctionEnded {
    require(_auctionIDCounter.current() == numberOfAuctions - 1, "Auctions not over");      
    _auctionIDCounter.increment();
    _auctionStatus[numberOfAuctions].started = true;
    _auctionStatus[numberOfAuctions].ended = true;
  }


  function decrementAuctionID() public onlyOwner whenPaused {
    _auctionIDCounter.decrement();
  }

  function startAuction() external onlyOwner whenPreAuction {
    uint256 currentAuctionID = getCurrentAuctionID();
    _auctionStatus[currentAuctionID].started = true;
    if (paused()) {
      unpause();
    }
    emit AuctionStarted(currentAuctionID);
  }

  function endAuction() external onlyOwner whenAuctionActive {
    uint256 currentAuctionID = getCurrentAuctionID();
    _auctionStatus[currentAuctionID].ended = true;
    if (!paused()) {
      pause();
    }
    emit AuctionEnded(currentAuctionID);
  }

  function getBid(address bidder) external view returns (Bid memory) {
    return _bids[bidder];
  }

  function getRemainingItemsForAuction(uint256 auctionID) external view returns (uint256) {
    require(auctionID < numberOfAuctions, "Invalid auctionID.");
    return _remainingItemsPerAuction[auctionID];
  }


  function selectWinners(address[] calldata bidders) external onlyOwner whenPaused whenAuctionEnded {
    uint256 auctionID = getCurrentAuctionID();

    for(uint256 i = 0; i < bidders.length; i++) {
      address bidder = bidders[i];
      uint256 bidUnitPrice = _bids[bidder].unitPrice;
      uint256 bidQuantity = _bids[bidder].quantity;


      if (bidUnitPrice == 0 || bidQuantity == 0) {
        continue;
      }

      if (_remainingItemsPerAuction[auctionID] == bidQuantity) {

        _bids[bidder] = Bid(0,0);
        emit WinnerSelected(auctionID, bidder, bidUnitPrice, bidQuantity);
        _remainingItemsPerAuction[auctionID] = 0;
        break;
      } else if (_remainingItemsPerAuction[auctionID] < bidQuantity) {

        emit WinnerSelected(auctionID, bidder, bidUnitPrice, _remainingItemsPerAuction[auctionID]);

        _bids[bidder].quantity -= _remainingItemsPerAuction[auctionID];
        _remainingItemsPerAuction[auctionID] = 0;
        break;
      } else {
        
        _bids[bidder] = Bid(0,0);
        emit WinnerSelected(auctionID, bidder, bidUnitPrice, bidQuantity);
        _remainingItemsPerAuction[auctionID] -= bidQuantity;
      }
    }
  }


  function refundBidders(address payable[] calldata bidders) external onlyOwner whenPaused whenAuctionEnded {
    uint256 totalRefundAmount = 0;
    for(uint256 i = 0; i < bidders.length; i++) {
      address payable bidder = bidders[i];
      uint256 refundAmount = _bids[bidder].unitPrice * _bids[bidder].quantity;

  
      if (refundAmount == 0) {
        continue;
      }

      _bids[bidder] = Bid(0,0);
      (bool success, ) = bidder.call{ value: refundAmount }("");
      require(success, "Transfer failed.");
      totalRefundAmount += refundAmount;
      emit BidderRefunded(bidder, refundAmount);
    }
  }

  function withdrawContractBalance() external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  
  function withdrawPartialContractBalance(uint256 amount) external onlyOwner {
    require(amount <= address(this).balance, "More than balance");
    (bool success, ) = beneficiaryAddress.call{value: amount}("");
    require(success, "Transfer failed.");
  }


  function claimRefund() external whenPaused whenAuctionEnded {

    require(_allowWithdrawals, "Withdrawals are not allowed right now.");
    uint256 refundAmount = _bids[msg.sender].unitPrice * _bids[msg.sender].quantity;
    require(refundAmount > 0, "Refund amount is 0.");
    _bids[msg.sender] = Bid(0,0);
    (bool success, ) = msg.sender.call{ value: refundAmount }("");
    require(success, "Transfer failed.");
    emit BidderRefunded(msg.sender, refundAmount);
  }


  function placeBid(uint256 quantity, uint256 unitPrice) external payable whenNotPaused whenAuctionActive {

    if (msg.value > 0 && msg.value < minimumBidIncrement) {
      revert("Bid lower than minimum bid increment.");
    }


    uint256 initialUnitPrice = _bids[msg.sender].unitPrice;
    uint256 initialQuantity = _bids[msg.sender].quantity;
    uint256 initialTotalValue = initialUnitPrice * initialQuantity;


    uint256 finalUnitPrice = unitPrice;
    uint256 finalQuantity = quantity;
    uint256 finalTotalValue = initialTotalValue + msg.value;


    require(finalUnitPrice % unitPriceStepSize == 0, "Unit price step too small.");


    require(finalQuantity >= minimumQuantity, "Quantity too low.");
    require(finalQuantity <= maximumQuantity, "Quantity too high.");


    require(finalTotalValue >= initialTotalValue, "Total value can't be lowered.");


    require(finalUnitPrice >= initialUnitPrice, "Unit price can't be lowered.");


    require(finalQuantity * finalUnitPrice == finalTotalValue, "Quantity * Unit Price != Total Value");


    require(finalUnitPrice >= minimumUnitPrice[_auctionIDCounter.current()], "Bid unit price too low.");


    if (initialUnitPrice == finalUnitPrice && initialQuantity == finalQuantity) {
      revert("This bid doesn't change anything.");
    }


    _bids[msg.sender].unitPrice = finalUnitPrice;
    _bids[msg.sender].quantity = finalQuantity;

    emit BidPlaced(_auctionIDCounter.current(), msg.sender, _bidPlacedCounter.current(), finalUnitPrice, finalQuantity);

    _bidPlacedCounter.increment();
  }


  receive() external payable {
    require(msg.value > 0, "No ether was sent.");
    require(msg.sender == beneficiaryAddress || msg.sender == owner(), "Only owner or beneficiary can fund contract.");
  }
}