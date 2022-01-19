/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

pragma solidity 0.6.12;

contract TestContract {

    uint256 num1 = 1;
    uint256 num2 = 24;
    uint256 num3 = 123;

    uint256[] public numbers;

    function addNumbers() public {

        numbers.push(num1);
        numbers.push(num2);
        numbers.push(num3);

    }
}