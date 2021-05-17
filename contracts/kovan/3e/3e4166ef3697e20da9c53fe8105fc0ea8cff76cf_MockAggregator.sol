/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// File: contracts/mock/MockAggregator.sol

pragma solidity ^0.6.12;

contract MockAggregator {
    
    address public reporter;
    mapping(uint8 => string) private prices;

    constructor() public{
        reporter = msg.sender;
    }

    function getLatestStringAnswerByIndex(uint8 _index) external view returns (string memory)
    {
        return prices[_index];
    }

    function reportPrice(uint8 _index, string memory price) external{
        require(msg.sender == reporter, "!reporter");
        prices[_index] = price;
    }
}