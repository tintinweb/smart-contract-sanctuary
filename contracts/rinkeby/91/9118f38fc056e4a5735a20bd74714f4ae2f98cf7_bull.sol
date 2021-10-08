// SPDX-License-Identifier: The Unlicense
// @Title Tron Bulls
// @Author Tron Bull's Team

pragma solidity >=0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract bull is ERC721Enumerable, Ownable {
  using Strings for uint256;
  

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.01 ether; //edit this cost
  uint256 public maxSupply = 15012;
  uint256 public maxMintAmount = 25; //edit max mint amount
  mapping(address => bool) public whitelisted;
  mapping(address => bool) public whitelisted2;
  mapping(address => bool) public whitelisted3;
  mapping(address => bool) public whitelisted4;
  bool private forsale = false;
  uint internal nonce = 0;
  uint [15012] internal indices;  //update with max supply
  mapping(address => uint256) public addressMintedBalance;
  uint256 public nftPerAddressLimit = 25;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function isWhiteListed() internal view virtual returns (bool){
      if(whitelisted[msg.sender] == true) {
          return true;
      }
      return false;
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
    if(msg.sender != owner()){
    require(forsale == true, "Not for sale yet!");
    require(_mintAmount <= maxMintAmount, "Can not mint more than the 10 at a given time");
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
    }
    require(_mintAmount > 0);
    require(supply + _mintAmount <= maxSupply, "Not enough tokens available");
 
    
    if(msg.sender != owner()){
          require(msg.value >= cost*(_mintAmount), "Value below price");
        }
    

    for(uint256 i = 0; i < _mintAmount; i++) {
            uint mintIndex = randomIndex();
            if (totalSupply() < maxSupply) {
                 addressMintedBalance[msg.sender]++;
                _safeMint(msg.sender, mintIndex);
            }
        }
  }
  
function mintWhitelisted() public {
    uint256 supply = totalSupply();
    require(forsale == true, "Not for sale yet!");
    require(supply + 1 <= maxSupply, "Not enough tokens available");
    require(isWhiteListed());
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + 1 <= nftPerAddressLimit, "max NFT per address exceeded");
    uint mintIndex = randomIndex();
    
    
        if(whitelisted2[msg.sender]==true){
            if(whitelisted3[msg.sender] ==true){
                if(whitelisted4[msg.sender]==true){
                    for(uint256 i=0 ; i<=3; i++){
                    mintIndex = randomIndex();
                        if (totalSupply() < maxSupply) {
                             addressMintedBalance[msg.sender]++;
                             _safeMint(msg.sender, mintIndex);
                          }
                    }
                }
                else{
                     for(uint256 i=0 ; i<=2; i++){
                         mintIndex = randomIndex();
                        if (totalSupply() < maxSupply) {
                             addressMintedBalance[msg.sender]++;
                             _safeMint(msg.sender, mintIndex);
                          }
                    }
                }
            }
            
            else{
                for(uint256 i=0 ; i<=1; i++){
                     mintIndex = randomIndex();
                        if (totalSupply() < maxSupply) {
                             addressMintedBalance[msg.sender]++;
                             _safeMint(msg.sender, mintIndex);
                          }
                    }
            }
        }
        
        else{
            mintIndex = randomIndex();
            if (totalSupply() < maxSupply) {
                    addressMintedBalance[msg.sender]++;
                    _safeMint(msg.sender, mintIndex);
                          }
        }
    
    
    whitelisted[msg.sender] = false; 
    whitelisted2[msg.sender] = false; 
    whitelisted3[msg.sender] = false; 
    whitelisted4[msg.sender] = false; 
    
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

  function whitelistUser(uint256 _amountgiven, address _user) public onlyOwner {
  if(_amountgiven == 1){
    whitelisted[_user] = true;
    }
    
    else if(_amountgiven == 2){
     whitelisted[_user] = true;  
     whitelisted2[_user] = true;
    }
    
    else if(_amountgiven == 3){
     whitelisted[_user] = true;  
     whitelisted2[_user] = true;
     whitelisted3[_user] = true;
    }
    
    else if(_amountgiven == 4){
     whitelisted[_user] = true;  
     whitelisted2[_user] = true;
     whitelisted3[_user] = true;
     whitelisted4[_user] = true;
    }
  }
  

  function withdraw() public onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}