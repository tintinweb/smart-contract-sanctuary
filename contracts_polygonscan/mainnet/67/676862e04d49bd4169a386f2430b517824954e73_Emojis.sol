// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract Emojis is ERC721Enumerable, Ownable {

  uint256 public constant MAX_EMOJIS = 10000;



  event Minted(address indexed from, address indexed to, uint256 indexed tokenId, uint256 amount);

  constructor() ERC721('Have a Nice Days Friends', 'HNDF'){
  }

  function mintEmoji(uint256 numberOfTokens) public onlyOwner  {
    require (totalSupply() + numberOfTokens <= MAX_EMOJIS, 'Cant mint another friend');
    _mintEmoji(numberOfTokens, owner());
  }

  function _mintEmoji(uint256 numberOfTokens, address sender) internal {
    for(uint i = 0; i < numberOfTokens; i++) {
        uint mintIndex = totalSupply()+1;
        _safeMint(sender, mintIndex);
        emit Minted(address(0), sender, mintIndex, numberOfTokens);
    }

  }

  function withdraw() public {
      uint balance = address(this).balance;
      payable(owner()).transfer(balance);
  }



}