// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract DreamscapesNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public price = 0.07 ether;
  uint256 public maxSupply = 5000;
  uint256 public maxMintAmount = 7;
  uint256 public nftPerAddressLimit = 3;
  string public provenance = "";
  bool public salePaused = false;
  bool public preSaleOnly = true;
  bool public revealed = false;
  string public notRevealedUri;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;
  address payable public payments;
  uint256 supply = totalSupply();
  address team1 = 0x889549315C4e407C66F657C889546C7D601c33A7; // R
  address team2 = 0x72955DA661419619BA017B1cd71530A9724b9bdc; // J
  address team3 = 0xdF6769E7fCF7D3DF3c1d488CE4AdD0df9a1AC9a6; // N
  address team4 = 0x42cD50b383d6098688BaB8a68a2feCC8e8EB7367; // C
  address team5 = 0x451ba8e9c27D101e769bC291E487F71425A39D2d ; // Z
  address giveaway = 0xc5bbC6ad9B7d201EF24d27548E58800CD477563d; // DS

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address _payments
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    payments = payable(_payments);
    mint(giveaway, 7);
    mint(giveaway, 7);
    mint(giveaway, 6);
    mint(team1, 1);
    mint(team2, 1);
    mint(team3, 1);
    mint(team4, 1);
    mint(team5, 1);
    setSalePaused(true);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _toAddress, uint256 _mintAmount) public payable {
    require(!salePaused, "the contract is paused");
    supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(preSaleOnly == true) {
            require(isWhitelisted(_toAddress), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[_toAddress];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= price * _mintAmount, "insufficient funds");
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[_toAddress]++;
      _safeMint(_toAddress, supply + i);
    }
  }
  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

 function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return bytes(notRevealedUri).length > 0
        ? string(abi.encodePacked(notRevealedUri, tokenId.toString(), baseExtension))
        : "";
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  // Only owner

  function reveal() public onlyOwner {
    revealed = true;
  }

  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    provenance = provenanceHash;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }
  
  function setPrice(uint256 _newPrice) public onlyOwner() {
    price = _newPrice;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setSalePaused(bool _state) public onlyOwner {
    salePaused = _state;
  }
  
  function setPreSaleOnly(bool _state) public onlyOwner {
    preSaleOnly = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(payments).call{value: address(this).balance}("");
    require(success);
  }
}