/**
 *Submitted for verification at polygonscan.com on 2021-12-10
*/

pragma solidity >=0.7.0 <0.9.0;

contract TestGelato {


    uint public count = 0;
    uint public lastTimeStamp;
    uint public interval;


    constructor (uint _interval) {
        interval = _interval;
        lastTimeStamp = block.timestamp;
    }

    function checkTime () external view returns(bool canExec) {
        if (block.timestamp > lastTimeStamp + interval) {
            return true;
        }
        return false;
    }


    function increaseCount() external {
        require((block.timestamp > lastTimeStamp + interval), "Neet to wait!");
        count++;
        lastTimeStamp = block.timestamp;
    }


}