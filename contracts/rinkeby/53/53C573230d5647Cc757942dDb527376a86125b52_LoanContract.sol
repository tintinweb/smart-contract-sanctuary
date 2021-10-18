pragma solidity ^0.8.4;

contract LoanContract {
    uint256 timeSet;
    uint256 timeTaken;


    constructor() public {
        timeSet = block.timestamp;
    }



    function timePassed(uint256 unixtime) public {
        timeTaken = block.timestamp - timeSet;
        timeSet = unixtime;
    } 


    function getTime() public view returns(uint256, uint256) {
        return (timeSet, timeTaken);
    }
}