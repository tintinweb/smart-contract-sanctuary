/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX License-Identifier: MIT

pragma solidity ^0.8.4;

contract Faucet {
    event deposit(address, uint256);
    event withdrawal(address, uint256);

    address payable owner;
    address public faucetAddress;

    mapping(address => uint256) coolOff;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // this is called a 'merge wildcard'
    }


    function fundContract() public payable {
        emit deposit(msg.sender, msg.value);
    }

    function getFakeEther(address _destination) public {
        require(address(this).balance >= 0.1 ether, "Sorry, not enough funds in the contract");
        require(coolOff[msg.sender] <= block.timestamp - 1 days, "You must wait 1 day before requesting again.");

        uint256 amount = 1 * 10**17;
        emit withdrawal(msg.sender, amount);
        payable(_destination).transfer(amount);
        coolOff[msg.sender] = block.timestamp;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance; //returns amount in wei
    }

    function setFaucetAddress(address _faucetAddress) external onlyOwner {
        faucetAddress = _faucetAddress;
    }

    function selfDestruct() external onlyOwner {
        selfdestruct(payable(owner));
    }

}