// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Ownable.sol" ;

//@title PRDX Token contract interface
interface PRDX_token {                                     
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function _approve(address owner, address spender, uint256 amount) external ; 
}

//@title PRDX Team Tokens Lock Contract
//@author Predix Network Team
contract PRDXTeamLock is Ownable {
    
    address public token_addr ; 
    PRDX_token token_contract = PRDX_token(token_addr) ;

    uint256 public PERC_per_MONTH = 10 ; 
    uint256 public last_claim ; 
    uint256 public start_lock ;
    
    uint256 public MONTH = 2628000 ; 
    
    uint256 public locked ; 

    /**
     * @dev Lock tokens by approving the contract to take them.
     * @param   value Amount of tokens you want to lock in the contract
     */
    function lock_tokens(uint256 value) public payable onlyOwner {
        token_contract.transferFrom(msg.sender, address(this), value) ; 
    
        locked += value ;
        start_lock = block.timestamp ; 
    }

    /**
     * @dev Withdraw function for the team to withdraw locked up tokens each month starting one month after lockup
     */
    function withdraw() public onlyOwner {
        require(block.timestamp >= start_lock + MONTH, "Cannot be claimed in first month") ;
        require(block.timestamp - last_claim >= MONTH, "Cannot claim twice per month") ; 
        last_claim = block.timestamp ; 
        
        token_contract.transfer(msg.sender, locked * PERC_per_MONTH/100) ; 
    }

    /**
     * @dev Set PRDX Token contract address
     * @param addr Address of PRDX Token contract
     */
    function set_token_contract(address addr) public onlyOwner {
        token_addr = addr ;
        token_contract = PRDX_token(token_addr) ;
    }
    

}