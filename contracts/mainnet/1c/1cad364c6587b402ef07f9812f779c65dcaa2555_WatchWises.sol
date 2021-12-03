// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma abicoder v2;

// import ERC721 iterface
import "./ERC721.sol";

// Watchface smart contract inherits ERC721 interface
contract WatchWises is ERC721, Ownable {

  // this contract's token collection name
  string public collectionName;
  // this contract's token symbol
  string public collectionNameSymbol;
  // total number of watchwise minted
  uint256 public watchWiseCounter;
   // total number of watchwise commision account
  address  watchwiseAccount = 0x6FBE5F05DA8575d55c969d6D18922629A20cCeca;
  uint256 public ownerCommission;
  uint256 public nftAmount;
  // define WatchWise struct
   struct WatchWise {
    uint256 tokenId;
    string tokenName;
    string tokenURL;
    address payable _owner;
    address payable currentOwner;
    address payable previousOwner;
    uint256 price;
    uint256 numberOfTransfers;
  }

  // map watchwise's token id to WatchWise
  mapping(uint256 => WatchWise) public allWatchWise;
  // check if token name exists
  mapping(string => bool) public tokenNameExists;
  // check if color exists
  //mapping(string => bool) public colorExists;
  // check if token URI exists
  mapping(string => bool) public tokenURIExists;

  // initialize contract while deployment with contract's collection name and token
  constructor() ERC721("Watchwise", "WAT") {
    collectionName = name();
    collectionNameSymbol = symbol();
  }

  // mint a new watchwise
  function mintMyNFT(string memory _name,  string memory _tokenURL, uint256 noOfTokens,  uint256 _price, uint256 _tokenId) onlyOwner external  {
    // check if thic fucntion caller is not an zero address account
    require(msg.sender != address(0), "Only owner able to mint the token ");
    //watchwiseAccount = address(0);
    // check if the token URI already exists or not
    require(!tokenURIExists[_tokenURL]);
    // check if the token name already exists or not
    require(!tokenNameExists[_name]);
    //increment counter
    for (uint i=0; i<noOfTokens; i++) {
    watchWiseCounter ++;
    _tokenId ++;
    // check if a token exists with the above token id => incremented counter
    require(!_exists(_tokenId));
   // mint the token
    _mint(msg.sender, _tokenId);
     // set token URI (bind token id with the passed in token URI)
    _setTokenURI(_tokenId, _tokenURL);
    // make passed token URI as exists
    tokenURIExists[_tokenURL] = true;
    // make token name passed as exists
    tokenNameExists[_name] = true;
    //creat a new watchwise (struct) and pass in new values
    WatchWise memory newWatchWise = WatchWise(
    _tokenId,
    _name,
    _tokenURL,
    payable(msg.sender),
    payable(msg.sender),
    payable (address(0)),
    _price,
    noOfTokens);
    // add the token id and it's watchwise to all cwatchwise mapping
    allWatchWise[_tokenId] = newWatchWise;
    }
  }

  // get owner of the token
  function getTokenOwner(uint256 _tokenId) public view returns(address) {
    address _tokenOwner = ownerOf(_tokenId);
    return _tokenOwner;
  }

 function changeTokenPrice(uint256 _tokenId, uint256 _newPrice) public {
    // require caller of the function is not an empty address
    require(msg.sender != address(0));
    // require that token should exist
    require(_exists(_tokenId));
    // get the token's owner
    address tokenOwner = ownerOf(_tokenId);
    // check that token's owner should be equal to the caller of the function
    require(tokenOwner == msg.sender);
    // get that token from all crypto boys mapping and create a memory of it defined as (struct => CryptoBoy)
    WatchWise memory watchwise = allWatchWise[_tokenId];
    // update token's price with new price
    watchwise.price = _newPrice;
    // set and update that token in the mapping
    allWatchWise[_tokenId] = watchwise;
  }

  // get metadata of the token
  function getTokenMetaData(uint _tokenId) onlyOwner public view returns(string memory) {
    string memory tokenMetaData = tokenURI(_tokenId);
    return tokenMetaData;
  }

  // get total number of tokens minted so far
  function getNumberOfTokensMinted()  onlyOwner public view returns(uint256) {
    uint256 totalNumberOfTokensMinted = totalSupply();
    return totalNumberOfTokensMinted;
  }

  // get total number of tokens owned by an address
  function getTotalNumberOfTokensOwnedByAnAddress(address _owner) onlyOwner public view returns(uint256) {
    uint256 totalNumberOfTokensOwned = balanceOf(_owner);
    return totalNumberOfTokensOwned;
  }

  // check if the token already exists
  function getTokenExists(uint256 _tokenId) onlyOwner public view returns(bool) {
    bool tokenExists = _exists(_tokenId);
    return tokenExists;
  }

 // check the token currnet Price
  function getTokenPrice(uint256 _tokenId) onlyOwner public view returns(uint256) {
    WatchWise memory watchwise = allWatchWise[_tokenId];
    return watchwise.price;
  }
  function buyToken(uint256 _tokenId) public payable {
    // check if the function caller is not an zero account address
    require(msg.sender != address(0));
    // check if the token id of the token being bought exists or not
    require(_exists(_tokenId));
    // get the token's owner
    address tokenOwner = ownerOf(_tokenId);
    // token's owner should not be an zero address account
    require(tokenOwner != address(0));
    // the one who wants to buy the token should not be the token's owner
    require(tokenOwner != msg.sender);
    // get that token from all watchwise mapping and create a memory of it defined as (struct => WatchWise)
    WatchWise memory watchwise = allWatchWise[_tokenId];
    // price sent in to buy should be equal to or more than the token's price
    require(msg.value >= 0.01 ether);
    // transfer the token from owner to the caller of the function (buyer)
    _transfer(tokenOwner, msg.sender, _tokenId);
    // get owner of the token
    address payable sendTo = watchwise.currentOwner;
    // send token's worth of ethers to the owner
    sendTo.transfer(msg.value);
    // update the token's previous owner
    watchwise.previousOwner = watchwise.currentOwner;
    // update the token's current owner
    watchwise.currentOwner = payable(msg.sender);
    // update the how many times this token was transfered
    watchwise.numberOfTransfers += 1;
    // set and update that token in the mapping
    allWatchWise[_tokenId] = watchwise;
  }
  // by a token by passing in the token's id
  function airdropToken(uint256 _tokenId, address _to) onlyOwner public payable {
    // check if the token id of the token being bought exists or not
    require(_exists(_tokenId));
    // get the token's owner
    address tokenOwner = ownerOf(_tokenId);
    // get that token from all watchwise mapping and create a memory of it defined as (struct => WatchWise)
    WatchWise memory watchwise = allWatchWise[_tokenId];
    // transfer the token from owner to the caller of the function (buyer)
    _transfer(tokenOwner, _to, _tokenId);
    // update the token's previous owner
    watchwise.previousOwner = watchwise.currentOwner;
    // update the token's current owner
    watchwise.currentOwner = payable(_to);
    // update the how many times this token was transfered
    watchwise.numberOfTransfers += 1;
    // set and update that token in the mapping
    allWatchWise[_tokenId] = watchwise;
  }
  function buyTokenMarketPlace(uint256 _tokenId) public payable {
    // check if the function caller is not an zero account address
    require(msg.sender != address(0));
    // check if the token id of the token being bought exists or not
    require(_exists(_tokenId));
    // get the token's owner
    address tokenOwner = ownerOf(_tokenId);
    // token's owner should not be an zero address account
    require(tokenOwner != address(0));
    // the one who wants to buy the token should not be the token's owner
    require(tokenOwner != msg.sender);
    // get that token from all watchwise mapping and create a memory of it defined as (struct => WatchWise)
    WatchWise memory watchwise = allWatchWise[_tokenId];
    // price sent in to buy should be equal to or more than the token's price
    require(msg.value >= 0.01 ether);
    // transfer the token from owner to the caller of the function (buyer)
    _transfer(tokenOwner, msg.sender, _tokenId);
    // get owner of the token
    address payable sendTo = watchwise.currentOwner;
    // send token's worth of ethers to the owner
    nftAmount = msg.value;
    ownerCommission= nftAmount - (nftAmount * 95 / 100);
    sendTo.transfer(nftAmount * 95 / 100);
    payable(address(watchwiseAccount)).transfer(ownerCommission);
    // update the token's previous owner
    watchwise.previousOwner = watchwise.currentOwner;
    // update the token's current owner
    watchwise.currentOwner = payable(msg.sender);
    // update the how many times this token was transfered
    watchwise.price = msg.value;
    watchwise.numberOfTransfers += 1;
    // set and update that token in the mapping
    allWatchWise[_tokenId] = watchwise;
  }
}