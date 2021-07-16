/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;


interface interfaceA{
    function setA(uint256 value) external;
    function getA() external view returns(uint256);
}


contract ContractB{
    
    function setA(address add,uint256 value) external{
        interfaceA a = interfaceA(add);
        a.setA(value);
    }
    
    function getA(address add) external view returns(uint256){
        interfaceA a = interfaceA(add);
        return a.getA();
    }

}