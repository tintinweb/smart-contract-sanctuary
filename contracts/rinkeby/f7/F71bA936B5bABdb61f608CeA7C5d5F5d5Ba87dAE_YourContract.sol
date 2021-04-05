/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

pragma solidity >=0.6.0 <0.9.0;

//SPDX-License-Identifier: MIT

// import "hardhat/console.sol";

//import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract YourContract {
    event Deposit(address sender, uint256 amount);
    event Withdraw(address sender, uint256 amount);

    mapping(address => uint256) public balances;

    bool public isActive = false;

    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 2 minutes;

    function deposit() public payable {
        balances[msg.sender] += msg.value;

        if (block.timestamp <= deadline && address(this).balance >= threshold)
            isActive = true;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() public {
        require(block.timestamp > deadline, "Deadline hasn't passed yet");
        require(isActive == false, "Contract is active");
        require(balances[msg.sender] > 0, "You haven't deposited");

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp > deadline) return 0;
        else return deadline - block.timestamp;
    }

    function execute() public {
        require(block.timestamp >= deadline, "Deadline has not been met");
        require(
            address(this).balance >= threshold,
            "Threshold has not been met"
        );
        payable(0x32bb0c7d7e8dB0cDFC635537803CEd4fF83647F4).transfer(
            address(this).balance
        );
    }
}