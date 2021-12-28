/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Developed by the dev team at Harpy Finance.
//
// Once the ICO is completed, the ETH raised will be sent to the deployer's wallet to distribute among the topics:
//
// Initial Liquidity — 72%
// Marketing — 2%
// Launch Incentives — 12%
// Reserve for Buyback & Burn — 5%
// Treasury Reserve — 9%
//
// No Eth raised in this ICO will belong to the DEVs. 100% of ETH Raised will go to the project.
//
// Special thanks to @mrv_eth for his commitment to the project.
// Have fun reading it. Hopefully it's bug-free. God bless.
contract HarpyCrowdsale {
    bool public icoCompleted;
    // the ICO start time, which can be in timestamp or in block number
    uint256 public icoStartTime;
    // the ICO end time
    uint256 public icoEndTime;
    // the token price
    uint256 public tokenRate;
    // the funding goal in wei which is the smallest Ethereum unit
    uint256 public fundingGoal;
    // amount of tokens sold
    uint256 public tokensRaised;
    // amount of ether collected
    uint256 public etherRaised;

    // The minimum amount of Wei you must pay to participate in the crowdsale
    uint256 public constant minPurchase = 4 ether; // 4 matic

    // The max amount of Wei that you can pay to participate in the crowdsale
    uint256 public constant maxPurchase = 800 ether; // 800 matic

    // You can only buy up to 50 M tokens during the ICO
    uint256 public constant maxTokensRaised = 97500 * (10**18);

    // limit for each goal
    uint256 public limitGoalOne = 24375 * (10**18);
    uint256 public limitGoalTwo = 48750 * (10**18);
    uint256 public limitGoalThree = 73125 * (10**18);
    uint256 public limitGoalFour = 97500 * (10**18);

    // The number of transactions
    uint256 public numberOfTransactions;

    // harpy token address
    // address public harpyAddress;
    // Payable address can receive Ether
    address payable public owner;

    // buyer info
    mapping(address => uint256) public tokensBought;
    mapping(address => uint256) public amountAlreadyClaimed;
    mapping(address => uint256) public etherPaid;

    constructor(
        uint256 _icoStart,
        uint256 _icoEnd,
        uint256 _tokenRate,
        uint256 _fundingGoal
    ) {
        require(
            _icoStart != 0 &&
                _icoEnd != 0 &&
                _icoStart < _icoEnd &&
                _tokenRate != 0 &&
                _fundingGoal != 0
        );
        icoStartTime = _icoStart;
        icoEndTime = _icoEnd;
        tokenRate = _tokenRate;
        fundingGoal = _fundingGoal;
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "dev: wat?");
        _;
    }

    modifier whenIcoCompleted() {
        require(icoCompleted);
        _;
    }

    function buy() public payable {
        _buy();
    }

    function _buy() public payable {
        require(validPurchase(), "HarpyCrowdsale/NotValidPurchase");

        uint256 tokensToBuy;
        // get the value of ether sent by the user and calculate if there is a excess
        uint256 etherUsed = calculateExcessBalance();

        // If the tokens raised are less than 25 million with decimals, apply the first rate
        if (tokensRaised < limitGoalOne) {
            // Goal 1
            tokensToBuy = (etherUsed * 10) / 4;

            // If the amount of tokens that you want to buy gets out of this tier
            if (tokensRaised + tokensToBuy > limitGoalOne) {
                tokensToBuy = calculateExcessTokens(etherUsed, limitGoalOne, 1);
            }
        } else if (
            tokensRaised >= limitGoalOne && tokensRaised < limitGoalTwo
        ) {
            // Goal 2
            tokensToBuy = (etherUsed * 21875) / 10000;

            // If the amount of tokens that you want to buy gets out of this tier
            if (tokensRaised + tokensToBuy > limitGoalTwo) {
                tokensToBuy = calculateExcessTokens(etherUsed, limitGoalTwo, 2);
            }
        } else if (
            tokensRaised >= limitGoalTwo && tokensRaised < limitGoalThree
        ) {
            // Goal 3
            tokensToBuy = (etherUsed * 1875) / 1000;

            // If the amount of tokens that you want to buy gets out of this tier
            if (tokensRaised + tokensToBuy > limitGoalThree) {
                tokensToBuy = calculateExcessTokens(
                    etherUsed,
                    limitGoalThree,
                    3
                );
            }
        } else if (tokensRaised >= limitGoalThree) {
            // Goal 4
            tokensToBuy = (etherUsed * 173611111) / 100000000;
        }

        // Store buyer info
        tokensBought[msg.sender] += tokensToBuy;
        amountAlreadyClaimed[msg.sender] = 0;
        numberOfTransactions = numberOfTransactions + 1;

        // Increase the tokens raised and ether raised state variables
        tokensRaised += tokensToBuy;
        etherRaised += etherUsed;
    }

    /// @notice Calculates how many ether will be used to generate the tokens in
    /// case the buyer sends more than the maximum balance but has some balance left
    /// and updates the balance of that buyer.
    function calculateExcessBalance() internal returns (uint256) {
        uint256 etherUsed = msg.value;
        uint256 differenceWei = 0;
        uint256 exceedingBalance = 0;

        // If we're in the last tier, check that the limit hasn't been reached
        // and if so, refund the difference and return what will be used to
        // buy the remaining tokens
        if (tokensRaised >= limitGoalThree) {
            uint256 addedTokens = tokensRaised +
                ((etherUsed * 173611111) / 100000000);

            // If tokensRaised + what you paid converted to tokens is bigger than the max
            if (addedTokens > maxTokensRaised) {
                // Refund the difference
                uint256 difference = addedTokens - maxTokensRaised;
                differenceWei = difference / 173611111 / 100000000;
                etherUsed = etherUsed - differenceWei;
            }
        }

        uint256 addedEthPaid = etherPaid[msg.sender] + etherUsed;

        // Checking that the individual limit of 0.5 ETH per user is not reached
        if (addedEthPaid <= maxPurchase) {
            etherPaid[msg.sender] += etherUsed;
        } else {
            exceedingBalance = addedEthPaid - maxPurchase;
            etherUsed -= exceedingBalance;

            // Add that balance to the ethPaid
            etherPaid[msg.sender] += etherUsed;
        }

        // Make the transfers at the end of the function for security purposes
        if (differenceWei > 0) {
            (bool success, ) = msg.sender.call{value: differenceWei}("");
            require(success, "Failed to refund Ether");
        }

        if (exceedingBalance > 0) {
            // Return the exceeding balance to the buyer
            (bool success, ) = msg.sender.call{value: exceedingBalance}("");
            require(success, "Failed to refund Ether");
        }

        return etherUsed;
    }

    function calculateExcessTokens(
        uint256 _amount,
        uint256 _tokensThisGoal,
        uint256 _goalSelected
    ) public returns (uint256 totalTokens) {
        require(_amount > 0 && _tokensThisGoal > 0);
        require(_goalSelected >= 1 && _goalSelected <= 4);

        uint256 weiThisGoal;

        if (_goalSelected == 1) {
            weiThisGoal = (_tokensThisGoal - tokensRaised) / 10 / 4;
        } else if (_goalSelected == 2) {
            weiThisGoal = (_tokensThisGoal - tokensRaised) / 21875 / 10000;
        } else if (_goalSelected == 3) {
            weiThisGoal = (_tokensThisGoal - tokensRaised) / 1875 / 1000;
        } else {
            weiThisGoal =
                (_tokensThisGoal - tokensRaised) /
                173611111 /
                100000000;
        }
        uint256 weiNextGoal = _amount - weiThisGoal;
        uint256 tokensNextGoal = 0;
        bool returnTokens = false;

        // If there's excessive wei for the last tier, refund those
        if (_goalSelected != 4) {
            tokensNextGoal = calculateTokensGoal(
                weiNextGoal,
                _goalSelected + 1
            );
        } else {
            returnTokens = true;
        }

        totalTokens = _tokensThisGoal - tokensRaised + tokensNextGoal;

        // Do the transfer at the end
        if (returnTokens) {
            (bool success, ) = msg.sender.call{value: weiNextGoal}("");
            require(success, "Failed to refund Ether");
        }
    }

    function calculateTokensGoal(uint256 _weiPaid, uint256 _goalSelected)
        internal
        returns (uint256 calculatedTokens)
    {
        require(_weiPaid > 0);
        require(_goalSelected >= 1 && _goalSelected <= 4);

        if (_goalSelected == 1) calculatedTokens = (_weiPaid * 10) / 4;
        else if (_goalSelected == 2)
            calculatedTokens = (_weiPaid * 21875) / 10000;
        else if (_goalSelected == 3)
            calculatedTokens = (_weiPaid * 1875) / 1000;
        else calculatedTokens = (_weiPaid * 173611111) / 100000000;
    }

    /// @notice Checks if a purchase is considered valid
    /// @return bool If the purchase is valid or not
    function validPurchase() internal returns (bool) {
        bool withinPeriod = block.timestamp >= icoStartTime &&
            block.timestamp <= icoEndTime;
        bool nonZeroPurchase = msg.value > 0;
        bool withinTokenLimit = tokensRaised < maxTokensRaised;
        bool minimumPurchase = msg.value >= minPurchase;
        bool hasBalanceAvailable = etherPaid[msg.sender] < maxPurchase;

        // We want to limit the gas to avoid giving priority to the biggest paying contributors
        //bool limitGas = tx.gasprice <= limitGasPrice;

        return
            withinPeriod &&
            nonZeroPurchase &&
            withinTokenLimit &&
            minimumPurchase &&
            hasBalanceAvailable;
    }

    /// @notice The extractEther function can only be called by the deployer
    function extractEther() public onlyOwner {
        // get the amount of Ether stored in this contract
        uint256 amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}