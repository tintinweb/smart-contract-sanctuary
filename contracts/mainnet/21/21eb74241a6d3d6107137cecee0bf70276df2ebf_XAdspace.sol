/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity ^0.8.0;


/*

XAdspace - Dutch auction digital advertisement spaces 

  v0.15.4

*/
                                                                                 
  
 


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


  
  
/**
 * 
 * 
 *  Dutch auction digital advertisement spaces
 *
 * 
 */
contract XAdspace {

   mapping(bytes32 => AdProgram) public adPrograms;  

   mapping(address => uint256) public adProgramNonces;  
   

   //polygon network, 50000 blocks per day approx
   uint256 public adspaceAuctionTimeBlocks = 50000 * 7;
 
   struct AdProgram {

     address programOwner;
     string programName;
     address paymentDelegate; //address to recieve payment      
     address token;

     address renter;
     uint256 startPrice;
     uint256 rentStartBlock;
     string adURL; 

     bool newRentalsAllowed;
      
   }

   event BoughtAdspace(bytes32 programId, address programOwner, address token, uint256 tokens, string adURL, address renter);
   event CreatedAdProgram(bytes32 programId, address programOwner, address token, uint256 tokens, string adURL);


   
  constructor( uint256 _timeBlocks )   {  
    adspaceAuctionTimeBlocks = _timeBlocks;
  }

   
   

  function createAdProgram(address token, uint256 startPrice, string calldata programName, string calldata initialUrl ) public returns (bool) {
    
    address from = msg.sender; 
 
    bytes32 programId = keccak256(abi.encodePacked(from, adProgramNonces[from]++));

    require( !adspaceIsDefined(programId) );

    adPrograms[programId] = AdProgram( from, programName, from, token, address(0), startPrice, block.number, initialUrl, true);

    require( adspaceIsDefined(programId) );

    emit CreatedAdProgram(programId, from, token, startPrice, initialUrl);

    return true;
  }


  function buyAdspace(bytes32 programId, address token, uint256 tokens, string calldata adURL) public returns (bool) {
     

    address from = msg.sender;

    require(adspaceIsDefined(programId), 'That adspace does not exist');
    require(adPrograms[programId].newRentalsAllowed == true, 'New rentals disallowed');


    uint256 remainingAdspaceValue = getRemainingAdspaceValue(programId);
 
    if( remainingAdspaceValue > 0  ){  
      //need to pay off the previous owner to refund   for the rest of their time that remained 
       IERC20(adPrograms[programId].token).transferFrom(from, adPrograms[programId].renter, remainingAdspaceValue );
    }
 
    uint256 rentalPremium = getAdspaceRentalPremium(programId);

    if( rentalPremium > 0 ){ 
      //need to pay the adspace owner the rental premium 
      IERC20(adPrograms[programId].token).transferFrom(from, adPrograms[programId].paymentDelegate, rentalPremium );
    }

    adPrograms[programId].renter = from;
    adPrograms[programId].adURL = adURL;
    adPrograms[programId].startPrice = remainingAdspaceValue + rentalPremium;
    adPrograms[programId].rentStartBlock = block.number;

    //make sure the buyer explicity authorizes these values in the input parameters 
    require( token == adPrograms[programId].token );
    require( tokens >= remainingAdspaceValue + rentalPremium );

    emit BoughtAdspace(programId, adPrograms[programId].programOwner, token, remainingAdspaceValue + rentalPremium, adURL, from);


    return true;
   

  }


  function setPaymentDelegate( bytes32 programId, address delegate ) public returns (bool) {
     
      require(adPrograms[programId].programOwner == msg.sender);

      require(adspaceIsDefined(programId));
      
      adPrograms[programId].paymentDelegate = delegate;

      return true; 
  }

  function setNewRentalsAllowed(  bytes32 programId, bool allowed ) public returns (bool) {
     
      require(adPrograms[programId].programOwner == msg.sender);

      require(adspaceIsDefined(programId));
      
      adPrograms[programId].newRentalsAllowed = allowed;

      return true; 
  }


  //can always set price, but can never be lower than what the  current space owners's 
  function setPriceForAdspace(bytes32 programId, uint256 newPrice) public returns (bool) {
     
       
      require(adPrograms[programId].programOwner == msg.sender);

      require(adspaceIsDefined(programId));
     
      //must be expired, or must be no bounty to pay to the previous renter 
      require ( getRemainingAdspaceValue(programId) == 0);

      adPrograms[programId].startPrice = newPrice;

      return true; 
  }

  function setTokenForAdspace(bytes32 programId, address newToken) public returns (bool) {
 
      require(adPrograms[programId].programOwner == msg.sender);

      require(adspaceIsDefined(programId));
      
      //must be expired, or must be no bounty to pay to the previous renter 
      require ( getRemainingAdspaceValue(programId) == 0);

      adPrograms[programId].token = newToken;

      return true; 
  }


  function adspaceTimeRemaining( bytes32 programId ) public view returns (uint256){

      uint256 expirationBlock = adPrograms[programId].rentStartBlock + adspaceAuctionTimeBlocks;


       if(block.number <= expirationBlock){
         return expirationBlock - block.number; 
       }

       return 0;
     
  }
 
  function adspaceIsDefined( bytes32 programId ) public view returns (bool){
     
      return adPrograms[programId].token != address(0x0)  ;
  }

  
   
  function getRemainingAdspaceValue( bytes32 programId ) public view returns (uint256){
      if(adspaceIsDefined(programId) && adPrograms[programId].renter != address(0x0)){
  
        uint256 blocksRemaining = adspaceTimeRemaining(programId);
 
        return (2 * adPrograms[programId].startPrice * blocksRemaining / adspaceAuctionTimeBlocks);
         
      }

      return 0;
  }
 
  function getAdspaceRentalPremium( bytes32 programId ) public view returns (uint256){
      if(adspaceIsDefined(programId) && adPrograms[programId].renter != address(0x0)){

             uint256 blocksRemaining = adspaceTimeRemaining(programId);
  
        return (adPrograms[programId].startPrice /2) +  (adPrograms[programId].startPrice  )  * (  blocksRemaining / adspaceAuctionTimeBlocks);
         
      }

      return  adPrograms[programId].startPrice  ;
  }
 
    
   
     // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------
 
    fallback() external payable { revert(); }
    receive() external payable { revert(); }
   

}