pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Ownable.sol";
import "./RandomlyAssigned.sol";

// WeMint Washington Edition ERC721 

// Calling mint mints a random  Washington until 10,000 have been minted
// Mint costs 0.0003 Ether ($1)
// 50 Kept for artist, developer & giveaways

// WeMint.Cash 

contract WeMintCash is ERC721, Ownable, RandomlyAssigned {
  using Strings for uint256;
  // uint256 public requested;
  uint256 public currentSupply = 0;
  
  string public baseURI = "https://ipfs.io/ipfs/QmcmxU24WqUwoFeXrnU1PWYW4BbxwDmKmgprJ3yesxsZLj/";

  constructor() 
    ERC721("WeMint Washington", "WASHINGTON")
    RandomlyAssigned(10000,1) // Max. 10000 NFTs available; Start counting from 1 (instead of 0)
    {
       for (uint256 a = 1; a <= 50; a++) {
            mint(msg.sender);
        }
    }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

    
  function mint (address _to)
      public
      payable
  {
      require( tokenCount() + 1 <= totalSupply(), "YOU CAN'T MINT MORE THAN MAXIMUM SUPPLY");
      require( availableTokenCount() - 1 >= 0, "YOU CAN'T MINT MORE THAN AVALABLE TOKEN COUNT"); 
      require( tx.origin == msg.sender, "CANNOT MINT THROUGH A CUSTOM CONTRACT");

      if (msg.sender != owner()) {  
        require( msg.value >= 0.0003 ether);
        require( balanceOf(msg.sender) <= 1);
        require( balanceOf(_to) <= 1);
      }
      
      uint256 id = nextToken();
        _safeMint(_to, id);
        currentSupply++;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistant token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }
  
  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}