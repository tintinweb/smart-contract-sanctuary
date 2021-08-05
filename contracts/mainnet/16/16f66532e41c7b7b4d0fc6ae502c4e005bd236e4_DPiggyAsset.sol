pragma solidity ^0.6.4;

import "SafeMath.sol";
import "Address.sol";
import "EIP20Interface.sol";
import "AucInterface.sol";
import "CompoundInterface.sol";
import "UniswapExchangeInterface.sol";
import "DPiggyAssetInterface.sol";
import "DPiggyInterface.sol";
import "DPiggyAssetData.sol";

/**
 * @title DPiggyAsset
 * @dev The contract is proxied for dPiggyAssetProxy.
 * It is created and managed by dPiggy contract that is also the contract admin.
 * Implements all operations for the Dai deposited for an asset.
 */
contract DPiggyAsset is DPiggyAssetData, DPiggyAssetInterface {
    using SafeMath for uint256;

    /**
     * @dev Function to initialize the contract.
     * It should be called through the `data` argument when creating the proxy.
     * It must be called only once. The `assert` is to guarantee that behavior.
     * @param _tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum. It is the asset for the respective contract. 
     * @param _minimumTimeBetweenExecutions The minimum time in seconds between executions to run the Compound redeem.
     */
    function init(address _tokenAddress, uint256 _minimumTimeBetweenExecutions) external {
        
        assert(
            minimumTimeBetweenExecutions == 0 && 
            executionId == 0 && 
            totalBalance == 0 && 
            tokenAddress == address(0)
        );
        
        tokenAddress = _tokenAddress;
        minimumTimeBetweenExecutions = _minimumTimeBetweenExecutions;
        
        address _compound = DPiggyInterface(admin).compound();
        isCompound = (_tokenAddress == _compound);
        
        totalBalance = 0;
        feeExemptionAmountForAucEscrowed = 0;
        executionId = 0;
        executions[executionId] = Execution({
            time: now, 
            rate: DPiggyInterface(admin).percentagePrecision(),
            totalDai: 0,
            totalRedeemed: 0,
            totalBought: 0,
            totalBalance: 0,
            totalFeeDeduction: 0,
            feeAmount: 0
        });
        
        /* Initialize the stored data that controls the reentrancy guard.
         * Due to the proxy, it must be set on a separate initialize method instead of the constructor.
         */
        _notEntered = true;
    }
    
    /**
     * @dev Function to resign the asset due to a proxy migration.
     * Only can be called by the admin (dPiggy contract).
     * @param users The users to be clear due to the migration.
     * @return cDai and asset amount on the respective contract.
     */
    function resignAssetForMigration(address[] calldata users) nonReentrant onlyAdmin external returns(uint256, uint256) {
        uint256 cDaiAmount = 0;
        uint256 assetAmount = 0;
        
        if (totalBalance > 0) {
            EIP20Interface _compound = EIP20Interface(DPiggyInterface(admin).compound());
            cDaiAmount = _compound.balanceOf(address(this));
            require(_compound.transfer(msg.sender, cDaiAmount));
            
            if (tokenAddress != address(0)) {
                EIP20Interface token = EIP20Interface(tokenAddress);
                assetAmount = token.balanceOf(address(this));
                if (assetAmount > 0) {
                    require(token.transfer(msg.sender, assetAmount));
                }
            } else {
                assetAmount = address(this).balance;
                if (assetAmount > 0) {
                    Address.toPayable(msg.sender).transfer(assetAmount);
                }
            }
            
            totalBalance = 0;
            feeExemptionAmountForAucEscrowed = 0;
            executionId++;
            feeExemptionAmountForUserBaseData[executionId] = 0;
            totalBalanceNormalizedDifference[executionId] = 0;
            
            for (uint256 i = 0; i < users.length; ++i) {
                UserData storage userData = usersData[users[i]];
                if (userData.currentAllocated > 0) {
                    userData.baseExecutionId = 0;
                    userData.baseExecutionAvgRate = 0;
                    userData.baseExecutionAccumulatedAmount = 0;
                    userData.baseExecutionAccumulatedWeightForRate = 0;
                    userData.baseExecutionAmountForFee = 0;
                    userData.currentAllocated = 0;
                    userData.previousAllocated = 0;
                    userData.previousProfit = 0;
                    userData.previousAssetAmount = 0;
                    userData.previousFeeAmount = 0;
                    userData.redeemed = 0;
                }
            }
            
            executions[executionId] = Execution({
                time: now, 
                rate: DPiggyInterface(admin).percentagePrecision(),
                totalDai: 0,
                totalRedeemed: 0,
                totalBought: 0,
                totalBalance: 0,
                totalFeeDeduction: 0,
                feeAmount: 0
            });
        }
        
        return (cDaiAmount, assetAmount);
    }
    
    /**
     * @dev Function to receive ether when it was bought on the Uniswap exchange.
     */
    receive() external payable {
    }
    
    /**
     * @dev Function to get the minimum time for the next Compound redeem execution.
     * @return The minimum time in Unix for the next Compound redeem execution.
     */
    function getMinimumTimeForNextExecution() public view returns(uint256) {
        Execution storage lastExecution = executions[executionId];
        return lastExecution.time.add(minimumTimeBetweenExecutions);
    }
    
    /**
     * @dev Function to get the user's Dai gross profit, asset net profit and the fee amount in Dai.
     * @param user User's address. 
     * @return The user's Dai gross profit, asset net profit and the fee amount charged in Dai. 
     * First return is the gross profit in Dai.
     * Second return is the asset net profit.
     * Third return is the fee amount charged in Dai.
     */
    function getUserProfitsAndFeeAmount(address user) public view override(DPiggyAssetInterface) returns(uint256, uint256, uint256) {
        UserData storage userData = usersData[user];
        return _getUserProfitsAndFeeAmount(DPiggyInterface(admin).escrowStart(user), userData);
    }

    /**
     * @dev Function to get the estimated current gross profit in Dai for the user.
     * So it is not the total gross profit, it is only for the user amount of Dai on the next Compound redeem execution.
     * The estimative of the amount of Dai on the Compound redeem execution considering the current Compound stored rate.
     * For an estimated total of the gross profit: `getUserProfit` + `getUserEstimatedCurrentProfitWithoutFee`.
     * @param user User's address. 
     * @return The estimated gross profit in Dai. 
     */
    function getUserEstimatedCurrentProfitWithoutFee(address user) public view returns(uint256) {
        UserData storage userData = usersData[user];
        if (userData.currentAllocated > 0) {
            CompoundInterface _compound = CompoundInterface(DPiggyInterface(admin).compound());
            Execution storage lastExecution = executions[executionId];
            uint256 rate = _getRateForExecution(_compound.exchangeRateStored().mul(_compound.balanceOf(address(this))).div(1e18), lastExecution);
            
            uint256 remainingBalance = 0;
            if (isCompound) {
                (uint256 executionsProfit,,uint256 feeAmount) = _getUserProfitsAndFeeAmount(DPiggyInterface(admin).escrowStart(user), userData);
                remainingBalance = executionsProfit.sub(feeAmount);
            }
            
            return _getAccruedInterestForExecution(executionId, rate, remainingBalance, userData);
        } else {
            return 0;
        }
    }
    
    /**
     * @dev Function to get the estimated current fee in Dai for the user.
     * To estimate the amount of fee on the Compound redeem execution is calculated by the difference between the `time` and the last execution time.
     * So it is not the total amount of fee, for an estimated total of the fee in Dai: 
     * `getUserAssetProfitAndFeeAmount(second return)` + `getUserEstimatedCurrentFee`.
     * @param user User's address. 
     * @param time The Unix time to calculate the fee. It should be the current Unix time. 
     * @return The estimated fee in Dai. 
     */
    function getUserEstimatedCurrentFee(address user, uint256 time) public view returns(uint256) {
        UserData storage userData = usersData[user];
        if (userData.currentAllocated > 0) {
            uint256 escrowStart = DPiggyInterface(admin).escrowStart(user);
            
            // Whether the user has the Auc escrowed the fee is zero.
            if (escrowStart == 0 || escrowStart > time) {
                Execution storage lastExecution = executions[executionId];
                if (lastExecution.time < time) {
                    uint256 _percentagePrecision = DPiggyInterface(admin).percentagePrecision();
                    uint256 fee = DPiggyInterface(admin).executionFee(time.sub(lastExecution.time));
                    return _getFeeAmountForExecution(userData.baseExecutionId == executionId, fee, _percentagePrecision, userData);
                }
            }
        }
        return 0;
    }
    
    /**
     * @dev Function to get the amount of asset redeemed for the user.
     * @param user User's address. 
     * @return The amount of asset redeemed. 
     */
    function getUserAssetRedeemed(address user) public view returns(uint256) {
        UserData storage userData = usersData[user];
        return userData.redeemed;
    }
    
    /**
     * @dev Function to get the amount of Dai deposited for the user.
     * @param user User's address. 
     * @return The amount of Dai deposited. 
     */
    function getUserTotalInvested(address user) public view returns(uint256) {
        UserData storage userData = usersData[user];
        return userData.currentAllocated;
    }
    
    /**
     * @dev Function to set the minimum time between the Compound redeem executions.
     * Only can be called by the admin (dPiggy contract).
     * @param time New minimum time in seconds between the Compound redeem executions.
     */
    function setMinimumTimeBetweenExecutions(uint256 time) onlyAdmin external override(DPiggyAssetInterface) {
        uint256 oldTime = minimumTimeBetweenExecutions;
        minimumTimeBetweenExecutions = time;
        emit SetMinimumTimeBetweenExecutions(time, oldTime);
    }
    
    /**
     * @dev Function to deposit Dai.
     * Only can be called by the admin (dPiggy contract).
     * On deposit, it sets all previous Dai profit, asset profit and fee amount until the last Compound redeem execution.
     * It sets stored data to be able to calculate the proportional profit and fee on the next Compound redeem execution
     * because the rate is a weighted average of all deposits rate in this period (between executions) 
     * and the same for the fee that should be proportional to the number of days in this period.
     * @param user User's address. 
     * @param amount Amount of Dai deposited.
     */
    function deposit(address user, uint256 amount) nonReentrant onlyAdmin external override(DPiggyAssetInterface) {
        uint256 _percentagePrecision = DPiggyInterface(admin).percentagePrecision();
        
        uint256 baseExecutionAmountForFee = 0;
        uint256 escrowStart = DPiggyInterface(admin).escrowStart(user);
        
        /* If the user has Auc escrowed, all the amount of Dai must set on the respective fee exemption control data. 
         * Otherwise, the fee exemption is the proportional amount of deposited Dai between the last execution and the current execution.  
         * The fee will be charged only during the days that Dai was invested, not all period.
         */
        if (escrowStart > 0) {
            _setEscrow(true, amount);
        } else {
            baseExecutionAmountForFee = _getNextExecutionFeeProportion(amount);
            _setFeeExemptionForNextExecution(true, amount.sub(baseExecutionAmountForFee));
        }
        
        CompoundInterface _compound = CompoundInterface(DPiggyInterface(admin).compound());
        require(EIP20Interface(DPiggyInterface(admin).dai()).approve(address(_compound), amount), "DPiggyAsset::deposit: Error on approve Compound");
        
        Execution storage lastExecution = executions[executionId];
        uint256 rate;
        if (totalBalance > 0) {
            rate = _getRateForExecution(_compound.balanceOfUnderlying(address(this)), lastExecution);
        } else {
            rate = lastExecution.rate;
        }
        
        assert(_compound.mint(amount) == 0);
        
        UserData storage userData = usersData[user];
        uint256 currentWeight = amount.mul(_percentagePrecision).div(rate);
        
        /* Whether there is a previous deposit for the user after the last Compound redeem execution the `base` data should be accumulated.
         * So the average weighted rate for this period is calculated: (total deposit for this period) / Sum [ (deposit n) / (rate n) ]
         */
        if (userData.currentAllocated > 0 && userData.baseExecutionId == executionId) {
            userData.baseExecutionAmountForFee = userData.baseExecutionAmountForFee.add(baseExecutionAmountForFee);
            userData.baseExecutionAccumulatedAmount = userData.baseExecutionAccumulatedAmount.add(amount);
            userData.baseExecutionAccumulatedWeightForRate = userData.baseExecutionAccumulatedWeightForRate.add(currentWeight);
            userData.baseExecutionAvgRate = userData.baseExecutionAccumulatedAmount.mul(_percentagePrecision).div(userData.baseExecutionAccumulatedWeightForRate);
        } else {
            (uint256 previousProfit, uint256 previousAssetAmount, uint256 previousFeeAmount) = _getUserProfitsAndFeeAmount(escrowStart, userData);
            userData.previousProfit = previousProfit;
            userData.previousAssetAmount = previousAssetAmount;
            userData.previousFeeAmount = previousFeeAmount;
            userData.previousAllocated = userData.currentAllocated;
            userData.baseExecutionAmountForFee = baseExecutionAmountForFee;
            userData.baseExecutionAccumulatedAmount = amount;
            userData.baseExecutionAccumulatedWeightForRate = currentWeight;
            userData.baseExecutionAvgRate = rate;
            userData.baseExecutionId = executionId;
        }
        
        userData.currentAllocated = userData.currentAllocated.add(amount);
        
        totalBalance = totalBalance.add(amount);
        _setTotalBalanceNormalizedDifferenceForNextExecution(true, amount, rate, lastExecution.rate);
        
        emit Deposit(user, amount, rate, executionId, baseExecutionAmountForFee);
    }
    
    /**
     * @dev Function to set the fee exemption due to the Auc escrowed for the user.
     * Only can be called by the admin (dPiggy contract).
     * @param user User's address. 
     * @return True if the user has some Dai deposited on the asset otherwise False. 
     */
    function addEscrow(address user) nonReentrant onlyAdmin external override(DPiggyAssetInterface) returns(bool) {
        UserData storage userData = usersData[user];
        if (userData.currentAllocated > 0) {
            _setEscrow(true, userData.currentAllocated);
            
            /* Whether the user deposited Dai after the last Compound redeem execution. The fee deduction calculated must be undone 
             * because with the Auc escrowed all user amount of Dai has fee exemption and it was set in other stored data.
             */
            if (userData.baseExecutionId == executionId) {
                uint256 amount = userData.baseExecutionAccumulatedAmount.sub(userData.baseExecutionAmountForFee);
                _setFeeExemptionForNextExecution(false, amount);
                userData.baseExecutionAmountForFee = 0; 
            }
            
            return true;
        }
        return false;
    }
    
    /**
     * @dev Function to force redeem of the asset profit for the user address.
     * Only can be called by the admin (dPiggy contract).
     * @param user User's address. 
     */
    function forceRedeem(address user) nonReentrant onlyAdmin external {
        _redeem(user, DPiggyInterface(admin).escrowStart(user));
    }
    
    /**
     * @dev Function to force finish of the user participation for the asset.
     * The asset profit is redeemed as well as all the Dai deposited.
     * Only can be called by the admin (dPiggy contract).
     * @param user User's address. 
     */
    function forceFinish(address user) nonReentrant onlyAdmin external {
        _finish(user);
    }
    
    /**
     * @dev Function to execute the Compound redeem.
     * It is redeemed all Dai profit for the period: (total on Compound contract - total deposited).
     * The fee is calculated over total Dai deposited minus:
     *  - Amount of Dai of the users that has Auc escrowed.
     *  - Proportional amount of Dai for users that deposited Dai between last execution and current execution. 
     *    The fee is charged only during the days that the Dai was invested, not all period.
     * The amount of Dai for the fee is used to buy Auc on Uniswap and then the Auc is burned.
     * So the remaining amount of Dai redeemed is used to buy the respective asset on Uniswap.
     * The execution is general, not for a user, the distribution of profit to each user is calculated on redeem/finish functions.
     */
    function executeCompoundRedeem() nonReentrant external {
        require(now >= getMinimumTimeForNextExecution(), "DPiggyAsset::executeCompoundRedeem: Invalid time for execution");
        
        Execution storage lastExecution = executions[executionId];
        CompoundInterface _compound = CompoundInterface(DPiggyInterface(admin).compound());
        
        uint256 feeAmount = 0;
        uint256 totalRedeemed = 0;
        uint256 totalFeeDeduction = 0;
        uint256 daiAmount = 0;
        
        //Whether there is no Dai deposited (totalBalance is zero) the execution still runs to register the basic data on the chain.
        if (totalBalance > 0) {
            totalFeeDeduction = feeExemptionAmountForUserBaseData[(executionId+1)].add(feeExemptionAmountForAucEscrowed);
            uint256 regardedAmountWithFee = totalBalance.sub(totalFeeDeduction);
            if (regardedAmountWithFee > 0) {
                feeAmount = regardedAmountWithFee.mul(DPiggyInterface(admin).executionFee(now.sub(lastExecution.time))).div(DPiggyInterface(admin).percentagePrecision());
            }
            
            daiAmount = _compound.balanceOfUnderlying(address(this));
            totalRedeemed = daiAmount.sub(totalBalance);
            
            //The maximum amount of fee must be lesser or equal to the total of Dai available after the redeemed.
            if (feeAmount > totalRedeemed) {
                feeAmount = totalRedeemed;
            } 
            
            //For Compound asset (cDai), the execution only redeems the fee amount because the cDai keeps invested on Compound contract.
            if (isCompound) {
                totalRedeemed = feeAmount;
            }
        }
        
        uint256 rate;    
        if (totalRedeemed > 0) {
            assert(_compound.redeemUnderlying(totalRedeemed) == 0);
            
            rate = _getRateForExecution(daiAmount, lastExecution);
        } else {
            rate = lastExecution.rate;
        }
        
        executionId++;
        executions[executionId] = Execution({
            time: now, 
            rate: rate,
            totalDai: daiAmount,
            totalRedeemed: totalRedeemed,
            totalBought: 0,
            totalBalance: totalBalance,
            totalFeeDeduction: totalFeeDeduction,
            feeAmount: feeAmount
        });
        
        uint256 totalAucBurned = 0;
        if (feeAmount > 0) {
            totalAucBurned = _burnAuc(feeAmount);
        }
        
        uint256 remainingAmount = totalRedeemed.sub(feeAmount);
        Execution storage currentExecution = executions[executionId];
        if (remainingAmount > 0) {
            currentExecution.totalBought = _buy(remainingAmount, tokenAddress);
        }
        
        emit CompoundRedeem(executionId, rate, totalBalance, totalRedeemed, feeAmount, currentExecution.totalBought, totalAucBurned);
    }
    
    /**
     * @dev Function to redeem the asset profit for the sender address.
     */
    function redeem() nonReentrant external {
        _redeem(msg.sender, DPiggyInterface(admin).escrowStart(msg.sender));
    }
    
    /**
     * @dev Function to finish the sender's participation for the asset.
     * The asset profit is redeemed as well as all the Dai deposited.
     */
    function finish() nonReentrant external {
       _finish(msg.sender);
    }
    
    /**
     * @dev Internal function to redeem the asset profit for the user.
     * @param user User's address. 
     * @param escrowStart The Unix time for user escrow start. Zero means no escrow. 
     */
    function _redeem(address user, uint256 escrowStart) internal {
        //There is no asset profit for Compound asset (cDai).
        if (!isCompound) {
            UserData storage userData = usersData[user];
            (,uint256 previousAssetAmount,) = _getUserProfitsAndFeeAmount(escrowStart, userData);
            if (previousAssetAmount > 0) { 
                uint256 amount = previousAssetAmount.sub(userData.redeemed);
                if (amount > 0) {
                    userData.redeemed = userData.redeemed.add(amount);
                    if (tokenAddress != address(0)) {
                        require(EIP20Interface(tokenAddress).transfer(user, amount), "DPiggyAsset::redeem: Error on transfer");
                    } else {
                        Address.toPayable(user).transfer(amount);
                    }
                    
                    emit Redeem(user, amount);
                }
            }
        }
    }
    
    /**
     * @dev Internal function to finish the user participation for the asset.
     * The asset profit is redeemed as well as all the Dai deposited.
     * It is executed a Compound redeem with total of Dai deposited plus the accrued interest since last Compound redeem execution.
     * @param user User's address. 
     */
    function _finish(address user) internal {
        UserData storage userData = usersData[user];
        if (userData.currentAllocated > 0) {
            uint256 escrowStart = DPiggyInterface(admin).escrowStart(user);
            
            _redeem(user, escrowStart);
            
            CompoundInterface _compound = CompoundInterface(DPiggyInterface(admin).compound());
            
            Execution storage lastExecution = executions[executionId];
            uint256 currentRate = _getRateForExecution(_compound.balanceOfUnderlying(address(this)), lastExecution);
            
            uint256 userAccruedInterest; 
            if (isCompound) {
                (uint256 executionsProfit,,uint256 feeAmount) = _getUserProfitsAndFeeAmount(escrowStart, userData);
                userAccruedInterest = executionsProfit.sub(feeAmount);
                
                //Set the user accrued interest to be subtracted from total balance on next Compound redeem execution. 
                totalBalanceNormalizedDifference[(executionId+1)] = totalBalanceNormalizedDifference[(executionId+1)].add(userAccruedInterest);
                
                userAccruedInterest = userAccruedInterest.add(_getAccruedInterestForExecution(executionId, currentRate, userAccruedInterest, userData));
            } else {
                userAccruedInterest = _getAccruedInterestForExecution(executionId, currentRate, 0, userData);
            }
            uint256 totalRedeemed = userData.currentAllocated.add(userAccruedInterest);
            
            assert(_compound.redeemUnderlying(totalRedeemed) == 0);
            
            require(EIP20Interface(DPiggyInterface(admin).dai()).transfer(user, totalRedeemed), "DPiggyAsset::finish: Error on transfer Dai");
            
            totalBalance = totalBalance.sub(userData.currentAllocated);
            
            // Whether the user did a deposit after the last Compound redeem execution the total balance normalized difference must be undone.
            if (userData.baseExecutionId == executionId) {
                _setTotalBalanceNormalizedDifferenceForNextExecution(false, userData.baseExecutionAccumulatedAmount, userData.baseExecutionAvgRate, lastExecution.rate);
            }
            
            /* Whether the user has Auc escrowed the Dai must be undone on the stored control data.
             * Or, whether the user deposited Dai after the last Compound redeem execution the fee deduction calculated also must be undone.
             */
            if (escrowStart > 0) {
                _setEscrow(false, userData.currentAllocated);
            } else if (userData.baseExecutionId == executionId) {
                _setFeeExemptionForNextExecution(false, userData.baseExecutionAccumulatedAmount.sub(userData.baseExecutionAmountForFee));
            }       
            
            userData.baseExecutionId = 0;
            userData.baseExecutionAvgRate = 0;
            userData.baseExecutionAccumulatedAmount = 0;
            userData.baseExecutionAccumulatedWeightForRate = 0;
            userData.baseExecutionAmountForFee = 0;
            userData.currentAllocated = 0;
            userData.previousAllocated = 0;
            userData.previousProfit = 0;
            userData.previousAssetAmount = 0;
            userData.previousFeeAmount = 0;
            userData.redeemed = 0;
        
            emit Finish(user, totalRedeemed, userAccruedInterest, 0, 0);
        }
    }
    
    /**
     * @dev Internal function to get the next Compound redeem execution fee proportion.
     * The proportion is the relation between the fee for the full amount of days between the executions 
     * and the fee for the number of days considering starting now, not the last execution time.
     * @param amount The amount of Dai to be calculated the proportion.
     * @return The proportional amount for the fee on the next Compound redeem execution.
     */
    function _getNextExecutionFeeProportion(uint256 amount) internal view returns(uint256) {
        uint256 nextExecution = getMinimumTimeForNextExecution();
        if (nextExecution > now) {
            Execution storage lastExecution = executions[executionId];
            uint256 fullFee = DPiggyInterface(admin).executionFee(nextExecution.sub(lastExecution.time));
            if (fullFee > 0) {
                uint256 proportionalFee = DPiggyInterface(admin).executionFee(nextExecution.sub(now));
                return proportionalFee.mul(amount).div(fullFee);
            }
        }
        return 0;
    }
    
    /**
     * @dev Internal function to get the calculated rate.
     * @param amount The amount of Dai.
     * @param lastExecution The last Compound redeem execution data.
     * @return The calculated rate for the execution.
     */
    function _getRateForExecution(uint256 amount, Execution storage lastExecution) internal view returns(uint256) {
        uint256 remainingBalance = 0;
        //Whether the asset is cDai then the net profit continues on Compound contract.
        if (isCompound && lastExecution.totalRedeemed > 0) {
            remainingBalance = lastExecution.totalDai.sub(lastExecution.totalBalance).sub(lastExecution.totalRedeemed);
        }
        return amount.mul(lastExecution.rate).div(totalBalance.add(remainingBalance).sub(totalBalanceNormalizedDifference[(executionId+1)]));
    }
    
    /**
     * @dev Internal function to get the user accrued interest for the Compound redeem execution.
     * @param previousExecutionId The previous execution id.
     * @param currentRate The rate for the current execution.
     * @param compoundRemainingBalance Remaining balance of Dai on Compound.
     * @param userData Stored data for the user.
     * @return The user accrued interest in Dai.
     */
    function _getAccruedInterestForExecution(
        uint256 previousExecutionId, 
        uint256 currentRate, 
        uint256 compoundRemainingBalance,
        UserData storage userData
    ) internal view returns(uint256) {
        Execution storage previousExecution = executions[previousExecutionId];
        uint256 userAccruedInterest;
        
        //Whether there is a deposit after the previous Compound redeem execution the base average rate must be used for the amount deposited.
        if (userData.baseExecutionId == previousExecutionId) {
            
            userAccruedInterest = _calculatetAccruedInterest(userData.baseExecutionAccumulatedAmount, currentRate, userData.baseExecutionAvgRate);
            
            //Whether there is a previous accrued interest of Dai since the previous execution.
            if (userData.previousAllocated > 0) {
                userAccruedInterest = userAccruedInterest.add(_calculatetAccruedInterest(compoundRemainingBalance.add(userData.previousAllocated), currentRate, previousExecution.rate));
            }
        } else {
            userAccruedInterest = _calculatetAccruedInterest(compoundRemainingBalance.add(userData.currentAllocated), currentRate, previousExecution.rate);
        }
        
        return userAccruedInterest;
    }
    
    /**
     * @dev Internal function to calculate the accrued interest.
     * @param amount The invested amount.
     * @param currentRate The rate for the current execution.
     * @param previousRate The rate for the previous execution.
     * @return Tha accrued interest calculated.
     */
    function _calculatetAccruedInterest(
        uint256 amount, 
        uint256 currentRate, 
        uint256 previousRate
    ) internal pure returns(uint256) {
        return amount.mul(currentRate).div(previousRate).sub(amount);
    }
    
    /**
     * @dev Internal function to get the user asset net profit and the fee amount charged in Dai.
     * @param escrowStart The Unix time for user escrow start. Zero means no escrow. 
     * @param userData Stored data for the user.
     * @return The user's Dai gross profit, asset net profit and the fee amount in Dai.
     */
    function _getUserProfitsAndFeeAmount(uint256 escrowStart, UserData storage userData) internal view returns(uint256, uint256, uint256) {
        if (userData.currentAllocated > 0) {
            uint256 accruedInterest = userData.previousProfit;
            uint256 assetAmount = userData.previousAssetAmount;
            uint256 feeAmount = userData.previousFeeAmount;
            uint256 remainingBalance = 0;
            if (isCompound) {
                remainingBalance = accruedInterest.sub(feeAmount);
            }
            for (uint256 i = (userData.baseExecutionId+1); i <= executionId; i++) {
                Execution storage execution = executions[i];
                if (execution.totalRedeemed > 0) {   
                    
                    uint256 userAccruedInterest = _getAccruedInterestForExecution(i - 1, execution.rate, remainingBalance, userData);
                    
                    accruedInterest = accruedInterest.add(userAccruedInterest);            
                    
                    uint256 userFeeAmout = 0;
                    //Whether there is no Auc escrowed and the execution had a fee.
                    if ((escrowStart == 0 || escrowStart > execution.time) && execution.feeAmount > 0) {
                        userFeeAmout = _getFeeAmountForExecution((userData.baseExecutionId+1) == i, execution.feeAmount, execution.totalBalance.sub(execution.totalFeeDeduction), userData);
                        
                        //The maximum amount of fee must be lesser or equal to the user's accrued interest.
                        if (userFeeAmout > userAccruedInterest) {
                            userFeeAmout = userAccruedInterest;
                        }
                        feeAmount = feeAmount.add(userFeeAmout);
                    }
                    
                    //Whether the asset is cDai then the net profit continues on Compound contract.
                    if (isCompound) {
                        remainingBalance = remainingBalance.add(userAccruedInterest.sub(userFeeAmout));
                    }
                    
                    if (execution.totalBought > 0) {
                        assetAmount = assetAmount.add(userAccruedInterest.sub(userFeeAmout).mul(execution.totalBought).div(execution.totalRedeemed.sub(execution.feeAmount)));
                    }
                }
            }
            return (accruedInterest, assetAmount, feeAmount);
        } else {
            return (0, 0, 0);
        }
    }
    
    /**
     * @dev Internal function to get the user fee amount in Dai for the execution.
     * @param isBaseMonth Whether it is the month just after the user deposit.
     * @param multiplier Multiplier value on the calculation. 
     * @param denominator Denominator value on the calculation.  
     * @param userData Stored data for the user.
     * @return The fee amount in Dai.
     */
    function _getFeeAmountForExecution(
        bool isBaseMonth,
        uint256 multiplier,
        uint256 denominator,
        UserData storage userData
    ) internal view returns(uint256) {
        uint256 regardedAmountWithFee;
        
        if (isBaseMonth) {
            regardedAmountWithFee = userData.previousAllocated.add(userData.baseExecutionAmountForFee);
        } else {
            regardedAmountWithFee = userData.currentAllocated;
        }
        
        return regardedAmountWithFee.mul(multiplier).div(denominator); 
    }
    
    /**
     * @dev Internal function to set an amount of Dai that has fee exemption on the next Compound redeem execution.
     * @param commit Whether it is adding the fee exemption.
     * @param amount The amount of Dai with fee exemption.
     */
    function _setFeeExemptionForNextExecution(bool commit, uint256 amount) internal {
        if (amount > 0) {
            uint256 nextExecution = executionId + 1;
            if (commit) {
                feeExemptionAmountForUserBaseData[nextExecution] = feeExemptionAmountForUserBaseData[nextExecution].add(amount);
            } else {
                feeExemptionAmountForUserBaseData[nextExecution] = feeExemptionAmountForUserBaseData[nextExecution].sub(amount);
            }
        }
    }
    
    /**
     * @dev Internal function to set the difference between the amount of Dai deposited and the respective value normalized to the last Compound redeem execution time.
     * @param commit Whether it is adding the difference for next Compound redeem execution.
     * @param totalAmount The total amount of Dai to be normalized.
     * @param currentRate The current rate.
     * @param previousRate The previous rate.
     */
    function _setTotalBalanceNormalizedDifferenceForNextExecution(
        bool commit, 
        uint256 totalAmount,
        uint256 currentRate,
        uint256 previousRate
    ) internal {
        uint256 nextExecution = executionId + 1;
        uint256 amount = totalAmount.sub(totalAmount.mul(previousRate).div(currentRate));
        if (commit) {
            totalBalanceNormalizedDifference[nextExecution] = totalBalanceNormalizedDifference[nextExecution].add(amount);
        } else {
            totalBalanceNormalizedDifference[nextExecution] = totalBalanceNormalizedDifference[nextExecution].sub(amount);
        }
    }
    
    /**
     * @dev Internal function to set an amount of Dai that has fee exemption due to Auc escrowed.
     * @param commit Whether it is adding the fee exemption.
     * @param amount The amount of Dai with fee exemption.
     */
    function _setEscrow(bool commit, uint256 amount) internal {
        if (commit) {
            feeExemptionAmountForAucEscrowed = feeExemptionAmountForAucEscrowed.add(amount);
        } else {
            feeExemptionAmountForAucEscrowed = feeExemptionAmountForAucEscrowed.sub(amount);
        }
    }

    /**
     * @dev Internal function to buy an asset on Uniswap.
     * @param _tokenAddress The ERC20 token address on the chain or '0x0' for Ethereum that should be purchased.
     * @param amount The amount of Dai to buy the asset.
     * @return The total amount of asset purchased.
     */
    function _buy(uint256 amount, address _tokenAddress) internal returns(uint256) {
        address _exchange = DPiggyInterface(admin).exchange();
        uint256 deadline = now + 86400;
        require(EIP20Interface(DPiggyInterface(admin).dai()).approve(_exchange, amount), "DPiggyAsset::_buy: Error on approve UniswapExchange");
        if (_tokenAddress != address(0)) {
            return UniswapExchangeInterface(_exchange).tokenToTokenSwapInput(amount, 1, 1, deadline, _tokenAddress);
        } else {
            return UniswapExchangeInterface(_exchange).tokenToEthSwapInput(amount, 1, deadline);
        }
    }
    
    /**
     * @dev Internal function to buy and then burn the Auc.
     * @param amount The amount of Dai. It is the fee amount on the Compound redeem execution.
     * @return The total amount of Auc burned.
     */
    function _burnAuc(uint256 amount) internal returns(uint256) {
        address _auc = DPiggyInterface(admin).auc();
        uint256 totalBought = _buy(amount, _auc);
        require(AucInterface(_auc).burn(totalBought), "DPiggyAsset::_burnAuc: Error on burn AUC");
        return totalBought;
    }
}
