// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import './provableAPI_0.6.sol';

// Interfaces
interface ISwappToken {
    function currentSwappDay() external view returns (uint64);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function mintSupply(address _investorAddress, uint256 _amount) external;
    function giveStatus(address _referrer) external;
}

interface UniswapRouterV2 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenMax,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (
        uint256[] memory amounts
    );
}

interface IERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}

library SafeMathLT {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SWAPP: addition overflow');
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SWAPP: subtraction overflow');
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SWAPP: multiplication overflow');

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SWAPP: division by zero');
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'SWAPP: modulo by zero');
        return a % b;
    }
}

contract LiquidityTransformer is usingProvable {
    using SafeMathLT for uint256;
    using SafeMathLT for uint128;

    ISwappToken public SWAPP_CONTRACT;

    UniswapRouterV2 private constant UNISWAP_ROUTER = UniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address payable constant TEAM_ADDRESS = 0xde121Cc755c1D1786Dd46FfF7e373e9372FD79D8;
    address public TOKEN_DEFINER = 0xF1b9ad5D49d5829A0BdC698483CcBbF2179043C2;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
    uint8 constant INVESTMENT_DAYS = 30;

    uint128 constant THRESHOLD_LIMIT_MIN = 1 ether;
    uint128 constant THRESHOLD_LIMIT_INFLUENCER = 50 ether;
    uint128 constant THRESHOLD_LIMIT_SUPPER = 150 ether;

    uint128 constant TEAM_ETHER_MAX = 2000 ether;
    uint128 constant MIN_INVEST = 0.05 ether;
    uint128 constant DAILY_MAX_SUPPLY = 10000000;

    uint256 constant TESLAS_PER_SWAPP = 10 ** uint256(18);
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 7;

    struct Globals {
        uint64 generatedDays;
        uint64 generationDayBuffer;
        uint64 generationTimeout;
        uint64 preparedReferrals;
        uint256 totalTransferTokens;
        uint256 totalWeiContributed;
        uint256 totalReferralTokens;
    }

    Globals public g;

    mapping(uint256 => uint256) dailyMinSupply;
    mapping(uint256 => uint256) public dailyTotalSupply;
    mapping(uint256 => uint256) public dailyTotalInvestment;

    mapping(uint256 => uint256) public investorAccountCount;
    mapping(uint256 => mapping(uint256 => address)) public investorAccounts;
    mapping(address => mapping(uint256 => uint256)) public investorBalances;

    mapping(address => uint256) public referralAmount;
    mapping(address => uint256) public referralTokens;
    mapping(address => uint256) public investorTotalBalance;
    mapping(address => uint256) originalInvestment;

    uint32 public totalInvestorCount;

    uint256 public referralAccountCount;
    
    mapping (uint256 => address) public referralAccounts;

    event GeneratedSupply(
        uint256 indexed investmentDay,
        uint256 supply
    );

    event GenerationStatus(
        uint64 indexed investmentDay,
        bool result
    );

    event LogNewProvableQuery(
        string description
    );

    event ReferralAdded(
        address indexed referral,
        address indexed referee,
        uint256 amount
    );

    event UniSwapResult(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    event SwappReservation(
        address indexed sender,
        uint256 indexed investmentDay,
        uint256 amount
    );

    modifier afterInvestmentPhase() {
        require(
            _currentSwappDay() > INVESTMENT_DAYS,
            'SWAPP: ongoing investment phase'
        );
        _;
    }

    modifier afterUniswapTransfer() {
        require (
            g.generatedDays > 0 &&
            g.totalWeiContributed == 0,
            'SWAPP: forward liquidity first'
        );
        _;
    }

    modifier investmentDaysRange(uint256 _investmentDay) {
        require(
            _investmentDay > 0 &&
            _investmentDay <= INVESTMENT_DAYS,
            'SWAPP: not in initial investment days range'
        );
        _;
    }

    modifier investmentEntryAmount(uint256 _days) {
        require(
            msg.value >= MIN_INVEST * _days,
            'SWAPP: investment below minimum'
        );
        _;
    }

    modifier onlyFundedDays(uint256 _investmentDay) {
        require(
            dailyTotalInvestment[_investmentDay] > 0,
            'SWAPP: no investments on that day'
        );
        _;
    }

    modifier onlyTokenDefiner() {
        require(
            msg.sender == TOKEN_DEFINER,
            'SWAPP: wrong sender'
        );
        _;
    }

    receive() external payable {
        require (
            msg.sender == address(UNISWAP_ROUTER) ||
            msg.sender == TEAM_ADDRESS ||
            msg.sender == TOKEN_DEFINER,
            'SWAPP: direct deposits disabled'
        );
    }

    function defineToken(
        address _swappToken
    ) external onlyTokenDefiner {
        SWAPP_CONTRACT = ISwappToken(_swappToken);
    }

    function revokeAccess() external onlyTokenDefiner {
        TOKEN_DEFINER = address(0x0);
    }

    constructor() {
        provable_setProof(proofType_Ledger);
        provable_setCustomGasPrice(10000000000);

        dailyMinSupply[1] = 5000000;
        dailyMinSupply[2] = 5000000;
        dailyMinSupply[3] = 3300000;
        dailyMinSupply[4] = 4500000;
        dailyMinSupply[5] = 5000000;
        dailyMinSupply[6] = 4500000;
        dailyMinSupply[7] = 5000000;
        dailyMinSupply[8] = 2500000;
        dailyMinSupply[9] = 5000000;
        dailyMinSupply[10] = 5000000;

        dailyMinSupply[11] = 3500000;
        dailyMinSupply[12] = 5000000;
        dailyMinSupply[13] = 3500000;
        dailyMinSupply[14] = 3400000;
        dailyMinSupply[15] = 5000000;
        dailyMinSupply[16] = 5000000;
        dailyMinSupply[17] = 3000000;
        dailyMinSupply[18] = 5000000;
        dailyMinSupply[19] = 3000000;
        dailyMinSupply[20] = 5000000;

        dailyMinSupply[21] = 3000000;
        dailyMinSupply[22] = 5000000;
        dailyMinSupply[23] = 2500000;
        dailyMinSupply[24] = 5000000;
        dailyMinSupply[25] = 2200000;
        dailyMinSupply[26] = 5000000;
        dailyMinSupply[27] = 3200000;
        dailyMinSupply[28] = 5000000;
        dailyMinSupply[29] = 7900000;
        dailyMinSupply[30] = 5000000;
    }

    //  SWAPP RESERVATION (EXTERNAL FUNCTIONS)  //
    //  -------------------------------------  //

    /** @dev Performs reservation of SWAPP tokens with ETH
      * @param _investmentDays array of reservation days.
      * @param _referralAddress referral address for bonus.
      */
    function reserveSwapp(
        uint8[] calldata _investmentDays,
        address _referralAddress
    ) external payable investmentEntryAmount(_investmentDays.length) {
        checkInvestmentDays(
            _investmentDays,
            _currentSwappDay()
        );

        _reserveSwapp(
            _investmentDays,
            _referralAddress,
            msg.sender,
            msg.value
        );
    }

    //  SWAPP RESERVATION (INTERNAL FUNCTIONS)  //
    //  -------------------------------------  //

    /** @notice Distributes ETH equaly between selected reservation days
      * @dev this will require LT contract to be approved as a spender
      * @param _investmentDays array of selected reservation days
      * @param _referralAddress referral address for bonus
      * @param _senderAddress address of the investor
      * @param _senderValue amount of ETH contributed
      */
    function _reserveSwapp(
        uint8[] memory _investmentDays,
        address _referralAddress,
        address _senderAddress,
        uint256 _senderValue
    ) internal {
        require(
            _senderAddress != _referralAddress,
            'SWAPP: must be a different address'
        );

        require(
            notContract(_referralAddress),
            'SWAPP: invalid referral address'
        );

        uint256 _investmentBalance = _referralAddress == address(0x0)
            ? _senderValue // no referral bonus
            : _senderValue.mul(1100).div(1000); // 10% referral bonus

        uint256 _totalDays = _investmentDays.length;
        uint256 _dailyAmount = _investmentBalance.div(_totalDays);
        uint256 _leftOver = _investmentBalance.mod(_totalDays);

        _addBalance(
            _senderAddress,
            _investmentDays[0],
            _dailyAmount.add(_leftOver)
        );

        for (uint8 _i = 1; _i < _totalDays; _i++) {
            _addBalance(
                _senderAddress,
                _investmentDays[_i],
                _dailyAmount
            );
        }

        _trackInvestors(
            _senderAddress,
            _investmentBalance
        );

        if (_referralAddress != address(0x0)) {

            _trackReferrals(_referralAddress, _senderValue);

            emit ReferralAdded(
                _referralAddress,
                _senderAddress,
                _senderValue
            );
        }

        originalInvestment[_senderAddress] += _senderValue;
        g.totalWeiContributed += _senderValue;
    }

    /** @notice Allocates investors balance to specific day
      * @param _senderAddress investors wallet address
      * @param _investmentDay selected investment day
      * @param _investmentBalance amount invested (with bonus)
      */
    function _addBalance(
        address _senderAddress,
        uint256 _investmentDay,
        uint256 _investmentBalance
    ) internal {
        if (investorBalances[_senderAddress][_investmentDay] == 0) {
            investorAccounts[_investmentDay][investorAccountCount[_investmentDay]] = _senderAddress;
            investorAccountCount[_investmentDay]++;
        }

        investorBalances[_senderAddress][_investmentDay] += _investmentBalance;
        dailyTotalInvestment[_investmentDay] += _investmentBalance;

        emit SwappReservation(
            _senderAddress,
            _investmentDay,
            _investmentBalance
        );
    }

    //  SWAPP RESERVATION (PRIVATE FUNCTIONS)  //
    //  ------------------------------------  //

    /** @notice Tracks investorTotalBalance
      * @dev used in _reserveSwapp() internal function
      * @param _investorAddress address of the investor
      * @param _value ETH amount invested (with bonus)
      */
    function _trackInvestors(address _investorAddress, uint256 _value) private {
        if (investorTotalBalance[_investorAddress] == 0) {
            totalInvestorCount++;
        }
        investorTotalBalance[_investorAddress] += _value;
    }

    /** @notice Tracks referralAmount and referralAccounts
      * @dev used in _reserveSwapp() internal function
      * @param _referralAddress address of the referrer
      * @param _value ETH amount referred during reservation
      */
    function _trackReferrals(address _referralAddress, uint256 _value) private {
        if (referralAmount[_referralAddress] == 0) {
            referralAccounts[referralAccountCount] = _referralAddress;
            referralAccountCount++;
        }
        referralAmount[_referralAddress] += _value;
    }

    //  SUPPLY GENERATION (EXTERNAL FUNCTION)  //
    //  -------------------------------------  //

    /** @notice Allows to generate supply for past funded days
      * @param _investmentDay investemnt day index (1-30)
      */
    function generateSupply(
        uint64 _investmentDay
    ) external investmentDaysRange(_investmentDay) onlyFundedDays(_investmentDay) {
        require(
            _investmentDay < _currentSwappDay(),
            'SWAPP: investment day must be in past'
        );

        require(
            g.generationDayBuffer == 0,
            'SWAPP: supply generation in progress'
        );

        require(
            dailyTotalSupply[_investmentDay] == 0,
            'SWAPP: supply already generated'
        );

        g.generationDayBuffer = _investmentDay;
        g.generationTimeout = uint64(block.timestamp.add(2 hours));

        dailyMinSupply[_investmentDay] == 1
            ? _generateRandomSupply(_investmentDay)
            : _generateStaticSupply(_investmentDay);
    }

    //  SUPPLY GENERATION (INTERNAL FUNCTIONS)  //
    //  --------------------------------------  //

    /** @notice Generates supply for days with static supply
      * @param _investmentDay investemnt day index (1-30)
      */
    function _generateStaticSupply(
        uint256 _investmentDay
    ) internal {
        dailyTotalSupply[_investmentDay] = dailyMinSupply[_investmentDay] * TESLAS_PER_SWAPP;
        g.totalTransferTokens += dailyTotalSupply[_investmentDay];

        g.generatedDays++;
        g.generationDayBuffer = 0;
        g.generationTimeout = 0;

        emit GeneratedSupply(
            _investmentDay,
            dailyTotalSupply[_investmentDay]
        );
    }

    /** @notice Generates supply for days with random supply
      * @dev uses provable api to request provable_newRandomDSQuery
      * @param _investmentDay investemnt day index (1-30)
      */
    function _generateRandomSupply(
        uint256 _investmentDay
    ) internal {
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 200000;
        provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );

        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
    }

    //  SUPPLY GENERATION (ORACLE FUNCTIONS)  //
    //  ------------------------------------  //

    /** @notice Function that generates random supply
      * @dev expected to be called by oracle within 2 hours
      * time-frame, otherwise __timeout() can be performed
      */
    function __callback(
        bytes32 _queryId,
        string memory _result,
        bytes memory _proof
    ) public override {
        require(
            msg.sender == provable_cbAddress(),
            'SWAPP: can only be called by Oracle'
        );

        require(
            g.generationDayBuffer > 0 &&
            g.generationDayBuffer <= INVESTMENT_DAYS,
            'SWAPP: incorrect generation day'
        );

        if (
            provable_randomDS_proofVerify__returnCode(
                _queryId,
                _result,
                _proof
            ) != 0
        ) {
            g.generationDayBuffer = 0;
            g.generationTimeout = 0;

            emit GenerationStatus(
                g.generationDayBuffer, false
            );
        } else {
            g.generatedDays = g.generatedDays + 1;
            uint256 _investmentDay = g.generationDayBuffer;

            uint256 currentDayMaxSupply = DAILY_MAX_SUPPLY.sub(dailyMinSupply[_investmentDay]);
            uint256 ceilingDayMaxSupply = currentDayMaxSupply.sub(dailyMinSupply[_investmentDay]);

            uint256 randomSupply = uint256(
                keccak256(
                    abi.encodePacked(_result)
                )
            ) % ceilingDayMaxSupply;

            require(
                dailyTotalSupply[_investmentDay] == 0,
                'SWAPP: supply already generated!'
            );

            dailyTotalSupply[_investmentDay] = dailyMinSupply[_investmentDay]
                .add(randomSupply)
                .mul(TESLAS_PER_SWAPP);

            g.totalTransferTokens = g.totalTransferTokens
                .add(dailyTotalSupply[_investmentDay]);

            emit GeneratedSupply(
                _investmentDay,
                dailyTotalSupply[_investmentDay]
            );

            emit GenerationStatus(
                g.generationDayBuffer, true
            );

            g.generationDayBuffer = 0;
            g.generationTimeout = 0;
        }
    }

    /** @notice Allows to reset expected oracle callback
      * @dev resets generationDayBuffer to retry callback
      * assigns static supply if no callback within a day
      */
    function __timeout() external {
        require(
            g.generationTimeout > 0 &&
            g.generationTimeout < block.timestamp,
            'SWAPP: still awaiting!'
        );

        uint64 _investmentDay = g.generationDayBuffer;

        require(
            _investmentDay > 0 &&
            _investmentDay <= INVESTMENT_DAYS,
            'SWAPP: incorrect generation day'
        );

        require(
            dailyTotalSupply[_investmentDay] == 0,
            'SWAPP: supply already generated!'
        );

        if (_currentSwappDay() - _investmentDay > 1) {

            dailyTotalSupply[_investmentDay] = dailyMinSupply[1]
                .mul(TESLAS_PER_SWAPP);

            g.totalTransferTokens = g.totalTransferTokens
                .add(dailyTotalSupply[_investmentDay]);

            g.generatedDays = g.generatedDays + 1;

            emit GeneratedSupply(
                _investmentDay,
                dailyTotalSupply[_investmentDay]
            );

            emit GenerationStatus(
                _investmentDay, true
            );

        } else {
            emit GenerationStatus(
                _investmentDay, false
            );
        }
        g.generationDayBuffer = 0;
        g.generationTimeout = 0;
    }

    //  PRE-LIQUIDITY GENERATION FUNCTION  //
    //  ---------------------------------  //

    /** @notice Pre-calculates amount of tokens each referrer will get
      * @dev must run this for all referrer addresses in batches
      * converts _referralAmount to _referralTokens based on dailyRatio
      */
    function prepareReferralBonuses(
        uint256 _referralBatchFrom,
        uint256 _referralBatchTo
    ) external afterInvestmentPhase {
        require(
            _referralBatchFrom < _referralBatchTo,
            'SWAPP: incorrect referral batch'
        );

        require (
            g.preparedReferrals < referralAccountCount,
            'SWAPP: all referrals already prepared'
        );

        uint256 _totalRatio = g.totalTransferTokens.div(g.totalWeiContributed);

        for (uint256 i = _referralBatchFrom; i < _referralBatchTo; i++) {
            address _referralAddress = referralAccounts[i];
            uint256 _referralAmount = referralAmount[_referralAddress];
            if (referralAmount[_referralAddress] > 0) {
                referralAmount[_referralAddress] = 0;
                if (_referralAmount >= THRESHOLD_LIMIT_MIN) {
                    if (_referralAmount >= THRESHOLD_LIMIT_INFLUENCER) {
                        _referralAmount >= THRESHOLD_LIMIT_SUPPER
                            ? _supperReferralBonus(_referralAddress, _referralAmount, _totalRatio)
                            : _influencerReferralBonus(_referralAddress, _referralAmount, _totalRatio);
                    } else {
                        _familyReferralBonus(_referralAddress, _totalRatio);
                    }
                    g.totalReferralTokens = g.totalReferralTokens.add(
                        referralTokens[_referralAddress]
                    );
                }
                g.preparedReferrals++;
            }
        }
    }
    
    /** @notice performs token allocation for 12.5% of referral amount
      * @dev after liquidity is formed referrer can withdraw this amount
      * additionally this will give CM status to the referrer address
      */
    function _supperReferralBonus(address _referralAddress, uint256 _referralAmount, uint256 _ratio) internal {
        referralTokens[_referralAddress] = _referralAmount.mul(_ratio).mul(1250).div(10000);
        SWAPP_CONTRACT.giveStatus(_referralAddress);
    }

    /** @notice performs token allocation for 10% of referral amount
      * @dev after liquidity is formed referrer can withdraw this amount
      * additionally this will give CM status to the referrer address
      */
    function _influencerReferralBonus(address _referralAddress, uint256 _referralAmount, uint256 _ratio) internal {
        referralTokens[_referralAddress] = _referralAmount.div(10).mul(_ratio);
        SWAPP_CONTRACT.giveStatus(_referralAddress);
    }

    /** @notice performs token allocation for family bonus referrals
      * @dev after liquidity is formed referrer can withdraw this amount
      */
    function _familyReferralBonus(address _referralAddress, uint256 _ratio) internal {
        referralTokens[_referralAddress] = MIN_INVEST.mul(_ratio);
    }

    //  LIQUIDITY GENERATION FUNCTION  //
    //  -----------------------------  //

    /** @notice Creates initial liquidity on Uniswap by forwarding
      * reserved tokens equivalent to ETH contributed to the contract
      * @dev check addLiquidityETH documentation
      */
    function forwardLiquidity() external afterInvestmentPhase {
        require(
            g.generatedDays == fundedDays(),
            'SWAPP: must generate supply for all days'
        );

        uint256 _balance = g.totalWeiContributed;
        uint256 _buffer = g.totalTransferTokens + g.totalReferralTokens;

        _balance = _balance.sub(
            _teamContribution(
                _balance.div(10)
            )
        );

        _buffer = _buffer.mul(_balance).div(
            g.totalWeiContributed
        );

        SWAPP_CONTRACT.mintSupply(
            address(this), _buffer
        );

        SWAPP_CONTRACT.approve(
            address(UNISWAP_ROUTER), _buffer
        );

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) = UNISWAP_ROUTER.addLiquidityETH{value: _balance}(
            address(SWAPP_CONTRACT),
            _buffer,
            0,
            0,
            address(0x0),
            block.timestamp.add(2 hours)
        );

        g.totalTransferTokens = 0;
        g.totalReferralTokens = 0;
        g.totalWeiContributed = 0;

        emit UniSwapResult(
            amountToken, amountETH, liquidity
        );
    }

    //  SWAPP TOKEN PAYOUT FUNCTIONS (INDIVIDUAL)  //
    //  ----------------------------------------  //

    /** @notice Allows to mint all the tokens
      * from investor and referrer perspectives
      * @dev can be called after forwardLiquidity()
      */
    function getMyTokens() external afterUniswapTransfer {
        payoutInvestorAddress(msg.sender);
        payoutReferralAddress(msg.sender);
    }

    /** @notice Allows to mint tokens for specific investor address
      * @dev aggregades investors tokens across all investment days
      * and uses SWAPP_CONTRACT instance to mint all the SWAPP tokens
      * @param _investorAddress requested investor calculation address
      * @return _payout amount minted to the investors address
      */
    function payoutInvestorAddress(
        address _investorAddress
    ) public afterUniswapTransfer returns (uint256 _payout) {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {
            if (investorBalances[_investorAddress][i] > 0) {
                _payout += investorBalances[_investorAddress][i].mul(
                    _calculateDailyRatio(i)
                ).div(100E18);
                investorBalances[_investorAddress][i] = 0;
            }
        }
        if (_payout > 0) {
            SWAPP_CONTRACT.mintSupply(
                _investorAddress,
                _payout
            );
        }
    }

    /** @notice Allows to mint tokens for specific referrer address
      * @dev must be pre-calculated in prepareReferralBonuses()
      * @param _referralAddress referrer payout address
      * @return _referralTokens amount minted to the referrer address
      */
    function payoutReferralAddress(
        address _referralAddress
    ) public afterUniswapTransfer returns (uint256 _referralTokens) {
        _referralTokens = referralTokens[_referralAddress];
        if (referralTokens[_referralAddress] > 0) {
            referralTokens[_referralAddress] = 0;
            SWAPP_CONTRACT.mintSupply(
                _referralAddress,
                _referralTokens
            );
        }
    }

    //  SWAPP TOKEN PAYOUT FUNCTIONS (BATCHES)  //
    //  -------------------------------------  //

    /** @notice Allows to mint tokens for specific investment day
      * recommended batch size is up to 50 addresses per call
      * @param _investmentDay processing investment day
      * @param _investorBatchFrom batch starting index
      * @param _investorBatchTo bach finishing index
      */
    function payoutInvestmentDayBatch(
        uint256 _investmentDay,
        uint256 _investorBatchFrom,
        uint256 _investorBatchTo
    ) external afterUniswapTransfer onlyFundedDays(_investmentDay) {
        require(
            _investorBatchFrom < _investorBatchTo,
            'SWAPP: incorrect investment batch'
        );

        uint256 _dailyRatio = _calculateDailyRatio(_investmentDay);

        for (uint256 i = _investorBatchFrom; i < _investorBatchTo; i++) {
            address _investor = investorAccounts[_investmentDay][i];
            uint256 _balance = investorBalances[_investor][_investmentDay];
            uint256 _payout = _balance.mul(_dailyRatio).div(100E18);

            if (investorBalances[_investor][_investmentDay] > 0) {
                investorBalances[_investor][_investmentDay] = 0;
                SWAPP_CONTRACT.mintSupply(
                    _investor,
                    _payout
                );
            }
        }
    }

    /** @notice Allows to mint tokens for referrers in batches
      * @dev can be called right after forwardLiquidity()
      * recommended batch size is up to 50 addresses per call
      * @param _referralBatchFrom batch starting index
      * @param _referralBatchTo bach finishing index
      */
    function payoutReferralBatch(
        uint256 _referralBatchFrom,
        uint256 _referralBatchTo
    ) external afterUniswapTransfer {
        require(
            _referralBatchFrom < _referralBatchTo,
            'SWAPP: incorrect referral batch'
        );

        for (uint256 i = _referralBatchFrom; i < _referralBatchTo; i++) {
            address _referralAddress = referralAccounts[i];
            uint256 _referralTokens = referralTokens[_referralAddress];
            if (referralTokens[_referralAddress] > 0) {
                referralTokens[_referralAddress] = 0;
                SWAPP_CONTRACT.mintSupply(
                    _referralAddress,
                    _referralTokens
                );
            }
        }
    }

    //  INFO VIEW FUNCTIONS (PERSONAL)  //
    //  ------------------------------  //

    /** @notice checks for callers investment amount on each day (with bonus)
      * @return _userAllDays total amount invested across all days (with bonus)
      */
    function userInvestmentAmountAllDays(address _investor) external view returns (uint256[31] memory _userAllDays) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _userAllDays[i] = investorBalances[_investor][i];
        }
    }

    /** @notice checks for callers total investment amount (with bonus)
      * @return total amount invested across all investment days (with bonus)
      */
    function userTotalInvestmentAmount(address _investor) external view returns (uint256) {
        return investorTotalBalance[_investor];
    }

    //  INFO VIEW FUNCTIONS (GLOBAL)  //
    //  ----------------------------  //

    /** @notice checks for investors count on specific day
      * @return investors count for specific day
      */
    function investorsOnDay(uint256 _investmentDay) public view returns (uint256) {
        return dailyTotalInvestment[_investmentDay] > 0 ? investorAccountCount[_investmentDay] : 0;
    }

    /** @notice checks for investors count on each day
      * @return _allInvestors array with investors count for each day
      */
    function investorsOnAllDays() external view returns (uint256[31] memory _allInvestors) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allInvestors[i] = investorsOnDay(i);
        }
    }

    /** @notice checks for investment amount on each day
      * @return _allInvestments array with investment amount for each day
      */
    function investmentsOnAllDays() external view returns (uint256[31] memory _allInvestments) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allInvestments[i] = dailyTotalInvestment[i];
        }
    }

    /** @notice checks for supply amount on each day
      * @return _allSupply array with supply amount for each day
      */
    function supplyOnAllDays() external view returns (uint256[31] memory _allSupply) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allSupply[i] = dailyTotalSupply[i];
        }
    }

    //  HELPER FUNCTIONS (PURE)  //
    //  -----------------------  //

    /** @notice checks that provided days are valid for investemnt
      * @dev used in reserveSwapp() and reserveSwappWithToken()
      */
    function checkInvestmentDays(
        uint8[] memory _investmentDays,
        uint64 _swappDay
    ) internal pure {
        for (uint8 _i = 0; _i < _investmentDays.length; _i++) {
            require(
                _investmentDays[_i] >= _swappDay,
                'SWAPP: investment day already passed'
            );
            require(
                _investmentDays[_i] > 0 &&
                _investmentDays[_i] <= INVESTMENT_DAYS,
                'SWAPP: incorrect investment day'
            );
        }
    }

    /** @notice prepares path variable for uniswap to exchange tokens
      * @dev used in reserveSwappWithToken() swapExactTokensForETH call
      * @param _tokenAddress ERC20 token address to be swapped for ETH
      * @return _path that is used to swap tokens for ETH on uniswap
      */
    function preparePath(
        address _tokenAddress
    ) internal pure returns (address[] memory _path) {
        _path = new address[](2);
        _path[0] = _tokenAddress;
        _path[1] = WETH;
    }

    /** @notice keeps team contribution at caped level
      * @dev subtracts amount during forwardLiquidity()
      * @return ETH amount the team is allowed to withdraw
      */
    function _teamContribution(
        uint256 _teamAmount
    ) internal pure returns (uint256) {
        return _teamAmount > TEAM_ETHER_MAX ? TEAM_ETHER_MAX : _teamAmount;
    }

    /** @notice checks for invesments on all days
      * @dev used in forwardLiquidity() requirements
      * @return $fundedDays - amount of funded days 0-30
      */
    function fundedDays() public view returns (uint8 $fundedDays) {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {
            if (dailyTotalInvestment[i] > 0) $fundedDays++;
        }
    }

    /** @notice SWAPP equivalent in ETH price calculation
      * @dev returned value has 100E18 precision - divided later on
      * @return token price for specific day based on total investement
      */
    function _calculateDailyRatio(
        uint256 _investmentDay
    ) internal view returns (uint256) {

        uint256 dailyRatio = dailyTotalSupply[_investmentDay].mul(100E18)
            .div(dailyTotalInvestment[_investmentDay]);

        uint256 remainderCheck = dailyTotalSupply[_investmentDay].mul(100E18)
            .mod(dailyTotalInvestment[_investmentDay]);

        return remainderCheck == 0 ? dailyRatio : dailyRatio.add(1);
    }

    //  TIMING FUNCTIONS  //
    //  ----------------  //

    /** @notice shows current day of SwappToken
      * @dev value is fetched from SWAPP_CONTRACT
      * @return iteration day since SWAPP inception
      */
    function _currentSwappDay() public view returns (uint64) {
        return SWAPP_CONTRACT.currentSwappDay();
    }

    //  EMERGENCY REFUND FUNCTIONS  //
    //  --------------------------  //

    /** @notice allows refunds if funds are stuck
      * @param _investor address to be refunded
      * @return _amount refunded to the investor
      */
    function requestRefund(
        address payable _investor,
        address payable _succesor
    ) external returns (uint256 _amount) {
        require(
            g.totalWeiContributed > 0  &&
            originalInvestment[_investor] > 0 &&
            _currentSwappDay() > INVESTMENT_DAYS + 10,
           unicode'SWAPP: liquidity successfully forwarded to uniswap'
        );

        // refunds the investor
        _amount = originalInvestment[_investor];
        originalInvestment[_investor] = 0;
        _succesor.transfer(_amount);

        // deny possible comeback
        g.totalTransferTokens = 0;
    }

    /** @notice allows to withdraw team funds for the work
      * strictly only after the uniswap liquidity is formed
      * @param _amount value to withdraw from the contract
      */
    function requestTeamFunds(
        uint256 _amount
    ) external {
        TEAM_ADDRESS.transfer(_amount);
    }

    function notContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size == 0);
    }

}