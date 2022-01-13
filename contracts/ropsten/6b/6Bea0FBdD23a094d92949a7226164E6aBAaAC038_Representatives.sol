/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface Digi {
    function balanceOf(address tokenOwner) external view returns (uint balance);

}

contract Representatives {
    address public tokenAddress;
    uint public representativeMin;
    uint public repMaturation;
    mapping(address => Representative )  public registeredReps;

    struct Representative{
        address _rep;
        uint _startBlock;
        uint _unlockBlock;
    }


    constructor() {
        repMaturation = 10;  //for testing = 10..about 90 seconds
        representativeMin = 10_000e18; // 10000 Digitrade
        tokenAddress = 0x0e8637266D6571a078384A6E3670A1aAA966166F;
    }


    function getUnlockBlock() public view returns (uint){
        return registeredReps[msg.sender]._unlockBlock;
    }

    function getStartBlock() public view returns (uint) {
        return registeredReps[msg.sender]._startBlock;
    }

    function getRep() public view returns (address _repAddress){
        if(msg.sender == registeredReps[msg.sender]._rep){
           _repAddress = msg.sender;
        }
        return _repAddress;
    }

    function registerRep(address _rep) public {
      require(msg.sender == _rep);
      require(Digi(tokenAddress).balanceOf(msg.sender) > representativeMin, "Balance under 10K DGT");
      uint _unlockBlock = block.number + repMaturation;  //unlocks after 30 days or so
      registeredReps[_rep] = Representative(_rep,block.number, _unlockBlock);
    }

}