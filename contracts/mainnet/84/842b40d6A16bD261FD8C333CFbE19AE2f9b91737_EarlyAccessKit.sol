pragma solidity ^0.4.18;

contract LootboxInterface {
  event LootboxPurchased(address indexed owner, uint16 displayValue);
  
  function buy(address _buyer) external;
}

contract ExternalInterface {
  function giveItem(address _recipient, uint256 _traits) external;

  function giveMultipleItems(address _recipient, uint256[] _traits) external;

  function giveMultipleItemsToMultipleRecipients(address[] _recipients, uint256[] _traits) external;

  function giveMultipleItemsAndDestroyMultipleItems(address _recipient, uint256[] _traits, uint256[] _tokenIds) external;
  
  function destroyItem(uint256 _tokenId) external;

  function destroyMultipleItems(uint256[] _tokenIds) external;

  function updateItemTraits(uint256 _tokenId, uint256 _traits) external;
}


contract EarlyAccessKit is LootboxInterface {
  uint16 constant _displayValue = 1;
  uint16 kitsSold = 0;
  address constant coreContract = 0xF7CEAF2ee0a1E237e624e0e5C8b7cC0D28f01088;

  function getEarlyAccessKitsRemaining() external view returns (uint16 kitsRemaining) {
      kitsRemaining = kitsSold;
  }

  function buy(address _buyer) external {
    require(msg.sender == coreContract);
    require(kitsSold < 500);
    kitsSold++;
    LootboxPurchased(_buyer, _displayValue);
    ExternalInterface store = ExternalInterface(msg.sender);
    store.giveItem(_buyer, 16401); 
  }
}