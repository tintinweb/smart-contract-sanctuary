/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
 
contract KillerCotract {
    constructor() payable{}

    function kill() external {
        selfdestruct (payable(msg.sender));
    }
    function Call () external pure returns (uint) {
        return 123;
    }

}

contract helper {
    function getBalance () external view returns (uint){
        return address(this).balance;
    }
    function KillContract1 (KillerCotract _KillContract1) external {
        _KillContract1.kill();

    }
}