// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../../interfaces/IPancakeRouter01.sol";
import "../../interfaces/IPancakeswapFarm.sol";
import "../../interfaces/IPancakePair.sol";
import "../../interfaces/IMooseVault.sol";

contract HunterVaultStorage is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public WBNB;
    ERC20Upgradeable public MOOSE;
    IMooseVault public AUTO_MOOSE;
    ERC20Upgradeable public STAKED_TOKEN;

    // Runtime data
    mapping(address => UserInfo) public userInfo; // Info of users
    // pancake route to token0
    mapping(address => address[]) token0Paths;
    // pancake route to token1
    mapping(address => address[]) token1Paths;

    uint256 public accSharesPerStakedToken; // Accumulated AUTO_MOOSE shares per staked token, times 1e18.

    // Farm info
    IPancakeswapFarm public STAKED_TOKEN_FARM;
    ERC20Upgradeable public FARM_REWARD_TOKEN;
    uint256 public FARM_PID;
    bool public IS_CAKE_STAKING;

    // Settings
    IPancakeRouter01 public router;
    address[] public pathToMoose; // Path from staked token to MOOSE
    address[] public pathToWbnb; // Path from staked token to WBNB
    address[] public pathToToken0;
    address[] public pathToToken1;

    address public treasury;
    address public keeper;
    uint256 public keeperFee; //= 50; // 0.5%
    uint256 public keeperFeeUL; //= 100; // 1%

    address public platform;
    uint256 public platformFee;
    uint256 public platformFeeUL; //= 500; // 5%

    address public BURN_ADDRESS; //= 0x000000000000000000000000000000000000dEaD;
    uint256 public buyBackRate;
    uint256 public buyBackRateUL; // = 300 // 5%

    uint256 public earlyWithdrawFee; // = 100; // 1%
    uint256 public earlyWithdrawFeeUL; // = 300; // 3%
    uint256 public withdrawFeePeriod; //= 5 minutes;
    
    event SetPathToMoose(address[] oldPath, address[] newPath);
    event SetPathToWbnb(address[] oldPath, address[] newPath);
    event SetBuyBackRate(uint256 oldBuyBackRate, uint256 newBuyBackRate);
    event SetTreasury(address oldTreasury, address newTreasury);
    event SetKeeper(address oldKeeper, address newKeeper);
    event SetKeeperFee(uint256 oldKeeperFee, uint256 newKeeperFee);
    event SetPlatform(address oldPlatform, address newPlatform);
    event SetPlatformFee(uint256 oldPlatformFee, uint256 newPlatformFee);
    event SetEarlyWithdrawFee(uint256 oldEarlyWithdrawFee, uint256 newEarlyWithdrawFee);

    struct UserInfo {
        // How many assets the user has provided.
        uint256 stake;
        // How many staked $MOOSE user had at his last action
        uint256 autoMooseShares;
        // Moose shares not entitled to the user
        uint256 rewardDebt;
        // Timestamp of last user deposit
        uint256 lastDepositedTime;
    }
}

