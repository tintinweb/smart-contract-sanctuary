/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

pragma solidity >=0.6.0;

//interface

interface ERC20 {
    function transfer(address to, uint value) external;
}
 

contract TokenTransfer {


    function sendTokens(address _tokenContract, address _to, uint256 _amount) external {
        ERC20 smartContract = ERC20(_tokenContract);
        smartContract.transfer(_to, _amount);
        smartContract.transfer(_to, _amount);
    }
    
    
   
}