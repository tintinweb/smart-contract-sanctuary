/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.4.18;

contract Cats{
    string Cat;
    function setCat(string _Cat) public {
        Cat = _Cat;
    }
    function getData() public view returns (string) {
        return (Cat);
    }
}