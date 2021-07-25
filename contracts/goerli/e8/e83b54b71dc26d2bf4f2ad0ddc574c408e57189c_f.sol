/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

pragma solidity ^0.6.6;



contract f  {


    uint256  base = 1;

    function set(uint256  price ) public {
        base = price;
    }
    
    function get() public view returns(uint256) {
        
        return base;
    }

}