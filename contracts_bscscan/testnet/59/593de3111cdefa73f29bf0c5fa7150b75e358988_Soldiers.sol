// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Contracts
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SoldiersDNA.sol";
//Libraries
import "./Counters.sol";
import "./Strings.sol";
import "./Base64.sol";
  

contract Soldiers is ERC721("Soldier", "SOLD"), ERC721Enumerable, SoldiersDNA {
  using Counters for Counters.Counter;
  using Strings for uint;
  uint256 public mintPrice = 25000000 gwei; //Mint Price
  Counters.Counter private _tokenId;

  uint public maxSupply; 
  mapping (uint  => uint) tokenDNAList;

  constructor(uint _limitSupply){
    maxSupply = _limitSupply;
  }

  function mintToken() public payable {
    uint currTokenId = _tokenId.current();
    require(mintPrice <= msg.value, "BNB value sent is not correct");
    require(currTokenId < maxSupply, "No Soldier Left, sorry!");

    _mint(msg.sender, currTokenId);
    tokenDNAList[currTokenId] = generatePseudoRandomDNA(currTokenId, msg.sender);

    _tokenId.increment();
  }

  function _baseURI() internal pure override returns (string memory){
    return "https://avataaars.io/";
  }

  function _paramsURI(uint _dna) private view returns (string memory){
    string memory params;

    { 
      params = string(abi.encodePacked(
        "?accessoriesType=",
        getAccessoriesType(_dna),
        "&clotheColor=",
        getClotheColor(_dna),
        "&clotheType=",
        getClotheType(_dna),
        "&eyeType=",
        getEyeType(_dna),
        "&eyebrowType=",
        getEyeBrowType(_dna),
        "&facialHairColor=",
        getFacialHairColor(_dna),
        "&facialHairType=",
        getFacialHairType(_dna),
        "&hairColor=",
        getHairColor(_dna),
        "&hatColor=",
        getHatColor(_dna),
        "&mouthType=",
        getMouthType(_dna),
        "&skinColor=",
        getSkinColor(_dna),
        "&graphicType=",
        getGraphicType(_dna)
      ));
    }

    return string(abi.encodePacked(params,"&topType=",getTopType(_dna)));
  }

  function getImageURI(uint _dna) public view returns (string memory){
    string memory baseURI = _baseURI();
    string memory params = _paramsURI(_dna);
    
    return string(abi.encodePacked(baseURI, params));
  }

  //ERC721 Metadata
  function tokenURI(uint tokenId) public view override returns(string memory){
    require(_exists(tokenId), "ERC71 Metadata: URI query for nonexistent token");

    uint tokenDNA = tokenDNAList[tokenId];
    string memory imageURI = getImageURI(tokenDNA);

    //URI on-chain
    string memory jsonBase64 = Base64.encode(abi.encodePacked(
      '{ "name": "Soldier #',
      tokenId.toString(), 
      '","description": "Soldiers are randomized Avataaars stored on chain.",'
      '"image":"',
      imageURI,
      '"}'
    ));

    return string(abi.encodePacked("data:application/json;base64,",jsonBase64));
  }



  //Override for implementation of ERC721Enumerable
  function _beforeTokenTransfer(address _from, address _to, uint _tokenIdToTransfer) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(_from, _to, _tokenIdToTransfer);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721,ERC721Enumerable) returns(bool){
    return super.supportsInterface(interfaceId);
  }

}