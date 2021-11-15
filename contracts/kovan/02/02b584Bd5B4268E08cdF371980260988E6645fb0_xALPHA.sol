// SPDX-License-Identifier: ISC

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "./BlockLock.sol";

import "./interfaces/IxALPHA.sol";
import "./interfaces/IxTokenManager.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IALPHAStaking.sol";
import "./interfaces/ISushiswapRouter.sol";
import "./interfaces/IUniswapV3SwapRouter.sol";
import "./interfaces/IStakingProxy.sol";

import "./helpers/StakingFactory.sol";

// solhint-disable-next-line contract-name-camelcase
contract xALPHA is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, IxALPHA, BlockLock {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20;

    uint256 private constant LIQUIDATION_TIME_PERIOD = 4 weeks;
    uint256 private constant INITIAL_SUPPLY_MULTIPLIER = 10;
    uint256 private constant BUFFER_TARGET = 20; // 5% target
    uint256 private constant STAKING_PROXIES_AMOUNT = 6;
    uint256 private constant MAX_UINT = 2**256 - 1;
    uint256 private constant TARGET_STAKING_INTERVAL = 48 hours;

    address private constant ETH_ADDRESS = address(0);
    IWETH private weth;
    IERC20 private alphaToken;
    StakingFactory private stakingFactory;
    address private stakingProxyImplementation;

    // The total amount staked across all proxies
    uint256 public totalStakedBalance;

    uint256 public adminActiveTimestamp;
    uint256 public withdrawableAlphaFees;
    uint256 public emergencyUnbondTimestamp;
    uint256 public lastStakeTimestamp;

    IxTokenManager private xTokenManager; // xToken manager contract
    address private uniswapRouter;
    address private sushiswapRouter;
    SwapMode private swapMode;
    FeeDivisors public feeDivisors;
    uint24 public v3AlphaPoolFee;

    function initialize(
        string calldata _symbol,
        IWETH _wethToken,
        IERC20 _alphaToken,
        address _alphaStaking,
        StakingFactory _stakingFactory,
        address _stakingProxyImplementation,
        IxTokenManager _xTokenManager,
        address _uniswapRouter,
        address _sushiswapRouter,
        FeeDivisors calldata _feeDivisors
    ) external override initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("xALPHA", _symbol);

        weth = _wethToken;
        alphaToken = _alphaToken;
        stakingFactory = _stakingFactory;
        stakingProxyImplementation = _stakingProxyImplementation;
        xTokenManager = _xTokenManager;
        uniswapRouter = _uniswapRouter;
        sushiswapRouter = _sushiswapRouter;
        updateSwapRouter(SwapMode.UNISWAP_V3);

        // Approve WETH and ALPHA for both swap routers
        alphaToken.approve(sushiswapRouter, MAX_UINT);
        IERC20(address(weth)).approve(sushiswapRouter, MAX_UINT);

        alphaToken.approve(uniswapRouter, MAX_UINT);
        IERC20(address(weth)).approve(uniswapRouter, MAX_UINT);

        v3AlphaPoolFee = 10000;

        _setFeeDivisors(_feeDivisors.mintFee, _feeDivisors.burnFee, _feeDivisors.claimFee);

        // Initialize the staking proxies
        for (uint256 i = 0; i < STAKING_PROXIES_AMOUNT; ++i) {
            // Deploy the proxy
            stakingFactory.deployProxy(stakingProxyImplementation);

            // Initialize
            IStakingProxy(stakingFactory.stakingProxyProxies(i)).initialize(_alphaStaking);
        }
    }

    /* ========================================================================================= */
    /*                                          User functions                                   */
    /* ========================================================================================= */

    /*
     * @dev Mint xALPHA using ETH
     * @notice Assesses mint fee
     * @param minReturn: Min return to pass to Uniswap trade
     *
     * This function swaps ETH to ALPHA using 1inch.
     */
    function mint(uint256 minReturn) external payable override whenNotPaused notLocked(msg.sender) {
        require(msg.value > 0, "Must send ETH");
        lock(msg.sender);

        // Swap ETH for ALPHA
        uint256 alphaAmount = _swapETHforALPHAInternal(msg.value, minReturn);

        uint256 fee = _calculateFee(alphaAmount, feeDivisors.mintFee);
        _incrementWithdrawableAlphaFees(fee);

        return _mintInternal(alphaAmount.sub(fee));
    }

    /*
     * @dev Mint xALPHA using ALPHA
     * @notice Assesses mint fee
     *
     * @param alphaAmount: ALPHA tokens to contribute
     *
     * The xALPHA contract must be approved to withdraw ALPHA from the
     * sender's wallet.
     */
    function mintWithToken(uint256 alphaAmount) external override whenNotPaused notLocked(msg.sender) {
        require(alphaAmount > 0, "Must send token");
        lock(msg.sender);

        alphaToken.transferFrom(msg.sender, address(this), alphaAmount);

        uint256 fee = _calculateFee(alphaAmount, feeDivisors.mintFee);
        _incrementWithdrawableAlphaFees(fee);

        return _mintInternal(alphaAmount.sub(fee));
    }

    /*
     * @dev Perform mint action
     * @param _incrementalAlpha: ALPHA tokens to contribute
     *
     * No safety checks since internal function. After calculating
     * the mintAmount based on the current liquidity ratio, it mints
     * xALPHA (using ERC20 mint).
     */
    function _mintInternal(uint256 _incrementalAlpha) private {
        uint256 mintAmount = calculateMintAmount(_incrementalAlpha, totalSupply());

        return super._mint(msg.sender, mintAmount);
    }

    /*
     * @dev Calculate mint amount for xALPHA
     *
     * @param _incrementalAlpha: ALPHA tokens to contribute
     * @param totalSupply: total supply of xALPHA tokens to calculate against
     *
     * @return mintAmount: the amount of xALPHA that will be minted
     *
     * Calculate the amount of xALPHA that will be minted for a
     * proportionate amount of ALPHA. In practice, totalSupply will
     * equal the total supply of xALPHA.
     */
    function calculateMintAmount(uint256 incrementalAlpha, uint256 totalSupply)
        public
        view
        override
        returns (uint256 mintAmount)
    {
        if (totalSupply == 0) return incrementalAlpha.mul(INITIAL_SUPPLY_MULTIPLIER);
        uint256 previousNav = getNav().sub(incrementalAlpha);
        mintAmount = incrementalAlpha.mul(totalSupply).div(previousNav);
    }

    /*
     * @dev Burn xALPHA tokens
     * @notice Will fail if pro rata balance exceeds available liquidity
     * @notice Assesses burn fee
     *
     * @param tokenAmount: xALPHA tokens to burn
     * @param redeemForEth: Redeem for ETH or ALPHA
     * @param minReturn: Min return to pass to 1inch trade
     *
     * Burns the sent amount of xALPHA and calculates the proportionate
     * amount of ALPHA. Either sends the ALPHA to the caller or exchanges
     * it for ETH.
     */
    function burn(
        uint256 tokenAmount,
        bool redeemForEth,
        uint256 minReturn
    ) external override notLocked(msg.sender) {
        require(tokenAmount > 0, "Must send xALPHA");
        lock(msg.sender);

        (uint256 stakedBalance, uint256 bufferBalance) = getFundBalances();
        uint256 alphaHoldings = stakedBalance.add(bufferBalance);
        uint256 proRataAlpha = alphaHoldings.mul(tokenAmount).div(totalSupply());

        require(proRataAlpha <= bufferBalance, "Insufficient exit liquidity");
        super._burn(msg.sender, tokenAmount);

        uint256 fee = _calculateFee(proRataAlpha, feeDivisors.burnFee);
        _incrementWithdrawableAlphaFees(fee);

        uint256 withdrawAmount = proRataAlpha.sub(fee);

        if (redeemForEth) {
            uint256 ethAmount = _swapALPHAForETHInternal(withdrawAmount, minReturn);
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{ value: ethAmount }(new bytes(0));
            require(success, "ETH burn transfer failed");
        } else {
            alphaToken.transfer(msg.sender, withdrawAmount);
        }
    }

    /*
     * @inheritdoc ERC20
     */
    function transfer(address recipient, uint256 amount) public override notLocked(msg.sender) returns (bool) {
        return super.transfer(recipient, amount);
    }

    /*
     * @inheritdoc ERC20
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override notLocked(sender) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /*
     * @dev Swap ETH for ALPHA
     * @notice uses either Sushiswap or Uniswap V3 depending on version
     *
     * @param ethAmount: amount of ETH to swap
     * @param minReturn: Min return to pass to Uniswap trade
     *
     * @return amount of ALPHA returned in the swap
     *
     * These swaps always use 'exact input' - they send exactly the amount specified
     * in arguments to the swap, and the output amount is calculated.
     */
    function _swapETHforALPHAInternal(uint256 ethAmount, uint256 minReturn) private returns (uint256) {
        uint256 deadline = MAX_UINT;

        if (swapMode == SwapMode.SUSHISWAP) {
            // SUSHISWAP
            IUniswapV2Router02 routerV2 = IUniswapV2Router02(sushiswapRouter);

            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = address(alphaToken);

            uint256[] memory amounts = routerV2.swapExactETHForTokens{ value: ethAmount }(
                minReturn,
                path,
                address(this),
                deadline
            );

            return amounts[1];
        } else {
            // UNISWAP V3
            IUniswapV3SwapRouter routerV3 = IUniswapV3SwapRouter(uniswapRouter);

            weth.deposit{ value: ethAmount }();

            IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(alphaToken),
                fee: v3AlphaPoolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: ethAmount,
                amountOutMinimum: minReturn,
                sqrtPriceLimitX96: 0
            });

            uint256 amountOut = routerV3.exactInputSingle(params);

            return amountOut;
        }
    }

    /*
     * @dev Swap ALPHA for ETH using Uniswap
     * @notice uses either Sushiswap or Uniswap V3 depending on version
     *
     * @param alphaAmount: amount of ALPHA to swap
     * @param minReturn: Min return to pass to Uniswap trade
     *
     * @return amount of ETH returned in the swap
     *
     * These swaps always use 'exact input' - they send exactly the amount specified
     * in arguments to the swap, and the output amount is calculated. The output ETH
     * is held in the contract.
     */
    function _swapALPHAForETHInternal(uint256 alphaAmount, uint256 minReturn) private returns (uint256) {
        uint256 deadline = MAX_UINT;

        if (swapMode == SwapMode.SUSHISWAP) {
            // SUSHISWAP
            IUniswapV2Router02 routerV2 = IUniswapV2Router02(sushiswapRouter);

            address[] memory path = new address[](2);
            path[0] = address(alphaToken);
            path[1] = address(weth);

            uint256[] memory amounts = routerV2.swapExactTokensForETH(
                alphaAmount,
                minReturn,
                path,
                address(this),
                deadline
            );

            return amounts[1];
        } else {
            // UNISWAP V3
            IUniswapV3SwapRouter routerV3 = IUniswapV3SwapRouter(uniswapRouter);

            IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: address(alphaToken),
                tokenOut: address(weth),
                fee: v3AlphaPoolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: alphaAmount,
                amountOutMinimum: minReturn,
                sqrtPriceLimitX96: 0
            });

            uint256 amountOut = routerV3.exactInputSingle(params);

            // Withdraw WETH
            weth.withdraw(amountOut);

            return amountOut;
        }
    }

    /* ========================================================================================= */
    /*                                            Management                                     */
    /* ========================================================================================= */

    /*
     * @dev Get NAV of the xALPHA contract
     * @notice Combination of staked balance held in staking contract
     *         and unstaked buffer balance held in xALPHA contract. Also
     *         includes stake currently being unbonded (as part of staked balance)
     *
     * @return Total NAV in ALPHA
     *
     */
    function getNav() public view override returns (uint256) {
        return totalStakedBalance.add(getBufferBalance());
    }

    /*
     * @dev Get buffer balance of the xALPHA contract
     *
     * @return Total unstaked ALPHA balance held by xALPHA, minus accrued fees
     */
    function getBufferBalance() public view override returns (uint256) {
        return alphaToken.balanceOf(address(this)).sub(withdrawableAlphaFees);
    }

    /*
     * @dev Get staked and buffer balance of the xALPHA contract, as separate values
     *
     * @return Staked and buffer balance as a tuple
     */
    function getFundBalances() public view override returns (uint256, uint256) {
        return (totalStakedBalance, getBufferBalance());
    }

    /**
     * @dev Get the withdrawable amount from a staking proxy

     * @param proxyIndex The proxy index

     * @return The withdrawable amount
     */
    function getWithdrawableAmount(uint256 proxyIndex) public view override returns (uint256) {
        require(proxyIndex < stakingFactory.getStakingProxyProxiesLength(), "Invalid index");
        return IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).getWithdrawableAmount();
    }

    /*
     * @dev Admin function to stake tokens from the buffer.
     *
     * @param proxyIndex: The proxy index to stake with
     * @param amount: allocation to staked balance
     * @param force: stake regardless of unbonding status
     */
    function stake(
        uint256 proxyIndex,
        uint256 amount,
        bool force
    ) public override onlyOwnerOrManager {
        _certifyAdmin();

        _stake(proxyIndex, amount, force);

        updateStakedBalance();
    }

    /*
     * @dev Updates the staked balance of the xALPHA contract.
     * @notice Includes any stake currently unbonding.
     *
     * @return Total staked balance in ALPHA staking contract
     */
    function updateStakedBalance() public override {
        // Set to zero temporarily
        totalStakedBalance = 0;
        for (uint256 i = 0; i < stakingFactory.getStakingProxyProxiesLength(); ++i) {
            totalStakedBalance = totalStakedBalance.add(
                IStakingProxy(stakingFactory.stakingProxyProxies(i)).getTotalStaked()
            );
        }
    }

    /*
     * @notice Admin-callable function in case of persistent depletion of buffer reserve
     * or emergency shutdown
     * @notice Incremental ALPHA will only be allocated to buffer reserve
     * @notice Starting a new unbonding period cancels the last one. Need to use 'force'
     * explicitly cancel a current unbonding.s
     */
    function unbond(uint256 proxyIndex, bool force) public override onlyOwnerOrManager {
        _certifyAdmin();
        _unbond(proxyIndex, force);
    }

    /*
     * @notice Admin-callable function to withdraw unbonded stake back into the buffer
     * @notice Incremental ALPHA will only be allocated to buffer reserve
     * @notice There is a 72-hour deadline to claim unbonded stake after the 30-day unbonding
     * period ends. This call will fail in the alpha staking contract if the 72-hour deadline
     * is expired.
     */
    function claimUnbonded(uint256 proxyIndex) public override onlyOwnerOrManager {
        _certifyAdmin();
        _claim(proxyIndex);

        updateStakedBalance();
    }

    /*
     * @notice Staking ALPHA cancels any currently open
     * unbonding. This will not stake unless the contract
     * is not unbonding, or the force param is sent
     * @param proxyIndex: the proxy index to stake with
     * @param amount: allocation to staked balance
     * @param force: stake regardless of unbonding status
     */
    function _stake(
        uint256 proxyIndex,
        uint256 amount,
        bool force
    ) private {
        require(amount > 0, "Cannot stake zero tokens");
        require(
            !IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).isUnbonding() || force,
            "Cannot stake during unbonding"
        );

        // Update the most recent stake timestamp
        lastStakeTimestamp = block.timestamp;

        alphaToken.transfer(address(stakingFactory.stakingProxyProxies(proxyIndex)), amount);
        IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).stake(amount);

        emit Stake(proxyIndex, block.timestamp, amount);
    }

    /*
     * @notice Unbonding ALPHA cancels any currently open
     * unbonding. This will not unbond unless the contract
     * is not already unbonding, or the force param is sent
     * @param proxyIndex: the proxy index to unbond
     * @param force: unbond regardless of status
     */
    function _unbond(uint256 proxyIndex, bool force) internal {
        require(
            !IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).isUnbonding() || force,
            "Cannot unbond during unbonding"
        );

        IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).unbond();

        emit Unbond(
            proxyIndex,
            block.timestamp,
            IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).getUnbondingAmount()
        );
    }

    /*
     * @notice Claims any fully unbonded ALPHA. Must be called
     * within 72 hours after unbonding period expires, or
     * funds are re-staked.
     *
     * @param proxyIndex: the proxy index to claim rewards for
     */
    function _claim(uint256 proxyIndex) internal {
        require(IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).isUnbonding(), "Not unbonding");

        uint256 claimedAmount = IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).getUnbondingAmount();

        IStakingProxy(stakingFactory.stakingProxyProxies(proxyIndex)).withdraw();

        emit Claim(proxyIndex, claimedAmount);
    }

    /*
     * @dev Get fee for a specific action
     *
     * @param _value: the value on which to assess the fee
     * @param _feeDivisor: the inverse of the percentage of the fee (i.e. 1% = 100)
     *
     * @return fee: total amount of fee to be assessed
     */
    function _calculateFee(uint256 _value, uint256 _feeDivisor) internal pure returns (uint256 fee) {
        if (_feeDivisor > 0) {
            fee = _value.div(_feeDivisor);
        }
    }

    /*
     * @dev Increase tracked amount of fees for management
     *
     * @param _feeAmount: the amount to increase management fees by
     */
    function _incrementWithdrawableAlphaFees(uint256 _feeAmount) private {
        withdrawableAlphaFees = withdrawableAlphaFees.add(_feeAmount);
    }

    /* ========================================================================================= */
    /*                                       Emergency Functions                                 */
    /* ========================================================================================= */

    /*
     * @dev Admin function for pausing contract operations. Pausing prevents mints.
     *
     */
    function pauseContract() public override onlyOwnerOrManager {
        _pause();
    }

    /*
     * @dev Admin function for unpausing contract operations.
     *
     */
    function unpauseContract() public override onlyOwnerOrManager {
        _unpause();
    }

    /*
     * @dev Public callable function for unstaking in event of admin failure/incapacitation.
     *
     * @notice Can only be called after a period of manager inactivity. Starts a 30-day unbonding
     * period. emergencyClaim must be called within 72 hours after the 30 day unbounding period expires.
     * Cancels any previous unbonding on the first call. Cannot be called again otherwise a caller
     * could indefinitely delay unbonding. Unbonds all staking proxy contracts.
     *
     * Once emergencyUnbondingTimestamp has been set, it is never reset unless an admin decides to.
     */
    function emergencyUnbond() external override {
        require(adminActiveTimestamp.add(LIQUIDATION_TIME_PERIOD) < block.timestamp, "Liquidation time not elapsed");

        uint256 thirtyThreeDaysAgo = block.timestamp - 33 days;
        require(emergencyUnbondTimestamp < thirtyThreeDaysAgo, "In unbonding period");

        emergencyUnbondTimestamp = block.timestamp;

        // Unstake everything
        for (uint256 i = 0; i < stakingFactory.getStakingProxyProxiesLength(); ++i) {
            _unbond(i, true);
        }
    }

    /*
     * @dev Public callable function for claiming unbonded stake in the event of admin failure/incapacitation.
     *
     * @notice Can only be called after a period of manager inactivity. Can only be called
     * after a 30-day unbonding period, and must be called within 72 hours of unbound period expiry. Makes a claim
     * for all staking proxies
     */
    function emergencyClaim() external override {
        require(adminActiveTimestamp.add(LIQUIDATION_TIME_PERIOD) < block.timestamp, "Liquidation time not elapsed");

        emergencyUnbondTimestamp = 0;

        // Claim everything
        for (uint256 i = 0; i < stakingFactory.getStakingProxyProxiesLength(); ++i) {
            _claim(i);
        }

        updateStakedBalance();
    }

    /* ========================================================================================= */
    /*                                          Utils/Fallback                                   */
    /* ========================================================================================= */

    /*
     * @notice Inverse of fee i.e., a fee divisor of 100 == 1%
     * @notice Three fee types
     * @dev Mint fee 0 or <= 2%
     * @dev Burn fee 0 or <= 1%
     * @dev Claim fee 0 <= 4%
     */
    function setFeeDivisors(
        uint256 mintFeeDivisor,
        uint256 burnFeeDivisor,
        uint256 claimFeeDivisor
    ) public override onlyOwner {
        _setFeeDivisors(mintFeeDivisor, burnFeeDivisor, claimFeeDivisor);
    }

    /*
     * @dev Internal setter for the fee divisors, with enforced maximum fees.
     */
    function _setFeeDivisors(
        uint256 _mintFeeDivisor,
        uint256 _burnFeeDivisor,
        uint256 _claimFeeDivisor
    ) private {
        require(_mintFeeDivisor == 0 || _mintFeeDivisor >= 50, "Invalid fee");
        require(_burnFeeDivisor == 0 || _burnFeeDivisor >= 100, "Invalid fee");
        require(_claimFeeDivisor >= 25, "Invalid fee");
        feeDivisors.mintFee = _mintFeeDivisor;
        feeDivisors.burnFee = _burnFeeDivisor;
        feeDivisors.claimFee = _claimFeeDivisor;

        emit FeeDivisorsSet(_mintFeeDivisor, _burnFeeDivisor, _claimFeeDivisor);
    }

    /*
     * @dev Registers that admin is present and active
     * @notice If admin isn't certified within liquidation time period,
     *         emergencyUnstake function becomes callable
     */
    function _certifyAdmin() private {
        adminActiveTimestamp = block.timestamp;
    }

    /*
     * @dev Update the AMM to use for swaps.
     * @param version: the swap mode - 0 for sushiswap, 1 for Uniswap V3.
     *
     * Should be used when e.g. pricing is better on one version vs.
     * the other. Only valid values are 0 and 1. A new version of Uniswap
     * or integration with another liquidity protocol will require a full
     * contract upgrade.
     */
    function updateSwapRouter(SwapMode version) public override onlyOwnerOrManager {
        require(version == SwapMode.SUSHISWAP || version == SwapMode.UNISWAP_V3, "Invalid swap router version");

        swapMode = version;

        emit UpdateSwapRouter(version);
    }

    /*
     * @dev Update the fee tier for the ETH/ALPHA Uniswap V3 pool.
     * @param fee: the fee tier to use.
     *
     * Should be used when trades can be executed more efficiently at a certain
     * fee tier, based on the combination of fees and slippage.
     *
     * Fees are expressed in 1/100th of a basis point.
     * Only three fee tiers currently exist.
     * 500 - (0.05%)
     * 3000 - (0.3%)
     * 10000 - (1%)
     * Not enforcing these values because Uniswap's contracts
     * allow them to set arbitrary fee tiers in the future.
     * Take care when calling this function to make sure a pool
     * actually exists for a given fee, and it is the most liquid
     * pool for the ALPHA/ETH pair.
     */
    function updateUniswapV3AlphaPoolFee(uint24 fee) external override onlyOwnerOrManager {
        v3AlphaPoolFee = fee;

        emit UpdateUniswapV3AlphaPoolFee(v3AlphaPoolFee);
    }

    /*
     * @dev Emergency function in case of errant transfer of
     *         xALPHA token directly to contract.
     *
     * Errant xALPHA can only be sent back to management.
     */
    function withdrawNativeToken() public override onlyOwnerOrManager {
        uint256 tokenBal = balanceOf(address(this));
        require(tokenBal > 0, "No tokens to withdraw");
        IERC20(address(this)).transfer(msg.sender, tokenBal);
    }

    /*
     * @dev Withdraw function for ALPHA fees.
     *
     * All fees are denominated in ALPHA, so this should cover all
     * fees earned via contract interactions. Fees can only be
     * sent to management.
     */
    function withdrawFees() public override {
        require(xTokenManager.isRevenueController(msg.sender), "Callable only by Revenue Controller");

        uint256 alphaFees = withdrawableAlphaFees;
        withdrawableAlphaFees = 0;
        alphaToken.transfer(msg.sender, alphaFees);

        emit FeeWithdraw(alphaFees);
    }

    /**
     * @dev Upgrades the staking proxies
     */
    function upgradeStakingProxies(address newImplementation) external onlyOwnerOrManager {
        stakingFactory.upgradeProxies(newImplementation);
    }

    /*
     * @dev Enforce functions only called by management.
     */
    modifier onlyOwnerOrManager {
        require(msg.sender == owner() || xTokenManager.isManager(msg.sender, address(this)), "Non-admin caller");
        _;
    }

    /*
     * @dev Fallback function for received ETH.
     *
     * The contract may receive ETH as part of swaps, so only reject
     * if the ETH is sent directly.
     */
    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "Errant ETH deposit");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.2;

