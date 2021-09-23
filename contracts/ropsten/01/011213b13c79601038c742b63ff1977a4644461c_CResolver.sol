/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ICounter {
    function lastExecuted() external view returns (uint256);
    function zero(uint amount) external;
    //function increaseCount(uint amount) external;
}

contract CResolver {
    address public immutable mFiToken;

    constructor(address _mFI) {
        mFiToken = _mFI;
    }

    function checker() external view returns (bool canExec, bytes memory execPayload)
    {
        uint256 lastExecuted = ICounter(mFiToken).lastExecuted();
 
        canExec = (block.timestamp - lastExecuted) > 50;
       
        //canExec1 = ((block.timestamp - lastExecuted) > 180);
        
        execPayload = abi.encodeWithSelector(ICounter.zero.selector, uint256(1));
        //execPayload = abi.encodeWithSelector(ICounter.increaseCount.selector, uint256(100));
    }
}