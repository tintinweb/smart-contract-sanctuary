/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity >=0.4.22 <0.8.0;

contract Storage{
    
    uint256 number;
    
    function store(uint256 num) public {
        number=num;
    }
    
    function retrivev() public view returns (uint256){
        return number;
    }
    
}