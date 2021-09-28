/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.7.5;

// SPDX-License-Identifier: MIT @GoPocketStudio
interface IFactory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

}

contract FindPair {
    
    function findPairInDex(address factory, address token0, address[] memory token1Array) external view returns (address) {
        IFactory factoryObj = IFactory(factory);
        for(uint32 i = 0; i < token1Array.length; i++) {
            address pair = factoryObj.getPair(token0, token1Array[i]);
            if(pair != address(0)){
                return pair;
            }
        }
        return address(0);
    }
}