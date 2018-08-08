pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send or transfer.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev Withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(address(this).balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    payee.transfer(payment);
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }

  // Called by children of this contract to remove value from an account
  function asyncDebit(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].sub(amount);
    totalPayments = totalPayments.sub(amount);
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * Sorted list of sales for use in the marketplace. Sorting is maintained by linked list.
 */
library SaleListLib {
  address public constant nullAddress = address(0);

  struct SaleList {
    address head;

    mapping(address => address) sellerListMapping;
    mapping(address => uint) sellerToPrice;
  }

  function getBest(SaleList storage self) public view returns (address, uint) {
    address head = self.head;
    return (head, self.sellerToPrice[head]);
  }

  function addSale(SaleList storage self, address seller, uint price) public {
    require(price != 0);
    require(seller != nullAddress);

    if (_contains(self, seller)) {
      removeSale(self, seller);
    }

    self.sellerToPrice[seller] = price;
    if (self.head == nullAddress || price <= self.sellerToPrice[self.head]) {
      self.sellerListMapping[seller] = self.head;
      self.head = seller;
    } else {
      address prev = self.head;
      address cur = self.sellerListMapping[prev];

      while (cur != nullAddress) {
        if (price <= self.sellerToPrice[cur]) {
          self.sellerListMapping[prev] = seller;
          self.sellerListMapping[seller] = cur;

          break;
        }

        prev = cur;
        cur = self.sellerListMapping[cur];
      }

      // Insert value greater than all values in list
      if (cur == nullAddress) {
        self.sellerListMapping[prev] = seller;
      }
    }
  }

  function removeSale(SaleList storage self, address seller) public returns (bool) {
    require(seller != nullAddress);

    if (!_contains(self, seller)) {
      return false;
    }

    if (seller == self.head) {
      self.head = self.sellerListMapping[seller];
      _remove(self, seller);
    } else {
      address prev = self.head;
      address cur = self.sellerListMapping[prev];

      // TODO: Make SURE that initialized mapping with address vals initializes those vals to address(0)
      // NOTE: Redundant check (prev != seller)
      while (cur != nullAddress && prev != seller) {
        if (cur == seller) {
          self.sellerListMapping[prev] = self.sellerListMapping[seller];
          _remove(self, seller);

          break;
        }

        prev = cur;
        cur = self.sellerListMapping[cur];
      }

      // NOTE: Redundant check
      if (cur == nullAddress) {
        return false;
      }
    }

    return true;
  }

  // NOTE: This is a purely internal method that *only* zeros out sellerListMapping and sellerToPrice
  function _remove(SaleList storage self, address seller) internal {
    self.sellerToPrice[seller] = 0;
    self.sellerListMapping[seller] = nullAddress;
  }

  function _contains(SaleList storage self, address seller) view internal returns (bool) {
    return self.sellerToPrice[seller] != 0;
  }
}

