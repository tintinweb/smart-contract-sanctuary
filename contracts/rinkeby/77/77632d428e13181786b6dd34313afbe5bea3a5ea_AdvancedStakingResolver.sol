/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IAdvancedStakingProxy {
    function addRewards() external;
}

contract AdvancedStakingResolver {
    address public immutable AdvStaking;
    address owner;
    uint256 lastExecuted;
    uint256 public interval;

    constructor(address _advStaking) {
        AdvStaking = _advStaking;
        lastExecuted = block.timestamp;
        interval = 86400;
        owner = msg.sender;
    }
    
    function updateInterval(uint256 _interval) external {
        require(msg.sender == owner);
        interval = _interval;
    }

    function checker()
        external
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = (block.timestamp - lastExecuted) > interval;
        if (canExec) {
            lastExecuted = block.timestamp;    
        }
        
        execPayload = abi.encodeWithSelector(
            IAdvancedStakingProxy.addRewards.selector
        );
    }
}