//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Hodl {
    mapping(address => uint256) public addressToAmount;
    mapping(address => uint256) public addressToHodlTime;
    event Staked(address staker, uint256 amount);
    event Unstaked(address unstaker, uint256 amount);

    function stake(uint256 hodltime) public payable {
        require(msg.value > 0, "Must be greater than zero");
        addressToAmount[msg.sender] += msg.value;
        addressToHodlTime[msg.sender] = block.timestamp + hodltime;
        emit Staked(msg.sender, msg.value);
    }

    function unstake() public {
        require(addressToHodlTime[msg.sender] < block.timestamp, "Your hodl time isn't over yet");
        uint256 withdraw = addressToAmount[msg.sender];
        addressToAmount[msg.sender] = 0;
        addressToHodlTime[msg.sender] = 0;
        payable(msg.sender).transfer(withdraw);
        emit Unstaked(msg.sender, withdraw);
        

    }
}