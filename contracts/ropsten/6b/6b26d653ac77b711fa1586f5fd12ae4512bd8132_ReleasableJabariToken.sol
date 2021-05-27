pragma solidity ^0.4.24;

import "./JabariToken.sol";

contract ReleasableJabariToken is JabariToken{
    
    bool public released = false;
    
    modifier isReleased(){
        if(!released){
            revert();
        }
        
        _;
    }
    
    constructor(uint256 _initialSupply) JabariToken(_initialSupply) public{}
    
    function release() onlyOwner public{
        released = true;
    }
    
    function transfer(address _to, uint256 _amount) isReleased public{
        super.transfer(_to, _amount);
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) isReleased public returns(bool){
      super.transferFrom(_from, _to, _amount);   
    }
    
    
}