/**
 *Submitted for verification at polygonscan.com on 2021-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CallTest{
    mapping(uint => uint[]) public callingHistory;

    constructor(){
    }

    function recordCall(uint _interval) external{
        callingHistory[_interval].push(block.timestamp);
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param _interval a parameter just like in doxygen (must be followed by parameter name)
    /// @return Documents the return variables of a contract’s function state variable
    function viewCallHistory(uint _interval) external view returns(uint[] memory){
        return callingHistory[_interval];
    }
}