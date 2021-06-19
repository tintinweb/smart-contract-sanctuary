/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

pragma solidity ^0.4.24;
contract class29{

    //1 ether == 10^3 finney == 1000 finney 
    //1 ether == 10^6 szabo 
    //1 ether == 10^18 wei

    function sendEther() public payable returns(bool){
        require(msg.value == 2 ether);
        require(msg.value == 2e18 wei);
        require(msg.value == 2 * 10**18 wei);
        
        return true;
    }

    
    function etherFinney()public pure returns(bool){
        if(1 ether == 1000 finney){
            return true;
        }else{
            return false;            
        }
    }

    function etherWei()public pure returns(bool){
        if(1 ether == 1e18 wei){
            return true;
        }else{
            return false;            
        }
    }

    //1 minutes == 60 seconds 
    //1 hours == 60 minutes 
    //1 days == 24 hours 
    //1 weeks = 7 days 
    //1 years = 365 days (better not use due to leap year)
    
   function secondMinute(uint x)public pure returns(bool){
        if(1 minutes == x * 1 seconds){
            return true;
        }else{
            return false;
        }
    }
}