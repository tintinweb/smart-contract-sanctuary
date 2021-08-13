// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import { Ownable, ERC721, ERC721Enumerable } from './FlatDependencies.sol';

contract DeadFellazToken is Ownable, ERC721Enumerable {
  uint public constant PRICE = 0.025 ether;

  uint public constant MAX_SUPPLY = 10_000;

  uint public constant MAX_MINT_AMOUNT = 13;

  uint public remainingPrizeMints = 2_000;

  uint public remainingPublicMints = 10_000 - remainingPrizeMints;

  string private _contractURI = "https://ipfs.io/ipfs/QmdUf9eYuXxmKuE34ZLNzzghD9gyUE8HEknrbgPLMbfBQU";

  string private __baseURI = "https://ipfs.io/ipfs/QmZqi1cq2cCnZrzZFKZJwiaJkj98XerMRowoP1PfLtJB3q/";

  constructor() ERC721('DeadFellaz Testnet', 'DEADFELLATESTNET') {}

  function mint(uint amount) public payable {
    address _owner = owner();

    bool isOwner = msg.sender == _owner;

    require(isOwner || amount <= MAX_MINT_AMOUNT, 'DeadFellazToken: mint amount exceeds maximum');

    require(isOwner || msg.value == amount * PRICE, "DeadFellazToken: Not enough value sent");

    uint currentTotalSupply = totalSupply();

    if (isOwner) {
      require(amount + remainingPublicMints + currentTotalSupply <= MAX_SUPPLY, "DeadFellazToken: Not enough prize mints remaining");
      remainingPrizeMints = remainingPrizeMints - amount;
    } else {
      require(amount + remainingPrizeMints + currentTotalSupply <= MAX_SUPPLY, "DeadFellazToken: Not enough mints remaining");
      remainingPublicMints = remainingPublicMints - amount;
    }

    for (uint i = 1; i<=amount; i++){
      _mint(msg.sender, currentTotalSupply+i);
    }

    // Sanity check
    require(totalSupply()<=MAX_SUPPLY, 'DeadFellazToken: Max supply exceeded');
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    __baseURI = newBaseURI;
  }

  function _baseURI() internal override view returns (string memory){
    return __baseURI;
  }

  function setContractURI(string memory newContractURI) external onlyOwner {
    _contractURI = newContractURI;
  }

  function contractURI() external view returns (string memory){
    return _contractURI;
  }

  function withdraw() external {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "DeadFellazToken: Withdraw unsuccessful");
  }
}