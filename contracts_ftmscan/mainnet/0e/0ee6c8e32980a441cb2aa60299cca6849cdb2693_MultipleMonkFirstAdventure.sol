/**
 *Submitted for verification at FtmScan.com on 2021-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


interface IMonkFirstAdventure {
    function adventure(uint _summoner) external;
}

contract MultipleMonkFirstAdventure {
    IMonkFirstAdventure constant mfa = IMonkFirstAdventure(0xbcedCE1e91dDDA15acFD10D0E55febB21FC6Aa38);
    
    address payable  owner;
 
    constructor() { owner = payable(msg.sender); }
    
    function multiple_adventure(uint[] calldata _summoners) external {
        for (uint256 i = 0; i < _summoners.length; i++) {
            mfa.adventure(_summoners[i]);
        }
    }

    function destroy() external {
        require(msg.sender == owner, "Only owner can call this function.");
        selfdestruct(owner);
    }
}