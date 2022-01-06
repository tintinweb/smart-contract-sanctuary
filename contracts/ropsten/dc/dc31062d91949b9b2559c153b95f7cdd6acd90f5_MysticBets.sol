// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 < 0.8.0;
pragma abicoder v2;

// import ERC721 iterface
import "./ERC721.sol";

// MysticBets smart contract inherits ERC721 interface
contract MysticBets is ERC721 {

  using Strings for uint256;
  // this contract's token collection name
  string public collectionName;
  // this contract's token symbol
  string public collectionNameSymbol;
  // total number of MysticBets minted
  uint256 public mysticBetsCounter;

  uint256 public constant mbjPrice = 25000000000000000; //0.025 ETH

  uint256 public constant MAX_MBJS = 10000; //10k

  // define MysticBet struct
   struct MysticBet {
    string tokenURI;
    address payable feeRecipient;
    address payable mintedBy;
    address payable currentOwner;
    address payable previousOwner;
    uint256 sellerFeeBasisPoints;
    uint256 numberOfTransfers;
    bool forSale;
  }

  // map mysticbet's token id to MysticBet
  mapping(uint256 => MysticBet) public allMysticBets;

  // initialize contract while deployment with contract's collection name and token
  constructor() ERC721("MysticBets Jersey", "MBJ") {
    collectionName = name();
    collectionNameSymbol = symbol();
  }

  // mint a new MysticBet
  function mintMysticBets(address payable _feeRecipient, uint256 _sellerFeeBasisPoints) external {
    // check if thic fucntion caller is not an zero address account
    require(msg.sender != address(0));
    // increment counter
    mysticBetsCounter ++;
    // check if a token exists with the above token id => incremented counter
    require(!_exists(mysticBetsCounter));

    require(mysticBetsCounter <= MAX_MBJS);

    // mint the token
    _mint(msg.sender, mysticBetsCounter);
    // set token URI (bind token id with the passed in token URI)
    _setTokenURI(mysticBetsCounter, generateTokenURI());
    // creat a new MysticBet (struct) and pass in new values
    MysticBet memory newMysticBet = MysticBet(
         generateTokenURI(),
        _feeRecipient,
        msg.sender,
        msg.sender,
        address(0),
        _sellerFeeBasisPoints,
        0,
        true
    );
    // add the token id and it's MysticBet to all MysticBets mapping
    allMysticBets[mysticBetsCounter] = newMysticBet;
  }

  // get owner of the token
  function getTokenOwner(uint256 _tokenId) public view returns(address) {
    address _tokenOwner = ownerOf(_tokenId);
    return _tokenOwner;
  }

  // get metadata of the token
  function getTokenMetaData(uint _tokenId) public view returns(string memory) {
    string memory tokenMetaData = tokenURI(_tokenId);
    return tokenMetaData;
  }

  // get total number of tokens minted so far
  function getNumberOfTokensMinted() public view returns(uint256) {
    uint256 totalNumberOfTokensMinted = totalSupply();
    return totalNumberOfTokensMinted;
  }

  // get total number of tokens owned by an address
  function getTotalNumberOfTokensOwnedByAnAddress(address _owner) public view returns(uint256) {
    uint256 totalNumberOfTokensOwned = balanceOf(_owner);
    return totalNumberOfTokensOwned;
  }

  // check if the token already exists
  function getTokenExists(uint256 _tokenId) public view returns(bool) {
    bool tokenExists = _exists(_tokenId);
    return tokenExists;
  }

  // by a token by passing in the token's id
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
    // get that token from all MysticBets mapping and create a memory of it defined as (struct => MysticBet)
    MysticBet memory mysticbet = allMysticBets[_tokenId];
    // price sent in to buy should be equal to or more than the token's price
    require(msg.value >= mbjPrice);
    // token should be for sale
    require(mysticbet.forSale);
    // transfer the token from owner to the caller of the function (buyer)
    _transfer(tokenOwner, msg.sender, _tokenId);
    // get owner of the token
    address payable sendTo = mysticbet.currentOwner;
    address payable feeSendTo = mysticbet.feeRecipient;
    // send token's worth of ethers to the owner
    sendTo.transfer(msg.value - msg.value * mysticbet.sellerFeeBasisPoints / 100);
    feeSendTo.transfer(msg.value * mysticbet.sellerFeeBasisPoints / 100);
    // update the token's previous owner
    mysticbet.previousOwner = mysticbet.currentOwner;
    // update the token's current owner
    mysticbet.currentOwner = msg.sender;
    // update the how many times this token was transfered
    mysticbet.numberOfTransfers += 1;
    // set and update that token in the mapping
    allMysticBets[_tokenId] = mysticbet;
  }

  // switch between set for sale and set not for sale
  function toggleForSale(uint256 _tokenId) public {
    // require caller of the function is not an empty address
    require(msg.sender != address(0));
    // require that token should exist
    require(_exists(_tokenId));
    // get the token's owner
    address tokenOwner = ownerOf(_tokenId);
    // check that token's owner should be equal to the caller of the function
    require(tokenOwner == msg.sender);
    // get that token from all MysticBets mapping and create a memory of it defined as (struct => MysticBet)
    MysticBet memory mysticbet = allMysticBets[_tokenId];
    // if token's forSale is false make it true and vice versa
    if(mysticbet.forSale) {
      mysticbet.forSale = false;
    } else {
      mysticbet.forSale = true;
    }
    // set and update that token in the mapping
    allMysticBets[_tokenId] = mysticbet;
  }

  function generateTokenURI() private view returns(string memory URI){
      URI = string(abi.encodePacked("https://ipfs.io/ipfs/QmPBGhBbRjd8TMkZ6fwr3ukDMaEvjCUMvt7gRfvTnfMWoa/", mysticBetsCounter.toString() , ".json" ));
  }
}