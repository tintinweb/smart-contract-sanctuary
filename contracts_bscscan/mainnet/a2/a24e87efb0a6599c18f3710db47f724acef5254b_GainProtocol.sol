//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

import "./IGainSweepstakes.sol";
import "./IGainProtocol.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./AggregatorV3Interface.sol";
import "./GainPriceFeed.sol";

/**
 * Mechanisms:
 *   1. Taxes - Taxes are taken from seller and buyers, not from transaction. for example, if A transfers 100 GP to B,
 *       A balance will be reduced by 103.5, and
 *      B account will receive 96.5 GP. (excluding static reward of course)
 *   2. Dynamic/Automatic liquidity - Auto LP is a mechanism to tax a certain amount of tax (2% for GP), and when it
 *      adds up to a certain amount sell half of it for BNB, and take both half and add to liquidity. GP fixed this
 *      mechanism, which was applied in previous protocols in two ways:
 *      1. GP always checks for available BNB in contract account, and adds them to liquidity as well, and by doing
 *         so, fix an issue which caused a LOT of BNB to be accumulated in the contract balance.
 *      2. GP moves the LP tokens to the contract account, which locks them forever
 *         Also, GP introduce dynamic liquidity. which can be used when there is too much liquidity in the LP.
 *         this is determined by setting bounds for liquidity (start, end) for total tokens.
 *         too much liquidity (should) mean a lot of accounts are selling their GAINs (or we are adding liquidity
 *         where it's no longer needed)
 *         so remove liquidity (which will give us BNBs and GAINs), then buy GAINs with the BNBs.
 *         This gives us a side effect of raising GAIN price (which balances out the sells for auto LP)
 *         and we use the resulting GAINs to reward all users (reflection).
 *         So basically - what we do here is use the tax we collected (which was put into the liquidity)
 *         when no longer needed to help our holders.
 *         This can be viewed as some kind of insurance - we collect a fee when everything is great
 *         but when dark days come, we use that money to help out holders to keep their profits
 *   3. Whale protection - In other contracts, we've all seen the following situation: the price rises
 *      (or even worse - crashes), then some big holder decides to dump all their funds, almost at once,
 *      which crashes the price..
 *      We think that with great power, comes great responsibly [uncle ben], and to help incentivize whales to act responsibly
 *      we've added a tax (maximum 25%) which is taken from anybody doing too much transfers per day (determined as)
 *      a percent from LP. if someone sells more then 2% of the LP per day, he will be taxed. taxes rate are exponential
 *      relative to total amount transferred relative to LP.
 *   4. Hodl rewards - GP gives back to loyal holders, 0.25% of seller tax is given to accounts that haven't sell
 *      anything yet. As long as the account hodl, he will get this reward (and as it's expected that less
 *      accounts will hodl, the 0.25% reward will be shared by less accounts).
 *   5. Associate account (connect) - Taxes are what makes GP tick, but there is a side effect: they can prevent trade.
 *      This is often the case for user who purchased the token from PCS, and want to move it to some exchange, but are
 *      reluctant to do so due to fees. To help trade happen, each user can define ONE and only ONE associate account which all
 *      transfers to will be excluded from tax. Please note that associate transfers will not be rewarded with
 *      hodl reward, and also won't cancel hodl eligibility from sender.
 *   6. Charity - GP takes 0.25% from each sell to give to charity, this is limited by dailyCharityLimitUSD $ per day.
 *   7. Sweepstake - GP conducts a sweepstake each day to give to holders with 7 different criteria.
 *       Please review GainSweepstakes.sol
 *   8. Static rewards - Each sell is taxed with 3% fee, which is delivered to all existing holders.
 *   9. Team tax - Every buy transaction is taxed 0.1% which will be taken for the team to keep them motivated and
 *      fully focused on the project. this is taken ONLY from buys, and not sells to make sure the team goals are
 *      aligned with the community.
 */

