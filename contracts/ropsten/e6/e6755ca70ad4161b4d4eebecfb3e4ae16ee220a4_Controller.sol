pragma solidity 0.4.24;
pragma experimental "v0.5.0";

contract Controller {
    address public votingAddr;
    address public masterVotingAddr;
    address public vestingAddr;

    constructor(
        address _votingAddr, 
        address _masterVotingAddr, 
        address _vestingAddr
    ) public {
        votingAddr = _votingAddr;
        masterVotingAddr = _masterVotingAddr;
        vestingAddr = _vestingAddr;
    }
}