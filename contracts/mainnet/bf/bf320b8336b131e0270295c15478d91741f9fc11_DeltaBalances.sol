pragma solidity ^0.5.0;

/* 
    Contract for DeltaBalances.github.io V5.
    Check values for multiple ERC20 tokens in a single request
    - token balances
    - token allowances
    - deposited token balances (decentralized exchanges)	
    
    V5 changes:
    - Update to Solidity 0.5 (breaking changes)
    - Add support for alternative balance functions using function selectors
    
    
    Address 0x0 is used to resemble ETH as a token (as used in EtherDelta, IDEX and more).
    
    
    To call the new &#39;generic&#39; functions, this contract uses function selectors based on the hash of function signatures (see getFunctionSelector).
    
    Some useful function signatures (bytes4):
    
    SIGNATURE                      SELECTOR     FUNCTION                   CONTRACTS
    ----------------------------------------------------------------------------------------------------------------------------
    "balanceOf(address)"           0x70a08231   balanceOf(user)            (ERC20, ERC223, ERC777 and more)
    "allowance(address,address)"   0xdd62ed3e   allowance(owner, spender)  (ERC20 tokens)

    "balanceOf(address,address)"   0xf7888aec   balanceOf(token, user)     (EtherDelta, IDEX, Token Store, R1 protocol, and more)
    "getBalance(address,address)"  0xd4fac45d   getBalance(token, user)    (JOYSO)
    "balances(address,address)"    0xc23f001f   balances(user, token)      (Switcheo)
    "balances(address)"            0x27e235e3   balances(user)             (ETHEN ETH)
    "tokens(address,address)"      0x508493bc   tokens(user, tokens)       (ETHEN tokens)
    
    
    
    Preious version (V4)  -> 0x40a38911e470fc088beeb1a9480c2d69c847bcec
*/



// ERC20 contract interface for token transfers.
contract Token {
  function transfer(address to, uint tokens) public returns (bool success);
}

// Exchange contract Interface for EtherDelta and forks.
contract Exchange {
  function balanceOf(address token, address user) public view returns (uint);
}

contract DeltaBalances {
    
  address payable public admin; 

  constructor() public {
    admin = msg.sender;
  }
  
  
  /* admin functionality */

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




  /* public functions */


 /* Get the function selector from a function signature.
    functionSignature: 
      - remove whitespace and variable names.
        use "balanceOf(address,address)"  NOT "balanceOf(address token, address user)"
      
    See the top comment for common selectors.
 */
  function getFunctionSelector(string calldata functionSignature) external pure returns (bytes4) {
    // calculate the keccak256 hash of the function signature and return a 4 bytes value
    return bytes4(keccak256(abi.encodePacked(functionSignature)));
  }

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
  
  /* Check the token allowances of a specific contract for multiple tokens.
     Returns array of deposited token balances in wei units. */
  function tokenAllowances(address spenderContract, address user, address[] calldata tokens) external view returns (uint[] memory allowances) {
    allowances = new uint[](tokens.length);
    
    for(uint i = 0; i < tokens.length; i++) {
      allowances[i] = tokenAllowance(spenderContract, user, tokens[i]); // check token allowance and catch errors
    }    
    return allowances;
  }


  /* Get multiple token balances deposited on a DEX using the traditional balanceOf function (EtherDelta, IDEX, Token Store, R1 protocol and many more).
     Returns array of deposited token balances in wei units. 
     
     This doesn&#39;t use the generic version (below) as this format is the most common and it is more efficient hardcoded
  */
  function depositedBalances(address exchange, address user, address[] calldata tokens) external view returns (uint[] memory balances) {
    balances = new uint[](tokens.length);
    Exchange ex = Exchange(exchange);
    
    for(uint i = 0; i < tokens.length; i++) {
      balances[i] = ex.balanceOf(tokens[i], user); //Errors if exchange does not implement &#39;balanceOf&#39; correctly, use depositedBalancesGeneric instead.
    }    
    return balances;
  }

  /* Get multiple token balances deposited on a DEX with a function selector
       - Selector: hashed function signature, see &#39;getFunctionSelector&#39;  
       - userFist:  determines whether the function uses foo(user, token) or foo(token, user)
     Returns array of deposited token balances in wei units. */
  function depositedBalancesGeneric(address exchange, bytes4 selector, address user, address[] calldata tokens, bool userFirst) external view returns (uint[] memory balances) {
    balances = new uint[](tokens.length);
    
    if(userFirst) {
      for(uint i = 0; i < tokens.length; i++) {
        balances[i] = getNumberTwoArgs(exchange, selector, user, tokens[i]);
      } 
    } else {
      for(uint i = 0; i < tokens.length; i++) {
        balances[i] = getNumberTwoArgs(exchange, selector, tokens[i], user);
      } 
    }
    return balances;
  }
  
  /* Get the deposited ETH balance for a DEX that uses a separate function for ETH balance instead of token 0x0.
       - Selector: hashed function signature, see &#39;getFunctionSelector&#39;  
     Returns deposited balance in wei units. */
  function depositedEtherGeneric(address exchange, bytes4 selector, address user) external view returns (uint) {
    return getNumberOneArg(exchange, selector, user);
  }

  
 /* Private functions */


 /* Check the token balance of a wallet in a token contract.
    Returns 0 on a bad token contract   */
  function tokenBalance(address user, address token) internal view returns (uint) {
    // token.balanceOf(user), selector 0x70a08231
    return getNumberOneArg(token, 0x70a08231, user);
  }
  
  
  /* Check the token allowance of a wallet for a specific contract.
     Returns 0 on a bad token contract.   */
  function tokenAllowance(address spenderContract, address user, address token) internal view returns (uint) {
      // token.allowance(owner, spender), selector 0xdd62ed3e
      return getNumberTwoArgs(token, 0xdd62ed3e, user, spenderContract);
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
  
  // Get an exchange balance requires 2 address arguments ( (token, user) and  (user, token) are both common).
  // selector is the hashed function signature (see top comments)
  function getNumberTwoArgs(address contractAddr, bytes4 selector, address arg1, address arg2) internal view returns (uint) {
    if(isAContract(contractAddr)) {
      (bool success, bytes memory result) = contractAddr.staticcall(abi.encodeWithSelector(selector, arg1, arg2));
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
  
  // check if contract (token, exchange) is actually a smart contract and not a &#39;regular&#39; address
  function isAContract(address contractAddr) internal view returns (bool) {
    uint256 codeSize;
    assembly { codeSize := extcodesize(contractAddr) } // contract code size
    return codeSize > 0; 
    // Might not be 100% foolproof, but reliable enough for an early return in &#39;view&#39; functions 
  }
}