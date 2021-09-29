/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity^0.5.0;

contract SimpleStorage
{
    uint StoreData;
    
    function set(uint x) public
    {
        StoreData= x;
    }
    function get() public view returns(uint)
    {
        return StoreData;
    }
}