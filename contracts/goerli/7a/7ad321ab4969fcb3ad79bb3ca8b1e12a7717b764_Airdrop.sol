/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity ^0.4.26;

contract Airdrop {

    
    function batch(address tokenAddr, address []toAddr, uint256 []value) returns (bool){

        require(toAddr.length == value.length && toAddr.length >= 1);

        bytes4 fID= bytes4(keccak256("transferFrom(address,address,uint256)"));

        for(uint256 i = 0 ; i < toAddr.length; i++){

            if(!tokenAddr.call(fID, msg.sender, toAddr[i], value[i])) { 
                revert();
            }
        }
        return true;
    }
    
     
   function test() returns(bytes4 result) {
       bytes4 fID= bytes4(keccak256("transferFrom(address,address,uint256)"));
       return fID;
   }
    
    function batch2(address []toAddr, uint256 []value) returns (bool){
        require(toAddr.length == value.length && toAddr.length >= 1);
        
        bytes4 fID= bytes4(keccak256("transferFrom(address,address,uint256)"));
        
        for(uint256 i = 0 ; i < toAddr.length; i++){
            
            if(!msg.sender.call(fID, msg.sender, toAddr[i], value[i])) { 
                
                revert();
            }
        }
        
        return true;
    }
}