/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

pragma solidity ^0.7.4;

contract OyVer{
    
    int256 akpoyu=0;
    int256 chpoy=0;
    
    function akpOyVer() public view {
         akpoyu+1;
    }
    
    function akpOySayir() public view returns (int256) {
        return akpoyu;
    }
    
    function chpOyVer() public view {
         chpoy+1;
    }
    
    function chpOySayir() public view returns (int256) {
        return chpoy;
    }
    
    
    
    
    
}