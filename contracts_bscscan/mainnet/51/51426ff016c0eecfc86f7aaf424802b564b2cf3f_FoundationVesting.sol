// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.5.16;

import { IBEP20 } from "./IBEP20.sol";

contract FoundationVesting {

    IBEP20 public NBL;
    address public beneficiary;
    uint256 public start;
    uint256 public allocatedTokens;
    uint256 public claimedTokens;
    uint256 public constant duration = 2970 days;
    uint256 public constant initialReleasePercentage = 1;

    event TokensClaimed(address beneficiary, uint256 value);
    event TokensAllocated(address beneficiary, uint256 value);

    constructor ( address _NBLaddress, address _beneficiary, uint256 _start, uint256 _amount ) public {
        NBL = IBEP20(_NBLaddress);
        beneficiary = _beneficiary;
        start = _start;
        allocatedTokens = _amount;
    }

    function claimTokens() public {
        uint256 claimableTokens = getClaimableTokens();
        require(claimableTokens > 0, "Vesting: no claimable tokens");

        claimedTokens += claimableTokens;
        NBL.transfer(beneficiary, claimableTokens);

        emit TokensClaimed(beneficiary, claimableTokens);
    }

    function getAllocatedTokens() public view returns (uint256 amount) {
        return allocatedTokens;
    }

    function getClaimedTokens() public view returns (uint256 amount) {
        return claimedTokens;
    }

    function getClaimableTokens() public view returns (uint256 amount) {
        uint256 releasedTokens = getReleasedTokensAtTimestamp(block.timestamp);
        return releasedTokens - claimedTokens;
    }

    function getReleasedTokensAtTimestamp(uint256 timestamp) public view returns (uint256 amount) {
        if (timestamp < start) {
            return 0;
        }
        
        uint256 elapsedTime = timestamp - start;

        if (elapsedTime >= duration) {
            return allocatedTokens;
        }

        uint256 initialRelease = allocatedTokens * initialReleasePercentage / 100;
        uint256 remainingTokensAfterInitialRelease = allocatedTokens - initialRelease;
        uint256 subsequentRelease = remainingTokensAfterInitialRelease * elapsedTime / duration;
        uint256 totalReleasedTokens = initialRelease + subsequentRelease;

        return totalReleasedTokens;
    }

}