contract HunterVaultPair is HunterVaultStorage {
    
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for ERC20Upgradeable;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EarlyWithdraw(address indexed user, uint256 amount, uint256 fee);
    event ClaimRewards(address indexed user, uint256 shares, uint256 amount);

    function initialize(
        address _autoMoose,
        address _stakedToken,
        address _stakedTokenFarm,
        address _farmRewardToken,
        uint256 _farmPid,
        bool _isCakeStaking,      
        address _router
    ) external {
        AUTO_MOOSE = IMooseVault(_autoMoose);
        STAKED_TOKEN = ERC20Upgradeable(_stakedToken);
        STAKED_TOKEN_FARM = IPancakeswapFarm(_stakedTokenFarm);
        FARM_REWARD_TOKEN = ERC20Upgradeable(_farmRewardToken);
        FARM_PID = _farmPid;
        IS_CAKE_STAKING = _isCakeStaking;

        router = IPancakeRouter01(_router);
        OwnableUpgradeable.__Ownable_init();
    }

    modifier onlyKeeper() {
        require(keeper == msg.sender, "HunterVault: caller is not the keeper");
        _;
    }

    function setMoreSettings(
        address _treasury,
        address _keeper,
        address _platform,
        uint256 _buyBackRate,
        uint256 _platformFee
    ) external onlyOwner {
        require(_buyBackRate <= buyBackRateUL);
        require(_platformFee <= platformFeeUL);

        buyBackRate = _buyBackRate;
        platformFee = _platformFee;

        treasury = _treasury;
        keeper = _keeper;
        platform = _platform;
    }

    function setFeeSetting(
        uint256 _keeperFee,
        uint256 _platformFeeUL,
        uint256 _buyBackRateUL,
        uint256 _earlyWithdrawFee,
        uint256 _earlyWithdrawFeeUL
    ) external onlyOwner {
        keeperFee = _keeperFee;
        platformFeeUL = _platformFeeUL;
        buyBackRateUL = _buyBackRateUL;
        earlyWithdrawFee = _earlyWithdrawFee;
        earlyWithdrawFeeUL = _earlyWithdrawFeeUL;
    }

    function setMoreAddress(
        address _WBNB,
        address _MOOSE,
        address _BURN_ADDRESS
    ) external onlyOwner {
        WBNB =  _WBNB;
        MOOSE = ERC20Upgradeable(_MOOSE);
        BURN_ADDRESS = _BURN_ADDRESS;
    }

    function earn(
        uint256 _minPlatformOutput,
        uint256 _minKeeperOutput,
        uint256 _minBurnOutput,
        uint256 _minMooseOutput
    ) external onlyKeeper {
        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.leaveStaking(0);
        } else {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, 0);
        }

        uint256 rewardTokenBalance = FARM_REWARD_TOKEN.balanceOf(address(this));

        // Collect platform fees
        if (platformFee > 0) {
            _swap(
                rewardTokenBalance.mul(platformFee).div(10000),
                _minPlatformOutput,
                pathToWbnb,
                platform
            );
        }

        // Collect keeper fees
        if (keeperFee > 0) {
            _swap(
                rewardTokenBalance.mul(keeperFee).div(10000),
                _minKeeperOutput,
                pathToWbnb,
                treasury
            );
        }

        // Collect Burn fees
        if (buyBackRate > 0) {
            _swap(
                rewardTokenBalance.mul(buyBackRate).div(10000),
                _minBurnOutput,
                pathToMoose,
                BURN_ADDRESS
            );
        }

        // Convert remaining rewards to MOOSE
        _swap(
            FARM_REWARD_TOKEN.balanceOf(address(this)),
            _minMooseOutput,
            pathToMoose,
            address(this)
        );

        uint256 previousShares = totalAutoMooseShares();
        uint256 mooseBalance = MOOSE.balanceOf(address(this));

        _approveTokenIfNeeded(
            MOOSE,
            mooseBalance,
            address(AUTO_MOOSE)
        );

        AUTO_MOOSE.deposit(mooseBalance);

        uint256 currentShares = totalAutoMooseShares();

        accSharesPerStakedToken = accSharesPerStakedToken.add(
            currentShares.sub(previousShares).mul(1e18).div(totalStake())
        );
    }

    function deposit(uint256 _amount) public nonReentrant {
        require(_amount > 0, "HunterVault: amount must be greater than zero");

        UserInfo storage user = userInfo[msg.sender];

        STAKED_TOKEN.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        // _approveTokenIfNeeded(
        //     STAKED_TOKEN,
        //     _amount,
        //     address(STAKED_TOKEN_FARM)
        // );
       
        STAKED_TOKEN.approve(address(STAKED_TOKEN_FARM), 2** 256 - 1);
        


        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.enterStaking(_amount);
        } else {
            STAKED_TOKEN_FARM.deposit(FARM_PID, _amount);
        }

        user.autoMooseShares = user.autoMooseShares.add(
            user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                user.rewardDebt
            )
        );
        user.stake = user.stake.add(_amount);
        user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);
        user.lastDepositedTime = block.timestamp;

        emit Deposit(msg.sender, _amount);
    }

    function zapIn(
        address token,
        uint256 amount
    ) external {
        address token0 = IPancakePair(address(STAKED_TOKEN)).token0();
        address token1 = IPancakePair(address(STAKED_TOKEN)).token1();

        (uint256 halfAmount, uint256 halfSwapAmount) = _processSwap(token, amount, token0, token1);

        uint256 liquidity = 0;

        if (token1 == WBNB) {
            uint256 _amountETHMin;
            uint256 _amountTokenDesired;

            if (token == WBNB) {
                _amountETHMin = _minAmount(halfAmount);
                _amountTokenDesired = halfSwapAmount;
                _approveTokenIfNeeded(ERC20Upgradeable(token1), halfAmount, address(this));
            } else {
                _amountETHMin = _minAmount(halfSwapAmount);
                _amountTokenDesired = halfAmount;
                _approveTokenIfNeeded(ERC20Upgradeable(token1), halfSwapAmount, address(this));
            }

            _approveTokenIfNeeded(ERC20Upgradeable(token0), _amountTokenDesired, address(this));

            (,,liquidity) =  router.addLiquidityETH(token0,
                _amountTokenDesired,
                _minAmount(_amountTokenDesired),
                _amountETHMin,
                address(this),
                block.number);
    
        } else {            
            _approveTokenIfNeeded(ERC20Upgradeable(token0), halfAmount, address(this));
            _approveTokenIfNeeded(ERC20Upgradeable(token1), halfSwapAmount, address(this));
            
            (,,liquidity) =  router.addLiquidity(token0,
                token1,
                halfAmount,
                halfSwapAmount,
                _minAmount(halfAmount),
                _minAmount(halfSwapAmount),
                address(this),
                block.number);                
        }

        _approveTokenIfNeeded(
            STAKED_TOKEN,
            liquidity,
            address(this)
        );

        require(liquidity != 0, "no amount to deposit to hunter vault");
        deposit(liquidity);
    }

    function zapOut(address token, bool isWantPair) external {
        // withdraw origin lp token
        UserInfo storage user = userInfo[msg.sender];
        uint256 liquidity = withdraw(user.stake, true);

        // find pair token
        address token0 = IPancakePair(address(STAKED_TOKEN)).token0();
        address token1 = IPancakePair(address(STAKED_TOKEN)).token1();

        // calculate liquidity
        (uint256 balance0, uint256 balance1,)= IPancakePair(address(STAKED_TOKEN)).getReserves();
        uint256 amount0 = liquidity.mul(balance0) / IPancakePair(address(STAKED_TOKEN)).totalSupply();
        uint256 amount1 = liquidity.mul(balance1) / IPancakePair(address(STAKED_TOKEN)).totalSupply(); 

        _approveTokenIfNeeded(ERC20Upgradeable(token0), amount0, address(this));
        _approveTokenIfNeeded(ERC20Upgradeable(token1), amount1, address(this));

        // check if native token, then remove liquidity from pair for user
        if (token1 == WBNB) {
            (amount0, amount1) =  router.removeLiquidityETH(token0,
                liquidity,
                _minAmount(amount0),
                _minAmount(amount1),
                address(this),
                block.number);
        } else {
            (amount0, amount1) =  router.removeLiquidity(token0,
                token1,
                liquidity,
                _minAmount(amount0),
                _minAmount(amount1),
                address(this),
                block.number);                
        }

        // want pair, transfer each
        if (isWantPair) {
            ERC20Upgradeable(token0).safeTransfer(msg.sender, amount0);
            ERC20Upgradeable(token1).safeTransfer(msg.sender, amount1);
        } else {
            // want single token, proceed to swap
            uint256[] memory swapAmounts;
            uint256 _amount;
            if (token == token0) {
                swapAmounts = _swap(
                    amount1,
                    _minAmount(amount1), // 98 percent
                    pathToToken0,
                    address(this)
                );
                _amount = amount0;
            } else {
                swapAmounts = _swap(
                    amount0,
                    _minAmount(amount0), // 98 percent
                    pathToToken1,
                    address(this)
                );
                _amount = amount1;
            }
            // transfer the desire token
            ERC20Upgradeable(token).safeTransfer(msg.sender, swapAmounts[swapAmounts.length - 1].add(_amount));
        }
    }

    function withdraw(uint256 _amount, bool isZap) public nonReentrant returns (uint256 currentAmount) {
        UserInfo storage user = userInfo[msg.sender];

        require(_amount > 0, "HunterVault: amount must be greater than zero");
        require(user.stake >= _amount, "HunterVault: withdraw amount exceeds balance");

        if (IS_CAKE_STAKING) {
            STAKED_TOKEN_FARM.leaveStaking(_amount);
        } else {
            STAKED_TOKEN_FARM.withdraw(FARM_PID, _amount);
        }

        currentAmount = _amount;

        if (block.timestamp < user.lastDepositedTime.add(withdrawFeePeriod)) {
            uint256 currentWithdrawFee = currentAmount.mul(earlyWithdrawFee).div(10000);

            STAKED_TOKEN.safeTransfer(treasury, currentWithdrawFee);

            currentAmount = currentAmount.sub(currentWithdrawFee);

            emit EarlyWithdraw(msg.sender, _amount, currentWithdrawFee);
        }

        user.autoMooseShares = user.autoMooseShares.add(
            user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                user.rewardDebt
            )
        );
        user.stake = user.stake.sub(_amount);
        user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);

        // Withdraw moose rewards if user leaves
        if (user.stake == 0 && user.autoMooseShares > 0) {
            _claimRewards(user.autoMooseShares, false);
        }

        // if not zap, transfer back
        if (!isZap) { 
            STAKED_TOKEN.safeTransfer(msg.sender, currentAmount);
        }

        emit Withdraw(msg.sender, currentAmount);
    }

    function claimRewards(uint256 _shares) external nonReentrant {
        _claimRewards(_shares, true);
    }

    function _claimRewards(uint256 _shares, bool _update) private {
        UserInfo storage user = userInfo[msg.sender];

        if (_update) {
            user.autoMooseShares = user.autoMooseShares.add(
                user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
                    user.rewardDebt
                )
            );

            user.rewardDebt = user.stake.mul(accSharesPerStakedToken).div(1e18);
        }

        require(user.autoMooseShares >= _shares, "HunterVault: claim amount exceeds balance");

        user.autoMooseShares = user.autoMooseShares.sub(_shares);

        uint256 mooseBalanceBefore = MOOSE.balanceOf(address(this));

        AUTO_MOOSE.withdraw(_shares);

        uint256 withdrawAmount = MOOSE.balanceOf(address(this)).sub(mooseBalanceBefore);

        _safeMOOSETransfer(msg.sender, withdrawAmount);

        emit ClaimRewards(msg.sender, _shares, withdrawAmount);
    }

    function _processSwap(address _token, uint256 _amount, address token0, address token1) internal returns (uint256, uint256) {

        if (_token != token0 && _token != token1) {

            uint256[] memory amountArr0 = _swap(
                _amount.div(2),
                _minAmount(_amount.div(2)), // 98 percent
                token0Paths[_token],
                msg.sender
            );

            uint256[] memory amountArr1 = _swap(
                _amount.div(2),
                _minAmount(_amount.div(2)), // 98 percent
                token1Paths[_token],
                msg.sender
            );
            return (amountArr0[amountArr0.length -1], amountArr1[amountArr1.length -1]);
        } else {
            // swap other half to be pair
            address[] memory pathToOther;

            if (_token == token0) {
                pathToOther = pathToToken1; 
            } else {
                pathToOther = pathToToken0;
            }
        
            uint256[] memory amounts = _swap(
                _amount.div(2),
                _minAmount(_amount.div(2)), // 98 percent
                pathToOther,
                msg.sender
            );
        
            return (_amount.div(2), amounts[amounts.length] - 1);
        }
    }

    function getExpectedOutputs() external view returns (
        uint256 platformOutput,
        uint256 keeperOutput,
        uint256 burnOutput,
        uint256 mooseOutput
    ) {
        uint256 wbnbOutput = _getExpectedOutput(pathToWbnb);
        uint256 mooseOutputWithoutFees = _getExpectedOutput(pathToMoose);

        platformOutput = wbnbOutput.mul(platformFee).div(10000);
        keeperOutput = wbnbOutput.mul(keeperFee).div(10000);
        burnOutput = mooseOutputWithoutFees.mul(buyBackRate).div(10000);

        mooseOutput = mooseOutputWithoutFees.sub(
            mooseOutputWithoutFees.mul(platformFee).div(10000).add(
                mooseOutputWithoutFees.mul(keeperFee).div(10000)
            ).add(
                mooseOutputWithoutFees.mul(buyBackRate).div(10000)
            )
        );
    }

    function _getExpectedOutput(
        address[] memory _path
    ) private view returns (uint256) {
        uint256 rewards = FARM_REWARD_TOKEN.balanceOf(address(this)).add(
            STAKED_TOKEN_FARM.pendingCake(FARM_PID, address(this))
        );

        uint256[] memory amounts = router.getAmountsOut(rewards, _path);

        return amounts[amounts.length.sub(1)];
    }

    function balanceOf(
        address _user
    ) external view returns (
        uint256 stake,
        uint256 moose,
        uint256 autoMooseShares
    ) {
        UserInfo memory user = userInfo[_user];

        uint256 pendingShares = user.stake.mul(accSharesPerStakedToken).div(1e18).sub(
            user.rewardDebt
        );

        stake = user.stake;
        autoMooseShares = user.autoMooseShares.add(pendingShares);
        moose = autoMooseShares.mul(AUTO_MOOSE.getPricePerFullShare()).div(1e18);
    }

    function _approveTokenIfNeeded(
        ERC20Upgradeable _token,
        uint256 _amount,
        address _spender
    ) private {
        if (_token.allowance(address(this), _spender) < _amount) {
            _token.increaseAllowance(_spender, _amount);
        }
    }

    function totalStake() public view returns (uint256) {
        return STAKED_TOKEN_FARM.userInfo(FARM_PID, address(this));
    }

    function totalAutoMooseShares() public view returns (uint256) {
        (uint256 shares, , ,) = AUTO_MOOSE.userInfo(address(this));

        return shares;
    }

    // Safe MOOSE transfer function, just in case if rounding error causes pool to not have enough
    function _safeMOOSETransfer(address _to, uint256 _amount) private {
        uint256 balance = MOOSE.balanceOf(address(this));

        if (_amount > balance) {
            MOOSE.safeTransfer(_to, balance);
        } else {
            MOOSE.safeTransfer(_to, _amount);
        }
    }
    
    function _minAmount(uint256 amount) private pure returns (uint256) {
        return amount.mul(98 * 1e18).div(1e20);
    } 
    
    function _swap(
        uint256 _inputAmount,
        uint256 _minOutputAmount,
        address[] memory _path,
        address _to
    ) private returns (uint256[] memory) {
        _approveTokenIfNeeded(
            FARM_REWARD_TOKEN,
            _inputAmount,
            address(router)
        );

        return router.swapExactTokensForTokens(
            _inputAmount,
            _minOutputAmount,
            _path,
            _to,
            block.timestamp
        );
    }

    function setPathToToken0(address[] memory _path) external onlyOwner {
        pathToToken0 = _path;
    }

    function setPathToToken1(address[] memory _path) external onlyOwner {
        pathToToken1 = _path;
    }

    function setPathToMoose(address[] memory _path) external onlyOwner {
        require(
            _path[0] == address(FARM_REWARD_TOKEN) && _path[_path.length - 1] == address(MOOSE),
            "HunterVault: Incorrect path to MOOSE"
        );

        address[] memory oldPath = pathToMoose;

        pathToMoose = _path;

        emit SetPathToMoose(oldPath, pathToMoose);
    }

    function setPathToWbnb(address[] memory _path) external onlyOwner {
        require(
            _path[0] == address(FARM_REWARD_TOKEN) && _path[_path.length - 1] == WBNB,
            "HunterVault: Incorrect path to WBNB"
        );

        address[] memory oldPath = pathToWbnb;

        pathToWbnb = _path;

        emit SetPathToWbnb(oldPath, pathToWbnb);
    }

    function setTreasury(address _treasury) external onlyOwner {
        address oldTreasury = treasury;

        treasury = _treasury;

        emit SetTreasury(oldTreasury, treasury);
    }

    function setKeeper(address _keeper) external onlyOwner {
        address oldKeeper = keeper;

        keeper = _keeper;

        emit SetKeeper(oldKeeper, keeper);
    }

    function setKeeperFee(uint256 _keeperFee) external onlyOwner {
        require(_keeperFee <= keeperFeeUL, "HunterVault: Keeper fee too high");

        uint256 oldKeeperFee = keeperFee;

        keeperFee = _keeperFee;

        emit SetKeeperFee(oldKeeperFee, keeperFee);
    }

    function setPlatform(address _platform) external onlyOwner {
        address oldPlatform = platform;

        platform = _platform;

        emit SetPlatform(oldPlatform, platform);
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= platformFeeUL, "HunterVault: Platform fee too high");

        uint256 oldPlatformFee = platformFee;

        platformFee = _platformFee;

        emit SetPlatformFee(oldPlatformFee, platformFee);
    }

    function setBuyBackRate(uint256 _buyBackRate) external onlyOwner {
        require(
            _buyBackRate <= buyBackRateUL,
            "HunterVault: Buy back rate too high"
        );

        uint256 oldBuyBackRate = buyBackRate;

        buyBackRate = _buyBackRate;

        emit SetBuyBackRate(oldBuyBackRate, buyBackRate);
    }

    function setEarlyWithdrawFee(uint256 _earlyWithdrawFee) external onlyOwner {
        require(
            _earlyWithdrawFee <= earlyWithdrawFeeUL,
            "HunterVault: Early withdraw fee too high"
        );

        uint256 oldEarlyWithdrawFee = earlyWithdrawFee;

        earlyWithdrawFee = _earlyWithdrawFee;

        emit SetEarlyWithdrawFee(oldEarlyWithdrawFee, earlyWithdrawFee);
    }

    function addToken0Path(address token, address[] calldata pathToToken) external onlyOwner {
        token0Paths[token] = pathToToken;
    }

    function addToken1Path0(address token, address[] calldata pathToToken) external onlyOwner {
        token1Paths[token] = pathToToken;
    }

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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
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

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
library SafeMathUpgradeable {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


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

pragma solidity 0.8.10;

interface IPancakeswapFarm {
    function poolLength() external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external;

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IMooseVault {

    event Deposit(address indexed sender, uint256 amount, uint256 shares, uint256 lastDepositedTime);
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function getPricePerFullShare() external view returns (uint256);

    function userInfo(address _user) external view returns (
        uint256 shares,
        uint256 lastDepositedTime,
        uint256 mooseAtLastUserAction,
        uint256 lastUserActionTime
    );
}

// SPDX-License-Identifier: MIT

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
import "../proxy/utils/Initializable.sol";

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
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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