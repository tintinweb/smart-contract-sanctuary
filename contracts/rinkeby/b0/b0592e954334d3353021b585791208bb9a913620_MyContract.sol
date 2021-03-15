/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity ^0.8.0;

/**
 * Simple "Hello World" smart contract on Solidity.
 */
contract MyContract {
    // string public str = "Hello World!";
    int256 public x = 10;

    // function getStr() public view returns(string) {
    //     return str;
    // }

    function plus(int256 temp) public view returns(int256) {
        return x + temp;
    }
}