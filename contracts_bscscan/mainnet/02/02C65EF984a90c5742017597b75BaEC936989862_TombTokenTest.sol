/*
                                       BROUGHT TO YOU BY:

                                                   /$$      /$$ /$$$$$$$$ /$$      /$$ /$$$$$$$$
                                                  | $$$    /$$$| $$_____/| $$$    /$$$| $$_____/
  /$$$$$$   /$$$$$$$  /$$$$$$  /$$$$$$$   /$$$$$$ | $$$$  /$$$$| $$      | $$$$  /$$$$| $$
 /$$__  $$ /$$_____/ /$$__  $$| $$__  $$ /$$__  $$| $$ $$/$$ $$| $$$$$   | $$ $$/$$ $$| $$$$$
| $$$$$$$$| $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$  $$$| $$| $$__/   | $$  $$$| $$| $$__/
| $$_____/| $$      | $$  | $$| $$  | $$| $$  | $$| $$\  $ | $$| $$      | $$\  $ | $$| $$
|  $$$$$$$|  $$$$$$$|  $$$$$$/| $$  | $$|  $$$$$$/| $$ \/  | $$| $$$$$$$$| $$ \/  | $$| $$$$$$$$
 \_______/ \_______/ \______/ |__/  |__/ \______/ |__/     |__/|________/|__/     |__/|________/

                       BRINGING HIGH TECH TO THE MEME ECONOMY FOR 69 YEARS

                               DISTRIBUTED CONSENSUS TECHNOLOGIES
                                         economeme.net
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';


contract TombTokenTest is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    enum Phase {
        PREP,
        LAUNCH,
        RAMPUP,
        RELEASED
    }

    string private                          _name = "TombTEST";
    string private                        _symbol = "TOMBTEST";
    uint public                      burialFactor = 10;

    uint8 private                       _decimals = 9;
    uint256 private                       _supply = 100000000000 * (10 ** _decimals);

    address public constant           zeroAddress = address(0);
    address public constant           burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private constant                  MAX = ~uint256(0);
    // TODO: Update wallets
    address payable public              devWallet = payable(0x51eA5B16350FbE2DE2dE7F2C0025ca33171676EA);
    address payable public         treasuryWallet = payable(0x51eA5B16350FbE2DE2dE7F2C0025ca33171676EA);
    address payable public          rewardsWallet = payable(0x51eA5B16350FbE2DE2dE7F2C0025ca33171676EA);
    address payable public        liquidityWallet = payable(0x51eA5B16350FbE2DE2dE7F2C0025ca33171676EA);

    uint256 private                  _dummy_value = 1 * (10 ** _decimals);

    uint256 public   unreservedNativeTokenBalance;
    uint256 public         unreservedTokenBalance;
    uint256 public           reservedTokenBalance;

    // Fee Rate for liquidity
    uint256 public          liquidityFeeNumerator = 5;
    uint256 public        liquidityFeeDenominator = 100;
    uint256 public     liquidityFeeRatioNumerator;
    uint256 public       payableToLiquidityWallet;

    // Target 20% liquidity
    bool public                       autoLiquify = true;
    uint256 public    minimumAutoLiquifyThreshold = 1000 * 1 gwei;
    uint256 public           autoLiquifyThreshold = 1000000 * 1 gwei;
    uint256 public       liquidityTargetNumerator = 90;
    uint256 public     liquidityTargetDenominator = 100;
    uint256 public                AMMFeeNumerator = 25;
    uint256 public              AMMFeeDenominator = 1000;

    // Fee Rate for treasury
    uint256 public           treasuryFeeNumerator = 1;
    uint256 public         treasuryFeeDenominator = 100;
    uint256 public      treasuryFeeRatioNumerator;
    uint256 public        payableToTreasuryWallet;

    // Fee Rate for dev
    uint256 public                devFeeNumerator = 2;
    uint256 public              devFeeDenominator = 100;
    uint256 public           devFeeRatioNumerator;
    uint256 public             payableToDevWallet;

    // Fee Rate for rewards
    uint256 public            rewardsFeeNumerator = 0;
    uint256 public          rewardsFeeDenominator = 100;
    uint256 public       rewardsFeeRatioNumerator;
    uint256 public         payableToRewardsWallet;

    // Rate at which tokens will be liquidated (as a percent of tokens available in the dex).
    uint256 public               feeRateNumerator = 4;
    uint256 public             feeRateDenominator = 100;

    // Change This to increase or decrease the buy tax amounts in bulk.
    uint256 public        buyFeeModifierNumerator = 100;
    uint256 public      buyFeeModifierDenominator = 100;

    // Change This to increase or decrease the sell tax amounts in bulk.
    uint256 public       sellFeeModifierNumerator = 100;
    uint256 public     sellFeeModifierDenominator = 100;

    // Change this to increase or decrease the transfer tax amounts.
    uint256 public   transferFeeModifierNumerator = 0;
    uint256 public transferFeeModifierDenominator = 100;

    // Ratio denominator for splitting liquidated native tokens to different wallets
    uint256 public              totalFeeNumerator;
    uint256 public            totalFeeDenominator;
    uint256 public            feeRatioDenominator;
    uint256 public nativeTokenFeeRatioDenominator;


    IUniswapV2Router02 public       tradingRouter;
    mapping(address => bool) public
                 automatedMarketMakerTradingPairs;

    address public  nativeTokenTradingPairAddress;
    IUniswapV2Pair         nativeTokenTradingPair;

    bool public                    tradingEnabled = false;
    bool public                liquifyCollections = true;
    bool public               sendFeesToReceivers = true;

    bool private      _inCollectionsLiquification = false;

    uint256 public                     launchTime;
    uint256 public                     rampUpTime;
    uint256 public                   releasedTime;

    uint256 public              launchPhaseLength;
    uint256 public              rampUpPhaseLength;

    uint256 public                 launchTXNLimit = _supply.mul(25).div(10000); // 0.25%
    uint256 public               releasedTXNLimit = _supply.mul(5).div(100);    // 5%

    uint256 public              launchWalletLimit = _supply.mul(1).div(100);    // 1%
    uint256 public            releasedWalletLimit = _supply.mul(5).div(100);    // 5%

    uint256 public         launchBuyCooldownTimer;
    uint256 public            launchGasPriceLimit = 20 * 1 gwei;
    bool public          fairMarketLimitsInEffect = true;

    Phase public                            phase = Phase.PREP;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) _excludedFromFees;
    mapping(address => bool) _excludedFromTransfer;
    mapping(address => bool) _excludedFromTXNLimits;
    mapping(address => bool) _excludedFromWalletLimits;
    mapping(address => bool) _excludedFromAllLimitations;

    // Anti bot checks
    mapping(address => uint256) private _walletLastTransferBlock;
    mapping(address => uint256) private _walletLastTransferTimestamp;

    mapping(address => bool) isEconoMEMEToken;

    event SwapTokensForETH(uint256 amountIn, address[] path);
    event FeesDispersed(uint256 expected, uint256 actual);

    event ContractInitialized();
    event TradingEnabled();
    event TokenEnteredPrepPhase();
    event TokenEnteredLaunchPhase();
    event TokenEnteredRampUpPhase();
    event TokenEnteredReleasedPhase();

    event AutoLiquifyEnabled();
    event AutoLiquifyDisabled();

    event FairMarketLimitsEnabled();
    event FairMarketLimitsDisabled();

    event TradingPairRegistered(address pair);
    event TradingPairDeRegistered(address pair);

    event TreasuryFeeUpdated(uint256 numerator, uint256 denominator);
    event DevFeeUpdated(uint256 numerator, uint256 denominator);
    event LiquidityFeeUpdated(uint256 numerator, uint256 denominator);
    event RewardsFeeUpdated(uint256 numerator, uint256 denominator);

    event SellFeeModifierUpdated(uint256 numerator, uint256 denominator);
    event BuyFeeModifierUpdated(uint256 numerator, uint256 denominator);
    event TransferFeeModifierUpdated(uint256 numerator, uint256 denominator);
    event CollectionsLiquidationRateUpdated(uint256 numerator, uint256 denominator);
    event LiquidityTargetUpdated(uint256 numerator, uint256 denominator);

    event TreasuryWalletChange(address oldWallet, address newWallet);
    event DevWalletChange(address oldWallet, address newWallet);
    event LiquidityWalletChange(address oldWallet, address newWallet);
    event RewardsWalletChange(address oldWallet, address newWallet);

    event EconoMEMETokenRegistered(address token);
    event EconoMEMETokenDeRegistered(address token);

    event UnfairLaunchSniper(address wallet);
    event UnfairGasUsedAtLaunch(address wallet);

    event UnfairBlockSendTransaction(address wallet);
    event UnfairBlockReceiveTransaction(address wallet);
    event UnfairBlockOriginTransaction(address wallet);

    modifier internalCollectionsLiquification () {
        _inCollectionsLiquification = true;
        _;
        _inCollectionsLiquification = false;
    }

    modifier feeRecipientOrOwner () {
        require(
            msg.sender == owner()
            || msg.sender == address(treasuryWallet)
            || msg.sender == address(devWallet)
            || msg.sender == address(liquidityWallet)
            || msg.sender == address(rewardsWallet)
        );
        _;
    }

    constructor () {
        _balances[owner()] = _supply.div(2);
        reservedTokenBalance = _supply.sub(_balances[owner()]);

        _excludedFromFees[owner()] = true;
        _excludedFromFees[address(this)] = true;

        emit Transfer(zeroAddress, address(this), reservedTokenBalance);
        emit Transfer(zeroAddress, owner(), _balances[owner()]);
        emit TokenEnteredPrepPhase();
    }

    receive() external payable {
        unreservedNativeTokenBalance.add(msg.value);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][msg.sender].sub(
                amount,
                'ERC20: transfer amount exceeds allowance'
            )
        );
        return true;
    }

    function initContract (uint256 _launchPhaseLength, uint256 _rampUpPhaseLength, uint256 _launchBuyCooldownTimer) external onlyOwner {
        require(phase == Phase.PREP, "Already initialized");
        launchPhaseLength = _launchPhaseLength;
        rampUpPhaseLength = _rampUpPhaseLength;
        launchBuyCooldownTimer = _launchBuyCooldownTimer;

        // PancakeSwap: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // Uniswap V2: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        tradingRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        nativeTokenTradingPairAddress = IUniswapV2Factory(tradingRouter.factory()).createPair(
            address(this),
            tradingRouter.WETH()
        );

        _setAutomatedMarketMakerPair(nativeTokenTradingPairAddress, true);
        nativeTokenTradingPair = IUniswapV2Pair(nativeTokenTradingPairAddress);
        updateFeeRatios();

        emit TreasuryFeeUpdated(treasuryFeeNumerator, treasuryFeeDenominator);
        emit TreasuryWalletChange(zeroAddress, address(treasuryWallet));

        emit DevFeeUpdated(devFeeNumerator, devFeeDenominator);
        emit DevWalletChange(zeroAddress, address(devWallet));

        emit LiquidityFeeUpdated(liquidityFeeNumerator, liquidityFeeDenominator);
        emit LiquidityWalletChange(zeroAddress, address(liquidityWallet));

        emit RewardsFeeUpdated(rewardsFeeNumerator, rewardsFeeDenominator);
        emit RewardsWalletChange(zeroAddress, address(rewardsWallet));

        emit BuyFeeModifierUpdated(buyFeeModifierNumerator, buyFeeModifierDenominator);
        emit SellFeeModifierUpdated(sellFeeModifierNumerator, sellFeeModifierDenominator);
        emit TransferFeeModifierUpdated(transferFeeModifierNumerator, transferFeeModifierDenominator);

        emit ContractInitialized();
    }

    function enableTrading () external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        require(balanceOf(nativeTokenTradingPairAddress) > 0, "Liquidity not provided yet");

        tradingEnabled = true;
        launchTime = block.timestamp;
        phase = Phase.LAUNCH;
        emit TradingEnabled();
        emit TokenEnteredLaunchPhase();
    }

    function registerEconoMEMEToken(address token) external onlyOwner {
        isEconoMEMEToken[token] = true;
        emit EconoMEMETokenRegistered(token);
    }

    function deregisterEconoMEMEToken(address token) external onlyOwner {
        isEconoMEMEToken[token] = false;
        emit EconoMEMETokenDeRegistered(token);
    }

    function isTokenInEconoMEME(address token) external view returns (bool) {
        return isEconoMEMEToken[token];
    }

    function addToTokenReserve(uint256 _amount) external {
        _transferExactTokens(msg.sender, address(this), _amount);
        reservedTokenBalance = reservedTokenBalance.add(_amount);
    }

    function buryTokens(address _token, uint256 _amount) external {
        require(isEconoMEMEToken[_token], "Not in the econoMEME");

        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, burnAddress, _amount);
        _transferExactTokens(address(this), msg.sender, _amount.div(burialFactor));
        reservedTokenBalance = reservedTokenBalance.sub(_amount);
    }

    function enableCollectionsLiquification () external onlyOwner {
        liquifyCollections = true;
    }

    function disableCollectionsLiquification () external onlyOwner {
        liquifyCollections = false;
    }

    function enableAutoLiquification() external onlyOwner {
        autoLiquify = true;
        emit AutoLiquifyDisabled();
    }

    function disableAutoLiquification() external onlyOwner {
        autoLiquify = false;
        emit AutoLiquifyDisabled();
    }

    function enableSendingFeesToReceivers () external onlyOwner {
        sendFeesToReceivers = true;
    }

    function disableSendingFeesToReceivers () external onlyOwner {
        sendFeesToReceivers = false;
    }

    function enableFairMarketLimits() external onlyOwner {
        fairMarketLimitsInEffect = true;
        emit FairMarketLimitsEnabled();
    }

    function disableFairMarketLimits() external onlyOwner {
        fairMarketLimitsInEffect = false;
        emit FairMarketLimitsDisabled();
    }

    function excludeFromFees(address wallet) external onlyOwner {
        _excludedFromFees[wallet] = true;
    }

    function includeInFees(address wallet) external onlyOwner {
        delete _excludedFromFees[wallet];
    }

    function excludeFromTXNLimit(address wallet) external onlyOwner {
        _excludedFromTXNLimits[wallet] = true;
    }

    function includeInTXNLimit(address wallet) external onlyOwner {
        delete _excludedFromTXNLimits[wallet];
    }

    function isExcludedFromTXNLimit(address wallet) external view returns (bool) {
        return _excludedFromTXNLimits[wallet];
    }

    function excludeFromWalletLimit(address wallet) external onlyOwner {
        _excludedFromWalletLimits[wallet] = true;
    }

    function includeInWalletLimit(address wallet) external onlyOwner {
        delete _excludedFromWalletLimits[wallet];
    }

    function isExcludedFromWalletLimit(address wallet) external view returns (bool) {
        return _excludedFromWalletLimits[wallet];
    }

    function excludedFromAllLimitations(address wallet) external onlyOwner {
        _excludedFromAllLimitations[wallet] = true;
    }

    function includeInAllLimitations(address wallet) external onlyOwner {
        delete _excludedFromAllLimitations[wallet];
    }

    function setCollectionsLiquidationRate(uint256 numerator, uint256 denominator) external onlyOwner {
        require(
            _dummy_value.mul(numerator).div(denominator) <
            _dummy_value.mul(feeRateNumerator).div(feeRateDenominator)
        );

        require(denominator != uint256(0));

        feeRateNumerator = numerator;
        feeRateDenominator = denominator;

        emit CollectionsLiquidationRateUpdated(numerator, denominator);
    }

    function setLiquidityTarget(uint256 numerator, uint256 denominator) external onlyOwner {
        require(denominator != 0);

        liquidityTargetNumerator = numerator;
        liquidityTargetDenominator = denominator;

        emit LiquidityTargetUpdated(numerator, denominator);

    }

    function setAutoLiquifyThreshold(uint256 amount) external onlyOwner {
        require(autoLiquifyThreshold >= (minimumAutoLiquifyThreshold));
        autoLiquifyThreshold = amount;
    }

    function setBuyFeeModifier(uint256 numerator, uint256 denominator) external onlyOwner {
        require(
            _dummy_value.mul(numerator).div(denominator) <
            _dummy_value.mul(buyFeeModifierNumerator).div(buyFeeModifierDenominator)
        );

        require(denominator != uint256(0));

        buyFeeModifierNumerator = numerator;
        buyFeeModifierDenominator = denominator;

        emit BuyFeeModifierUpdated(numerator, denominator);
    }

    function setSellFeeModifier(uint256 numerator, uint256 denominator) external onlyOwner {
        require(
            _dummy_value.mul(numerator).div(denominator) <
            _dummy_value.mul(sellFeeModifierNumerator).div(sellFeeModifierDenominator)
        );

        require(denominator != uint256(0));

        sellFeeModifierNumerator = numerator;
        sellFeeModifierDenominator = denominator;

        emit SellFeeModifierUpdated(numerator, denominator);
    }

    function setTransferFeeModifier(uint256 numerator, uint256 denominator) external onlyOwner {
        require(
            _dummy_value.mul(numerator).div(denominator) <
            _dummy_value.mul(transferFeeModifierNumerator).div(transferFeeModifierDenominator)
        );

        require(denominator != uint256(0));

        transferFeeModifierNumerator = numerator;
        transferFeeModifierDenominator = denominator;

        emit TransferFeeModifierUpdated(numerator, denominator);

    }

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        emit DevWalletChange(address(treasuryWallet), _treasuryWallet);
        treasuryWallet = payable(_treasuryWallet);

    }

    function setTreasuryFee(uint256 numerator, uint256 denominator) external onlyOwner {
        require(
            _dummy_value.mul(numerator).div(denominator) <
            _dummy_value.mul(treasuryFeeNumerator).div(treasuryFeeDenominator)
        );

        require(denominator != uint256(0));

        treasuryFeeNumerator = numerator;
        treasuryFeeDenominator = denominator;

        updateFeeRatios();
        emit TreasuryFeeUpdated(numerator, denominator);
    }

    function setDevWallet(address _devWallet) external onlyOwner {
        emit DevWalletChange(address(devWallet), _devWallet);
        devWallet = payable(_devWallet);
    }

    function setDevFee(uint256 numerator, uint256 denominator) external onlyOwner {
        require(
            _dummy_value.mul(numerator).div(denominator) <
            _dummy_value.mul(devFeeNumerator).div(devFeeDenominator)
        );

        require(denominator != uint256(0));

        devFeeNumerator = numerator;
        devFeeDenominator = denominator;

        updateFeeRatios();
        emit DevFeeUpdated(numerator, denominator);
    }

    function setRewardWallet(address _rewardWallet) external onlyOwner {
        emit RewardsWalletChange(address(rewardsWallet), _rewardWallet);
        rewardsWallet = payable(_rewardWallet);
    }

    function setRewardFee(uint256 numerator, uint256 denominator) external onlyOwner {
        require(
            _dummy_value.mul(numerator).div(denominator) <
            _dummy_value.mul(rewardsFeeNumerator).div(rewardsFeeDenominator)
        );

        require(denominator != uint256(0));

        rewardsFeeNumerator = numerator;
        rewardsFeeDenominator = denominator;

        updateFeeRatios();
        emit RewardsFeeUpdated(numerator, denominator);
    }

    function setLiquidityWallet(address _liquidityWallet) external onlyOwner {
        emit LiquidityWalletChange(address (liquidityWallet), _liquidityWallet);
        liquidityWallet = payable(_liquidityWallet);
    }

    function setLiquidityFee(uint256 numerator, uint256 denominator) external onlyOwner {
        require(
            _dummy_value.mul(numerator).div(denominator) <
            _dummy_value.mul(liquidityFeeNumerator).div(liquidityFeeDenominator)
        );

        require(denominator != uint256(0));

        liquidityFeeNumerator = numerator;
        liquidityFeeDenominator = denominator;

        updateFeeRatios();
        emit LiquidityFeeUpdated(numerator, denominator);
    }

    function emergencyWithdraw() external feeRecipientOrOwner {
        sendNativeTokenToFeeReceivers();
    }

    function emergencyWithdrawTokens( address token) external onlyOwner {
        require(token != address(this), "Owner cannot withdraw this token balance");
        require(!automatedMarketMakerTradingPairs[token], "Owner cannot withdraw LP tokens");

        IERC20 strandedToken = IERC20(token);
        strandedToken.transfer(owner(), strandedToken.balanceOf(address(this)));
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view override returns (uint256) {
        return _supply;
    }

    // Provisionally adding to determine how often we accidentally blacklist someone
    function allowToTransfer(address wallet) external onlyOwner {
        _excludedFromTransfer[wallet] = false;
    }

    function isExcludedFromTransfers(address wallet) external view returns (bool) {
        return _excludedFromTransfer[wallet];
    }

    function isExcludedFromFees(address wallet) public view returns(bool) {
        return _excludedFromFees[wallet];
    }

    function setAutomatedMarketMakerPair(address _pair, bool value) external onlyOwner {
        _setAutomatedMarketMakerPair(_pair, value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != zeroAddress, "ERC20: approve from the zero address");
        require(spender != zeroAddress, "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        uint256 _feeNumerator;
        uint256 _feeDenominator;

        if (isSwapSell(to)) {
            // Owner exception required to be able to add liquidity pre launch
            require(tradingEnabled || msg.sender == owner() || from == owner(), "Trading disabled");

            if (!_inCollectionsLiquification && liquifyCollections) {
                resolveFeeCollection();
            }

            _feeNumerator = sellFeeModifierNumerator;
            _feeDenominator = sellFeeModifierDenominator;

        } else if (isSwapBuy(from)) {
            require(tradingEnabled || msg.sender == owner() || from == owner(), "Trading disabled");

            _feeNumerator = buyFeeModifierNumerator;
            _feeDenominator = buyFeeModifierDenominator;

            //antibot
            if (block.timestamp == launchTime) {
                _excludedFromTransfer[to] = true;
                emit UnfairLaunchSniper(to);
            }

            if (autoLiquify && payableToLiquidityWallet >= autoLiquifyThreshold) {
                _addLiquidity();
            }

            require(
                block.timestamp >= _walletLastTransferTimestamp[tx.origin].add(
                    phase == Phase.LAUNCH ? launchBuyCooldownTimer : uint256(0)
                ),
                "!TOOFAST"
            );
            _walletLastTransferTimestamp[tx.origin] = block.timestamp;

            // Transfer
        } else {
            _feeNumerator = transferFeeModifierNumerator;
            _feeDenominator = transferFeeModifierDenominator;
        }

        if (_excludedFromFees[to] || _excludedFromFees[from]) {
            _feeNumerator = uint256(0);
        }

        _transferTokens(from, to, amount, _feeNumerator, _feeDenominator);
    }

    function _setAutomatedMarketMakerPair(address _pair, bool value) private {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);

        // minimal check to prevent this method from being
        // used to include non contract addresses in swap fees
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        automatedMarketMakerTradingPairs[_pair] = value;

        if (value) {
            emit TradingPairRegistered(_pair);
        } else {
            emit TradingPairDeRegistered(_pair);
        }
    }

    function sendNativeTokenToFeeReceivers() private {

        payableToTreasuryWallet = payableToTreasuryWallet.add(unreservedNativeTokenBalance.mul(treasuryFeeRatioNumerator).div(feeRatioDenominator));
        payableToRewardsWallet = payableToRewardsWallet.add(unreservedNativeTokenBalance.mul(rewardsFeeRatioNumerator).div(feeRatioDenominator));
        payableToLiquidityWallet = payableToLiquidityWallet.add(unreservedNativeTokenBalance.mul(liquidityFeeRatioNumerator).div(feeRatioDenominator));
        payableToDevWallet = payableToDevWallet.add(unreservedNativeTokenBalance.mul(devFeeRatioNumerator).div(feeRatioDenominator));

        uint256 totalPaid;
        uint256 totalPayable = payableToTreasuryWallet.add(payableToRewardsWallet).add(payableToLiquidityWallet).add(payableToDevWallet);
        unreservedNativeTokenBalance = unreservedNativeTokenBalance.sub(totalPayable);

        bool success;

        if (payableToTreasuryWallet > 0) {
            (success, ) = treasuryWallet.call{ value: payableToTreasuryWallet }('');
            if (success) {
                totalPaid = totalPaid.add(payableToTreasuryWallet);
                payableToTreasuryWallet = uint256(0);
            }
        }

        if (payableToRewardsWallet > 0) {
            (success, ) = rewardsWallet.call{ value: payableToRewardsWallet }('');
            if (success) {
                totalPaid = totalPaid.add(payableToRewardsWallet);
                payableToRewardsWallet = uint256(0);
            }
        }

        if (
            payableToLiquidityWallet > 0
        ) {
            bool sendToliquidityWallet;

            if (!autoLiquify) {
                sendToliquidityWallet = true;
            } else {
                (uint256 reserveTokens, uint256 reserveNative,) = nativeTokenTradingPair.getReserves();

                uint256 mcap = _supply.mul(reserveNative).div(reserveTokens);
                if (
                    mcap.mul(liquidityTargetNumerator).div(liquidityTargetDenominator) > reserveNative
                ) {
                    sendToliquidityWallet = true;
                } else {
                    sendToliquidityWallet = false;
                }
            }

            if (sendToliquidityWallet) {
                (success, ) = liquidityWallet.call{ value: payableToLiquidityWallet}('');
                if (success) {
                    totalPaid = totalPaid.add(payableToLiquidityWallet);
                    payableToLiquidityWallet = uint256(0);
                }
            }
        }

        if (payableToDevWallet > 0) {
            (success, ) = devWallet.call{ value: payableToDevWallet }('');
            if (success) {
                totalPaid = totalPaid.add(payableToDevWallet);
                payableToDevWallet = uint256(0);
            }
        }

        emit FeesDispersed(totalPayable, totalPaid);
    }

    function isSwapBuy(address from) private view returns(bool) {
        return automatedMarketMakerTradingPairs[from];
    }

    function isSwapSell(address to) private view returns(bool) {
        return automatedMarketMakerTradingPairs[to];
    }

    function _transferExactTokens(address from, address to, uint256 amount) private {
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function _transferTokens(address from, address to, uint256 amount, uint256 fee_ratio_numerator, uint256 fee_ratio_denominator) private {
        require(!_excludedFromTransfer[from]);
        require(!_excludedFromTransfer[to]);
        require(!_excludedFromTransfer[msg.sender]);
        require(!_excludedFromTransfer[tx.origin]);

        uint256 _feeAmount = feeAmountForNativeToken(amount, fee_ratio_numerator, fee_ratio_denominator);
        uint256 _transferAmount = amount.sub(_feeAmount);

        _balances[from] = _balances[from].sub(amount);
        _balances[address(this)] = _balances[address(this)].add(_feeAmount);
        _balances[to] = _balances[to].add(_transferAmount);

        unreservedTokenBalance = unreservedTokenBalance.add(_feeAmount);

        if (phase == Phase.LAUNCH) {
            if (block.timestamp > launchTime.add(launchPhaseLength)) {
                phase = Phase.RAMPUP;
                rampUpTime = block.timestamp;
                emit TokenEnteredRampUpPhase();
            }
        } else if (phase == Phase.RAMPUP) {
            if (block.timestamp > launchTime.add(rampUpPhaseLength)) {
                phase = Phase.RELEASED;
                releasedTime = block.timestamp;
                emit TokenEnteredReleasedPhase();
            }
        }

        // Only apply wallet and txn limits to transactions not involving the contract itself;
        // This will allow the contract to amass more that the maxWalletLimit tokens
        // and it can transfer (sell) more than the maxTXNLimit
        if (
            !(
                // these are the circumstances that should exclude
                from == address(this)
                || to == address(this)
                || to == burnAddress
                || from == owner()
                || to  == owner()
                || _excludedFromAllLimitations[from]
                || _excludedFromAllLimitations[to]
                || _inCollectionsLiquification
            )
        ) {
            if (!_excludedFromTXNLimits[from]) {
                uint256 maxTXNLimit = _calculateMaxTXNLimit();
                require(amount <= maxTXNLimit, "!MAXTXN");
            }

            if (
                !_excludedFromWalletLimits[to]
                && !automatedMarketMakerTradingPairs[to]
            ) {
                uint256 maxWalletLimit = _calculateMaxWalletLimit();
                require(_balances[to] <= maxWalletLimit, "!MAXWALLET");
            }

            if (fairMarketLimitsInEffect) {
                // Gas limit only applies to launch
                // If people want to use a high gas limit in general that's their business
                if (tx.gasprice > (phase == Phase.LAUNCH ? launchGasPriceLimit : MAX)) {
                    _excludedFromTransfer[to] = true;
                    emit UnfairGasUsedAtLaunch(to);
                }

                // However post launch there is no need to run more than one transaction per block
                // unless you are trying to sandwich someone's transactions.
                // Not allowed!
                if (!automatedMarketMakerTradingPairs[from]) {
                    if (_walletLastTransferBlock[from] == block.number) {
                        _excludedFromTransfer[from] = true;
                        emit UnfairBlockSendTransaction(from);
                    }
                    _walletLastTransferBlock[from] = block.number;
                }

                if (!automatedMarketMakerTradingPairs[to]) {
                    if (_walletLastTransferBlock[to] != block.number) {
                        _excludedFromTransfer[to] = true;
                        emit UnfairBlockReceiveTransaction(to);
                    }
                    _walletLastTransferBlock[to] = block.number;
                }

                if (_walletLastTransferBlock[tx.origin] == block.number) {
                    _excludedFromTransfer[tx.origin] = true;
                    emit UnfairBlockOriginTransaction(tx.origin);
                }
                _walletLastTransferBlock[tx.origin] = block.number;
            }
        }

        emit Transfer(from, to, _transferAmount);
    }

    function _calculateMaxTXNLimit() private view returns (uint256) {
        if (phase == Phase.RELEASED) {
            return releasedTXNLimit;
        } else if (phase == Phase.LAUNCH) {
            return launchTXNLimit;
        } else if (phase == Phase.RAMPUP) {
            uint256 secondsSinceLaunch = block.timestamp.sub(launchTime);

            return launchTXNLimit.add(
                releasedTXNLimit.sub(
                    launchTXNLimit
                ).mul(
                    secondsSinceLaunch
                ).div(
                    rampUpPhaseLength
                )
            );

        } else {
            // In prep phase we may transfer as much as we like;
            return _supply;
        }
    }

    function _calculateMaxWalletLimit() private view returns (uint256) {
        if (phase == Phase.RELEASED) {
            return releasedWalletLimit;
        } else if (phase == Phase.LAUNCH) {
            return launchWalletLimit;
        } else if (phase == Phase.RAMPUP) {
            uint256 secondsSinceLaunch = block.timestamp.sub(launchTime);

            return launchWalletLimit.add(
                releasedWalletLimit.sub(
                    launchWalletLimit
                ).mul(
                    secondsSinceLaunch
                ).div(
                    rampUpPhaseLength
                )
            );
        } else {
            // In prep phase we may transfer as much as we want;
            return _supply;
        }
    }

    function feeAmountForNativeToken(uint256 amount, uint256 _feeRatioNumerator, uint256 _feeRatioDenominator) private view returns (uint256) {
        // Early return if no fee is to be collected
        if (_feeRatioNumerator == uint256(0)) {
            return uint256(0);
        }

        return amount.mul(
            totalFeeNumerator
        ).div(
            totalFeeDenominator
        ).mul(
            _feeRatioNumerator
        ).div(
            _feeRatioDenominator
        );
    }

    function calculateRewardsFee(uint256 amount) private view returns(uint256) {
        return amount.mul(rewardsFeeNumerator).div(rewardsFeeDenominator);
    }

    function calculateTreasuryFee(uint256 amount) private view returns(uint256) {
        return amount.mul(treasuryFeeNumerator).div(treasuryFeeDenominator);
    }

    function calculateDevFee(uint256 amount) private view returns(uint256) {
        return amount.mul(devFeeNumerator).div(devFeeDenominator);
    }

    function calculateLiquidityFee(uint256 amount) private view returns(uint256) {
        return amount.mul(liquidityFeeNumerator).div(liquidityFeeDenominator);
    }

    function resolveFeeCollection() private internalCollectionsLiquification {
        uint256 pairFeeRatioTokens = balanceOf(nativeTokenTradingPairAddress).mul(feeRateNumerator).div(feeRateDenominator);
        uint256 tokensToSwap = unreservedTokenBalance > pairFeeRatioTokens ? pairFeeRatioTokens : unreservedTokenBalance;

        unreservedTokenBalance = unreservedTokenBalance.sub(tokensToSwap);

        swapTokensForNativeToken(tokensToSwap);

        if (sendFeesToReceivers) {
            sendNativeTokenToFeeReceivers();
        }
    }

    function swapTokensForNativeToken(uint256 tokens) private {
        if (tokens == uint256(0)) {
            return;
        }

        // generate the pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = tradingRouter.WETH();

        _approve(address(this), address(tradingRouter), tokens);

        uint256 previousNativeTokenBalance = address(this).balance;

        // make the swap
        tradingRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0, // accept any amount of Native Tokens
            path,
            address(this), // The contract
            block.timestamp
        );

        unreservedNativeTokenBalance = unreservedNativeTokenBalance.add(
            address(this).balance.sub(previousNativeTokenBalance)
        );

        emit SwapTokensForETH(tokens, path);
    }

    function addLiquidity() external payable {
        payableToLiquidityWallet = payableToLiquidityWallet.add(msg.value);
        _addLiquidity();
    }

    function _addLiquidity() private {
        uint256 amountForTokens = payableToLiquidityWallet.div(2);
        uint256 amountForNative = payableToLiquidityWallet.sub(amountForTokens);

        if (amountForTokens > 0 && amountForNative > 0) {
            uint256 startingBalance = address(this).balance;
            uint256 startingTokenBalance = balanceOf(address(this));

            buyTokens(amountForTokens, _calculateMinTokens(amountForTokens));

            // Newly purchased tokens
            uint256 tokensToAdd = balanceOf(address(this)).sub(startingTokenBalance);

            // approve token transfer to cover all possible scenarios
            _approve(address(this), address(tradingRouter), tokensToAdd);

            // add the liquidity
            tradingRouter.addLiquidityETH{value: amountForNative}(
                address(this),
                tokensToAdd,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                liquidityWallet,
                block.timestamp
            );

            payableToLiquidityWallet = payableToLiquidityWallet.sub(startingBalance.sub(address(this).balance));
        }
    }

    function _calculateMinTokens(uint256 nativeAmount) private view returns(uint256) {
        uint256 nativePurchaseAmount = nativeAmount.sub(
            nativeAmount.mul(AMMFeeNumerator).div(AMMFeeDenominator)
        );

        (uint256 tokenReserve, uint256 nativeTokenReserve,) = nativeTokenTradingPair.getReserves();

        return tokenReserve.sub(tokenReserve.mul(nativeTokenReserve).div(nativeTokenReserve.add(nativePurchaseAmount)));
    }

    function buyTokens(uint256 amount, uint256 minTokens) private {
        address[] memory path = new address[](2);
        path[0] = tradingRouter.WETH();
        path[1] = address(this);

        // make the swap
        tradingRouter.swapExactETHForTokens{value: amount}(
            minTokens,
            path,
            address(this),
            block.timestamp
        );
    }

    function updateFeeRatios() private {
        // multiple of all denominators
        totalFeeDenominator = liquidityFeeDenominator.mul(rewardsFeeDenominator).mul(devFeeDenominator).mul(treasuryFeeDenominator);

        // scaled up numerators to the totalFeeDenominator
        liquidityFeeRatioNumerator = liquidityFeeNumerator.mul(totalFeeDenominator).div(liquidityFeeDenominator);
        treasuryFeeRatioNumerator = treasuryFeeNumerator.mul(totalFeeDenominator).div(treasuryFeeDenominator);
        rewardsFeeRatioNumerator = rewardsFeeNumerator.mul(totalFeeDenominator).div(rewardsFeeDenominator);
        devFeeRatioNumerator = devFeeNumerator.mul(totalFeeDenominator).div(devFeeDenominator);

        // a denominator that gives the fraction of a whole that each xxxFeeRatioNumerator is
        feeRatioDenominator = liquidityFeeRatioNumerator.add(
            treasuryFeeRatioNumerator
        ).add(
            rewardsFeeRatioNumerator
        ).add(
            devFeeRatioNumerator
        );

        // The feeRatioDenominator is also the totalled numerator wrt to totalFeeDenominator
        totalFeeNumerator = feeRatioDenominator;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}