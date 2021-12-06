// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./transfer/Transfers.sol";
import "./interfaces/TokenRecipient.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract
 * @dev OMNIA token contract that overriden ERC20Burnable and ERC20Permit contracts
 *      to apply 15% fee.
 */
contract OMNIA is Transfers {
    /**
     * @dev Sets router manager, swap manager, Rewards contract and initiliase
     *      both contracts.
     *
     *      Sets auto liquidity wallet.
     *
     *      Excludes default addresses from fees, sets the mainnet router & sets
     *      `autoLiquidityWallet` to {owner()} who is {_msgSender()} at deployment.
     *
     *      Mints 10M OMNIA to `_msgSender()`.
     */
    constructor(
        address routerManager_,
        address swapManager_,
        address pcsRouter_,
        address rewards_
    ) ERC20("OMNIA token", "OMNIA") ERC20Permit("OMNIA token") {
        router = IRouterManager(routerManager_);
        swapManager = ISwapManager(swapManager_);
        rewards = IRewards(rewards_);

        // Initialize PancakeSwap V2 router and OMNIA <-> BNB pair.
        // Mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        router.initialize(address(this), pcsRouter_, rewards_);
        rewards.initialize(routerManager_, swapManager_, address(this));

        autoLiquidityWallet = owner();

        _addressesExcludedFromFeesByDefault();

        _mint(_msgSender(), 10**7 * 10**18);
    }

    function _addressesExcludedFromFeesByDefault() private {
        setExcludedFromFees(address(this), true);
        setExcludedFromFees(address(rewards), true);
        setExcludedFromFees(owner(), true);

        setExcludedFromFees(DX_SALE_LOCK, true);
        setExcludedFromFees(UNICRYPT_LOCK, true);
        setExcludedFromFees(UNICRYPT_LOCK_FEES, true);
        setExcludedFromFees(rewards.OMNIA_REFLECTION_WALLET(), true);
    }

    /**
     * @dev Updates Rewards contract.
     *
     *      Excludes the new Rewards contract from fees and rewards.
     *      Also update the instance of Rewards in RouterManager.
     *
     *      Initialise the new Rewards contract.
     *
     *  Requirements:
     * - only the owner can update it
     */
    function updateRewardsContract(address rewards_) external onlyOwner {
        rewards = IRewards(rewards_);

        // Fee exclusion happens in OMNIA
        // Rewards exclusion happens in Rewards contract AND each new Rewards contract
        // instance is excluded in {Rewards.initialise}
        setExcludedFromFees(address(rewards), true);

        // Update new Rewards contract in RouterManager too: OMNIA or owner
        router.updateRewardsContract(rewards_);

        rewards.initialize(
            address(router),
            address(swapManager),
            address(this)
        );
    }

    /**
     * @dev Integrates an approve and call method for contracts that integrates {TokenRecipient}.
     */
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes calldata _extraData
    ) external returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(_msgSender(), _value, _extraData);
            return true;
        }
    }

    /**
     * @dev Transfers lost BEP20 sent by error to Rewards contract.
     *
     *      Only lost OMNIA token can be retrieved by the owner. This
     *      means the amount of OMNIA token allocated to liquidity addings
     *      will never be able to be withdrawn.
     *
     * Requirements:
     * - only the owner can transfers lost BEP20
     * - `maxOunt` of OMNIA to transfer cant be 0
     */
    function transferLostBEP20(address tokenAddress, address to)
        external
        onlyOwner
    {
        uint256 maxAmount = ERC20(tokenAddress).balanceOf(address(this));

        if (tokenAddress == address(this)) {
            // Amount of OMNIA left minus amount of OMNIA allocated to
            // liquidity addings
            maxAmount -= totalOmniaToBeAddedToLiquidity;
            require(maxAmount > 0, "OMNIA reserved to liquidity");
        }

        ERC20(tokenAddress).transfer(to, maxAmount);
    }

    /**
     * @dev Transfer lost BNB to `to` address.
     *
     *      We allow to transfer `amount` BNB and not the whole balance as
     *      a small portion might be what OMNIA couldn't add to liquidity.
     */
    function transferLostBNB(address payable to, uint256 amount)
        external
        payable
        onlyOwner
    {
        to.transfer(amount);
    }

    /**
     * @dev Excludes the `newOwner` from fees.
     *
     * @inheritdoc Ownable
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        setExcludedFromFees(newOwner, true);
        super.transferOwnership(newOwner);
    }

    /**
     * @inheritdoc ExternalContracts
     */
    function _excludeExternalContractFromFees(address addr) internal override {
        setExcludedFromFees(addr, true);
    }

    /**
     * @dev Ensures OMNIA token contract is able to receive BNB.
     */
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../dailySell/DailySellManager.sol";
import "./TransferManager.sol";
import "../liquidityAddings/LiquidityAddingsManager.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 * @dev Defines the behaviour of any transfers. Applies the 15% fee if needed,
 *      overrides {ERC20._beforeTokenTransfer()} & overloads {ERC20._afterTokenTransfer()}.
 */
