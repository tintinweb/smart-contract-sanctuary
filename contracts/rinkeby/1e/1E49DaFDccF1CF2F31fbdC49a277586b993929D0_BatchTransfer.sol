/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

contract interfaceTT{
    function transfer(address recipient, uint256 amount) public returns (bool){
        
    }
}

contract BatchTransfer {
    
    function SingleTransfer(address ttAddress,address add,uint256 amount) public returns(bool){
        interfaceTT tt = interfaceTT(ttAddress);
        tt.transfer(add,amount);
        return true;
    }
    
    function BTransfer(address ttAddress,address[] memory adds,uint256[] memory amounts) public returns(bool){
        interfaceTT tt = interfaceTT(ttAddress);
        for(uint256 i = 0;i < adds.length;i++){
            require(tt.transfer(adds[i],amounts[i]));
        }
        return true;
    }
    
    
    // function BTransfer(address[] memory adds,uint256[] memory amounts) public returns(bool){
    //     for(uint256 i = 0;i < adds.length;i++){
    //         require(tt.call(bytes4(keccak256("transfer(address,uint256)")),{adds[i],amounts[i])});
    //     }
    //     return true;
    // }
    
    
}