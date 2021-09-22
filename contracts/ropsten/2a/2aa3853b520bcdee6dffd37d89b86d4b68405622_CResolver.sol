/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ICounter {
    function lastExecuted() external view returns (uint256);
    function loop(uint256 amount) external;
}

contract CResolver {
    address public immutable TYPES;

    constructor(address _typ) {
        TYPES = _typ;
    }

    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 lastExecuted = ICounter(TYPES).lastExecuted();

        canExec = (block.timestamp - lastExecuted) > 180;

        execPayload = abi.encodeWithSelector(
            ICounter.loop.selector,
            uint256(100)
        );
    }
}