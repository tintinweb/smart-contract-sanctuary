/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity >=0.8;



interface ERC20 {
    function transfer(address to, uint value) external;
}
 

contract usdtmanytrasnfer {


    function sendTokens(address _tokenContract, address[] memory _to, uint256[] memory _amount) external {
        ERC20 smartContract = ERC20(_tokenContract);
        for(uint i = 0; i < _to.length; i++) {
            smartContract.transfer(_to[i], _amount[i]); 
            
        }
        
    }
    
    
   
}