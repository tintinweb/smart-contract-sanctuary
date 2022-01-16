// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

// import ERC721 iterface
import "./ERC721.sol";

// NFTBlocks smart contract inherits ERC721 interface
contract NFTBlocks is ERC721 {

  // this contract's token collection name
  string public collectionName;
  // this contract's token symbol
  string public collectionNameSymbol;
  // total number of nft blocks minted
  uint256 public nftBlockCounter;

  // define nft block struct
   struct NFTBlock {
    uint256 tokenId;
    string tokenName;
    string tokenURI;
    address payable mintedBy;
    address payable currentOwner;
    address payable previousOwner;
    uint256 price;
    uint256 numberOfTransfers;
    bool forSale;
  }

  // map nftblock's token id to nft block
  mapping(uint256 => NFTBlock) public allNFTBlocks;
  // check if token name exists
  mapping(string => bool) public tokenNameExists;
  // check if color exists
  mapping(string => bool) public colorExists;
  // check if token URI exists
  mapping(string => bool) public tokenURIExists;

  // initialize contract while deployment with contract's collection name and token
  constructor() ERC721("NFT Blocks Collection", "NB") {
    collectionName = name();
    collectionNameSymbol = symbol();
  }

  // mint a new nft block
  function mintNFTBlock(string memory _name, string memory _tokenURI, uint256 _price, string[] calldata _colors) external {
    // check if thic fucntion caller is not an zero address account
    require(msg.sender != address(0));
    // increment counter
    nftBlockCounter ++;
    // check if a token exists with the above token id => incremented counter
    require(!_exists(nftBlockCounter),"NFT Block counter already exists");

    // loop through the colors passed and check if each colors already exists or not
    for(uint i=0; i<_colors.length; i++) {
      require(!colorExists[_colors[i]],"NFT Color already exists");
    }
    // check if the token URI already exists or not
    require(!tokenURIExists[_tokenURI],"NFT URI already exists");
    // check if the token name already exists or not
    require(!tokenNameExists[_name],"NFT URI name already exists");

    // mint the token
    _mint(msg.sender, nftBlockCounter);
    // set token URI (bind token id with the passed in token URI)
    _setTokenURI(nftBlockCounter, _tokenURI);

    // loop through the colors passed and make each of the colors as exists since the token is already minted
    for (uint i=0; i<_colors.length; i++) {
      colorExists[_colors[i]] = true;
    }
    // make passed token URI as exists
    tokenURIExists[_tokenURI] = true;
    // make token name passed as exists
    tokenNameExists[_name] = true;

    // creat a new nft block (struct) and pass in new values
    NFTBlock memory newNFTBlock = NFTBlock(
      nftBlockCounter,
      _name,
      _tokenURI,
      payable (msg.sender),
      payable (msg.sender),
      payable(address(0)),
      _price,
      0,
      true
    );
    // add the token id and it's nft block to all nft blocks mapping
    allNFTBlocks[nftBlockCounter] = newNFTBlock;
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
    // get that token from all nft blocks mapping and create a memory of it defined as (struct => NFTBlock)
    NFTBlock memory nftblock = allNFTBlocks[_tokenId];
    // price sent in to buy should be equal to or more than the token's price
    require(msg.value >= nftblock.price);
    // token should be for sale
    require(nftblock.forSale);
    // transfer the token from owner to the caller of the function (buyer)
    _transfer(tokenOwner, msg.sender, _tokenId);
    // get owner of the token
    address payable sendTo = nftblock.currentOwner;
    // send token's worth of ethers to the owner
    sendTo.transfer(msg.value);
    // update the token's previous owner
    nftblock.previousOwner = nftblock.currentOwner;
    // update the token's current owner
    nftblock.currentOwner = payable (msg.sender);
    // update the how many times this token was transfered
    nftblock.numberOfTransfers += 1;
    // set and update that token in the mapping
    allNFTBlocks[_tokenId] = nftblock;
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
    // get that token from all nft blocks mapping and create a memory of it defined as (struct => NFTBlock)
    NFTBlock memory nftblock = allNFTBlocks[_tokenId];
    // update token's price with new price
    nftblock.price = _newPrice;
    // set and update that token in the mapping
    allNFTBlocks[_tokenId] = nftblock;
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
    // get that token from all nft blocks mapping and create a memory of it defined as (struct => NFTBlock)
    NFTBlock memory nftblock = allNFTBlocks[_tokenId];
    // if token's forSale is false make it true and vice versa
    if(nftblock.forSale) {
      nftblock.forSale = false;
    } else {
      nftblock.forSale = true;
    }
    // set and update that token in the mapping
    allNFTBlocks[_tokenId] = nftblock;
  }
}