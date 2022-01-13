// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

/**
 * A gas optimized implementation of a vesting contract for tokens according to a predetermined vesting schedule
 * for multiple beneficiaries. Beneficiaries can choose how often they invoke release() to receive the unlocked
 * tokens. There are several steps to use this contract
 *  - construction with token address, length of vesting period, and release interval
 *  - init of the beneficiaries with their respective amounts
 *  - launch of the contract when the launch date is known and after enough tokens are received.
 */
contract MultiBeneficiaryLock is Ownable {

    IERC20 private immutable token;
    uint32 private immutable period;
    uint32 private immutable interval;
    uint256 private start;
    uint256 private totalTokens;

    struct Balance {
        uint256 released;
        uint256 total;
    }

    mapping(address => Balance) private balance;

    modifier notLaunched {
        require(start == 0, "MBL01");
        _;
    }
    modifier launched {
        require(start > 0, "MBL02");
        _;
    }

    /**
     * Construct a MultiBeneficiary lock contract that has the specified vesting period in days
     * and a release interval in days when new tokens prorata become available.
     */
    constructor(IERC20 tokenAddress, uint32 periodDays, uint32 intervalDays) {
        require(intervalDays <= periodDays, "MBL03");
        token = tokenAddress;
        period = periodDays;
        interval = intervalDays;

    }

    /**
     * Initialize beneficiaries. Provide the list of beneficiaries for this lock contract and their respective
     * balances. Only the owner can call this function.
     * As this is a gas intensive method for large arrays, check for duplicate addresses is left out. It is the
     * responsibility of the owner to prevent duplicates which can be validated by calling checkInitBeneficiaries upfront.
     */
    function initBeneficiaries(address[] calldata addresses,
        uint256[] calldata amounts) external onlyOwner notLaunched {
        require(totalTokens == 0, "MBL04");
        require(addresses.length == amounts.length, "MBL05");
        uint256 total = 0;
        for (uint256 i=0; i < addresses.length; i++) {
            total = total + amounts[i];
            balance[addresses[i]] = Balance(0, amounts[i]);
        }
        totalTokens = total;
    }

    /**
     * Check that the given list of beneficiaries is sane. Gasless check which can be called before initBeneficiaries.
     */
    function checkInitBeneficiaries(address[] calldata addresses, uint256[] calldata amounts) external view onlyOwner notLaunched returns (uint256){
        require(totalTokens == 0, "MBL04");
        require(addresses.length == amounts.length, "MBL05");

        uint256 total = 0;
        for (uint256 i=0; i < addresses.length; i++) {
            total = total + amounts[i];
            require(amounts[i] > 0, "MBL06");
            for (uint256 j = i + 1; j < addresses.length; j++) {
                require(addresses[i] != addresses[j], "MBL07");
            }
        }
        return total;
    }

    /**
     * Return the minium amount of tokens that is required for the contract to be launched
     * only relevant after init.
     */
    function tokenCountOnLaunch() external view returns (uint256) {
        return totalTokens;
    }

    /**
     * Return if all preconditions are met for the lock contract to launch:
     * not launched yet, initialized and token balance enough.
     */
    function readyForLaunch() external view returns (bool) {
        return (start == 0) && (totalTokens > 0) && (token.balanceOf(address(this)) >= totalTokens);
    }

    /**
     * Launch the contract given a start block time as the basis for the vesting period.
     * when blocktime reaches startBlocktime, the first interval wait for release starts.
     * blocktime in seconds since epoch.
     */
    function launch(uint256 startBlocktime) external notLaunched onlyOwner {
        require(startBlocktime > 0, "MBL08");
        require(totalTokens > 0, "MBL09");
        require(token.balanceOf(address(this)) >= totalTokens, "MBL10");
        start = startBlocktime;
    }

    /**
     * @return the token being held.
     */
    function erc20() external view returns (IERC20) {
        return token;
    }

    /**
     * @return number of tokens still locked up for a particular beneficiary
     */
    function locked(address holder) external view returns (uint256){
        return balance[holder].total - balance[holder].released - amountCanRelease(holder);
    }

    /**
     * @return the amount of tokens that have already been released for a particular beneficiary
     */
    function released(address holder) external view returns (uint256){
        return balance[holder].released;
    }

    /**
     * @return block.timestamp
     */
    function blocktime() internal virtual view returns (uint256){
        return block.timestamp;
    }

    /**
     * @return number of days since contract's launchdate
     * Only relevant when launched.
     */
    function calculateDaysSinceStart() private view returns (uint256){
        uint256 ts = blocktime();
        if (ts < start) return 0;
        return (ts - start) / (1 days);
    }

    /**
     * @return the amount of tokens that can be released to the beneficiary at this time
     */
    function amountCanRelease(address holder) public view returns (uint256){
        // not launched
        if (start == 0) return 0;
        Balance memory beneficiaryBalance = balance[holder];
        uint256 amount = beneficiaryBalance.total - beneficiaryBalance.released;
        if (amount == 0) return 0;
        uint256 daysSinceStart = calculateDaysSinceStart();
        if (daysSinceStart > period) return amount;
        uint256 amountPerDay = beneficiaryBalance.total / period;
        uint256 daysStartToLastRelease = beneficiaryBalance.released / amountPerDay;
        // starttime to last release date's interval start date
        uint256 daysSinceLastRelease = daysSinceStart - daysStartToLastRelease;
        if (daysSinceLastRelease < interval) return 0;
        return (daysSinceLastRelease / interval * interval) * amountPerDay;
    }

    /**
     * Release all tokens that can be released for a particular beneficiary. Invoker pays the gas.
     * Anyone can invoke.
     */
    function releaseFor(address holder) public launched {
        uint256 amountToRelease = amountCanRelease(holder);
        require(amountToRelease > 0);
        assert(balance[holder].total - balance[holder].released >= amountToRelease);
        balance[holder].released += amountToRelease;
        require(token.transfer(holder, amountToRelease), "MBL11");
    }

    /**
     * Release all tokens that can be released for msg.sender.
     */
    function release() external {
        releaseFor(msg.sender);
    }

}