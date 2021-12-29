//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract LdcNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  bool public preSaleOn = false;
	bool public publicSaleOn = false;
  bool public santaAlgorithmOn = false;
  bool public revealed = false;
  string public notRevealedURI;
  uint256 public maxSupply = 2500;
  uint256 public reserved = 100; // For airdrops, ruffles, etc.
  uint256 public preSaleCost = 55000000000000000; // 0.055 eth
  uint256 public publicSaleCost = 65000000000000000; // 0.065 eth
  uint256 public preSaleMaxMintAmount = 3;
  uint256 public publicSaleMaxMintAmount = 6;
  uint256 public prizeAmount = 6000000000000000000; // 6 eth
  uint256 public prize1ETH = 1000000000000000000; // 1 eth
  uint256 public prize05ETH = 500000000000000000; // 0.5 eth
  uint256 public prize01ETH = 100000000000000000; // 0.1 eth

  mapping (address => uint256) public minted; // To check how many tokens an address has minted
  mapping (address => bool) public whiteListedWallets;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(address _to, uint256 _mintAmount) public payable {
    bool saleOn = (preSaleOn || publicSaleOn);
    require(saleOn, "Sale must be ON");
     
    uint256 supply = totalSupply();

    if (msg.sender != owner()) {
     if (preSaleOn) {
      require(preSaleOn, "Presale must be ON");
      require(_mintAmount > 0, "Mint abmount must be more than 0");
      require(whiteListedWallets[msg.sender] == true, "You aren't whitelisted!");
      require(supply + _mintAmount <= maxSupply, "Purchase would exceed max supply of NFTs");
      require(minted[msg.sender] + _mintAmount <= preSaleMaxMintAmount, "Purchase would exceed max tokens for presale");
      require(msg.value >= preSaleCost * _mintAmount, "Ether value sent is not correct");

     } else if (publicSaleOn) {
      require(publicSaleOn, "Publicsale must be ON");
      require(_mintAmount > 0, "Mint abmount must be more than 0");
      require(supply + _mintAmount <= maxSupply - reserved, "Purchase would exceed max supply of NFTs");
      require(minted[msg.sender] + _mintAmount <= publicSaleMaxMintAmount, "Purchase would exceed max tokens for sale");
      require(msg.value >= publicSaleCost * _mintAmount, "Ether value sent is not correct");
      
      }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
          _safeMint(_to, supply + i);
    } 

    minted[msg.sender] += _mintAmount;  

      // Santa algorithm
    if (santaAlgorithmOn && prizeAmount > 0 && msg.sender != owner()) {
      
        uint rnd = random();        
      if (rnd < 1 && address(this).balance > prize1ETH) {
        payable(_to).transfer(prize1ETH);
        prizeAmount -= prize1ETH;
      } else if (rnd < 4 && address(this).balance > prize05ETH) {
        payable(_to).transfer(prize05ETH);
        prizeAmount -= prize05ETH;
      } else if (rnd < 80 && address(this).balance > prize01ETH) {
        payable(_to).transfer(prize01ETH);
        prizeAmount -= prize01ETH;
      }
    }
   }

  function random() internal returns (uint) {
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty ,msg.sender))) % 999;
    return randomnumber;
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

        if (revealed == false) {
          return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
  }

  //only owner
  function addWhiteList(address[] memory whiteListedAddresses) public onlyOwner
  {
        for(uint256 i=0; i<whiteListedAddresses.length;i++)
        {
            whiteListedWallets[whiteListedAddresses[i]] = true;
        }
  }

  function setPrizeAmount(uint256 _prizeAmount) public onlyOwner {
    prizeAmount = _prizeAmount;
  }

  function setPreSaleCost(uint256 _preSaleCost) public onlyOwner {
    preSaleCost = _preSaleCost;
  }

  function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
    publicSaleCost = _publicSaleCost;
  }

  function setPreSaleMaxMintAmount(uint256 _preSaleMaxMintAmount) public onlyOwner {
    preSaleMaxMintAmount = _preSaleMaxMintAmount;
  }

   function setmaxPublicSaleMintAmount(uint256 _publicSaleMaxMintAmount) public onlyOwner {
    publicSaleMaxMintAmount = _publicSaleMaxMintAmount;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

   function setReserved(uint256 _reserved) public onlyOwner {
    reserved = _reserved;
  }

  function flipPreSaleOn() public onlyOwner {
    preSaleOn = !preSaleOn;
  }
    
  function flipPublicSaleOn() public onlyOwner {
    publicSaleOn = !publicSaleOn;
  }

  function flipRevealed() public onlyOwner {
    revealed = !revealed;
  }

  function flipSantaAlgorithmOn() public onlyOwner {
    santaAlgorithmOn = !santaAlgorithmOn;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setNotRevealedURI(string memory _newNotRevealedURI) public onlyOwner {
    notRevealedURI = _newNotRevealedURI;
  }
  
  function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner {
        baseExtension = _newBaseExtension;
  }

  function withdrawAll() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
  }

  function withdrawSome(uint _eth) external onlyOwner {
        payable(msg.sender).transfer(_eth);
  }
}