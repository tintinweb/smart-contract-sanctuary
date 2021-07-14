/**
 *Submitted for verification at polygonscan.com on 2021-07-14
*/

pragma abicoder v2;
pragma solidity ^0.7.0;

contract BulkTokenMetadataV2 {
    struct Token {
        address token_address;
        uint totalSupply;
        uint decimals;
        string symbol;
        string name;
    }
    struct TotalSupply {
        address token_address;
        uint totalSupply;
    }
    struct Decimal {
        address token_address;
        uint decimals;
    }
    struct Symbol {
        address token_address;
        string symbol;
    }
    struct Name {
        address token_address;
        string name;
    }

  function getTokens(address[] calldata tokenAddresses) external view returns (Token[] memory tokens) {
    tokens = new Token[](tokenAddresses.length);
    
    for(uint i = 0; i < tokenAddresses.length; i++) {
      if(isAContract(tokenAddresses[i])) {
        try this.getTokenInfo(tokenAddresses[i]) returns (Token memory token) {
          tokens[i] = token;
        } catch {
          tokens[i] = Token(address(0), 0, 0, "", "");  
        }
      } else {
        tokens[i] = Token(address(0), 0, 0, "", "");   
      }
    }
    return tokens;
  }
  
  function getTokenInfo(address tokenAddress) public view returns (Token memory token) {
    token = Token(tokenAddress, ERC20(tokenAddress).totalSupply(), ERC20(tokenAddress).decimals(), ERC20(tokenAddress).symbol(), ERC20(tokenAddress).name());
  }
  
  function getTokenTotalSupply(address tokenAddress) public view returns (TotalSupply memory token) {
    token = TotalSupply(tokenAddress, ERC20(tokenAddress).totalSupply());
  }
  
  function getTokenDecimals(address tokenAddress) public view returns (Decimal memory token) {
    token = Decimal(tokenAddress, ERC20(tokenAddress).decimals());
  }
  
  function getTokenSymbols(address tokenAddress) public view returns (Symbol memory token) {
    token = Symbol(tokenAddress, ERC20(tokenAddress).symbol());
  }
  
  function getTokenNames(address tokenAddress) public view returns (Name memory token) {
    token = Name(tokenAddress, ERC20(tokenAddress).name());
  }
    
  // check if contract (token, exchange) is actually a smart contract and not a 'regular' address
  function isAContract(address contractAddr) internal view returns (bool) {
    uint256 codeSize;
    assembly { codeSize := extcodesize(contractAddr) } // contract code size
    return codeSize > 0; 
    // Might not be 100% foolproof, but reliable enough for an early return in 'view' functions 
  }
}

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}