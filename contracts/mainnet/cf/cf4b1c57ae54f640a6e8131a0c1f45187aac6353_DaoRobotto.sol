// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract DaoRobotto is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string private _name;
  string private _symbol;
  uint256 internal MaxMintedtokenId = 0;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxMintAmount = 20;
  uint256 public maxSupplyPerWallet = 10000;
  
  bool public paused = false;

  uint256 public NonOpenedTokenFromId = 0;

  bool public presale = true;
  
  bool public whitelistedAndMint = true;


  uint256 public whitelistMinCost = 0.08 ether;

  string public presaleURI = "http://23.254.217.117:5555/Dao_Robotto/DefaultFile.json";

  mapping(address => bool) public whitelisted;
  mapping(uint256 => string) public tokenPresaleURI;
  mapping(uint256 => bool) public TokenSaleBlacklist;

  bool public WhitelistOnlyFromOwner = true;

// address of Associated Contracts
  mapping(address => bool) public AssociatedContracts;
  uint256 public FusionCost = 0.0 ether;

address  Hito = 0xe3577D975F1359dF3dd186Cf4D2bB73FFFC2074c; // Community Wallet 
address  Seiiku = 0x7A4CF0CE8170421f5cc70F1102fCA9F0fe2aa28D; // Project development
address  Kifu = 0xa86BF12898Aea8Da994ba2903a86e5a9ee2F4232; // Team contribution


  constructor(
    string memory _initBaseURI
  ) ERC721("Dao Robotto", "Dao Robotto") {
      _symbol = "Dao Robotto";
      _name ="Dao Robotto";
    setBaseURI(_initBaseURI);
  }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(TokenSaleBlacklist[tokenId] == false, "Token in the Blacklist...");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner or approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(TokenSaleBlacklist[tokenId] == false, "Token in the Blacklist...");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner or approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @return the name of the token.
     */
    function name() public override view returns (string memory) {
      return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public override view returns (string memory) {
      return _symbol;
    }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    require(!paused);
    require(_mintAmount > 0);
    
    require(MaxMintedtokenId + _mintAmount <= maxSupply);
    
    if (msg.sender != owner()) {

        uint256 WalletTokenCount = balanceOf(_to);
        require(WalletTokenCount + _mintAmount <= maxSupplyPerWallet);

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
          _safeMint(_to, MaxMintedtokenId + 1);
          MaxMintedtokenId++;
          tokenPresaleURI[MaxMintedtokenId] = presaleURI;
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
      return tokenPresaleURI[tokenId];
    }
    else if(NonOpenedTokenFromId > 0 && NonOpenedTokenFromId < tokenId){
      return tokenPresaleURI[tokenId];
    }
    else
    {
        string memory currentBaseURI = _baseURI();
        
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";    
    }

  }

//Burn and Fusion Functions

function burn(uint256 tokenId) public payable{

    if (msg.sender != owner()) {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || AssociatedContracts[_msgSender()] == true, "Fusion: caller is not owner or approved");
    }
      _burn(tokenId);
    }
    
function ExternalFusion(uint256 tokenId, uint256 AttributeID) public payable{
      if (msg.sender != owner()) {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || AssociatedContracts[_msgSender()] == true, "Fusion: caller is not owner or approved");
      }
    }

function Fusion(uint256 tokenId, uint256 AttributeID) public payable{
      if (msg.sender != owner()) {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Fusion: caller is not owner or approved");
        require(_isApprovedOrOwner(_msgSender(), AttributeID), "Fusion: caller is not owner or approved");
        require(msg.value >= FusionCost);
      }
      else if (msg.sender == owner()){
        address tokrnOwner = ownerOf(tokenId);
        address AttributeOwner = ownerOf(AttributeID);

        require(tokrnOwner == AttributeOwner);
      }

      burn(AttributeID);
    }


function Fusion(uint256 tokenId, uint256 Attribute1ID, uint256 Attribute2ID) public payable{
      if (msg.sender != owner()) {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Fusion: caller is not owner or approved");
        require(_isApprovedOrOwner(_msgSender(), Attribute1ID), "Fusion: caller is not owner or approved");
        require(_isApprovedOrOwner(_msgSender(), Attribute2ID), "Fusion: caller is not owner or approved");

        require(msg.value >= FusionCost);

      }
      else if (msg.sender == owner()){
        
        address tokrnOwner = ownerOf(tokenId);
        address Attribute1Owner = ownerOf(Attribute1ID);
        address Attribute2Owner = ownerOf(Attribute2ID);

        require(tokrnOwner == Attribute1Owner && tokrnOwner == Attribute2Owner);

      }

      burn(Attribute1ID);
      burn(Attribute2ID);
    }

function AssociatedFunktion(address Contract, uint256 tokenId, uint256 AttributeID) public payable{
    
    require(AssociatedContracts[Contract] == true, "Contract is not available");

    if (msg.sender != owner()) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Fusion: caller is not owner or approved (TokenID)");
        address ContractAttributeIDOwner = ERC721(Contract).ownerOf(AttributeID);
        require(_msgSender() == ContractAttributeIDOwner, "Fusion: caller is not owner or approved (AttributeID)");
        require(msg.value >= FusionCost);
    }
    
     DaoRobotto(payable(Contract)).AssociatedFunktion(address(this), tokenId, AttributeID);    
    }



  //only owner
function setBlackList(uint256[] memory newTokenSaleBlacklist) public onlyOwner() {

    for (uint256 i; i < MaxMintedtokenId+1; i++) {
      TokenSaleBlacklist[i] = false;
    }

    for (uint256 i; i < newTokenSaleBlacklist.length+1; i++) {
      TokenSaleBlacklist[newTokenSaleBlacklist[i]] = true;
    }

  }

  function setName(string memory _newName) public onlyOwner() {
    _name = _newName;
  }

  function setSymbol(string memory newSymbol) public onlyOwner() {
    _symbol = newSymbol;
  }

  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }
  function setwhitelistMinCost(uint256 _newCost) public onlyOwner() {
    whitelistMinCost = _newCost;
  }

  function setFusionCost(uint256 _newCost) public onlyOwner() {
    FusionCost = _newCost;
  }

  function setmaxSupply(uint256 _newMaxSupply) public onlyOwner() {
    maxSupply = _newMaxSupply;
  }

  function setNonOpenedTokenFromId(uint256 _newNonOpenedTokenFromId) public onlyOwner() {
    NonOpenedTokenFromId = _newNonOpenedTokenFromId;
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

  function setTokenPresaleURI(uint256 TokenId, string memory _newPresaleURI) public onlyOwner {
     tokenPresaleURI[TokenId] = _newPresaleURI;
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

  function AddAssociatedContracts(address Contract) public onlyOwner{
    require(msg.sender == owner());
    AssociatedContracts[Contract] = true;
  }

  function removeAssociatedContracts(address Contract) public onlyOwner{
    require(msg.sender == owner());
    AssociatedContracts[Contract] = false;
  }

  function setwhitelistedAndMint(bool _state) public onlyOwner {
    whitelistedAndMint = _state; 
  }

  function setWhitelistOnlyFromOwner(bool _state) public onlyOwner {
    WhitelistOnlyFromOwner = _state; 
  }

  receive () external payable {
       
  }
  
  function withdraw() public onlyOwner{

        uint bal = address(this).balance;
        uint _1_Percent = bal  / 100  ; // 1/100 = 1%

        uint _33_ = _1_Percent * 33;
        uint _34_ = _1_Percent * 34;
        
        require(payable(Hito).send(_34_));
        require(payable(Seiiku).send(_33_));
        require(payable(Kifu).send(_33_));
        
  }

}