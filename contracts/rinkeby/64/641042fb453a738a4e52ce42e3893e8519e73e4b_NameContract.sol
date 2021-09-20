/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

pragma solidity ^0.4.26;

contract NameContract {
    
    uint data = 10;
    
    function getdata() external view returns(uint)
    {
        return data;
    }
    
    function setdata(uint _a) external 
    {
        data=_a;
    }
    
    function privatedata(uint _ab) private
    {
        data=_ab+10;
    }
}