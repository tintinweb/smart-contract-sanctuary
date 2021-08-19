/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.0;



// File: First.sol

contract First {
    string message;                    //переменная - строка

    constructor() public {
        message = "";                 //установка значения переменной по умолчанию
    }

    function getMessage() public view returns (string memory) {       //геттер
        if ((keccak256(abi.encodePacked((message))) == keccak256(abi.encodePacked((""))))) //строчка не изменена (=пустая) =>вывод сообщения
            return "The message is empty. Please set any string.";
        else
            return message;                                                //строчка не пустая=> вывод строчки
    }

    function setMessage(string memory _str) public returns(string memory) { //запись строки в переменную- сеттер
        message = _str;
    }

}