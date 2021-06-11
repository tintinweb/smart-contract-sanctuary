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

   uint256 adspaceAuctionTimeBlocks = 5000;
 
   struct AdProgram {
     address owner;
     address token;

     address renter;
     uint256 startPrice;
     uint256 rentStartBlock;

     string adURL; 
     //uint256 previousPrice;
   }
   
   constructor( uint256 _timeBlocks )   {
  
    adspaceAuctionTimeBlocks = _timeBlocks;
  }
   

  function createAdProgram(address token, uint256 startPrice) public returns (bool) {
    address from = msg.sender; 

    require( !adspaceIsActive(from) );

    adPrograms[from] = AdProgram(from, token, address(0), startPrice, block.number, '');
  }


  function buyAdspace(address spaceOwner, address token, uint256 tokens, string calldata adURL) public returns (bool) {
    //if adspace already exists 

    address from = msg.sender;


    uint256 remainingAdspaceValue = getRemainingAdspaceValue(spaceOwner);
 
    if( remainingAdspaceValue > 0 ){ 
 
      //need to pay off the previous owner to refund   for the rest of their time that remained 
       IERC20(adPrograms[spaceOwner].token).transferFrom(from, adPrograms[spaceOwner].renter, remainingAdspaceValue );
    }



    uint256 rentalPremium = remainingAdspaceValue;// getAdspaceRentalPremium(spaceOwner);
    adPrograms[spaceOwner].owner = from;
 

    //need to pay the adspace owner the rental premium 
    IERC20(adPrograms[spaceOwner].token).transferFrom(from, adPrograms[spaceOwner].owner, remainingAdspaceValue );


    adPrograms[spaceOwner].renter = from;
    adPrograms[spaceOwner].adURL = adURL;
    adPrograms[spaceOwner].startPrice = remainingAdspaceValue + rentalPremium;


    //make sure the buyer explicity authorizes these values in the input parameters 
    require( token == adPrograms[spaceOwner].token );
    require( tokens > remainingAdspaceValue + rentalPremium );


    return true;
   

  }

  //can always set price, but can never be lower than what the  current space owners's 
  function setPriceForAdspace(address spaceOwner, uint256 newPrice) public returns (bool) {

      require (newPrice >= getRemainingAdspaceValue(spaceOwner));

      adPrograms[spaceOwner].startPrice = newPrice;

      return true; 
  }


 
 
  function adspaceIsActive( address spaceOwner ) public view returns (bool){
 
      return adPrograms[spaceOwner].owner != address(0x0)  ;
  }

  
   
  function getRemainingAdspaceValue( address spaceOwner) public view returns (uint256){
      if(adspaceIsActive(spaceOwner)){

        uint256 expirationBlock = adPrograms[spaceOwner].rentStartBlock + adspaceAuctionTimeBlocks;

        
        if(block.number <= expirationBlock){
          uint256 blocksRemaining = expirationBlock - block.number;

          return (2 * adPrograms[spaceOwner].startPrice * blocksRemaining / adspaceAuctionTimeBlocks);
        }

       
      }
      return 0;
  }
 
  function getAdspaceRentalPremium( address spaceOwner) public view returns (uint256){
      if(adspaceIsActive(spaceOwner)){

        uint256 expirationBlock = adPrograms[spaceOwner].rentStartBlock + adspaceAuctionTimeBlocks;

        if(block.number <= expirationBlock){
          uint256 blocksRemaining = expirationBlock - block.number; 

          return (adPrograms[spaceOwner].startPrice /2) +  (adPrograms[spaceOwner].startPrice  )  * (  blocksRemaining / adspaceAuctionTimeBlocks);
        }
       
      }
      return (adPrograms[spaceOwner].startPrice /2);
  }
 
    
   
     // ------------------------------------------------------------------------

    // Don't accept ETH

    // ------------------------------------------------------------------------
 
    fallback() external payable { revert(); }
    receive() external payable { revert(); }
   

}