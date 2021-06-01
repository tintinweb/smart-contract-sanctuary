/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

pragma solidity ^0.6.12;
contract call{
    
    
    function _call(address contract_addr,address recipient,uint256 amount) public returns(bool,bytes4){
        
    (bool success , bytes memory data) =contract_addr.call(abi.encodeWithSignature("transfer(address,uint256)",recipient,amount));
      
    require(success && (data.length == 0 || abi.decode(data,(bool))),"call error");
    //return (success, data);
        
    }
}