/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.3;

interface ERC20 {
    function transfer(address to, uint tokens) external;
    function transferFrom(address from, address to, uint tokens) external;
    function totalSupply() external view returns (uint); // change to Rebaser's orbiSupplyTotal for Mainnet
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
    
    function getTheoreticalTokenEmission(bool tokenOrLiquidity) public view returns(uint) {
        if (tokenOrLiquidity)
            return (1e16 - 1e16 * 3504000 / ((block.timestamp - creationTime) + 3504000)) * 5 / 6;
        return (1e16 - 1e16 * 3504000 / ((block.timestamp - creationTime) + 3504000)) / 6;
    }
    
    function stake(uint pseudoAmount, bool tokenOrLiquidity) public {
        distributeRewards(tokenOrLiquidity);
        if (tokenOrLiquidity) {
            require(stakingBalancesLiquidity[msg.sender] == 0, "Staking position already exists");
            ERC20(liquidityAddress).transferFrom(msg.sender, address(this), pseudoAmount);
            totalStakeDepositsLiquidity += pseudoAmount;
            stakingBalancesLiquidity[msg.sender] = pseudoAmount;
            rewardPerStakeInitsLiquidity[msg.sender] = rewardPerStakeTotalLiquidity;
            return;
        }
        require(stakingBalancesToken[msg.sender] == 0, "Staking position already exists");
        uint amount = pseudoAmount * 1e17 / ERC20(tokenAddress).totalSupply();
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), pseudoAmount);
        totalStakeDepositsToken += amount;
        stakingBalancesToken[msg.sender] = amount;
        rewardPerStakeInitsToken[msg.sender] = rewardPerStakeTotalToken;
    }
    
    function unstake(bool tokenOrLiquidity) public {
        withdraw(false, tokenOrLiquidity);
        if (tokenOrLiquidity) {
            ERC20(liquidityAddress).transfer(msg.sender, stakingBalancesLiquidity[msg.sender]);
            totalStakeDepositsLiquidity -= stakingBalancesLiquidity[msg.sender];
            stakingBalancesLiquidity[msg.sender] = 0;
            return;
        }
        ERC20(tokenAddress).transfer(msg.sender, stakingBalancesToken[msg.sender] * ERC20(tokenAddress).totalSupply() / 1e17);
        totalStakeDepositsToken -= stakingBalancesToken[msg.sender];
        stakingBalancesToken[msg.sender] = 0;
    }
    
    function withdraw(bool reinvesting, bool tokenOrLiquidity) public {
        require(!(reinvesting && tokenOrLiquidity), "Cannot reinvest in liquidity stake");
        if (tokenOrLiquidity) {
            distributeRewards(tokenOrLiquidity);
            availableRewardsLiquidity[msg.sender] += (rewardPerStakeTotalLiquidity - rewardPerStakeInitsLiquidity[msg.sender]) * stakingBalancesLiquidity[msg.sender] / 10**(currentScaleLiquidity * 18);
            rewardPerStakeInitsLiquidity[msg.sender] = rewardPerStakeTotalLiquidity;
            uint withdrawAmountLiquidity = availableRewardsLiquidity[msg.sender] * ERC20(tokenAddress).totalSupply() / 1e17;
            totalRewardsWithdrawnLiquidity += withdrawAmountLiquidity;
            ERC20(liquidityAddress).transfer(msg.sender, withdrawAmountLiquidity);
            availableRewardsLiquidity[msg.sender] = 0;
            return;
        }
        distributeRewards(tokenOrLiquidity);
        availableRewardsToken[msg.sender] += (rewardPerStakeTotalToken - rewardPerStakeInitsToken[msg.sender]) * stakingBalancesToken[msg.sender] / 10**(currentScaleToken * 18);
        rewardPerStakeInitsToken[msg.sender] = rewardPerStakeTotalToken;
        if (reinvesting) {
            stakingBalancesToken[msg.sender] += availableRewardsToken[msg.sender];
            totalStakeDepositsToken += availableRewardsToken[msg.sender];
            availableRewardsToken[msg.sender] = 0;
            return;
        }
        uint withdrawAmountToken = availableRewardsToken[msg.sender] * ERC20(tokenAddress).totalSupply() / 1e17;
        totalRewardsWithdrawnToken += withdrawAmountToken;
        ERC20(tokenAddress).transfer(msg.sender, withdrawAmountToken);
        availableRewardsToken[msg.sender] = 0;
    }
    
    function withdrawAll() public {
        withdraw(false, false);
        withdraw(false, true);
    }
    
    function updatePosition(uint amount, bool tokenOrLiquidity) public {
        unstake(tokenOrLiquidity);
        if (amount > 0)
            stake(amount, tokenOrLiquidity);
    }
    
    function distributeRewards(bool tokenOrLiquidity) internal {
        if (tokenOrLiquidity && totalStakeDepositsLiquidity > 0) {
            uint tokenEmissionDelta = getTheoreticalTokenEmission(tokenOrLiquidity) - lastRealTokenEmissionLiquidity;
            while (totalStakeDepositsLiquidity > tokenEmissionDelta * 10**(currentScaleLiquidity * 18)) {
                currentScaleLiquidity += 1;
                rewardPerStakeTotalLiquidity *= 1e18;
            }
            rewardPerStakeTotalLiquidity += tokenEmissionDelta * 10**(currentScaleLiquidity * 18) / totalStakeDepositsLiquidity;
            lastRealTokenEmissionLiquidity = getTheoreticalTokenEmission(tokenOrLiquidity);
        } 
        if (!tokenOrLiquidity && totalStakeDepositsToken > 0) {
            uint tokenEmissionDelta = getTheoreticalTokenEmission(tokenOrLiquidity) - lastRealTokenEmissionToken;
            while (totalStakeDepositsToken > tokenEmissionDelta * 10**(currentScaleToken * 18)) {
                currentScaleToken += 1;
                rewardPerStakeTotalToken *= 1e18;
            }
            rewardPerStakeTotalToken += tokenEmissionDelta * 10**(currentScaleToken * 18) / totalStakeDepositsToken;
            lastRealTokenEmissionToken = getTheoreticalTokenEmission(tokenOrLiquidity);
        }
    }
    
    function reinvest() public {
        withdraw(true, false);
    }
    
    function getAmountStaked(bool tokenOrLiquidity, address staker) public view returns(uint) {
        if (tokenOrLiquidity)
            return stakingBalancesLiquidity[staker] * ERC20(tokenAddress).totalSupply() / 1e17;
        return stakingBalancesToken[staker] * ERC20(tokenAddress).totalSupply() / 1e17;
    }
    
    function getAvailableRewards(bool tokenOrLiquidity, address staker) public view returns(uint) {
        if (tokenOrLiquidity) {
            uint tokenEmissionDelta = getTheoreticalTokenEmission(tokenOrLiquidity) - lastRealTokenEmissionLiquidity;
            uint pseudoTotalStakeDepositsLiquidity = totalStakeDepositsLiquidity;
            uint pseudoCurrentScaleLiquidity = currentScaleLiquidity;
            uint pseudoRewardPerStakeTotalLiquidity = rewardPerStakeTotalLiquidity;
            while (pseudoTotalStakeDepositsLiquidity > tokenEmissionDelta * 10**(pseudoCurrentScaleLiquidity * 18)) {
                pseudoCurrentScaleLiquidity += 1;
                pseudoRewardPerStakeTotalLiquidity *= 1e18;
            }
            pseudoRewardPerStakeTotalLiquidity += tokenEmissionDelta * 10**(pseudoCurrentScaleLiquidity * 18) / pseudoTotalStakeDepositsLiquidity;
            uint pseudoAvailableRewardsLiquidity = availableRewardsLiquidity[staker] + (pseudoRewardPerStakeTotalLiquidity - rewardPerStakeInitsLiquidity[staker]) * stakingBalancesLiquidity[staker] / 10**(pseudoCurrentScaleLiquidity * 18);
            return pseudoAvailableRewardsLiquidity * ERC20(tokenAddress).totalSupply() / 1e17;
        } else {
            uint tokenEmissionDelta = getTheoreticalTokenEmission(tokenOrLiquidity) - lastRealTokenEmissionToken;
            uint pseudoTotalStakeDepositsToken = totalStakeDepositsToken;
            uint pseudoCurrentScaleToken = currentScaleToken;
            uint pseudoRewardPerStakeTotalToken = rewardPerStakeTotalToken;
            while (pseudoTotalStakeDepositsToken > tokenEmissionDelta * 10**(pseudoCurrentScaleToken * 18)) {
                pseudoCurrentScaleToken += 1;
                pseudoRewardPerStakeTotalToken *= 1e18;
            }
            pseudoRewardPerStakeTotalToken += tokenEmissionDelta * 10**(pseudoCurrentScaleToken * 18) / pseudoTotalStakeDepositsToken;
            uint pseudoAvailableRewardsToken = availableRewardsToken[staker] + (pseudoRewardPerStakeTotalToken - rewardPerStakeInitsLiquidity[staker]) * stakingBalancesToken[staker] / 10**(pseudoCurrentScaleToken * 18);
            return pseudoAvailableRewardsToken * ERC20(tokenAddress).totalSupply() / 1e17;
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
    
}