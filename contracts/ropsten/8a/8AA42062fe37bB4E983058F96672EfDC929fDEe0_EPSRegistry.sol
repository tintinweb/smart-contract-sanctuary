/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

/**
 * The EPS registry interface.
 */
interface EPS {

  // Events:
  event proxyItemCreated(address indexed proxy, address indexed owner, address indexed delivery, uint256 timestamp);
  event proxyItemUpdated(address indexed proxy, address indexed owner, address indexed delivery, uint256 timestamp);
  event proxyItemDeleted(address indexed proxy, address indexed owner, address indexed delivery, uint256 timestamp);

  // Functions:
  function getOwner(address _proxy) external view returns (address ownerAddress);
  function getDelivery(address _proxy) external view returns (address deliveryAddress);
  function getOwnerAndDeliveryAddress(address _proxy) external view returns (address ownerAddress, address deliveryAddress);
  function getSignerOwner() external view returns (address ownerAddress) ;
  function getSignerDelivery() external view returns (address deliveryAddress);
  function getSignerOwnerAndDeliveryAddress() external view returns (address ownerAddress, address deliveryAddress);
  function addProxyEntry(address _proxy, address _delivery) external; 
  function changeProxyEntry(address _proxy, address _delivery) external; 
  function deleteProxyEntry(address _proxy) external;
}

/**
 * The EPS registry contract.
 */
contract EPSRegistry is EPS {

  struct RegistryItem {
    address owner;
    address delivery;
  }

  mapping (address => RegistryItem) registryItems;

  // Only the owner of the record can perform this action: 
  modifier isProxyOwner(address _proxy) {
    address owner = getOwner(_proxy);
    require(owner == msg.sender, "Only owner can perform this action");
    _;
  }

  // Proxy addresses can be used only ONCE. Asset (owner) addresses can be used with unique proxy addresses
  // to facilitate different delivery addresses. For example, owner 0x01 can implement a proxy to address 0x11
  // that delivers assets to 0x0a, and a proxy to address 0x12 that delivers assets to address 0x0b. In both 
  // cases the owner is the same (for validation of holdings, etc.) but the delivery address is different.
  // This allows users to decide where the results of their interactions (e.g. new tokens) should be delivered,
  // enabling them to be delivered to the right place first time and prevent needless contract interactions. 
  modifier isNewProxyAddress(address _proxy) {
    require(!proxyEntryExists(_proxy), "Proxy entry already exists");
    _;
  }

  modifier isExistingProxyAddress(address _proxy) {
    require(proxyEntryExists(_proxy), "Proxy entry does not exist");
    _;
  }

  // Return if an entry exists for this proxy address
  function proxyEntryExists(address _proxy) public view returns (bool) {
    return registryItems[_proxy].owner != address(0x0);
  }

  // ======================================================================================================
  // GET: VIEW METHODS - these take the proxy address as a parameter so can be used to query details for 
  // any proxy address. If you wish to return details for the msg.sender use the signer methods below.
  // ======================================================================================================
  
  // Get the owner address for a proxy address:
  function getOwner(address _proxy) public view returns (address ownerAddress) {
    return (registryItems[_proxy].owner);
  }

  // Get the delivery address for a proxy address:
  function getDelivery(address _proxy) public view returns (address deliveryAddress) {
    return (registryItems[_proxy].delivery);
  }

  // Returns the proxied address details (owner and delivery address) for a passed proxy address. This is the 
  // function to call to view the details for any given address. For confirmed details for an address that is 
  // being interaceted with the function getConfirmedProxyDetails() should be used. This takes no parameters
  // and looks up the proxy details on the basis of the msg.sender.
  function getOwnerAndDeliveryAddress(address _proxy) public view returns (address ownerAddress, address deliveryAddress) {
    return (getOwner(_proxy), getDelivery(_proxy));
  }

  // ======================================================================================================
  // GET: SIGNER METHODS - these execute the view methods with msg.sender as the parameter 
  // i.e. call this if you wish to limit details to the address you are interacting with.
  // ======================================================================================================
  // Get the owner address for a proxy address:
  function getSignerOwner() external view returns (address ownerAddress) {
    return (getOwner(msg.sender));
  }

  // Get the delivery address for a proxy address:
  function getSignerDelivery() external view returns (address deliveryAddress) {
    return (getDelivery(msg.sender));
  }

  // Returns the proxied address details (owner and delivery address) for the msg.sender being interacted with.
  function getSignerOwnerAndDeliveryAddress() external view returns (address ownerAddress, address deliveryAddress) {
    return (getOwnerAndDeliveryAddress(msg.sender));
  }

  // ======================================================================================================
  // MAINTAIN: methods for maintaining proxy entries 
  // ======================================================================================================
  // Add a new proxy entry
  function addProxyEntry(address _proxy, address _delivery) external isNewProxyAddress(_proxy) {
    require (_proxy != address(0), "Proxy address must be provided");
    require (_delivery != address(0), "Delivery address must be provided");
    registryItems[_proxy] = RegistryItem(msg.sender, _delivery);
    emit proxyItemCreated(_proxy, msg.sender, _delivery, block.timestamp);
  }

  // Change an existing proxy entry
  function changeProxyEntry(address _proxy, address _delivery) external isExistingProxyAddress(_proxy) isProxyOwner(_proxy) {
    require (_delivery != address(0), "Delivery address must be provided");
    registryItems[_proxy].delivery = _delivery;
    emit proxyItemUpdated(_proxy, msg.sender, _delivery, block.timestamp);
  }

  // Delete a proxy entry
  function deleteProxyEntry(address _proxy) external isExistingProxyAddress(_proxy) isProxyOwner(_proxy) {
    address _delivery = registryItems[_proxy].delivery;
    delete registryItems[_proxy];
    emit proxyItemDeleted(_proxy, msg.sender, _delivery, block.timestamp);
  }
}