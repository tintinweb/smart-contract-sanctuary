// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract ExecutiveHusky is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.07 ether;
  uint256 public maxSupply = 7777;
  uint256 public maxMintAmount = 10;
  uint256 public maxSupplyPerWallet = 1;
  
  bool public paused = true;
  
  bool public presale = true;
  
  bool public whitelistedAndMint = true;
  bool public MintForCreator = true;

  uint256 public whitelistMinCost = 0.05 ether;

  string public presaleURI = "http://23.254.217.117:5555/ExecutiveHuskyClub/DefaultFile.json";
  
  // address of OmniFusion contract
  //address public FusionContractAddress;

  mapping(address => bool) public whitelisted;

  bool public WhitelistOnlyFromOwner = true;


//Creator
    address Creator = 0x0329fB3b8A76D462534F4a6Ee9FeE81F16D4adb2;

// Member1
  address  _65_Member1 = 0x0894a0178C022D0C573380f95C8949E391B75b20;
// Member2
  address  _25_Member2 = 0x2075EB461cb59c5F32838dd31dDCb8e607561185;
// Member3
  address  _5_Member3 = 0xa8049Db284302481badb823609145d7705cA8FA4; 
// Member4
  address  _5_Member4 = 0x9108e880920DA54C4D671eD9c7551D03b0dB8b30;


  constructor(
    string memory _initBaseURI
  ) ERC721("ExecutiveHusky", "ExecutiveHusky") {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    require(!paused);
    require(_mintAmount > 0);
    
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply);
    
    uint256 WalletTokenCount = balanceOf(_to);
    require(WalletTokenCount + _mintAmount <= maxSupplyPerWallet);
    
    
    if (msg.sender != owner()) {

        if(whitelisted[msg.sender] == true) {
            require(_mintAmount <= maxMintAmount);
            require(msg.value >= whitelistMinCost * _mintAmount);
        }
        else
        {
            require(_mintAmount <= maxMintAmount);
            require(msg.value >= cost * _mintAmount);
        }

    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      if(MintForCreator == true){
          _safeMint(Creator, supply + i);
          _transfer(Creator, _to, supply + i);
      }
      else{
          _safeMint(_to, supply + i);
      }
      
    }
  }
  
  function mintWithwhitelisted(address _to, uint256 _mintAmount) public payable {
   
   if(whitelistedAndMint == true)
            whitelisted[msg.sender] = true;
            
    mint(_to, _mintAmount);
    
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

    if(presale){
        return presaleURI;
    }
    else
    {
        string memory currentBaseURI = _baseURI();
        
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";    
    }

  }
  
  //only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setwhitelistMinCost(uint256 _newCost) public onlyOwner() {
    whitelistMinCost = _newCost;
  }

  function setmaxSupply(uint256 _newMaxSupply) public onlyOwner() {
    maxSupply = _newMaxSupply;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setmaxSupplyPerWallet(uint256 _newmaxSupplyPerWallet) public onlyOwner() {
    maxSupplyPerWallet = _newmaxSupplyPerWallet;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function setpresaleURI(string memory _newPresaleURI) public onlyOwner {
    presaleURI = _newPresaleURI;
  }
  
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setpresale(bool _state) public onlyOwner {
    presale = _state;
    
  }
  
  function whitelistUser(address _user) public {
    if(WhitelistOnlyFromOwner == true)
      require(msg.sender == owner());
    else if(msg.sender != owner())
      require(msg.sender == _user);

    whitelisted[_user] = true;
  }
  
   function removeWhitelistUser(address _user) public {
     if(WhitelistOnlyFromOwner == true)
      require(msg.sender == owner());
     else if(msg.sender != owner())
      require(msg.sender == _user);

      whitelisted[_user] = false;
  }

  function setMintForCreator(bool _state) public onlyOwner {
    MintForCreator = _state; 
  }
  
  function setwhitelistedAndMint(bool _state) public onlyOwner {
    whitelistedAndMint = _state; 
  }

  function setWhitelistOnlyFromOwner(bool _state) public onlyOwner {
    WhitelistOnlyFromOwner = _state; 
  }

  // changes the address of the OmniFusion implementation
  //function setFusionContractAddress(address _address) payable external onlyOwner {
  //      FusionContractAddress = _address;
 // }
  
  function withdraw() public {
      
      if(msg.sender == owner() || msg.sender == _25_Member2)
      {
        uint bal = address(this).balance;
        uint _1_Procent = bal / 100 ; // 1/100 = 1%
        
        uint _65_Member1_Share = _1_Procent * 65;
        uint _25_Member2_Share = _1_Procent * 25;
        uint _5_Member3_Share = _1_Procent * 5;
        uint _5_Member4_Share = _1_Procent * 5; 
        
        require(payable(_65_Member1).send(_65_Member1_Share));
        require(payable(_25_Member2).send(_25_Member2_Share));
        require(payable(_5_Member3).send(_5_Member3_Share));
        require(payable(_5_Member4).send(_5_Member4_Share));
      }
  }
  
  
}