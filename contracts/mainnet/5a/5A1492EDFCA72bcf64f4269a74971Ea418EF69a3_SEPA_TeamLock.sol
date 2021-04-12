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
contract SEPA_TeamLock is Ownable {
    
    address public token_addr ; 
    SEPA_token token_contract = SEPA_token(token_addr) ;

    uint256 public PERC_per_MONTH = 10 ; 
    uint256 public last_claim ; 
    uint256 public start_lock ;
    
    uint256 public MONTH = 2628000 ; 
    
    uint256 public locked ; 

    /**
     * @dev Lock tokens by approving the contract to take them.
     * @param   value Amount of tokens you want to lock in the contract
     */
    function lock_tokens(uint256 value) external payable onlyOwner {
        token_contract.transferFrom(msg.sender, address(this), value) ; 
    
        locked += value ;
        start_lock = block.timestamp ; 
    }

    function withdraw(address _addr) external onlyOwner {
        require(block.timestamp >= start_lock + 6 * MONTH, "Cannot be claimed in first 6 months") ;
        require(block.timestamp - last_claim >= MONTH, "Cannot claim twice per month") ; 
        last_claim = block.timestamp ; 
        
        token_contract.transfer(_addr, locked * PERC_per_MONTH/100) ; 
    }

    /**
     * @dev Set SEPA Token contract address
     * @param addr Address of SEPA Token contract
     */
    function set_token_contract(address addr) external onlyOwner {
        token_addr = addr ;
        token_contract = SEPA_token(token_addr) ;
    }
    

}