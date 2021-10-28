// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";

/*
########################################################################################
###########........#############################%==%%###################################
#######..............##########==+:*==########==:..-*=#####.........................####
######................########==.....==#######%:.....==###...........................###
#####........##........########=-....*=#######%-....:=####...........................###
#####.......####.......########%=-...*=#######%*...*=#######....###...............######
#####......######......##########=*..+=#######=+..+=##############........##############
#####......######......###########=:.*=%######=:.-=%##############.......###############
#####......######......###########=*..-=%####=:...=%#############.......################
#####......######......###########=*...-=###=*....==############.......#################
#####.......####.......###########==....==###+...-=############........#################
#####..................####===+==##=+...==###=-..+=###########........#######.......####
#####.................####=:....==##=*.-==##==..*=############........######........####
#####.................####==-...:==#=*...+==*...+=###########........#######........####
####.......#####......######=+...**-..-:*+====-..==##########........#######........####
####.......#####......######==*-..............*+.-=##########.......#########.......####
####.......#####......######=-.......:**-.......*-+#########........#########.......####
####.......#####......#######=*::*==*=-.-*==*-....==########........#########.......####
####.......####........#######=:+-....*=...*=......=########.........#######.......#####
###.........###........#######%=.=....-=-....:-...:=#########........#######.......#####
###.........###........########=:.*===*..........*=##########.........#####........#####
###.........###........#########=........-......*=############....................######
###.........###........#########%=-......+:.....==#############.................########
####.......#####......###########%==+*======*-:==################.............##########
########################################################################################
*/
contract AlienVibeTribe is ERC721Enumerable, Ownable {
  using Strings for uint256;
    
  string public baseURI = "https://dosnhnysc7knz.cloudfront.net/contract/metadata/";
  string private _contractURI = "https://dosnhnysc7knz.cloudfront.net/contract/avt.json";
  uint256 public price = 0.07 ether;
  uint256 public maxSupply = 5551;
  bool public isMintingActive = false;

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

  function mint(uint256 _mintAmount) public payable {
    require(isMintingActive, "Minting is not allowed");
    require(_mintAmount <= 20, "max 20 tokens at once");
	require(price * _mintAmount == msg.value, "insufficient ETH");
    uint256 supply = totalSupply();
    require(maxSupply - supply >= _mintAmount, "overflow of maximum total supply");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }
  
  function mintOwner(uint256 _mintAmount) public onlyOwner {
    require(isMintingActive, "Minting is not allowed");
    require(_mintAmount <= 20, "max 20 tokens at once");
    uint256 supply = totalSupply();
    require(maxSupply - supply >= _mintAmount, "overflow of maximum total supply");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory uri = _baseURI();
    return bytes(uri).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
  }

  function setItemPrice(uint256 _price) public onlyOwner {
	price = _price;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function setContractURI(string memory newContractURI) public onlyOwner {
	_contractURI = newContractURI;
  }
  
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function withdraw() public onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
  
  function reclaimToken(IERC20 token) public onlyOwner {
	require(address(token) != address(0));
	uint256 balance = token.balanceOf(address(this));
    token.transfer(msg.sender, balance);
  }
  
  function setIsActiveMinting(bool isActive) public onlyOwner {
	isMintingActive = isActive;
  }
  
  function setMaxSupply(uint256 max) public onlyOwner {
	maxSupply = max;
  }
}