// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface ICAL{
    function calculate()external returns(uint);
} 

contract GameEnd{
    ICAL public ical;
    uint public numb;
    constructor(address _calculator){
        ical = ICAL(_calculator);
    }

    function bet()public returns(uint){
        numb = ical.calculate();
        return numb;
    }
    function readNumb() public view returns(uint) {
        return numb;
    }
}