pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NewTNft is ERC721Enumerable, Ownable {
  using Strings for uint256;

  bool public paused = false;
  bool public onlyWhitelisted = true;

  string public baseURI;
  
  address public artist;
  address public txFeeToken;
  uint public txFeeAmount;
  
  uint256 public cost = 0.07 ether;
  uint256 public maxSupply = 10000  ;
  uint256 public maxMintAmount = 2;
  uint256 public maxActualMintAmount = 5;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => bool) public excludedList;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    address _artist, 
    address _txFeeToken,
    uint _txFeeAmount
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    artist = _artist; 
    txFeeToken = _txFeeToken;
    txFeeAmount = _txFeeAmount;
    excludedList[_artist] = true; 

    for (uint256 i = 1; i < 51; i++) {
      _safeMint(msg.sender, i);
    }
    
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + _mintAmount < maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        if (onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            require(ownerMintedCount + _mintAmount < 3, "max NFT per address exceeded");
        }
        else{
            require(ownerMintedCount + _mintAmount < 6, "max NFT per address exceeded");
        }
            
    }
    require(msg.value >= cost * _mintAmount, "insufficient funds");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }
  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")): "";
  }

  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
  
  function setExcluded(address excluded, bool status) external onlyOwner {
    require(msg.sender == artist, 'artist only');
    excludedList[excluded] = status;
  }

  function transferFrom(address from, address to, uint256 tokenId) public override {
     require(_isApprovedOrOwner(_msgSender(), tokenId),'ERC721: transfer caller is not owner nor approved');

     if (excludedList[from] == false) {
          _payTxFee(from);
     }

     _transfer(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override {
     if (excludedList[from] == false) {
        _payTxFee(from);
     }

     safeTransferFrom(from, to, tokenId, '');
   }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {

    require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');

    if(excludedList[from] == false) {
          _payTxFee(from);
    }
    
    _safeTransfer(from, to, tokenId, _data);
  }

  function _payTxFee(address from) internal {
    IERC20 token = IERC20(txFeeToken);
    token.transferFrom(from, artist, txFeeAmount);
  }

}