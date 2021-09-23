/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
//0xd79f25E19b35C514935fdf5b520BB3aD0c600e1d


/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. 
 */
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
    public
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  
  modifier onlyOwner()
  {
    _isOwner();
    _;
  }
  
  function _isOwner() internal view
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}



/**
 * @dev Math operations with safety checks that throw on error. 
 */
library SafeMath
{
  /**
   * @dev - List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant OVERFLOW = "008001";
  string constant SUBTRAHEND_GREATER_THEN_MINUEND = "008002";
  string constant DIVISION_BY_ZERO = "008003";

  /**
   * @dev Multiplies two numbers, reverts on overflow.
   * @param _factor1 Factor number.
   * @param _factor2 Factor number.
   * @return product The product of the two factors.
   */
  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2, OVERFLOW);
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient, reverts on division by zero.
   * @param _dividend Dividend number.
   * @param _divisor Divisor number.
   * @return quotient The quotient.
   */
  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {
    // Solidity automatically asserts when dividing by 0, using all gas.
    require(_divisor > 0, DIVISION_BY_ZERO);
    quotient = _dividend / _divisor;
    // assert(_dividend == _divisor * quotient + _dividend % _divisor); // There is no case in which this doesn't hold.
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param _minuend Minuend number.
   * @param _subtrahend Subtrahend number.
   * @return difference Difference.
   */
  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend, SUBTRAHEND_GREATER_THEN_MINUEND);
    difference = _minuend - _subtrahend;
  }

  /**
   * @dev Adds two numbers, reverts on overflow.
   * @param _addend1 Number.
   * @param _addend2 Number.
   * @return sum Sum.
   */
  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1, OVERFLOW);
  }

  /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when
    * dividing by zero.
    * @param _dividend Number.
    * @param _divisor Number.
    * @return remainder Remainder.
    */
  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder)
  {
    require(_divisor != 0, DIVISION_BY_ZERO);
    remainder = _dividend % _divisor;
  }

}


contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "22");
    }
}





/**
 * @dev signature of external (deployed) contract for NFT publishing (ERC721)
 * only methods we will use, needed for us to communicate with ArtGallery token (which is ERC721)
 */
contract ArtGalleryTokens {
    
 
 
 function mint(address _to, uint256 _tokenId, string calldata _uri) external {}
 
 function ownerOf(uint256 _tokenId) external view returns (address) {}
 function burn(uint256 _tokenId) external {}
 
 function tokenURI(uint256 _tokenId) external  view returns(string memory) {}
    
}

contract mpContract {
    function getNextTokenId() external  view returns (uint256){}
    function nftProfiles(uint256) public view returns ( uint32 id, uint256 price, string memory url, address artist, bool is_auction, 
                                                        uint256 start_time, uint256 end_time, uint256 buy_now_price, uint256 min_step,
                                                        uint256 limit, bool is_timed){}
    function approved_artists(uint256) public view returns(address){}
    function getPaymentToken() external view returns(address){}
    function getNFTContract() external view returns(address){}
    
    function getFullAuctionRecordById(uint32 id) public view returns( uint256 current_price, 
                                                                        address current_winner, 
                                                                        uint256 prev_price, 
                                                                        address previous_winner,
                                                                        bool bought_for_buy_now_price,
                                                                        bool winner_got_token
                                                                        )  {}
    
}


