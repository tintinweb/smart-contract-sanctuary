/**
 *Submitted for verification at FtmScan.com on 2022-01-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

contract Destroy {
    function destroy() external {
        address addr;
        assembly {
            selfdestruct(addr)
        }
    }
}