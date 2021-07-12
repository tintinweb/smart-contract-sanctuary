/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.2;

// import "@openzeppelin/contracts/math/SafeMath.sol";

contract Test {
    // using SafeMath for uint256;
    event Result(uint256 payableValue, uint256 ratio, uint256 iggValue);

    function TestSaleCalc(uint256 payableValue, uint256 ratio) public {
        // uint256 iggAmount = (payableValue.div(1000000000000).mul(ratio)) /
        //     1000000;

        uint256 iggAmount = ((payableValue / 1000000000000) * ratio) / 1000000;

        emit Result(payableValue, ratio, iggAmount);
    }
}