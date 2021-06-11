/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity ^0.8.4;

contract Test{
        function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
        function test() public view returns(string memory) {
         return string(abi.encodePacked("json(", "https://cd624cd2621d.ngrok.io", "/chain/", "BNB", "/address/", 
            toAsciiString(msg.sender), "/transaction/", "1", "/amount/", "100", ")"));
    }
    
    function test2() public view returns(address) {
         return msg.sender;
    }
}