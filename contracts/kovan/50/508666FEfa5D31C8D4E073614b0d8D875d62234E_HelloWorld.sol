/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

/*SPDX-License-Identifier: UNLICENSED*/
pragma solidity ^0.8.0;
contract HelloWorld{
    string hello;
    function setHello(string memory _hello) external {
        hello = _hello;
    }
    //se faccio sopra string public hello la get me la fa in automatico
    function getHello() external view returns (string memory){
        return hello;
        
    }
    /*function mul(uint a,uint b) pure {
        return a*b;
    }*/
}