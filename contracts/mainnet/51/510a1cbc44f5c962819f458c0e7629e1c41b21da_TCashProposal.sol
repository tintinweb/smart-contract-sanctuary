/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

//SPDX-License-Identifier: MIT

// Tornado Cash proposal to fund a multisig with 5% of the vested TORN of the governance treasury 
// and 5% of the funds vesting over the next 12 month. The multisig is owned by community members
// and its goal is to funds ecosystem initiatives. 

// Author: @Rezan-vm

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ISablier {
    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256);
}

interface Vesting {
  function SECONDS_PER_MONTH() external view returns (uint256);
  function release() external;
  function vestedAmount() external view returns (uint256);
  function released() external view returns (uint256);
  function startTimestamp() external view returns (uint256);
}

contract TCashProposal {
    IERC20 public constant TORN = IERC20(0x77777FeDdddFfC19Ff86DB637967013e6C6A116C);
    
    Vesting public constant GOV_VESTING = Vesting(0x179f48C78f57A3A78f0608cC9197B8972921d1D2);

    ISablier public constant SABLIER = ISablier(0xA4fc358455Febe425536fd1878bE67FfDBDEC59a);

    // Gnosis safe address that will receive the tokens
    address public constant COMMUNITY_MULTISIG = address(0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4);
    
    // Percentage of the treasury to fund the multisig with
    uint256 public constant PERCENT_OF_TREASURY = 5; // 5%
    
    uint256 public constant SECOND_PER_MONTH = 30 days;
    uint256 public constant MONTH_PER_YEAR = 12;
    uint256 public constant SECOND_PER_YEAR = SECOND_PER_MONTH * MONTH_PER_YEAR;
    uint256 public constant HUNDRED = 100;

    function executeProposal() public {
        // Claim vested funds if any
        if(GOV_VESTING.vestedAmount() > 0) {
            GOV_VESTING.release();
        }

        // Total funds that have already vested
        uint256 releasedFunds = GOV_VESTING.released();

        // Initial Funding, transfer 5% of what has already vested
        // Note: No safeMath needed in solidity 0.8.0
        TORN.transfer(COMMUNITY_MULTISIG, releasedFunds * PERCENT_OF_TREASURY / HUNDRED);

        // Calculate how many token are vesting per month
        uint256 elapsedMonths = (block.timestamp - GOV_VESTING.startTimestamp()) / SECOND_PER_MONTH;
        uint256 vestingPerMonth = releasedFunds / elapsedMonths;
        
        // Send to sablier 5% of what is about to unlock in the next 12 months
        uint256 sablierDeposit = vestingPerMonth * MONTH_PER_YEAR * PERCENT_OF_TREASURY / HUNDRED;
        
        // The deposited amount in Sablier needs to be a multiple of the of the distribution period.
        // Round down and distribute slightly less tokens.
        uint256 sablierAdjustedDeposit = sablierDeposit - sablierDeposit % SECOND_PER_YEAR;

        // Approve the amount and create the stream
        TORN.approve(address(SABLIER), sablierAdjustedDeposit);
        SABLIER.createStream(
            COMMUNITY_MULTISIG,
            sablierAdjustedDeposit,
            address(TORN),
            block.timestamp,
            block.timestamp + SECOND_PER_YEAR
        );
    }
}