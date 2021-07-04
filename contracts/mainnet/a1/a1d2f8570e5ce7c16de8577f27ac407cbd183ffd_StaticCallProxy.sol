/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity ^0.8.2;
 
interface IStaticCallProxy {
    function currentState() external view returns (uint256);
    
    function newState() external view returns (uint256);
    
    function updateState() external view returns (uint256);
}

contract StaticCallProxy {
    function currentState() external view returns (uint256) {
        return IStaticCallProxy(0xEf8e447bD63fd3c1eEC349cF4D1DcE19Be7A807c).currentState();
    }
    
    function newState() external view returns (uint256) {
        return IStaticCallProxy(0xEf8e447bD63fd3c1eEC349cF4D1DcE19Be7A807c).newState();
    }
    
    function updateState() external view returns (uint256) {
        return IStaticCallProxy(0xEf8e447bD63fd3c1eEC349cF4D1DcE19Be7A807c).updateState();
    }
}