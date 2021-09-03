// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IERC721, ERC721, ERC721Enumerable, Ownable, ProxyRegistry } from './FlatDependencies.sol';

contract GroupieToken is IERC721, Ownable, ERC721Enumerable {
  uint public constant START_PRICE = 1.9608 ether;

  uint public constant END_PRICE = 0.06 ether;

  uint public startTime;

  uint public immutable DURATION;

  uint public immutable PRICE_PER_SECOND;

  uint public constant MAX_SUPPLY = 10_000;

  uint public constant MAX_MINT_AMOUNT = 10;

  uint public ownerMintsRemaining = 150;

  string private _contractURI = "ipfs://QmPKHMpVnFiGUWLAghwX2jjFaFDhjKdvi55u7oqUhUDHZL";

  string public baseURI = "";

  address public immutable proxyRegistryAddress;

  uint public constant decimals = 0;

  event Receipt(address indexed to, uint price, uint amount, uint cost, uint sent, uint change);

  constructor(
    uint durationInHours,
    address _proxyRegistryAddress
  ) ERC721('Groupies TEST', 'GROUPIE TEST') {
    DURATION = durationInHours * 60 * 60;
    PRICE_PER_SECOND = (START_PRICE - END_PRICE) / (durationInHours * 60 * 60);
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {

      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

      // Whitelist OpenSea proxy contract for easy trading.
      if (proxyRegistry.proxies(owner) == operator) {
          return true;
      }
      return super.isApprovedForAll(owner, operator);
  }

  function start() public onlyOwner {
    require(startTime == 0, 'GroupieToken: Already started');
    startTime = block.timestamp;
  }


  /// @notice Reserved mints for owner
  function ownerMint(uint amount) public onlyOwner {

    uint mintsRemaining = ownerMintsRemaining;

    /// @notice Owner mints cannot be minted after the maximum has been reached
    require(mintsRemaining > 0, "GroupieToken: Max owner mint limit reached");

    if (amount > mintsRemaining){
      amount = mintsRemaining;
    }

    _mintAmountTo(msg.sender, amount, totalSupply());

    ownerMintsRemaining = mintsRemaining - amount;

  }

  /// @notice Public mints
  function mint(uint amount) public payable {
    require(startTime > 0 && block.timestamp >= startTime, 'GroupieToken: not yet launched');

    /// @notice public can mint mint a maximum quantity at a time.
    require(amount <= MAX_MINT_AMOUNT, 'GroupieToken: mint amount exceeds maximum');

    uint currentTotalSupply = totalSupply();

    /// @notice Cannot exceed maximum supply
    require(currentTotalSupply+amount+ownerMintsRemaining <= MAX_SUPPLY, "GroupieToken: Not enough mints remaining");

    uint price = priceAtTime(block.timestamp);

    uint cost = amount * price;

    /// @notice public must send in correct funds
    require(msg.value > 0 && msg.value >= cost, "GroupieToken: Not enough value sent");

    if (msg.value > cost){
      uint change = msg.value - cost;
      (bool success, ) = msg.sender.call{value: change}("");
      require(success, "GroupieToken: Change send unsuccessful");
      emit Receipt(msg.sender, price, amount, cost, msg.value, change);
    } else {
      emit Receipt(msg.sender, price, amount, cost, msg.value, 0);
    }

    _mintAmountTo(msg.sender, amount, currentTotalSupply);
  }

  function _mintAmountTo(address to, uint amount, uint startId) internal {
    for (uint i = 1; i<=amount; i++){
      _mint(to, startId+i);
    }
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function _baseURI() internal override view returns (string memory){
    return baseURI;
  }

  function setContractURI(string memory newContractURI) external onlyOwner {
    _contractURI = newContractURI;
  }

  function contractURI() external view returns (string memory){
    return _contractURI;
  }

  function currentPrice() public view returns (uint){
    return priceAtTime(block.timestamp);
  }

  function priceAtTime(uint time) public view returns (uint){
    uint _startTime = startTime;

    if (_startTime == 0 || time <= _startTime) return START_PRICE;

    if (time >= _startTime + DURATION) return END_PRICE;

    /// @notice Calculate the price decrease since start and subtract it from the starting price
    return START_PRICE - (PRICE_PER_SECOND * (time - _startTime));
  }

  function endTime() public view returns (uint){
    if (startTime == 0) return 0;
    return startTime + DURATION;
  }

  /// @notice Sends balance of this contract to owner
  function withdraw() public onlyOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "GroupieToken: Withdraw unsuccessful");
  }

  function details() public view returns(uint _startTime, uint _endTime, uint _duration, uint _startPrice, uint _endPrice, uint _priceSecond, uint _priceAtBlock, uint _blockTimestamp){
    return (startTime, endTime(), DURATION, START_PRICE, END_PRICE, PRICE_PER_SECOND, priceAtTime(block.timestamp), block.timestamp);
  }

}