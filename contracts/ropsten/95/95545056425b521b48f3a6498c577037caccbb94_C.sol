/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

pragma solidity >0.7.0;
contract C{
    uint public a=1;
    function test() public view returns(uint){
        uint b=a+1;
        return b;
    }
}