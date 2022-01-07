/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

pragma solidity ^0.8.7;

contract abc
{
    uint256 public  favrtnumber;
    function storenumber(uint _store) public 
    {
        favrtnumber = _store;
    }

    function retrieve() public view returns(uint)
    {
        return favrtnumber;
    }

    function r(uint favrtnumber) public pure
    {
        favrtnumber+favrtnumber;
    }
}