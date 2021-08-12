/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Bait {
    receive() external payable {}
    
    function bait(address _pickpocket) external {

        (bool success, ) = _pickpocket.delegatecall(abi.encodeWithSignature("finesse(address)", _pickpocket));
        require(success, "Bait: finesse did not go thru :(");
    }
}