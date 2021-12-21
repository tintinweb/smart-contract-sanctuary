/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// SPDX-License-Identifier: --🌲--

pragma solidity ^0.8.0;

// Get a link to NFT contract
interface NFT {

  function mint(address to, uint256 id) external;

  function balanceOf(address owner) external view returns (uint256 balance);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

  function getApproved(uint256 tokenId) external view returns (address operator);

  function ownerOf(uint256 tokenId) external view returns (address owner);

}

// Get a link to BEP20 token contract
interface IBEP20Token {
    
  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);
    
}

/**
 * @title Treedefi Mystery Box for BNB Version 1.0
 *
 * @author treedefi
 */
contract MysteryBoxBNB {

  //---sell parameters---//  
  uint256 public nextId;
  uint256 public itemsSold;
  uint256 public price;
  uint256 public lastId;
  uint256 public dailyLimit;
  
  // Block timestamp of contract creation
  uint256 immutable launchTime;

  //---Set of addresses---// 
  address public admin;
  address public nftContract;
  address public nftree;
  address public seedToken;
  address public treeToken;

  //-----Dividend parameters-----//
  uint256 public reflectionBalance;
  uint256 public totalDividend;

  // Mapping from tokenId to last dividend claimed
  mapping (uint256 => uint256) public lastDividendAt;

  // Mapping from address to dailyPurchase counter
  mapping (address => mapping (uint256 => uint256)) public dailyPurchase;

  /**
	 * @dev Fired in initializeSell()
	 *
   * @param _by an address of owner who executes the function
	 * @param _mintPrice minting price in BNB per mystery box
   * @param _nextId starting tokenId of mystery box
   * @param _lastId last tokenId of mystery box
   * @param _limit daily limit for an address to buy mystery box
	 */
  event Initialize(
    address indexed _by,
    uint256 _mintPrice,
    uint _nextId,
    uint _lastId,
    uint _limit     
  );

  /**
	 * @dev Creates/deploys Treedefi MysteryBox BNB Version 1.0
	 *
	 * @param admin_ address of admin
   * @param nftContract_ address of treedefi farmer
   * @param nftree_ address of treedefi collectibles
   * @param seed_ address of SEED token
   * @param tree_ address of TREE token
	 */
  constructor(
      address admin_,
      address nftContract_,
      address nftree_,
      address seed_,
      address tree_
    )
  {
    //---Setup smart contract internal state---//
    admin = admin_;
    nftContract = nftContract_;
    nftree = nftree_;
    seedToken = seed_;
    treeToken = tree_;
    launchTime = block.timestamp;
  }

  /**
	 * @dev Initialize sell parameters
	 *
   * @notice same function can be used to reinitialize parameters,
   *         arguments should be placed carefully for reinitialization/ 
   *         modification of sell parameter 
   *
	 * @param mintPrice_ minting price in BNB per mystery box
   * @param nextId_ starting tokenId of mystery box
   * @param lastId_ last tokenId of mystery box
   * @param limit_ daily limit for an address to buy mystery box
	 */
  function initializeSell(uint256 mintPrice_, uint nextId_, uint lastId_, uint limit_)
    external
  {
    
    require(msg.sender == admin, "Treedefi: only admin can initialize sell");
    
    // Set up sell parameters
    price = mintPrice_;
    lastId = lastId_;
    nextId = nextId_;
    dailyLimit = limit_;

    // Emits an event
    emit Initialize(msg.sender, mintPrice_, nextId_, lastId_, limit_);
    
  }

  /**
	 * @dev Mints treedefi farmers NFTs by charging fixed price set by admin
	 * 
	 * @param amount_ number NFTs to buy
   */
  function mint(uint amount_) public payable {
    
    // Calculate mint fee after diducting discount for seed/tree/nftree holders
    uint256 _mintFee = calculateMintFee(price*amount_);    
    
    require(msg.value >= _mintFee, "Treedefi: must send correct price");
    
    require(nextId + amount_ <= lastId + 1, "Treedefi: not enough farmers left");
    
    require(
      dailyPurchase[msg.sender][currentDay()] + amount_ <= dailyLimit,
      "Treedefi: daily limit crossed"
    );

    for(uint i=0; i < amount_; i++){
      // Mint an NFT
      NFT(nftContract).mint(msg.sender, nextId);
      // Update last dividend
      lastDividendAt[nextId] = totalDividend;
      // Increment nextId counter
      nextId++;
      // Increment sold counter
      itemsSold++;
      // Update daily purchase data
      dailyPurchase[msg.sender][currentDay()]++;
      // Distribute collected fee
      splitBalance(msg.value/amount_);
    }

  }
  
  /**
	 * @dev Returns current rate
	 */
  function currentRate() public view returns (uint256){
      if(itemsSold == 0) return 0;
      return reflectionBalance/itemsSold;
  }

  /**
	 * @dev Transfer pending rewards for all NFTs owned by sender
	 */
  function claimRewards() public {
    
    // Get NFT balance
    uint count = NFT(nftContract).balanceOf(msg.sender);
    
    // Record pending reward balance
    uint256 balance = 0;
    
    for(uint i=0; i < count; i++){
        uint tokenId = NFT(nftContract).tokenOfOwnerByIndex(msg.sender, i);
        balance += getReflectionBalance(tokenId);
        lastDividendAt[tokenId] = totalDividend;
    }
    
    // Transfer reward amount
    payable(msg.sender).transfer(balance);
  
  }
  
  /**
	 * @dev Returns total pending reward amount
	 */
  function getReflectionBalances() public view returns(uint256) {
    
    // Get NFT balance
    uint count = NFT(nftContract).balanceOf(msg.sender);
    
    // Record pending reward amount
    uint256 total = 0;
    
    for(uint i=0; i < count; i++){
        uint tokenId = NFT(nftContract).tokenOfOwnerByIndex(msg.sender, i);
        total += getReflectionBalance(tokenId);
    }
    
    return total;
  
  }

  /**
	 * @dev Transfer pending rewards for given NFT
   *
   * @param tokenId_ tokenId of given NFT
	 */
  function claimReward(uint256 tokenId_) public {
    
    require(
        NFT(nftContract).ownerOf(tokenId_) == msg.sender || NFT(nftContract).getApproved(tokenId_) == msg.sender,
        "Treedefi: only owner or approved can claim rewards"
    );
    
    // Get pending amount
    uint256 balance = getReflectionBalance(tokenId_);
    
    // Transfer amount
    payable(NFT(nftContract).ownerOf(tokenId_)).transfer(balance);
    
    // Update dividend data
    lastDividendAt[tokenId_] = totalDividend;
  
  }

  /**
	 * @dev Returns pending reward amount for given tokenId
	 */
  function getReflectionBalance(uint256 tokenId_) public view returns (uint256){
    return totalDividend - lastDividendAt[tokenId_];
  }

  /**
	 * @dev Splits given amount
   *
   * @param amount_ amount value
	 */
  function splitBalance(uint256 amount_) private {
    
    // Calculate dividend amount
    uint256 reflectionShare = amount_/10;
    
    // Calculate leftover amount
    uint256 mintingShare  = amount_ - reflectionShare;
    
    // Update dividend data
    reflectDividend(reflectionShare);
    
    // Transfer leftover amount to admin
    payable(admin).transfer(mintingShare);
  
  }

  /**
	 * @dev Updates dividend data
	 */
  function reflectDividend(uint256 amount_) private {
    reflectionBalance  = reflectionBalance + amount_;
    totalDividend = totalDividend + (amount_/itemsSold);
  }

  /**
	 * @dev Pays additional dividend to NFT owners
	 */
  function reflectToOwners() public payable {
    reflectDividend(msg.value);
  }

  /**
	 * @dev Returns mint fee after diducting discount for seed/tree/nftree holders
	 */
  function calculateMintFee(uint256 amount_) public view returns(uint256) {

    // Check SEED/TREE/Nftree balance of sender  
    uint256 seedBalance = IBEP20Token(seedToken).balanceOf(msg.sender);
    uint256 treeBalance = IBEP20Token(treeToken).balanceOf(msg.sender);
    uint256 nftreeBalance = NFT(nftree).balanceOf(msg.sender);
    
    // Record discount
    uint256 discount;

    if(nftreeBalance > 0 || seedBalance > 100E18 || treeBalance > 0) {
        discount = 3;
    } 
    if(nftreeBalance > 10 || seedBalance > 500E18 || treeBalance > 20E18) {
        discount = discount + 1;
    }
    if(nftreeBalance > 20 || seedBalance > 1000E18 || treeBalance > 40E18) {
        discount = discount + 2;
    }
    if(nftreeBalance > 30 || seedBalance > 2000E18 || treeBalance > 50E18) {
        discount = discount + 3;  
    }
    if(nftreeBalance > 40 || seedBalance > 3000E18 || treeBalance > 60E18) {
        discount = discount + 3;  
    }
    
    return (amount_ * (100 - discount)) / 100;

  }

  /**
	 * @dev Returns current day from launch
	 */
  function currentDay() public view returns (uint256) {
    return ((block.timestamp - launchTime) / 86400);
  }

  /**
    * @dev Withdraw BEP20 tokens 
    * 
    * @param token_ address of BEP20 token
    */
  function withdrawTokens(address token_) external {
    
    require(msg.sender == admin, "Treedefi: only admin can withdraw tokens");

    // Fetch balance of the contract  
    uint _balance = IBEP20Token(token_).balanceOf(address(this));
    
    require(_balance > 0, "Treedefi: zero balance");
    
    // transfer tokens to owner if balance is non-zero
    IBEP20Token(token_).transfer(msg.sender, _balance);
      
  }

}