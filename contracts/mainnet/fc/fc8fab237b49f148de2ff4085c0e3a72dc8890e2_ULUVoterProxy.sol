// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

interface ULUStake {
    function totalAccumulatedReward() external view returns (uint);
    function stakingPower(address) external view returns (uint);
}

contract ULUVoterProxy {

    ULUStake public constant stakingPool = ULUStake(0xe2A1e9467B5D18F9cD7e7fEbd4D926DC519EcaEE);

    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return "ULUPOWAH";
    }

    function symbol() external pure returns (string memory) {
        return "ULU";
    }

    function totalSupply() external view returns (uint) {
        return stakingPool.totalAccumulatedReward();
    }

    function balanceOf(address _voter) external view returns (uint) {
        (uint _votes) = stakingPool.stakingPower(_voter);
        return _votes;
    }

    constructor() public {}
}