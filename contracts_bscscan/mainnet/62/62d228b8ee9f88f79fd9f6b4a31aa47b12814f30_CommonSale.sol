// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./IERC20Cutted.sol";
import "./RecoverableFunds.sol";
import "./StagedCrowdsale.sol";

contract CommonSale is Pausable, StagedCrowdsale, RecoverableFunds {

    using SafeMath for uint256;

    struct Balance {
        uint256 initial;
        uint256 withdrawn;
    }

    struct VestingSchedule {
        uint256 start;
        uint256 duration;
        uint256 interval;
    }

    event Deposit(address account, uint256 tokens);
    event Withdrawal(address account, uint256 tokens);

    IERC20Cutted public token;
    uint256 public price; // amount of tokens per 1 ETH
    uint256 public invested;
    uint256 public percentRate = 100;
    address payable public wallet;

    mapping(uint256 => mapping(address => Balance)) public balances;
    mapping(uint8 => VestingSchedule) public vestingSchedules;

    function setToken(address newTokenAddress) public onlyOwner {
        token = IERC20Cutted(newTokenAddress);
    }

    function setPercentRate(uint256 newPercentRate) public onlyOwner {
        percentRate = newPercentRate;
    }

    function setWallet(address payable newWallet) public onlyOwner {
        wallet = newWallet;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setVestingSchedule(uint8 id, uint256 start, uint256 duration, uint256 interval) public onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[id];
        schedule.start = start;
        schedule.duration = duration;
        schedule.interval = interval;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getAccountInfo(address account) public view returns (uint256, uint256, uint256) {
        uint256 initial;
        uint256 withdrawn;
        uint256 vested;
        for (uint8 stageIndex = 0; stageIndex < stages.length; stageIndex++) {
            Balance memory balance = balances[stageIndex][account];
            uint8 scheduleIndex = stages[stageIndex].vestingSchedule;
            VestingSchedule memory schedule = vestingSchedules[scheduleIndex];
            uint256 vestedAmount = calculateVestedAmount(balance, schedule);
            initial = initial.add(balance.initial);
            withdrawn = withdrawn.add(balance.withdrawn);
            vested = vested.add(vestedAmount);
        }
        return (initial, withdrawn, vested);
    }

    function withdraw() public whenNotPaused returns (uint256) {
        uint256 tokens;
        for (uint256 stageIndex = 0; stageIndex < stages.length; stageIndex++) {
            Balance storage balance = balances[stageIndex][msg.sender];
            if (balance.initial == 0) continue;
            uint8 scheduleIndex = stages[stageIndex].vestingSchedule;
            VestingSchedule memory schedule = vestingSchedules[scheduleIndex];
            uint256 vestedAmount = calculateVestedAmount(balance, schedule);
            if (vestedAmount == 0) continue;
            balance.withdrawn = balance.withdrawn.add(vestedAmount);
            tokens = tokens.add(vestedAmount);
        }
        require(tokens > 0, "CommonSale: No tokens available for withdrawal");
        token.transfer(msg.sender, tokens);
        emit Withdrawal(msg.sender, tokens);
        return tokens;
    }

    receive() external payable {
        internalFallback();
    }

    function calculateVestedAmount(Balance memory balance, VestingSchedule memory schedule) internal view returns (uint256) {
        if (block.timestamp < schedule.start) return 0;
        uint256 tokensAvailable;
        if (block.timestamp >= schedule.start.add(schedule.duration)) {
            tokensAvailable = balance.initial;
        } else {
            uint256 parts = schedule.duration.div(schedule.interval);
            uint256 tokensByPart = balance.initial.div(parts);
            uint256 timeSinceStart = block.timestamp.sub(schedule.start);
            uint256 pastParts = timeSinceStart.div(schedule.interval);
            tokensAvailable = tokensByPart.mul(pastParts);
        }
        return tokensAvailable.sub(balance.withdrawn);
    }

    function calculateInvestmentAmounts(Stage memory stage) internal view returns (uint256, uint256) {
        // apply a bonus if any
        uint256 tokensWithoutBonus = msg.value.mul(price).div(1 ether);
        uint256 tokensWithBonus = tokensWithoutBonus;
        if (stage.bonus > 0) {
            tokensWithBonus = tokensWithoutBonus.add(tokensWithoutBonus.mul(stage.bonus).div(percentRate));
        }
        // limit the number of tokens that user can buy according to the hardcap of the current stage
        if (stage.tokensSold.add(tokensWithBonus) > stage.hardcapInTokens) {
            tokensWithBonus = stage.hardcapInTokens.sub(stage.tokensSold);
            if (stage.bonus > 0) {
                tokensWithoutBonus = tokensWithBonus.mul(percentRate).div(percentRate + stage.bonus);
            }
        }
        // calculate the resulting amount of ETH that user will spend
        uint256 tokenBasedLimitedInvestValue = tokensWithoutBonus.mul(1 ether).div(price);
        // return the number of purchasesd tokens and spent ETH
        return (tokensWithBonus, tokenBasedLimitedInvestValue);
    }

    function internalFallback() internal whenNotPaused returns (uint256) {
        uint256 stageIndex = getCurrentStageOrRevert();
        Stage storage stage = stages[stageIndex];
        // check min investment limit
        require(msg.value >= stage.minInvestmentLimit, "CommonSale: The amount of ETH you sent is too small");
        (uint256 tokens, uint256 investment) = calculateInvestmentAmounts(stage);
        require(tokens > 0, "CommonSale: No tokens available for purchase");
        uint256 change = msg.value.sub(investment);
        // update stats
        invested = invested.add(investment);
        stage.tokensSold = stage.tokensSold.add(tokens);
        // update balance and transfer tokens
        Balance storage balance = balances[stageIndex][msg.sender];
        if (stage.vestingSchedule == 0) {
            balance.initial = balance.initial.add(tokens);
            balance.withdrawn = balance.withdrawn.add(tokens);
            token.transfer(msg.sender, tokens);
        } else {
            balance.initial = balance.initial.add(tokens);
        }
        // transfer ETH
        wallet.transfer(investment);
        if (change > 0) {
            payable(msg.sender).transfer(change);
        }

        emit Deposit(msg.sender, tokens);
        return tokens;
    }

}