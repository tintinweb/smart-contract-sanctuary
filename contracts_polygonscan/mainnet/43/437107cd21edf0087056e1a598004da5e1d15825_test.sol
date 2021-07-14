/**
 *Submitted for verification at polygonscan.com on 2021-07-14
*/

pragma solidity 0.8.4;

contract test {
     function add(uint256 a, uint256 b) public pure returns (uint256 c) {
         c = a + b;
     }
     function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
         c = a * b;
     }
     function sub(uint256 a, uint256 b) public pure returns (uint256 c) {
         c = a - b;
     }
     function div(uint256 a, uint256 b) public pure returns (uint256 c) {
         c = a / b;
     }
}