contract NFTMarketplace is
  Ownable, 
  ReentrancyGuard {
    
    using SafeMath for uint256;    
    
    address public _own_address;
    
    /**
    * @dev - modifier for access to admin level functions
    */
    modifier onlyOwnerOrMarketplaceManager() {
          _isOwnerOrMarketplaceManager();    
          _;
    }
    
    /**
    * @dev - utility function for modifier above
    */  
    function _isOwnerOrMarketplaceManager() internal view{
         require(
              msg.sender == marketplace_manager || msg.sender == owner,
              "only price manager or owner can call this function"
              );
    }
    
    
    /**
    * @dev - modifier for access to functions for approved artists
    */
    modifier onlyArtist() {
          isArtist();
          _;
    }
    
    /**
    * @dev - utility function for modifier above
    */      
    function isArtist() internal view {
      require(
          isApprovedArtist(msg.sender),
          "only artist can call this function"
          );
    }
    
    /**
    * @dev - utility function for modifier above
    */  
    function isApprovedArtist(address _addr) internal view returns(bool){
        for (uint256 i = 0; i < approved_artists_length; i++){
            if (_addr == approved_artists[i]) return true;
        }
        return false;
    }
 
    /**
    * @dev - modifier to check if calling party is contract or wallet (do not allow contracts)
    * not bullet-proof check, but additional measure
    */
    modifier notContract(){
      require(
          (!isContract(msg.sender)),
          "external contracts are not allowed"
          );
          _;
    }

    /**
    * @dev - utility function for modifier above
    */
    function isContract(address _addr) internal view returns (bool){
      uint32 size;
      assembly {
          size := extcodesize(_addr)
      }
    
      return (size > 0);
    }
    
   
    ArtGalleryTokens nftContract;  //external NFT publishing contract
  
  
  
    mpContract prevMPContract; //previous contract, for upgrade scenario
  
   
    address nftContractAddress = 0x0000000000000000000000000000000000000000; //NFT contract (ArtGallery)
    
    
    address marketplace_manager = 0x0000000000000000000000000000000000000000; //marketplace manager (admin)
  
  
    //constants 
    uint32 constant BAD_NFT_PROFILE_ID = 9999999;
    uint256 constant BAD_PRICE = 0;
    string constant BAD_URL = '';
    uint32 constant UNLIMITED = 9999999;
  
    //approved artists list
    mapping (uint256 => address) public approved_artists;
    uint256 public approved_artists_length = 0;
  
  
    //balances on contract, i.e. artists, platform comission wallet
    mapping (address => uint256) public balances;
    
    //wallet where platform commission accumulated
    address public comission_wallet;
  
    /**
    * @dev 'database' to store profiles of NFTs
    * id is here is implemented for integrity only, i.e. in nftProfiles[index] = .id should be always equal (index+1)
    */
    struct NFTProfile{
          uint32 id;                //unique id
          uint256 price;            //in ETH, last 18 digits are decimals, in case of auction it will be start price
          string url;               //url to JSON with metadata
          address artist;           //artist, 'owner' of profile
          bool is_auction;          //is it auction sale or direct?
          uint256 start_time;       //auction start time
          uint256 end_time;         //auction end time
          uint256 buy_now_price;    //auction 'buy now' price
          uint256 min_step;         //auction min step (+X to previous bid)
          uint256 limit;            // default ==1, means unique piece, if > 1 than more than 1 items could be minted, price is static, 
          bool is_timed;            // if is_timed == true - can be sold duirng specific time, unlimited items (limit value is ignored)
                                    // and start_time & end_time fields (from auction are reused - meaning range when item is sold)
    }
  
    
    //nft profiles 'database'
    mapping (uint256 => NFTProfile) public nftProfiles;
    uint256 public nftProfiles_length = 0;
  
  
    //auction record 
    struct AuctionRecord{
          uint256 current_price;
          address current_winner;
          uint256 prev_price;
          address previous_winner;
          bool bought_for_buy_now_price;
          bool winner_got_token;
    }
  
    //auction records 'database',indexed by profile id
    mapping (uint256 => AuctionRecord) public auctionData;
  
    //next token id (with this token id next token will be minted)
    uint256 next_token_id = 10;
  
    //platform commission
    uint256 platform_comission = 2000; //20%, scale is 10000, i.e. 250 - > 2.5%

   /**
   * @dev Events - commented to save gas
   */
/*
    event Minted(uint32 profileID, uint256 tokenId, address wallet, uint256 ethAmount, uint256 priceAtMoment);
    
    event MintedToWinner(uint32 profileID, uint256 _tokenId, address wallet, uint256 current_price); 
    
    event AdminMinted(uint32 profileID, uint256 tokenId, address wallet, uint256 curPrice); 
    event AdminBurned(uint256 _tokenId); 
*/

    /**
    * @dev Contract constructor.
    */
    constructor()  public {
         _own_address = address(this);
         marketplace_manager = owner;                           //initialy owner is marketplace manager
         nftContract = ArtGalleryTokens(nftContractAddress);    //NFT minting interface
    }
    
 
    /**
    * @dev setter for platform commission
    * commission is in 10000 scale, i.e. 1000 is 0.1 (10%)
    */      
    function setPlatformComission(uint256 comission) external onlyOwnerOrMarketplaceManager{
          platform_comission = comission;
    }
      
 
    /**
    * @dev getter for platform commission
    * commission is in 10000 scale, i.e. 1000 is 0.1 (10%)
    */    
    function getPlatformComission() public view returns(uint256){
        return platform_comission;
    }

 
    /**
    * @dev setter for marketplace manager
    */   
    function setMarketplaceManagerRight(address newMarketplaceManager) external onlyOwner{
          marketplace_manager = newMarketplaceManager;
    }
      
 
    /**
    * @dev getter for marketplace manager
    */    
    function getMarketplaceManager() public view returns(address){
        return marketplace_manager;
    }

   
 
    /**
    * @dev setter for comission wallet address
    */    
    function setComissionWallet(address cmsn_wallet) external onlyOwnerOrMarketplaceManager{
          comission_wallet = cmsn_wallet;
    }
      
    /**
    * @dev getter for comission wallet address
    */    
    function getComissionWallet() public view returns(address){
        return comission_wallet;
    }
    
    
   
    
    
    
    /**
    * @dev setter for nftContractAddress (NFT publishing contract)
    */    
    function setNFTContract(address newNFTContract) external onlyOwner returns(bool){
    
        nftContractAddress = newNFTContract;
        nftContract = ArtGalleryTokens(nftContractAddress);
    }
    
    /**
    * @dev getter for nftContractAddress (NFT publishing contract)
    */    
    function getNFTContract() external view returns(address){
        return nftContractAddress;
    }


    /**
    * @dev getter for next_token_id
    */
    function getNextTokenId() external  view returns (uint256){
          return next_token_id;
    }
  
    /**
    * @dev setter for next_token_id
    */
    function setNextTokenId(uint32 setId) external onlyOwnerOrMarketplaceManager (){
          next_token_id = setId;
    }
      

    /**
    * @dev - register artist in approved_artists list
    * admin level function
    */     
    function registerArtist(address _addr) external onlyOwnerOrMarketplaceManager {
        approved_artists[approved_artists_length] = _addr;
        approved_artists_length++;
    }
  
  
    /**
    * @dev - removes address from approved_artists list, address index in list is  a parameter
    * admin level function
    */   
    function removeArtistAtIndex(uint32 index) public onlyOwnerOrMarketplaceManager {
         if (index >= approved_artists_length) return;
         if (index == approved_artists_length -1){
             approved_artists_length--;
         } else {
             for (uint256 i = index; i < approved_artists_length-1; i++){
                 approved_artists[i] = approved_artists[i+1];
             }
             approved_artists_length--;
         }
    }
  
  
    /**
    * @dev - removes address from approved_artists list, address to remove is a parameter
    * admin level function
    */ 
    function removeArtistByAddress(address _addr) external onlyOwnerOrMarketplaceManager {
         for (uint32 i = 0; i < approved_artists_length; i++){
              if (approved_artists[i] == _addr){
                  removeArtistAtIndex(i);      
                  return;
              }
         }
    }
  
  
  
  
    /**
    * @dev adds 'profile' to 'database'
    * admin level function, can be used by admin to create profile for any artist
    */
    function addNFTProfile(     
                                uint256 price, 
                                string calldata url,
                                address artist,
                                bool is_auction,
                                uint256 start_time,
                                uint256 end_time,
                                uint256 buy_now_price,
                                uint256 min_step,
                                uint256 limit,
                                bool is_timed
        ) external onlyOwnerOrMarketplaceManager {
          require((is_timed && !is_auction) || !is_timed,"cannot be timed & auction" );
          require((limit>1 && !is_auction) || limit == 1, "auction only for uinque items");
            
          uint32 id = uint32(nftProfiles_length)+1;    
          NFTProfile memory temp = NFTProfile(id,price,url, artist, is_auction, start_time, end_time, buy_now_price, min_step, limit, is_timed);
          nftProfiles[nftProfiles_length] = temp;
          nftProfiles_length++;
          
          if (is_auction){
              auctionData[id].current_price = price;
              auctionData[id].current_winner = 0x0000000000000000000000000000000000000000;
          }
    }
      
     /**
    * @dev - add NFT profile into internal 'database'
    * called by artist, i.e. create profile with 'artist' field equial to caller
    * caller should be artist (ie. in the approved artists list)
    */
    function addMyNFTProfile( 
                            uint256 price, 
                            string calldata url, 
                            bool is_auction,
                            uint256 start_time,
                            uint256 end_time,
                            uint256 buy_now_price,
                            uint256 min_step,
                            uint256 limit,
                            bool is_timed
        ) external onlyArtist {
          require((is_timed && !is_auction) || !is_timed,"cannot be timed & auction" );
          require((limit>1 && !is_auction) || limit == 1, "auction only for uinque items");    
            
          uint32 id = uint32(nftProfiles_length)+1;  
          NFTProfile memory temp = NFTProfile(id,price,url, msg.sender, is_auction, start_time, end_time, buy_now_price, min_step, limit, is_timed);
          nftProfiles[nftProfiles_length] = temp;
          nftProfiles_length++;
          
          if (is_auction){
              auctionData[id].current_price = price;
              auctionData[id].current_winner = 0x0000000000000000000000000000000000000000;
          }
    }
  
    
    /**
    * @dev admin level function - do not use if you do not know what is it, 
    * it will destroy current contract data, it reads data from other contract and writes them into the current
    * useful during contract upgrade scenario
    */
    function setupFrom(address mpContractAddress, uint32 len_profiles, uint32 len_artists) external onlyOwner {
      prevMPContract = mpContract(mpContractAddress); 
      
      next_token_id = prevMPContract.getNextTokenId();
      
    
      nftContractAddress = prevMPContract.getNFTContract();
      nftContract = ArtGalleryTokens(nftContractAddress);
      
      for (uint32 j = 0; j < len_artists; j++){
         
        (address _addr) = prevMPContract.approved_artists(j);
        approved_artists[approved_artists_length] = _addr;
        approved_artists_length++;
      }
      
      for (uint32 i = 0; i < len_profiles; i++){
         
        (uint32 id, uint256 price, string memory url, address artist, 
         bool is_auction, uint256 start_time, uint256 end_time, uint256 buy_now_price, uint256 min_step, uint256 limit, bool is_timed) = prevMPContract.nftProfiles(i);
        NFTProfile memory temp = NFTProfile( id,price,url,artist, is_auction, start_time, end_time, buy_now_price, min_step, limit, is_timed);    
        nftProfiles[nftProfiles_length] = temp;
        nftProfiles_length++;
        
        if (is_auction){
            setAucitonDataFromPrevContract(id);
        }
        
        
      }
      
      
    }
  
   function setAucitonDataFromPrevContract(uint32 id) internal{
        (uint256 current_price, address current_winner, uint256 prev_price, 
            address previous_winner, bool bought_for_buy_now_price,bool winner_got_token) = prevMPContract.getFullAuctionRecordById(id);
        auctionData[id].current_price = current_price;
        auctionData[id].current_winner = current_winner;
        auctionData[id].prev_price = prev_price;
        auctionData[id].previous_winner = previous_winner;
        auctionData[id].bought_for_buy_now_price = bought_for_buy_now_price;
        auctionData[id].winner_got_token = winner_got_token;
   }
  
    /**
    * @dev removes 'record' to 'database'
    * @param id (profile id)
    *
    */
    function removeNFTProfileAtId(uint32 id) external onlyOwnerOrMarketplaceManager {
         //id is always equal index +1 => index = id-1
         require(id > 0 && id <= nftProfiles_length,"id out of range");
         require(nftProfiles[id-1].id == id,"inconsistent profiles list");
         removeNFTProfileAtIndex(id-1);  
         /*
         for (uint32 i = 0; i < nftProfiles_length; i++){
              if (nftProfiles[i].id == id){
                  removeNFTProfileAtIndex(i);      
                  return;
              }
         }*/
    }
  

  
    /**
    * @dev removes 'record' to 'database'
    * @param index, record number (from 0)
    *
    */
    function removeNFTProfileAtIndex(uint32 index) public onlyOwnerOrMarketplaceManager {
         if (index >= nftProfiles_length) return;
         if (index == nftProfiles_length -1){
             nftProfiles_length--;
         } else {
             for (uint256 i = index; i < nftProfiles_length-1; i++){
                 nftProfiles[i] = nftProfiles[i+1];
                 
                 nftProfiles[i].id = uint32(i)+1; //id should be equal index+1;
                 auctionData[i+1] = auctionData[i+2];
             }
             nftProfiles_length--;
         }
    }
  
  
    /**
    * @dev removes 'record' to 'database'
    * @param id (profile id)
    *
    */
    function removeMyNFTProfileAtId(uint32 id) external onlyArtist {
        require(id > 0 && id <= nftProfiles_length,"id out of range");
        require(nftProfiles[id-1].id == id,"inconsistent profiles list");
        removeMyNFTProfileAtIndex(id-1,msg.sender);    
        /* for (uint32 i = 0; i < nftProfiles_length; i++){
              if (nftProfiles[i].id == id && nftProfiles[i].artist == msg.sender){
                  removeMyNFTProfileAtIndex(i,msg.sender);      
                  return;
              }
         }*/
    }
  
  
    /**
    * @dev removes 'record' to 'database'
    * @param index, record number (from 0)
    *
    */
    function removeMyNFTProfileAtIndex(uint32 index, address artist) public onlyArtist {
         require (msg.sender == artist || msg.sender == _own_address, "only artist or internal call");
         require ( nftProfiles[index].artist == artist, "only for own profiles");
         if (index >= nftProfiles_length) return;
         if (index == nftProfiles_length -1){
             nftProfiles_length--;
         } else {
             for (uint256 i = index; i < nftProfiles_length-1; i++){
                 nftProfiles[i] = nftProfiles[i+1];
                 
                 nftProfiles[i].id = uint32(i)+1; //id should be equal index+1;
                 auctionData[i+1] = auctionData[i+2];
             }
             nftProfiles_length--;
         }
    }
  
    /**
    * @dev replaces 'record' in the 'database'
    * @param id, unique id of profile
    * @param price, price of NFT assets which will be generated based on profile
    * @param url, url of NFT assets which will be generated based on profile
    * 
    */
    function replaceNFTProfileAtId(   uint32 id, 
                                        uint256 price, 
                                        string calldata url,
                                        address artist,
                                        bool is_auction, 
                                        uint256 start_time, 
                                        uint256 end_time, 
                                        uint256 buy_now_price,
                                        uint256 min_step,
                                        uint256 limit,
                                        bool is_timed
                                        
        ) external onlyOwnerOrMarketplaceManager {
            //id should be equal index+1;
            require(id > 0 && id <= nftProfiles_length,"id out of range");
            require((is_timed && !is_auction) || !is_timed,"cannot be timed & auction" );
            require((limit>1 && !is_auction) || limit == 1, "auction only for uinque items");
            require(nftProfiles[id-1].id == id,"inconsistent profiles list");
            uint256 index = id-1;
         
            nftProfiles[index].price = price;
            nftProfiles[index].url = url;
            nftProfiles[index].artist = artist;
            nftProfiles[index].is_auction = is_auction;
            nftProfiles[index].start_time = start_time; 
            nftProfiles[index].end_time = end_time;
            nftProfiles[index].buy_now_price = buy_now_price;
            nftProfiles[index].min_step = min_step;
            nftProfiles[index].limit = limit;
            nftProfiles[index].is_timed = is_timed;
            
            if (is_auction){
              auctionData[id].current_price = price;
              auctionData[id].current_winner = 0x0000000000000000000000000000000000000000;
            }
                 
    }
  
  
    /**
    * @dev replaces 'record' in the 'database'
    * @param id, unique id of profile
    */
    function replaceMyNFTProfileAtId(   uint32 id, 
                                        uint256 price, 
                                        string calldata url, 
                                        bool is_auction, 
                                        uint256 start_time, 
                                        uint256 end_time, 
                                        uint256 buy_now_price,
                                        uint256 min_step,
                                        uint256 limit,
                                        bool is_timed
        ) external onlyArtist {
            require(id > 0 && id <= nftProfiles_length,"id out of range");
            require((is_timed && !is_auction) || !is_timed,"cannot be timed & auction" );
            require((limit>1 && !is_auction) || limit == 1, "auction only for uinque items");
            require(nftProfiles[id-1].id == id,"inconsistent profiles list");
            require(nftProfiles[id-1].artist == msg.sender,"only for own profiles");
            uint256 index = id-1;
            
            nftProfiles[index].price = price;
            nftProfiles[index].url = url;
            nftProfiles[index].artist = msg.sender;
            nftProfiles[index].is_auction = is_auction;
            nftProfiles[index].start_time = start_time; 
            nftProfiles[index].end_time = end_time;
            nftProfiles[index].buy_now_price = buy_now_price;
            nftProfiles[index].min_step = min_step;
            nftProfiles[index].limit = limit;
            nftProfiles[index].is_timed = is_timed;
            
            if (is_auction){
              auctionData[id].current_price = price;
              auctionData[id].current_winner = 0x0000000000000000000000000000000000000000;
            }
    }
  
  
  
    /**
    * @dev return nft profile details (all fields)
    */
    function viewNFTProfileDetails(uint32 id) external view 
      returns(  uint256 price,
                string memory uri, 
                address artist,
                bool is_auction, 
                uint256 start_time, 
                uint256 end_time, 
                uint256 buy_now_price,
                uint256 min_step,
                uint256 limit,
                bool is_timed){
           
        //if out of range         
        if (id < 1 || id > nftProfiles_length){
            return (BAD_PRICE, BAD_URL, 0x0000000000000000000000000000000000000000,false,0,0,0,0,0,false);    
        }   
        
       
        
        //if consistent profiles list
        uint256 index = id-1;  
        if (nftProfiles[index].id == id){
                  return (  nftProfiles[index].price, 
                            nftProfiles[index].url, 
                            nftProfiles[index].artist,
                            nftProfiles[index].is_auction,
                            nftProfiles[index].start_time, 
                            nftProfiles[index].end_time,
                            nftProfiles[index].buy_now_price,
                            nftProfiles[index].min_step,
                            nftProfiles[index].limit,
                            nftProfiles[index].is_timed
                          );     
        } else { //if not consistent..
            return (BAD_PRICE, BAD_URL, 0x0000000000000000000000000000000000000000,false,0,0,0,0,0,false);
        }
         
         
    }
  
    /**
    * @dev - get auction winner (wallet)
    */    
    function getAuctionWinner(uint32 profileID) external view returns(address, uint256){
        if (auctionIsOverTime(profileID) || auctionData[profileID].bought_for_buy_now_price){
             (uint256 current_price, address current_winner, , ) = getAuctionRecordById(profileID);
             return (current_winner, current_price);
        } else {
            return (0x0000000000000000000000000000000000000000,0);
        }
       
    }
 
    /**
    * @dev - update winner, internal function called during bidding (from bidForNFT)
    * updates auction record
    */  
    function updateWinner(uint32 id, uint256 new_price, address new_winner) internal {
       auctionData[id].prev_price =  auctionData[id].current_price;
       auctionData[id].previous_winner =  auctionData[id].current_winner;
       auctionData[id].current_price = new_price;
       auctionData[id].current_winner = new_winner;
       
       //check if it is fist bid, just return
       if (auctionData[id].previous_winner == 0x0000000000000000000000000000000000000000) return;
       
       //+return tokens to prev winner
     
       require(_own_address.balance >= auctionData[id].prev_price, "unsufficient funds");
       
       ///
       bool success = false;
       // ** sendTo.transfer(amount);** 
       (success, ) = auctionData[id].previous_winner.call{value: auctionData[id].prev_price}("");
       require(success, "auction tokens return failed");
       ///
    
        
        if (isBuyNowPrice(id,new_price)){
            auctionData[id].bought_for_buy_now_price = true;
        }
    }
  
 
    /**
    * @dev - get auction record (4 first fields)
    */  
    function getAuctionRecordById(uint32 id) internal view returns(uint256 current_price, address current_winner, uint256 prev_price, address previous_winner)  {
           return ( auctionData[id].current_price,
                    auctionData[id].current_winner,
                    auctionData[id].prev_price,
                    auctionData[id].previous_winner);
    }
    
    
   
    /**
    * @dev - get auction record (all fields)
    */  
    function getFullAuctionRecordById(uint32 id) public view returns( uint256 current_price, 
                                                                        address current_winner, 
                                                                        uint256 prev_price, 
                                                                        address previous_winner,
                                                                        bool bought_for_buy_now_price,
                                                                        bool winner_got_token
                                                                        )  {
           return ( auctionData[id].current_price,
                    auctionData[id].current_winner,
                    auctionData[id].prev_price,
                    auctionData[id].previous_winner,
                    auctionData[id].bought_for_buy_now_price,
                    auctionData[id].winner_got_token);
    }
      
 
    /**
    * @dev - get auction min step
    */  
    function getAuctionMinStepById(uint32 id) public  view returns (uint256){
        //if out of range        
        if (id < 1 || id > nftProfiles_length){
            return 0;
        }    
        
        //if consistent..
        uint256 index = id-1;
        if (nftProfiles[index].id == id){
              return nftProfiles[index].min_step;
        } else { //if not consistent
            return 0;
        }
     
    }
  
  
    /**
    * @dev - get auction start & end time
    */  
    function getAuctionStartEnd(uint32 id) public  view returns (uint256 start_time, uint256 end_time){
        //if out of range        
        if (id < 1 || id > nftProfiles_length){
            return (0,0);
        }    
        
        //if consistent..
        uint256 index = id-1;
        if (nftProfiles[index].id == id){
            return (nftProfiles[index].start_time, nftProfiles[index].end_time);
        } else { //if not consistent
            return (0,0);    
        }
      
    }
  
  
    /**
    * @dev get price by id from 'database'
    * @param id, unique id of profiles
    */
    function getPriceById(uint32 id) public  view returns (uint256){
        
        //if out of range        
        if (id < 1 || id > nftProfiles_length){
             return BAD_PRICE;    
        }
        
        //if consistent..
        uint256 index = id-1;
        if (nftProfiles[index].id == id){
            return nftProfiles[index].price;
        } else { //if not consistent
            return BAD_PRICE;    
        }
      
    }
  
  
    /**
    * @dev get 'buy now' auction price by id from 'database'
    * @param id, unique id of profiles
    */
    function getBuyNowPriceById(uint32 id) public  view returns (uint256){
        //if out of range        
        if (id < 1 || id > nftProfiles_length){
             return BAD_PRICE;    
        }
        
        //if consistent..
        uint256 index = id-1;
        if (nftProfiles[index].id == id){
            return nftProfiles[index].buy_now_price;    
        } else {
            return BAD_PRICE;    
        }
      
    }
  

    /**
    * @dev - check if price is 'buy now' price for auction
    */
    function isBuyNowPrice(uint32 id, uint256 price) public view returns(bool){
      uint256 buy_now_price = getBuyNowPriceById(id);
      if (buy_now_price == BAD_PRICE) return false;
      if (price >= buy_now_price){
          return true;
      } else {
          return false;
      }
    }
 
  
    /**
    * @dev set new price for asset (profile of NFT), price for which customer can buy
    * @param id, unique id of profiles
    * 'admin level' - i.e. admin can set prices for all profiles
    */
    function setPriceById(uint32 id, uint256 new_price) external onlyOwnerOrMarketplaceManager{
        require(id > 0 && id <= nftProfiles_length,"id out of range");    
        require(nftProfiles[id-1].id == id,"inconsistent profiles list");
    
        nftProfiles[id-1].price = new_price;
    }
  
  
    /**
    * @dev set new price for asset (profile of NFT), price for which customer can buy
    * @param id, unique id of profiles
    * only for artist own items (i.e. calling wallet should be artist of that profile)
    */
    function setMyPriceById(uint32 id, uint256 new_price) external onlyArtist{
        require(id > 0 && id <= nftProfiles_length,"id out of range");    
        require(nftProfiles[id-1].id == id,"inconsistent profiles list");
        require(nftProfiles[id-1].artist == msg.sender,"only for own profiles");
        
        nftProfiles[id-1].price = new_price;
    }
  
  
    /**
    * @dev get url by id from 'database'
    * @param id, unique id of profiles
    */ 
    function  getUrlById(uint32 id) public view returns (string memory){
        //if out of range        
        if (id < 1 || id > nftProfiles_length){
             return BAD_URL;    
        }
        
        //if consistent..
        uint256 index = id-1;
        if (nftProfiles[index].id == id){
            return nftProfiles[index].url;
        } else { // if not consistent
            return BAD_URL;
        }

    }
    
    
    function  getLimitById(uint32 id) public view returns (uint256){
        uint256 cur_time = block.timestamp;
      
        if (id < 1 || id > nftProfiles_length){
            return BAD_NFT_PROFILE_ID;    
        }
      
       
        uint256 index = id-1;
        //if consistent..
        if (nftProfiles[index].id == id){
             if (nftProfiles[index].is_timed ){
                if (cur_time >= nftProfiles[index].start_time && cur_time <= nftProfiles[index].end_time){
                    return 1; //i.e. 'unlimited' within specific time range   
                } else {
                    return 0; //range is over   
                }
                  
             } else {
                 return nftProfiles[index].limit;
             }
        } else { //if not consistent
             return BAD_NFT_PROFILE_ID;    
        }
      
     
    }
  
      
    /**
    * @dev - check if specific 'nft profile' is auction
    */    
    function  isAuctionByProfileId(uint32 id) public view returns (bool){
        if (id < 1 || id > nftProfiles_length){
            return false;    
        }
        
       
        uint256 index = id-1;
        //if consistent
        if (nftProfiles[index].id == id){
            return nftProfiles[index].is_auction;
        } else { //if not consistent
            return false;    
        }
     
    }
  
    function  isTimedByProfileId(uint32 id) public view returns (bool){
        if (id < 1 || id > nftProfiles_length){
            return false;    
        }
        
        uint256 index = id-1;
        //if consistent
        if (nftProfiles[index].id == id){
             return nftProfiles[index].is_timed;
        } else { //if not consistent
             return false;    
        }
     
    }
  
   
    /**
    * @dev accepts payment only in ETH for mint NFT & calls external contract
    * it is public function, i.e called by buyer via dApp
    * buyer selects profile (profileID), provides own wallet address (_to)
    * and dApp provides available _tokenId (for flexibility its calculation is not automatic on 
    * smart contract level, but it is possible to implement) - > nftContract.totalSupply()+1
    * why not recommended: outsite of smart contract with multiple simultaneous customers we can 
    * instanteneusly on level of backend determinte next free id.
    * on ArtGalleryTokens smartcontract level it can be only calculated correctly after mint transaction is confirmed
    * here utility function is implemented which is used by backend ,getNextTokenId()
    * it is also possible to use setNextTokenId function (by owner) to reset token id if needed
    * normal use is dApp requests next token id (tid = getNextTokenId()) and after that
    * calls publicMint(profile, to, tid)
    * it allows different dApps use different token ids areas
    * like   dapp1: tid = getNextTokenId() + 10000
    *        dapp2: tid = getNextTokenId() + 20000
    */
    function buyNFT(          //'buy' == mint NFT token function, provides NFT token in exchange of eth    
        uint32 profileID,       //id of NFT profile
        uint256 ethAmount,     //amount of eth we check it is equal to price, amount in real form i.e. 18 decimals
        address _to,            //where to deliver 
        uint256 _tokenId        //with which id NFT will be generated
      ) 
        external 
        notContract
        payable
    {
        require (getLimitById(profileID) > 0,"limit is over");
        require (!isAuctionByProfileId(profileID),"buy only for non-auction");
        
        uint256 curPrice = getPriceById(profileID);
        require(curPrice != BAD_PRICE, "price for NFT profile not found");
        require(ethAmount > 0, "You need to provide some eth"); //it is already in 'real' form, i.e. with decimals
        require(ethAmount == msg.value,"sent amount do not match");
        require(ethAmount == curPrice,"amount do not correspond price"); //correct work (i.e. dApp calculated price correctly)
        
       
        require(isFreeTokenId(_tokenId), "token id is is occupied"); //adjust on calling party
    
   
        //external contract mint
        try nftContract.mint(_to,_tokenId, getUrlById(profileID)){
            next_token_id++;
            //emit Minted(profileID, _tokenId, msg.sender,  ethAmount, curPrice); 
            uint256 index = profileID-1;
            if (nftProfiles[index].id == profileID){
                //decrease limit
                if (!nftProfiles[index].is_timed) nftProfiles[index].limit--;
              
                //calc comission
                uint256 cmsn = ethAmount.mul(platform_comission);
                cmsn = cmsn.div(10000);
                balances[nftProfiles[index].artist] += ethAmount.sub(cmsn);
                balances[comission_wallet] += cmsn;
            } else {
                require(false,"inconsistent profiles list, mint failed");
            }
            
            
            
        } catch {
            //return payment by using require..it should revert transaction 
            require(false,"mint failed");
        }
    
 
    }
 
    /**
    * @dev - auction bidding for NFT
    */    
    function bidForNFT(          
        uint32 profileID,       //id of NFT profile
        uint256 ethAmount     //amount of eth we check it is equal to price, amount in real form i.e. 18 decimals
      
      ) 
        external 
        notContract
        payable
    {
        require(getLimitById(profileID) == 1, "auctions are only for unique items");
        require(!isTimedByProfileId(profileID), "auctions are not for timed items");       
        require (isAuctionByProfileId(profileID),"it is not auction");
        require(isRightAuctionTime(profileID), "auction - wrong time");
        require(!auctionData[profileID].winner_got_token, "auction is over, winner got token");
        require(!auctionData[profileID].bought_for_buy_now_price, "auction is over, bought for buy now price");
        
        uint256 curPrice = getPriceById(profileID);
        require(curPrice != BAD_PRICE, "price for NFT profile not found");
        require(ethAmount > 0, "You need to provide some eth"); //it is already in 'real' form, i.e. with decimals
        require(ethAmount == msg.value,"sent amount do not match");
        
        require(isRightAuctionPrice(profileID, ethAmount),"wrong bid amount"); //correct work (i.e. dApp calculated price correctly)
        
        //price is right
        //update current_winner 
        updateWinner(profileID,ethAmount,msg.sender);
    }

    /**
    * @dev - finally deliver NFT to auction winner
    */   
    function mintToWinner(uint32 profileID,  uint256 _tokenId) external notContract {
        (uint256 current_price, address current_winner, , ) = getAuctionRecordById(profileID);
        require (auctionIsOverTime(profileID) || auctionData[profileID].bought_for_buy_now_price, "auction has not ended");
        require (current_winner == msg.sender, "you are not the winner");
        require(isFreeTokenId(_tokenId), "token id is occupied"); //adjust on calling party
        require(!auctionData[profileID].winner_got_token, "winner got token");

            //external contract mint
        try nftContract.mint(msg.sender,_tokenId, getUrlById(profileID)){
            next_token_id++;
            auctionData[profileID].winner_got_token = true;
            
            uint256 index = profileID-1;
            if (nftProfiles[index].id == profileID){
                  //calc comission
                  uint256 cmsn = current_price.mul(platform_comission);
                  cmsn = cmsn.div(10000);
                  balances[nftProfiles[index].artist] += current_price.sub(cmsn);
                  balances[comission_wallet] += cmsn;
            } else {
                require(false,"inconsistent profiles list, mint failed");
            }
            //emit MintedToWinner(profileID, _tokenId, msg.sender, current_price); 
        } catch {
            //return payment by using require..it should revert transaction 
            require(false,"mint failed");
        }
    
        
    }    

   /**
   * @dev 
   * price >=prev_bid + min_step)
   * 
   */     
    function isRightAuctionPrice(uint32 profileID, uint256 bid_price) internal view returns(bool){
        (uint256 current_price, , , ) = getAuctionRecordById(profileID);
        (uint256 min_step) = getAuctionMinStepById(profileID);
        if (bid_price >= current_price.add(min_step)){ 
            return true;
        } else {
            return false;
        }
    }
  
    /**
    * @dev 
    * checks if time is within auction time [start  : end]
    * 
    */   
    function isRightAuctionTime(uint32 profileID) internal view returns(bool){
      (uint256 start_time, uint256 end_time) = getAuctionStartEnd(profileID);
      
      if (block.timestamp >= start_time && block.timestamp <= end_time) {
          return true;
      } else {
          return false;
      }
      
    }
  
    /**
    * @dev - check if auction is over based on current time
    */
    function auctionIsOverTime(uint32 profileID) internal view returns(bool){
      (, uint256 end_time) = getAuctionStartEnd(profileID);
      
      if (block.timestamp > end_time) {
          return true;
      } else {
          return false;
      }
    }
  
  
    /**
    * @dev 'admin level function' - mint token 'for free' 
    * gets profileID, wallet to where token will be delivered (_to), and _tokenId (should be free)
    */
    function adminMint(       //mint for free as admin
        uint32 profileID,       //id of NFT profile
        address _to,            //where to deliver 
        uint256 _tokenId        //with which id NFT will be generated
      ) 
        external 
        onlyOwnerOrMarketplaceManager
      {
        uint256 curPrice = getPriceById(profileID);
        require(curPrice != BAD_PRICE, "price for NFT profile not found");
        require(isFreeTokenId(_tokenId), "token id is occupied");
      
    
        
        //external contract mint
        try nftContract.mint(_to,_tokenId, getUrlById(profileID)){
            next_token_id++;
            //emit AdminMinted(profileID, _tokenId, _to, curPrice); 
        } catch {
            //return payment by using require..it should revert transaction 
            require(false,"mint failed");
        }
        
    }


    /**
    * @dev 'admin level function' - burn specific token 
    */
    function adminBurn(uint256 _tokenId) external  onlyOwnerOrMarketplaceManager returns(uint256){  //burn as admin
        try nftContract.burn(_tokenId) {
            //emit AdminBurned(_tokenId); 
        } catch {
        //ensure error will be send (false, i.e. require is never fulfilled, error send)
            require (false, "NFT burn failed");
        }
      
    }
  
  
    /**
    * @dev by specific tokenId find it's profile id
    */
    function getProfileIdByTokenId(uint256 tokenId) public view returns(uint32){
      string memory url = BAD_URL;
      try nftContract.tokenURI(tokenId) {
        url = nftContract.tokenURI(tokenId);
        return getProfileIdbyUrl(url);
      } catch {
        return BAD_NFT_PROFILE_ID;
      }
     
    }
  
    /**
    * @dev get url to JSON with NFT metadata
    */
    function getProfileIdbyUrl(string memory url) public  view returns (uint32){
      for (uint256 i = 0; i < nftProfiles_length; i++){
          if (keccak256(bytes(nftProfiles[i].url)) == keccak256(bytes(url))){
              return nftProfiles[i].id;
          }
      }
      return BAD_NFT_PROFILE_ID;
    }
  
 
    /**
    * @dev to check if tokenId is free before calling buy/bid from frontend
    */
    function isFreeTokenId(uint256 tokenId) public view returns (bool){
      try nftContract.tokenURI(tokenId) { 
          //if we can run this successfully it means token id is not free -> false
          return false;
      } catch {
          return true; //if we errored getting url by tokenId, it is free -> true
      }
    }
  
   
    /**
    * @dev NFT asset price by profile id
    */
    function getTokenPriceByTokenId(uint256 tokenId) public view returns(uint256){
      string memory url = BAD_URL;
      try nftContract.tokenURI(tokenId) {
        url = nftContract.tokenURI(tokenId);
        uint32 profileId = getProfileIdbyUrl(url);
        if (profileId == BAD_NFT_PROFILE_ID){
            return BAD_NFT_PROFILE_ID;
        } else {
            return getPriceById(profileId);
        }
      } catch {
        return BAD_NFT_PROFILE_ID;
      }
     
    }
  

    
 
 
    /**
     * @dev - returns info on balance of specific wallet 
     */
    function getBalance(address wallet) external view returns(uint256) {
        return balances[wallet];
    }
    
    /**
     * @dev universal function to exract accumulated balances for all balance holders (artists, platform comission wallet)
     * extracts specific amount (in wei)
     */
    function withdrawMyBalance(uint256 ethAmount) external nonReentrant {
        require(ethAmount > 0, "You need to withdraw at least some ether");
    
        require(_own_address.balance >= ethAmount, "unsufficient funds");
        
        require(balances[msg.sender] >= ethAmount, "not enough on your balance");
    
        bool success = false;
        // ** sendTo.transfer(amount);** 
        (success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "withdraw failed");
    }
    
     /**
     * @dev universal function to exract accumulated balances for all balance holders (artists, platform comission wallet)
     * extracts whole accumulated balance
     */
    function withdrawAllMyBalance() external nonReentrant {
        uint256 ethAmount = balances[msg.sender];
        require(ethAmount > 0, "no balance");
      
        require(_own_address.balance >= ethAmount, "unsufficient funds");
        
        require(balances[msg.sender] >= ethAmount, "not enough on your balance");
    
        bool success = false;
        // ** sendTo.transfer(amount);** 
        (success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "withdraw failed");
    }
 
   
    
}