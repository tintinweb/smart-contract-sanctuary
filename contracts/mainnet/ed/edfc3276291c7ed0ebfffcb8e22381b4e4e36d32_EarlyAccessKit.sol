pragma solidity ^0.4.18;

contract ExternalInterface {
  function giveItem(address _recipient, uint256 _traits) external;

  function giveMultipleItems(address _recipient, uint256[] _traits) external;

  function giveMultipleItemsToMultipleRecipients(address[] _recipients, uint256[] _traits) external;

  function giveMultipleItemsAndDestroyMultipleItems(address _recipient, uint256[] _traits, uint256[] _tokenIds) external;
  
  function destroyItem(uint256 _tokenId) external;

  function destroyMultipleItems(uint256[] _tokenIds) external;

  function updateItemTraits(uint256 _tokenId, uint256 _traits) external;
}


contract LootboxInterface {
  event LootboxPurchased(address indexed owner, uint16 displayValue);
  
  function buy(address _buyer) external;
}

contract EarlyAccessKit is LootboxInterface {
  uint16 constant _displayValue = 1;
  uint16 kitsSold = 0;

  function getEarlyAccessKitsRemaining() external view returns (uint16 kitsRemaining) {
      kitsRemaining = kitsSold;
  }

  function buy(address _buyer) external {
    require(kitsSold < 500);
    kitsSold++;
    LootboxPurchased(_buyer, _displayValue);
    ExternalInterface store = ExternalInterface(msg.sender);
    store.giveItem(_buyer, 16401); 
    // 1 1 1
    //0000000001 0000000001 0001  
  }
}