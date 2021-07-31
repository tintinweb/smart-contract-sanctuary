// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TiredUnicorns is ERC721Enumerable, Ownable {

   using Strings for uint256;

   string _baseTokenURI;
   string _metadataExtension = "";

   string public METADATA_PROVENANCE_HASH = "";

   string private _baseContractURI;
   uint16 private _reserved = 300;
   uint16 public constant MAX_UNICORNS = 12000;
   uint256 private _price = 0.02 ether;
   bool public _paused = false;

   // Optional mapping for token URIs
   mapping(uint256 => string) private _tokenURIs;

   constructor(string memory baseURI, string memory baseContractURI) ERC721("Tired Unicorns", "UNICORNS")  {
      
      setBaseURI(baseURI);
      setContractURI(baseContractURI);

      // team gets 2 unicorns:)
      _safeMint(owner(), 0);
      _safeMint(owner(), 1);
   }
   
   function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
   }

   function contractURI() public view returns (string memory) {
      return _baseContractURI;
   }

   /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      string memory _tokenURI = _tokenURIs[tokenId];
      string memory base = _baseURI();

      // If there is no base URI, return the token URI.
      if (bytes(base).length == 0) {
            return _tokenURI;
      }
      // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
      if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI, _metadataExtension));
      }
      // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
      return string(abi.encodePacked(base, tokenId.toString(), _metadataExtension));
   }

   function getMetadataExtension() public view returns(string memory) {
      return _metadataExtension;
   }

   function adoptUnicorn(uint8 num) public payable {
      uint256 supply = totalSupply();
      require( !_paused,                                  "Sale paused" );
      require( num > 0 && num < 21,                       "You can adopt a maximum of 20 unicorn and minimum 1" );
      require( supply + num < MAX_UNICORNS - _reserved,   "Exceeds maximum Unicorns supply" );
      require( msg.value >= _price * num,                 "Ether sent is not correct" );

      for(uint8 i; i < num; i++){
         _safeMint( msg.sender, supply + i );
      }
   }

   function tokensOfOwner(address _owner) public view returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);

      if(tokenCount == 0) {
         return new uint256[](0);
      }
      else {
         uint256[] memory tokensId = new uint256[](tokenCount);
         for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
         }
         return tokensId;
      }
   }

   function getPrice() public view returns (uint256) {
      return _price;
   }

   function getReservedCount() public view returns (uint16) {
      return _reserved;
   }

   function setProvenanceHash(string memory _hash) public onlyOwner {
      METADATA_PROVENANCE_HASH = _hash;
   }

   function setContractURI(string memory baseContractURI) public onlyOwner {
      _baseContractURI = baseContractURI;
   }

   function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
   }

   /**
    * @dev Internal function to set the token URI for a given token.
    * Reverts if the token ID does not exist.
    * @param tokenId uint256 ID of the token to set its URI
    * @param uri string URI to assign
    */
   function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
      require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
      _tokenURIs[tokenId] = uri;
   }

   function setMetadataExtension(string memory str) public onlyOwner {
      _metadataExtension = str;
   }

   function setPrice(uint256 _newPrice) public onlyOwner {
     _price = _newPrice;
   }

   function reserveAirdrop(address _to, uint8 _amount) external onlyOwner {
      require( _amount <= _reserved, "Exceeds reserved Unicorn supply" );

      uint256 supply = totalSupply();
      for(uint8 i; i < _amount; i++){
         _safeMint( _to, supply + i );
      }

      _reserved -= _amount;
   }

   function pauseSale(bool val) public onlyOwner {
      _paused = val;
   }

   function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
   }
}