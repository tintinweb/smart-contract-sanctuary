// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IERC721, ERC721, ERC721Enumerable, Ownable, ProxyRegistry } from './FlatDependencies.sol';

contract DeadFellazToken is IERC721, Ownable, ERC721Enumerable {
  uint public constant PRICE = 0.025 ether;

  uint public constant MAX_SUPPLY = 10_000;

  uint public constant MAX_MINT_AMOUNT = 13;

  uint public constant MAX_PRIZE_MINTS = 2_000;

  string private _contractURI = "https://ipfs.io/ipfs/QmdUf9eYuXxmKuE34ZLNzzghD9gyUE8HEknrbgPLMbfBQU";

  string public baseURI = "https://dead-fellaz-api.vercel.app/traits/";

  address public immutable proxyRegistryAddress;

  constructor(
    address _proxyRegistryAddress
  ) ERC721('DeadFellaz Testnet 2', 'DEADFELLATESTNET2') {
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

  function mintPrizes(uint amount) public onlyOwner {
    uint currentTotalSupply = totalSupply();

    /// @notice Prize mints must mint first, and cannot be minted after the maximum has been reached
    require(currentTotalSupply < MAX_PRIZE_MINTS, "DeadFellazToken: Max prize mint limit reached");

    if (currentTotalSupply + amount > MAX_PRIZE_MINTS){
      amount = MAX_PRIZE_MINTS - currentTotalSupply;
    }

    _mintAmountTo(msg.sender, amount, currentTotalSupply);

  }

  function mint(uint amount) public payable {
    uint currentTotalSupply = totalSupply();

    /// @notice public can mint only when the maximum prize mints have been minted
    // require(currentTotalSupply >= MAX_PRIZE_MINTS, "DeadFellazToken: Not yet launched");

    /// @notice Cannot exceed maximum supply
    require(currentTotalSupply+amount <= MAX_SUPPLY, "DeadFellazToken: Not enough mints remaining");

    /// @notice public can mint mint a maximum quantity at a time.
    require(amount <= MAX_MINT_AMOUNT, 'DeadFellazToken: mint amount exceeds maximum');


    /// @notice public must send in correct funds
    require(msg.value == amount * PRICE, "DeadFellazToken: Not enough value sent");

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

  function withdraw() public onlyOwner {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "DeadFellazToken: Withdraw unsuccessful");
  }
}