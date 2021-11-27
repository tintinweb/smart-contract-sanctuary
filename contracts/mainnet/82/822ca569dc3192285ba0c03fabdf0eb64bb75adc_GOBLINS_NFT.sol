// SPDX-License-Identifier: GPL-3.0

// Creator: https://artora.io

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract GOBLINS_NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
 
    
    string public baseURI;
    
    uint256 public cost = 0.05 ether;
    uint256 public maxSupply = 10946;
    uint256 public maxMintItemsPerWallet = 5;
    bool public paused = true;


     mapping(address => uint) public preMintAddresses; 
    uint public preMintMaxItems = 2189; // 20%
    uint public preMintCount = 0;
    bool public preMintPaused = true;

    
    constructor (
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
        ) ERC721 (_name,_symbol) {
            setBaseURI (_initBaseURI);
           // mint (msg.sender,109);
            
        }
        
//internal
function _baseURI () internal view virtual override returns (string memory) {
    return baseURI;
}

//public

function preMint(uint256 amount) external payable {
        require(!preMintPaused, "Paused");
        require (msg.value >= cost * amount);
        require(preMintCount + amount <= preMintMaxItems, "Mint Cap");
         require(preMintAddresses[msg.sender]<=maxMintItemsPerWallet, "Wallet Cap"); // max tokens per address
        preMintCount += amount;
         preMintAddresses[msg.sender] += amount;
        _mintWithoutValidation(msg.sender, amount);
 }

function mint (address _to, uint256 _amount) public payable {

    if (msg.sender != owner()) {
        require (!paused);
        require (_amount <= maxMintItemsPerWallet);// In minting maxMintItemsPerWallet became 'max Items per Transactions'
        require (msg.value >= cost * _amount);
    }
    _mintWithoutValidation(_to,_amount);
}

 function _mintWithoutValidation(address to, uint amount) internal {
        
        require(totalSupply() + amount <= maxSupply, "Sold");
        require(  amount >0, "Zero");
        for (uint i = 0; i < amount; i++) {
            _safeMint(to, (totalSupply()+1));
        }
    }

function walletOfOwner(address _owner) 
public 
view
returns (uint256[] memory)
{
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[] (ownerTokenCount);
    for (uint256 i; i<ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner,i);
    }
    return tokenIds;
}

function tokenURI (uint256 tokenId) 
    public 
    view
    virtual
    override
    returns (string memory)
    {
    require 
    (_exists (tokenId),
    "Not exist"
    );
    string memory currentBaseURI = _baseURI();
    return
    bytes (currentBaseURI).length > 0
    ? string (abi.encodePacked(baseURI,tokenId.toString(),".json"))
    : "";
    }

//only owner



function setCost(uint256 _newCost) public onlyOwner() {
    cost=_newCost;
}

function setmaxMintItemsPerWallet(uint256 _newmaxMintItemsPerWallet) public onlyOwner() {
    maxMintItemsPerWallet=_newmaxMintItemsPerWallet;
}

function setBaseURI(string memory _newBaseURI) public onlyOwner() {
    baseURI=_newBaseURI;
}

function pause(bool _state, bool _premintState ) public onlyOwner() {
    paused=_state;
    preMintPaused=_premintState;
     
}

function withdraw() public payable onlyOwner() {
    require(payable(msg.sender).send(address(this).balance));
}
}