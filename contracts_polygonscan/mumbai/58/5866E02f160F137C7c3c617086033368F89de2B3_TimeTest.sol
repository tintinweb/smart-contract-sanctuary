pragma solidity 0.8.0;

contract TimeTest {
    uint256 public totalWrites;
    mapping(uint256 => Racer)public raceInfo;
    struct Racer{
        address racer;
        uint32 raceTime;
    }
    function writeTime(uint32 _time)public{
        raceInfo[totalWrites] = Racer({
            racer: msg.sender,
            raceTime: _time
        });
        totalWrites++;
    }

    function raceeInfo(uint256 _page)public view returns(address _racer, uint32 _raceTime){
        return (raceInfo[_page].racer,raceInfo[_page].raceTime);
    }
}