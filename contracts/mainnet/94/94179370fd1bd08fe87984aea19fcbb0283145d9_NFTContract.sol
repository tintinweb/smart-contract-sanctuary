// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract NFTContract is ERC721Enumerable, Ownable {
  
  using Strings for uint256;

  mapping(address => uint256) public freeNFTOwnedList;
  uint256 public pricePerNFT = 0.025 ether;
  
  uint256 public maxNFTSupply = 10000;
  
  //Free Mint Settings
  uint256 public maxFreeMintableAmount = 5;
  uint256 public totalFreeAmount;
  uint256 public maxFreeAmount = 1000;
  uint256 amountOfPayment;
 
  uint256 public nowRoundSaleAmount = 0;
  uint256 public nowRoundSaleMaxAmount = 1000;


  // Mint Settings
  uint256 public maxMintableAmount = 10;
  bool public stopNFTMinting = true;
  bool public revealed = false;

  
  // Uri Settings
  string baseExt = ".json";
  string public secretItemURI = "ipfs://Qmb2gSniUfsXv9dRHjPqVKua9h8XSPEhuRxJaBwAmgDJ8Z/secret.json";
  string private baseURI;
 
  constructor(string memory _baseURI) ERC721("THETIGERSCLUB", "TTC") {
    baseURI = _baseURI;
  }


  function mint(uint256 _mintAmount) public payable {
     require(!stopNFTMinting);
     require(_mintAmount > 0);
     require(_mintAmount <= maxMintableAmount);
    uint256 supply = totalSupply();
    require(supply+_mintAmount<=maxNFTSupply);
    if(totalFreeAmount < maxFreeAmount){
      uint256 remaining = doHaveFree(msg.sender);
      if(totalFreeAmount + _mintAmount < maxFreeAmount){
        totalFreeAmount += _mintAmount;
        freeNFTOwnedList[msg.sender] += _mintAmount;
      }else{
        if(remaining >= maxFreeAmount -totalFreeAmount){
          uint256 rate = calculateRate();
          amountOfPayment = _mintAmount - (maxFreeAmount -totalFreeAmount);
          require(msg.value == pricePerNFT * rate * amountOfPayment, "1");
          nowRoundSaleAmount += amountOfPayment;
          freeNFTOwnedList[msg.sender] += (_mintAmount -amountOfPayment);
          totalFreeAmount += (_mintAmount -amountOfPayment);
        }else{
          uint256 rate = calculateRate();
          amountOfPayment = _mintAmount -remaining;
          require(msg.value == pricePerNFT * rate * amountOfPayment, "1");
          totalFreeAmount += (_mintAmount - amountOfPayment);
          freeNFTOwnedList[msg.sender] += (_mintAmount - amountOfPayment);
          nowRoundSaleAmount += amountOfPayment;
        }        
      }
    }else{
      uint256 rate = calculateRate();
      if(nowRoundSaleAmount + _mintAmount <= nowRoundSaleMaxAmount*rate){
        require(msg.value == pricePerNFT * rate * _mintAmount);
        nowRoundSaleAmount += _mintAmount;
      }else{
        uint256 remaining = (nowRoundSaleAmount + _mintAmount) - nowRoundSaleMaxAmount;
        uint256 amountOfPayment = (remaining * (rate +1) * pricePerNFT) + (_mintAmount - remaining) * pricePerNFT * rate;
        require(msg.value == amountOfPayment);
        nowRoundSaleAmount += _mintAmount;
      }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory){
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override  returns (string memory) {   
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    if(!revealed) {
        return secretItemURI;
    }
    string memory realBaseURI = baseURI;
    return string(abi.encodePacked(realBaseURI, tokenId.toString(), baseExt));
  }
  function calculateRate() private view returns(uint256){
        return (nowRoundSaleAmount/nowRoundSaleMaxAmount) + 1;
  }
  function doHaveFree(address _add) private returns(uint256){
     return (maxFreeMintableAmount - freeNFTOwnedList[_add]);
  }

  function stopFreeMintable() public onlyOwner{
    maxFreeAmount = totalFreeAmount;
  }

  function changeSecretItemURI(string memory _uri) public onlyOwner{
    secretItemURI = _uri;
  }
  
  function setPricePerNFT(uint256 _new) public onlyOwner {
    pricePerNFT = _new;
  }

  function setmaxMintAmount(uint256 _amount) public onlyOwner {
    maxMintableAmount = _amount;
  }

  function setBaseURI(string memory _uri) public onlyOwner {
    baseURI = _uri;
  }
  function changeBaseExt(string memory _ext) public onlyOwner{
    baseExt = _ext;
  }
  function changeBaseURIVisibility() public onlyOwner{
    revealed = !revealed;
  }

  function changeMaxFreeAmount(uint256 _val) public onlyOwner{
      maxFreeAmount = _val;
  }

  function changeStatusMintable() public onlyOwner {
    stopNFTMinting = !stopNFTMinting;
  }
 
  function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

}