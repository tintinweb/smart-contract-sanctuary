/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

pragma solidity ^0.8.0;


/*

XAdspace - Dutch auction digital advertisement spaces 

  

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
 *  Integrated with PaySpec for the invoicing 
 *
 */
contract XAdspace {

   mapping(address => AdProgram) public adPrograms;  
   

   //polygon network, 50000 blocks per day approx
   uint256 adspaceAuctionTimeBlocks = 50000 * 7;
 
   struct AdProgram {
     address paymentDelegate; //address to recieve payment      
     address token;

     address renter;
     uint256 startPrice;
     uint256 rentStartBlock;
     string adURL; 

     bool newRentalsAllowed;
      
   }
   
   constructor( uint256 _timeBlocks )   {  
    adspaceAuctionTimeBlocks = _timeBlocks;
  }
   

  function createAdProgram(address token, uint256 startPrice, string calldata initialUrl) public returns (bool) {
    address from = msg.sender; 

    require( !adspaceIsDefined(from) );

    adPrograms[from] = AdProgram( from, token, address(0), startPrice, block.number, initialUrl, true);

    require( adspaceIsDefined(from) );

    return true;
  }


  function buyAdspace(address spaceOwner, address token, uint256 tokens, string calldata adURL) public returns (bool) {
     

    address from = msg.sender;

    require(adspaceIsDefined(spaceOwner), 'That adspace does not exist');
    require(adPrograms[spaceOwner].newRentalsAllowed == true, 'New rentals disallowed');


    uint256 remainingAdspaceValue = getRemainingAdspaceValue(spaceOwner);
 
    if( remainingAdspaceValue > 0  ){  
      //need to pay off the previous owner to refund   for the rest of their time that remained 
       IERC20(adPrograms[spaceOwner].token).transferFrom(from, adPrograms[spaceOwner].renter, remainingAdspaceValue );
    }
 
    uint256 rentalPremium = getAdspaceRentalPremium(spaceOwner);

    if( rentalPremium > 0 ){ 
      //need to pay the adspace owner the rental premium 
      IERC20(adPrograms[spaceOwner].token).transferFrom(from, adPrograms[spaceOwner].paymentDelegate, rentalPremium );
    }

    adPrograms[spaceOwner].renter = from;
    adPrograms[spaceOwner].adURL = adURL;
    adPrograms[spaceOwner].startPrice = remainingAdspaceValue + rentalPremium;
    adPrograms[spaceOwner].rentStartBlock = block.number;

    //make sure the buyer explicity authorizes these values in the input parameters 
    require( token == adPrograms[spaceOwner].token );
    require( tokens >= remainingAdspaceValue + rentalPremium );


    return true;
   

  }


  function setPaymentDelegate( address delegate ) public returns (bool) {
     
      address spaceOwner = msg.sender;

      require(adspaceIsDefined(spaceOwner));
      
      adPrograms[spaceOwner].paymentDelegate = delegate;

      return true; 
  }

  function setNewRentalsAllowed( bool allowed ) public returns (bool) {
     
      address spaceOwner = msg.sender;

      require(adspaceIsDefined(spaceOwner));
      
      adPrograms[spaceOwner].newRentalsAllowed = allowed;

      return true; 
  }


  //can always set price, but can never be lower than what the  current space owners's 
  function setPriceForAdspace( uint256 newPrice) public returns (bool) {
     
      address spaceOwner = msg.sender;

      require(adspaceIsDefined(spaceOwner));
     
      //must be expired, or must be no bounty to pay to the previous renter 
      require ( getRemainingAdspaceValue(spaceOwner) == 0);

      adPrograms[spaceOwner].startPrice = newPrice;

      return true; 
  }

  function setTokenForAdspace(address newToken) public returns (bool) {

      address spaceOwner = msg.sender;

      require(adspaceIsDefined(spaceOwner));
      
      //must be expired, or must be no bounty to pay to the previous renter 
      require ( getRemainingAdspaceValue(spaceOwner) == 0);

      adPrograms[spaceOwner].token = newToken;

      return true; 
  }


  function adspaceTimeRemaining( address spaceOwner ) public view returns (uint256){

      uint256 expirationBlock = adPrograms[spaceOwner].rentStartBlock + adspaceAuctionTimeBlocks;


       if(block.number <= expirationBlock){
         return expirationBlock - block.number; 
       }

       return 0;
     
  }
 
  function adspaceIsDefined( address spaceOwner ) public view returns (bool){
     
      return adPrograms[spaceOwner].token != address(0x0)  ;
  }

  
   
  function getRemainingAdspaceValue( address spaceOwner) public view returns (uint256){
      if(adspaceIsDefined(spaceOwner) && adPrograms[spaceOwner].renter != address(0x0)){
  
        uint256 blocksRemaining = adspaceTimeRemaining(spaceOwner);
 
        return (2 * adPrograms[spaceOwner].startPrice * blocksRemaining / adspaceAuctionTimeBlocks);
         
      }

      return 0;
  }
 
  function getAdspaceRentalPremium( address spaceOwner) public view returns (uint256){
      if(adspaceIsDefined(spaceOwner) && adPrograms[spaceOwner].renter != address(0x0)){

             uint256 blocksRemaining = adspaceTimeRemaining(spaceOwner);
  
        return (adPrograms[spaceOwner].startPrice /2) +  (adPrograms[spaceOwner].startPrice  )  * (  blocksRemaining / adspaceAuctionTimeBlocks);
         
      }

      return  adPrograms[spaceOwner].startPrice  ;
  }
 
    
   
     // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------
 
    fallback() external payable { revert(); }
    receive() external payable { revert(); }
   

}