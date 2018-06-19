pragma solidity ^0.4.4;

contract TimeBasedContract
{
    function TimeBasedContract() public {
    }

    function() public payable {
        uint minutesTime = (now / 60) % 60;
        require(((minutesTime/10)*10) == minutesTime);
    }
}