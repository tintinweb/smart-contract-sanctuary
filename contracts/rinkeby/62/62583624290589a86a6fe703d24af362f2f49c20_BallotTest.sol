/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

pragma solidity ^0.8.0;
contract BallotTest {
function test(string calldata a, string calldata b,string calldata c) public pure returns (string memory) {

return string(abi.encodePacked(a,b,c)) ;
}
}