contract SaleRegistry is Ownable {
  using SafeMath for uint256;

  /////////
  // Events
  /////////

  event SalePosted(
    address indexed _seller,
    bytes32 indexed _sig,
    uint256 _price
  );

  event SaleCancelled(
    address indexed _seller,
    bytes32 indexed _sig
  );

  ////////
  // State
  ////////

  mapping(bytes32 => SaleListLib.SaleList) _sigToSortedSales;

  mapping(address => mapping(bytes32 => uint256)) _addressToSigToSalePrice;

  // NOTE: Rules are different for contract owner. Can run many sales at a time, all at a single price. This
  // allows multi-sale at genesis time
  mapping(bytes32 => uint256) _ownerSigToNumSales;

  mapping(bytes32 => uint256) public sigToNumSales;

  /////////////
  // User views
  /////////////

  // Returns (seller, price) tuple
  function getBestSale(bytes32 sig) public view returns (address, uint256) {
    return SaleListLib.getBest(_sigToSortedSales[sig]);
  }

  // Returns price that the sender is selling the current sig for (or 0 if not)
  function getMySalePrice(bytes32 sig) public view returns (uint256) {
    return _addressToSigToSalePrice[msg.sender][sig];
  }

  ///////////////
  // User actions
  ///////////////

  // Convenience method used *only* at genesis sale time
  function postGenesisSales(bytes32 sig, uint256 price, uint256 numSales) internal onlyOwner {
    SaleListLib.addSale(_sigToSortedSales[sig], owner, price);
    _addressToSigToSalePrice[owner][sig] = price;

    _ownerSigToNumSales[sig] = _ownerSigToNumSales[sig].add(numSales);
    sigToNumSales[sig] = sigToNumSales[sig].add(numSales);

    emit SalePosted(owner, sig, price);
  }

  // Admin method for re-listing all genesis sales
  function relistGenesisSales(bytes32 sig, uint256 newPrice) external onlyOwner {
    SaleListLib.addSale(_sigToSortedSales[sig], owner, newPrice);
    _addressToSigToSalePrice[owner][sig] = newPrice;

    emit SalePosted(owner, sig, newPrice);
  }

  // NOTE: Only allows 1 active sale per address per sig, unless owner
  function postSale(address seller, bytes32 sig, uint256 price) internal {
    SaleListLib.addSale(_sigToSortedSales[sig], seller, price);
    _addressToSigToSalePrice[seller][sig] = price;

    sigToNumSales[sig] = sigToNumSales[sig].add(1);

    if (seller == owner) {
      _ownerSigToNumSales[sig] = _ownerSigToNumSales[sig].add(1);
    }

    emit SalePosted(seller, sig, price);
  }

  // NOTE: Special remove logic for contract owner&#39;s sale!
  function cancelSale(address seller, bytes32 sig) internal {
    if (seller == owner) {
      _ownerSigToNumSales[sig] = _ownerSigToNumSales[sig].sub(1);

      if (_ownerSigToNumSales[sig] == 0) {
        SaleListLib.removeSale(_sigToSortedSales[sig], seller);
        _addressToSigToSalePrice[seller][sig] = 0;
      }
    } else {
      SaleListLib.removeSale(_sigToSortedSales[sig], seller);
      _addressToSigToSalePrice[seller][sig] = 0;
    }
    sigToNumSales[sig] = sigToNumSales[sig].sub(1);

    emit SaleCancelled(seller, sig);
  }
}

contract OwnerRegistry {
  using SafeMath for uint256;

  /////////
  // Events
  /////////

  event CardCreated(
    bytes32 indexed _sig,
    uint256 _numAdded
  );

  event CardsTransferred(
    bytes32 indexed _sig,
    address indexed _oldOwner,
    address indexed _newOwner,
    uint256 _count
  );

  ////////
  // State
  ////////

  bytes32[] _allSigs;
  mapping(address => mapping(bytes32 => uint256)) _ownerToSigToCount;
  mapping(bytes32 => uint256) _sigToCount;

  ////////////////
  // Admin actions
  ////////////////

  function addCardToRegistry(address owner, bytes32 sig, uint256 numToAdd) internal {
    // Only allow adding cards that haven&#39;t already been added
    require(_sigToCount[sig] == 0);

    _allSigs.push(sig);
    _ownerToSigToCount[owner][sig] = numToAdd;
    _sigToCount[sig] = numToAdd;

    emit CardCreated(sig, numToAdd);
  }

  /////////////
  // User views
  /////////////

  function getAllSigs() public view returns (bytes32[]) {
    return _allSigs;
  }

  function getNumSigsOwned(bytes32 sig) public view returns (uint256) {
    return _ownerToSigToCount[msg.sender][sig];
  }

  function getNumSigs(bytes32 sig) public view returns (uint256) {
    return _sigToCount[sig];
  }

  ///////////////////
  // Transfer actions
  ///////////////////

  function registryTransfer(address oldOwner, address newOwner, bytes32 sig, uint256 count) internal {
    // Must be transferring at least one card!
    require(count > 0);

    // Don&#39;t allow a transfer when the old owner doesn&#39;t enough of the card
    require(_ownerToSigToCount[oldOwner][sig] >= count);

    _ownerToSigToCount[oldOwner][sig] = _ownerToSigToCount[oldOwner][sig].sub(count);
    _ownerToSigToCount[newOwner][sig] = _ownerToSigToCount[newOwner][sig].add(count);

    emit CardsTransferred(sig, oldOwner, newOwner, count);
  }
}

