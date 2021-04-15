/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity 0.8.0;


/*

 Miners Guild 

 Staking contract that supports community-extractable donations 
 
 Donate to stakers of this contract by sending ERC20 tokens to the contract address. 

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



 
 
 
   

interface MintableERC20  {
     function mint(address account, uint256 amount) external ;
     function burn(address account, uint256 amount) external ;
}

 
 
abstract contract ApproveAndCallFallBack {
       function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public virtual;
  }
  
  
  
  
/**
 * 
 * 
 *  Staking contract that supports community-extractable donations 
 *
 */
contract MinersGuild is 
  ApproveAndCallFallBack
{
 
  
  address public _stakeableCurrency; 
  address public _reservePoolToken; 
   
   
   
  constructor(  address stakeableCurrency, address reservePoolToken  ) 
  { 
    
   _stakeableCurrency = stakeableCurrency;
   _reservePoolToken = reservePoolToken;
  }
  
  
 
  
  function stakeCurrency( address from,  uint256 currencyAmount ) public returns (bool){
        
      
      require( IERC20(_stakeableCurrency).transferFrom(from, address(this), currencyAmount ), 'unable to stake'  );
     
      
       uint256 totalReserveTokens = IERC20(_reservePoolToken).totalSupply(); 
    
      //mint reserve token for the staker  
      MintableERC20(_reservePoolToken).mint(from,  _reserveTokensMinted( _stakeableCurrency, currencyAmount, totalReserveTokens) ) ;
      
     return true; 
  }
  
   
  function unstakeCurrency( uint256 reserveTokenAmount, address[] memory claimTokenAddresses) public returns (bool){
        
      uint256 totalReserveTokens = IERC20(_reservePoolToken).totalSupply();
        
       //burn LP token  
      MintableERC20(_reservePoolToken).burn(msg.sender,  reserveTokenAmount ); 
      
      for(uint i =0; i< claimTokenAddresses.length; i++){
       address claimTokenAddress = claimTokenAddresses[i]; 
       uint256 vaultOutputAmount =  _vaultOutputAmount(claimTokenAddress, reserveTokenAmount, totalReserveTokens);
       IERC20(claimTokenAddress).transfer( msg.sender, vaultOutputAmount );
      
      } 
      
      
     return true; 
  }
  
  
  //amount of reserve_tokens to give to staker 
  function _reserveTokensMinted(address currencyToken, uint256 currencyAmount, uint256 totalReserveTokens) internal view returns (uint){
         
      uint256 internalVaultBalance =  IERC20(currencyToken).balanceOf(address(this)); 
      
      uint256 unscaledFutureReserveTokens = totalReserveTokens + currencyAmount;
      
      
      uint256 incomingTokenRatio = (currencyAmount*10000) / internalVaultBalance;
       
       
      return ( ( unscaledFutureReserveTokens)  * incomingTokenRatio) / 10000;
  }
  
  
    //amount of reserve_tokens to give to staker 
  function _vaultOutputAmount(address currencyToken,  uint256 reserveTokenAmount, uint256 totalReserveTokens) internal view returns (uint){
      
      uint256 internalVaultBalance = IERC20(currencyToken).balanceOf(address(this));
      
       
      uint256 burnedTokenRatio = (reserveTokenAmount*10000) / totalReserveTokens  ;
      
       
      return (internalVaultBalance * burnedTokenRatio) / 10000   ;
  }
  
  
  
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public override{
        require(token == _stakeableCurrency);
      
        stakeCurrency(from, tokens);
    }
    
   
   
   

}