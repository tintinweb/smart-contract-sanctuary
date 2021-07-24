/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity ^0.7.0;

contract test001 {
    
    
    uint256 total;
    
    constructor () public {
        total = 0;
    }
    
    function deposite(uint256 _money) public {
        total += _money;
    }
    
    
    function ball() public view returns (uint256){
        return total;
    }
    
    
}