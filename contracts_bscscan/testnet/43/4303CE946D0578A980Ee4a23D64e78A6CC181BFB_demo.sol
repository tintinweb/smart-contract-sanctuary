/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

pragma solidity ^0.8.0;

contract demo
{
    
    uint a;
    uint b;
    uint c;
    constructor(uint _a,uint _b) 
    {
        a=_a;
        b=_b;
         c=a+b;
    }
    function total() public view returns(uint)
    {
        
        return c;
    }
}


/*pragma solidity ^0.8.0;

contract demo
{
    function total(uint a , uint b) public pure returns(uint)
    {
        uint c =a+b;
        return c;
    }
}
*/