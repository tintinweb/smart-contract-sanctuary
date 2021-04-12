// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../Ownable.sol" ;

//@title SEPA Token contract interface
interface SEPA_token {                                     
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function _approve(address owner, address spender, uint256 amount) external ; 
}

//@title SEPA Team Tokens Lock Contract
contract SEPA_ReserveRepay is Ownable {
    
    address public token_addr ; 
    SEPA_token token_contract = SEPA_token(token_addr) ;

    uint256 public locked ; 

    function withdraw(uint256 amount, address _addr) external onlyOwner {
        token_contract.transfer(_addr, amount) ; 
    }

    function set_token_contract(address addr) external onlyOwner {
        token_addr = addr ;
        token_contract = SEPA_token(token_addr) ;
    }
    

}