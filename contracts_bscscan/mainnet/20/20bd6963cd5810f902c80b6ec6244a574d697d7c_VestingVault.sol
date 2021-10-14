// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./SafeMath.sol";

contract VestingVault {

    using SafeMath for uint256;

    event ChangeBeneficiary(address oldBeneficiary, address newBeneficiary);

    event Withdraw(address indexed to, uint256 amount);

    string public name;

    address public vestingToken;

    uint256 public constant vestingPeriod = 30 days;

    uint256 public constant vestingBatchs = 10;

    uint256 public initialVestedAmount;

    uint256 public vestingEndTimestamp;

    address public beneficiary;

    constructor (string memory name_, address vestingToken_, uint256 initialVestedAmount_, address beneficiary_) {
        name = name_;
        vestingToken = vestingToken_;
        initialVestedAmount = initialVestedAmount_;
        beneficiary = beneficiary_;
        vestingEndTimestamp = block.timestamp + vestingPeriod.mul(vestingBatchs);
    }

    function setBeneficiary(address newBeneficiary) public {
        require(msg.sender == beneficiary, "VestingVault.setBeneficiary: can only be called by beneficiary");
        emit ChangeBeneficiary(beneficiary, newBeneficiary);
        beneficiary = newBeneficiary;
    }

    function getRemainingLockedAmount() public view returns (uint256) {
        //release discretely on a "vestingPeriod" basis (e.g. monthly basis if vestingPeriod = 30 days)
        //after every vestingPeriod, 1 vestingBatch (1/vestingBatchs of initialVestedAmount) is released
        //numOfLockedBatches = vestingEndTimestamp.sub(block.timestamp).div(vestingPeriod).add(1);
        //ratio remaining locked = (1/vestingBatchs) * numOfLockedBatches
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp >= vestingEndTimestamp) {
            return 0;
        } else {
            return vestingEndTimestamp.sub(currentTimestamp).div(vestingPeriod).add(1).mul(initialVestedAmount).div(vestingBatchs);
        }
    }

    function withdraw(address to, uint256 amount) public {
        require(msg.sender == beneficiary, "VestingVault.withdraw: can only be called by beneficiary");
        require(to != address(0), "VestingVault.withdraw: withdraw to 0 address");
        IToken(vestingToken).transfer(to, amount);

        uint256 balance = IToken(vestingToken).balanceOf(address(this));
        require(balance >= getRemainingLockedAmount(), "VestingVault.withdraw: amount exceeds allowed by schedule");

        emit Withdraw(to, amount);
    }

}

interface IToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}