pragma solidity ^0.4.23;

contract TimeCard {
    string public suicaId;
    uint[] public timeList;
    uint[] public workTimeList;
    
    constructor(string mySuicaId) public {
        suicaId = mySuicaId;
    }
    
    function setTimeStamp(string mySuicaId, uint timeStamp) public {
        require(keccak256(abi.encodePacked(suicaId)) == keccak256(abi.encodePacked(mySuicaId)));
        timeList.push(timeStamp);
        if((timeList.length % 2 ) == 0 ) {
            uint startTime = timeList[timeList.length -2];
            uint endTime = timeList[timeList.length -1];
            uint workTime = getWorkTime(startTime, endTime);
            workTimeList.push(workTime);
        }
    }

    function getWorkTime(uint startTime, uint endTime) internal pure returns(uint){
        uint workTime = endTime - startTime;
        return workTime;
    }
}