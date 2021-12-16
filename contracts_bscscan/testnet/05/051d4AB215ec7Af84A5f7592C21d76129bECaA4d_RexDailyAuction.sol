/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-18
*/

// SPDX-License-Identifier: --🤴--

pragma solidity ^0.7.4;

/*
 ______      _______   ____    ____
|   __  \   |    ___|  \   \  /   /
|  |__|  |  |   |___    \   \/   /
|       /   |   |___    /   /\   \
|__|\ ___\  |_______|  /___/  \___\  (Add-on: Daily Auctions Contract)

Latin: king, ruler, monarch

Name      :: XEN
Ticker    :: XEN
Decimals  :: 18

Website   :: https://www.XEN-token.com
Telegram  :: https://t.me/eth_rex
Twitter   :: https://twitter.com/rex_token
Discord   :: https://discord.gg/YYy4K3pTye

Concept   :: HYBRID-INTEREST TIME DEPOSITS
Special   :: RANDOM PERSONAL Big Pay Days
Category  :: Passive Income

Use XEN-token.com for interacting with this contract.
Find the ::REXpaper:: for more information.

*/

interface IRexToken {

    function currentRexDay()
        external view
        returns (uint32);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function mintSupply(
        address _donatorAddress,
        uint256 _amount
    ) external;

    function setUltraRexican(
        address _referrer
    ) external;

