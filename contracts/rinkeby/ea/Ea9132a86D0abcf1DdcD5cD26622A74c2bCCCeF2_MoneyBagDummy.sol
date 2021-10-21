/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

pragma solidity ^0.8.9;


interface IMoneyBag {
    function deposit(uint32 stakingId) external payable;

    function withdraw(uint32 stakingId) external;

    function currentInterest(uint32 stakingId) view external returns (uint256);
}

contract MoneyBagDummy is IMoneyBag {

    mapping(address => mapping(uint32 => uint256)) deposits;
    uint256 interest = 10e16;

    constructor()  {

    }

    function deposit(uint32 stakingId) external payable {
        deposits[msg.sender][stakingId] = msg.value;
    }

    function withdraw(uint32 stakingId) external {
        (bool success, bytes memory data) = msg.sender.call{value : deposits[msg.sender][stakingId] * interest / 1e18}(abi.encode(stakingId));
        require(success, "Failed to send Ether");
        deposits[msg.sender][stakingId] = 0;
    }

    function currentInterest(uint32 stakingId) view external returns (uint256) {
        return interest;
    }
}