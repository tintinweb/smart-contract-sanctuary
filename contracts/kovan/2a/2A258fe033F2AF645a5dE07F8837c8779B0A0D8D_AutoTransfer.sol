// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./KeeperCompatible.sol";
contract AutoTransfer is KeeperCompatibleInterface {
    address payable public to;
    uint public amount;
    uint public frequency;
    uint public lastTimeStamp;
    constructor(address payable _to, uint _amount, uint _frequency) payable{
        to = _to;
        amount = _amount;
        frequency = _frequency;
        lastTimeStamp = block.timestamp;
    }

    function checkUpkeep(bytes calldata ) view external override returns(bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp-lastTimeStamp) > frequency && address(this).balance > amount;
    }

    function performUpkeep(bytes calldata) external override{
        lastTimeStamp = block.timestamp;
        _transfer();
    }

    function _transfer() internal{
        to.transfer(amount);
    }

    receive() payable external{
    }
}