abstract contract Transfers is
    DailySellManager,
    TransferManager,
    LiquidityAddingsManager
{
    /**
     * @notice Only called in {OMNIA.constructor()}.
     * @dev Overrides {ERC20._mint()} to use overloaded {_afterTokenTransfer()}.
     *
     * @inheritdoc ERC20
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(amount > 0, "Mint: amount <= 0");

        super._mint(account, amount);
    }

    /**
     * @dev Overrides {ERC20._transfer()} to apply 15% fee using {_processTransfer()}
     *      and uses overloaded {_afterTokenTransfer()}.
     *
     * @inheritdoc ERC20
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(sender != address(0), "Transfer from: addr(0)");
        require(recipient != address(0), "Transfer to: addr(0)");
        require(amount > 0, "Transfer: amount <= 0");

        if (isListed) _beforeTokenTransfer(sender, recipient, amount);

        (
            uint256 sentAmount,
            uint256 transferAmount,
            ,
            uint256 liquidityFee
        ) = _processTransfer(sender, recipient, amount);

        if (isListed)
            _afterTokenTransfer(sender, recipient, sentAmount, liquidityFee);
    }

    /**
     * @dev Overrides {ERC20._beforeTokenTransfer()} to update next rewards claiming date
     *      for both the `sender` and the `recipient`.
     *
     *      If Rewards contract is set or swapping to add liquidity or Rewards contract is
     *      processing auto claim we skip the actions below.
     *
     *      Updates the total reward points (for both sender & receiver) to avoid flashloans
     *      attack.
     *      Process the auto claim on transfers.
     *
     * @inheritdoc ERC20
     */
    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (address(rewards) == address(0)) return;
        if (
            !(!isSwapAddingLiquidity(sender, recipient) &&
                !rewards.isProcessingAutoClaim())
        ) {
            return;
        }

        // Extend the reward cycle according to the amount transferred.  This is done so
        // that users do not abuse the cycle (buy before it ends & sell after they claim
        // the reward)
        rewards.updateNextClaimDate(recipient, balanceOf(recipient), amount);
        rewards.updateNextClaimDate(sender, balanceOf(sender), amount);

        // update reward points
        rewards.updateRewardPointsOnTransfer(sender, recipient);

        // Trigger auto-claim: listed on PCS, sender not Rewards contract, simple transfer only,
        // auto claim interval has been reached, is not currently auto claiming and auto claim
        // not paused
        bool _canProcessAutoRewardCalim = isListed &&
            sender != address(rewards) &&
            router.isNotSellingAndNotPurchasing(sender, recipient) &&
            rewards.processAutoClaimIntervalReached() &&
            !rewards.isProcessingAutoClaim() &&
            !rewards.autoClaimPaused();
        if (_canProcessAutoRewardCalim) {
            try
                rewards.processAutoClaim(
                    rewards.maxBatchRewardsDistributionGAS()
                )
            {} catch {}
        }
    }

    /**
     * @dev Calculates exact amount to send with daily restriction & fee if applicable.
     *
     *      Update total amount of OMNIA eligible for rewards (critical part for rewards
     *      calculation).
     *
     *      If Rewards contract is set, it updates balances to apply fees & update public
     *      counters related to taken fees.
     *
     *      If transfer is not a swap to add liquidity nor a transfer to send out rewards,
     *      it updates auto claim queue {Rewards.updateAutoClaimQueue}.
     *
     * @return sentAmount
     *         amount sent without fees.
     * @return transferAmount
     *         amount the `recipient` receives after the 15% fee has been applied.
     * @return rewardFee
     *         amount of OMNIA that is allocated for liquidity addings.
     * @return liquidityFee
     *         amount of OMNIA that is allocated for rewards.
     *
     * Emits a {Transfer} event.
     */
    function _processTransfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        virtual
        returns (
            uint256 sentAmount,
            uint256 transferAmount,
            uint256 rewardFee,
            uint256 liquidityFee
        )
    {
        (
            sentAmount,
            transferAmount,
            rewardFee,
            liquidityFee
        ) = _calculateTransferAmounts(sender, recipient, amount);

        rewards.updateEligibleSupplyForRewards(
            sender,
            recipient,
            sentAmount,
            transferAmount
        );

        // Update balances
        if (address(rewards) != address(0)) {
            _updateBalances(
                sender,
                recipient,
                sentAmount,
                rewardFee,
                liquidityFee
            );
        }

        // Update auto-claim queue after balances have been updated
        if (
            !isSwapAddingLiquidity(sender, recipient) &&
            !rewards.isProcessingAutoClaim()
        ) {
            rewards.updateAutoClaimQueue(sender);
            rewards.updateAutoClaimQueue(recipient);
        }

        emit Transfer(sender, recipient, transferAmount);
    }

    /**
     * @dev Update balances taking fees into account.
     *
     *      Updates public counters to track total amount of OMNIA taken as fees for
     *      both rewards and liquidty: `_totalFeesPooledForRewards` &
     *      `totalFeesPooledForLiquidity`.
     *
     * @param sender address sending `sentAmount` of OMNIA.
     * @param recipient address receiving amount of OMNIA from `sender`, with fee applied.
     * @param sentAmount original amount of OMNIA sent by `sender` to `recipient`.
     * @param rewardFee amount of OMNIA allocated for rewards and sent to Rewards contract.
     * @param liquidityFee amount of OMNIA allocated for liquidity addings and sent to
     *                     OMNIA token  contract.
     */
    function _updateBalances(
        address sender,
        address recipient,
        uint256 sentAmount,
        uint256 rewardFee,
        uint256 liquidityFee
    ) internal {
        // Calculate amount to be received by recipient
        uint256 receivedAmount = sentAmount - rewardFee - liquidityFee;

        // Update balances
        _balances[sender] -= sentAmount;
        _balances[recipient] += receivedAmount;

        // Sent reward fees to Rewards contract
        _balances[address(rewards)] += rewardFee;
        // Add liquidity fee to OMNIA contract
        _balances[address(this)] += liquidityFee;

        // Update counters
        _totalFeesPooledForRewards += rewardFee;
        totalFeesPooledForLiquidity += liquidityFee;
    }

    /**
     * @dev If the transfer is a sell, it adds liquidity & update amount sold by `sender`.
     *
     * @param sender address sending the original amount `sentAmount` of OMNIA (fee not applied yet).
     * @param recipient address receiving the amount of OMNIA token from `sender` (fee applied).
     * @param sentAmount original amount sent by `sender` (AKA amount without fee, the number the
     *                   user see when they do a transfer).
     * @param liquidityFee amount allocated to liquidity addings.
     */
    function _afterTokenTransfer(
        address sender,
        address recipient,
        uint256 sentAmount,
        uint256 liquidityFee
    ) internal virtual {
        if (router.isSelling(sender, recipient)) {
            _addLiquidityIfNeeded(sender, recipient, liquidityFee);

            if (router.isNotRouterNorPair(sender))
                _dailySellOf[sender].sold += sentAmount;
        }
    }

    /**
     * @dev If `sender` is selling and is not router nor pair, calculates how much they can send
     *      at maximum to avoid going above daily sell threshold.
     *
     *      In any case it calculates how much OMNIA is taken as fee due to the 15% fee.
     *
     * @param sender address sending OMNIA.
     * @param recipient address receiving OMNIA.
     * @param amount amount of OMNIA from `sender` to `recipient` (without any fee applied yet).
     *
     * @return sentAmount
     *         amount sent without fees.
     * @return transferAmount
     *         amount the `recipient` receives after the 15% fee has been applied.
     * @return rewardFee
     *         amount of OMNIA that is allocated for liquidity addings.
     * @return liquidityFee
     *         amount of OMNIA that is allocated for rewards.
     */
    function _calculateTransferAmounts(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        returns (
            uint256 sentAmount,
            uint256 transferAmount,
            uint256 rewardFee,
            uint256 liquidityFee
        )
    {
        bool isSellingAndListed = router.isSelling(sender, recipient) &&
            isListed;
        bool _senderIsNotRouterNorPair = router.isNotRouterNorPair(sender);

        /// Apply daily restriction only if `sender` is selling AND OMNIA listed on PCS
        /// AND exclude router AND pair from daily restriction
        if (isSellingAndListed && _senderIsNotRouterNorPair)
            sentAmount = _triggerDailyLimit(sender, amount);
        else sentAmount = amount;

        // Calculate fee rate
        uint256 feeRate = _calculateFeeRate(sender, recipient);
        // Calculate amounts reserved for rewards and for liquidity addings
        (rewardFee, liquidityFee) = _calculateSpecificFees(
            (sentAmount * feeRate) / 100
        );
        transferAmount = sentAmount - rewardFee - liquidityFee;
    }

    /**
     * @dev Calculates amount of fees taken for rewards & for liquidity.
     *
     *      If `MAX_BNB_LOCKED` has already been added to LP due to transfer fee
     *      the total amount of fee will be used to send rewards?
     *
     * @param feeAmount_ total amount of fee to be splitted between liquidity & rewards.
     */
    function _calculateSpecificFees(uint256 feeAmount_)
        internal
        view
        returns (uint256 rewardFee, uint256 liquidityFee)
    {
        // If 12,000 have not been added yet as liquidity
        if (totalBNBAddedToLiquidity < MAX_BNB_LOCKED) {
            rewardFee += (feeAmount_ * REWARD_FEE) / TOTAL_TRANSACTION_FEE;
            liquidityFee +=
                (feeAmount_ * LIQUIDITY_FEE) /
                TOTAL_TRANSACTION_FEE;
        } else rewardFee += feeAmount_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface TokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        bytes calldata _extraData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../externalContracts/ExternalContracts.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 * @dev Defines daily sell restriction and calculate circluating supply.
 */
abstract contract DailySellManager is ExternalContracts {
    uint256 public constant DAILY_SELL_PERCENTAGE = 10**3; // 0.1% = 0.0001 = 10^-3

    struct Sell {
        uint256 latestReset;
        uint256 sold;
    }

    mapping(address => Sell) internal _dailySellOf;

    /**
     * @dev Every addresses are restricted to a daily sell of 0.1% of the total supply.
     *      Calculate how much `sender` can sell right now.
     *
     * @param sender address sending OMNIA.
     * @param amount amount of OMNIA sending (15% fee not taken in account here).
     *
     * @return uint256
     *         how many OMNIA the `sender` can sell right now, in Wei.
     */
    function _triggerDailyLimit(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        /// If last sell from `sender` was 24h ago or more
        /// Or an address has never sold, reset the daily sell counter
        if (block.timestamp - _dailySellOf[sender].latestReset >= 1 days) {
            _dailySellOf[sender].latestReset = block.timestamp;
            /// Now `sender` can sell another {maxDailySell()}
            _dailySellOf[sender].sold = 0;
        }

        /// Max daily sell based on what `sender` has already sold during these
        /// last 24h
        uint256 maxDailySellAmount = maxDailySell() - _dailySellOf[sender].sold;

        // If amount to sell is over daily allowance, cap it daily allowance
        // Else sell given amount
        return amount > maxDailySellAmount ? maxDailySellAmount : amount;
    }

    /**
     * @notice Function for better UX, only external.
     * @dev Calculates how much `account_` can sell right now.
     *
     * @param account_ address of a seller.
     * @return uint256
     *         how many OMNIA the `account_` can sell right now, in Wei.
     */
    function amountAllowedToSell(address account_)
        external
        view
        returns (uint256)
    {
        Sell memory _dailySell = _dailySellOf[account_];

        if (block.timestamp - _dailySell.latestReset >= 1 days) {
            return maxDailySell();
        }
        return (maxDailySell() - _dailySell.sold);
    }

    /**
     * @dev Calculates the current circulating supply.
     *
     *      Circulating supply is the amount of OMNIA held by every addresses
     *      except: 0x..dEaD, address(0), `_vestingContract`, `DX_SALE_LOCK`,
     *              `UNICRYPT_LOCK`, `UNICRYPT_LOCK_FEES` and ALL farming
     *              contracts `_farmingContracts` we have used.
     *
     * @return uint256
     *         current circulating supply, in Wei.
     */
    function calculateCirculatingSupply() public view returns (uint256) {
        IERC20 token = IERC20(address(this));

        uint256 excludedFromCirculation;

        excludedFromCirculation += token.balanceOf(
            0x000000000000000000000000000000000000dEaD
        );
        excludedFromCirculation += token.balanceOf(address(0));
        excludedFromCirculation += token.balanceOf(vestingContract());
        excludedFromCirculation += token.balanceOf(DX_SALE_LOCK);
        excludedFromCirculation += token.balanceOf(UNICRYPT_LOCK);
        excludedFromCirculation += token.balanceOf(UNICRYPT_LOCK_FEES);

        for (uint256 i = 0; i < EnumerableSet.length(_farmingContracts); i++) {
            excludedFromCirculation += token.balanceOf(
                EnumerableSet.at(_farmingContracts, i)
            );
        }

        // Only burnt/inaccessible tokens are excluded from circluating supply
        return token.totalSupply() - excludedFromCirculation;
    }

    /**
     * @return uint256
     *         current daily amount that can be sold by any addresses, in Wei.
     */
    function maxDailySell() public view returns (uint256) {
        return calculateCirculatingSupply() / DAILY_SELL_PERCENTAGE;
    }

    /**
     * @return uint256
     *         cmount sold by `user` during these last 24h, in Wei.
     */
    function dailySellOf(address user) external view returns (Sell memory) {
        return _dailySellOf[user];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./TransferFee.sol";
import "../interfaces/IOMNIA.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 * @dev Manages transfers by defining rewards & liquidity percentages.
 *
 *      Also saves the amount of OMNIA taken used for rewards and used
 *      for liquidity addings.
 */
abstract contract TransferManager is IOMNIA, TransferFee {
    // % of each transaction that will be taken for liquidity addings
    uint8 public constant LIQUIDITY_FEE = 3;
    // % of each transaction that will be taken for rewards
    uint8 public constant REWARD_FEE = 12;

    // total amount of OMNIA taken for rewards, expressed in OMNIA
    uint256 internal _totalFeesPooledForRewards;
    // total amount of OMNIA taken for liquidity addings, expressed in OMNIA
    uint256 public totalFeesPooledForLiquidity;

    /**
     * @return uint256
               total amount of OMNIA taken for rewards 
     */
    function totalFeesPooledForRewards()
        public
        view
        override
        returns (uint256)
    {
        return _totalFeesPooledForRewards;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SwapToBNB.sol";
import "./LiquidityManager.sol";
import "../imported/ERC20Burnable.sol";
import "../transfer/TransferFeeActivation.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 *
 * @dev Adds liquidity to OMNIA-BNB LP, by swapping half of the liquidity fee into BNB and
 *      then call PCSRouter.addLiquidityETH(...).
 */
abstract contract LiquidityAddingsManager is
    LiquidityManager,
    SwapToBNB,
    ERC20Burnable,
    TransferFeeActivation
{
    /**
     * @dev Increase amount of OMNIA allocated to liquidity.
     *
     *      Abort straight after that if the transfer is a liquidity adding.
     *
     *      If total amount allocated to liquidity is equal or higher than the
     *      `liquidityAddingThreshold` AND is selling AND is listed on PCS AND
     *      less than `MAX_BNB_LOCKED` have been added to LP this way, it adds
     *      `totalOmniaToBeAddedToLiquidity` to liquidity.
     *
     * @param sender address sending some OMNIA.
     * @param recipient address receiving some OMNIA from `sender`.
     * @param liquidityFee new amount of OMNIA allocated to liquidity addings.
     */
    function _addLiquidityIfNeeded(
        address sender,
        address recipient,
        uint256 liquidityFee
    ) internal {
        totalOmniaToBeAddedToLiquidity += liquidityFee;

        if (isSwapAddingLiquidity(sender, recipient)) {
            return;
        }

        // Check if it's time to swap some OMNIA to BNB and add liquidity
        if (totalOmniaToBeAddedToLiquidity >= liquidityAddingThreshold) {
            bool isSelling = address(router.pancakeswapV2Pair()) == recipient;
            if (
                isSelling &&
                isListed &&
                totalBNBAddedToLiquidity < MAX_BNB_LOCKED
            ) {
                _swapAndAddLiquidity();
            }
        }
    }

    /**
     * @dev Swaps half of liquidity fee amount to BNB and keep the other half to add liquidity.
     *
     * Emits a {LiquidityAdded} event, when BNB + OMNIA have been added into liquidity.
     * Emits a {LiquidityAddingFailed} event, if adding liquidity failed.
     */
    function _swapAndAddLiquidity() internal {
        // Allow PCS to spend OMNIA from the OMNIA contract itself to swap & add liquidity
        _approve(
            address(this),
            address(router.pancakeswapV2Router()),
            totalOmniaToBeAddedToLiquidity
        );
        // As we need both WBNB & OMNIA, only half of the allocated OMNIA amount for
        // liqudity will be added as OMNIA
        uint256 omniaToBeAddedToLiquidity = totalOmniaToBeAddedToLiquidity / 2;

        // Half of the allocated OMNIA amount for liqudity is swapped to BNB
        (
            uint256 bnbToBeAddedToLiquidity,
            uint256 amountOMNIASwappedToBNB
        ) = _swapOMNIAForBNB(totalOmniaToBeAddedToLiquidity / 2);

        (uint256 reserveBNB, uint256 reserveOMNIA, ) = router
            .pancakeswapV2Pair()
            .getReserves();
        uint256 latestBNBQuote = router.pancakeswapV2Router().quote(
            totalOmniaToBeAddedToLiquidity,
            reserveOMNIA,
            reserveBNB
        );

        // If there is much more BNB to be added as liquidity than really needed we
        // update the amount to be addded with `latestBNBQuote`
        bnbToBeAddedToLiquidity = bnbToBeAddedToLiquidity > latestBNBQuote
            ? latestBNBQuote
            : bnbToBeAddedToLiquidity;

        // Try OMNIA > BNB swap
        try
            router.pancakeswapV2Router().addLiquidityETH{
                value: bnbToBeAddedToLiquidity
            }(
                address(this),
                omniaToBeAddedToLiquidity,
                swapManager.calculateSplippageOn(bnbToBeAddedToLiquidity),
                swapManager.calculateSplippageOn(omniaToBeAddedToLiquidity),
                autoLiquidityWallet,
                block.timestamp + 360
            )
        returns (
            uint256 omniaAddedToLiquidity,
            uint256 bnbAddedToLiquidity,
            uint256
        ) {
            // Substract amount of OMNIA that was swapped to BNB in {SwapToBNB._swapOMNIAForBNB(...)}
            totalOmniaToBeAddedToLiquidity -= amountOMNIASwappedToBNB;
            // Substract how much OMNIA have been exactly added to liquidty
            totalOmniaToBeAddedToLiquidity -= omniaAddedToLiquidity;
            // Keep track of how many BNB were added to liquidity this way
            totalBNBAddedToLiquidity += bnbAddedToLiquidity;

            emit LiquidityAdded(omniaAddedToLiquidity, bnbAddedToLiquidity);
        } catch Error(string memory reason) {
            emit LiquidityAddingFailed(
                reason,
                block.timestamp,
                omniaToBeAddedToLiquidity,
                bnbToBeAddedToLiquidity
            );
            _approve(address(this), address(router.pancakeswapV2Router()), 0);
        }
    }

    /**
     * @return uint256
     *         how many more OMNIA tokens are needed in the contract before
     *         adding liquidity to OMNIA-BNB pool.
     */
    function amountUntilNextLiquidityAdding() external view returns (uint256) {
        uint256 balance = balanceOf(address(this));
        if (balance > liquidityAddingThreshold) {
            // Swap on next relevant transaction
            return 0;
        }

        return liquidityAddingThreshold - balance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../libraries/IsContractLib.sol";
import "../../Rewards/interfaces/IRewards.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 *
 * @dev Variables & setters for external contracts used in OMNIA token
 *      (other than PancakeSwap ones).
 */
abstract contract ExternalContracts is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address internal constant DX_SALE_LOCK =
        0x81E0eF68e103Ee65002d3Cf766240eD1c070334d;
    address internal constant UNICRYPT_LOCK =
        0xeaEd594B5926A7D5FBBC61985390BaAf936a6b8d;
    address internal constant UNICRYPT_LOCK_FEES =
        0xAA3d85aD9D128DFECb55424085754F6dFa643eb1;

    IRewards public rewards;

    EnumerableSet.AddressSet internal _farmingContracts;
    bool public canExcludeFarmingContractFromCirculatingSupply = true;

    address private _vestingContract;

    event FarmingContractExcluded(address newAddr);
    event FarmingContractReincluded(address newAddr);
    event UpdateVestingContract(address oldAddr, address newAddr);

    /**
     * @dev Excludes a farming contract from circulating supply.
     *
     * Requirements:
     * - only the owner can exclude a farming contract
     * - only contracts can be excluded
     * - only if the right of excluding farming contract has not been renounced
     * - only if farming contract `addr` has not already been excluded
     *
     * Emits an {FarmingContractExcluded} event.
     */
    function excludeFarmingContractFromCirculatingSuppy(address addr)
        external
        onlyOwner
    {
        require(
            IsContractLib.isContract(addr) &&
                canExcludeFarmingContractFromCirculatingSupply,
            "Farming: unauthorized"
        );
        require(_farmingContracts.add(addr), "Farming: excluded");

        rewards.excludeContractFromRewards(addr);
        _excludeExternalContractFromFees(addr);

        emit FarmingContractExcluded(addr);
    }

    /**
     * @dev Includes a farming contract in circulating supply again.
     *
     * Requirements:
     * - only the owner can exclude a farming contract
     * - only if the farming contract `addr` is not already included in
     *   circulating supply
     *
     * Emits an {FarmingContractReincluded} event.
     */
    function reincludeFarmingContractInCirculatingSuppy(address addr)
        external
        onlyOwner
    {
        require(_farmingContracts.remove(addr), "Farming: not excluded");
        emit FarmingContractReincluded(addr);
    }

    /**
     * @dev Prevents from excluding any new farming contracts from circulating
     *      supply.
     *
     * Requirements:
     * - only the owner can renounce from excluding new farming contracts
     */
    function renounceExcludingFarmingContract() external onlyOwner {
        canExcludeFarmingContractFromCirculatingSupply = false;
    }

    /**
     * @dev Setter for vesting contract.
     *
     * Emits an {UpdateVestingContract} event.
     */
    function setVestingContract(address addr) external onlyOwner {
        // Event before changes to emit old address
        emit UpdateVestingContract(_vestingContract, addr);

        _vestingContract = addr;

        rewards.excludeContractFromRewards(addr);
        _excludeExternalContractFromFees(addr);
    }

    /**
     * @notice bytes32 can be converted into address using: address(uint160(uint256(addr))).
     * @return bytes32[] memory
     *         all farming contracts addresses.
     */
    function farmingContracts() public view returns (bytes32[] memory) {
        return _farmingContracts._inner._values;
    }

    /**
     * @return address
     *         vesting contract address.
     */
    function vestingContract() public view returns (address) {
        return _vestingContract;
    }

    /**
     * @notice The overriden function uses {TransferFeeExclusionList.setExcludedFromFees(...)}.
     * @dev Excludes vesting and farming contract from fees when they are set.
     */
    function _excludeExternalContractFromFees(address addr) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library IsContractLib {
    /**
     * @notice An addres is a contract if its {extcodesize} is greater than 0.
     *
     * @return bool
     *         on whether `account` is a contract.
     */
    function isContract(address account) external view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Only methods that need to be used in OMNIA contract are present in this interface.
 * @dev Interface to use in OMNIA token contract.
 */
interface IRewards {
    function initialize(
        address routerManager_,
        address swapManager_,
        address omnia_
    ) external;

    function isProcessingAutoClaim() external view returns (bool);

    function updateNextClaimDate(
        address rewardee_,
        uint256 rewardeeBalance_,
        uint256 transferAmount_
    ) external;

    function updateRewardPointsOnTransfer(address sender_, address receiver_)
        external;

    function processAutoClaimIntervalReached() external view returns (bool);

    function autoClaimPaused() external view returns (bool);

    function processAutoClaim(uint256 gas) external;

    function maxBatchRewardsDistributionGAS() external returns (uint256);

    function updateAutoClaimQueue(address user) external;

    function updateEligibleSupplyForRewards(
        address sender_,
        address receiver_,
        uint256 sentAmount_,
        uint256 receivedAmount_
    ) external;

    function excludeContractFromRewards(address account_) external;

    function OMNIA_REFLECTION_WALLET() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./TransferFeeExclusionList.sol";
import "./TransferFeeActivation.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 * @dev Verifies if sender and recipient are subjected to transfer fee.
 */
abstract contract TransferFee is
    TransferFeeExclusionList,
    TransferFeeActivation
{
    // Total fee taken on each transfer: buy, sell & send
    uint8 public constant TOTAL_TRANSACTION_FEE = 15;

    /**
     * @return uint256
     *         - 15: none is excluded from fees
     *         - 0: `sender_` and/or `recipient_` is excluded from fees
     */
    function _calculateFeeRate(address sender_, address recipient_)
        internal
        view
        returns (uint256)
    {
        bool applyFees = _canApplyTransferFee(sender_, recipient_);
        if (applyFees) {
            return TOTAL_TRANSACTION_FEE;
        }

        return 0;
    }

    /**
     * @return applyFees
     *         token has been listed on PCS AND BOTH `sender_` &
     *         `recipient_` are not excluded from fees.
     */
    function _canApplyTransferFee(address sender_, address recipient_)
        internal
        view
        returns (bool applyFees)
    {
        applyFees =
            isListed &&
            !isExcludedFromFees(sender_) &&
            !isExcludedFromFees(recipient_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface to be used inside {Rewards.CumulativeRewardCalculator._calculateOMNIAReward(...)}
 */
interface IOMNIA {
    function totalFeesPooledForRewards() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 * @dev 15% fee iclusion or exclusion.
 */
abstract contract TransferFeeExclusionList is Ownable {
    // List of addresses that are excluded from 15% fee
    EnumerableSet.AddressSet private _addressesExcludedFromFees;

    /**
     * @dev Ex-include `addr` from 15% fee.
     *
     * @param addr address to in-exclude from fee.
     * @param isExcluded true or false.
     *
     * Requirements:
     * - only the owner can call the method
     */
    function setExcludedFromFees(address addr, bool isExcluded)
        public
        onlyOwner
    {
        if (isExcluded) EnumerableSet.add(_addressesExcludedFromFees, addr);

        if (!isExcluded) EnumerableSet.remove(_addressesExcludedFromFees, addr);
    }

    /**
     * @return bool
     *         verifies if `addr` is excluded from 15% fee or not.
     */
    function isExcludedFromFees(address addr) public view returns (bool) {
        return EnumerableSet.contains(_addressesExcludedFromFees, addr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 * @dev Activate PCS listing.
 */
abstract contract TransferFeeActivation is Ownable {
    bool public isListed = false;

    /**
     * @dev Activating PCS listing will activate fees on all transfers
     *      & auto claim process on PCS sells.
     *
     * Requirements:
     * - only the owner can call it
     */
    function activatePcsListing() external onlyOwner {
        isListed = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../Router/interfaces/IRouterManager.sol";
import "../../SwapManager/ISwapManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Abstract contract, part of OMNIA token contract.
 * @dev Swaps OMNIA to BNB.
 */
abstract contract SwapToBNB {
    IRouterManager public router;
    ISwapManager public swapManager;

    event OmniaSwapToBnbFailed(string reason);

    /**
     * @dev Swaps `amountOfOmnia` OMNIA to BNB.
     *
     * @return newBNBamount
     *         total amount of BNB received after swap.
     * @return amountOMNIASwappedToBNB
     *         total amount of OMNIA swapped for BNB.
     *
     * Emits a {OmniaSwapToBnbFailed} event, if the OMNIA > BNB swap failed,
     * containing the reason of the failure.
     */
    function _swapOMNIAForBNB(uint256 omniaAmount_)
        internal
        returns (uint256 newBNBamount, uint256 amountOMNIASwappedToBNB)
    {
        uint256 initialBNBBalance = address(this).balance;

        IERC20 _omnia = IERC20(address(this));
        uint256 initialOMNIABalance = _omnia.balanceOf(address(this));

        (uint256 maxOut, address[] memory path) = swapManager.pathAndMaxOut(
            address(this),
            router.pancakeswapV2Router().WETH(),
            omniaAmount_
        );

        try
            router
                .pancakeswapV2Router()
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    omniaAmount_,
                    swapManager.calculateSplippageOn(maxOut),
                    path,
                    address(this),
                    block.timestamp + 360
                )
        {} catch Error(string memory reason) {
            emit OmniaSwapToBnbFailed(reason);
        }

        // Return the amount of BNB received
        newBNBamount = address(this).balance - initialBNBBalance;
        // Return amount of OMNIA swapped to BNB
        amountOMNIASwappedToBNB =
            initialOMNIABalance -
            _omnia.balanceOf(address(this));
    }

    /**
     * @dev Current transfer is from OMNIA contract itself towards PCS pair.
     *      This means OMNIA contract is swapping OMNIA against BNB to add
     *      liquidity.
     *
     * @return bool
     *         is OMNIA contract swapping OMNIA tokens against another token
     *         or not.
     */
    function isSwapAddingLiquidity(address sender, address recipient)
        public
        view
        returns (bool)
    {
        return
            sender == address(this) &&
            recipient == address(router.pancakeswapV2Pair());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Defines variables & events used in {LiquidityAddingsManager}.
 */
abstract contract LiquidityManager is Ownable {
    // Maximum amount of BNB to add to liquidity. Once attain all reflection fees
    // will be used to reward holders, no more liquidity addings.
    uint256 public constant MAX_BNB_LOCKED = 12000 * 10**18;

    // Amount of OMNIA helded by OMNIA contract that is reserved for liquidity
    // addings
    uint256 public totalOmniaToBeAddedToLiquidity;
    // The total number of BNB added to the pool by the token itself
    uint256 public totalBNBAddedToLiquidity;

    // There should be at least 100 OMNIA in the contract before adding liquidity
    // to the pool
    uint256 public liquidityAddingThreshold = 100 * 10**18;
    // Wallet that receives LP token
    address public autoLiquidityWallet;

    event LiquidityAdded(uint256 tokenAdded, uint256 bnbAdded);
    event LiquidityAddingFailed(
        string reason,
        uint256 time,
        uint256 omniaAmount,
        uint256 bnbAmount
    );

    /**
     * @dev Updatse minimum amount of OMNIA that needs to be in OMNIA contract
     *      itself before adding liquidity to the OMNIA-BNB pool.
     *
     * @param threshold new minimum amount of OMNIA, in Wei, to trigger liquidity
     *                  addings.
     *
     * Requirements:
     * - only the owner can update `liquidityAddingThreshold`
     * - `threshold` must be stricly above 0 and lower than 1,000 OMNIA (in Wei)
     */
    function setLiquidityAddingThreshold(uint256 threshold) external onlyOwner {
        require(
            threshold > 0 && threshold <= 1000 * 10**18,
            "0 <= threshold > 1,000"
        );
        liquidityAddingThreshold = threshold;
    }

    /**
     * @dev Wallet that will receive LP tokens from automatic liquidity addings.
     *
     * @param liquidityWallet new address that will receive LP tokens.
     *
     * Requirements:
     * - only the owner can update `autoLiquidityWallet`
     * - `liquidityWallet` must not be address(0)
     */
    function setAutoLiquidityWallet(address liquidityWallet)
        external
        onlyOwner
    {
        require(liquidityWallet != address(0), "addr(0)");
        autoLiquidityWallet = liquidityWallet;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Permit.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @notice code from OpenZeppelin with our ERC20: internal _balances (instead private)
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20Permit {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IPancakeRouter02.sol";

/**
 * @dev Interface to be used in {BEP20Swap}, {SwapManager} and {SwapToBNB}.
 */
interface IRouterManager {
    function initialize(
        address omnia_,
        address router_,
        address rewards_
    ) external;

    function updateRewardsContract(address rewards_) external;

    /**
     * @dev Given PancakeSwapRouter address will create OMNIA-WBNB LP and
     *      and update `pancakeswapV2Router()` and `pancakeswapV2Router()`
     *      returns.
     *
     *      👉 On updates after deployment 🚨
     *      ⚠⚠ DONT FORGET to EXCLUDE new PAIR AND ROUTER manually ⚠⚠
     *
     * @param routerAddress new address of PancakeSwapRouter to use.
     */
    function setPancakeSwapRouter(address routerAddress) external;

    /**
     * @return IPancakeRouter02
     *         interface of PancakeSWapRouter contract.
     */
    function pancakeswapV2Router() external view returns (IPancakeRouter02);

    /**
     * @return IUniswapV2Pair
     *         interface of OMNIA-BNB LP contract.
     */
    function pancakeswapV2Pair() external view returns (IUniswapV2Pair);

    /**
     * @param sender_ address that sends tokens in a transfer.
     * @param recipient_ address that receives tokens in a transfer.
     *
     * @return bool
     *         is selling or not.
     */
    function isSelling(address sender_, address recipient_)
        external
        view
        returns (bool);

    /**
     * @return bool
     *         is `account_` nor PCS router nor pair.
     */
    function isNotRouterNorPair(address account_) external view returns (bool);

    /**
     * @param sender_ address that sends tokens in a transfer.
     * @param recipient_ address that receives tokens in a transfer.
     *
     * @return bool
     *         is the transfer not sell nor a purchase.
     */
    function isNotSellingAndNotPurchasing(address sender_, address recipient_)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface to be used in {BEP20Swap} and {SwapToBNB}.
 */
interface ISwapManager {
    /**
     * @dev Calculates the exact amount to be received after slippage has been applied.
     *
     * @param amount amount of some token to be swapped
     * @return uint256
     *         amount after slippage has been applied.
     */
    function calculateSplippageOn(uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @notice Swaps OMNIA for BNB, using `_pancakeswapV2Router.WETH()` as `bep20Token_`.
     * @dev Gets the path to swap OMNIA to chosen token & calculates maximum
     *      amount to receive in selected token.
     *
     * @param bep20Token_ coin to swap from OMNIA.
     * @param omniaAmount_ amount of OMNIA to swap into `bep20Token_`.
     *
     * @return maxOut
     *         maximum amount of `bep20Token_` to be received.
     * @return path
     *         path for OMNIA > `bep20Token_` swap.
     *
     */
    function pathAndMaxOut(
        address omnia,
        address bep20Token_,
        uint256 omniaAmount_
    ) external view returns (uint256 maxOut, address[] memory path);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner)
        internal
        virtual
        returns (uint256 current)
    {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @notice _balances has been set as an internal variable & _mint has been updated.
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    /**
     * @dev Made private by Openzeppelin. Internal required for OMNIA as the reflection
     * needed to updates balances to take fees
     */
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /**
     * @notice _beforeTokenTransfer & _afterTokenTransfer have been deleted because we override
     *         these functions later and it creates issue when the OMNIA token is deployed.
     *@dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}