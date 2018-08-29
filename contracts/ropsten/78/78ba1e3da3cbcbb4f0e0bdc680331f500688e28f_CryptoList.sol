pragma solidity 0.4.24;

/// @title A Craigslist inspired Buy & Sell dApp for Ethereum
/// @author Navneet Raghuvanshi
/// @notice A simple Buy & Sell dApp called CryptoList
contract CryptoList {
    
  // For setting owner
  address private owner;
  
  //Circuit Breaker for pausing the contract
  bool private isPaused = false;

  // Item Structure
  struct Item {
    uint id;
    address seller;
    address buyer;
    string name;
    string description;
    uint256 price;
	  string ipfsHash;
  }

  // Item Tracking
  mapping (uint => Item) public items;
  uint itemCounter;
  
    //
	// Events
	//
  event LogSellItem(uint indexed _id, address indexed _seller, string _name, uint256 _price, string _ipfsHash);
  event LogBuyItem(uint indexed _id, address indexed _seller, address indexed _buyer, string _name, uint256 _price, string _ipfsHash);

	//
	// Modifiers
	//

/// @dev Create a modifer that checks if the msg.sender is the owner of the contract
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

/// @dev Create a modifer that checks if the number of items is more than zero
  modifier counterNotZero() {
    require(itemCounter > 0);
    _;
  }

/// @dev Create a modifer that checks if the contract is paused
  modifier isHalted() {
    require(isPaused == false);
    _;
  }

	// Kill switch to deactivate the contract
/// @dev Create a function that deactivates the contract when owner calls
  function kill() public onlyOwner {
    selfdestruct(owner);
  }

/// @notice Sell an item 
/// @dev Increment itemCounter, store Item and emit LogSellItem event
/// @param _name Item Name (string)
/// @param _description Item Description (string)
/// @param _price Price of the Item (uint256)
/// @param _ipfsHash IPFS Hash of image (string)
  function sellItem(string _name, string _description, uint256 _price, string _ipfsHash) public {
    // Increment item count
    itemCounter++;

    // store the item
    items[itemCounter] = Item(
      itemCounter,
      msg.sender,
      0x0,
      _name,
      _description,
      _price,
      _ipfsHash
    );

    emit LogSellItem(itemCounter, msg.sender, _name, _price, _ipfsHash);
  }

/// @notice Owner can pause the contract
/// @dev Owner can call this function to toggle contract isPaused state
  function toggleContractActive() public onlyOwner {
    isPaused = !isPaused;
  }
    
/// @notice Fetch the number of items in the contract
/// @dev Return itemCounter
  function getNumberOfItems() public view returns (uint) {
    return itemCounter;
  }

/// @notice Fetch all item IDs still for sale
/// @dev Fetch & Return items from memory
  function getItemsForSale() public view returns (uint[]) {
    // prepare output array
    uint[] memory itemIds = new uint[](itemCounter);

    uint numberOfItemsForSale = 0;
    // iterate over items
    for(uint i = 1; i <= itemCounter;  i++) {
      // keep the ID if the item is still for sale
      if(items[i].buyer == 0x0) {
        itemIds[numberOfItemsForSale] = items[i].id;
        numberOfItemsForSale++;
      }
    }

    // copy the itemIds array into a smaller forSale array
    uint[] memory forSale = new uint[](numberOfItemsForSale);
    for(uint j = 0; j < numberOfItemsForSale; j++) {
      forSale[j] = itemIds[j];
    }
    return forSale;
  }

  // buy an item
/// @notice Buy an item 
/// @dev Check for item availablity, match price, transfer payment, emit LogBuyItem event
/// @param _id Item ID (uint)
  function buyItem(uint _id) payable public counterNotZero {
    // we check that the item exists
    require(_id > 0 && _id <= itemCounter);

    // we retrieve the item
    Item storage item = items[_id];

    // we check that the Item has not been sold yet
    require(item.buyer == 0X0);

    // we don&#39;t allow the seller to buy his own Item
    require(msg.sender != item.seller);

    // we check that the value sent corresponds to the price of the Item
    require(msg.value == item.price);

    // keep buyer&#39;s information
    item.buyer = msg.sender;

    // the buyer can pay the seller
    item.seller.transfer(msg.value);

    // trigger the event
    emit LogBuyItem(_id, item.seller, item.buyer, item.name, item.price, item.ipfsHash);
  }
}