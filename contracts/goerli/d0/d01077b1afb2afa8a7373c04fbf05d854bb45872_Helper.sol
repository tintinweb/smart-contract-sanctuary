/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Helper {
    address public owner;
    uint256 public betAmount;
    uint256 public outAmount;

    uint256 public total;
    // order => address
    mapping(uint256 => address) public orders;
    // address => order
    mapping(address => uint256) public addresses;
    uint256 public canWithdrawOrder;

    event Bet(address indexed _address, uint256 indexed _order);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }



    constructor(uint256 _betAmount, uint256 _outAmount) {
        betAmount = _betAmount;
        outAmount = _outAmount;
        owner = msg.sender;
    }

    receive() external payable {
        require(msg.value == betAmount, "Bet amount error");
        require(addresses[msg.sender] == 0, "Already bet");

        orders[++total] = msg.sender;
        addresses[msg.sender] = total;
        emit Bet(msg.sender, total);
        if (total < 2) {
            canWithdrawOrder = 0;
        } else {
            canWithdrawOrder = total - 1 - total * (outAmount - betAmount) / betAmount;
        }
    }

    function setAmount(uint256 _betAmount, uint256 _outAmount) public {
        betAmount = _betAmount;
        outAmount = _outAmount;
    }

    function getCanWithdraw() public view returns(bool) {
        uint256 order = addresses[msg.sender];
        if (order == 0) {
            revert("No bet");
        }

        if (order <= canWithdrawOrder) {
            return true;
        }

        return false;
    }

    function withdraw() public {
        uint256 order = addresses[msg.sender];
        if (order == 0) {
            revert("No bet");
        }

        if (order > canWithdrawOrder) {
            revert("Cannot withdraw");
        }

        address payable target = payable(msg.sender);

        delete addresses[target];

        target.transfer(outAmount);
    }

    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }
}