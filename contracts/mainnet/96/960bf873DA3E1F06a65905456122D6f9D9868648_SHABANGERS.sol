// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IContractFusion.sol";

contract SHABANGERS is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.09 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 20;
  
  bool public paused = true;
  
  bool public presale = true;
  string public presaleURI = "http://23.254.217.117:5555/Switsh.json";
  
  // address of OmniFusion contract
  address public FusionContractAddress;



// Member1
  address  _40_Member1 = 0xf270765de3918461D47B0549FD553BF8703D8E46;
// Member2
  address  _40_Member2 = 0x2B0FC0979668f82bEBBdD9f024375e28868070D3;
// Member3
  address  _20_Member3 = 0x9360c8f77310A7aad619aDaB0BF3b3d549714cB9;

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

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply);
    
    if (msg.sender != owner()) {
        require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
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
  
  // fuse two tokens together
  function fuseTokens(uint toFuse, uint toBurn, bytes memory payload, bool burn) external {
        IContractFusion(FusionContractAddress).fuseTokens(msg.sender, toFuse, toBurn, payload);
        
        if(burn == true)
            _burn(toBurn);
    }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
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
  
  // changes the address of the OmniFusion implementation
  function setFusionContractAddress(address _address) payable external onlyOwner {
        FusionContractAddress = _address;
    }
  
  function withdraw() public onlyOwner {
        uint bal = address(this).balance;
        
        uint _10_expenses = bal / 10; // 1/10 = 10%
        
        require(payable(msg.sender).send(_10_expenses));
        
        bal = bal -_10_expenses;
      
        uint _20_Share = bal / 5; // 1/5 = 20%
        uint _40_Share = (bal - _20_Share) / 2; // 100% - 20% => 80% / 2 => 40%
        
        require(payable(_40_Member1).send(_40_Share));
        require(payable(_40_Member2).send(_40_Share));
        require(payable(_20_Member3).send(_20_Share));
  }
  
  
}