    function getTokensStaked(
        address _staker
    ) external view returns (uint256);
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

contract RexDailyAuction {

    using RexSafeMath for uint256;
    using RexSafeMath32 for uint32;

    address public TOKEN_DEFINER;   // for initializing contracts after deployment
    address payable private DONATE;
    address payable private TEAM_WALLET;
    string public rdaStatus;

    IRexToken public REX_CONTRACT;
    IBEP20 public TREX_CONTRACT;
    IBEP20 public MREX_CONTRACT;

    IUniswapV2Pair public UNISWAP_PAIR;
    // --Main net-- //
    //IUniswapV2Router02 public constant UNISWAP_ROUTER = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    //address constant FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    // --Test net-- //
    IUniswapV2Router02 public constant UNISWAP_ROUTER = IUniswapV2Router02(0x52530AeEcd4574b880924b3FAFa16c0B6b081329);
    address constant FACTORY = 0xE22f569d511f3203a6C52684342184059465d003;

    uint32 constant DONATION_DAYS = 365;        // 1 to 365
    uint32 constant LAST_BIGPAYDAY = 393;
    uint32 constant TREASURY_DAY = 394;
    uint32 constant BNB_CLAIM_DAY = 400;
    uint32 constant LAST_CONTRACT_DAY = 428;

    uint256 constant MIN_INVEST = 1000000 gwei; // 0.001 BNB
    uint256 constant MAX_INVEST = 2E18;         // 2 BNB
    uint256 constant CLAIM_TRESHOLD = 25E18;    // 25 BNB
    uint256 constant DAILY_START_SUPPLY = uint256(890200);  // on day 3, then decreasing by DAILY_DIFF_SUPPLY
    uint256 constant DAILY_DIFF_SUPPLY = uint256(385);      // daily supply reduction amount
    uint256 constant DAY_ONE_SUPPLY = uint256(1276600);
    uint256 constant DAY_TWO_SUPPLY = uint256(890600);
    uint256 constant SXEN_PER_REX = 1E18;    // decimals
    uint256 constant TEN_PRECISION = 1E10;
    uint256 constant HIGH_PRECISION = 100E18;
    uint256 constant HUNDREDTH_OF_BNB = 1E16;
    uint256 constant TENTH_OF_BNB = 1E17;       // equals price of 1 MREX
    uint256 constant ONE_BNB = 1E18;

    struct Globals {
        uint32 generatedDays;
        uint256 totalDonatedBNB;
        uint256 totalGeneratedREX;
        uint256 totalClaimedDonationREX;
        uint256 totalClaimedReferralREX;
        uint256 totalClaimedReferralBNB;
        uint256 totalClaimedRandomBNB;
    }

    Globals public g;

    mapping(uint32 => uint256) public dailyWeiContributed; // used for redistribution (XEN)
    mapping(uint32 => uint256) public dailyGeneratedREX;   // for calculating dailyRatio (XEN)
    mapping(uint32 => uint256) public dailyTotalDonation;  // for calculating dailyRatio (XEN)
    mapping(uint32 => uint256) public dailyTotalReferral;  // for calculating dailyRatio (XEN)
    mapping(uint32 => uint256) public dailyRatio;
    uint32 private lastCheckedSupplyDay;

    mapping(uint32 => uint256) public donatorAccountCount;                  // numberOfDonators per day
    mapping(uint32 => mapping(uint256 => address)) public donatorAccounts;  // address of DonationNumber of DonationDay
    mapping(address => mapping(uint32 => uint256)) public donatorBalances;  // address->day->amount
    mapping(address => mapping(uint32 => bool)) public donatorBalancesDrawn;// address->day->bool // set to true at withdrawal
    mapping(address => uint256) public donatorTotalReceivedREX;             // for RANDOM BNB
    mapping(address => uint256) public donatorTotalBalance;                 // with bonus
    mapping(address => uint256) public originalDonation;                    // count donations for BNBTREASURY
    mapping (uint256 => address) public uniqueDonators;                     // address of x-th donator
    uint256 public uniqueDonatorCount;

    mapping(uint32 => uint256) public referrerAccountCount;                 // number/day
    mapping(uint32 => mapping(uint256 => address)) public referrerAccounts; // day->number => address
    mapping(address => mapping(uint32 => uint256)) public referrerBalances; // address->day => amount
    mapping(address => mapping(uint32 => bool)) public referrerBalancesDrawn; // address->day => bool // set to true at withdrawal
    mapping(address => uint256) public referralBNB;                         // claimable referral BNB of an address
    mapping(address => uint256) public referrerTotalBalance; // Total received amount for referrals (10% of referred donations)
    mapping (uint256 => address) public uniqueReferrers;                    // address of x-th referrer
    uint256 public uniqueReferrerCount;

    mapping(address => uint256) public randomBNB;       // addresses' total amount of claimable BNB from BNB BIG PAY DAYS
    mapping(uint32 => uint256) public restOfBnbPool;    // track the undistributed BNB of each day :: should be zero
    mapping(address => bool) public addressHitByRandom; // if not hit, take part in BNBTREASURY claim phase (days 400-427)
    mapping(address => bool) public addressClaimedAllRexFromDon; // if true, address takes part in BPD
    uint256 public addressHitByRandomCount;             // count up, to know size of array, for BNBTREASURY
    uint256 private unusedTokens;

    uint256 public BNBPOOL;     // temporary pool of BNB reserved for BNB-BigPayDays, unless distributed (to "randomBNB[user]")
    uint256 public REF_BNBPOOL; // temporary pool of BNB reserved for referrers, unless distributed to them (to "referralBNB[user]")
    uint256 public BNBTREASURY; // pool of BNB for donators not hit by random, claim phase: days 400-427

    uint256 public treasuryRatio;   // 1E10 precision ratio, an unhit address gets from BNBTREASURY
    bool public treasuryRatioIsSet; // set with the first contract interaction, before or on day 400

    event DonationReceived(address indexed sender, uint32 indexed donationDay, uint256 amount);
    event ReferralAdded(address indexed referrer, address indexed donator, uint256 amount);
    event DistributedRandomBnb(uint32 day, uint256 daysParticipants, uint256 daysReceivers, uint256 poolSizeStart, uint256 poolSizeEnd);
    event SupplyGenerated(uint32 indexed donationDay, uint256 generatedREX);
    event TreasuryGenerated(uint32 day, uint256 amount, uint256 ratio);
    event ClaimedBnbFromReferrals(address receiver, uint256 amount);
    event ClaimedRexFromDonations(address receiver, uint256 amount);
    event ClaimedRexFromReferrals(address receiver, uint256 amount);
    event ClaimedBnbFromBPD(address receiver, uint256 amount);
    event LiquidityGenerated(uint32 day, uint256 bnbAmount, uint256 rexAmount);

    /**
     * @notice Triggers the daily distribution routines
     */
    modifier supplyTrigger() {
        _dailyDistributionRoutine();
        _;
    }

    /**
     * @notice For initializing the contract
     */
    modifier onlyTokenDefiner() {
        require(
            msg.sender == TOKEN_DEFINER,
            'XEN: Not allowed.'
        );
        _;
    }

    receive() external payable { require (msg.sender == address(UNISWAP_ROUTER), 'XEN: No direct deposits.'); }
    fallback() external payable { revert(); }


    // init functions

    function initRexContracts(address _rex, address _trex, address _mrex) external onlyTokenDefiner {
        REX_CONTRACT = IRexToken(_rex);
        TREX_CONTRACT = IBEP20(_trex);
        MREX_CONTRACT = IBEP20(_mrex);
        rdaStatus = unicode'✅ XEN ACTIVE. Revoke access!';
    }

    function revokeAccess() external onlyTokenDefiner {
        TOKEN_DEFINER = address(0x0);
        rdaStatus = unicode'✅ XEN ACTIVE and SAFU.';
    }

    constructor() {
        TOKEN_DEFINER = msg.sender;
        DONATE = payable(0x6Df08c7B0CE433e29A77281b6E776487730ee900);
        TEAM_WALLET = payable(0x6Df08c7B0CE433e29A77281b6E776487730ee900);
        rdaStatus = unicode'❗Init XEN contracts!';
    }

    /**
     * @notice Check the contract's status (of initialization)
     */
    function getStatus() public view returns(string memory) { return rdaStatus; }

    /** @dev Donate BNB to daily auction's current day
      * @param _referralAddress Referral address for 10% bonus
      */
    function donateBNB(address _referralAddress)
        external payable supplyTrigger
    {
        require(msg.value >= MIN_INVEST, 'XEN: donation below minimum');
        require(msg.value <= MAX_INVEST, 'XEN: donation above maximum');
        require(_currentRexDay() >= 1, 'XEN: Too early.');
        require(_currentRexDay() <= DONATION_DAYS, 'XEN: Too late.');
        require(donatorBalances[msg.sender][_currentRexDay()] == 0, 'XEN: Already donated.');
        _reserveRex(_referralAddress, msg.sender, msg.value);
    }

    /** @dev Donate more BNB to daily auction's current day, if address holds TXEN or MREX
      * @param _referralAddress Referral address for 10% bonus
      */
    function donateMoreBNB(address _referralAddress)
        external payable supplyTrigger
    {
        require(msg.value >= MIN_INVEST, 'XEN: donation below minimum');
        require(_currentRexDay() >= 1, 'XEN: Too early.');
        require(_currentRexDay() <= DONATION_DAYS, 'XEN: Too late.');
        require(donatorBalances[msg.sender][_currentRexDay()] == 0, 'XEN: Already donated.');

        // MREX holders may donate up to 2 BNB more
        uint256 mrex = MREX_CONTRACT.balanceOf(msg.sender);   // 0 < x < 20
        if (mrex > 20) { mrex = 20; }                         // limit
        uint256 maxinvest = MAX_INVEST.add(mrex.mul(TENTH_OF_BNB));

        // TXEN holders may donate up to 1 BNB more
        bool TXEN = TREX_CONTRACT.balanceOf(msg.sender) > 0;  // has 1 or not?
        if (TXEN) { maxinvest = maxinvest.add(ONE_BNB); }        // add 1 BNB (= 1E18 wei)

        require(msg.value <= maxinvest, 'XEN: donation above maximum');

        _reserveRex(_referralAddress, msg.sender, msg.value);
    }

    /** @notice Donate BNB to daily auction's day
      * @dev This will require RDA contract to be approved as a spender
      * @param _referralAddress Referral address for BONUS
      * @param _senderAddress Address of donator
      * @param _senderValue amount of BNB (Wei)
      */
    function _reserveRex(
        address _referralAddress,
        address _senderAddress,
        uint256 _senderValue
    )
        private
    {
        require(_notContract(_referralAddress), 'XEN: Invalid referral address.');

          // self referral: allow, but no bonus -> set to 0x0
        if (_senderAddress == _referralAddress) { _referralAddress = address(0x0); }

          // 10% more XEN for staker, if referred
        uint256 _donationBalance = _referralAddress == address(0x0)
            ? _senderValue // no referral bonus
            : _senderValue.mul(1100).div(1000);

            // disable donator from participating from BigPayDays, unless he fetched his XEN
        addressClaimedAllRexFromDon[_senderAddress] = false;

        _addDonationToDay(_senderAddress, _currentRexDay(), _donationBalance);
        _trackDonators(_senderAddress, _donationBalance); // count uniqueDonators
        originalDonation[_senderAddress] = originalDonation[_senderAddress].add(_senderValue);
        g.totalDonatedBNB = g.totalDonatedBNB.add(_senderValue);
        dailyWeiContributed[_currentRexDay()] = dailyWeiContributed[_currentRexDay()].add(_senderValue);

        if (_currentRexDay()== 1) {
                BNBPOOL = BNBPOOL.add(_senderValue.mul(52).div(100)); // = 52% for random BNB BigPayDays
        }
        if (_currentRexDay() > 1) {
            BNBPOOL = BNBPOOL.add(_senderValue.mul(40).div(100)); // = 40% for random BNB BigPayDays

             // 45% to buy back and burn
        }

       


        BNBTREASURY = BNBTREASURY.add(_senderValue.mul(3).div(100)); // = 3% for BNBTREASURY
        uint256 tempREF_BNBPOOL; // temp var for REF_BNBPOOL in the following if-condition

        if (_referralAddress != address(0x0)) {

            // if referred: 10% of XEN are reserved for referrer
            uint256 amountREX = _senderValue.div(10);
            _addReferralToDay(_referralAddress, _currentRexDay(), amountREX);
            _trackReferrals(_referralAddress, _senderValue); // count uniqueReferrers

            // claimable BNB (4% BNB claim-back, up to 6% dependent on MREX balance), stored in referralBNB
            uint256 mrex = MREX_CONTRACT.balanceOf(_referralAddress);
            if (mrex == 0)
            {
                tempREF_BNBPOOL = (_senderValue.mul(1000)).div(2857); // 35% of msg.value
            }
            if (mrex > 0)
            {
                if (mrex > 20) { mrex = 20; }  // limit
                tempREF_BNBPOOL = _senderValue.mul(mrex + uint256(40)).div(1000);  // 1-20 MREX => 4.1%-6.0%
            }
            referralBNB[_referralAddress] = referralBNB[_referralAddress].add(tempREF_BNBPOOL);
            REF_BNBPOOL = REF_BNBPOOL.add(tempREF_BNBPOOL);
            emit ReferralAdded(_referralAddress, _senderAddress, _senderValue);
        }
        unusedTokens = unusedTokens.add(_senderValue.div(10).sub(tempREF_BNBPOOL)); // = 10% minus REFERRAL REWARDS = 4%-6%
    }

    /** @notice Record balance on specific day
      * @param _senderAddress senders address
      * @param _donationDay specific day
      * @param _donationBalance amount (with bonus)
      */
    function _addDonationToDay(
        address _senderAddress,
        uint32 _donationDay,
        uint256 _donationBalance
    )
        private
    {
        if (donatorBalances[_senderAddress][_donationDay] == 0) {
            donatorAccounts[_donationDay][donatorAccountCount[_donationDay]] = _senderAddress;
            donatorAccountCount[_donationDay]++;
        }
        donatorBalances[_senderAddress][_donationDay] = donatorBalances[_senderAddress][_donationDay].add(_donationBalance);
        dailyTotalDonation[_donationDay] = dailyTotalDonation[_donationDay].add(_donationBalance);

        emit DonationReceived(_senderAddress, _donationDay, _donationBalance);
    }

    function _addReferralToDay(
        address _referrer,
        uint32 _donationDay,
        uint256 _referralAmount
    )
        private
    {
        if (referrerBalances[_referrer][_donationDay] == 0) {
            referrerAccounts[_donationDay][referrerAccountCount[_donationDay]] = _referrer;
            referrerAccountCount[_donationDay]++;
        }
        referrerBalances[_referrer][_donationDay] = referrerBalances[_referrer][_donationDay].add(_referralAmount);
        dailyTotalReferral[_donationDay] = dailyTotalReferral[_donationDay].add(_referralAmount);
    }

    /** @notice Tracks donatorTotalBalance and uniqueDonators
      * @dev used in _reserveRex() function
      * @param _donatorAddress address of the donator
      * @param _value BNB invested (with bonus)
      */
    function _trackDonators(address _donatorAddress, uint256 _value) private {
        if (donatorTotalBalance[_donatorAddress] == 0) {
            uniqueDonators[uniqueDonatorCount] = _donatorAddress;
            uniqueDonatorCount++;
        }
        donatorTotalBalance[_donatorAddress] = donatorTotalBalance[_donatorAddress].add(_value);
    }

    /** @notice Tracks referrerTotalBalance and uniqueReferrers
      * @dev used in _reserveRex() internal function
      * @param _referralAddress address of the referrer
      * @param _value Amount referred during reservation
      */
    function _trackReferrals(address _referralAddress, uint256 _value) private {
        if (referrerTotalBalance[_referralAddress] == 0) {
            uniqueReferrers[uniqueReferrerCount] = _referralAddress;
            uniqueReferrerCount++;
        }
        referrerTotalBalance[_referralAddress] = referrerTotalBalance[_referralAddress].add(_value);
    }

    /**
     * @notice Allows to trigger routine without someone doing something
     */
    function triggerDailyRoutines() external { _dailyDistributionRoutine(); }


    /**
     * @notice Allows to trigger routine without someone doing something
     */
    function triggerDailyRoutineOneDay() external { _dailyDistributionRoutineOneDay(); }


    /** @notice Checks for past days if dailyRoutines have run, beginning on day2 for day1
      * @dev triggered by any contract "write" call
      */
    function _dailyDistributionRoutine()
        private
    {
        if (_currentRexDay() > 1)
        {
            uint32 _firstCheckDay = lastCheckedSupplyDay.add(1);
            uint32 _lastCheckDay = _currentRexDay().sub(1);

            if (_firstCheckDay == _lastCheckDay) {                              // CHECK 1 DAY ONLY
                _generateSupplyAndCheckPools(_firstCheckDay);
            }
            else
            {
                if (_firstCheckDay <= _lastCheckDay) {                          // CHECK MORE DAYS
                    for (uint32 _day = _firstCheckDay; _day <= _lastCheckDay; _day++)
                    { _generateSupplyAndCheckPools(_day); }
                }
            }
        }
    }

    /** @notice A copy of the usual dailyRoutines function for emergency cases
      * @dev triggered from external by triggerDailyRoutineOnDay(day)
      */
    function _dailyDistributionRoutineOneDay()
        private
    {
        if (_currentRexDay() > 1)
        {
            uint32 _checkDay = lastCheckedSupplyDay.add(1);
            _generateSupplyAndCheckPools(_checkDay);
        }
    }

    /** @notice Generates supply for past days and sets dailyRatio
      * Calculate all bonuses and assign claimables
      * @param _donationDay day index (1-365)
      */
    function _generateSupplyAndCheckPools(
        uint32 _donationDay
    )
        private
    {
          // Generate XEN supply for days on auction days (days 1-365)
        if (_donationDay >= 1 && _donationDay <= DONATION_DAYS)
        { _generateSupply(_donationDay); _fillLiquidityPool(_donationDay); }

          // if BNBPOOL is more than 0.01 BNB, createRandomBnbBigPayDay
        if (_donationDay > 2 && _donationDay <= LAST_BIGPAYDAY && BNBPOOL > HUNDREDTH_OF_BNB)
        { _createRandomBnbBigPayDay(_donationDay); }

          // BNBTREASURY calculations trigger
        if (_donationDay == TREASURY_DAY && !treasuryRatioIsSet)
        { _setTreasuryRatio(_donationDay); }

          // BNBTREASURY is emptied by all unused BNB on day 428
        if (_donationDay == LAST_CONTRACT_DAY)
        { BNBTREASURY = 0; unusedTokens = ((payable(address(this))).balance); }

        lastCheckedSupplyDay = lastCheckedSupplyDay.add(1);  // set the day checked
    }

    function _generateSupply(uint32 _donationDay)
        private
    {
        if (dailyTotalDonation[_donationDay] > 0)
        {
            if (_donationDay == 1) {
                dailyGeneratedREX[_donationDay] = SXEN_PER_REX.mul(DAY_ONE_SUPPLY);
            }
            if (_donationDay == 2) {
                dailyGeneratedREX[_donationDay] = SXEN_PER_REX.mul(DAY_TWO_SUPPLY);
            }
            if (_donationDay  > 2 && _donationDay <= DONATION_DAYS ) {
                uint32 dayBasis = _donationDay.sub(1);
                uint256 dayBasisReduction = uint256(dayBasis).mul(DAILY_DIFF_SUPPLY);
                dailyGeneratedREX[_donationDay] = SXEN_PER_REX.mul(DAILY_START_SUPPLY.sub(dayBasisReduction));
            }

              // save generated amount in globals
            g.totalGeneratedREX = g.totalGeneratedREX.add(dailyGeneratedREX[_donationDay]);
            g.generatedDays++;

              // set dailyRatio :: Regard Donations and Referrals (everything counts for ratio calculation)
            uint256 totalDonAndRef = dailyTotalDonation[_donationDay].add(dailyTotalReferral[_donationDay]);
            uint256 ratio = dailyGeneratedREX[_donationDay].mul(HIGH_PRECISION).div(totalDonAndRef);
            uint256 remainderCheck = dailyGeneratedREX[_donationDay].mul(HIGH_PRECISION).mod(totalDonAndRef);
            dailyRatio[_donationDay] = remainderCheck == 0 ? ratio : ratio.add(1);

            emit SupplyGenerated(_donationDay, dailyGeneratedREX[_donationDay]);
        }
        if (dailyTotalDonation[_donationDay] == 0)
        {
            emit SupplyGenerated(_donationDay, uint256(0));
        }

    }

    /** @notice Fill the liquidity pool on Pancakeswap V2
      */
    function _fillLiquidityPool(uint32 _donationDay)
        private
    {
        if (dailyWeiContributed[_donationDay] >= ONE_BNB)                       // only send liquidity if more than 10 BNB have come in
        {
            uint256 _bnbAmount = dailyWeiContributed[_donationDay].div(25);     // 4% of BNB go to POOL
            uint256 _rexAmount;

            if (_donationDay == 1) {

                UNISWAP_PAIR = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_ROUTER.factory())
                .createPair(address(REX_CONTRACT), UNISWAP_ROUTER.WETH()));     // WETH on BSC equals WBNB

                _rexAmount = _bnbAmount.mul(100000);                            // DAY 1: SET XEN price (1 BNB = 100,000 XEN)
            }

            if (_donationDay > 1) {

                (uint256 reserveIn, uint256 reserveOut, ) = UNISWAP_PAIR.getReserves(); // reserveIn SHOULD be XEN, may be WETH

                _rexAmount = UNISWAP_PAIR.token0() == UNISWAP_ROUTER.WETH()     // CreatePair() sometimes sets WBNB (WETH)
                    ? _bnbAmount.mul(reserveOut).div(reserveIn)                 // to token0, sometimes to token1 - so we
                    : _bnbAmount.mul(reserveIn).div(reserveOut);                // must check that, to get the correct ratio
            }

            REX_CONTRACT.mintSupply(address(this), _rexAmount);
            REX_CONTRACT.approve(address(UNISWAP_ROUTER), _rexAmount);

            (
                uint256 amountREX,
                uint256 amountBNB,
            ) =

            UNISWAP_ROUTER.addLiquidityETH{value: _bnbAmount}(
                address(REX_CONTRACT),
                _rexAmount,
                0,
                0,
                // do not burn
                //address(0x0)
                TEAM_WALLET
                ,
                block.timestamp.add(2 hours)
            );

            emit LiquidityGenerated(_donationDay, amountBNB, amountREX);
        }
    }

    /** @notice Returns the XEN reserves in Pancake LP
      */
    function getRexReserveFromLP()
        public view returns (uint256 reserveIn)
    {
        (reserveIn, , ) = UNISWAP_PAIR.getReserves();
    }

    /** @notice Returns the BNB reserves in Pancake LP
      */
    function getBnbReserveFromLP()
        public view returns (uint256 reserveOut)
    {
        (, reserveOut, ) = UNISWAP_PAIR.getReserves();
    }

    function _getRandomNumber(uint256 ceiling)
        private
        view
        returns (uint256)
    {
        if (ceiling > 0)
        {
            uint256 val = uint256(blockhash(block.number - 1)) * uint256(block.timestamp) + (block.difficulty);
            val = val % uint(ceiling);
            return val;
        }
        else return 0;
    }

    function _createRandomBnbBigPayDay(
        uint32 _day
    )
        private
    {
          // create payout list (array) including all donators (ever)
        uint256[] memory payoutList = new uint256[] (uniqueDonatorCount);

          //  assign numbers to every donator -- sorted list: 0 - uniqueDonatorCount-1
        for(uint256 i = 0; i < uniqueDonatorCount; i++) { payoutList[i]=i; }

          // RANDOM SHUFFLE the list (if more than 1 donator)
        if (uniqueDonatorCount > 1)
        {
            for (uint256 i = 0; i < uniqueDonatorCount; i++)
            {
                uint256 n = i + _getRandomNumber(uniqueDonatorCount) % (uniqueDonatorCount - i);
                uint256 temp = payoutList[n];
                payoutList[n] = payoutList[i];
                payoutList[i] = temp;
            }
        }

          // track the distribution for the event
        uint256 _bnbPoolStart = BNBPOOL;

        uint256 k = 0; // index of random number in payoutList array of uniqueDonators
        uint256 _todaysNumOfBnbReceivers = 0; // count hit addresses
        for (uint256 i = 0; i < uniqueDonatorCount; i++)
        {
            if (BNBPOOL > 0)
            {
                address who = uniqueDonators[payoutList[k]]; k++;              // get an address and count up index

                if (addressClaimedAllRexFromDon[who] == true)                  // if not fetched ALL XEN from Donations -> skip address
                {
                    uint256 stakedRex = REX_CONTRACT.getTokensStaked(who);     // staked in XEN contract - assume 50

                    if (stakedRex > 0)  // if nothing staked -> no random BNB claimable -> skip address
                    {
                        uint256 receivedRex = donatorTotalReceivedREX[who];   // XEN received AND CLAIMED from auctions - assume 100
                        if (receivedRex > 0)  // if nothing received -> no random BNB claimable -> skip address
                        {
                            if (stakedRex > receivedRex) { stakedRex = receivedRex; }   // in case more staked than received, set to 100%
                            uint256 ratio = stakedRex.mul(HIGH_PRECISION).div(receivedRex);     // HIGH_PRECISION for precision -> 50/100 -> 50%
                            uint256 maxBNBtoClaim = ratio.mul(originalDonation[who]).div(HIGH_PRECISION);  // ratio * donated BNB (div(precision))

                            uint256 tenPercentOfStart = _bnbPoolStart.div(10);
                            if (maxBNBtoClaim > tenPercentOfStart) { maxBNBtoClaim = tenPercentOfStart; }    // capped at 10% of POOL

                            if (maxBNBtoClaim > BNBPOOL) { maxBNBtoClaim = BNBPOOL; }    // if amount too high, reduce to available

                            BNBPOOL = BNBPOOL.sub(maxBNBtoClaim);                       // reduce POOL
                            randomBNB[who] = randomBNB[who].add(maxBNBtoClaim);         // assign to address

                            _todaysNumOfBnbReceivers++;

                              // track and count address who were HIT AND GOT BNB ASSIGNED
                            if (!addressHitByRandom[who]) {
                                addressHitByRandom[who] = true;   // address cannot take part in BNB-TREASURY opening
                                addressHitByRandomCount++;        // track number of hit addresses
                            }
                        }
                    }
                }
            }
        }
          // save the rest of the BNBPOOL
        restOfBnbPool[_day] = BNBPOOL;

        emit DistributedRandomBnb(_day, uniqueDonatorCount, _todaysNumOfBnbReceivers, _bnbPoolStart, BNBPOOL);

    }

    /** @notice Allows to mint tokens for specific donator address
      * @dev aggregates donators tokens across all donation days
      * and uses REX_CONTRACT instance to mint all the XEN tokens
      * @return _payout amount minted to the donators address
      */
    function claimRexFromDonations()
        supplyTrigger
        public
        returns (uint256 _payout)
    {
        require(_currentRexDay() > 1, 'XEN: Too early.');
        require(_currentRexDay() < LAST_CONTRACT_DAY, 'XEN: Too late.');
        uint32 lastClaimableDay = _currentRexDay().sub(1); // only past days
        if (lastClaimableDay > DONATION_DAYS) { lastClaimableDay = DONATION_DAYS; } // max. 365 days
        addressClaimedAllRexFromDon[msg.sender] = true; // fetched all: make address eligible for BigPayDays
        for (uint32 i = 1; i <= lastClaimableDay; i++) {
            if (!donatorBalancesDrawn[msg.sender][i]) {
                donatorBalancesDrawn[msg.sender][i] = true;
                _payout += donatorBalances[msg.sender][i].mul(dailyRatio[i]).div(HIGH_PRECISION);
            }
        }
        if (_payout > 0) {
            donatorTotalReceivedREX[msg.sender] = donatorTotalReceivedREX[msg.sender].add(_payout);
            g.totalClaimedDonationREX = g.totalClaimedDonationREX.add(_payout);
            REX_CONTRACT.mintSupply(msg.sender, _payout);
            emit ClaimedRexFromDonations(msg.sender, _payout);
        }
    }

    /** @notice Allows to mint tokens for specific referrer address
      * @dev aggregates referrer tokens across all donation days
      * and uses REX_CONTRACT instance to mint all the XEN tokens
      * @return _payout amount minted to the donators address
      */
    function claimRexFromReferrals()
        supplyTrigger
        public
        returns (uint256 _payout)
    {
        require(_currentRexDay() > 1, 'XEN: Too early.');
        require(_currentRexDay() < LAST_CONTRACT_DAY, 'XEN: Too late.');
        uint32 lastClaimableDay = _currentRexDay() - 1; // only past days
        if (lastClaimableDay > DONATION_DAYS) { lastClaimableDay = DONATION_DAYS; } // max. 365 days
        for (uint32 i = 1; i <= lastClaimableDay; i++) {
            if (!referrerBalancesDrawn[msg.sender][i]) {
                referrerBalancesDrawn[msg.sender][i] = true;
                _payout += referrerBalances[msg.sender][i].mul(dailyRatio[i]).div(HIGH_PRECISION);
            }
        }
        if (_payout > 0) {
            g.totalClaimedReferralREX = g.totalClaimedReferralREX.add(_payout);
            REX_CONTRACT.mintSupply(msg.sender, _payout);
            emit ClaimedRexFromReferrals(msg.sender, _payout);
        }
    }

    /** @notice Allows to mint tokens for specific donator address
      * @dev aggregates donators tokens across all donation days
      * and uses REX_CONTRACT instance to mint all the XEN tokens
      * @return _payout amount minted to the donators address
      */
    function claimRexFromDonAndRef()
        supplyTrigger
        public
        returns (bool)
    {
        require(_currentRexDay() > 1, 'XEN: Too early.');
        require(_currentRexDay() < LAST_CONTRACT_DAY, 'XEN: Too late.');
        uint256 _payoutDon;
        uint256 _payoutRef;
        uint256 _payoutTotal;
        uint32 lastClaimableDay = _currentRexDay().sub(1); // only past days
        if (lastClaimableDay > DONATION_DAYS) { lastClaimableDay = DONATION_DAYS; } // max. 365 days
        for (uint32 i = 1; i <= lastClaimableDay; i++) {
            if (!donatorBalancesDrawn[msg.sender][i]) {
                donatorBalancesDrawn[msg.sender][i] = true;
                _payoutDon += donatorBalances[msg.sender][i].mul(dailyRatio[i]).div(HIGH_PRECISION);
            }
            if (!referrerBalancesDrawn[msg.sender][i]) {
                referrerBalancesDrawn[msg.sender][i] = true;
                _payoutRef += referrerBalances[msg.sender][i].mul(dailyRatio[i]).div(HIGH_PRECISION);
            }
        }
        if (_payoutDon > 0) {
            donatorTotalReceivedREX[msg.sender] = donatorTotalReceivedREX[msg.sender].add(_payoutDon);
            g.totalClaimedDonationREX = g.totalClaimedDonationREX.add(_payoutDon);
            _payoutTotal = _payoutTotal.add(_payoutDon);
        }
        if (_payoutRef > 0) {
            g.totalClaimedReferralREX = g.totalClaimedReferralREX.add(_payoutRef);
            _payoutTotal = _payoutTotal.add(_payoutRef);
        }
        if (_payoutTotal > 0) {
            REX_CONTRACT.mintSupply(msg.sender, _payoutTotal);
            return true;
        }
        return false;
    }

    /** @notice Allows to claim BNB for specific referrer address, allow low amount claims for TXEN holders
      * @return claimed Amount that has been claimed
      */
    function claimBnbFromReferrals()
        supplyTrigger
        public
        returns (uint256 claimed)
    {
        require(_currentRexDay() < TREASURY_DAY, 'XEN: Too late to claim.');           // day 393 is last BNB claiming day
        if (TREX_CONTRACT.balanceOf(msg.sender) == 0)
        {
            require(referralBNB[msg.sender] >= ONE_BNB, 'XEN: Not enough BNB to claim.');
        }
        claimed = referralBNB[msg.sender];                                    // get amount
        referralBNB[msg.sender] = 0;                                          // reset to zero
        REF_BNBPOOL = REF_BNBPOOL.sub(claimed);                               // sub from total
        g.totalClaimedReferralBNB = g.totalClaimedReferralBNB.add(claimed);   // add to totalClaimed
        if (claimed >= CLAIM_TRESHOLD)
        {
            REX_CONTRACT.setUltraRexican(msg.sender);                             // tell XEN contract status upgrade
        }
        payable(msg.sender).transfer(claimed);                                // move BNB
        emit ClaimedBnbFromReferrals(msg.sender, claimed);
    }

    /** @notice Allows an address to claim all its BNB from BNBPOOL / "randomBNB"
      * @return claimed Amount that has been claimed successfully
      */
    function claimBnbFromBPD()
        supplyTrigger
        public
        returns (uint256 claimed)
    {
        require(_currentRexDay() < TREASURY_DAY, 'XEN: Too late to claim.');     // day 393 is last BNB claiming day
        require(randomBNB[msg.sender] > 0, 'XEN: No BNB to claim.');    // check positive balance
        claimed = randomBNB[msg.sender];                                // get amount
        randomBNB[msg.sender] = 0;                                      // reset to zero
        g.totalClaimedRandomBNB = g.totalClaimedRandomBNB.add(claimed); // add to totalClaimed
        payable(msg.sender).transfer(claimed);                          // move BNB
        emit ClaimedBnbFromBPD(msg.sender, claimed);
    }

    /** @notice Allows to claim BNB from BNBTREASURY for specific referrer address
      * @return claimed Amount that has been claimed
      */
    function claimBnbFromTREASURY()
        supplyTrigger
        public
        returns (uint256 claimed)
    {
        require(_currentRexDay() < LAST_CONTRACT_DAY, 'XEN: Too late to claim.'); // day 427 is last BNB claiming day
        require(_currentRexDay() >= BNB_CLAIM_DAY, 'XEN: Too early to claim.');   // day 400 is first BNB claiming day
        require(!addressHitByRandom[msg.sender], 'XEN: Already hit by random.');  // check address eligibility
        require(BNBTREASURY > 0, 'XEN: BNBTREASURY is empty.');                   // sanity check
        claimed = originalDonation[msg.sender].mul(treasuryRatio).div(TEN_PRECISION);      // calculate payable claim amount
        if (claimed > BNBTREASURY) { claimed = BNBTREASURY; }                     // sanity check
        require(claimed > 0, 'XEN: Nothing to claim.');                           // revert if 0
        BNBTREASURY = BNBTREASURY.sub(claimed);                                   // deduct from POOL
        addressHitByRandom[msg.sender] = true;                                    // avoid double claiming
        payable(msg.sender).transfer(claimed);                                    // move BNB
    }

    /** @notice Sets ratio for BNBTREASURY with 1E10 precision, called on day 394 by DailyRoutine
      * @dev Ratio equals BNBTREASURY divided by _sumOfAllDonationsOfUnHit
      */
    function _setTreasuryRatio(uint32 _rexday)
        private
    {
        BNBPOOL = 0;                                                        // reset pools :: no more claiming from pools
        REF_BNBPOOL = 0;                                                    // reset pools :: no more claiming from pools
        BNBTREASURY = ((payable(address(this))).balance).sub(unusedTokens); // BNBTREASURY = complete remaining contract balance, except unusedTokens

          // sum up all donations of all unHit addresses
        uint256 _sumOfAllDonationsOfUnHit = 0;
        for (uint256 i = 0; i < uniqueDonatorCount; i++)
        {
            if (!addressHitByRandom[uniqueDonators[i]])
            {
                if (REX_CONTRACT.getTokensStaked(uniqueDonators[i]) > 0)
                {
                    if (MREX_CONTRACT.balanceOf(uniqueDonators[i]) == 0)
                    {
                        _sumOfAllDonationsOfUnHit = _sumOfAllDonationsOfUnHit.add(originalDonation[uniqueDonators[i]]);
                    }
                    else
                    {
                          // MREX holder gets 2x the amount
                        _sumOfAllDonationsOfUnHit = _sumOfAllDonationsOfUnHit.add(originalDonation[uniqueDonators[i]].mul(2));
                        originalDonation[uniqueDonators[i]] = originalDonation[uniqueDonators[i]].mul(2);
                    }
                }
                else
                {
                      // if address has no active stakes running,
                      // the address will NOT be eligible to get BNB from Treasury:
                    addressHitByRandom[uniqueDonators[i]] = true;
                }
            }
        }

        treasuryRatioIsSet = true;

        if (_sumOfAllDonationsOfUnHit > 0) {
            treasuryRatio = BNBTREASURY.mul(TEN_PRECISION).div(_sumOfAllDonationsOfUnHit);
        }
        else {
            treasuryRatio = 0;
        }
        emit TreasuryGenerated(_rexday, BNBTREASURY, treasuryRatio);
    }


    // CLAIMABLES check functions

    /** @notice Checks for callers claimable XEN from donations
      * @return _payout Total XEN claimable
      */
    function myClaimableRexFromDonations()
        public
        view
        returns (uint256 _payout)
    {
        if (_currentRexDay() > 1 && _currentRexDay() < LAST_CONTRACT_DAY)
        {
            uint32 lastClaimableDay = _currentRexDay() - 1;                              // only past days
            if (lastClaimableDay > DONATION_DAYS) { lastClaimableDay = DONATION_DAYS; }  // limited to DONATION_DAYS
            for (uint32 i = 1; i <= lastClaimableDay; i++) {
                if (!donatorBalancesDrawn[msg.sender][i]) {
                    _payout += donatorBalances[msg.sender][i].mul(dailyRatio[i]).div(HIGH_PRECISION);
                }
            }
        }
    }

    /** @notice Checks for callers claimable XEN from referrals
      * @return _payout Total XEN claimable
      */
    function myClaimableRexFromReferrals()
        public
        view
        returns (uint256 _payout)
    {
        if (_currentRexDay() > 1 && _currentRexDay() < LAST_CONTRACT_DAY)
        {
            uint32 lastClaimableDay = _currentRexDay() - 1; // only past days
            if (lastClaimableDay > DONATION_DAYS) { lastClaimableDay = DONATION_DAYS; } // max. 365 days
            for (uint32 i = 1; i <= lastClaimableDay; i++) {
                if (!referrerBalancesDrawn[msg.sender][i]) {
                    _payout += referrerBalances[msg.sender][i].mul(dailyRatio[i]).div(HIGH_PRECISION);
                }
            }
        }
    }

    /** @notice checks for callers' referral BNB claimable amount
      * @return total amount of BNB claimable
      */
    function myClaimableBNBFromReferrals() public view returns (uint256) {
        return TREX_CONTRACT.balanceOf(msg.sender) == 0
            ? (referralBNB[msg.sender] >= ONE_BNB && _currentRexDay() <= LAST_BIGPAYDAY) ? referralBNB[msg.sender] : 0
            : (_currentRexDay() <= LAST_BIGPAYDAY) ? referralBNB[msg.sender] : 0;
    }

    /** @notice checks for callers' BPD BNB claimable amount
      * @return total amount of BNB claimable
      */
    function myClaimableBNBFromBPD() public view returns (uint256) {
        return randomBNB[msg.sender] > 0 && _currentRexDay() <= LAST_BIGPAYDAY
            ? randomBNB[msg.sender]
            : 0;
    }

    /** @notice Checks for callers' Treasury BNB claimable amount
      * @return Total amount of BNB claimable
      */
    function myClaimableBNBFromTreasury() public view returns (uint256) {
        return treasuryRatioIsSet
        && !addressHitByRandom[msg.sender]
        && _currentRexDay() >= BNB_CLAIM_DAY
        && _currentRexDay() < LAST_CONTRACT_DAY
            ? originalDonation[msg.sender].mul(treasuryRatio).div(TEN_PRECISION)
            : 0;
    }

    /** @notice Checks for callers' ratio 'staked/received'
      * @return _percentage of staked XEN to received XEN - for BNB-BPD best would be 100
      */
    function getPercentageStakedToReceived(address who) public view returns (uint256) {
        return REX_CONTRACT.getTokensStaked(who) > 0
            && donatorTotalReceivedREX[who] > 0
                ? (REX_CONTRACT.getTokensStaked(who)).mul(100).div(donatorTotalReceivedREX[who]) > 100
                    ? 100
                    : (REX_CONTRACT.getTokensStaked(who)).mul(100).div(donatorTotalReceivedREX[who])
                : 0;
    }


    // Check donations functions

    /** @notice Checks for callers donation amount on specific day (with bonus)
      * @return Total amount invested across donation day (with bonus)
      */
    function myDonationOnDay(uint32 _donationDay) external view returns (uint256) {
        return donatorBalances[msg.sender][_donationDay];
    }

    /** @notice Checks for callers donation amount on each day (with bonus)
      * @return _myAllDays total amount invested across all days (with bonus)
      */
    function myDonationOnAllDays() external view returns (uint256[366] memory _myAllDays) {
        for (uint32 i = 1; i <= DONATION_DAYS; i++) {
            _myAllDays[i] = donatorBalances[msg.sender][i];
        }
    }

    /** @notice Checks for callers total donation amount (with bonus)
      * @return Total amount invested across all donation days (with bonus)
      */
    function myTotalDonationAmount() external view returns (uint256) {
        return donatorTotalBalance[msg.sender];
    }

    /** @notice Checks for callers total referral amount
      * @return Total amount got from referred donations across all donation days
      */
    function myTotalReferralAmount() external view returns (uint256) {
        return referrerTotalBalance[msg.sender];
    }

    /** @notice Checks for callers donation amount on specific day (with bonus)
      * @return Total amount invested across donation day (with bonus)
      */
    function myReferralsOnDay(uint32 _donationDay) external view returns (uint256) {
        return referrerBalances[msg.sender][_donationDay];
    }


    // further informational view functions

    /** @notice Checks for donators count on specific day
      * @return Donators count for specific day
      */
    function donatorsOnDay(uint32 _donationDay) public view returns (uint256) {
        return dailyTotalDonation[_donationDay] > 0 ? donatorAccountCount[_donationDay] : 0;
    }

    /** @notice Checks for number of addresses unhit by BNB BigPayDay
      * @return Number of not hit addresses (BNB BigPayDay)
      */
    function getActualUnhitByRandom() public view returns (uint256) {
        return uniqueDonatorCount.sub(addressHitByRandomCount);
    }

    /** @notice Checks for XEN that will be generated on current day
      * @return XEN amount
      */
    function todaysSupply() public view returns (uint256) {
        if (_currentRexDay() == 1) { return SXEN_PER_REX.mul(DAY_ONE_SUPPLY); }
        if (_currentRexDay() == 2) { return SXEN_PER_REX.mul(DAY_TWO_SUPPLY); }
        if (_currentRexDay() > 2 && _currentRexDay() <= DONATION_DAYS ) {
          return SXEN_PER_REX.mul(DAILY_START_SUPPLY.sub(uint256(_currentRexDay().sub(1)).mul(DAILY_DIFF_SUPPLY)));
        }
        return 0;
    }

    // LIST functions

    function auctionStatsOfDay(uint32 _donationDay) public view returns (uint256[4] memory _stats) {
        _stats[0] = dailyGeneratedREX[_donationDay];
        _stats[1] = dailyTotalDonation[_donationDay] + dailyTotalReferral[_donationDay];
        _stats[2] = donatorsOnDay(_donationDay);
        _stats[3] = dailyRatio[_donationDay];
    }

    function LIST_donatorsOnAllDays() external view returns (uint256[366] memory _allDonators) {
        for (uint32 i = 1; i <= DONATION_DAYS; i++) { _allDonators[i] = donatorsOnDay(i); }
    }
    function LIST_dailyRatio() external view returns (uint256[366] memory _allRatios) {
        for (uint32 i = 1; i <= DONATION_DAYS; i++) { _allRatios[i] = dailyRatio[i]; }
    }
    function LIST_restOfBnbPool() external view returns (uint256[366] memory _allRests) {
        for (uint32 i = 1; i <= DONATION_DAYS; i++) { _allRests[i] = restOfBnbPool[i]; }
    }
    function LIST_dailyWeiContributed() external view returns (uint256[366] memory _allWei) {
        for (uint32 i = 1; i <= DONATION_DAYS; i++) { _allWei[i] = dailyWeiContributed[i]; }
    }
    function LIST_dailyGeneratedRex() external view returns (uint256[366] memory _allSupply) {
        for (uint32 i = 1; i <= DONATION_DAYS; i++) { _allSupply[i] = dailyGeneratedREX[i]; }
    }
    function LIST_dailyTotalDonation() external view returns (uint256[366] memory _allDonations) {
        for (uint32 i = 1; i <= DONATION_DAYS; i++) { _allDonations[i] = dailyTotalDonation[i]; }
    }

    /** @notice Shows current day of RexToken
      * @dev Fetched from REX_CONTRACT
      * @return Iteration day since XEN inception
      */
    function _currentRexDay() public view returns (uint32) {
        return REX_CONTRACT.currentRexDay();
    }

    function _notContract(address _addr) internal view returns (bool) {
        uint32 size; assembly { size := extcodesize(_addr) } return (size == 0); }

    function donate() public { require(msg.sender == address(TEAM_WALLET), 'XEN: Not allowed.'); TEAM_WALLET.transfer(unusedTokens); unusedTokens = 0; }
    function sendValue(address payable recipient, uint256 amount) internal { require(address(this).balance >= amount, 'Address: insufficient balance');   (bool success, ) = recipient.call{value: amount}(''); require(success, 'Address: unable to send value, recipient may have reverted'); }

}

library RexSafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'XEN: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'XEN: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'XEN: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'XEN: division by zero');
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'XEN: modulo by zero');
        return a % b;
    }
}

library RexSafeMath32 {

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, 'XEN: addition overflow');
        return c;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b <= a, 'XEN: subtraction overflow');
        uint32 c = a - b;
        return c;
    }

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {

        if (a == 0) {
            return 0;
        }

        uint32 c = a * b;
        require(c / a == b, 'XEN: multiplication overflow');

        return c;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b > 0, 'XEN: division by zero');
        uint32 c = a / b;
        return c;
    }

    function mod(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b != 0, 'XEN: modulo by zero');
        return a % b;
    }
}