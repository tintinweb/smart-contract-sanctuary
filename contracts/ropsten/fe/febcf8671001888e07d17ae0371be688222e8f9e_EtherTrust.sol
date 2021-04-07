/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;


contract EtherTrust {

    struct UnitDistribution {
        address settlor;
        uint timeUnitInSeconds;
        uint distributionAmountPerTimeUnit;

        uint startDistributionTime;
        uint startReleaseTime;
        uint lastReleaseTime;
        uint totalAmount;
    }


    mapping(address => address) private settlorToTrustee;

    mapping(address => UnitDistribution) private trusteeToUnitDistribution;

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'EtherTrust: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }


    constructor() {}

    /*
      If ppl send the ether to this contract directly
     */
    receive() external payable {
        uint totalAmount = msg.value;
        require(totalAmount > 0, "msg.value is 0");
        address settlor = tx.origin;
        require(settlor != address(0), "settlor address is 0");
        settlorToTrustee[settlor] = settlor;
        trusteeToUnitDistribution[settlor].settlor = settlor;
        trusteeToUnitDistribution[settlor].totalAmount = totalAmount;
    }


    function setTrust(
        address payable trustee,
        // distribution can happened before release
        uint startDistributionTime,
        // before release time, trustee can not get the ether from this contract
        uint startReleaseTime,
        uint timeUnitInSeconds,
        uint distributionAmountPerTimeUnit) external lock {

        require(trustee != address(0), "trustee address is 0");
        address settlor = tx.origin;
        require(settlor != address(0), "settlor address is 0");

        settlorToTrustee[settlor] = trustee;
        UnitDistribution storage ud = trusteeToUnitDistribution[settlor];
        ud.startDistributionTime = startDistributionTime;
        ud.startReleaseTime = startReleaseTime;
        ud.timeUnitInSeconds = timeUnitInSeconds;
        ud.distributionAmountPerTimeUnit = distributionAmountPerTimeUnit;
    }


    function addTrust(
        address payable trustee,
        // distribution can happened before release
        uint startDistributionTime,
        // before release time, trustee can not get the ether from this contract
        uint startReleaseTime,
        uint timeUnitInSeconds,
        uint distributionAmountPerTimeUnit) payable external lock {

        uint totalAmount = msg.value;
        require(totalAmount > 0, "msg.value is 0");
        require(trustee != address(0), "trustee address is 0");
        address settlor = tx.origin;
        require(settlor != address(0), "settlor address is 0");
        require(settlorToTrustee[settlor] == address(0),
                "only one trustee can be created by one settlor");

        settlorToTrustee[settlor] = trustee;

        trusteeToUnitDistribution[trustee].settlor = settlor;
        trusteeToUnitDistribution[trustee].totalAmount = totalAmount;
        trusteeToUnitDistribution[trustee].startDistributionTime = startDistributionTime;
        trusteeToUnitDistribution[trustee].startReleaseTime = startReleaseTime;
        trusteeToUnitDistribution[trustee].timeUnitInSeconds = timeUnitInSeconds;
        trusteeToUnitDistribution[trustee].distributionAmountPerTimeUnit = distributionAmountPerTimeUnit;

    }


    /*
      To protect the privacy of the trust,
      only query from the trustee can get the balance
    */
    function getTrust() external view returns (
        uint, uint, uint, uint, uint, uint) {
        address settlor = msg.sender;
        address trustee = settlorToTrustee[settlor];
        UnitDistribution memory ud = trusteeToUnitDistribution[trustee];
        if (ud.totalAmount == 0) {
            return (0, 0, 0, 0, 0, 0);
        }
        return (ud.totalAmount,
                ud.startDistributionTime,
                ud.startReleaseTime,
                ud.timeUnitInSeconds,
                ud.distributionAmountPerTimeUnit,
                ud.lastReleaseTime);
    }

    /*
      Trustee get ether from this function
     */
    function release() external lock {
        address trustee = msg.sender;
        require(trustee != address(0));
        UnitDistribution storage ud = trusteeToUnitDistribution[trustee];
        require(ud.totalAmount != 0, "no trustee unit distribution was found");
        uint startReleaseTime = ud.startReleaseTime;
        uint nowTimestamp = block.timestamp;
        require(startReleaseTime < nowTimestamp, "release not yet started");
        if (ud.lastReleaseTime != 0) {
            require(nowTimestamp > ud.lastReleaseTime + ud.timeUnitInSeconds,
                    "too early for next release");
        }
        uint distributionTimeInSeconds = ud.lastReleaseTime == 0 ?
            nowTimestamp - ud.startDistributionTime : nowTimestamp - ud.lastReleaseTime;
        uint distributionUnitAmount = distributionTimeInSeconds / ud.timeUnitInSeconds;
        uint releaseAmount = distributionUnitAmount * ud.distributionAmountPerTimeUnit;
        if (releaseAmount >= ud.totalAmount) {
            delete settlorToTrustee[ud.settlor];
            delete trusteeToUnitDistribution[trustee];
            if (!payable(trustee).send(releaseAmount)) {
                revert("release failed");
            }
            return;
        }
        ud.totalAmount -= releaseAmount;
        uint timeRemainder = distributionTimeInSeconds % ud.timeUnitInSeconds;
        if (timeRemainder != 0) {
            ud.lastReleaseTime = nowTimestamp - timeRemainder;
        }
        if (!payable(trustee).send(releaseAmount)) {
            revert("release failed");
        }
    }

}