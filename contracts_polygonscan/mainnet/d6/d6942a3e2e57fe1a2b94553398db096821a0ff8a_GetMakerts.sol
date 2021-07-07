/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
interface Compound {
    function getAllMarkets() external view returns (address[] memory);
    
}



contract GetMakerts {
    
    address public COMPTROLLER=0x46220a07F071D1a821D68fA7C769BCcdA3C65430;


    function get() public view returns (address[] memory){
        return Compound(COMPTROLLER).getAllMarkets();
    }


}