/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity >=0.7.0 <0.8.0;

contract MySmartContract {
    function Hello() public view returns (string memory) {
        return "Hello World XieWei";
    }
    function Greet(string memory str) public view returns (string memory) {
        return str;
    }
}