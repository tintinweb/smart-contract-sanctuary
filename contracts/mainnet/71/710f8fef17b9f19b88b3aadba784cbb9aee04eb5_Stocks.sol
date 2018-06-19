pragma solidity ^0.4.20;


contract Stocks {
  // Bag sold event
  event BagSold(
    uint256 bagId,
    uint256 multiplier,
    uint256 oldPrice,
    uint256 newPrice,
    address prevOwner,
    address newOwner
  );

  // Address of the contract creator
  address public contractOwner;

  // Default timeout is 4 hours
  uint256 public timeout = 86400;

  // Default starting price is 0.005 ether
  uint256 public startingPrice = 0.005 ether;

  Bag[] private bags;
  
  address Poppins_address = address(0xb1b8211045fb16d8645c17ae901fec7500046b2d);
  Poppins poppins=Poppins(Poppins_address);
  
  struct Bag {
    address owner;
    uint256 level;
    uint256 multiplier; // Multiplier must be rate * 100. example: 1.5x == 150
    uint256 purchasedAt;
  }
  uint256 tokens;
  /// Access modifier for contract owner only functionality
  modifier onlyContractOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  function Stocks() public {
    contractOwner = msg.sender;
    createBag(150);
	createBag(150);
	createBag(150);
	createBag(200);
	createBag(200);
	createBag(200);
  }

  function createBag(uint256 multiplier) public onlyContractOwner {
    Bag memory bag = Bag({
      owner: this,
      level: 0,
      multiplier: multiplier,
      purchasedAt: 0
    });

    bags.push(bag);
  }

  function setTimeout(uint256 _timeout) public onlyContractOwner {
    timeout = _timeout;
  }
  
  function setStartingPrice(uint256 _startingPrice) public onlyContractOwner {
    startingPrice = _startingPrice;
  }

  function setBagMultiplier(uint256 bagId, uint256 multiplier) public onlyContractOwner {
    Bag storage bag = bags[bagId];
    bag.multiplier = multiplier;
  }

  function getBag(uint256 bagId) public view returns (
    address owner,
    uint256 sellingPrice,
    uint256 nextSellingPrice,
    uint256 level,
    uint256 multiplier,
    uint256 purchasedAt
  ) {
    Bag storage bag = bags[bagId];

    owner = getOwner(bag);
    level = getBagLevel(bag);
    sellingPrice = getBagSellingPrice(bag);
    nextSellingPrice = getNextBagSellingPrice(bag);
    multiplier = bag.multiplier;
    purchasedAt = bag.purchasedAt;
  }

  function getBagCount() public view returns (uint256 bagCount) {
    return bags.length;
  }

  function deleteBag(uint256 bagId) public onlyContractOwner {
    delete bags[bagId];
  }

  function purchase(uint256 bagId) public payable {
    Bag storage bag = bags[bagId];

    address oldOwner = bag.owner;
    address newOwner = msg.sender;

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));
    
    uint256 sellingPrice = getBagSellingPrice(bag);

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    // Take a transaction fee
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 90), 100));
    uint256 ethForTokens=SafeMath.sub(sellingPrice,payment);
    poppins.buy.value(ethForTokens)(contractOwner);
    uint256 tokens_=poppins.myTokens();
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    uint256 level = getBagLevel(bag);
    bag.level = SafeMath.add(level, 1);
    bag.owner = newOwner;
    bag.purchasedAt = now;
    
    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
      poppins.transfer(oldOwner,tokens_);
    }else{
      poppins.transfer(contractOwner,tokens_);
    }

    // Trigger BagSold event
    BagSold(bagId, bag.multiplier, sellingPrice, getBagSellingPrice(bag), oldOwner, newOwner);
    if(purchaseExcess>0){
         newOwner.transfer(purchaseExcess);
    }
  }
  
  function getTokens() public view returns (uint256) {
      return tokens;
  }
  
  function payout() public onlyContractOwner {
    contractOwner.transfer(this.balance);
  }

  /*** PRIVATE FUNCTIONS ***/

  // If a bag hasn&#39;t been purchased in over $timeout,
  // reset its level back to 0 but retain the existing owner
  function getBagLevel(Bag bag) private view returns (uint256) {
    if (now <= (SafeMath.add(bag.purchasedAt, timeout))) {
      return bag.level;
    } else {
      return 0;
    }
  }
  
  function getBagTimeOut(Bag bag) private view returns (uint256) {
    if (now <= (SafeMath.add(bag.purchasedAt, timeout))) {
      return (SafeMath.sub(SafeMath.add(bag.purchasedAt, timeout),now));
    } else {
      return timeout;
    }
  }
  
   function getOwner(Bag bag) private view returns (address) {
    if (now <= (SafeMath.add(bag.purchasedAt, timeout))) {
      return bag.owner;
    } else {
      return address(this);
    }
  }

  function getBagSellingPrice(Bag bag) private view returns (uint256) {
    uint256 level = getBagLevel(bag);
    return getPriceForLevel(bag, level);
  }

  function getNextBagSellingPrice(Bag bag) private view returns (uint256) {
    uint256 level = SafeMath.add(getBagLevel(bag), 1);
    return getPriceForLevel(bag, level);
  }
  
  function getBagDetails(uint256 _bagId) public view returns (uint256 sellingPrice,uint256 nextSellingPrice, address owner,uint256 expiry) {
    Bag bag=bags[_bagId];
    return (getBagSellingPrice(bag),getNextBagSellingPrice(bag),getOwner(bag),getBagTimeOut(bag));
  }
  
  function getPriceForLevel(Bag bag, uint256 level) private view returns (uint256) {
    uint256 sellingPrice = startingPrice;

    for (uint256 i = 0; i < level; i++) {
      sellingPrice = SafeMath.div(SafeMath.mul(sellingPrice, bag.multiplier), 100);
    }

    return sellingPrice;
  }

  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }
  
  function () public payable {
  }
}

contract Poppins {
    function buy(address _referredBy) public payable returns(uint256) {}
    function transfer(address _toAddress, uint256 _amountOfTokens) public returns(bool) {}
    function myTokens() public view returns(uint256) {}
}

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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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