/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

//daehyukkim

pragma solidity 0.8.0;

contract class_14_1 {
    
    /* uint[] numbers;
    
    function buyLotto(uint number) public view {
        
        for (uint a=0;a<7;a++) {
            
            if(numbers[a]==6) {
            
                numbers[a];
            
            }
            
        }
        
    }*/
    uint balance = 0;
    
    function getsenderBalance() public view returns(uint) {

        return msg.sender.balance;
        
    }

}