// SPDX-License-Identifier: MIT

// Created by MoBoosted
// MBSA - Bull NFT

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Counters.sol";
import 'ERC2981ContractWideRoyalties.sol';
import 'IMBSABullNFT.sol';

contract MBSABullNFT is ERC721Enumerable, ERC2981ContractWideRoyalties, IMBSABullNFT, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string private _baseTokenURI;
  string private _ipfsBaseURI;
  uint256 public reflectionBalance;
  uint256 public totalDividend;
  mapping (uint256 => uint256) public reflectBalance;
  mapping (uint256 => address ) public minter;


  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 3 ether;
  uint256 public maxSupply = 9999;
  uint256 public maxDevSupply = 550;
  uint256 public devIssued = 0;
  uint256 public maxMintAmount = 20;
  uint256 public devRewards = 0;
  uint256 public royaltyValue = 700;  // 700 = 7%
  uint256 public devroyalty = 4; // split 4% to MBSA Team 3% reflection
  uint256 public reflectroyalty = 3; // split 4% to MBSA Team 3% reflection
  bool public paused = false;
  bool public revealed = false;
  uint256 public revealTime;
  string public notRevealedUri;
  address private payments = 0x39AEAF2f808Bd4e3383fCFa914Fb91C9133D9DF9;
  address private royaltyContractAddress = 0x39AEAF2f808Bd4e3383fCFa914Fb91C9133D9DF9;
  mapping(address => bool) public whitelisted;

  struct RenderToken {
    uint256 id;
    string uri;
    uint256 refBalance;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address _payments
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    _baseTokenURI = "";
    _ipfsBaseURI = _initBaseURI;
    setRoyalties(payable(_payments), royaltyValue);
    payments = payable(_payments);
    setNotRevealedURI(_initNotRevealedUri);
    revealTime = block.timestamp + 48 hours;
    paused = true;
    
  }

    /// @notice Allows to set the royalties on the contract
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) public onlyOwner(){
        _setRoyalties(recipient, value);
    }

    function setPaused( bool _pause) public onlyOwner(){
        paused = _pause;
    }

    function setRoyaltyContractAddress(address _royaltyContractAddress) public onlyOwner(){
      royaltyContractAddress = _royaltyContractAddress;
      setRoyalties(_royaltyContractAddress, 700);
    }
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = _tokenIds.current();
    require(msg.value == cost*_mintAmount, "Please ensure the correct price is sent");
    require(!paused, "Unable to mint right now - Minting has been Paused");
    require(_mintAmount > 0, "Mint mount has to be more than 0");
    require(_mintAmount <= maxMintAmount, "You cannot mint more than 20 NFT's");
    require(supply + _mintAmount <= maxSupply, "There are not enough NFT's to fulfil your order");

    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= cost * _mintAmount, "Please ensure the correct price is sent");
        }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
      _safeMint(_to, newTokenId);
    //   lastDividendAt[supply+1] = totalDividend;
    }
  }

  // public
  function devMint(address _to, uint256 _mintAmount) public {
    uint256 supply = _tokenIds.current();
    require(devIssued < maxDevSupply, "Max dev NFTs have been issued");
    require(_mintAmount > 0, "Mint mount has to be more than 0");
    require(_mintAmount <= maxMintAmount, "You cannot mint more than 20 NFT's");
    require(supply + _mintAmount <= maxSupply, "There are not enough NFT's to fulfil your order");
    require(devIssued + _mintAmount <= maxDevSupply, "There are not enough NFT's to fulfil your order");
    require(msg.sender==owner() || whitelisted[msg.sender], "You are not approved for this transaction");
    for (uint256 i = 1; i <= _mintAmount; i++) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
      _safeMint(_to, newTokenId);
      devIssued = devIssued + 1;
    }
  }
  
  function tokensMinted() public view returns(uint256){
      return _tokenIds.current();
  }

  function tokenMinter(uint256 tokenId) public view returns(address){
    return minter[tokenId];
  }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981ContractWideRoyalties)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981ContractWideRoyalties.supportsInterface(interfaceId);
            // ERC721Burnable.supportsInterface(interfaceId);
    }


  function getMyTokens(address user)
    public
    view
    returns (RenderToken[] memory)
  {
    uint256 tokenCount = balanceOf(user);
    RenderToken[] memory tokens = new RenderToken[](tokenCount+1);
    for (uint256 i = 0; i < tokenCount; i++) {
        uint256 nftid = tokenOfOwnerByIndex(user, i);
        string memory uri = tokenURI(nftid);
        uint256 refBal = getReflectionBalance(nftid);
        tokens[i] = RenderToken(nftid, uri, refBal);
    }
    // tokens[0] = RenderToken(ownerTokenCount, totSup.toString());
    return tokens;
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

    if(revealed == false && revealTime > block.timestamp) {
        return notRevealedUri;
    }
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function burn(uint256 tokenId) public onlyOwner(){
        uint256 refBal = getReflectionBalance(tokenId);
        _burn(tokenId);
        reflectDividend(refBal);
  }    
    
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable) {
    // if (totalSupply() > tokenId) claimReward(tokenId);
    super._beforeTokenTransfer(from, to, tokenId);
  }

//only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost * 10**18;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
 function setPayments(address _payments) public onlyOwner {
    payments = payable(_payments);
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    require(payable(payments).send(address(this).balance));
  }

  function currentRate() public view returns (uint256){
      if(totalSupply() == 0) return 0;
      return reflectionBalance/totalSupply();
  }

  function claimReflectionRewards() public view {
    uint count = balanceOf(msg.sender);
    uint256 balance = 0;
    for(uint i=0; i < count; i++){
        uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
        balance += reflectBalance[tokenId];
    }
    // payable(msg.sender).transfer(balance);
  }

  function getReflectionBalances() public view returns(uint256) {
    uint count = balanceOf(msg.sender);
    uint256 balance = 0;
    for(uint i=0; i < count; i++){
        uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
        balance += getReflectionBalance(tokenId);
    }
    return balance;
  }

  function claimReward(uint256 tokenId) public view {
    require(ownerOf(tokenId) == _msgSender() || getApproved(tokenId) == _msgSender(), "Only owner or approved can claim rewards");
    reflectBalance[tokenId];
  }

  function getReflectionBalance(uint256 tokenId) public view returns (uint256){

      return reflectBalance[tokenId];
  }

  function splitBalance(uint256 amount) external override returns(bool success){
      reflectDividend(amount);
      return true;
  }

  function reflectDividend(uint256 amount) private {
    uint256 reflectAmt = amount/totalSupply();
    uint256 totSup = totalSupply();
    for (uint256 i=0; i<totSup; i++){
        uint256 tokId = tokenByIndex(i);
        reflectBalance[tokId] =  reflectBalance[tokId] + reflectAmt;
    }
  }

  //only owner
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

}