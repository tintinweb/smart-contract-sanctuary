/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma abicoder v2;
pragma solidity ^0.7.0;

contract MultiBalances {
    
  struct TokensToCheck {
        address holder_address;
        address[] token_addresses;
    }
    
    struct Balance {
        address token_address;
        uint balance;
    }
    
    struct Balances {
        address holder_address;
        Balance[] balances;
    }

  /* public functions */

  /* Check the ERC20 token balances of a wallet for multiple tokens.
     Returns array of token balances in wei units. */
  function tokenBalances(address user,  address[] calldata tokens) external view returns (uint[] memory balances) {
    balances = new uint[](tokens.length);
    
    for(uint i = 0; i < tokens.length; i++) {
      if(tokens[i] != address(0x0)) { 
        balances[i] = tokenBalance(user, tokens[i]); // check token balance and catch errors
      } else {
        balances[i] = user.balance; // ETH balance    
      }
    }    
    return balances;
  }
  
  function balancesOneByOne(TokensToCheck[] calldata tokensToCheck) external view returns (Balances[] memory balances) {
      Balances[] memory balances = new Balances[](tokensToCheck.length);
      
      for(uint i = 0; i < tokensToCheck.length; i++) { // holder address and token addresses
        address holderAddress = tokensToCheck[i].holder_address;
        address[] memory tokenAddresses = tokensToCheck[i].token_addresses;
        Balance[] memory tokenBalances = new Balance[](tokenAddresses.length);
        
        for(uint j = 0; j < tokenAddresses.length; j++) { // token addresses
              if (tokenAddresses[j] != address(0x0)) { 
                tokenBalances[j] = Balance(address(tokenAddresses[j]), tokenBalance(holderAddress, tokenAddresses[j]));
              } else {
                tokenBalances[j] = Balance(address(0x0), address(holderAddress).balance); // ETH balance    
              }
          }
          balances[i] = Balances(holderAddress, tokenBalances);
      }
      return balances;
    }

  
 /* Private functions */

 /* Check the token balance of a wallet in a token contract.
    Returns 0 on a bad token contract   */
  function tokenBalance(address user, address token) internal view returns (uint) {
    // token.balanceOf(user), selector 0x70a08231
    return getNumberOneArg(token, 0x70a08231, user);
  }
  
  /* Generic private functions */
  
  // Get a token or exchange value that requires 1 address argument (most likely arg1 == user).
  // selector is the hashed function signature (see top comments)
  function getNumberOneArg(address contractAddr, bytes4 selector, address arg1) internal view returns (uint) {
    if(isAContract(contractAddr)) {
      (bool success, bytes memory result) = contractAddr.staticcall(abi.encodeWithSelector(selector, arg1));
      // if the contract call succeeded & the result looks good to parse
      if(success && result.length == 32) {
        return abi.decode(result, (uint)); // return the result as uint
      } else {
        return 0; // function call failed, return 0
      }
    } else {
      return 0; // not a valid contract, return 0 instead of error
    }
  }

  
  // check if contract (token, exchange) is actually a smart contract and not a 'regular' address
  function isAContract(address contractAddr) internal view returns (bool) {
    uint256 codeSize;
    assembly { codeSize := extcodesize(contractAddr) } // contract code size
    return codeSize > 0; 
    // Might not be 100% foolproof, but reliable enough for an early return in 'view' functions 
  }
}