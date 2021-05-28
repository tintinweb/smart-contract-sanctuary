/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.5.16;

contract EnumTest {
    enum ExampleEnum {
        ExampleOption0,
        ExampleOption1,
        ExampleOption2
    }

    ExampleEnum choice ;

    function getChoice() public view returns(ExampleEnum) {
        return choice;
    }

    function setChoice() public {
        choice = ExampleEnum.ExampleOption2;
    }

    function getEnum(uint number) public pure returns(uint option) {
        return uint(ExampleEnum.ExampleOption0);
    }
}