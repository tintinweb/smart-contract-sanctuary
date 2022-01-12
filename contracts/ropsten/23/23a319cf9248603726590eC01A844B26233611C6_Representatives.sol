/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
//1/11/2022

interface Digi {
    function balanceOf(address tokenOwner) external view returns (uint balance);

}

contract Representatives {
    address public tokenAddress;
    uint representativeMin;
    uint repMaturation;
    mapping(address => Representative )  public registeredReps;

    struct Representative{
        address _rep;
        uint _startBlock;
        uint _unlockBlock;
    }


    constructor() {
        repMaturation = 10;  //for testing = 10..about 90 seconds
        representativeMin = 10_000e18; // 10000 Digitrade
        tokenAddress = 0x157Ad74590955CFfEad38F6Ec14c61e3eA42a617;
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

    function getRepMin() public view returns (uint){
        return representativeMin;
    }

    function getMaturationTime() public view returns (uint) {
        return repMaturation;
    }

    function registerRep(address _rep) public {
      require(msg.sender == _rep);
      require(Digi(tokenAddress).balanceOf(msg.sender) > representativeMin, "Balance under 10K DGT");
      uint _unlockBlock = block.number + repMaturation;  //unlocks after 30 days or so
      registeredReps[_rep] = Representative(_rep,block.number, _unlockBlock);
    }

}