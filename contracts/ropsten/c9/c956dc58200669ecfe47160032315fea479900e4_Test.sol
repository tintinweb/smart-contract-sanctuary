/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

pragma solidity ^0.5.0;

contract Test
{
    function encode(uint a, string memory b) internal pure returns(string memory)
    {
        return string(abi.encode(a, b));
    }
    function decode(string memory a) internal pure returns(uint, string memory)
    {
        return abi.decode(bytes(a), (uint, string));
    }

    function test(uint a, string calldata b) external pure returns(uint, string memory) {
        string memory encoded = encode(a, b);
        return decode(encoded);
    }    
}