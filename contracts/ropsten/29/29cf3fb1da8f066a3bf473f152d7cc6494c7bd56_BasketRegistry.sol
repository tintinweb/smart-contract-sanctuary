/*

  Copyright 2018 CoinAlpha, Inc.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.4.21;

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

/**
  * @title BasketRegistry -- Storage contract to keep track of all baskets created
  * @author CoinAlpha, Inc. <contact@coinalpha.com>
  */
contract BasketRegistry {
  using SafeMath for uint;

  // Constants set at contract inception
  address                           public admin;
  mapping(address => bool)          public basketFactoryMap;

  uint                              public basketIndex;           // Baskets index starting from index = 1
  address[]                         public basketList;
  mapping(address => BasketStruct)  public basketMap;
  mapping(address => uint)          public basketIndexFromAddress;

  uint                              public arrangerIndex;         // Arrangers register starting from index = 1
  address[]                         public arrangerList;
  mapping(address => uint)          public arrangerBasketCount;
  mapping(address => uint)          public arrangerIndexFromAddress;

  // Structs
  struct BasketStruct {
    address   basketAddress;
    address   arranger;
    string    name;
    string    symbol;
    address[] tokens;
    uint[]    weights;
    uint      totalMinted;
    uint      totalBurned;
  }

  // Modifiers
  modifier onlyBasket {
    require(basketIndexFromAddress[msg.sender] > 0); // Check: "Only a basket can call this function"
    _;
  }
  modifier onlyBasketFactory {
    require(basketFactoryMap[msg.sender] == true);   // Check: "Only a basket factory can call this function"
    _;
  }

  // Events
  event LogWhitelistBasketFactory(address basketFactory);
  event LogBasketRegistration(address basketAddress, uint basketIndex);
  event LogIncrementBasketsMinted(address basketAddress, uint quantity, address sender);
  event LogIncrementBasketsBurned(address basketAddress, uint quantity, address sender);

  /// @dev BasketRegistry constructor
  function BasketRegistry() public {
    basketIndex = 1;
    arrangerIndex = 1;
    admin = msg.sender;
  }

  /// @dev Set basket factory address after deployment
  /// @param  _basketFactory                       Basket factory address
  /// @return success                              Operation successful
  function whitelistBasketFactory(address _basketFactory) public returns (bool success) {
    require(msg.sender == admin);                  // Check: "Only an admin can call this function"
    basketFactoryMap[_basketFactory] = true;
    emit LogWhitelistBasketFactory(_basketFactory);
    return true;
  }

  /// @dev Add new basket to registry after being created in the basketFactory
  /// @param  _basketAddress                       Address of deployed basket
  /// @param  _arranger                            Address of basket admin
  /// @param  _name                                Basket name
  /// @param  _symbol                              Basket symbol
  /// @param  _tokens                              Token address array
  /// @param  _weights                             Weight ratio array
  /// @return basketIndex                          Index of basket in registry
  function registerBasket(
    address   _basketAddress,
    address   _arranger,
    string    _name,
    string    _symbol,
    address[] _tokens,
    uint[]    _weights
  )
    public
    onlyBasketFactory
    returns (uint index)
  {
    basketMap[_basketAddress] = BasketStruct(
      _basketAddress, _arranger, _name, _symbol, _tokens, _weights, 0, 0
    );
    basketList.push(_basketAddress);
    basketIndexFromAddress[_basketAddress] = basketIndex;

    if (arrangerBasketCount[_arranger] == 0) {
      arrangerList.push(_arranger);
      arrangerIndexFromAddress[_arranger] = arrangerIndex;
      arrangerIndex = arrangerIndex.add(1);
    }
    arrangerBasketCount[_arranger] = arrangerBasketCount[_arranger].add(1);

    emit LogBasketRegistration(_basketAddress, basketIndex);
    basketIndex = basketIndex.add(1);
    return basketIndex.sub(1);
  }

  /// @dev Check if basket exists in registry
  /// @param  _basketAddress                       Address of basket to check
  /// @return basketExists
  function checkBasketExists(address _basketAddress) public view returns (bool basketExists) {
    return basketIndexFromAddress[_basketAddress] > 0;
  }

  /// @dev Retrieve basket info from the registry
  /// @param  _basketAddress                       Address of basket to check
  /// @return basketDetails
  function getBasketDetails(address _basketAddress)
    public
    view
    returns (
      address   basketAddress,
      address   arranger,
      string    name,
      string    symbol,
      address[] tokens,
      uint[]    weights,
      uint      totalMinted,
      uint      totalBurned
    )
  {
    BasketStruct memory b = basketMap[_basketAddress];
    return (b.basketAddress, b.arranger, b.name, b.symbol, b.tokens, b.weights, b.totalMinted, b.totalBurned);
  }

  /// @dev Look up a basket&#39;s arranger
  /// @param  _basketAddress                       Address of basket to check
  /// @return arranger
  function getBasketArranger(address _basketAddress) public view returns (address) {
    return basketMap[_basketAddress].arranger;
  }

  /// @dev Increment totalMinted from BasketStruct
  /// @param  _quantity                            Quantity to increment
  /// @param  _sender                              Address that bundled tokens
  /// @return success                              Operation successful
  function incrementBasketsMinted(uint _quantity, address _sender) public onlyBasket returns (bool) {
    basketMap[msg.sender].totalMinted = basketMap[msg.sender].totalMinted.add(_quantity);
    emit LogIncrementBasketsMinted(msg.sender, _quantity, _sender);
    return true;
  }

  /// @dev Increment totalBurned from BasketStruct
  /// @param  _quantity                            Quantity to increment
  /// @param  _sender                              Address that debundled tokens
  /// @return success                              Operation successful
  function incrementBasketsBurned(uint _quantity, address _sender) public onlyBasket returns (bool) {
    basketMap[msg.sender].totalBurned = basketMap[msg.sender].totalBurned.add(_quantity);
    emit LogIncrementBasketsBurned(msg.sender, _quantity, _sender);
    return true;
  }

  /// @dev Fallback to reject any ether sent to contract
  //  CHeck: "BasketRegistry does not accept ETH transfers"
  function () public payable { revert(); }
}