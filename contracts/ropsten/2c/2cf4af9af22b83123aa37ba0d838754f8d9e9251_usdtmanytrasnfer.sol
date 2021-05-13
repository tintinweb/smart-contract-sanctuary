/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity >=0.8;



interface ERC20 {
    function transfer(address to, uint value) external;
}
 

contract usdtmanytrasnfer {


    function sendTokens(address _tokenContract, address _to, uint256 _amount) external {
        ERC20 smartContract = ERC20(_tokenContract);
       
            smartContract.transfer(_to, _amount); 
            
       
        
    }
    
    
   
}