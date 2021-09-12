/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

contract getBalance1{
    
    uint balance;
    
    function setbalance()public{
         balance = 500;
    }
    
    function getBalance()public view returns(uint){
        return balance;
    }
    
}