/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

pragma solidity >=0.4.16 <0.9.0;

contract C {
    uint private data;

    function f(uint a) private pure returns(uint b) { return a + 1; }
    function setData(uint a) public { data = a; }
    function getData() public view returns(uint) { return data; }
    function compute(uint a, uint b) public  returns (uint) { return a + b; }
}



contract E is C {
    function g() public returns(uint) {
        uint val = compute(3, 5); // access to internal member (from derived to parent contract)
        return val;
    }
}