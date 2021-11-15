pragma solidity ^0.5.15;

/*
Governance contract handles all the proof of burn related functionality
*/
contract Governance {
    constructor(uint256 maxDepth, uint256 maxDepositSubTree) public {
        _MAX_DEPTH = maxDepth;
        _MAX_DEPOSIT_SUBTREE = maxDepositSubTree;
    }

    uint256 public _MAX_DEPTH = 4;

    function MAX_DEPTH() public view returns (uint256) {
        return _MAX_DEPTH;
    }

    uint256 public _MAX_DEPOSIT_SUBTREE = 2;

    function MAX_DEPOSIT_SUBTREE() public view returns (uint256) {
        return _MAX_DEPOSIT_SUBTREE;
    }

    // finalisation time is the number of blocks required by a batch to finalise
    // Delay period = 7 days. Block time = 15 seconds
    uint256 public _TIME_TO_FINALISE = 7 days;

    function TIME_TO_FINALISE() public view returns (uint256) {
        return _TIME_TO_FINALISE;
    }

    // min gas required before rollback pauses
    uint256 public _MIN_GAS_LIMIT_LEFT = 100000;

    function MIN_GAS_LIMIT_LEFT() public view returns (uint256) {
        return _MIN_GAS_LIMIT_LEFT;
    }

    uint256 public _MAX_TXS_PER_BATCH = 10;

    function MAX_TXS_PER_BATCH() public view returns (uint256) {
        return _MAX_TXS_PER_BATCH;
    }

    uint256 public _STAKE_AMOUNT = 32 ether;

    function STAKE_AMOUNT() public view returns (uint256) {
        return _STAKE_AMOUNT;
    }
}

