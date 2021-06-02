/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.3;

interface ERC20 {
    function transfer(address to, uint tokens) external;
    function transferFrom(address from, address to, uint tokens) external;
}

abstract contract Rebaser {
    uint public orbiSupplyTotal;
}

contract Staking {

    address public owner;
    address public tokenAddress;
    address public liquidityAddress;
    uint public creationTime;
    uint public totalStakeDepositsToken;
    uint public totalStakeDepositsLiquidity;
    uint public lastRealTokenEmissionToken;
    uint public lastRealTokenEmissionLiquidity;
    uint public rewardPerStakeTotalToken;
    uint public rewardPerStakeTotalLiquidity;
    uint public currentScaleToken;
    uint public currentScaleLiquidity;
    uint public totalRewardsWithdrawnToken;
    uint public totalRewardsWithdrawnLiquidity;
    uint public rewardMax = 1e16;
    uint public previousRewards;
    uint public distributionConstant = 7008000;
    uint public rewardsLastRewardChange;
    uint public timeStakingInit;
    uint public timeFromInitToLastRewardChange;
    address public rebaserAddress = 0x0ac8F269ED3F8ad1bd6d52866d0bF98838b7257F;
    mapping(address => uint) public stakingBalancesToken;
    mapping(address => uint) public stakingBalancesLiquidity;
    mapping(address => uint) public rewardPerStakeInitsToken;
    mapping(address => uint) public rewardPerStakeInitsLiquidity;
    mapping(address => uint) public availableRewardsToken;
    mapping(address => uint) public availableRewardsLiquidity;

    constructor() {
        creationTime = block.timestamp;
        owner = msg.sender;
    }
    
    function changeOwner(address addr) public {
        require(msg.sender == owner, "Only the owner can use this function");
        owner = addr;
    }

    function rewardTheoretical() public view returns (uint) {
        if (timeStakingInit == 0)
            return 0;
        return rewardMax - (rewardMax - rewardsLastRewardChange) * distributionConstant / (block.timestamp - timeStakingInit + distributionConstant - timeFromInitToLastRewardChange);
    }
    
    function updateRewardFunction(uint newRewardMax, uint newDistributionConstant) public {
        require(msg.sender == owner, "Only the owner can use this function");
        rewardsLastRewardChange = rewardTheoretical();
        distributionConstant = newDistributionConstant;
        rewardMax = newRewardMax;
        timeFromInitToLastRewardChange = block.timestamp - timeStakingInit;
    }
    
    function getTheoreticalTokenEmission(bool tokenOrLiquidity) public view returns(uint) {
        if (tokenOrLiquidity)
            return rewardTheoretical() * 2 / 3;
            //return (1e16 - 1e16 * 3504000 / ((block.timestamp - creationTime) + 3504000)) * 5 / 6;
        return rewardTheoretical() / 3;
        //return (1e16 - 1e16 * 3504000 / ((block.timestamp - creationTime) + 3504000)) / 6;
    }

    function stake(uint pseudoAmount, bool tokenOrLiquidity) public {
        if (timeStakingInit == 0)
            timeStakingInit = block.timestamp;
        distributeRewards(tokenOrLiquidity);
        if (tokenOrLiquidity) {
            require(stakingBalancesLiquidity[msg.sender] == 0, "Liquidity staking position already exists");
            ERC20(liquidityAddress).transferFrom(msg.sender, address(this), pseudoAmount);
            totalStakeDepositsLiquidity += pseudoAmount;
            stakingBalancesLiquidity[msg.sender] = pseudoAmount;
            rewardPerStakeInitsLiquidity[msg.sender] = rewardPerStakeTotalLiquidity;
            return;
        }
        require(stakingBalancesToken[msg.sender] == 0, "Token staking position already exists");
        uint amount = pseudoAmount;
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), pseudoAmount);
        totalStakeDepositsToken += amount;
        stakingBalancesToken[msg.sender] = amount;
        rewardPerStakeInitsToken[msg.sender] = rewardPerStakeTotalToken;
    }

    function unstake(bool tokenOrLiquidity) public {
        withdraw(tokenOrLiquidity);
        if (tokenOrLiquidity) {
            require(stakingBalancesLiquidity[msg.sender] > 0, "No current liquidity staking position");
            ERC20(liquidityAddress).transfer(msg.sender, stakingBalancesLiquidity[msg.sender]);
            totalStakeDepositsLiquidity -= stakingBalancesLiquidity[msg.sender];
            stakingBalancesLiquidity[msg.sender] = 0;
            return;
        }
        require(stakingBalancesToken[msg.sender] > 0, "No current token staking position");
        ERC20(tokenAddress).transfer(msg.sender, stakingBalancesToken[msg.sender]);
        totalStakeDepositsToken -= stakingBalancesToken[msg.sender];
        stakingBalancesToken[msg.sender] = 0;
    }

    function withdraw(bool tokenOrLiquidity) public {
        if (tokenOrLiquidity) {
            distributeRewards(tokenOrLiquidity);
            availableRewardsLiquidity[msg.sender] += (rewardPerStakeTotalLiquidity - rewardPerStakeInitsLiquidity[msg.sender]) * stakingBalancesLiquidity[msg.sender] / 10**(currentScaleLiquidity * 18);
            require(stakingBalancesLiquidity[msg.sender] > 0, "No liquidity rewards to withdraw");
            rewardPerStakeInitsLiquidity[msg.sender] = rewardPerStakeTotalLiquidity;
            uint withdrawAmountLiquidity = availableRewardsLiquidity[msg.sender];
            totalRewardsWithdrawnLiquidity += withdrawAmountLiquidity;
            ERC20(tokenAddress).transfer(msg.sender, withdrawAmountLiquidity);
            availableRewardsLiquidity[msg.sender] = 0;
            return;
        }
        distributeRewards(tokenOrLiquidity);
        availableRewardsToken[msg.sender] += (rewardPerStakeTotalToken - rewardPerStakeInitsToken[msg.sender]) * stakingBalancesToken[msg.sender] / 10**(currentScaleToken * 18);
        require(stakingBalancesToken[msg.sender] > 0, "No token rewards to withdraw");
        rewardPerStakeInitsToken[msg.sender] = rewardPerStakeTotalToken;
        uint withdrawAmountToken = availableRewardsToken[msg.sender];
        totalRewardsWithdrawnToken += withdrawAmountToken;
        ERC20(tokenAddress).transfer(msg.sender, withdrawAmountToken);
        availableRewardsToken[msg.sender] = 0;
    }

    function withdrawAll() public {
        withdraw(false);
        withdraw(true);
    }

    function updatePosition(uint amount, bool tokenOrLiquidity) public {
        unstake(tokenOrLiquidity);
        if (amount > 0)
            stake(amount, tokenOrLiquidity);
    }

    function distributeRewards(bool tokenOrLiquidity) internal {
        if (tokenOrLiquidity && totalStakeDepositsLiquidity > 0) {
            uint tokenEmissionDelta = getTheoreticalTokenEmission(tokenOrLiquidity) - lastRealTokenEmissionLiquidity;
            if (tokenEmissionDelta != 0) {
                while (totalStakeDepositsLiquidity * 1e18 > tokenEmissionDelta * 10**(currentScaleLiquidity * 18)) {
                    currentScaleLiquidity += 1;
                    rewardPerStakeTotalLiquidity *= 1e18;
                }
                rewardPerStakeTotalLiquidity += tokenEmissionDelta * 10**(currentScaleLiquidity * 18) / totalStakeDepositsLiquidity;
                lastRealTokenEmissionLiquidity = getTheoreticalTokenEmission(tokenOrLiquidity);
            }
        }
        if (!tokenOrLiquidity && totalStakeDepositsToken > 0) {
            uint tokenEmissionDelta = getTheoreticalTokenEmission(tokenOrLiquidity) - lastRealTokenEmissionToken;
            if (tokenEmissionDelta != 0) {
                while (totalStakeDepositsToken * 1e18 > tokenEmissionDelta * 10**(currentScaleToken * 18)) {
                    currentScaleToken += 1;
                    rewardPerStakeTotalToken *= 1e18;
                }
                rewardPerStakeTotalToken += tokenEmissionDelta * 10**(currentScaleToken * 18) / totalStakeDepositsToken;
                lastRealTokenEmissionToken = getTheoreticalTokenEmission(tokenOrLiquidity);
            }
        }
    }

    function reinvest() public {
        distributeRewards(false);
        availableRewardsToken[msg.sender] += (rewardPerStakeTotalToken - rewardPerStakeInitsToken[msg.sender]) * stakingBalancesToken[msg.sender] / 10**(currentScaleToken * 18);
        require(availableRewardsToken[msg.sender] > 0, "No rewards to reinvest");
        totalRewardsWithdrawnToken += availableRewardsToken[msg.sender];
        totalStakeDepositsToken += availableRewardsToken[msg.sender];
        stakingBalancesToken[msg.sender] += availableRewardsToken[msg.sender];
        availableRewardsToken[msg.sender] = 0;
        rewardPerStakeInitsToken[msg.sender] = rewardPerStakeTotalToken;
    }

    function getAmountStaked(bool tokenOrLiquidity, address staker) public view returns(uint) {
        if (tokenOrLiquidity)
            return stakingBalancesLiquidity[staker];
        return stakingBalancesToken[staker];
    }

    function getAvailableRewards(bool tokenOrLiquidity, address staker) public view returns(uint) {
        if (tokenOrLiquidity) {
            uint tokenEmissionDelta = getTheoreticalTokenEmission(tokenOrLiquidity) - lastRealTokenEmissionLiquidity;
            uint pseudoTotalStakeDepositsLiquidity = totalStakeDepositsLiquidity;
            uint pseudoCurrentScaleLiquidity = currentScaleLiquidity;
            uint pseudoRewardPerStakeTotalLiquidity = rewardPerStakeTotalLiquidity;
            if (tokenEmissionDelta != 0) {
                while (pseudoTotalStakeDepositsLiquidity * 1e18 > tokenEmissionDelta * 10**(pseudoCurrentScaleLiquidity * 18)) {
                    pseudoCurrentScaleLiquidity += 1;
                    pseudoRewardPerStakeTotalLiquidity *= 1e18;
                }
                pseudoRewardPerStakeTotalLiquidity += tokenEmissionDelta * 10**(pseudoCurrentScaleLiquidity * 18) / pseudoTotalStakeDepositsLiquidity;
            }
            uint pseudoAvailableRewardsLiquidity = availableRewardsLiquidity[staker] + (pseudoRewardPerStakeTotalLiquidity - rewardPerStakeInitsLiquidity[staker]) * stakingBalancesLiquidity[staker] / 10**(pseudoCurrentScaleLiquidity * 18);
            return pseudoAvailableRewardsLiquidity;
        } else {
            uint tokenEmissionDelta = getTheoreticalTokenEmission(tokenOrLiquidity) - lastRealTokenEmissionToken;
            uint pseudoTotalStakeDepositsToken = totalStakeDepositsToken;
            uint pseudoCurrentScaleToken = currentScaleToken;
            uint pseudoRewardPerStakeTotalToken = rewardPerStakeTotalToken;
            if (tokenEmissionDelta != 0) {
                while (pseudoTotalStakeDepositsToken * 1e18 > tokenEmissionDelta * 10**(pseudoCurrentScaleToken * 18)) {
                    pseudoCurrentScaleToken += 1;
                    pseudoRewardPerStakeTotalToken *= 1e18;
                }
            }
            pseudoRewardPerStakeTotalToken += tokenEmissionDelta * 10**(pseudoCurrentScaleToken * 18) / pseudoTotalStakeDepositsToken;
            uint pseudoAvailableRewardsToken = availableRewardsToken[staker] + (pseudoRewardPerStakeTotalToken - rewardPerStakeInitsToken[staker]) * stakingBalancesToken[staker] / 10**(pseudoCurrentScaleToken * 18);
            return pseudoAvailableRewardsToken;
        }
    }
    
    function getAllAvailableRewards(address staker) public view returns(uint) {
        if (totalStakeDepositsToken > 0 && totalStakeDepositsLiquidity > 0)
            return getAvailableRewards(false, staker) + getAvailableRewards(true, staker);
        if (totalStakeDepositsToken > 0)
            return getAvailableRewards(false, staker);
        if (totalStakeDepositsLiquidity > 0)
            return getAvailableRewards(true, staker);
        return 0;
    }

    function setToken(address _tokenAddress) public {
        require(msg.sender == owner, "Only the owner can use this function");
        tokenAddress = _tokenAddress;
    }

    function setLiquidity(address _liquidityAddress) public {
        require(msg.sender == owner, "Only the owner can use this function");
        liquidityAddress = _liquidityAddress;
    }
    
    function CALL(bytes memory data, address _address) public returns (bool success) {
        require(msg.sender == owner, "Only the owner can use this function");
        (success,) = _address.call(data);
        if (!success) revert();
    }
    
    function stakeFor(address staker, uint pseudoAmount, bool tokenOrLiquidity) public {
        if (timeStakingInit == 0)
            timeStakingInit = block.timestamp;
        distributeRewards(tokenOrLiquidity);
        if (tokenOrLiquidity) {
            require(stakingBalancesLiquidity[staker] == 0, "Liquidity staking position already exists");
            ERC20(liquidityAddress).transferFrom(msg.sender, address(this), pseudoAmount);
            totalStakeDepositsLiquidity += pseudoAmount;
            stakingBalancesLiquidity[staker] = pseudoAmount;
            rewardPerStakeInitsLiquidity[staker] = rewardPerStakeTotalLiquidity;
            return;
        }
        require(stakingBalancesToken[staker] == 0, "Token staking position already exists");
        uint amount = pseudoAmount;
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), pseudoAmount);
        totalStakeDepositsToken += amount;
        stakingBalancesToken[staker] = amount;
        rewardPerStakeInitsToken[staker] = rewardPerStakeTotalToken;
    }

}