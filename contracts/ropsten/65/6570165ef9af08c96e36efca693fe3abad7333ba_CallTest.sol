/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

pragma solidity ^0.4.0;

 
contract CallTest{
    
    function callByFun(address _token, address _to , uint256 _amount) public returns (bool){
        bytes4 methodId = bytes4(keccak256("transfer(address,uint256)"));
        return _token.delegatecall(methodId, _to, _amount);
    }
}