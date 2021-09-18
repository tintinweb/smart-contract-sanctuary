/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

pragma solidity >=0.7.0 <0.9.0;

contract TBH
{
    function get() public view returns (string memory) {}
}

contract Hack
{
    string str;        
              
    constructor() {      
        TBH c = TBH(0x585C403bC5c7eb62BF3630c7FeF1F837603bA866);
        str = c.get();
    }         
}