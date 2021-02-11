/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity ^0.5.0;

contract Test
{
    string temp;
    function encode(string memory b) internal pure returns(string memory)
    {
        return string(abi.encode(b));
    }
    function decode(string memory a) internal pure returns(uint, string memory)
    {
        return abi.decode(bytes(a), (uint, string));
    }

    function test(string calldata b) external returns(uint, string memory) {
        string memory encoded = encode(b);
        temp = encoded;
        return decode(encoded);
    } 
    function aa() external view returns(string memory)
    {
        return temp; 
}
}