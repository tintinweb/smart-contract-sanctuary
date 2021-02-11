// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeMath.sol";

contract PlasmaVesting {
    using SafeMath for uint256;

    address public ppay;
    address public recipient;

    uint256 public vestingAmount;
    uint256 public vestingBegin;
    uint256 public vestingCliff;
    uint256 public vestingEnd;

    uint256 public lastUpdate;

    constructor(
        address ppay_,
        address recipient_,
        uint256 vestingAmount_,
        uint256 vestingBegin_,
        uint256 vestingCliff_,
        uint256 vestingEnd_
    ) public {
        require(vestingBegin_ >= block.timestamp, 'PlasmaVesting::constructor: vesting begin too early');
        require(vestingCliff_ >= vestingBegin_, 'PlasmaVesting::constructor: cliff is too early');
        require(vestingEnd_ > vestingCliff_, 'PlasmaVesting::constructor: end is too early');

        ppay = ppay_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    function setRecipient(address recipient_) external {
        require(msg.sender == recipient, 'PlasmaVesting::setRecipient: unauthorized');
        recipient = recipient_;
    }

    function claim() external returns (bool) {
        require(block.timestamp >= vestingCliff, 'PlasmaVesting::claim: not time yet');
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = IPpay(ppay).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        return IPpay(ppay).transfer(recipient, amount);
    }
}

interface IPpay {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address dst, uint256 rawAmount) external returns (bool);
}