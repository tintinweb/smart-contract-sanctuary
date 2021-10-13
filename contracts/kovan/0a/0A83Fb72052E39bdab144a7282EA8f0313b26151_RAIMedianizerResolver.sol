/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: UNLICENSED
//pragma solidity 0.8.0;
pragma solidity ^0.6.7;

interface IResolver {
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

interface IRaiMedianizer {
    function lastUpdateTime() external view returns (uint256);

    function updateResult(address feeReceiver) external;
}


contract RAIMedianizerResolver is IResolver {
    uint16 constant MIN_UPDATE_DELAY = 600;
    // solhint-disable var-name-mixedcase
    address public immutable RAIMEDIANIZER;
    uint16 public updateDelay;

    constructor(address _medianizer, uint16 _updateDelay) public {
        RAIMEDIANIZER = _medianizer;
	require(_updateDelay >= MIN_UPDATE_DELAY, "RAIMedianizerResolver/update-delay-too-small");
	updateDelay = _updateDelay;
    }

    function checker()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 lastUpdateTime = IRaiMedianizer(RAIMEDIANIZER).lastUpdateTime();

        // solhint-disable not-rely-on-time
        canExec = (block.timestamp - lastUpdateTime) > updateDelay;

        execPayload = abi.encodeWithSelector(
            IRaiMedianizer.updateResult.selector,
            msg.sender
        );
    }
}