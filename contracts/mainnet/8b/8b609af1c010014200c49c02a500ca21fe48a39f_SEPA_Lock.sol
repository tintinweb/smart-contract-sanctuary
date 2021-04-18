// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../Ownable.sol" ;

//@title SEPA Token contract interface
interface SEPA_token {                                     
    function transfer(address to, uint256 amount) external returns (bool);
}

//@title SEPA Lock Contract
contract SEPA_Lock is Ownable {
    
    address public token_addr ; 
    SEPA_token token_contract = SEPA_token(token_addr) ;
    
    bool public m1_withdrawn = false ; 
    bool public m2_withdrawn = false ; 

    /**
     * @dev Set SEPA Token contract address
     * @param _addr Address of SEPA Token contract
     */
    function set_token_contract(address _addr) external onlyOwner {
        token_addr = _addr ;
        token_contract = SEPA_token(token_addr) ;
    }
    
    function withdraw_whitelist(address _addr) external onlyOwner {
        require(block.timestamp >= 162057600, "Cannot withdraw locked whitelist tokens yet. Unlocked: Sun May 09 2021 16:00:00 GMT+0000") ; 
        
        token_contract.transfer(_addr, 9535e18) ; 
    }
    
    function withdraw_seed(address _addr) external onlyOwner {
        require(block.timestamp >= 162316800, "Cannot withdraw locked seed tokens yet. Unlocked: Tue Jun 08 2021 16:00:00 GMT+0000") ; 
        
        token_contract.transfer(_addr, 9378e18) ; 
    }

    function withdraw_marketing1(address _addr) external onlyOwner {
        require(block.timestamp > 162057600, "Cannot withdraw locked marketing1 tokens yet. Unlocked: Sun May 09 2021 16:00:00 GMT+0000") ; 
        require(m1_withdrawn == false) ; 
        
        m1_withdrawn = true ;
        token_contract.transfer(_addr, 1167e18) ;
    }
    
    function withdraw_marketing2(address _addr) external onlyOwner {
        require(block.timestamp > 162316000, "Cannot withdraw locked marketing2 tokens yet. Unlocked: Tue Jun 08 2021 16:00:00 GMT+0000") ; 
        require(m2_withdrawn == false) ; 
        
        m2_withdrawn = true ; 
        token_contract.transfer(_addr, 1166e18) ; 
    }
    
    function withdraw_marketing3(address _addr) external onlyOwner {
        require(block.timestamp > 162576000, "Cannot withdraw locked marketing3 tokens yet. Unlocked: Thu Jul 08 2021 16:00:00 GMT+0000") ; 
    
        token_contract.transfer(_addr, 1166e18) ; 
    }

}