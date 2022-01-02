pragma solidity 0.7.5;

contract Blocktimestampcheck{
    uint256 time;

    function getTime() public returns(uint256){
        time = block.timestamp;
        time;

    }

}