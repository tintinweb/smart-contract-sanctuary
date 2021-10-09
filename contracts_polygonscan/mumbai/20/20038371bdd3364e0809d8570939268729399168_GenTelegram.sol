pragma solidity 0.6.12;

contract GenTelegram {
    mapping(address => string) public telegrams;

    function setTelegram(string calldata telegram) external {
        telegrams[msg.sender] = telegram;
    }
}