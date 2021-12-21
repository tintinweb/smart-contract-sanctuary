/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

pragma solidity ^0.5.1;

contract SampleContract {
    uint storageData;

    event MamboNumberTwo(uint _value);
    event MamboNumberFive(uint _value);
    event MamboNumberString(string _value);

    function test(uint x, uint y, string memory s) public {
        emit MamboNumberTwo(x);
        emit MamboNumberFive(y);
        emit MamboNumberString(s);
    }
}