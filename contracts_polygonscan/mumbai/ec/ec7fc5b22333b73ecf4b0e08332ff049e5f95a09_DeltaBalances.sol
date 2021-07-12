/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

/**
 *Submitted for verification at Etherscan.io on 2018-10-13
*/

pragma solidity ^0.4.25;

/* 
    Contract for DeltaBalances.github.io V4.
    Check ERC20 token balances & allowances for multiple tokens in 1 batched request.
    
    V4 changes:
    - Small optimizations.
    - Add token allowances.
    - Removed unused functions.
    
    For the previous versions, see 0x3E25F0BA291F202188Ae9Bda3004A7B3a803599a for code and comments.
    
    Address 0x0 is used to indicate ETH (as used in EtherDelta, IDEX and more).
*/

// Exchange contract Interface for EtherDelta and forks.
contract Exchange {
  function balanceOf(address token, address user) public view returns (uint);
}

// ERC20 contract interface.
contract Token {
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function transfer(address to, uint tokens) public returns (bool success);
  function allowance(address tokenOwner, address spenderContract) public view returns (uint remaining);
}

contract DeltaBalances {
    
  address public admin; 

  constructor() public {
    admin = msg.sender;
  }

  // Limit withdrawals to the contract creator.
  modifier isAdmin() {
    require(msg.sender == admin);
    _;
  }


  // Backup withdraw, in case ETH gets in here.
  function withdraw() external isAdmin {
    admin.transfer(address(this).balance);
  }

  // Backup withdraw, in case ERC20 tokens get in here.
  function withdrawToken(address token, uint amount) external isAdmin {
    require(token != address(0x0) && Token(token).transfer(msg.sender, amount));
  }


  /* Check the token balances of a wallet for multiple tokens.
     Returns array of token balances in wei units. */
  function tokenBalances(address user,  address[] tokens) external view returns (uint[]) {
    uint[] memory balances = new uint[](tokens.length);
    
    for(uint i = 0; i < tokens.length; i++) {
      if(tokens[i] != address(0x0)) { 
        balances[i] = tokenBalance(user, tokens[i]); // check token balance and catch errors
      } else {
        balances[i] = user.balance; // ETH balance    
      }
    }    
    return balances;
  }


  /* Get multiple token balances deposited on a DEX (EtherDelta, IDEX, or similar exchange).
     Returns array of deposited token balances in wei units. */
  function depositedBalances(address exchange, address user, address[] tokens) external view returns (uint[]) {
    Exchange ex = Exchange(exchange);
    uint[] memory balances = new uint[](tokens.length);
    
    for(uint i = 0; i < tokens.length; i++) {
      balances[i] = ex.balanceOf(tokens[i], user); //might error if exchange does not implement balanceOf correctly
    }    
    return balances;
  }

  /* Get multiple token allowances for a contract.
     Returns array of deposited token balances in wei units. */
  function tokenAllowances(address spenderContract, address user, address[] tokens) external view returns (uint[]) {
    uint[] memory allowances = new uint[](tokens.length);
    
    for(uint i = 0; i < tokens.length; i++) {
      allowances[i] = tokenAllowance(spenderContract, user, tokens[i]); // check token allowance and catch errors
    }    
    return allowances;
  }


 /* Check the token balance of a wallet in a token contract.
    Returns 0 on a bad token contract   */
  function tokenBalance(address user, address token) internal view returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size
   
   // is it a contract and does it implement balanceOf() 
    if(tokenCode > 0 && token.call(0x70a08231, user)) {    // bytes4(keccak256("balanceOf(address)")) == 0x70a08231  
      return Token(token).balanceOf(user);
    } else {
      return 0; // not a valid token, return 0 instead of error
    }
  }
  
  
  /* Check the token allowance of a wallet for a specific contract.
     Returns 0 on a bad token contract.   */
  function tokenAllowance(address spenderContract, address user, address token) internal view returns (uint) {
    // check if token is actually a contract
    uint256 tokenCode;
    assembly { tokenCode := extcodesize(token) } // contract code size
   
   // is it a contract and does it implement allowance() 
    if(tokenCode > 0 && token.call(0xdd62ed3e, user, spenderContract)) {    // bytes4(keccak256("allowance(address,address)")) == 0xdd62ed3e
      return Token(token).allowance(user, spenderContract);
    } else {
      return 0; // not a valid token, return 0 instead of error
    }
  }
}