contract GainProtocol is IGainProtocol, Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    struct Owner {
        uint64 lockedStartTime; // Timestamp - when was funds locking started
        uint64 lockedEndTime; // Timestamp - when will funds locking ends
        uint64 dailyTransferLastUpdatedDay; // Timestamp - when was daily transfer count last updated
        bool excludedFromHodlReward; // Is eligible for hodl reward
        uint96 dailyTransfers; // amount of token transferred today - up to TOKEN_TOTAL (which is limited to 70bit)
        uint96 hodlTokens; // hodl tokens reward - up to TOKEN_TOTAL (which is limited to 70bit)
        uint256 balance;
        uint256 lockedBalance; // Funds locked (used after winning sweepstake - in reflection units)
    }

    struct Fees {
        // Used to avoid stack too deep
        uint256 liquidity;
        uint256 sweepstake;
        uint256 charity;
        uint256 reward;
        uint256 hodl;
        uint256 team;
        uint256 whaleProtection;
    }

    struct FeesPercentage {
        // Used to avoid stack too deep
        uint256 liquidity;
        uint256 sweepstake;
        uint256 charity;
        uint256 reward;
        uint256 hodl;
        uint256 team;
        uint256 whaleProtection;
    }

    // Constants
    string private constant NAME = "GainProtocol";
    string private constant SYMBOL = "GAIN";
    // Returns the number of decimals the token uses
    // e.g. 9, means to divide the token amount by 1000000000 to get its user representation.
    uint8 private constant DECIMALS = 9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant TOKEN_TOTAL = 1 * 10**12 * 10**9; // 1T (1,000,000,000,000)
    uint256 private constant PERCENT_DIVIDER_FACTOR = 10**4;
    uint256 private constant EXPONENT_PERCENT_DIVIDER = 10**2;
    uint256 private constant MAX_WHALE_FEE = 2500; // 25%
    uint256 private constant MAX_SWEEPSTAKE_REFUND = 10**17; // 0.1 BNB

    // Mappings

    // mapping of amounts allowed to be transferred by spender from owner account.
    mapping(address => mapping(address => uint256)) private allowances;
    // Exclude the ENTIRE transaction from fee, for example: if A is excluded, if he sends
    // funds, to someone, no fee will be charged.
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => address) private associateRequest;
    mapping(address => address) public associateOf;
    mapping(address => bool) public isAssociateBlackList;
    mapping(address => bool) public isExcludedFromBuyFee;
    mapping(address => bool) public isExcludedFromSellFee;
    mapping(address => bool) public isExcludedFromWhaleProtectionFee;

    mapping(address => Owner) private owners; // Owner map
    mapping(address => uint256) private tokenOwned; // Only for wallets excluded from reward
    mapping(address => bool) public isExcludedFromReward;
    address[] private excludedFromReward;

    // Flags
    bool private inSwapAndLiquify;
    bool private inSweepstake;

    // Values
    uint256 private hodlTotalSupply;
    uint256 private rHodlersRewardPool;
    uint256 private rAvailableSweepstake; // In reflection
    uint256 private rAvailableLiquidity; // In reflection
    uint256 private rAvailableCharity; // In reflection
    uint256 private rDailyCharity; // In reflection
    uint256 private collectedSweepstakeTotal; // in tokens
    uint256 private collectedLiquidityTotal; // in tokens
    uint256 private collectedTeamFeeTotal; // in tokens
    uint256 private soldLiquidityTotal; // in tokens
    uint256 private collectedWhaleTotal; // in tokens
    uint256 private collectedRewardTotal; // in tokens
    uint256 private collectedHodlRewardTotal; // in tokens
    uint256 private collectedCharityTotal; // in tokens
    bool private tradeStarted;
    uint256 public charityLimit;
    uint256 private lastDailyUpdate;
    uint256 private rewardTotal = (MAX - (MAX % TOKEN_TOTAL));
    uint256 private cachedRate = rewardTotal / TOKEN_TOTAL;

    IGainSweepstakes public sweepstake;
    IGainProtocolTransferListener public governance =
        IGainProtocolTransferListener(0);
    GainPriceFeed public priceFeed;
    IUniswapV2Router02 public immutable override uniswapV2Router;
    IUniswapV2Pair public immutable override uniswapV2Pair;

    // Parameters

    uint256 public maxTxAmount = 5000 * 10**6 * 10**9; // 0.5% from total
    uint256 private numTokensSellToAddToLiquidity = 500 * 10**6 * 10**9; // 0.05% from total
    // Will be changed manually once there is enough liquidity, as we need a bigger K at start, regardless of percent
    uint256 private liquidityTargetPercentStart = 2500; // 25%
    uint256 private liquidityTargetPercentEnd = 3000; // 30%
    uint256 public dailyCharityLimitUSD = 10000;

    uint256 private sweepstakeTaxPercentage = 150; // 1.5%
    uint256 private liquidityTaxPercentage = 190; // 1.9%
    uint256 private rewardTaxPercentage = 300; // 3%
    uint256 private charityTaxPercentage = 25; // 0.25%
    uint256 private hodlTaxPercentage = 25; // 0.25%
    uint256 private teamTaxPercentage = 10; // 0.1%

    uint256 public sweepstakeLockTime = 7 * 24 * 60 * 60; // 30 days

    uint256 public whaleProtectionPercentFromLP = 200; // 2%
    bool private swapAndLiquifyEnabled = true;
    bool private dynamicSwapAndLiquifyEnabled = false;
    bool private whaleProtectionEnabled = true;
    bool private taxesEnabled = true;
    bool private associatesEnabled = true;
    address public teamWallet;

    // Events
    event GiveBack(address from, uint256 amount);
    event GiveBackHodl(address from, uint256 amount);
    event TokensLocked(address owner, uint256 amount, uint256 duration);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event WhaleProtectionUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 bnbIntoLiquidity,
        uint256 tokensIntoLiquidity
    );
    event RemoveFromLiquidityAndReward(
        uint256 tokenRemovedFromLiquidity,
        uint256 bnbRemovedFromLiquidity,
        uint256 tokenRewarded
    );
    event SellerFeesCollected(
        uint256 reward,
        uint256 hodl,
        uint256 charity,
        uint256 whaleProtection
    );

    event NoFeesTransfer(address from, address to, uint256 tokenAmount);

    event BuyerFeesCollected(
        uint256 liquidity,
        uint256 sweepstake,
        uint256 team
    );
    event WhaleProtectionFeeCollected(uint256 amount);

    // Modifiers
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier inSweepstakeLock() {
        inSweepstake = true;
        _;
        inSweepstake = false;
    }

    // section: externals

    function getTaxes()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            sweepstakeTaxPercentage,
            liquidityTaxPercentage,
            rewardTaxPercentage,
            charityTaxPercentage,
            hodlTaxPercentage,
            teamTaxPercentage
        );
    }

    /**
     * @dev Get total sweepstake token distributed so far
     */
    function collectedSweepstake() external view override returns (uint256) {
        return collectedSweepstakeTotal.add(availableSweepstake());
    }

    /**
     * @dev Get all time liquidity collected
     */
    function collectedLiquidity() external view override returns (uint256) {
        return collectedLiquidityTotal.add(availableLiquidity());
    }

    /**
     * @dev Get all time collected charity
     */
    function collectedCharity() external view override returns (uint256) {
        return collectedCharityTotal.add(availableCharity());
    }

    /**
     * @dev Get all time collected team fee
     */
    function collectedTeamFee() external view override returns (uint256) {
        return collectedTeamFeeTotal;
    }

    /**
     * @dev Get all time collected whale fee
     */
    function collectedWhaleFee() external view override returns (uint256) {
        return collectedWhaleTotal;
    }

    /**
     * @dev Get all time collected hodl reward
     */
    function collectedHodlReward() external view override returns (uint256) {
        return collectedHodlRewardTotal;
    }

    /**
     * @dev Get all time collected reward (without whale fee)
     */

    function collectedReward() external view override returns (uint256) {
        return collectedRewardTotal.sub(collectedWhaleTotal);
    }

    /**
     * @dev Get sold liquidity
     */
    function soldLiquidity() external view override returns (uint256) {
        return soldLiquidityTotal;
    }

    /**
     * @dev Get next sweepstake jackpot
     */
    function availableSweepstake() public view override returns (uint256) {
        return tokenFromReflection(rAvailableSweepstake);
    }

    /**
     * @dev Get charity available
     */
    function availableCharity() public view override returns (uint256) {
        return tokenFromReflection(rAvailableCharity);
    }

    /**
     * @dev Get available liquidity (to be added to LP)
     */
    function availableLiquidity() public view override returns (uint256) {
        return tokenFromReflection(rAvailableLiquidity);
    }

    /**
     * @dev allows a user to give funds to reward all other users
     *      This is better then burning :)
     */
    function giveBack(uint256 _tAmount) external override {
        address sender = _msgSender();
        uint256 rAmount = _tAmount.mul(cachedRate);
        // Try to liquidate hodl tokens if needed.
        _removeTokensFromHodlForBalanceIfNeeded(sender, _tAmount);

        owners[sender].balance = owners[sender].balance.sub(
            rAmount,
            "You don't have enough funds"
        );
        if (isExcludedFromReward[sender]) {
            tokenOwned[sender] = tokenOwned[sender].sub(_tAmount);
        }
        _reflectReward(_tAmount, rAmount);
        emit GiveBack(sender, _tAmount);
    }

    /**
     * @dev allows a user to give funds to reward all other users (hodl version)
     *      This is better then burning :)
     */
    function giveBackHodl(uint256 _tAmount) external override {
        address sender = _msgSender();
        uint256 rAmount = _tAmount.mul(cachedRate);

        // Try to liquidate hodl tokens if needed.
        _removeTokensFromHodlForBalanceIfNeeded(sender, _tAmount);

        owners[sender].balance = owners[sender].balance.sub(
            rAmount,
            "You don't have enough funds"
        );
        if (isExcludedFromReward[sender]) {
            tokenOwned[sender] = tokenOwned[sender].sub(_tAmount);
        }
        _reflectHodlFee(_tAmount, rAmount);
        emit GiveBackHodl(sender, _tAmount);
    }

    /**
     * @dev Set an associate for this wallet. this cannot be changed later
     *   _associate: wallet address
     */
    function setAssociate(address _associate) external override {
        _setAssociate(_msgSender(), _associate);
    }

    function _setAssociate(address _sender, address _associate) private {
        if (associateRequest[_associate] != _sender) {
            associateRequest[_sender] = _associate;
            return;
        }
        require(
            associateOf[_sender] == address(0) &&
                associateOf[_associate] == address(0),
            "Cannot change associate"
        );

        require(
            !isAssociateBlackList[_associate] && !isAssociateBlackList[_sender],
            "This address is blacklisted"
        );

        associateOf[_sender] = _associate;
        associateOf[_associate] = _sender;
    }

    /**
     * @dev run sweepstake. using inSweepstakeLock to avoid swapAndLiquify in sweepstake as it's pretty heavy as is
     */
    function startDraw() external override inSweepstakeLock {
        uint256 startGas = gasleft();
        sweepstake.startDraw(tokenFromReflection(rAvailableSweepstake));
        uint256 gasSpent = startGas.sub(gasleft());
        // Try to transfer back the cost of running this function, fails quietly..
        uint256 bnbRefund = _min(
            _min(MAX_SWEEPSTAKE_REFUND, gasSpent.mul(tx.gasprice)),
            address(this).balance
        );
        _msgSender().transfer(bnbRefund);
    }

    /**
     * @dev get total transfers done today of an account
     */

    function dailyTransfersOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        uint256 dayIndex = block.timestamp.div(1 days);

        if (owners[_account].dailyTransferLastUpdatedDay != dayIndex) {
            return 0;
        }
        return owners[_account].dailyTransfers;
    }

    /**
     * @dev Enable sending BNB to contract. can be helpful in the future for balancing liquidity.
     * Also needed to get BNB from uniswapV2Router when swapping
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @dev Returns hodl tokens, and total hodl tokens. divided one by the other to get hodl reward percent
     * @return hodlTokens _account holding
     * @return hodlTokenSupply total hodl supply
     */
    function hodlTokensOf(address _account)
        external
        view
        override
        returns (uint256 hodlTokens, uint256 hodlTokenSupply)
    {
        hodlTokens = owners[_account].hodlTokens;
        hodlTokenSupply = hodlTotalSupply;
    }

    /**
     * @dev Transfer _tAmount tokens for _to, which will be locked for _lockPeriodSeconds seconds
     */

    function lockedTransfer(
        address _to,
        uint256 _tAmount,
        uint256 _lockPeriodSeconds
    ) external override {
        _lockedTransfer(_msgSender(), _to, _tAmount, _lockPeriodSeconds);
    }

    /**
     * @dev Allows to lock _tAmount for _lockPeriodSeconds seconds. relative part will be released on an
     *      hourly basis
     */
    function lockTokens(uint256 _tAmount, uint256 _lockPeriodSeconds)
        external
        override
    {
        _lockReflection(
            _msgSender(),
            reflectionFromToken(_tAmount),
            _lockPeriodSeconds
        );
    }

    /**
     * @dev Get when the locked tokens will be released
     */
    function lockedBalanceReleaseDate(address _account)
        external
        view
        override
        returns (uint256)
    {
        uint256 lockEndTime = owners[_account].lockedEndTime;
        return lockEndTime > block.timestamp ? lockEndTime : block.timestamp;
    }

    /**
     * @dev Get how much tokens are locked for the user
     */
    function lockedBalanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return tokenFromReflection(_getLockedReflectionOf(_account));
    }

    /**
     * @dev Calculate fee for a transaction - public function
     */
    function calculateFees(
        address _sender,
        address _recipient,
        uint256 _tAmount
    )
        external
        view
        override
        returns (
            uint256 liquidityFee,
            uint256 sweepstakeFee,
            uint256 teamFee,
            uint256 charityFee,
            uint256 rewardFee,
            uint256 hodlFee,
            uint256 whaleProtectionFee
        )
    {
        Fees memory fees = _calculateFees(_sender, _recipient, _tAmount);
        liquidityFee = fees.liquidity;
        sweepstakeFee = fees.sweepstake;
        teamFee = fees.team;
        charityFee = fees.charity;
        rewardFee = fees.reward;
        hodlFee = fees.hodl;
        whaleProtectionFee = fees.whaleProtection;
    }

    // section: externals - onlyOwner

    /**
     * Sets the team wallet to transfer team motivation funds
     */
    function setTeamWallet(address _account) external onlyOwner {
        teamWallet = _account;
    }

    /**
     * @dev Set the number of tokens to liquify at once
     *      We will probably lower this value in the future
     *      to avoid too much price drop when swapping
     */
    function setNumTokensSellToAddToLiquidity(uint256 _value)
        external
        onlyOwner
    {
        numTokensSellToAddToLiquidity = _value;
    }

    /**
     * @dev Set Maximum tx amount
     */
    function setMaxTxAmount(uint256 _value) external onlyOwner {
        maxTxAmount = _value;
    }

    /**
     * @dev When a user wins a sweepstake, the win funds are locked for a few days.
     * _value: the number of days to lock sweepstake winnings
     */
    function setSweepstakeLockTime(uint256 _value) external onlyOwner {
        sweepstakeLockTime = _value;
    }

    /**
     * @dev if dynamic liquidity is enabled, sets limits. see explanations above
     * _values: range [start, end]
     */
    function setLiquidityTarget(uint256 _start, uint256 _end)
        external
        onlyOwner
    {
        liquidityTargetPercentStart = _start;
        liquidityTargetPercentEnd = _end;
    }

    /**
     * @dev Override the associate for a wallet.
     * In case there will be a future Gain Protocol wallet, we will use this to allow transfers to the new wallet.
     * Note: This is LESS strong then excludeFromFee.
     * can only be called by owner
     * _from: The wallet to change the associate for.
     * _associate: The new associate wallet.
     */
    function overrideAssociate(address _from, address _associate)
        external
        onlyOwner
        returns (bool)
    {
        associateOf[_from] = _associate;
        return true;
    }

    /**
     * @dev Limits the maximum daily charity collected (in USD)
     * _value: amount in USD
     */

    function setCharityLimitUSD(uint256 _value) external onlyOwner {
        dailyCharityLimitUSD = _value;
        (, uint256 value) = priceFeed.gainsForUSD(_value);
        charityLimit = value;
    }

    /**
     * @dev changes the taxes being collected. cannot add up to more then 10%
     */

    function setTaxPercentage(
        uint16 _sweepstake,
        uint16 _liquidity,
        uint16 _reward,
        uint16 _charity,
        uint16 _hodl,
        uint16 _team
    ) external onlyOwner {
        require(_sweepstake + _liquidity + _team <= 350, "Max 3.5% tax");
        require(_reward + _charity + _hodl <= 350, "Max 3.5% tax");
        sweepstakeTaxPercentage = _sweepstake;
        liquidityTaxPercentage = _liquidity;
        rewardTaxPercentage = _reward;
        charityTaxPercentage = _charity;
        hodlTaxPercentage = _hodl;
        teamTaxPercentage = _team;
    }

    /**
     * @dev set when to take whale protection fee. this is the percent from the total GAINs in the LP.
     * value is compared for a user daily sells (see whale protection mechanism)
     * _value - Percent from LP
     */
    function setWhaleProtectionPercentFromLP(uint256 _value)
        external
        onlyOwner
    {
        whaleProtectionPercentFromLP = _value;
    }

    /**
     * @dev enables dynamic swap and liquify (see dynamic liquidity above)
     */
    function setDynamicSwapAndLiquifyEnabled(bool _value) external onlyOwner {
        dynamicSwapAndLiquifyEnabled = _value;
    }

    /**
     * @dev set price feed contract address
     * _priceFeed contract address
     */
    function setPriceFeed(GainPriceFeed _priceFeed) external onlyOwner {
        priceFeed = _priceFeed;
    }

    /**
     * @dev Exclude account from fee. exclude every transaction this account is a part of from ALL fees
     */
    function excludeFromFee(address _account, bool _isExcluded)
        external
        onlyOwner
    {
        isExcludedFromFee[_account] = _isExcluded;
    }

    /**
     * @dev Exclude account from buy fee. seller fee will be taken (unless it's also excluded)
     */
    function excludeFromBuyFee(address _account, bool _isExcluded)
        external
        onlyOwner
    {
        isExcludedFromBuyFee[_account] = _isExcluded;
    }

    /**
     * @dev Add account to associate blacklist so it cannot be added as associate (for example: PancakeSwap)
     */
    function blackListFromAssociate(address _account, bool _isBlackListed)
        external
        onlyOwner
    {
        isAssociateBlackList[_account] = _isBlackListed;
    }

    /**
     * @dev Exclude account from whale protection. will be used for
     *      address(this) and possibly for exchanges if needed in the future
     */
    function excludeFromWhaleProtection(address _account, bool _isExclude)
        external
        onlyOwner
    {
        isExcludedFromWhaleProtectionFee[_account] = _isExclude;
    }

    /**
     * @dev Exclude account from sell fee. buyer fee will be taken (unless it's also excluded)
     */
    function excludeFromSellFee(address _account, bool _isExclude)
        external
        onlyOwner
    {
        isExcludedFromSellFee[_account] = _isExclude;
    }

    /**
     * @dev Used in case we will change the sweepstake mechanism (unlikely)
     */
    function setSweepstakeAddress(IGainSweepstakes _newSweepstake)
        external
        onlyOwner
    {
        sweepstake = _newSweepstake;
    }

    /**
     * @dev Used when we have our governance contract ready
     */
    function setGovernanceAddress(IGainProtocolTransferListener _governance)
        external
        onlyOwner
    {
        governance = _governance;
    }

    /**
     * @dev Disable/enable taxes (will be used in ICO)
     */
    function setTaxesEnabled(bool _enabled) external onlyOwner {
        taxesEnabled = _enabled;
    }

    /**
     * @dev Disable/enable associates
     */
    function setAssociatesEnabled(bool _enabled) external onlyOwner {
        associatesEnabled = _enabled;
    }

    /**
     * @dev Enable/disable Auto LP. can only be called by owner
     *      _enabled: new state
     */

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /**
     * @dev will be used after ICO
     */
    function startTrade() external onlyOwner {
        tradeStarted = true;
    }

    /**
     * @dev Enable/disable whale protection. can only be called by owner
     *      _enabled: new state
     */

    function setWhaleProtectionEnabled(bool _enabled) external onlyOwner {
        whaleProtectionEnabled = _enabled;
        emit WhaleProtectionUpdated(_enabled);
    }

    /**
     * @dev exclude an account from getting a reward and hodl
     */
    function excludeFromReward(address _account, bool _isExcluded)
        external
        onlyOwner
    {
        if (_isExcluded) {
            _excludeFromReward(_account);
        } else {
            _includeInReward(_account);
        }
    }

    /**
     * @dev exclude an account from getting a reward and hodl
     */
    function _excludeFromReward(address _account) private {
        require(_account != address(this), "Cannot exclude");
        require(!isExcludedFromReward[_account], "Already excluded");
        _removeTokensFromHodl(_account);
        if (owners[_account].balance > 0) {
            tokenOwned[_account] = tokenFromReflection(
                owners[_account].balance
            );
        }
        isExcludedFromReward[_account] = true;
        excludedFromReward.push(_account);
    }

    /**
     * @dev reverts previous function
     */
    function _includeInReward(address _account) private {
        require(isExcludedFromReward[_account], "Already included");
        for (uint256 i = 0; i < excludedFromReward.length; i++) {
            if (excludedFromReward[i] == _account) {
                // As in time, balance lost sync with tokenOwned, calculate new balance
                uint256 newBalance = reflectionFromToken(tokenOwned[_account]);
                // Adjust reward total to fit the new balance
                rewardTotal = rewardTotal.sub(owners[_account].balance).add(
                    newBalance
                );
                owners[_account].balance = newBalance;

                excludedFromReward[i] = excludedFromReward[
                    excludedFromReward.length - 1
                ];
                tokenOwned[_account] = 0;
                isExcludedFromReward[_account] = false;
                excludedFromReward.pop();
                break;
            }
        }
    }

    /**
     * @dev Withdraw charity to some address
     */
    function withdrawCharity(address _to) external onlyOwner lockTheSwap {
        uint256 charityInTokens = tokenFromReflection(rAvailableCharity);
        rAvailableCharity = 0;
        _transfer(address(this), _to, charityInTokens);
        collectedCharityTotal = collectedCharityTotal.add(charityInTokens);
    }

    // section: public

    /**
     * @dev Returns the state (on/off) of the following features: swapAndLiquify, dynamicSwapAndLiquify, whaleProtection, taxes, associates.
     * @return swapAndLiquify
     * @return dynamicSwapAndLiquify
     * @return whaleProtection
     * @return taxes
     * @return associates
     */
    function featuresState()
        external
        view
        returns (
            bool swapAndLiquify,
            bool dynamicSwapAndLiquify,
            bool whaleProtection,
            bool taxes,
            bool associates
        )
    {
        swapAndLiquify = swapAndLiquifyEnabled;
        dynamicSwapAndLiquify = dynamicSwapAndLiquifyEnabled;
        whaleProtection = whaleProtectionEnabled;
        taxes = taxesEnabled;
        associates = associatesEnabled;
    }

    /**
     * @dev Return current liquidity control parameters value
     * @return numTokensSell How much tokens to accumulate before swap and liquify
     * @return liquidityTargetStart Dynamic liquidity start range (percent)
     * @return liquidityTargetEnd  Dynamic liquidity end range (percent)
     */
    function liquidityParams()
        external
        view
        returns (
            uint256 numTokensSell,
            uint256 liquidityTargetStart,
            uint256 liquidityTargetEnd
        )
    {
        numTokensSell = numTokensSellToAddToLiquidity;
        liquidityTargetStart = liquidityTargetPercentStart;
        liquidityTargetEnd = liquidityTargetPercentEnd;
    }

    /**
     * @dev convert reflection units to tokens
     */
    function tokenFromReflection(uint256 _rAmount)
        public
        view
        override
        returns (uint256)
    {
        // solhint-disable-next-line reason-string
        require(_rAmount <= rewardTotal, "> total reflections");
        return _rAmount.div(cachedRate);
    }

    /**
     * @dev convert token units to reflection
     */
    function reflectionFromToken(uint256 _tAmount)
        public
        view
        override
        returns (uint256)
    {
        require(_tAmount <= TOKEN_TOTAL, "> total tokens");
        return _tAmount.mul(cachedRate);
    }

    // section: special externals

    /**
     * @dev transfer sweepstake funds to winners. can only be called by sweepstake contract
     */
    function transferSweepstake(address _winner, uint256 _tAmount)
        external
        override
    {
        require(_msgSender() == address(sweepstake), "Invalid sender");
        uint256 rAmount = reflectionFromToken(_tAmount);
        rAvailableSweepstake = rAvailableSweepstake.sub(rAmount);
        collectedSweepstakeTotal = collectedSweepstakeTotal.add(_tAmount);
        // This must be called last, as it will change cachedRate
        _lockedTransfer(address(this), _winner, _tAmount, sweepstakeLockTime);
    }

    // section: IERC20

    constructor(address _routerAddrs, IGainSweepstakes _sweepstake) public {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddrs);
        // Create a uniswap pair for this new token

        address pairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Pair = IUniswapV2Pair(pairAddress);

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        sweepstake = _sweepstake;
        sweepstake.setParentERC(this);
        sweepstake.initialTransfer(_msgSender(), TOKEN_TOTAL);

        owners[_msgSender()].balance = rewardTotal;
        owners[_msgSender()].excludedFromHodlReward = true;
        owners[address(0xDEAD)].excludedFromHodlReward = true;
        owners[address(this)].excludedFromHodlReward = true;
        isExcludedFromBuyFee[address(this)] = true;
        isExcludedFromSellFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), TOKEN_TOTAL);
    }

    /**
     * @dev Token name
     */

    function name() external pure returns (string memory) {
        return NAME;
    }

    /**
     * @dev Token symbol
     */

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    /**
     * @dev Token decimal point
     */

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev Token total supply (doesn't change)
     */

    function totalSupply() external view override returns (uint256) {
        return TOKEN_TOTAL;
    }

    /**
     * @dev Get how much _spender can spend from _owners wallet
     * _owner: owners address
     * _spender: spender address
     */

    function allowance(address _owner, address _spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances[_owner][_spender];
    }

    /**
     * @dev Approve _spender to spend _amount from callers wallet. this overrides previous allowance
     * _spender: spender address
     * _amount: token quantity
     */

    function approve(address _spender, uint256 _amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    /**
     * @dev Returns the balance of a wallet, in tokens.
     * @param _account: wallet address
     */

    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        // If reflection is disabled - take token count
        if (isExcludedFromReward[_account]) {
            return tokenOwned[_account];
        }
        // Converted here to prevent overflow
        uint256 hodlRewardTokens = rHodlersRewardPool.div(cachedRate);
        uint256 hodlTokens = owners[_account].hodlTokens;
        uint256 hodlReward = hodlTotalSupply > 0
            ? hodlRewardTokens.mul(hodlTokens).div(hodlTotalSupply)
            : 0;

        return owners[_account].balance.div(cachedRate).add(hodlReward);
    }

    /**
     * @dev Transfer _amount tokens to _recipient
     */
    function transfer(address _recipient, uint256 _amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    /**
     * @dev transfer from _sender to _recipient, _amount tokens. will only work if approve was called before
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(
            _sender,
            _msgSender(),
            allowances[_sender][_msgSender()].sub(
                _amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    // section: internal functions

    /**
     * @dev internal method for approve
     */
    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "ERC20: approve from zero address");
        require(_spender != address(0), "ERC20: approve to zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /**
     * @dev get current rate (ratio between reflection and tokens)
     */
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /**
     * @dev Returns total reward and total tokens (excluding tokens and reward held by excluded from reward users)
     */
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = rewardTotal;
        uint256 tSupply = TOKEN_TOTAL;
        for (uint256 i = 0; i < excludedFromReward.length; i++) {
            if (
                owners[excludedFromReward[i]].balance > rSupply ||
                tokenOwned[excludedFromReward[i]] > tSupply
            ) return (rewardTotal, TOKEN_TOTAL);
            rSupply = rSupply.sub(owners[excludedFromReward[i]].balance);
            tSupply = tSupply.sub(tokenOwned[excludedFromReward[i]]);
        }
        if (rSupply < rewardTotal.div(TOKEN_TOTAL)) {
            return (rewardTotal, TOKEN_TOTAL);
        }
        return (rSupply, tSupply);
    }

    /**
     * @dev internal transfer function
     * @return The amount of *reflection* added to the receiver (returning reflection as token
     *         is less viable as reward changes in the function)
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) private returns (uint256) {
        // THIS IS A WORKAROUND!! see _swapBNBForTokens
        if (_to == address(1) && inSwapAndLiquify) {
            _to = address(this);
        }
        // This is like calling setAssociate, but can be used when you can't call the contract function (like when using an exchange)
        if (associateRequest[_to] == _from && _amount == 777771234) {
            _setAssociate(_from, _to);
            emit Transfer(_from, _to, 0);
            return 0;
        }
        require(_from != address(0), "ERC20: transfer from zero addrs");
        require(_to != address(0), "ERC20: transfer to zero address");
        require(_amount > 0, "Transfer amount must be > 0");
        // Instead of adding ANOTHER list of people allowed to trade, we just use isExcludedFromFee (which can only be added by owner)
        require(tradeStarted || isExcludedFromFee[_from], "Trade not started");

        // Needed for ICO
        if (_from != owner() && _to != owner()) {
            require(_amount <= maxTxAmount, "Transfer amount exceeds maxTx");
        }

        if (
            _from != address(uniswapV2Pair) &&
            !inSweepstake &&
            !inSwapAndLiquify
        ) {
            _handleLiquify();
        }

        // Update data that needs to be updated on a daily basis
        _updateDailyData();

        //transfer amount
        return _tokenTransfer(_from, _to, _amount);
    }

    /**
     * @dev Update charity limit from USD value
     */
    function _updateDailyData() private {
        uint256 dayIndex = block.timestamp.div(1 days);
        if (dayIndex != lastDailyUpdate) {
            // Ignoring success, because with an error, value = 0, and that's OK for us..
            // Note: Until there will be a working LP, the value here will be 0..
            (, uint256 value) = priceFeed.gainsForUSD(dailyCharityLimitUSD);
            charityLimit = value;
            rDailyCharity = 0;
            lastDailyUpdate = dayIndex;
        }
    }

    /**
     * @dev all liquify related handling,
     *      will liquify or un-liquify (for dynamic liquidity) if needed
     */
    function _handleLiquify() private {
        // Get tokens ready for liquify
        uint256 tokensWaitingForLiquidity = rAvailableLiquidity.div(cachedRate);

        // liquify if needed
        bool overMinTokenBalance = tokensWaitingForLiquidity >=
            numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && swapAndLiquifyEnabled) {
            // add liquidity
            _swapAndLiquify(numTokensSellToAddToLiquidity);
        }

        // Dynamic liquidity
        uint256 neededMaxLiquidity = _percent(
            TOKEN_TOTAL,
            liquidityTargetPercentEnd
        );
        if (
            dynamicSwapAndLiquifyEnabled &&
            _getLiquidity() >= neededMaxLiquidity
        ) {
            _removeFromLiquidityAndReward(numTokensSellToAddToLiquidity);
        }
    }

    /**
     * @dev Get LP reserves for GAIN/BNB
     * returns (gainReserve, BNBReserve)
     */
    function _getReserves() private view returns (uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, ) = uniswapV2Pair.getReserves();
        return
            uniswapV2Pair.token0() == address(this)
                ? (reserve0, reserve1)
                : (reserve1, reserve0);
    }

    /**
     * @dev swap GAINS for BNB, and add the resulting tokens to liquidity
     * if there are hanging BNBs - use them also
     */
    function _swapAndLiquify(uint256 tokensToLiquify) private lockTheSwap {
        (uint256 gainReserve, uint256 bnbReserve) = _getReserves();
        if (gainReserve == 0 || bnbReserve == 0) {
            // No LP yet, this will fail..
            return;
        }
        // Try to keep the balance above MAX_SWEEPSTAKE_REFUND
        uint256 balanceBefore = address(this).balance;
        (, uint256 balance) = balanceBefore.trySub(
            MAX_SWEEPSTAKE_REFUND.mul(5)
        );
        // We will also add this to liquidity, don't need BNB seating around..
        uint256 balanceInGains = balance.mul(gainReserve).div(bnbReserve);
        uint256 toConvert = tokensToLiquify > balanceInGains
            ? tokensToLiquify.sub(balanceInGains).div(2)
            : 0;
        uint256 otherHalf = tokensToLiquify.sub(toConvert);

        // swap tokens for BNB
        if (toConvert > 0) {
            _swapTokensForBNB(toConvert);
        }
        uint256 receivedBNBs = address(this).balance.sub(balanceBefore);

        // add liquidity to uniswap
        // There should never be any BNB left in the contract
        uint256 balanceBeforeLiquify = address(this).balance;
        (uint256 amountTokenAdded, ) = _addLiquidity(
            otherHalf,
            address(this).balance
        );
        collectedLiquidityTotal = collectedLiquidityTotal
            .add(amountTokenAdded)
            .add(toConvert);

        rAvailableLiquidity = rAvailableLiquidity.sub(
            amountTokenAdded.add(toConvert).mul(cachedRate)
        );

        emit SwapAndLiquify(
            toConvert,
            receivedBNBs,
            balanceBeforeLiquify.sub(address(this).balance),
            otherHalf
        );
    }

    /**
     * @dev There is too much liquidity (as defined by liquidityTargetPercentEnd)
     * this (should) mean a lot of accounts are selling their GAINs.
     * so remove liquidity (which will give us BNBs and GAINs), then buy GAINs with the BNBs.
     * This gives us a side effect of raising GAIN price (which balances out the sells)
     * and we use the resulting GAINs to reward all users (reflection).
     * So basically - what we do here is use the tax we collected (which was put into the liquidity)
     * when no longer needed to help our holders.
     * This can be viewed as some kind of insurance - we collect a fee when everything is great
     * but when dark days come, we use that money to help out holders to keep their profits
     */
    function _removeFromLiquidityAndReward(uint256 _tokensToRemoveFromLiquidity)
        private
        lockTheSwap
    {
        (uint256 amountToken, uint256 amountBNB) = _removeLiquidity(
            _tokensToRemoveFromLiquidity.div(2)
        );
        if (amountToken == 0 || amountBNB == 0) {
            // Cannot remove liquidity
            return;
        }
        uint256 swappedTokens = _swapBNBForTokens(amountBNB);
        uint256 newRate = _getRate();
        uint256 totalTokens = swappedTokens.add(amountToken);
        owners[address(this)].balance = owners[address(this)].balance.sub(
            totalTokens.mul(newRate)
        );
        _reflectReward(totalTokens, totalTokens.mul(newRate));
        soldLiquidityTotal = soldLiquidityTotal.add(totalTokens);
        emit RemoveFromLiquidityAndReward(amountToken, amountBNB, totalTokens);
    }

    /**
     * @dev send GAINs and get BNB
     */
    function _swapTokensForBNB(uint256 _tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev send BNBs and get GAIN
     */
    function _swapBNBForTokens(uint256 _bnbAmount) private returns (uint256) {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uint256 balanceBefore = balanceOf(address(this));

        // We put address(1) here because uniswap will fail
        // if we send to address(this) (UniswapV2: INVALID_TO).
        // due to that, we are forced to work around this, send to
        // address(1), and in _transfer, change address(1) to address(this)
        // This is a bit ugly, but i see no good alternative..
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _bnbAmount
        }(0, path, address(1), block.timestamp);
        return balanceOf(address(this)).sub(balanceBefore);
    }

    /**
     * @dev send BNBs and GAIN to LP
     */
    function _addLiquidity(uint256 _tokenAmount, uint256 _bnbAmount)
        private
        returns (uint256 amountToken, uint256 amountETH)
    {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // add the liquidity
        (amountToken, amountETH, ) = uniswapV2Router.addLiquidityETH{
            value: _bnbAmount
        }(
            address(this),
            _tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Remove liquidity of gainAmount gains + BNB of the same value (total in gains: 2 * gainAmount)
     */

    function _removeLiquidity(uint256 _gainAmount)
        private
        returns (uint256, uint256)
    {
        // Not using getLiquidity as we need updated balances, not reserves
        uint256 liquidity = balanceOf(address(uniswapV2Pair));
        uint256 liquidityNeeded = _gainAmount
            .mul(uniswapV2Pair.totalSupply())
            .div(liquidity);

        // Just in case we are not the owner of all the liquidity
        liquidityNeeded = _min(
            uniswapV2Pair.balanceOf(address(this)),
            liquidityNeeded
        );
        if (liquidityNeeded == 0) {
            // No available liquidity
            return (0, 0);
        }
        uniswapV2Pair.approve(address(uniswapV2Router), liquidityNeeded);
        return
            uniswapV2Router.removeLiquidityETH(
                address(this),
                liquidityNeeded,
                0,
                0,
                address(this),
                block.timestamp
            );
    }

    /**
     * @dev compare _amount to total liquidity (in GAINs), and return percentage
     */
    function _compareToLP(uint256 _amount) private view returns (uint256) {
        return _amount.mul(PERCENT_DIVIDER_FACTOR).div(_getLiquidity());
    }

    /**
     * @dev Get liquidity (at GAINs side)
     */
    function _getLiquidity() private view returns (uint256) {
        (uint256 gainReserve, ) = priceFeed.getReserves();
        return gainReserve;
    }

    /**
     * @dev Transfer _tAmount tokens from _from to _to, and lock them for _lockPeriodSeconds.
     * Relative amount will be released on an hourly basis
     */
    function _lockedTransfer(
        address _from,
        address _to,
        uint256 _tAmount,
        uint256 _lockPeriodSeconds
    ) private {
        uint256 rTransferred = _transfer(_from, _to, _tAmount);
        // Add newly won reflection to locked balance
        /* NOTICE: there is a logical issue here:
            If we win 10000 tokens, and in 15 days another 10 token
            we now have 5010 tokens locked for 30 days, instead of 10 for 30 days and 5000 for 15 days
            we are OK with that..
        */
        _lockReflection(_to, rTransferred, _lockPeriodSeconds);
    }

    /**
     * @dev lock _rAmount reflection for _account for _lockPeriodSeconds.
     *      Relative amount will be released on an hourly basis
     */
    function _lockReflection(
        address _account,
        uint256 _rAmount,
        uint256 _lockPeriodSeconds
    ) private {
        uint256 newLockTime = block.timestamp.add(_lockPeriodSeconds);
        // Prevent a situation where someone reduces his current lock
        // By locking some more tokens, for 1 seconds

        newLockTime = _max(owners[_account].lockedEndTime, newLockTime);
        require(_lockPeriodSeconds > 0, "Too short lock");
        require(_rAmount > 0, "Invalid parameter");
        owners[_account].lockedBalance = _rAmount.add(
            _getLockedReflectionOf(_account) // in case he already has a locked amount
        );
        owners[_account].lockedStartTime = uint64(block.timestamp);
        owners[_account].lockedEndTime = uint64(newLockTime);
        emit TokensLocked(
            _account,
            tokenFromReflection(_rAmount),
            _lockPeriodSeconds
        );
    }

    /**
     * @dev Get how much reflection is locked for the user
     */
    function _getLockedReflectionOf(address _account)
        private
        view
        returns (uint256)
    {
        uint256 lockEndTime = owners[_account].lockedEndTime;
        if (lockEndTime <= block.timestamp || lockEndTime == 0) {
            return 0;
        }
        uint256 timeSlotLeft = lockEndTime.sub(block.timestamp).div(1 hours);
        uint256 totalTimeSlots = lockEndTime
            .sub(owners[_account].lockedStartTime)
            .div(1 hours);
        // Doing here div before mul on purpose, because otherwise if someone has 0.1% of all tokens
        // (which happens in ICO), there will be an error. the reason is because 0.1% * (24 * 30) > 100% which is UINT_MAX.
        // Anyway, as totalTime is not that big, the inaccuracy doesn't do that much of an effect
        // Also, this doesn't effect user funds, only locked amount, so less critical
        return
            owners[_account].lockedBalance.div(totalTimeSlots).mul(
                timeSlotLeft
            );
    }

    /**
     * @dev Calculate fee for a transaction
     */
    function _calculateFees(
        address _sender,
        address _recipient,
        uint256 _tAmount
    ) private view returns (Fees memory) {
        {
            // Avoid stack too deep
            bool excludedFromFee = isExcludedFromFee[_sender] ||
                isExcludedFromFee[_recipient] ||
                (associateOf[_sender] == _recipient &&
                    !isAssociateBlackList[_recipient] &&
                    associatesEnabled);
            // Don't take tax if taxes are disabled, or from swapAndLiquify
            if (!taxesEnabled || inSwapAndLiquify || excludedFromFee) {
                return
                    Fees({
                        liquidity: 0,
                        sweepstake: 0,
                        charity: 0,
                        team: 0,
                        hodl: 0,
                        reward: 0,
                        whaleProtection: 0
                    });
            }
        }

        FeesPercentage memory feesP = FeesPercentage({
            liquidity: liquidityTaxPercentage,
            sweepstake: sweepstakeTaxPercentage,
            team: teamTaxPercentage,
            charity: charityTaxPercentage,
            hodl: hodlTaxPercentage,
            reward: rewardTaxPercentage,
            whaleProtection: 0
        });
        if (teamWallet == address(0)) {
            feesP.liquidity = feesP.liquidity.add(feesP.team);
            feesP.team = 0;
        }

        if (isExcludedFromBuyFee[_recipient]) {
            // Remove only buy fee (for example: selling from PancakeSwap)
            feesP.sweepstake = 0;
            feesP.liquidity = 0;
            feesP.team = 0;
        } else if (
            dynamicSwapAndLiquifyEnabled &&
            _getLiquidity() > _percent(TOKEN_TOTAL, liquidityTargetPercentStart)
        ) {
            // No need to increase liquidity
            feesP.sweepstake = feesP.liquidity.add(feesP.sweepstake);
            feesP.liquidity = 0;
        }

        if (isExcludedFromSellFee[_sender]) {
            // Remove only sell fee (for example: buying from PancakeSwap)
            feesP.charity = 0;
            feesP.hodl = 0;
            feesP.reward = 0;
        } else if (
            _getLiquidity() > 0 &&
            whaleProtectionEnabled &&
            !isExcludedFromWhaleProtectionFee[_sender]
        ) {
            uint256 percentRelativeToLP = _compareToLP(
                dailyTransfersOf(_sender).add(_tAmount)
            );
            if (percentRelativeToLP > whaleProtectionPercentFromLP) {
                uint256 diff = percentRelativeToLP.sub(
                    whaleProtectionPercentFromLP
                );
                // EXPONENT_PERCENT_DIVIDER moves one of the diff, from percentages, to multiplier
                // as 1% * 1% is actually 0.1% [and for that case, we should have divided by 10**4] (and not 1% which is what we are looking for).
                // So we do 1% * 1 or another example: 2% * 2 (and not  2% * 2%)
                // There is still a problem with anything below 1%, so for that range, we don't **2
                feesP.whaleProtection = _min(
                    _max(diff.mul(diff).div(EXPONENT_PERCENT_DIVIDER), diff),
                    MAX_WHALE_FEE
                );
            }
        }
        uint256 charityFee = _percent(_tAmount, feesP.charity);
        uint256 hodlFee = _percent(_tAmount, feesP.hodl);
        uint256 tDailyCharity = rDailyCharity.div(cachedRate);
        if (tDailyCharity.add(charityFee) > charityLimit) {
            // Get the needed amount to get to the charity limit. if the limit is smaller
            // then daily charity (can happen if there was a manual update)
            // make sure there is no underflow (and take all fee to hodl)
            (, uint256 diff) = charityLimit.trySub(tDailyCharity);
            hodlFee = hodlFee.add(charityFee.sub(diff));
            charityFee = diff;
        }
        return
            Fees({
                liquidity: _percent(_tAmount, feesP.liquidity),
                sweepstake: _percent(_tAmount, feesP.sweepstake),
                team: _percent(_tAmount, feesP.team),
                charity: charityFee,
                reward: _percent(_tAmount, feesP.reward),
                hodl: hodlFee,
                whaleProtection: _percent(_tAmount, feesP.whaleProtection)
            });
    }

    /**
     * @dev this method is responsible for taking all fees
     * @return The amount of *reflection* added to the receiver (returning reflection as token
     *         is less viable as reward changes in the function)
     */
    function _tokenTransfer(
        address _from,
        address _to,
        uint256 _tAmount
    ) private returns (uint256) {
        // Reset daily transfer if day changes
        {
            // Avoid Stack too deep

            uint256 dayIndex = block.timestamp.div(1 days);
            if (owners[_from].dailyTransferLastUpdatedDay != dayIndex) {
                owners[_from].dailyTransferLastUpdatedDay = uint64(dayIndex);
                owners[_from].dailyTransfers = 0;
            }
        }

        Fees memory fees = _calculateFees(_from, _to, _tAmount);
        if (fees.whaleProtection > 0) {
            emit WhaleProtectionFeeCollected(fees.whaleProtection);
        }
        uint256 tSellerSold = _tAmount.add(_totalSellerFees(fees));
        uint256 tTransferAmount = _tAmount.sub(_totalBuyerFees(fees));
        uint256 rTransferAmount = tTransferAmount.mul(cachedRate);

        owners[_from].dailyTransfers = uint96(
            uint256(owners[_from].dailyTransfers).add(_tAmount)
        );

        _onTransfer(
            _from,
            _to,
            _tAmount,
            fees,
            tTransferAmount,
            balanceOf(_from)
        );

        bool balanceAddedAsHodl = _reflectHodlTokens(
            _from,
            _to,
            tSellerSold,
            tTransferAmount
        );
        owners[_from].balance = owners[_from].balance.sub(
            tSellerSold.mul(cachedRate),
            "Not enough funds when taking seller fee"
        );
        if (isExcludedFromReward[_from]) {
            tokenOwned[_from] = tokenOwned[_from].sub(tSellerSold);
        }
        // solhint-disable-next-line reason-string
        require(
            balanceOf(_from) >= _getLockedReflectionOf(_from).div(cachedRate),
            "Some funds are locked"
        );
        if (!balanceAddedAsHodl) {
            if (isExcludedFromReward[_to]) {
                tokenOwned[_to] = tokenOwned[_to].add(tTransferAmount);
            }
            owners[_to].balance = owners[_to].balance.add(rTransferAmount);
        }

        _reflectLiquidity(fees.liquidity.mul(cachedRate));
        _reflectSweepstakeFee(fees.sweepstake.mul(cachedRate));
        _reflectHodlFee(fees.hodl, fees.hodl.mul(cachedRate));
        _reflectTeamFee(fees.team, fees.team.mul(cachedRate));
        _reflectCharityFee(fees.charity.mul(cachedRate));

        collectedWhaleTotal = collectedWhaleTotal.add(fees.whaleProtection);
        _reflectReward(
            fees.reward.add(fees.whaleProtection),
            fees.reward.add(fees.whaleProtection).mul(cachedRate)
        );

        if (
            fees.reward != 0 ||
            fees.charity != 0 ||
            fees.whaleProtection != 0 ||
            fees.hodl != 0
        ) {
            emit SellerFeesCollected(
                fees.reward,
                fees.hodl,
                fees.charity,
                fees.whaleProtection
            );
        } else if (
            fees.liquidity == 0 && fees.sweepstake == 0 && fees.team == 0
        ) {
            emit NoFeesTransfer(_from, _to, tTransferAmount);
        }

        if (fees.liquidity != 0 || fees.sweepstake != 0 || fees.team != 0) {
            emit BuyerFeesCollected(fees.liquidity, fees.sweepstake, fees.team);
        }

        emit Transfer(_from, _to, tTransferAmount);
        return rTransferAmount;
    }

    /**
     * @dev Reflect hodl tokens for a transaction being made.
     *      will remove _from from being able to receive hodl reward (if not connect)
     * @return true if _to balance was added as hodl tokens, false otherwise
     */
    function _reflectHodlTokens(
        address _from,
        address _to,
        uint256 _tSoldAmount,
        uint256 _tTransferAmount
    ) private returns (bool) {
        if (
            associateOf[_from] == _to &&
            !isAssociateBlackList[_to] &&
            associatesEnabled &&
            !owners[_to].excludedFromHodlReward
        ) {
            // If an associate account - not all balance should be removed
            _removeTokensFromHodlForBalanceIfNeeded(_from, _tSoldAmount);
            return false;
        }
        // Remove all hodl tokens
        _removeTokensFromHodl(_from);
        owners[_from].excludedFromHodlReward = true;

        // If percipient is entitled to hodl reward, and the transfer is not an associate transfer
        // (associate is excluded to prevent abuse), and percipient is not excluded from reward
        if (!owners[_to].excludedFromHodlReward && !isExcludedFromReward[_to]) {
            uint256 tHodlersRewardPool = rHodlersRewardPool.div(cachedRate);

            uint256 newTokens = _tTransferAmount;
            if (hodlTotalSupply != 0) {
                newTokens = _tTransferAmount.mul(hodlTotalSupply).div(
                    tHodlersRewardPool
                );
            }
            hodlTotalSupply = hodlTotalSupply.add(newTokens);

            owners[_to].hodlTokens = uint96(
                uint256(owners[_to].hodlTokens).add(newTokens)
            );

            rHodlersRewardPool = rHodlersRewardPool.add(
                _tTransferAmount.mul(cachedRate)
            );
            return true;
        }
        return false;
    }

    /**
     * @dev Remove hodl tokens so that balance will reach _wantedBalance
     */
    function _removeTokensFromHodlForBalanceIfNeeded(
        address _account,
        uint256 _wantedBalance
    ) private {
        uint256 tBalance = owners[_account].balance.div(cachedRate);
        if (_wantedBalance <= tBalance) {
            return;
        }
        uint256 tokensDiff = _wantedBalance.sub(tBalance);
        // will throw (subtract overflow) if not enough tokens
        _removeTokensFromHodl(_account, tokensDiff);
    }

    /**
     * @dev Removes all hodl tokens of _account (and add them to his balance),
     * @notice Will NOT mark him as un-eligible.
     */
    function _removeTokensFromHodl(address _account) private {
        _removeTokensFromHodl(_account, 0);
    }

    /**
     * @dev Removes _tTokensToRemove hodl tokens from _account (and add them to his balance),
     * if _tTokensToRemove == 0, will remove all tokens.
     * @notice Will NOT mark him as excluded.
     */
    function _removeTokensFromHodl(
        address _account,
        uint256 _amountInGains // Send 0 for everything
    ) private {
        uint256 hodlTokens = owners[_account].hodlTokens;
        // Liquidate hodl reward to balance
        if (hodlTokens == 0) {
            return;
        }
        uint256 hodlTokensToRemove;
        uint256 liquidateAmount;
        uint256 tHodlersRewardPool = rHodlersRewardPool.div(cachedRate);
        if (_amountInGains > 0) {
            liquidateAmount = _amountInGains;
            hodlTokensToRemove = _amountInGains.mul(hodlTotalSupply).div(
                tHodlersRewardPool
            );
        } else {
            hodlTokensToRemove = hodlTokens;
            liquidateAmount = hodlTokensToRemove.mul(tHodlersRewardPool).div(
                hodlTotalSupply
            );
        }

        uint256 rLiquidateAmount = liquidateAmount.mul(cachedRate);
        // Update sender balance to include hodl reward
        owners[_account].balance = owners[_account].balance.add(
            rLiquidateAmount
        );
        hodlTotalSupply = hodlTotalSupply.sub(hodlTokensToRemove);
        owners[_account].hodlTokens = uint96(
            hodlTokens.sub(hodlTokensToRemove, "Not enough funds")
        );
        // Remove taken reward

        rHodlersRewardPool = rHodlersRewardPool.sub(rLiquidateAmount);
    }

    /**
     * @dev Call sweepstake onTransfer
     */
    function _onTransfer(
        address _from,
        address _to,
        uint256 _tAmount,
        Fees memory _fees,
        uint256 _tTransferAmount,
        uint256 _sellerBalance
    ) private {
        if (address(sweepstake) != address(0)) {
            sweepstake.onTransfer(
                _from,
                _to,
                _tAmount,
                _fees.liquidity,
                _fees.sweepstake,
                _fees.team,
                _fees.charity,
                _fees.reward,
                _fees.hodl,
                _fees.whaleProtection,
                _tTransferAmount,
                _sellerBalance
            );
        }

        if (address(governance) != address(0)) {
            governance.onTransfer(
                _from,
                _to,
                _tAmount,
                _fees.liquidity,
                _fees.sweepstake,
                _fees.team,
                _fees.charity,
                _fees.reward,
                _fees.hodl,
                _fees.whaleProtection,
                _tTransferAmount,
                _sellerBalance
            );
        }
    }

    /**
     * @dev log and take team fee
     */
    function _reflectTeamFee(uint256 _tAmount, uint256 _rAmount) private {
        if (isExcludedFromReward[teamWallet]) {
            tokenOwned[teamWallet] = tokenOwned[teamWallet].add(_tAmount);
        }
        owners[teamWallet].balance = owners[teamWallet].balance.add(_rAmount);
        collectedTeamFeeTotal = collectedTeamFeeTotal.add(_tAmount);
    }

    /**
     * @dev log and take sweepstake fee
     */
    function _reflectSweepstakeFee(uint256 _rAmount) private {
        rAvailableSweepstake = rAvailableSweepstake.add(_rAmount);
        owners[address(this)].balance = owners[address(this)].balance.add(
            _rAmount
        );
    }

    /**
     * @dev log and take hodl fee
     */
    function _reflectHodlFee(uint256 _tAmount, uint256 _rAmount) private {
        // There is an edge case here - if there are no hodl eligible holders,
        // The whole amount will be given to the first new account - but this
        // is so unlikely (and outcome isn't a crash) that we don't
        // see the need to address this
        rHodlersRewardPool = rHodlersRewardPool.add(_rAmount);
        collectedHodlRewardTotal = collectedHodlRewardTotal.add(_tAmount);
    }

    /**
     * @dev log and take liquidity fee
     */
    function _reflectLiquidity(uint256 _rAmount) private {
        rAvailableLiquidity = rAvailableLiquidity.add(_rAmount);
        owners[address(this)].balance = owners[address(this)].balance.add(
            _rAmount
        );
    }

    /**
     * @dev log and take charity fee
     */
    function _reflectCharityFee(uint256 _rAmount) private {
        rDailyCharity = rDailyCharity.add(_rAmount);
        rAvailableCharity = rAvailableCharity.add(_rAmount);
        owners[address(this)].balance = owners[address(this)].balance.add(
            _rAmount
        );
    }

    /**
     * @dev log and take reward fee
     */
    function _reflectReward(uint256 _tAmount, uint256 _rAmount) private {
        rewardTotal = rewardTotal.sub(_rAmount);
        collectedRewardTotal = collectedRewardTotal.add(_tAmount);
        cachedRate = _getRate();
    }

    // Utilities
    function _min(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    function _max(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _a > _b ? _a : _b;
    }

    function _percent(uint256 _amount, uint256 _percentToTake)
        private
        pure
        returns (uint256)
    {
        return _amount.mul(_percentToTake).div(PERCENT_DIVIDER_FACTOR);
    }

    function _totalBuyerFees(Fees memory _fees) private pure returns (uint256) {
        return _fees.sweepstake.add(_fees.liquidity).add(_fees.team);
    }

    function _totalSellerFees(Fees memory _fees)
        private
        pure
        returns (uint256)
    {
        return
            _fees.reward.add(_fees.charity).add(_fees.whaleProtection).add(
                _fees.hodl
            );
    }
}