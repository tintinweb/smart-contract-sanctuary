// SPDX-License-Identifier: The Unlicense
// @Title Tron Bulls
// @Author Tron Bull's Team

pragma solidity >=0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract hft is ERC721Enumerable, Ownable {
  using Strings for uint256;
  

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.01 ether; //edit this cost
  uint256 public maxSupply = 100;
  uint256 public maxMintAmount = 10; //edit max mint amount
  mapping(address => bool) public whitelisted;
  bool private forsale = false;
  uint internal nonce = 0;
  uint [100] internal indices;  //update with max supply

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    //mint(msg.sender, 20);  //mint initial amount
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function randomIndex() internal returns (uint) {
        uint totalSize = maxSupply - totalSupply();
        uint index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint value = 0;
        uint value2 = value;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        value2 = value + 1;
        return value2;
    }

  // public
   function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(forsale == true, "Not for sale yet!");
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount, "Can not mint more than the 10 at a given time");
    require(supply + _mintAmount <= maxSupply, "Not enough tokens available");
 
    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= cost*(_mintAmount), "Value below price");
        }
    }

    for(uint256 i = 0; i < _mintAmount; i++) {
            uint mintIndex = randomIndex();
            if (totalSupply() < maxSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    /*    
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }*/
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
    function toggleForSale() public onlyOwner {
        forsale = !forsale;
    }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}