/**
 Contract which implements locking of functions via a notLocked modifier
 Functions are locked per address. 
 */
contract BlockLock {
    // how many blocks are the functions locked for
    uint256 private constant BLOCK_LOCK_COUNT = 6;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;

    function lock(address _address) internal {
        lastLockedBlock[_address] = block.number + BLOCK_LOCK_COUNT;
    }

    modifier notLocked(address lockedAddress) {
        require(lastLockedBlock[lockedAddress] <= block.number);
        _;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IxTokenManager.sol";
import "./IALPHAStaking.sol";
import "./IWETH.sol";
import "./IOneInchLiquidityProtocol.sol";
import "./IStakingProxy.sol";

import "../helpers/StakingFactory.sol";

interface IxALPHA {
    enum SwapMode {
        SUSHISWAP,
        UNISWAP_V3
    }

    struct FeeDivisors {
        uint256 mintFee;
        uint256 burnFee;
        uint256 claimFee;
    }

    event Stake(uint256 proxyIndex, uint256 timestamp, uint256 amount);
    event Unbond(uint256 proxyIndex, uint256 timestamp, uint256 amount);
    event Claim(uint256 proxyIndex, uint256 amount);
    event FeeDivisorsSet(uint256 mintFee, uint256 burnFee, uint256 claimFee);
    event FeeWithdraw(uint256 fee);
    event UpdateSwapRouter(SwapMode version);
    event UpdateUniswapV3AlphaPoolFee(uint24 fee);

    function initialize(
        string calldata _symbol,
        IWETH _wethToken,
        IERC20 _alphaToken,
        address _alphaStaking,
        StakingFactory _stakingFactory,
        address _stakingProxyImplementation,
        IxTokenManager _xTokenManager,
        address _uniswapRouter,
        address _sushiswapRouter,
        FeeDivisors calldata _feeDivisors
    ) external;

    function mint(uint256 minReturn) external payable;

    function mintWithToken(uint256 alphaAmount) external;

    function calculateMintAmount(uint256 incrementalAlpha, uint256 totalSupply)
        external
        view
        returns (uint256 mintAmount);

    function burn(
        uint256 tokenAmount,
        bool redeemForEth,
        uint256 minReturn
    ) external;

    function getNav() external view returns (uint256);

    function getBufferBalance() external view returns (uint256);

    function getFundBalances() external view returns (uint256, uint256);

    function getWithdrawableAmount(uint256 proxyIndex) external view returns (uint256);

    function stake(
        uint256 proxyIndex,
        uint256 amount,
        bool force
    ) external;

    function updateStakedBalance() external;

    function unbond(uint256 proxyIndex, bool force) external;

    function claimUnbonded(uint256 proxyIndex) external;

    function pauseContract() external;

    function unpauseContract() external;

    function emergencyUnbond() external;

    function emergencyClaim() external;

    function setFeeDivisors(
        uint256 mintFeeDivisor,
        uint256 burnFeeDivisor,
        uint256 claimFeeDivisor
    ) external;

    function updateSwapRouter(SwapMode version) external;

    function updateUniswapV3AlphaPoolFee(uint24 fee) external;

    function withdrawNativeToken() external;

    function withdrawFees() external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IxTokenManager {
    /**
     * @dev Add a manager to an xAsset fund
     */
    function addManager(address manager, address fund) external;

    /**
     * @dev Remove a manager from an xAsset fund
     */
    function removeManager(address manager, address fund) external;

    /**
     * @dev Check if an address is a manager for a fund
     */
    function isManager(address manager, address fund) external view returns (bool);

    /**
     * @dev Set revenue controller
     */
    function setRevenueController(address controller) external;

    /**
     * @dev Check if address is revenue controller
     */
    function isRevenueController(address caller) external view returns (bool);
}

// SPDX-License-Identifier: ISC

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: ISC

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

interface IAlphaStaking {
    event SetWorker(address worker);
    event Stake(address owner, uint256 share, uint256 amount);
    event Unbond(address owner, uint256 unbondTime, uint256 unbondShare);
    event Withdraw(address owner, uint256 withdrawShare, uint256 withdrawAmount);
    event CancelUnbond(address owner, uint256 unbondTime, uint256 unbondShare);
    event Reward(address worker, uint256 rewardAmount);
    event Extract(address governor, uint256 extractAmount);

    struct Data {
        uint256 status;
        uint256 share;
        uint256 unbondTime;
        uint256 unbondShare;
    }

    // solhint-disable-next-line func-name-mixedcase
    function STATUS_READY() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function STATUS_UNBONDING() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function UNBONDING_DURATION() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function WITHDRAW_DURATION() external view returns (uint256);

    function alpha() external view returns (address);

    function getStakeValue(address user) external view returns (uint256);

    function totalAlpha() external view returns (uint256);

    function totalShare() external view returns (uint256);

    function stake(uint256 amount) external;

    function unbond(uint256 share) external;

    function withdraw() external;

    function users(address user) external view returns (Data calldata);
}

// SPDX-License-Identifier: ISC

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

// Copied from:
// https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: ISC

pragma solidity >=0.6.2;

interface IStakingProxy {
    function initialize(address alphaStaking) external;

    function getTotalStaked() external view returns (uint256);

    function getUnbondingAmount() external view returns (uint256);

    function getLastUnbondingTimestamp() external view returns (uint256);

    function getWithdrawableAmount() external view returns (uint256);

    function isUnbonding() external view returns (bool);

    function withdraw() external;

    function stake(uint256 amount) external;

    function unbond() external;
}

// SPDX-License-Identifier: ISC

pragma solidity >=0.6.2;

import "../proxies/StakingProxyProxy.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingFactory is Ownable {
    address payable[] public stakingProxyProxies;

    constructor() public Ownable() {}

    function deployProxy(address stakingProxyImplementation) external onlyOwner returns (address) {
        StakingProxyProxy proxy = new StakingProxyProxy(stakingProxyImplementation, address(this));
        stakingProxyProxies.push(address(proxy));
        return address(proxy);
    }

    function upgradeProxies(address newImplementation) external onlyOwner {
        for (uint256 i = 0; i < stakingProxyProxies.length; ++i) {
            StakingProxyProxy(stakingProxyProxies[i]).upgradeTo(newImplementation);
        }
    }

    function getStakingProxyProxiesLength() external view returns (uint256) {
        return stakingProxyProxies.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity ^0.6.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: ISC

pragma solidity ^0.6.0;

interface IOneInchLiquidityProtocol {
    function swap(
        address src,
        address dst,
        uint256 amount,
        uint256 minReturn,
        address referral
    ) external payable returns (uint256 result);

    function swapFor(
        address src,
        address dst,
        uint256 amount,
        uint256 minReturn,
        address referral,
        address payable receiver
    ) external payable returns (uint256 result);
}

// SPDX-License-Identifier: ISC

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract StakingProxyProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _proxyAdmin) public TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

