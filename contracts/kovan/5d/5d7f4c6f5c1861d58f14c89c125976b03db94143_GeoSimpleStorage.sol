/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 < 0.8.0;

contract GeoSimpleStorage {
    // states for variables
    // public can be called by anyone
    // external can only be called from outside the contract, via another contract
    // internal can only called from within the contract and inheireted contracts
    // private only be visible in the specific contract
    
    uint256 tokenid;
    
    struct Token {
        uint256 tokenid;
        string tokendata;
          }
    
    
    Token[] public token;
    mapping(uint256 => string) public tokenIdtotokendata;
    
    

    function addToken(uint256 _tokenid, string memory _tokendata) public {
        token.push(Token(_tokenid, _tokendata));
        tokenIdtotokendata[_tokenid] = _tokendata;
    } 
    
    
}