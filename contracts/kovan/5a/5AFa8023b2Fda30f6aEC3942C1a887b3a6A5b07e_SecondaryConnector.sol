pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract SecondaryConnector {
    event Info(
        address indexed msgSenderSecondary,
        address indexed thisAddrSecondary,
        address[] tokens
    );
    function getInfo(address[] calldata tokens) external payable {
        emit Info(msg.sender, address(this), tokens);
    }
}

