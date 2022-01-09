/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Token{

    string constant public name = "Token";
    string constant public enName = "TK";
    string constant public symbol = "TEST TOKEN";
    uint constant public number = 1200000000;
    uint constant public decimals = 6;

    function getName() public  pure returns(string memory){
        return name;
    }

    function getEnName() public  pure returns(string memory){
        return enName;
    }

    function getSymbol() public  pure returns(string memory){
        return symbol;
    }

    function getNumber() public  pure returns(uint){
        return number;
    }

    function getDecimals() public  pure returns(uint){
        return decimals;
    }

}