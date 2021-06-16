// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "ERC20.sol";
import "Ownable.sol";


contract LitionVesting is Ownable {
    ERC20 usdcToken = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address beneficiary = 0xCC2f62d82eeE4fFF4aa82D4b0C7840c54F02716f;
    uint256 public totalClaimed;
    
    uint256 JUNE_2021 = 1622499891;
    uint256 SEPTEMBER_2021 = 1630448691;
    uint256 DECEMBER_2021 = 1638314691;
    uint256 MARCH_2022 = 1646090691;
    
    uint256 maxDateToClaimUnallocated;
    
    event TokensClaimed(uint256 _total);

    function claimTokens() external
    {
        require(msg.sender == beneficiary, "Invalid caller");
        
        uint256 tokensToClaim = getTotalToClaimOnDate(block.timestamp);
        require(tokensToClaim > 0, "Nothing to claim");
        
        totalClaimed += tokensToClaim;
        
        require(usdcToken.transfer(msg.sender, tokensToClaim), "Insufficient balance in vesting contract");
        emit TokensClaimed(tokensToClaim);
    }
    
    function _claimUnallocated(uint256 _total) external onlyOwner {
        require(block.timestamp < maxDateToClaimUnallocated, "Option not available anymore");
        
        require(usdcToken.transfer(msg.sender, _total), "Insufficient balance in vesting contract");
    }
    
    function getTotalToClaimOnDate(uint256 _date) public view returns (uint256) {
        if (_date < JUNE_2021) {
            return 0;
        }
        if (_date < SEPTEMBER_2021) {
            return 75000 * 1e6 - totalClaimed;
        }
        if (_date < DECEMBER_2021) {
            return 150000 * 1e6 - totalClaimed;
        }
        if (_date < MARCH_2022) {
            return 225000 * 1e6 - totalClaimed;
        }
        return 300000 * 1e6 - totalClaimed;
    }
    
    constructor() {
        maxDateToClaimUnallocated = block.timestamp + 30 days;
    }
}