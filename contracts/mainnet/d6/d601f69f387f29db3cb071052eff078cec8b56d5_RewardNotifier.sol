pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RewardNotifier is Ownable {
    function execute(address[] calldata targets, bytes[] memory data) external onlyOwner {
        bool success;
        bytes memory returnData;
        require(targets.length == data.length, "INVALID_INPUT");
        for (uint i = 0; i < targets.length; i++) {
            (success, returnData) = targets[i].call(data[i]);
            require(success, string(returnData));
        }
    }
}