pragma solidity ^0.8.0;

import './ERC721.sol';

contract NFT is ERC721 {
  uint public nextTokenId;
  uint public availableTokens;
  address public admin;
  mapping(uint256 => string) private _meta;

  constructor() ERC721('Gosho the Market', 'GHSO') {
    admin = msg.sender;
    _meta[availableTokens++] = "QmPtQeKGmho6weFyePrZwiBuxbLsa18NjwaiV95AVa831U";
    _meta[availableTokens++] = "QmSMCWKmjBUZZk22eSCYiiPxY796JXrbTqJsZ6sNwfNs3A";
  }
  
  function mint(address to) external {
    require(msg.sender == admin, 'only admin');
    require(nextTokenId < availableTokens);
    _safeMint(to, nextTokenId);
    nextTokenId++;
  }

  function _baseURI() internal view override returns (string memory) {
    return 'ipfs://';
  }

  function tokenURI(uint256 availableTokens) public view virtual override returns (string memory) {
    require(_exists(availableTokens), "ERC721Metadata: URI query for nonexistent token");
    // return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    return string(abi.encodePacked(_baseURI(), _meta[availableTokens]));
  }

  function createNft(string memory CID) external {
    require(msg.sender == admin, 'only admin');
    _meta[availableTokens++] = CID;
  }
}