// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IHarvest {
    function setHarvestRewardVault(address _harvestRewardVault) external;

    function setHarvestRewardPool(address _harvestRewardPool) external;

    function setHarvestPoolToken(address _harvestfToken) external;

    function setFarmToken(address _farmToken) external;

    function updateReward() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IHarvestVault {
    function deposit(uint256 amount) external;

    function withdraw(uint256 numberOfShares) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IMintNoRewardPool {
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function earned(address account) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewards(address account) external view returns (uint256);

    function userRewardPerTokenPaid(address account)
        external
        view
        returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function getReward() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IStrategy {
    function setTreasury(address payable _feeAddress) external;

    function setCap(uint256 _cap) external;

    function setLockTime(uint256 _lockTime) external;

    function setFeeAddress(address payable _feeAddress) external;

    function setFee(uint256 _fee) external;

    function rescueDust() external;

    function rescueAirdroppedTokens(address _token, address to) external;

    function setSushiswapRouter(address _sushiswapRouter) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

// Interface declarations

/* solhint-disable func-order */

interface IUniswapRouter {
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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./base/HarvestSCBase.sol";
import "../base/StrategyBase.sol";

/*
  |Strategy Flow| 
      - User shows up with Token and we deposit it in Havest's Vault. 
      - After this we have fToken that we add in Harvest's Reward Pool which gives FARM as rewards

    - Withdrawal flow does same thing, but backwards
        - User can obtain extra Token when withdrawing. 50% of them goes to the user, 50% goes to the treasury in ETH
        - User can obtain FARM tokens when withdrawing. 50% of them goes to the user in Token, 50% goes to the treasury in ETH 
*/
contract HarvestSC is StrategyBase, HarvestSCBase, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Create a new HarvestDAI contract
     * @param _harvestRewardVault VaultDAI  address
     * @param _harvestRewardPool NoMintRewardPool address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _harvestfToken Pool's underlying token address
     * @param _farmToken Farm address
     * @param _token Token address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function initialize(
        address _harvestRewardVault,
        address _harvestRewardPool,
        address _sushiswapRouter,
        address _harvestfToken,
        address _farmToken,
        address _token,
        address _weth,
        address payable _treasuryAddress,
        address payable _feeAddress
    ) external initializer {
        __ReentrancyGuard_init();
        __HarvestBase_init(
            _harvestRewardVault,
            _harvestRewardPool,
            _sushiswapRouter,
            _harvestfToken,
            _farmToken,
            _token,
            _weth,
            _treasuryAddress,
            _feeAddress,
            5000000 * (10**18)
        );
    }

    /**
     * @notice Deposit to this strategy for rewards
     * @param tokenAmount Amount of Token investment
     * @param deadline Number of blocks until transaction expires
     * @return Amount of fToken
     */
    function deposit(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 slippage
    ) public nonReentrant returns (uint256) {
        // -----
        // validate
        // -----
        _validateDeposit(deadline, tokenAmount, totalToken, slippage);

        _updateRewards(msg.sender);

        IERC20(token).safeTransferFrom(msg.sender, address(this), tokenAmount);

        DepositData memory results;
        UserInfo storage user = userInfo[msg.sender];

        user.timestamp = block.timestamp;

        totalToken = totalToken.add(tokenAmount);
        user.amountToken = user.amountToken.add(tokenAmount);
        results.obtainedToken = tokenAmount;

        // -----
        // deposit Token into harvest and get fToken
        // -----
        results.obtainedfToken = _depositTokenToHarvestVault(
            results.obtainedToken
        );

        // -----
        // stake fToken into the NoMintRewardPool
        // -----
        _stakefTokenToHarvestPool(results.obtainedfToken);
        user.amountfToken = user.amountfToken.add(results.obtainedfToken);

        // -----
        // mint parachain tokens
        // -----
        _mintParachainAuctionTokens(results.obtainedfToken);

        emit Deposit(
            msg.sender,
            tx.origin,
            results.obtainedToken,
            results.obtainedfToken
        );

        user.underlyingRatio = _getRatio(
            user.amountfToken,
            user.amountToken,
            18
        );

        return results.obtainedfToken;
    }

    /**
     * @notice Withdraw tokens and claim rewards
     * @param deadline Number of blocks until transaction expires
     * @return Amount of ETH obtained
     */
    function withdraw(
        uint256 amount,
        uint256 deadline,
        uint256 slippage,
        uint256 ethPerToken,
        uint256 ethPerFarm,
        uint256 tokensPerEth //no of tokens per 1 eth
    ) public nonReentrant returns (uint256) {
        // -----
        // validation
        // -----
        UserInfo storage user = userInfo[msg.sender];
        uint256 receiptBalance = receiptToken.balanceOf(msg.sender);

        _validateWithdraw(
            deadline,
            amount,
            user.amountfToken,
            receiptBalance,
            user.timestamp,
            slippage
        );

        _updateRewards(msg.sender);

        WithdrawData memory results;
        results.initialAmountfToken = user.amountfToken;
        results.prevDustEthBalance = address(this).balance;

        // -----
        // withdraw from HarvestRewardPool (get fToken back)
        // -----
        results.obtainedfToken = _unstakefTokenFromHarvestPool(amount);

        // -----
        // get rewards
        // -----
        harvestRewardPool.getReward(); //transfers FARM to this contract

        // -----
        // calculate rewards and do the accounting for fTokens
        // -----
        uint256 transferableRewards =
            _calculateRewards(msg.sender, amount, results.initialAmountfToken);

        (user.amountfToken, results.burnAmount) = _calculatefTokenRemainings(
            amount,
            results.initialAmountfToken
        );
        _burnParachainAuctionTokens(results.burnAmount);

        // -----
        // withdraw from HarvestRewardVault (return fToken and get Token back)
        // -----
        results.obtainedToken = _withdrawTokenFromHarvestVault(
            results.obtainedfToken
        );
        emit ObtainedInfo(
            msg.sender,
            results.obtainedToken,
            results.obtainedfToken
        );

        // -----
        // calculate feeable tokens (extra Token obtained by returning fToken)
        //              - feeableToken/2 (goes to the treasury in ETH)
        //              - results.totalToken = obtainedToken + 1/2*feeableToken (goes to the user)
        // -----
        results.auctionedToken = 0;
        (results.feeableToken, results.earnedTokens) = _calculateFeeableTokens(
            results.initialAmountfToken,
            results.obtainedToken,
            user.amountToken,
            results.obtainedfToken,
            user.underlyingRatio
        );
        user.earnedTokens = user.earnedTokens.add(results.earnedTokens);

        results.calculatedTokenAmount = (amount.mul(10**18)).div(
            user.underlyingRatio
        );
        if (user.amountfToken == 0) {
            user.amountToken = 0;
        } else {
            if (results.calculatedTokenAmount <= user.amountToken) {
                user.amountToken = user.amountToken.sub(
                    results.calculatedTokenAmount
                );
            } else {
                user.amountToken = 0;
            }
        }
        results.obtainedToken = results.obtainedToken.sub(results.feeableToken);

        if (results.feeableToken > 0) {
            //min
            results.auctionedToken = results.feeableToken.div(2);
            results.feeableToken = results.feeableToken.sub(
                results.auctionedToken
            );
        }
        results.totalToken = results.obtainedToken.add(results.feeableToken);
        // -----
        // swap auctioned Token to ETH
        // -----
        address[] memory swapPath = new address[](2);
        swapPath[0] = token;
        swapPath[1] = weth;

        if (results.auctionedToken > 0) {
            uint256 swapAuctionedTokenResult =
                _swapTokenToEth(
                    swapPath,
                    results.auctionedToken,
                    deadline,
                    slippage,
                    ethPerToken
                );
            results.auctionedEth = results.auctionedEth.add(
                swapAuctionedTokenResult
            );

            emit ExtraTokensExchanged(
                msg.sender,
                results.auctionedToken,
                swapAuctionedTokenResult
            );
        }

        // -----
        // check & swap FARM rewards with ETH (50% for treasury) and with Token by going through ETH first (the other 50% for user)
        // -----

        if (transferableRewards > 0) {
            emit RewardsEarned(msg.sender, transferableRewards);
            user.earnedRewards = user.earnedRewards.add(transferableRewards);

            swapPath[0] = farmToken;

            results.rewardsInEth = _swapTokenToEth(
                swapPath,
                transferableRewards,
                deadline,
                slippage,
                ethPerFarm
            );
            results.auctionedRewardsInEth = results.rewardsInEth.div(2);
            //50% goes to treasury in ETH
            results.userRewardsInEth = results.rewardsInEth.sub(
                results.auctionedRewardsInEth
            );
            //50% goes to user in Token (swapped below)

            results.auctionedEth = results.auctionedEth.add(
                results.auctionedRewardsInEth
            );
            emit RewardsExchanged(
                msg.sender,
                "ETH",
                transferableRewards,
                results.rewardsInEth
            );
        }
        if (results.userRewardsInEth > 0) {
            swapPath[0] = weth;
            swapPath[1] = token;

            uint256 userRewardsEthToTokenResult =
                _swapEthToToken(
                    swapPath,
                    results.userRewardsInEth,
                    deadline,
                    slippage,
                    tokensPerEth
                );
            results.totalToken = results.totalToken.add(
                userRewardsEthToTokenResult
            );

            emit RewardsExchanged(
                msg.sender,
                "Token",
                transferableRewards.div(2),
                userRewardsEthToTokenResult
            );
        }
        user.rewards = user.rewards.sub(transferableRewards);

        // -----
        // final accounting
        // -----
        if (results.calculatedTokenAmount <= totalToken) {
            totalToken = totalToken.sub(results.calculatedTokenAmount);
        } else {
            totalToken = 0;
        }

        user.underlyingRatio = _getRatio(
            user.amountfToken,
            user.amountToken,
            18
        );

        // -----
        // transfer Token to user, ETH to fee address and ETH to the treasury address
        // -----
        if (fee > 0) {
            uint256 feeToken = _calculateFee(results.totalToken);
            results.totalToken = results.totalToken.sub(feeToken);

            swapPath[0] = token;
            swapPath[1] = weth;

            uint256 feeTokenInEth =
                _swapTokenToEth(
                    swapPath,
                    feeToken,
                    deadline,
                    slippage,
                    ethPerToken
                );

            safeTransferETH(feeAddress, feeTokenInEth);
            user.userCollectedFees = user.userCollectedFees.add(feeTokenInEth);
        }

        IERC20(token).safeTransfer(msg.sender, results.totalToken);

        safeTransferETH(treasuryAddress, results.auctionedEth);
        user.userTreasuryEth = user.userTreasuryEth.add(results.auctionedEth);

        emit Withdraw(
            msg.sender,
            tx.origin,
            results.obtainedToken,
            results.obtainedfToken,
            results.auctionedEth
        );

        // -----
        // dust check
        // -----
        if (address(this).balance > results.prevDustEthBalance) {
            ethDust = ethDust.add(
                address(this).balance.sub(results.prevDustEthBalance)
            );
        }

        return results.totalToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../../../interfaces/IUniswapRouter.sol";
import "../../../interfaces/IHarvestVault.sol";
import "../../../interfaces/IMintNoRewardPool.sol";

import "../../../interfaces/IHarvest.sol";
import "../../../interfaces/IStrategy.sol";

import "../../base/StrategyBase.sol";
import "./HarvestStorage.sol";

contract HarvestBase is
    HarvestStorage,
    OwnableUpgradeable,
    StrategyBase,
    IHarvest,
    IStrategy
{
    using SafeMath for uint256;

    struct UserDeposits {
        uint256 timestamp;
        uint256 amountfToken;
    }
    /// @notice Used internally for avoiding "stack-too-deep" error when depositing
    struct DepositData {
        address[] swapPath;
        uint256[] swapAmounts;
        uint256 obtainedToken;
        uint256 obtainedfToken;
        uint256 prevfTokenBalance;
    }

    /// @notice Used internally for avoiding "stack-too-deep" error when withdrawing
    struct WithdrawData {
        uint256 prevDustEthBalance;
        uint256 prevfTokenBalance;
        uint256 prevTokenBalance;
        uint256 obtainedfToken;
        uint256 obtainedToken;
        uint256 feeableToken;
        uint256 feeableEth;
        uint256 totalEth;
        uint256 totalToken;
        uint256 auctionedEth;
        uint256 auctionedToken;
        uint256 rewards;
        uint256 farmBalance;
        uint256 burnAmount;
        uint256 earnedTokens;
        uint256 rewardsInEth;
        uint256 auctionedRewardsInEth;
        uint256 userRewardsInEth;
        uint256 initialAmountfToken;
        uint256 calculatedTokenAmount;
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Events -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    event ExtraTokensExchanged(
        address indexed user,
        uint256 tokensAmount,
        uint256 obtainedEth
    );
    event ObtainedInfo(
        address indexed user,
        uint256 underlying,
        uint256 underlyingReceipt
    );

    event RewardsEarned(address indexed user, uint256 amount);
    event ExtraTokens(address indexed user, uint256 amount);

    /// @notice Event emitted when owner makes a rescue dust request
    event RescuedDust(string indexed dustType, uint256 amount);

    /// @notice Event emitted when owner changes any contract address
    event ChangedAddress(
        string indexed addressType,
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice Event emitted when owner changes any contract address
    event ChangedValue(
        string indexed valueType,
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    /**
     * @notice Create a new HarvestDAI contract
     * @param _harvestRewardVault VaultToken  address
     * @param _harvestRewardPool NoMintRewardPool address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _harvestfToken Pool's underlying token address
     * @param _farmToken Farm address
     * @param _token Token address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function __HarvestBase_init(
        address _harvestRewardVault,
        address _harvestRewardPool,
        address _sushiswapRouter,
        address _harvestfToken,
        address _farmToken,
        address _token,
        address _weth,
        address payable _treasuryAddress,
        address payable _feeAddress,
        uint256 _cap
    ) internal initializer {
        require(_harvestRewardVault != address(0), "VAULT_0x0");
        require(_harvestRewardPool != address(0), "POOL_0x0");
        require(_harvestfToken != address(0), "fTOKEN_0x0");
        require(_farmToken != address(0), "FARM_0x0");

        __Ownable_init();

        __StrategyBase_init(
            _sushiswapRouter,
            _token,
            _weth,
            _treasuryAddress,
            _feeAddress,
            _cap
        );
        harvestRewardVault = IHarvestVault(_harvestRewardVault);
        harvestRewardPool = IMintNoRewardPool(_harvestRewardPool);
        harvestfToken = _harvestfToken;
        farmToken = _farmToken;
        receiptToken = new ReceiptToken(token, address(this));
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Setters -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /**
     * @notice Update the address of VaultDAI
     * @dev Can only be called by the owner
     * @param _harvestRewardVault Address of VaultDAI
     */
    function setHarvestRewardVault(address _harvestRewardVault)
        external
        override
        onlyOwner
    {
        require(_harvestRewardVault != address(0), "VAULT_0x0");
        emit ChangedAddress(
            "VAULT",
            address(harvestRewardVault),
            _harvestRewardVault
        );
        harvestRewardVault = IHarvestVault(_harvestRewardVault);
    }

    /**
     * @notice Update the address of NoMintRewardPool
     * @dev Can only be called by the owner
     * @param _harvestRewardPool Address of NoMintRewardPool
     */
    function setHarvestRewardPool(address _harvestRewardPool)
        external
        override
        onlyOwner
    {
        require(_harvestRewardPool != address(0), "POOL_0x0");
        emit ChangedAddress(
            "POOL",
            address(harvestRewardPool),
            _harvestRewardPool
        );
        harvestRewardPool = IMintNoRewardPool(_harvestRewardPool);
    }

    /**
     * @notice Update the address of Sushiswap Router
     * @dev Can only be called by the owner
     * @param _sushiswapRouter Address of Sushiswap Router
     */
    function setSushiswapRouter(address _sushiswapRouter)
        external
        override
        onlyOwner
    {
        require(_sushiswapRouter != address(0), "0x0");
        emit ChangedAddress(
            "SUSHISWAP_ROUTER",
            address(sushiswapRouter),
            _sushiswapRouter
        );
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
    }

    /**
     * @notice Update the address of Pool's underlying token
     * @dev Can only be called by the owner
     * @param _harvestfToken Address of Pool's underlying token
     */
    function setHarvestPoolToken(address _harvestfToken)
        external
        override
        onlyOwner
    {
        require(_harvestfToken != address(0), "TOKEN_0x0");
        emit ChangedAddress("TOKEN", harvestfToken, _harvestfToken);
        harvestfToken = _harvestfToken;
    }

    /**
     * @notice Update the address of FARM
     * @dev Can only be called by the owner
     * @param _farmToken Address of FARM
     */
    function setFarmToken(address _farmToken) external override onlyOwner {
        require(_farmToken != address(0), "FARM_0x0");
        emit ChangedAddress("FARM", farmToken, _farmToken);
        farmToken = _farmToken;
    }

    /**
     * @notice Update the address for fees
     * @dev Can only be called by the owner
     * @param _feeAddress Fee's address
     */
    function setTreasury(address payable _feeAddress)
        external
        override
        onlyOwner
    {
        require(_feeAddress != address(0), "0x0");
        emit ChangedAddress(
            "TREASURY",
            address(treasuryAddress),
            address(_feeAddress)
        );
        treasuryAddress = _feeAddress;
    }

    /**
     * @notice Set max ETH cap for this strategy
     * @dev Can only be called by the owner
     * @param _cap ETH amount
     */
    function setCap(uint256 _cap) external override onlyOwner {
        emit ChangedValue("CAP", cap, _cap);
        cap = _cap;
    }

    /**
     * @notice Set lock time
     * @dev Can only be called by the owner
     * @param _lockTime lock time in seconds
     */
    function setLockTime(uint256 _lockTime) external override onlyOwner {
        require(_lockTime > 0, "TIME_0");
        emit ChangedValue("LOCKTIME", lockTime, _lockTime);
        lockTime = _lockTime;
    }

    function setFeeAddress(address payable _feeAddress)
        external
        override
        onlyOwner
    {
        emit ChangedAddress("FEE", address(feeAddress), address(_feeAddress));
        feeAddress = _feeAddress;
    }

    function setFee(uint256 _fee) external override onlyOwner {
        require(_fee <= uint256(9000), "FEE_TOO_HIGH");
        emit ChangedValue("FEE", fee, _fee);
    }

    /**
     * @notice Rescue dust resulted from swaps/liquidity
     * @dev Can only be called by the owner
     */
    function rescueDust() external override onlyOwner {
        if (ethDust > 0) {
            safeTransferETH(treasuryAddress, ethDust);
            treasueryEthDust = treasueryEthDust.add(ethDust);
            emit RescuedDust("ETH", ethDust);
            ethDust = 0;
        }
    }

    /**
     * @notice Rescue any non-reward token that was airdropped to this contract
     * @dev Can only be called by the owner
     */
    function rescueAirdroppedTokens(address _token, address to)
        external
        override
        onlyOwner
    {
        require(_token != farmToken, "rescue_reward_error");

        uint256 balanceOfToken = IERC20(_token).balanceOf(address(this));
        require(balanceOfToken > 0, "balance_0");

        require(IERC20(_token).transfer(to, balanceOfToken), "rescue_failed");
    }

    /// @notice Transfer rewards to this strategy
    function updateReward() external override onlyOwner {
        harvestRewardPool.getReward();
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ View methods -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /**
     * @notice Check if user can withdraw based on current lock time
     * @param user Address of the user
     * @return true or false
     */
    function isWithdrawalAvailable(address user) public view returns (bool) {
        if (lockTime > 0) {
            return userInfo[user].timestamp.add(lockTime) <= block.timestamp;
        }
        return true;
    }

    /**
     * @notice View function to see pending rewards for account.
     * @param account user account to check
     * @return pending rewards
     */
    function getPendingRewards(address account) public view returns (uint256) {
        if (account != address(0)) {
            if (userInfo[account].amountfToken == 0) {
                return 0;
            }
            return
                _earned(
                    userInfo[account].amountfToken,
                    userInfo[account].userRewardPerTokenPaid,
                    userInfo[account].rewards
                );
        }
        return 0;
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Internal methods -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    function _calculateRewards(
        address account,
        uint256 amount,
        uint256 amountfToken
    ) internal view returns (uint256) {
        uint256 rewards = userInfo[account].rewards;
        uint256 farmBalance = IERC20(farmToken).balanceOf(address(this));

        if (amount == 0) {
            if (rewards < farmBalance) {
                return rewards;
            }
            return farmBalance;
        }

        return (amount.mul(rewards)).div(amountfToken);
    }

    function _updateRewards(address account) internal {
        if (account != address(0)) {
            UserInfo storage user = userInfo[account];

            uint256 _stored = harvestRewardPool.rewardPerToken();

            user.rewards = _earned(
                user.amountfToken,
                user.userRewardPerTokenPaid,
                user.rewards
            );
            user.userRewardPerTokenPaid = _stored;
        }
    }

    function _earned(
        uint256 _amountfToken,
        uint256 _userRewardPerTokenPaid,
        uint256 _rewards
    ) internal view returns (uint256) {
        return
            _amountfToken
                .mul(
                harvestRewardPool.rewardPerToken().sub(_userRewardPerTokenPaid)
            )
                .div(1e18)
                .add(_rewards);
    }

    function _validateWithdraw(
        uint256 deadline,
        uint256 amount,
        uint256 amountfToken,
        uint256 receiptBalance,
        uint256 timestamp,
        uint256 slippage
    ) internal view {
        _validateCommon(deadline, amount, slippage);

        require(amountfToken >= amount, "AMOUNT_GREATER_THAN_BALANCE");

        require(receiptBalance >= amountfToken, "RECEIPT_AMOUNT");

        if (lockTime > 0) {
            require(timestamp.add(lockTime) <= block.timestamp, "LOCK_TIME");
        }
    }

    function _depositTokenToHarvestVault(uint256 amount)
        internal
        returns (uint256)
    {
        _increaseAllowance(token, address(harvestRewardVault), amount);

        uint256 prevfTokenBalance = _getBalance(harvestfToken);
        harvestRewardVault.deposit(amount);
        uint256 currentfTokenBalance = _getBalance(harvestfToken);

        require(
            currentfTokenBalance > prevfTokenBalance,
            "DEPOSIT_VAULT_ERROR"
        );

        return currentfTokenBalance.sub(prevfTokenBalance);
    }

    function _withdrawTokenFromHarvestVault(uint256 amount)
        internal
        returns (uint256)
    {
        _increaseAllowance(harvestfToken, address(harvestRewardVault), amount);

        uint256 prevTokenBalance = _getBalance(token);
        harvestRewardVault.withdraw(amount);
        uint256 currentTokenBalance = _getBalance(token);

        require(currentTokenBalance > prevTokenBalance, "WITHDRAW_VAULT_ERROR");

        return currentTokenBalance.sub(prevTokenBalance);
    }

    function _stakefTokenToHarvestPool(uint256 amount) internal {
        _increaseAllowance(harvestfToken, address(harvestRewardPool), amount);
        harvestRewardPool.stake(amount);
    }

    function _unstakefTokenFromHarvestPool(uint256 amount)
        internal
        returns (uint256)
    {
        _increaseAllowance(harvestfToken, address(harvestRewardPool), amount);

        uint256 prevfTokenBalance = _getBalance(harvestfToken);
        harvestRewardPool.withdraw(amount);
        uint256 currentfTokenBalance = _getBalance(harvestfToken);

        require(
            currentfTokenBalance > prevfTokenBalance,
            "WITHDRAW_POOL_ERROR"
        );

        return currentfTokenBalance.sub(prevfTokenBalance);
    }

    function _calculatefTokenRemainings(uint256 amount, uint256 amountfToken)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 burnAmount = amount;
        if (amount < amountfToken) {
            amountfToken = amountfToken.sub(amount);
        } else {
            burnAmount = amountfToken;
            amountfToken = 0;
        }

        return (amountfToken, burnAmount);
    }

    function _calculateFeeableTokens(
        uint256 amountfToken,
        uint256 obtainedToken,
        uint256 amountToken,
        uint256 obtainedfToken,
        uint256 underlyingRatio
    ) internal returns (uint256 feeableToken, uint256 earnedTokens) {
        if (obtainedfToken == amountfToken) {
            //there is no point to do the ratio math as we can just get the difference between current obtained tokens and initial obtained tokens
            if (obtainedToken > amountToken) {
                feeableToken = obtainedToken.sub(amountToken);
            }
        } else {
            uint256 currentRatio = _getRatio(obtainedfToken, obtainedToken, 18);

            if (currentRatio < underlyingRatio) {
                uint256 noOfOriginalTokensForCurrentAmount =
                    (obtainedfToken.mul(10**18)).div(underlyingRatio);
                if (noOfOriginalTokensForCurrentAmount < obtainedToken) {
                    feeableToken = obtainedToken.sub(
                        noOfOriginalTokensForCurrentAmount
                    );
                }
            }
        }

        if (feeableToken > 0) {
            uint256 extraTokensFee = _calculateFee(feeableToken);
            emit ExtraTokens(msg.sender, feeableToken.sub(extraTokensFee));
            earnedTokens = feeableToken.sub(extraTokensFee);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./HarvestBase.sol";

contract HarvestSCBase is StrategyBase, HarvestBase {

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Events -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    /// @notice Event emitted when rewards are exchanged to ETH or to a specific Token
    event RewardsExchanged(
        address indexed user,
        string exchangeType, //ETH or Token
        uint256 rewardsAmount,
        uint256 obtainedAmount
    );

    /// @notice Event emitted when user makes a deposit
    event Deposit(
        address indexed user,
        address indexed origin,
        uint256 amountToken,
        uint256 amountfToken
    );

    /// @notice Event emitted when user withdraws
    event Withdraw(
        address indexed user,
        address indexed origin,
        uint256 amountToken,
        uint256 amountfToken,
        uint256 treasuryAmountEth
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "../../../interfaces/IMintNoRewardPool.sol";
import "../../../interfaces/IHarvestVault.sol";

contract HarvestStorage {
    /// @notice Info of each user.
    struct UserInfo {
        uint256 amountEth; //how much ETH the user entered with; should be 0 for HarvestSC
        uint256 amountToken; //how much Token was obtained by swapping user's ETH
        uint256 amountfToken; //how much fToken was obtained after deposit to vault
        uint256 underlyingRatio; //ratio between obtained fToken and token
        uint256 userTreasuryEth; //how much eth the user sent to treasury
        uint256 userCollectedFees; //how much eth the user sent to fee address
        uint256 timestamp; //first deposit timestamp; used for withdrawal lock time check
        uint256 earnedTokens;
        uint256 earnedRewards; //before fees
        //----
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }

    uint256 public totalToken;
    address public farmToken;
    address public harvestfToken;
    uint256 public ethDust;
    uint256 public treasueryEthDust;
    IMintNoRewardPool public harvestRewardPool;
    IHarvestVault public harvestRewardVault;
    mapping(address => UserInfo) public userInfo;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../tokens/ReceiptToken.sol";
import "../../interfaces/IUniswapRouter.sol";

contract Storage{
    address public weth;
    address payable public treasuryAddress;
    address payable public feeAddress;
    address public token;
    IUniswapRouter public sushiswapRouter;
    ReceiptToken public receiptToken;

    uint256 internal _minSlippage;
    uint256 public lockTime;
    uint256 public fee;
    uint256 constant feeFactor = uint256(10000);
    uint256 public cap;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../tokens/ReceiptToken.sol";
import "../../interfaces/IUniswapRouter.sol";
import "./Storage.sol";

contract StrategyBase is Storage, Initializable, UUPSUpgradeable, OwnableUpgradeable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    /// @notice Event emitted when user makes a deposit and receipt token is minted
    event ReceiptMinted(address indexed user, uint256 amount);
    /// @notice Event emitted when user withdraws and receipt token is burned
    event ReceiptBurned(address indexed user, uint256 amount);

    /**
     * @notice Create a new strategy contract
     * @param _sushiswapRouter Sushiswap Router address
     * @param _token Token address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function __StrategyBase_init(
      address _sushiswapRouter, address _token,
      address _weth,
      address payable _treasuryAddress,
      address payable _feeAddress,
      uint256 _cap) internal initializer {
        require(_sushiswapRouter != address(0), "ROUTER_0x0");
        require(_token != address(0), "TOKEN_0x0");
        require(_weth != address(0), "WETH_0x0");
        require(_treasuryAddress != address(0), "TREASURY_0x0");
        require(_feeAddress != address(0), "FEE_0x0");
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
        token = _token;
        weth = _weth;
        treasuryAddress = _treasuryAddress;
        feeAddress = _feeAddress;
        cap = _cap;
        _minSlippage = 10; //0.1%
        lockTime = 1;
        fee = uint256(100);
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {

    }


    function _validateCommon(
        uint256 deadline,
        uint256 amount,
        uint256 _slippage
    ) internal view {
        require(deadline >= block.timestamp, "DEADLINE_ERROR");
        require(amount > 0, "AMOUNT_0");
        require(_slippage >= _minSlippage, "SLIPPAGE_ERROR");
        require(_slippage <= feeFactor, "MAX_SLIPPAGE_ERROR");
    }

    function _validateDeposit(
        uint256 deadline,
        uint256 amount,
        uint256 total,
        uint256 slippage
    ) internal view {
        _validateCommon(deadline, amount, slippage);

        require(total.add(amount) <= cap, "CAP_REACHED");
    }

    function _mintParachainAuctionTokens(uint256 _amount) internal {
        receiptToken.mint(msg.sender, _amount);
        emit ReceiptMinted(msg.sender, _amount);
    }

    function _burnParachainAuctionTokens(uint256 _amount) internal {
        receiptToken.burn(msg.sender, _amount);
        emit ReceiptBurned(msg.sender, _amount);
    }

    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        return _calculatePortion(_amount, fee);
    }

    function _getBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function _increaseAllowance(
        address _token,
        address _contract,
        uint256 _amount
    ) internal {
        IERC20(_token).safeIncreaseAllowance(address(_contract), _amount);
    }

    function _getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function _swapTokenToEth(
        address[] memory swapPath,
        uint256 exchangeAmount,
        uint256 deadline,
        uint256 slippage,
        uint256 ethPerToken
    ) internal returns (uint256) {
        uint256[] memory amounts =
            sushiswapRouter.getAmountsOut(exchangeAmount, swapPath);
        uint256 sushiAmount = amounts[amounts.length - 1]; //amount of ETH
        uint256 portion = _calculatePortion(sushiAmount, slippage);
        uint256 calculatedPrice = (exchangeAmount.mul(ethPerToken)).div(10**18);
        uint256 decimals = ERC20(swapPath[0]).decimals();
        if (decimals < 18) {
            calculatedPrice = calculatedPrice.mul(10**(18 - decimals));
        }
        if (sushiAmount > calculatedPrice) {
            require(
                sushiAmount.sub(calculatedPrice) <= portion,
                "PRICE_ERROR_1"
            );
        } else {
            require(
                calculatedPrice.sub(sushiAmount) <= portion,
                "PRICE_ERROR_2"
            );
        }

        _increaseAllowance(
            swapPath[0],
            address(sushiswapRouter),
            exchangeAmount
        );
        uint256[] memory tokenSwapAmounts =
            sushiswapRouter.swapExactTokensForETH(
                exchangeAmount,
                _getMinAmount(sushiAmount, slippage),
                swapPath,
                address(this),
                deadline
            );
        return tokenSwapAmounts[tokenSwapAmounts.length - 1];
    }

    function _swapEthToToken(
        address[] memory swapPath,
        uint256 exchangeAmount,
        uint256 deadline,
        uint256 slippage,
        uint256 tokensPerEth
    ) internal returns (uint256) {
        uint256[] memory amounts =
            sushiswapRouter.getAmountsOut(exchangeAmount, swapPath);
        uint256 sushiAmount = amounts[amounts.length - 1];
        uint256 portion = _calculatePortion(sushiAmount, slippage);
        uint256 calculatedPrice =
            (exchangeAmount.mul(tokensPerEth)).div(10**18);
        uint256 decimals = ERC20(swapPath[0]).decimals();
        if (decimals < 18) {
            calculatedPrice = calculatedPrice.mul(10**(18 - decimals));
        }
        if (sushiAmount > calculatedPrice) {
            require(
                sushiAmount.sub(calculatedPrice) <= portion,
                "PRICE_ERROR_1"
            );
        } else {
            require(
                calculatedPrice.sub(sushiAmount) <= portion,
                "PRICE_ERROR_2"
            );
        }

        uint256[] memory swapResult =
            sushiswapRouter.swapExactETHForTokens{value: exchangeAmount}(
                _getMinAmount(sushiAmount, slippage),
                swapPath,
                address(this),
                deadline
            );

        return swapResult[swapResult.length - 1];
    }

    function _getMinAmount(uint256 amount, uint256 slippage)
        private
        pure
        returns (uint256)
    {
        uint256 portion = _calculatePortion(amount, slippage);
        return amount.sub(portion);
    }

    function _calculatePortion(uint256 _amount, uint256 _fee)
        private
        pure
        returns (uint256)
    {
        return (_amount.mul(_fee)).div(feeFactor);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This contract is used for printing receipt tokens
// Whenever someone joins a pool, a receipt token will be printed for that person
contract ReceiptToken is ERC20, Ownable {
    ERC20 public underlyingToken;
    address public underlyingStrategy;

    constructor(address underlyingAddress, address strategy)
        ERC20(
            string(abi.encodePacked("pAT-", ERC20(underlyingAddress).name())),
            string(abi.encodePacked("pAT-", ERC20(underlyingAddress).symbol()))
        )
    {
        underlyingToken = ERC20(underlyingAddress);
        underlyingStrategy = strategy;
    }

    /**
     * @notice Mint new receipt tokens to some user
     * @param to Address of the user that gets the receipt tokens
     * @param amount Amount of receipt tokens that will get minted
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burn receipt tokens from some user
     * @param from Address of the user that gets the receipt tokens burne
     * @param amount Amount of receipt tokens that will get burned
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(address newImplementation, bytes memory data, bool forceCall) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature(
                    "upgradeTo(address)",
                    oldImplementation
                )
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _setImplementation(newImplementation);
            emit Upgraded(newImplementation);
        }
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /*
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Base contract for building openzeppelin-upgrades compatible implementations for the {ERC1967Proxy}. It includes
 * publicly available upgrade functions that are called by the plugin and by the secure upgrade mechanism to verify
 * continuation of the upgradability.
 *
 * The {_authorizeUpgrade} function MUST be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

