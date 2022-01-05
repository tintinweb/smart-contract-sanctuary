// SPDX-License-Identifier: MIT

// Created by MoBoosted
// Surelock Holmes

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract SurelockHolmesNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string private _baseTokenURI;
  string private _ipfsBaseURI;
  mapping (uint256 => address ) public minter;
  mapping(uint256 => string) _tokenURIs;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 500 ether; //500 Rugpull
  uint256 public maxSupply = 150;
  bool public paused = false;
  mapping(address => bool) public whitelisted;

  struct RenderToken {
    uint256 id;
    string uri;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    _baseTokenURI = "";
    _ipfsBaseURI = _initBaseURI;
    cost =  500 ether; // 500 Rugpull
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


  // public
  function mint(address _to, uint256 _mintAmount, string memory uri) public {
    uint256 supply = _tokenIds.current();
    require(!paused, "Unable to mint right now - Minting has been Paused");
    require(_mintAmount > 0, "Mint amount has to be more than 0");
    require(supply < maxSupply + 1, "Maximum NFTS have been minted");

    for (uint256 i = 1; i <= _mintAmount; i++) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
      _safeMint(_to, newTokenId);
      _setTokenURI(newTokenId, uri);
    }
  }

  function tokenMinter(uint256 tokenId) public view returns(address){
    return minter[tokenId];
  }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId);
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

  function getMyTokens(address user)
    public
    view
    returns (RenderToken[] memory)
  {
    uint256 tokenCount = balanceOf(user);
    RenderToken[] memory tokens = new RenderToken[](tokenCount+1);
    for (uint256 i = 0; i < tokenCount; i++) {
        uint256 nftid = tokenOfOwnerByIndex(user, i);
        string memory uri = tokenURI(nftid);
        tokens[i] = RenderToken(nftid, uri);
    }
    return tokens;
  }

  function getNFT(uint256 nftid)
    public
    view
    returns (string memory)
  {
    string memory uri = tokenURI(nftid);
    return uri;
  }

  function getAllTokens() public view returns (RenderToken[] memory) {
    uint256 lastestId = totalSupply();
    uint256 counter = 0;
    RenderToken[] memory res = new RenderToken[](lastestId);
    for (uint256 i = 0; i < lastestId; i++) {
      if (_exists(counter)) {
        string memory uri = tokenURI(counter);
        res[counter] = RenderToken(counter, uri);
      }
      counter++;
    }
    return res;
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
    _tokenURIs[tokenId] = _tokenURI;
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

    string memory _tokenURI = _tokenURIs[tokenId];
    return _tokenURI;

  }


//only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }


}