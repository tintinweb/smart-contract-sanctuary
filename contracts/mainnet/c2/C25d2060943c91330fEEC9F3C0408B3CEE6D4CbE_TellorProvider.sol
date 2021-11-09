pragma solidity 0.4.24;

import "./ITellorGetters.sol";
import "./IMedianOracle.sol";

contract TellorProvider{

    ITellorGetters public tellor;
    IMedianOracle public medianOracle;

    
    struct TellorTimes{
        uint128 time0;
        uint128 time1;
    }
    TellorTimes public tellorReport;
    uint256 constant TellorID = 41;


    constructor(address _tellor, address _medianOracle) public {
        tellor = ITellorGetters(_tellor);
        medianOracle = IMedianOracle(_medianOracle);
    }

    function pushTellor() external {
        (bool retrieved, uint256 value, uint256 _time) = getTellorData(); 
        //Saving _time in a storage value to quickly verify disputes later
        if(tellorReport.time0 >= tellorReport.time1) {
            tellorReport.time1 = uint128(_time);
        } else {
            tellorReport.time0 = uint128(_time);
        }
        medianOracle.pushReport(value);
    }

    function verifyTellorReports() external {
        //most recent tellor report is in dispute, so let's purge it
        if(tellor.retrieveData(TellorID, tellorReport.time0) == 0 || tellor.retrieveData(TellorID,tellorReport.time1) == 0){
            medianOracle.purgeReports();
        }
    }

    function getTellorData() internal view returns(bool, uint256, uint256){
        uint256 _count = tellor.getNewValueCountbyRequestId(TellorID);
        if(_count > 0) {
            uint256 _time = tellor.getTimestampbyRequestIDandIndex(TellorID, _count - 1);
            uint256 _value = tellor.retrieveData(TellorID, _time);
            return(true, _value, _time);
        }
        return (false, 0, 0);
    }

}

pragma solidity 0.4.24;


/**
* @title Tellor Getters
* @dev Oracle contract with all tellor getter functions. The logic for the functions on this contract 
* is saved on the TellorGettersLibrary, TellorTransfer, TellorGettersLibrary, and TellorStake
*/
interface ITellorGetters {
    function getNewValueCountbyRequestId(uint _requestId) external view returns(uint);
    function getTimestampbyRequestIDandIndex(uint _requestID, uint _index) external view returns(uint);
    function retrieveData(uint _requestId, uint _timestamp) external view returns (uint);
}

pragma solidity 0.4.24;

interface IMedianOracle{

    //  // The number of seconds after which the report is deemed expired.
    // uint256 public reportExpirationTimeSec;

    // // The number of seconds since reporting that has to pass before a report
    // // is usable.
    // uint256 public reportDelaySec;
    function reportDelaySec() external returns(uint256);
    function reportExpirationTimeSec() external returns(uint256);
    function pushReport(uint256 payload) external;
    function purgeReports() external;
}