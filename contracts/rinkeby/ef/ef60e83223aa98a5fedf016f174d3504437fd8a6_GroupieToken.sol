// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IERC721, ERC721, ERC721Enumerable, Ownable, ProxyRegistry } from './FlatDependencies.sol';

contract GroupieToken is IERC721, Ownable, ERC721Enumerable {
  uint public constant PRICE = 0.09 ether;

  uint public constant MAX_SUPPLY = 10_000;

  uint public constant MAX_MINT_AMOUNT = 10;

  uint public ownerMintsRemaining = 150;

  string private _contractURI = "ipfs://QmPKHMpVnFiGUWLAghwX2jjFaFDhjKdvi55u7oqUhUDHZL";

  string public baseURI = "ipfs://QmdzsKcQDWFDVbsJLTgqV8nAShWTuuoBGNwxn33MQUmfJh/";

  address public immutable proxyRegistryAddress;

  constructor(
    address _proxyRegistryAddress
  ) ERC721('Groupies TEST', 'GROUPIE TEST') {
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
    /// @notice public can mint mint a maximum quantity at a time.
    require(amount <= MAX_MINT_AMOUNT, 'GroupieToken: mint amount exceeds maximum');

    uint currentTotalSupply = totalSupply();

    /// @notice Cannot exceed maximum supply
    require(currentTotalSupply+amount+ownerMintsRemaining <= MAX_SUPPLY, "GroupieToken: Not enough mints remaining");

    /// @notice public must send in correct funds
    require(msg.value > 0 && msg.value == amount * PRICE, "GroupieToken: Not enough value sent");

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

  /// @notice Sends balance of this contract to owner
  function withdraw() public onlyOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "GroupieToken: Withdraw unsuccessful");
  }
}