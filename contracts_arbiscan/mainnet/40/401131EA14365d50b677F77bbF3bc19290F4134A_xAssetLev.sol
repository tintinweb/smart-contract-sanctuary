//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interface/IBalancerVault.sol";
import "./interface/IFlashLoanReceiver.sol";
import "./interface/ILiquidityPool.sol";
import "./interface/IMarket.sol";
import "./interface/IPrice.sol";
import "./interface/IUniswapV3Router.sol";
import "./interface/ISushiRouter.sol";
import "./interface/IWeth.sol";
import "./interface/IxTokenManager.sol";
import "./lock/BlockLock.sol";

contract xAssetLev is
    Initializable,
    IFlashLoanReceiver,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    BlockLock
{
    enum Exchange {
        UniSingleHop,
        UniMultiHop,
        BalancerSingleSwap,
        BalancerBatchSwap,
        SushiSingleHop,
        SushiMultiHop
    }

    struct TokenAddresses {
        address baseToken;
        address weth;
        address usdc;
    }

    struct LendingAddresses {
        address liquidityPool;
        address market;
        address price;
    }

    struct FeeDivisors {
        uint256 mintFee; // fee is determined by dividing amount. Example: mintFee = 500 => 0.2%
        uint256 burnFee; // fee is determined by dividing amount. Example: burnFee = 500 => 0.2%
    }

    struct SupplyData {
        uint256 totalCap;
        uint256 userCap;
        uint256 initialSupplyMultiplier; // used to determine initial supply. baseToken amount * initialSupplyMultiplier
    }

    /**
     * @dev Struct that contains parameters that are used by the lever and delever functions
     *
     * tradeData for each exchange:
     *
     *  `UniSingleHop` = tradeData ignored.
     *
     *  `UniMultiHop` = pool assets and their fees e.g.
     *     abi.encode(
     *      ["address", "uint24", "address", "uint24", "address"],
     *      asset1,
     *      poolFeeAsset1Asset2,
     *      asset2,
     *      poolFeeAsset2Asset3,
     *      asset3
     *     );
     *
     *  `BalancerSingleSwap` = poolId
     *
     *  `BalancerBatchSwap` = array of poolIds and array of assets.
     */
    struct LeverageFunctionParams {
        bool checkNav;
        uint256 maxNavLoss;
        Exchange exchange;
        bytes tradeData;
    }

    struct LiquidityBuffer {
        bool active;
        uint256 amount;
    }

    //--------------------------------------------------------------------------
    // State variables
    //--------------------------------------------------------------------------

    uint256 internal constant MAX_UINT = 2**256 - 1;

    IERC20Metadata public baseToken;
    IERC20Metadata private usdc;
    IWeth private weth;

    ILiquidityPool private liquidityPool;
    IMarket private market;
    IPrice private priceFeed;

    IUniswapV3Router private uniswapV3Router;
    uint24 private uniswapFee;

    IxTokenManager private xTokenManager;

    FeeDivisors public feeDivisors;
    SupplyData public supplyData;
    LiquidityBuffer public liquidityBuffer;

    uint256 public claimableFees;

    uint256 private baseTokenMultiplier;
    uint256 private priceFeedDivisor;
    uint256 private lendingDivisor;
    uint256 private usdcToBaseTokenMultiplier;
    uint256 private baseTokenToUSDCFactor;

    IBalancerVault private balancerVault;
    ISushiRouter private sushiRouter;

    //--------------------------------------------------------------------------
    // Events
    //--------------------------------------------------------------------------

    event Leverage(uint256 depositAmount, uint256 borrowAmount, uint256 swapReturn);
    event Deleverage(uint256 withdrawAmount, uint256 swapReturn);
    event CollateralWithdrawal(uint256 collateral);
    event CollateralDeposit(uint256 collateral);
    event TotalSupplyCapChange(uint256 totalSupplyCap);
    event UserBalanceCapChange(uint256 userSupplyCap);

    //--------------------------------------------------------------------------
    // Modifiers
    //--------------------------------------------------------------------------

    /**
     * @dev Enforce functions only called by management.
     */
    modifier onlyOwnerOrManager() {
        require(msg.sender == owner() || xTokenManager.isManager(msg.sender, address(this)), "Non-admin caller");
        _;
    }

    /**
     * @dev Reverts the transaction if the operation causes a nav loss greater than the tolerance.
     *
     * @param check Performs the check if true
     * @param maxNavLoss The nav loss tolerance, ignored if check is false
     */
    modifier checkNavLoss(bool check, uint256 maxNavLoss) {
        uint256 navBefore;
        uint256 navAfter;
        uint256 marketBalance;
        uint256 bufferBalance;

        if (check) {
            (marketBalance, bufferBalance) = getFundBalances();
            navBefore = (marketBalance + bufferBalance);
        }

        _;

        if (check) {
            (marketBalance, bufferBalance) = getFundBalances();
            navAfter = (marketBalance + bufferBalance);

            require(navAfter >= navBefore - maxNavLoss, "NAV loss greater than tolerance");
        }
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Errant ETH deposit");
    }

    //--------------------------------------------------------------------------
    // Constructor / Initializer
    //--------------------------------------------------------------------------

    /**
     * @dev Initializes this leverage asset
     *
     * @param _symbol The token ticker
     * @param _tokens The tokens needed
     * @param _lending The lending contract addresses
     * @param _uniswapV3Router The uniswap router
     * @param _uniswapFee The uniswap pool fee
     * @param _xTokenManager The xtoken manager contract
     * @param _feeDivisors The fee divisors
     * @param _supplyData The supply data
     * @param _liquidityBuffer The liquidity buffer
     */
    function initialize(
        string calldata _symbol,
        TokenAddresses calldata _tokens,
        LendingAddresses calldata _lending,
        IUniswapV3Router _uniswapV3Router,
        uint24 _uniswapFee,
        IBalancerVault _balancerVault,
        ISushiRouter _sushiRouter,
        IxTokenManager _xTokenManager,
        FeeDivisors calldata _feeDivisors,
        SupplyData calldata _supplyData,
        LiquidityBuffer calldata _liquidityBuffer
    ) external initializer {
        __ERC20_init("xAssetLev", _symbol);
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        // lending contracts
        market = IMarket(_lending.market);
        liquidityPool = ILiquidityPool(_lending.liquidityPool);
        priceFeed = IPrice(_lending.price);

        // token contracts
        baseToken = IERC20Metadata(_tokens.baseToken);
        usdc = IERC20Metadata(_tokens.usdc);
        weth = IWeth(_tokens.weth);

        // uniswap
        uniswapV3Router = _uniswapV3Router;
        uniswapFee = _uniswapFee;

        // balancer
        balancerVault = _balancerVault;

        // sushi
        sushiRouter = _sushiRouter;

        xTokenManager = _xTokenManager;

        feeDivisors = _feeDivisors;
        supplyData = _supplyData;
        liquidityBuffer = _liquidityBuffer;

        // token approvals for uniswap swap router
        usdc.approve(address(uniswapV3Router), MAX_UINT);
        baseToken.approve(address(uniswapV3Router), MAX_UINT);
        weth.approve(address(uniswapV3Router), MAX_UINT);

        // token approvals for sushi
        usdc.approve(address(sushiRouter), MAX_UINT);
        baseToken.approve(address(sushiRouter), MAX_UINT);
        weth.approve(address(sushiRouter), MAX_UINT);

        // token approvals for balancer
        usdc.approve(address(balancerVault), MAX_UINT);
        baseToken.approve(address(balancerVault), MAX_UINT);
        weth.approve(address(balancerVault), MAX_UINT);

        // token approvals for xtoken lending
        baseToken.approve(address(market), MAX_UINT);
        usdc.approve(address(liquidityPool), MAX_UINT);

        // set the decimals converters
        baseTokenMultiplier = 10**baseToken.decimals();
        priceFeedDivisor = 10**12;
        lendingDivisor = 10**18;
        usdcToBaseTokenMultiplier = 10**(usdc.decimals() + baseToken.decimals());
        baseTokenToUSDCFactor = baseToken.decimals() < usdc.decimals()
            ? 10**(usdc.decimals() - baseToken.decimals())
            : 10**(baseToken.decimals() - usdc.decimals());
    }

    //--------------------------------------------------------------------------
    // For Investors
    //--------------------------------------------------------------------------

    /**
     * @dev Mint leveraged asset tokens with ETH
     *
     * @param minReturn The minimum return for the ETH trade
     */
    function mint(uint256 minReturn) external payable notLocked(msg.sender) whenNotPaused {
        require(msg.value > 0, "Must send ETH");
        _lock(msg.sender);

        // make the deposit to weth
        weth.deposit{ value: msg.value }();

        // swap for base token if weth is not the base token
        uint256 baseTokenAmount;
        if (address(baseToken) == address(weth)) {
            baseTokenAmount = msg.value;
        } else {
            baseTokenAmount = _swapExactInputForOutput(address(weth), address(baseToken), msg.value, minReturn);
        }

        uint256 fee = baseTokenAmount / feeDivisors.mintFee;
        _incrementFees(fee);

        _mintInternal(msg.sender, baseTokenAmount - fee, totalSupply());
    }

    /**
     * @dev Mint leveraged asset tokens with the base token
     *
     * @param inputAssetAmount The amount of base tokens used to mint
     */
    function mintWithToken(uint256 inputAssetAmount) external notLocked(msg.sender) whenNotPaused {
        require(inputAssetAmount > 0, "Must send token");
        _lock(msg.sender);

        require(baseToken.transferFrom(msg.sender, address(this), inputAssetAmount), "ERC20 transfer failure");

        uint256 fee = inputAssetAmount / feeDivisors.mintFee;
        _incrementFees(fee);

        _mintInternal(msg.sender, inputAssetAmount - fee, totalSupply());
    }

    /**
     * @dev Burns the leveraged asset token for the base token or ETH
     *
     * @param xassetAmount The amount to burn
     * @param redeemForEth True to return ETH, false otherwise
     * @param minReturn The minimum return to swap from base token to ETH, unused if not redeeming for Eth of WETH baseToken
     */
    function burn(
        uint256 xassetAmount,
        bool redeemForEth,
        uint256 minReturn
    ) external notLocked(msg.sender) {
        require(xassetAmount > 0, "Must send token");
        _lock(msg.sender);
        (uint256 marketBalance, uint256 bufferBalance) = getFundBalances();

        // Conversion between xasset and base token
        uint256 proRataTokens = ((marketBalance + bufferBalance) * xassetAmount) / totalSupply();
        require(proRataTokens + getLiquidityBuffer() <= bufferBalance, "Insufficient exit liquidity");
        // Determine fee and tokens owed to user
        uint256 fee = proRataTokens / feeDivisors.burnFee;
        uint256 userTokens = proRataTokens - fee;

        // Increment the claimable fees
        _incrementFees(fee);

        if (redeemForEth) {
            uint256 userEth;

            // If the base token is weth there's no need to swap on open market
            if (address(baseToken) == address(weth)) {
                userEth = userTokens;
            } else {
                // swap from base token to weth
                userEth = _swapExactInputForOutput(address(baseToken), address(weth), userTokens, minReturn);
            }
            weth.withdraw(userEth);

            // Send eth
            (bool success, ) = msg.sender.call{ value: userEth }(new bytes(0));
            require(success, "ETH  transfer failed");
        } else {
            require(baseToken.transfer(msg.sender, userTokens), "ERC20 transfer failure");
        }

        _burn(msg.sender, xassetAmount);
    }

    /**
     * @notice Add block lock functionality to token transfers
     */
    function transfer(address recipient, uint256 amount) public override notLocked(msg.sender) returns (bool) {
        require(balanceOf(recipient) + amount <= supplyData.userCap, "Transfer exceeds user cap");
        return super.transfer(recipient, amount);
    }

    /**
     * @notice Add block lock functionality to token transfers
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override notLocked(sender) returns (bool) {
        require(balanceOf(recipient) + amount <= supplyData.userCap, "Transfer exceeds user cap");
        return super.transferFrom(sender, recipient, amount);
    }

    //--------------------------------------------------------------------------
    // View Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Returns the buffer balance without including fees
     *
     * @return The buffer balance
     */
    function getBufferBalance() public view returns (uint256) {
        return baseToken.balanceOf(address(this)) - claimableFees;
    }

    /**
     * @dev Returns the liquidity buffer amount based on if it's active or not
     *
     * @return 0 if inactive, buffer amount if active
     */
    function getLiquidityBuffer() public view returns (uint256) {
        return liquidityBuffer.active ? liquidityBuffer.amount : 0;
    }

    /**
     * @dev Get the withdrawable fee amounts
     *
     * @return feeAsset The fee asset
     * @return feeAmount The withdrawable amount
     */
    function getWithdrawableFees() public view returns (address feeAsset, uint256 feeAmount) {
        feeAsset = address(baseToken);
        feeAmount = claimableFees;
    }

    /**
     * @dev This function could revert if collateral < debt, since this contract is liquidation proof.
     *
     * @return marketBalance The value of the contract's collateral minus the contract's debt
     * @return bufferBalance The buffer balance
     */
    function getFundBalances() public view returns (uint256 marketBalance, uint256 bufferBalance) {
        uint256 collateral = market.collateral(address(this)); // 18 decimals
        uint256 usdDenominatedDebt = liquidityPool.updatedBorrowBy(address(this)); // 18 decimals

        // convert collateral to baseToken decimals
        uint256 parsedCollateral = baseToken.decimals() == 18
            ? collateral
            : (collateral * baseTokenMultiplier) / lendingDivisor; // baseToken decimals

        // Get the asset price in usdc
        uint256 assetUsdPrice = priceFeed.getPrice(); // 12 decimals

        // convert usd denominated debt to base token terms
        uint256 priceMultiplier = baseToken.decimals() > usdc.decimals()
            ? 10**(baseToken.decimals() - usdc.decimals())
            : 1;
        uint256 priceDivider = baseToken.decimals() < usdc.decimals()
            ? 10**(usdc.decimals() - baseToken.decimals())
            : 1;
        uint256 baseTokenDenominatedDebt = (usdDenominatedDebt * priceMultiplier) / (assetUsdPrice * priceDivider); // baseToken decimals

        require(parsedCollateral >= baseTokenDenominatedDebt, "Debt is greater than collateral");
        marketBalance = parsedCollateral - baseTokenDenominatedDebt;
        bufferBalance = getBufferBalance();
    }

    /**
     * @dev Calculates the mint amount based on current supply
     *
     * @param incrementalToken The amount of base tokens used for minting
     * @param totalSupply The current totalSupply of xAssetLev
     *
     * @return The mint amount
     */
    function calculateMintAmount(uint256 incrementalToken, uint256 totalSupply) public view returns (uint256) {
        if (totalSupply == 0) {
            return incrementalToken * supplyData.initialSupplyMultiplier;
        } else {
            (uint256 marketBalance, uint256 bufferBalance) = getFundBalances();
            uint256 nav = marketBalance + bufferBalance;
            require(nav > incrementalToken, "NAV too low for minting");

            uint256 navBefore = nav - incrementalToken;
            return (incrementalToken * totalSupply) / navBefore;
        }
    }

    //--------------------------------------------------------------------------
    // Management
    //--------------------------------------------------------------------------

    /**
     * @dev Creates the leveraged position
     *
     * @param depositAmount The amount to be deposited.
     * @param borrowAmount The amount to be borrowed.
     * @param params The leverage function params.
     *
     * @dev When swapping usdc for baseToken on the open market, it is possible (probable even) that the asset price will
     *      be different than xLending's internal asset price. When the open market places a higher value on the baseToken
     *      asset than xLending, the NAV of the contract will go down. The maxNavLoss parameter is the maximum tolerance
     *      of NAV loss. Conversely, if the open market places a lower value on the baseToken asset than xLending, the
     *      NAV of the contract will go up.
     */
    function lever(
        uint256 depositAmount,
        uint256 borrowAmount,
        LeverageFunctionParams calldata params
    ) public onlyOwnerOrManager checkNavLoss(params.checkNav, params.maxNavLoss) {
        // Create the leveraged position
        require(depositAmount <= getBufferBalance(), "Deposit amount too large");

        // It's possible to not need to collateralize and only borrow
        if (depositAmount > 0) {
            market.collateralize(depositAmount);
        }
        liquidityPool.borrow(borrowAmount);

        // Perform swaps (USDC -> baseToken)
        uint256 swapReturn;
        if (params.exchange == Exchange.UniSingleHop) {
            swapReturn = _swapExactInputForOutput(address(usdc), address(baseToken), borrowAmount, 0);
        } else if (params.exchange == Exchange.UniMultiHop) {
            swapReturn = _swapExactInputForOutputMultiHop(params.tradeData, borrowAmount, 0);
        } else if (params.exchange == Exchange.BalancerSingleSwap) {
            // decode trade data
            bytes32 poolId = abi.decode(params.tradeData, (bytes32));

            // make the swap
            swapReturn = _swapBalancerSingleSwap(
                IBalancerVault.SwapKind.GIVEN_IN,
                poolId,
                usdc,
                baseToken,
                borrowAmount,
                0
            );
        } else if (params.exchange == Exchange.BalancerBatchSwap) {
            // decode trade data
            (bytes32[] memory poolIds, IERC20[] memory assets) = abi.decode(params.tradeData, (bytes32[], IERC20[]));
            // there's one pool id for a pool comprised of 2 assets.
            // example: usdc/usdt => usdt/weth
            //      2 pool ids,
            //      3 assets
            require(poolIds.length + 1 == assets.length, "Invalid multihop params");

            swapReturn = _swapBalancerBatchSwap(IBalancerVault.SwapKind.GIVEN_IN, poolIds, assets, borrowAmount);
        } else if (params.exchange == Exchange.SushiSingleHop) {
            address[] memory tradePath = new address[](2);
            tradePath[0] = address(usdc);
            tradePath[1] = address(baseToken);
            swapReturn = _swapExactInSushi(tradePath, borrowAmount, 0);
        } else if (params.exchange == Exchange.SushiMultiHop) {
            address[] memory tradePath = abi.decode(params.tradeData, (address[]));
            swapReturn = _swapExactInSushi(tradePath, borrowAmount, 0);
        } else {
            revert("Internal error: invalid exchange");
        }

        emit Leverage(depositAmount, borrowAmount, swapReturn);
    }

    /**
     * @dev Unwinds the leveraged position through flash loan
     *
     * @param withdrawAmount The amount of collateral to be withdrawn.
     * @param params The leverage function params.
     *
     * @dev When swapping usdc for baseToken on the open market, it is possible (probable even) that the asset price will
     *      be different than xLending's internal asset price. When the open market places a lower value on the baseToken
     *      asset than xLending, the NAV of the contract will go down. The maxNavLoss parameter is the maximum tolerance
     *      of NAV loss. Conversely, if the open market places a higher value on the baseToken asset than xLending, the
     *      NAV of the contract will go up.
     */
    function delever(uint256 withdrawAmount, LeverageFunctionParams calldata params)
        public
        onlyOwnerOrManager
        checkNavLoss(params.checkNav, params.maxNavLoss)
    {
        require(withdrawAmount <= market.collateral(address(this)), "Not enough collateral");

        // Get the amount of usd to borrow to cover withdrawAmount
        uint256 assetUsdPrice = priceFeed.getPrice(); // 12 decimals
        uint256 usdcAmount = withdrawAmount * assetUsdPrice; // baseToken decimals + 12 decimals

        // usdcAmountAdjusted is usdc decimals (6)
        uint256 usdcAmountAdjusted = baseToken.decimals() < usdc.decimals()
            ? _divUp(usdcAmount * baseTokenToUSDCFactor, priceFeedDivisor)
            : _divUp(_divUp(usdcAmount, priceFeedDivisor), baseTokenToUSDCFactor);
        // In case we have an existing balance of USDC (should never be the case), we use entirety of existing balance
        usdcAmountAdjusted = usdc.balanceOf(address(this)) >= usdcAmountAdjusted
            ? 0
            : usdcAmountAdjusted - usdc.balanceOf(address(this));

        // subtract the flash loan fee, xlend will add it
        uint256 amountFee = _divUp((usdcAmountAdjusted * (liquidityPool.getFlashLoanFeeFactor())), lendingDivisor);
        usdcAmountAdjusted -= amountFee;

        // encode amount to withdraw
        bytes memory paramsLoan = abi.encode(withdrawAmount, params.exchange, params.tradeData);

        // Take a flash loan based on debt owed
        // Note function executeOperation is the callback
        liquidityPool.flashLoan(address(this), usdcAmountAdjusted, paramsLoan);
    }

    /**
     * @dev Flash loan callback function.
     * Pay market debt with flash loan funds
     * Withdraw collateral (amount contained in _params)
     * Swap withdrawn collateral for USDC
     * Pay back flash loan
     *
     * @param _amount The amount borrowed from flash loan
     * @param _fee The flash loan fee
     * @param _params The flash loan params, will contain amount of ETH to withdraw
     */
    function executeOperation(
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override {
        require(msg.sender == address(liquidityPool), "Only callable by flash loan provider");

        // Decode params
        (uint256 withdrawAmount, Exchange exchange, bytes memory tradeData) = abi.decode(
            _params,
            (uint256, Exchange, bytes)
        );

        // Pay back debt
        liquidityPool.whitelistRepay(_amount);

        // Withdraw
        _withdraw(withdrawAmount);

        // Swap collateral for flash loan debt
        // Max input to trade is buffer balance so that we don't trade away fees
        uint256 flashLoanDebt = _amount + _fee;
        uint256 swapReturn;
        if (exchange == Exchange.UniSingleHop) {
            swapReturn = _swapInputForExactOutput(address(baseToken), address(usdc), getBufferBalance(), flashLoanDebt);
        } else if (exchange == Exchange.UniMultiHop) {
            swapReturn = _swapInputForExactOutputMultiHop(tradeData, getBufferBalance(), flashLoanDebt);
        } else if (exchange == Exchange.BalancerSingleSwap) {
            // decode trade data
            bytes32 poolId = abi.decode(tradeData, (bytes32));

            // make the swap
            swapReturn = _swapBalancerSingleSwap(
                IBalancerVault.SwapKind.GIVEN_OUT,
                poolId,
                baseToken,
                usdc,
                flashLoanDebt,
                getBufferBalance()
            );
        } else if (exchange == Exchange.BalancerBatchSwap) {
            // decode trade data
            (bytes32[] memory poolIds, IERC20[] memory assets) = abi.decode(tradeData, (bytes32[], IERC20[]));
            // there's one pool id for a pool comprised of 2 assets.
            // example: usdc/usdt => usdt/weth
            //      2 pool ids,
            //      3 assets
            require(poolIds.length + 1 == assets.length, "Invalid multihop params");

            swapReturn = _swapBalancerBatchSwap(IBalancerVault.SwapKind.GIVEN_OUT, poolIds, assets, flashLoanDebt);
        } else if (exchange == Exchange.SushiSingleHop) {
            address[] memory tradePath = new address[](2);
            tradePath[0] = address(baseToken);
            tradePath[1] = address(usdc);
            swapReturn = _swapExactOutSushi(tradePath, flashLoanDebt, getBufferBalance());
        } else if (exchange == Exchange.SushiMultiHop) {
            address[] memory tradePath = abi.decode(tradeData, (address[]));
            swapReturn = _swapExactOutSushi(tradePath, flashLoanDebt, getBufferBalance());
        } else {
            revert("Internal error: invalid exchange");
        }

        emit Deleverage(withdrawAmount, swapReturn);
    }

    /**
     * @dev Withdraw collateral from xtoken lending
     *
     * @param withdrawAmount The amount to withdraw
     */
    function withdraw(uint256 withdrawAmount) external onlyOwnerOrManager {
        _withdraw(withdrawAmount);

        emit CollateralWithdrawal(withdrawAmount);
    }

    /**
     * @dev Deposit collateral to xtoken lending
     *
     * @param depositAmount The amount to deposit
     */
    function deposit(uint256 depositAmount) external onlyOwnerOrManager {
        require(depositAmount <= getBufferBalance(), "Deposit amount exceeds buffer");

        _deposit(depositAmount);

        emit CollateralDeposit(depositAmount);
    }

    /**
     * @dev Set the supply cap
     *
     * @param _supplyCap The new supply cap
     */
    function setTotalSupplyCap(uint256 _supplyCap) external onlyOwnerOrManager {
        supplyData.totalCap = _supplyCap;

        emit TotalSupplyCapChange(_supplyCap);
    }

    /**
     * @dev Set the user balance cap
     *
     * @param _userBalanceCap The new user balance cap
     */
    function setUserBalanceCap(uint256 _userBalanceCap) external onlyOwnerOrManager {
        supplyData.userCap = _userBalanceCap;

        emit UserBalanceCapChange(_userBalanceCap);
    }

    /**
     * @dev Set the liquidity buffer amount
     *
     * @param _liquidityBufferAmount The liquidity buffer amount
     */
    function setLiquidityBufferAmount(uint256 _liquidityBufferAmount) external onlyOwnerOrManager {
        liquidityBuffer.amount = _liquidityBufferAmount;
    }

    /**
     * @dev Set the liquidity buffer active level
     *
     * @param _active True to make active, false otherwise
     */
    function setLiquidityBufferActive(bool _active) external onlyOwnerOrManager {
        liquidityBuffer.active = _active;
    }

    /**
     * @dev Claim and withdraw fees
     * @notice Only callable by the revenue controller
     */
    function claimFees() external {
        require(xTokenManager.isRevenueController(msg.sender), "Callable only by Revenue Controller");
        // => transfer tokens
        uint256 totalFees = claimableFees;
        claimableFees = 0;
        if (totalFees > 0) {
            require(baseToken.transfer(msg.sender, totalFees), "ERC20 transfer failure");
        }
    }

    /**
     * @dev Exempts an address from blocklock
     * @param lockAddress The address to exempt
     */
    function exemptFromBlockLock(address lockAddress) external onlyOwnerOrManager {
        _exemptFromBlockLock(lockAddress);
    }

    /**
     * @dev Removes exemption for an address from blocklock
     * @param lockAddress The address to remove exemption
     */
    function removeBlockLockExemption(address lockAddress) external onlyOwnerOrManager {
        _removeBlockLockExemption(lockAddress);
    }

    /**
     * @dev Admin function for pausing contract operations. Pausing prevents mints.
     */
    function pauseContract() external onlyOwnerOrManager {
        _pause();
    }

    /**
     * @dev Admin function for unpausing contract operations.
     */
    function unpauseContract() external onlyOwnerOrManager {
        _unpause();
    }

    /**
     * @dev Admin function to update the fee divisors
     *
     * @param newDivisors The new fee divisors
     */
    function setFeeDivisor(FeeDivisors calldata newDivisors) external onlyOwnerOrManager {
        feeDivisors.burnFee = newDivisors.burnFee;
        feeDivisors.mintFee = newDivisors.mintFee;
    }

    /**
     * @dev Admin function to set the balancer vault and make token approvals
     *
     * @param _balancerVault The balancer vault
     */
    function setBalancerVault(IBalancerVault _balancerVault) external onlyOwnerOrManager {
        balancerVault = _balancerVault;

        // make the token approvals
        usdc.approve(address(balancerVault), MAX_UINT);
        baseToken.approve(address(balancerVault), MAX_UINT);
        weth.approve(address(balancerVault), MAX_UINT);
    }

    /**
     * @dev Admin function to set the sushi router and make token approvals
     *
     * @param _sushiRouter The sushi router
     */
    function setSushiRouter(ISushiRouter _sushiRouter) external onlyOwnerOrManager {
        sushiRouter = _sushiRouter;

        // make the token approvals
        usdc.approve(address(sushiRouter), MAX_UINT);
        baseToken.approve(address(sushiRouter), MAX_UINT);
        weth.approve(address(sushiRouter), MAX_UINT);
    }

    //--------------------------------------------------------------------------
    // Private functions
    //--------------------------------------------------------------------------

    function _mintInternal(
        address recipient,
        uint256 baseTokenAmount,
        uint256 totalSupply
    ) private {
        uint256 amountToMint = calculateMintAmount(baseTokenAmount, totalSupply);
        require(totalSupply + amountToMint <= supplyData.totalCap);
        require(balanceOf(recipient) + amountToMint < supplyData.userCap);

        _mint(recipient, amountToMint);
    }

    function _withdraw(uint256 _withdrawAmount) private {
        market.withdraw(_withdrawAmount);
    }

    function _deposit(uint256 _depositAmount) private {
        market.collateralize(_depositAmount);
    }

    function _incrementFees(uint256 _amount) private {
        claimableFees += _amount;
    }

    function _swapExactInputForOutput(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 minReturn
    ) internal returns (uint256) {
        IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router.ExactInputSingleParams({
            tokenIn: address(inputToken),
            tokenOut: address(outputToken),
            fee: uniswapFee,
            recipient: address(this),
            deadline: MAX_UINT,
            amountIn: inputAmount,
            amountOutMinimum: minReturn,
            sqrtPriceLimitX96: 0
        });

        return uniswapV3Router.exactInputSingle(params);
    }

    function _swapExactInputForOutputMultiHop(
        bytes calldata tradePath,
        uint256 inputAmount,
        uint256 minReturn
    ) internal returns (uint256) {
        IUniswapV3Router.ExactInputParams memory params = IUniswapV3Router.ExactInputParams({
            path: tradePath,
            recipient: address(this),
            deadline: MAX_UINT,
            amountIn: inputAmount,
            amountOutMinimum: minReturn
        });

        return uniswapV3Router.exactInput(params);
    }

    function _swapInputForExactOutput(
        address inputToken,
        address outputToken,
        uint256 maxInput,
        uint256 exactReturn
    ) internal returns (uint256) {
        IUniswapV3Router.ExactOutputSingleParams memory params = IUniswapV3Router.ExactOutputSingleParams({
            tokenIn: address(inputToken),
            tokenOut: address(outputToken),
            fee: uniswapFee,
            recipient: address(this),
            deadline: MAX_UINT,
            amountOut: exactReturn,
            amountInMaximum: maxInput,
            sqrtPriceLimitX96: 0
        });

        return uniswapV3Router.exactOutputSingle(params);
    }

    function _swapInputForExactOutputMultiHop(
        bytes memory tradePath,
        uint256 maxInput,
        uint256 exactReturn
    ) internal returns (uint256) {
        IUniswapV3Router.ExactOutputParams memory params = IUniswapV3Router.ExactOutputParams({
            path: tradePath,
            recipient: address(this),
            deadline: MAX_UINT,
            amountOut: exactReturn,
            amountInMaximum: maxInput
        });

        return uniswapV3Router.exactOutput(params);
    }

    function _divUp(uint256 n, uint256 d) internal pure returns (uint256) {
        return (n + d - 1) / d;
    }

    function _swapBalancerSingleSwap(
        IBalancerVault.SwapKind swapKind,
        bytes32 poolId,
        IERC20 inputToken,
        IERC20 outputToken,
        uint256 amount,
        uint256 limit
    ) internal returns (uint256) {
        // Build the SingleSwap struct
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap(
            poolId,
            swapKind,
            inputToken,
            outputToken,
            amount,
            ""
        );

        // Build the FundManagement struct
        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement(
            address(this),
            false,
            payable(this),
            false
        );

        return balancerVault.swap(singleSwap, fundManagement, limit, MAX_UINT);
    }

    function _swapBalancerBatchSwap(
        IBalancerVault.SwapKind swapKind,
        bytes32[] memory poolIds,
        IERC20[] memory assets,
        uint256 amount
    ) internal returns (uint256) {
        // build limits
        int256[] memory limits = new int256[](assets.length);
        for (uint256 i = 0; i < assets.length; ++i) {
            limits[i] = type(int256).max;
        }

        // build FundManagement struct
        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement(
            address(this),
            false,
            payable(this),
            false
        );

        // build BatchSwapStep struct
        IBalancerVault.BatchSwapStep[] memory batchSwapSteps = new IBalancerVault.BatchSwapStep[](poolIds.length);
        for (uint256 i = 0; i < poolIds.length; i++) {
            batchSwapSteps[i] = IBalancerVault.BatchSwapStep({
                poolId: poolIds[i],
                assetInIndex: swapKind == IBalancerVault.SwapKind.GIVEN_IN ? i : i + 1,
                assetOutIndex: swapKind == IBalancerVault.SwapKind.GIVEN_IN ? i + 1 : i,
                amount: i == 0 ? amount : 0,
                userData: ""
            });
        }

        uint256 balanceBefore = assets[assets.length - 1].balanceOf(address(this));
        balancerVault.batchSwap(swapKind, batchSwapSteps, assets, fundManagement, limits, MAX_UINT);
        uint256 balanceAfter = assets[assets.length - 1].balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }

    function _swapExactInSushi(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut
    ) internal returns (uint256) {
        uint256[] memory amounts = sushiRouter.swapExactTokensForTokens(
            amountIn,
            minOut,
            path,
            address(this),
            MAX_UINT
        );

        return amounts[amounts.length - 1]; // last element is the output
    }

    function _swapExactOutSushi(
        address[] memory path,
        uint256 amountOut,
        uint256 maxIn
    ) internal returns (uint256) {
        uint256[] memory amounts = sushiRouter.swapTokensForExactTokens(
            amountOut,
            maxIn,
            path,
            address(this),
            MAX_UINT
        );

        return amounts[0]; // first element is the input
    }
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
// interface IAsset is IERC20Metadata {
//     // solhint-disable-previous-line no-empty-blocks
// }

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IBalancerVault {
    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IERC20 assetIn;
        IERC20 assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IERC20[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IERC20[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IFlashLoanReceiver {
    function executeOperation(
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface ILiquidityPool {
    function updatedBorrowBy(address _borrower) external view returns (uint256);

    function borrow(uint256 _amount) external;

    function repay(uint256 _amount) external;

    function whitelistRepay(uint256 _amount) external;

    function flashLoan(
        address _receiver,
        uint256 _amount,
        bytes memory _params
    ) external;

    function getFlashLoanFeeFactor() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IMarket {
    function getCollateralFactor() external view returns (uint256);

    function setCollateralFactor(uint256 _collateralFactor) external;

    function getCollateralCap() external view returns (uint256);

    function setCollateralCap(uint256 _collateralCap) external;

    function collateralize(uint256 _amount) external;

    function collateral(address _borrower) external view returns (uint256);

    function borrowingLimit(address _borrower) external view returns (uint256);

    function setComptroller(address _comptroller) external;

    function setCollateralizationActive(bool _active) external;

    function sendCollateralToLiquidator(
        address _liquidator,
        address _borrower,
        uint256 _amount
    ) external;

    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Abstract Price Contract
/// @notice Handles the hassles of calculating the same price formula for each xAsset
/// @dev Not deployable. This has to be implemented by any xAssetPrice contract
abstract contract IPrice {
    /// @dev Specify the underlying asset of each xAssetPrice contract
    address public underlyingAssetAddress;
    address public underlyingPriceFeedAddress;
    address public usdcPriceFeedAddress;

    uint256 internal assetPriceDecimalMultiplier;
    uint256 internal usdcPriceDecimalMultiplier;

    uint256 private constant FACTOR = 1e18;
    uint256 private constant PRICE_DECIMALS_CORRECTION = 1e12;

    /// @notice Provides the amount of the underyling assets of xAsset held by the xAsset asset in wei
    function getAssetHeld() public view virtual returns (uint256);

    /// @notice Anyone can know how much certain xAsset is worthy in USDC terms
    /// @dev This relies on the getAssetHeld function implemented by each xAssetPrice contract
    /// @dev Prices are handling 12 decimals
    /// @return capacity (uint256) How much an xAsset is worthy on USDC terms
    function getPrice() external view returns (uint256) {
        uint256 assetHeld = getAssetHeld();
        uint256 assetTotalSupply = IERC20(underlyingAssetAddress).totalSupply();

        (
            uint80 roundIDUsd,
            int256 assetUsdPrice,
            ,
            uint256 timeStampUsd,
            uint80 answeredInRoundUsd
        ) = AggregatorV3Interface(underlyingPriceFeedAddress).latestRoundData();
        require(timeStampUsd != 0, "ChainlinkOracle::getLatestAnswer: round is not complete");
        require(answeredInRoundUsd >= roundIDUsd, "ChainlinkOracle::getLatestAnswer: stale data");
        uint256 usdPrice = (assetHeld * (uint256(assetUsdPrice)) * (assetPriceDecimalMultiplier)) / (assetTotalSupply);

        (
            uint80 roundIDUsdc,
            int256 usdcusdPrice,
            ,
            uint256 timeStampUsdc,
            uint80 answeredInRoundUsdc
        ) = AggregatorV3Interface(usdcPriceFeedAddress).latestRoundData();
        require(timeStampUsdc != 0, "ChainlinkOracle::getLatestAnswer: round is not complete");
        require(answeredInRoundUsdc >= roundIDUsdc, "ChainlinkOracle::getLatestAnswer: stale data");
        uint256 usdcPrice = ((usdPrice * (PRICE_DECIMALS_CORRECTION)) / (uint256(usdcusdPrice))) /
            (usdcPriceDecimalMultiplier);
        return usdcPrice;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

// Copied from:
// https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router {
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface ISushiRouter {
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
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWeth is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

/**
 Contract which implements locking of functions via a notLocked modifier
 Functions are locked per address. 
 */
contract BlockLock {
    // how many blocks are the functions locked for
    uint256 private constant BLOCK_LOCK_COUNT = 6;
    // last block for which this address is timelocked
    mapping(address => uint256) public lastLockedBlock;
    mapping(address => bool) public blockLockExempt;

    function _lock(address lockAddress) internal {
        if (!blockLockExempt[lockAddress]) {
            lastLockedBlock[lockAddress] = block.number + BLOCK_LOCK_COUNT;
        }
    }

    function _exemptFromBlockLock(address lockAddress) internal {
        blockLockExempt[lockAddress] = true;
    }

    function _removeBlockLockExemption(address lockAddress) internal {
        blockLockExempt[lockAddress] = false;
    }

    modifier notLocked(address lockAddress) {
        require(lastLockedBlock[lockAddress] <= block.number, "Address is temporarily locked");
        _;
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

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}