/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

pragma solidity >=0.4.22;

contract Test
{
    address[] public testArr;
    int public count;

    constructor(){
        testArr.push(msg.sender);
    }

    function addToArr() public {
        testArr.push(msg.sender);
    }
}