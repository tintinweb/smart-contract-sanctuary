// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

contract BabyBananaPrivateSale {
    using EnumerableSet for EnumerableSet.AddressSet;

    address constant MARKETING_WALLET = 0x0426760C100E3be682ce36C01D825c2477C47292;

    uint256 hardcap = 250 * 10**18; // 250 BNB
    uint256 maxContribution = 25 * 10**17; // 2.5 BNB
    uint256 minContribution = 1 * 10**17; // 0.1 BNB
    uint256 totalContributions;

    EnumerableSet.AddressSet contributors;
    mapping(address => uint256) public contributions;
    mapping(address => bool) public isWhitelisted;

    modifier onlyMarketing() {
        require(msg.sender == MARKETING_WALLET);
        _;
    }

    receive() external payable {
        require(isWhitelisted[msg.sender], "Not whitelisted");
        require(msg.value >= minContribution, "Too small contribution");
        require(totalContributions + msg.value <= hardcap, "Can't exceed hard cap");
        require(contributions[msg.sender] + msg.value <= maxContribution, "Can't exceed max contribution");

        contributions[msg.sender] += msg.value;
        contributors.add(msg.sender);
        totalContributions += msg.value;
    }

    // Interface

    function contributorsLength() external view returns(uint256) {
        return contributors.length();
    }
    
    function contributorAt(uint256 index) external view returns(address) {
        return contributors.at(index);
    }

    // Marketing

    function withdraw() external onlyMarketing {
        (bool sent,) = payable(MARKETING_WALLET).call{value: address(this).balance, gas: 30000}("");
        require(sent, "Tx failed");
    }

    function removeMaxContribution() external onlyMarketing {
        maxContribution = hardcap;
    }

    function updateMaxContribution(uint256 newMaxContribution) external onlyMarketing {
        maxContribution = newMaxContribution;
    }

    function updateHardcap(uint256 newHardcap) external onlyMarketing {
        hardcap = newHardcap;
    }

    function setWhitelistStatus(address account, bool status) external onlyMarketing {
        isWhitelisted[account] = status;
    }

    function addBatchToWhitelist(address[] calldata accounts) external onlyMarketing {
        for (uint256 i; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = true;
        }
    }
}