contract ArtistRegistry {
  using SafeMath for uint256;

  mapping(bytes32 => address) _sigToArtist;

  // fee tuple is of form (txFeePercent, genesisSalePercent)
  mapping(bytes32 => uint256[2]) _sigToFeeTuple;

  function addArtistToRegistry(bytes32 sig,
                               address artist,
                               uint256 txFeePercent,
                               uint256 genesisSalePercent) internal {
    // Must be a valid artist address!
    require(artist != address(0));

    // Only allow 1 sig per artist!
    require(_sigToArtist[sig] == address(0));

    _sigToArtist[sig] = artist;
    _sigToFeeTuple[sig] = [txFeePercent, genesisSalePercent];
  }

  function computeArtistTxFee(bytes32 sig, uint256 txFee) internal view returns (uint256) {
    uint256 feePercent = _sigToFeeTuple[sig][0];
    return (txFee.mul(feePercent)).div(100);
  }

  function computeArtistGenesisSaleFee(bytes32 sig, uint256 genesisSaleProfit) internal view returns (uint256) {
    uint256 feePercent = _sigToFeeTuple[sig][1];
    return (genesisSaleProfit.mul(feePercent)).div(100);
  }

  function getArtist(bytes32 sig) internal view returns (address) {
    return _sigToArtist[sig];
  }
}

