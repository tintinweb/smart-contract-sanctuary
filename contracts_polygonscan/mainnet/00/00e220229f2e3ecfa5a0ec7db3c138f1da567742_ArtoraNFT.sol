// SPDX-License-Identifier: GPL-3.0

// Creator: https://artora.io

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract ArtoraNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

    string public _name="Poly Zebra";
    string public _symbol="ZEBRANFT";
    // mintPrice
    // pre-mint price: 2*1000000000000000000
    // Public price: 6*1000000000000000000
    uint256 public mintPrice = 6 ether;
    uint256 public maxSupply = 6174;
    uint256 public _initialMint=10;

    uint public giveawayMaxItems = 800;
    uint public preMintMaxItems = 2174;
    uint public giveawayCount = 0;
    uint public preMintCount = 0;
    
 
    
   
    uint public maxItemsPerPreMint = 10; // Mutable by owner
    uint public maxItemsPerTx = 20; // Mutable by owner

    string public baseURI="ipfs://" ;
    string public baseExtension = ".json";
    bool public preMintPaused = true;
    bool public whitelistPaused = false;
    bool public publicMintPaused = true;
   mapping(address => uint) public preMintAddresses; 
 

  constructor( ) ERC721(_name, _symbol) {
    // mint(msg.sender, baseURI);
      _mintWithoutValidation(msg.sender, _initialMint);
  }
   receive() external payable {}

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


  
  
  
   
 

    function giveawayMint(address to, uint amount) external onlyOwner {
        require(giveawayCount + amount <= giveawayMaxItems, "giveawayMint: Surpasses cap");
        giveawayCount += amount;
        _mintWithoutValidation(to, amount);
    }

     

  function publicMint() external payable {
        
        uint remainder = msg.value % mintPrice;
        uint amount = msg.value / mintPrice;
        require(remainder == 0, "publicMint: Send a divisible amount of eth");
        require(amount <= maxItemsPerTx, "publicMint: Max 5 per tx");
        

        require(totalSupply() + amount <= maxSupply, "publicMint: Surpasses cap");
        _mintWithoutValidation(msg.sender, amount);
    }

     function preMint() external payable {
        require(!preMintPaused, "preMint: Paused");
         
        uint remainder = msg.value % mintPrice;
        uint amount = msg.value / mintPrice;
        require(remainder == 0, "preMint: Send a divisible amount of eth");
        require(preMintCount + amount <= preMintMaxItems, "preMint: Surpasses cap");
        require(amount <= preMintAddresses[msg.sender], "preMint: Amount greater than allocation");
        
        preMintCount += amount;
        preMintAddresses[msg.sender] -= amount;
        _mintWithoutValidation(msg.sender, amount);
    }

    function _mintWithoutValidation(address to, uint amount) internal {
        require(totalSupply() + amount <= maxSupply, "mintWithoutValidation: Sold out");
        for (uint i = 0; i < amount; i++) {
            uint tokenId = totalSupply()+1;
            _safeMint(to, tokenId);
            emit Mint(to, tokenId);
        }
    }
 
     event Mint(address indexed owner, uint indexed tokenId);

     function addToWhitelist(address[] memory toAdd) external onlyOwner {
        for(uint i = 0; i < toAdd.length; i++) {
            preMintAddresses[toAdd[i]] = maxItemsPerPreMint;
        }
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
  function setCost(uint256 _newCost) public onlyOwner {
    mintPrice = _newCost;
  }

  function setmaxItemsPerTx(uint256 _newmaxItemsPerTx) public onlyOwner {
    maxItemsPerTx = _newmaxItemsPerTx;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

   function setPreMintPaused(bool _preMintPaused) external onlyOwner {
        preMintPaused = _preMintPaused;
    }

    function setPublicMintPaused(bool _publicMintPaused) external onlyOwner {
        publicMintPaused = _publicMintPaused;
    }

    function setMaxItemsPerTx(uint _maxItemsPerTx) external onlyOwner {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setMaxItemsPerPreMint(uint _maxItemsPerPreMint) external onlyOwner {
        maxItemsPerPreMint = _maxItemsPerPreMint;
    }

     
 
  

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}