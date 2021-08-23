/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-02
*/

pragma solidity  ^0.6.1;


interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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



contract Bishshot 
   {
           
     //define the admin of ICO 
     address public owner;
      
     address public inputtoken;
     address public outputtoken;
     
     bool public claimenabled = false; 
     bool public investingenabled = false;
     uint8 icoindex;
      
     // total Supply for ICO
     uint256 public totalsupply;
     
     
    IBEP20 public naut;
    uint256 public nautlimit = 1000000000;

     mapping (address => uint256)public userinvested;
     address[] public investors;
     mapping (address => bool) public existinguser;
     
     uint256 public maxInvestment = 0;   
    
     //set price of token  
      uint public tokenPrice;                   
 
 
     //hardcap 
      uint public icoTarget;
 
      
      //define a state variable to track the funded amount
      uint public receivedFund;
 

        function checkICObalance() public view returns(uint256 _balance) {

            return IBEP20(0x6507458BB53aec6Be863161641ec28739C41cC97).balanceOf(msg.sender);
        }
        
   

}