contract PepeCore is PullPayment, OwnerRegistry, SaleRegistry, ArtistRegistry {
  using SafeMath for uint256;

  uint256 constant public totalTxFeePercent = 4;

  ////////////////////
  // Shareholder stuff
  ////////////////////

  // Only 3 equal shareholders max allowed on this contract representing the three equal-partner founders
  // involved in its inception
  address public shareholder1;
  address public shareholder2;
  address public shareholder3;

  // 0 -> 3 depending on contract state. I only use uint256 so that I can use SafeMath...
  uint256 public numShareholders = 0;

  // Used to set initial shareholders
  function addShareholderAddress(address newShareholder) external onlyOwner {
    // Don&#39;t let shareholder be address(0)
    require(newShareholder != address(0));

    // Contract owner can&#39;t be a shareholder
    require(newShareholder != owner);

    // Must be an open shareholder spot!
    require(shareholder1 == address(0) || shareholder2 == address(0) || shareholder3 == address(0));

    if (shareholder1 == address(0)) {
      shareholder1 = newShareholder;
      numShareholders = numShareholders.add(1);
    } else if (shareholder2 == address(0)) {
      shareholder2 = newShareholder;
      numShareholders = numShareholders.add(1);
    } else if (shareholder3 == address(0)) {
      shareholder3 = newShareholder;
      numShareholders = numShareholders.add(1);
    }
  }

  // Splits the amount specified among shareholders equally
  function payShareholders(uint256 amount) internal {
    // If no shareholders, shareholder fees will be held in contract to be withdrawable by owner
    if (numShareholders > 0) {
      uint256 perShareholderFee = amount.div(numShareholders);

      if (shareholder1 != address(0)) {
        asyncSend(shareholder1, perShareholderFee);
      }

      if (shareholder2 != address(0)) {
        asyncSend(shareholder2, perShareholderFee);
      }

      if (shareholder3 != address(0)) {
        asyncSend(shareholder3, perShareholderFee);
      }
    }
  }

  ////////////////
  // Admin actions
  ////////////////

  function withdrawContractBalance() external onlyOwner {
    uint256 contractBalance = address(this).balance;
    uint256 withdrawableBalance = contractBalance.sub(totalPayments);

    // No withdrawal necessary if <= 0 balance
    require(withdrawableBalance > 0);

    msg.sender.transfer(withdrawableBalance);
  }

  function addCard(bytes32 sig,
                   address artist,
                   uint256 txFeePercent,
                   uint256 genesisSalePercent,
                   uint256 numToAdd,
                   uint256 startingPrice) external onlyOwner {
    addCardToRegistry(owner, sig, numToAdd);

    addArtistToRegistry(sig, artist, txFeePercent, genesisSalePercent);

    postGenesisSales(sig, startingPrice, numToAdd);
  }

  ///////////////
  // User actions
  ///////////////

  function createSale(bytes32 sig, uint256 price) external {
    // Can&#39;t sell a card for 0... May want other limits in the future
    require(price > 0);

    // Can&#39;t sell a card you don&#39;t own
    require(getNumSigsOwned(sig) > 0);

    // Can&#39;t post a sale if you have one posted already! Unless you&#39;re the contract owner
    require(msg.sender == owner || _addressToSigToSalePrice[msg.sender][sig] == 0);

    postSale(msg.sender, sig, price);
  }

  function removeSale(bytes32 sig) public {
    // Can&#39;t cancel a sale that doesn&#39;t exist
    require(_addressToSigToSalePrice[msg.sender][sig] > 0);

    cancelSale(msg.sender, sig);
  }

  function computeTxFee(uint256 price) private pure returns (uint256) {
    return (price * totalTxFeePercent) / 100;
  }

  // If card is held by contract owner, split among artist + shareholders
  function paySellerFee(bytes32 sig, address seller, uint256 sellerProfit) private {
    if (seller == owner) {
      address artist = getArtist(sig);
      uint256 artistFee = computeArtistGenesisSaleFee(sig, sellerProfit);
      asyncSend(artist, artistFee);

      payShareholders(sellerProfit.sub(artistFee));
    } else {
      asyncSend(seller, sellerProfit);
    }
  }

  // Simply pay out tx fees appropriately
  function payTxFees(bytes32 sig, uint256 txFee) private {
    uint256 artistFee = computeArtistTxFee(sig, txFee);
    address artist = getArtist(sig);
    asyncSend(artist, artistFee);

    payShareholders(txFee.sub(artistFee));
  }

  // Handle wallet debit if necessary, pay out fees, pay out seller profit, cancel sale, transfer card
  function buy(bytes32 sig) external payable {
    address seller;
    uint256 price;
    (seller, price) = getBestSale(sig);

    // There must be a valid sale for the card
    require(price > 0 && seller != address(0));

    // Buyer must have enough Eth via wallet and payment to cover posted price
    uint256 availableEth = msg.value.add(payments[msg.sender]);
    require(availableEth >= price);

    // Debit wallet if msg doesn&#39;t have enough value to cover price
    if (msg.value < price) {
      asyncDebit(msg.sender, price.sub(msg.value));
    }

    // Split out fees + seller profit
    uint256 txFee = computeTxFee(price);
    uint256 sellerProfit = price.sub(txFee);

    // Pay out seller (special logic for seller == owner)
    paySellerFee(sig, seller, sellerProfit);

    // Pay out tx fees
    payTxFees(sig, txFee);

    // Cancel sale
    cancelSale(seller, sig);

    // Transfer single sig ownership in registry
    registryTransfer(seller, msg.sender, sig, 1);
  }

  // Can also be used in airdrops, etc.
  function transferSig(bytes32 sig, uint256 count, address newOwner) external {
    uint256 numOwned = getNumSigsOwned(sig);

    // Can&#39;t transfer cards you don&#39;t own
    require(numOwned >= count);

    // If transferring from contract owner, cancel the proper number of sales if necessary
    if (msg.sender == owner) {
      uint256 remaining = numOwned.sub(count);

      if (remaining < _ownerSigToNumSales[sig]) {
        uint256 numSalesToCancel = _ownerSigToNumSales[sig].sub(remaining);

        for (uint256 i = 0; i < numSalesToCancel; i++) {
          removeSale(sig);
        }
      }
    } else {
      // Remove existing sale if transferring all owned cards
      if (numOwned == count && _addressToSigToSalePrice[msg.sender][sig] > 0) {
        removeSale(sig);
      }
    }

    // Transfer in registry
    registryTransfer(msg.sender, newOwner, sig, count);
  }
}