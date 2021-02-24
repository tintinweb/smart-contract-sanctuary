/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity ^0.5.10;




contract ExchangeToken{
 
    
    address payable owner ;
    bool LoukBuying;
    
  
    mapping (address => uint256) users;
    
    constructor () public{
        
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
    require(msg.sender==owner);
    _;
    }
    
    
    function _BayToken(uint256 mount) private 
    {
        
        owner.transfer(mount);
        
    }
    
    function BayToken() external payable returns (bool)
    {
        
        _BayToken( msg.value);
        return true ;
        
    }

}