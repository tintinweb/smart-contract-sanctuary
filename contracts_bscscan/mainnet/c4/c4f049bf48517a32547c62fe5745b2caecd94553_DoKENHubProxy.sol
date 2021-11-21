/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

/**
 *ProxyContract for metaland dashboard forked from metagrow dashboard tracker
*/



// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.6;


/**
 * MainTokenInterface is an interface which represent functions on your
 * main token contract that is able to returns the value which is required by DoKENDividendHub
 **/
 
interface MainTokenInterface {
    function dividendTracker() external view returns(address);
    function rewardToken() external view returns(address);
    function totalFees() external view returns(uint256);
    function tokenRewardsFee() external view returns(uint256);
    function liquidityFee() external view returns(uint256);
    function marketingFee() external view returns(uint256);
    function getTotalDividendsDistributed() external view returns(uint256);
    function getAccountDividendsInfo(address account)
    external
    view
        returns (
          address,
          int256,
          int256,
          uint256,
          uint256,
          uint256,
          uint256,
          uint256
        );
    
    function getNumberOfDividendTokenHolders() external view returns(uint256);
    
    function owner() external view returns(address);
}

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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

contract DoKENHubProxy {
    
    
   address public tokenAddress = 0xD302c09BC32aEF53146B6bA7BC420F5CACa897f6; // META Land
   MainTokenInterface public DoKEN = MainTokenInterface(tokenAddress);
    
    // this function is mandatory, 
    function DoKENGetMainAddress() external view returns(address){
        return tokenAddress;
    }
    function DoKENDividendTrackerAddress() public view returns(address){
        return DoKEN.dividendTracker();
    }
    
    // You have to make a call to your main contract, which returns the value
    // that is required by DoKENDiviendHub Interface
    // pls adjust it to follow with your project contract
    
    function DoKENRewardAddress() public view returns (address) {
        return DoKEN.rewardToken();
    }
    
    function DoKENRewardOnPool() external view returns (uint256) {
        return IERC20(DoKENRewardAddress()).balanceOf(DoKENDividendTrackerAddress());
    }
    
    // totalFee,rewardFee,liquidityFee,marketingFee,developerFee,additionalSellingFee
    function DoKENTokenFees() external view 
    returns ( uint256,uint256,uint256,uint256,uint256,uint256)
      {
        return (
            DoKEN.totalFees(),
            DoKEN.tokenRewardsFee(),
            DoKEN.liquidityFee(),
            DoKEN.marketingFee(),
            0,0
        );
      }
    
    function DoKENRewardDistributed() external view returns (uint256) {
        return DoKEN.getTotalDividendsDistributed();
    }
    
    function dummyGetAccountDividendsInfo(address account) public view returns (
         address,
          int256,
          int256,
          uint256,
          uint256,
          uint256,
          uint256,
          uint256
        ){
            return DoKEN.getAccountDividendsInfo(account);
        }
    
    function DoKENGetAccountDividendsInfo(address account)
    public
    view
        returns (
          address,
          int256,
          int256,
          uint256,
          uint256,
          uint256,
          uint256,
          uint256,
          uint256
        )
      {
          // get the native dividendsinfo first
          // the native returns this value in order
          
          /** 
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
          **/
          
          (address xaccount, int256 xindex, int256 xiterationsUntilProcessed, uint256 xwithdrawableDividends,
          uint256 xtotalDividends,,,) = dummyGetAccountDividendsInfo(account);
         
         // once we get the native, now we only need to get the withdrawnDividend
         uint256 xwithdrawnDividend = xtotalDividends - xwithdrawableDividends;
         
         // now we get all the required data, lets return the required amount as explained on here
         // https://doken.gitbook.io/doken-documentation/dividend-hub/dividend-hub-installation#dokengetaccountdividendsinfo
         
         /** 
          address account,
          int256 index
            int256 iterationsUntilProcessed
            uint256 withdrawableDividends
            uint256 withdrawnDividends
            uint256 totalDividends
            uint256 lastClaimTime
            uint256 nextClaimTime
            uint256 secondsUntilAutoClaimAvailable
        **/
         
         return (
            xaccount,
            xindex,
            xiterationsUntilProcessed,
            xwithdrawableDividends,
            xwithdrawnDividend,
            xtotalDividends,
            0, // we cant get the claim time because of the stack-to-deep error
            0,
            0
         );
      }
      
   function DoKENRewardPaid(address holder) external view returns (uint256) {
       (, , , , uint256 paidAmount, , , , ) = DoKENGetAccountDividendsInfo(holder);
       return paidAmount;
   }
   
    
    function DoKENRewardUnPaid(address holder) external view returns (uint256) {
        (, , , uint256 unpaidAmount, , , , , ) = DoKENGetAccountDividendsInfo(
          holder
        );
       
        return unpaidAmount;
    }
    
    
    function DoKENNumberOfDividendTokenHolders() external view returns (uint256) {
        return DoKEN.getNumberOfDividendTokenHolders();
    }
    
    
}