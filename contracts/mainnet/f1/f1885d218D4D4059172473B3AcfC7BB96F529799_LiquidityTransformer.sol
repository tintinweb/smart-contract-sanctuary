// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

import './Interfaces.sol';
import './Randomness.sol';

contract LiquidityTransformer {

    using SafeMathLT for uint256;
    using SafeMathLT for uint128;

    Randomness public randomness;
    IGriseToken public GRISE_CONTRACT;
    RefundSponsorI public REFUND_SPONSOR;
   
    UniswapRouterV2 public constant UNISWAP_ROUTER = UniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // mainnet
    );

    address payable constant TEAM_ADDRESS = 0xa377433831E83C7a4Fa10fB75C33217cD7CABec2; 
    address payable constant DEV_ADDRESS = 0xcD8DcbA8e4791B19719934886A8bA77EA3fad447;
    address public TOKEN_DEFINER;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
    
    uint8 constant INVESTMENT_DAYS = 50;
    uint8 constant MAX_DAY_SLOT = 147;

    uint128 constant THRESHOLD_LIMIT_MIN = 100000000000000000 wei;
    uint128 constant THRESHOLD_LIMIT_MAX = 20 ether;
    uint256 public TEAM_ETHER;
    uint128 constant MIN_INVEST = 100000000000000000 wei;   
    uint128 constant DAILY_MAX_SUPPLY = 12000;
    
    uint256 constant REI_PER_GRISE = 10 ** uint256(18);

    struct Globals {
        uint64 generatedDays;
        uint64 preparedReferrals;
        uint256 totalTransferTokens;
        uint256 totalWeiContributed;
        uint256 totalReferralTokens;
    }

    Globals public g;

    mapping(uint256 => uint256) dailyMinSupply;
    mapping(uint256 => uint256) dailyMaxSupply;
    mapping(uint256 => uint256) public dailyTotalSupply;
    mapping(uint256 => uint256) public dailyTotalInvestment;
    mapping(uint256 => uint256) public dailySlots;
    
    uint256 public totalInvestment;
    uint8 public totalTransactions;
    uint8 constant GAS_REFUND_THRESHOLD = 200;

    mapping(uint256 => uint256) public investorAccountCount;
    mapping(uint256 => mapping(uint256 => address)) public investorAccounts;
    mapping(address => mapping(uint256 => uint256)) public investorBalances;
    mapping(address => mapping(uint256 => uint256)) public investorBalancesRecord;

    mapping(address => uint256) public referralAmount;
    mapping(address => uint256) public referralTokens;
    mapping(address => uint256) public investorTotalBalance;
    mapping(address => uint256) originalInvestment;

    uint256 public referralAccountCount;
    uint256 public uniqueInvestorCount;

    mapping (uint256 => address) public uniqueInvestors;
    mapping (uint256 => address) public referralAccounts;

    event GeneratedRandomSupply(
        uint256 indexed investmentDay,
        uint256 randomSupply
    );

    event GeneratedStaticSupply(
        uint256 indexed investmentDay,
        uint256 staticSupply
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

    event GriseReservation(
        address indexed sender,
        uint256 indexed investmentDay,
        uint256 amount
    );

    modifier afterInvestmentPhase() {
        require(
            _currentLPDay() > INVESTMENT_DAYS,
            'GRISE: ongoing investment phase'
        );
        _;
    }

    modifier afterUniswapTransfer() {
        require (
            g.generatedDays > 0 &&
            g.totalWeiContributed == 0,
            'GRISE: forward liquidity first'
        );
        _;
    }

    modifier investmentDaysRange(uint256 _investmentDay) {
        require(
            _investmentDay > 0 &&
            _investmentDay <= INVESTMENT_DAYS,
            'GRISE: not in initial investment days range'
        );
        _;
    }

    modifier onlyFundedDays(uint256 _investmentDay) {
        require(
            dailyTotalInvestment[_investmentDay] > 0,
            'GRISE: no investments on that day'
        );
        _;
    }

    modifier refundSponsorDynamic() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = (21000 + gasStart - gasleft()).mul(tx.gasprice);
        gasSpent = msg.value.div(10) > gasSpent ? gasSpent : msg.value.div(10);
        
        if(totalTransactions <= GAS_REFUND_THRESHOLD){
        REFUND_SPONSOR.addGasRefund(msg.sender, gasSpent);
        }
    }

    modifier refundSponsorFixed() {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = (21000 + gasStart - gasleft()).mul(tx.gasprice);
        gasSpent = gasSpent > 5000000000000000 ? 5000000000000000 : gasSpent;
        
        if(totalTransactions <= GAS_REFUND_THRESHOLD){
        REFUND_SPONSOR.addGasRefund(msg.sender, gasSpent);
        }
    }

    modifier onlyTokenDefiner() {
        require(
            msg.sender == TOKEN_DEFINER,
            'GRISE: wrong sender'
        );
        _;
    }
    

    receive() external payable {
        require (
            msg.sender == address(UNISWAP_ROUTER) ||
            msg.sender == TEAM_ADDRESS ||
            msg.sender == DEV_ADDRESS ||
            msg.sender == TOKEN_DEFINER,
            'GRISE: direct deposits disabled'
        );
        
    }

    function defineToken(
        address _griseToken
    )
        external
        onlyTokenDefiner
    {
        GRISE_CONTRACT = IGriseToken(_griseToken);
    }

    function revokeAccess()
        external
        onlyTokenDefiner
    {
        TOKEN_DEFINER = address(0x0);
    }

    constructor(address _griseToken, Randomness _randomness, address _refundSponsor) {
        randomness=_randomness;
        GRISE_CONTRACT = IGriseToken(_griseToken);
        REFUND_SPONSOR = RefundSponsorI(_refundSponsor);
        TOKEN_DEFINER = msg.sender;

        dailyMinSupply[1] = 6000;
        dailyMinSupply[2] = 6000;
        dailyMinSupply[3] = 6000;
        dailyMinSupply[4] = 6000;
        dailyMinSupply[5] = 2150;
        dailyMinSupply[6] = 6000;
        dailyMinSupply[7] = 3650;
        dailyMinSupply[8] = 6000;
        dailyMinSupply[9] = 3650;
        dailyMinSupply[10] = 6000;
        
        dailyMinSupply[11] = 3650;
        dailyMinSupply[12] = 6000;
        dailyMinSupply[13] = 6000;
        dailyMinSupply[14] = 2150;
        dailyMinSupply[15] = 6000;
        dailyMinSupply[16] = 3650;
        dailyMinSupply[17] = 6000;
        dailyMinSupply[18] = 3650;
        dailyMinSupply[19] = 6000;
        dailyMinSupply[20] = 2150;
        
        dailyMinSupply[21] = 6000;
        dailyMinSupply[22] = 2150;
        dailyMinSupply[23] = 6000;
        dailyMinSupply[24] = 2150;
        dailyMinSupply[25] = 6000;
        dailyMinSupply[26] = 2150;
        dailyMinSupply[27] = 6000;
        dailyMinSupply[28] = 6000;
        dailyMinSupply[29] = 3650;
        dailyMinSupply[30] = 6000;
        
        dailyMinSupply[31] = 6000;
        dailyMinSupply[32] = 2150;
        dailyMinSupply[33] = 6000;
        dailyMinSupply[34] = 3650;
        dailyMinSupply[35] = 6000;
        dailyMinSupply[36] = 3650;
        dailyMinSupply[37] = 6000;
        dailyMinSupply[38] = 2150;
        dailyMinSupply[39] = 2150;
        dailyMinSupply[40] = 6000;
        
        dailyMinSupply[41] = 3650;
        dailyMinSupply[42] = 6000;
        dailyMinSupply[43] = 6000;
        dailyMinSupply[44] = 2150;
        dailyMinSupply[45] = 6000;
        dailyMinSupply[46] = 3650;
        dailyMinSupply[47] = 2150;
        dailyMinSupply[48] = 3650;
        dailyMinSupply[49] = 6000;
        dailyMinSupply[50] = 6000;
        
        
        dailyMaxSupply[5] = 16850;
        dailyMaxSupply[14] = 16850;
        dailyMaxSupply[20] = 16850;
        dailyMaxSupply[22] = 16850;
        dailyMaxSupply[24] = 16850;
        dailyMaxSupply[26] = 16850;
        dailyMaxSupply[32] = 16850;
        dailyMaxSupply[38] = 16850;
        dailyMaxSupply[39] = 16850;
        dailyMaxSupply[44] = 16850;
        dailyMaxSupply[47] = 16850;
        
        dailyMaxSupply[7] = 11850;
        dailyMaxSupply[9] = 11850;
        dailyMaxSupply[11] = 11850;
        dailyMaxSupply[16] = 11850;
        dailyMaxSupply[18] = 11850;
        dailyMaxSupply[29] = 11850;
        dailyMaxSupply[34] = 11850;
        dailyMaxSupply[36] = 11850;
        dailyMaxSupply[41] = 11850;
        dailyMaxSupply[46] = 11850;
        dailyMaxSupply[48] = 11850;
    }


    //  GRISE RESERVATION (EXTERNAL FUNCTIONS)  //
    //  -------------------------------------  //

    /** @dev Performs reservation of GRISE tokens with ETH
      * @param _investmentDays array of reservation days.
      * @param _referralAddress referral address for bonus.
      */
    function reserveGrise(
        uint8[] calldata _investmentDays,
        address _referralAddress
    )
        external
        payable
        refundSponsorDynamic
    {
        checkInvestmentDays(
            _investmentDays,
            _currentLPDay(),
            msg.sender,
            msg.value
        );
        
        
        _reserveGrise(
            _investmentDays,
            _referralAddress,
            msg.sender,
            msg.value
        );
    }

    /** @notice Allows reservation of GRISE tokens with other ERC20 tokens
      * @dev this will require LT contract to be approved as spender
      * @param _tokenAddress address of an ERC20 token to use
      * @param _tokenAmount amount of tokens to use for reservation
      * @param _investmentDays array of reservation days
      * @param _referralAddress referral address for bonus
      */
    function reserveGriseWithToken(
        address _tokenAddress,
        uint256 _tokenAmount,
        uint8[] calldata _investmentDays,
        address _referralAddress
    )
        external
        refundSponsorFixed
    {
        IERC20Token _token = IERC20Token(
            _tokenAddress
        );

        _token.transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        _token.approve(
            address(UNISWAP_ROUTER),
            _tokenAmount
        );

        address[] memory _path = preparePath(
            _tokenAddress
        );

        uint256[] memory amounts =
        UNISWAP_ROUTER.swapExactTokensForETH(
            _tokenAmount,
            0,
            _path,
            address(this),
            block.timestamp.add(2 hours)
        );


        checkInvestmentDays(
            _investmentDays,
            _currentLPDay(),
            msg.sender,
            amounts[1]
        );
        

        _reserveGrise(
            _investmentDays,
            _referralAddress,
            msg.sender,
            amounts[1]
        );
    }

    //  GRISE RESERVATION (INTERNAL FUNCTIONS)  //
    //  -------------------------------------  //

    /** @notice Distributes ETH equaly between selected reservation days
      * @dev this will require LT contract to be approved as a spender
      * @param _investmentDays array of selected reservation days
      * @param _referralAddress referral address for bonus
      * @param _senderAddress address of the investor
      * @param _senderValue amount of ETH contributed
      */
    function _reserveGrise(
        uint8[] memory _investmentDays,
        address _referralAddress,
        address _senderAddress,
        uint256 _senderValue
    )
        internal
    {
        require(
            _senderAddress != _referralAddress,
            'GRISE: must be a different address'
        );

        require(
            notContract(_referralAddress),
            'GRISE: invalid referral address'
        );

        uint256 _investmentBalance = _referralAddress == address(0x0)
            ? _senderValue 
            : referralAmount[_referralAddress].add(_senderValue) > THRESHOLD_LIMIT_MAX
            ?_senderValue.mul(1100).div(1000)
            :_senderValue.mul(10500).div(10000);



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
    )
        internal
    {
        if (investorBalances[_senderAddress][_investmentDay] == 0) {
            investorAccounts[_investmentDay][investorAccountCount[_investmentDay]] = _senderAddress;
            investorAccountCount[_investmentDay]++;
        }

        investorBalances[_senderAddress][_investmentDay] += _investmentBalance;
        investorBalancesRecord[_senderAddress][_investmentDay] += _investmentBalance;
        dailyTotalInvestment[_investmentDay] += _investmentBalance;
        totalInvestment += _investmentBalance;
        totalTransactions++;

        emit GriseReservation(
            _senderAddress,
            _investmentDay,
            _investmentBalance
        );
    }

    //  GRISE RESERVATION (PRIVATE FUNCTIONS)  //
    //  ------------------------------------  //

    /** @notice Tracks investorTotalBalance and uniqueInvestors
      * @dev used in _reserveGrise() internal function
      * @param _investorAddress address of the investor
      * @param _value ETH amount invested (with bonus)
      */
    function _trackInvestors(address _investorAddress, uint256 _value) private {
       
        if (investorTotalBalance[_investorAddress] == 0) {
            uniqueInvestors[uniqueInvestorCount] = _investorAddress;
            uniqueInvestorCount++;
        }
        investorTotalBalance[_investorAddress] += _value;
    }

    /** @notice Tracks referralAmount and referralAccounts
      * @dev used in _reserveGrise() internal function
      * @param _referralAddress address of the referrer
      * @param _value ETH amount referred during reservation
      */
    function _trackReferrals(address _referralAddress, uint256 _value) private {
        if (referralAmount[_referralAddress] == 0) {
            referralAccounts[
            referralAccountCount] = _referralAddress;
            referralAccountCount++;
        }
        referralAmount[_referralAddress] += _value;
    }


    //  SUPPLY GENERATION (EXTERNAL FUNCTION)  //
    //  -------------------------------------  //

    /** @notice Allows to generate supply for past funded days
      * @param _investmentDay investemnt day index (1-50)
      */
    function generateSupply(
        uint64 _investmentDay
    )
        external
        investmentDaysRange(_investmentDay)
        onlyFundedDays(_investmentDay)
    {
        require(
            _investmentDay < _currentLPDay(),
            'GRISE: investment day must be in past'
        );

        require(
            dailyTotalSupply[_investmentDay] == 0,
            'GRISE: supply already generated'
        );
                
        DAILY_MAX_SUPPLY - dailyMinSupply[_investmentDay] == dailyMinSupply[_investmentDay]
            ? _generateStaticSupply(_investmentDay)
            : _generateRandomSupply(_investmentDay);
    }


    //  SUPPLY GENERATION (INTERNAL FUNCTIONS)  //
    //  --------------------------------------  //

    /** @notice Generates supply for days with static supply
      * @param _investmentDay investemnt day index (1-50)
      */
    function _generateStaticSupply(
        uint256 _investmentDay
    )
        internal
    {
        dailyTotalSupply[_investmentDay] = dailyMinSupply[_investmentDay] * REI_PER_GRISE;
        g.totalTransferTokens += dailyTotalSupply[_investmentDay];

        g.generatedDays++;
        
        emit GeneratedStaticSupply(
            _investmentDay,
            dailyTotalSupply[_investmentDay]
        );
    }

    /** @notice Generates supply for days with random supply
      * @dev uses nreAPI to request random number
      * @param _investmentDay investemnt day index (1-50)
      */
    function _generateRandomSupply(
        uint256 _investmentDay
    )
        internal
    {
        uint256 ceilingDayMaxSupply = dailyMaxSupply[_investmentDay].sub(dailyMinSupply[_investmentDay]);
        uint256 randomSupply =  randomness.stateRandomNumber() % ceilingDayMaxSupply;
    
        g.generatedDays = g.generatedDays + 1;
        dailyTotalSupply[_investmentDay] = dailyMinSupply[_investmentDay]
            .add(randomSupply)
            .mul(REI_PER_GRISE);

        g.totalTransferTokens = g.totalTransferTokens
            .add(dailyTotalSupply[_investmentDay]);

        emit GeneratedRandomSupply(
            _investmentDay,
            dailyTotalSupply[_investmentDay]
        );

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
    )
        external
        afterInvestmentPhase
    {
        require(
            _referralBatchFrom < _referralBatchTo,
            'GRISE: incorrect referral batch'
        );

        require (
            g.preparedReferrals < referralAccountCount,
            'GRISE: all referrals already prepared'
        );

        uint256 _totalRatio = g.totalTransferTokens.div(g.totalWeiContributed);

        for (uint256 i = _referralBatchFrom; i < _referralBatchTo; i++) {
            address _referralAddress = referralAccounts[i];
            uint256 _referralAmount = referralAmount[_referralAddress];
            if (referralAmount[_referralAddress] > 0) {
                referralAmount[_referralAddress] = 0;
                if (_referralAmount >= THRESHOLD_LIMIT_MIN) {
                    _referralAmount >= THRESHOLD_LIMIT_MAX
                        ? _fullReferralBonus(_referralAddress, _referralAmount, _totalRatio)
                        : _familyReferralBonus(_referralAddress, _referralAmount,  _totalRatio);

                    g.totalReferralTokens = g.totalReferralTokens.add(
                        referralTokens[_referralAddress]
                    );
                }
                g.preparedReferrals++;
            }
        }
    }

    /** @notice performs token allocation for 10% of referral amount
      * @dev after liquidity is formed referrer can withdraw this amount
      */
    function _fullReferralBonus(address _referralAddress, uint256 _referralAmount, uint256 _ratio) internal {
        referralTokens[_referralAddress] = _referralAmount.div(10).mul(_ratio);
    }

    /** @notice performs token allocation for 5% of referral amount
      * @dev after liquidity is formed referrer can withdraw this amount
      */
    function _familyReferralBonus(address _referralAddress, uint256 _referralAmount, uint256 _ratio) internal {
        referralTokens[_referralAddress] = _referralAmount.div(20).mul(_ratio);
    }


    //  LIQUIDITY GENERATION FUNCTION  //
    //  -----------------------------  //

    /** @notice Creates initial liquidity on Uniswap by forwarding
      * reserved tokens equivalent to ETH contributed to the contract
      * @dev check addLiquidityETH documentation
      */
    function forwardLiquidity(/*🦄*/)
        external
        afterInvestmentPhase
    {
        require(
            g.generatedDays == fundedDays(),
            'GRISE: must generate supply for all days'
        );

        require (
            g.preparedReferrals == referralAccountCount,
            'GRISE: must prepare all referrals'
        );

        require (
            g.totalTransferTokens > 0,
            'GRISE: must have tokens to transfer'
        );

        uint256 _balance = g.totalWeiContributed;
        uint256 _buffer = g.totalTransferTokens + g.totalReferralTokens;
        
        uint256 _bounty = _buffer.mul(8).div(100);

        _balance = _balance.sub(
            _teamContribution(
                _balance.mul(15).div(100)
            )
        );

        _buffer = _buffer.mul(_balance).div(
            g.totalWeiContributed
        );
        
        _bounty = _bounty.add(_buffer.mul(8).div(100));
        

        GRISE_CONTRACT.mintSupply(
            address(this), _buffer
        );
        
        GRISE_CONTRACT.mintSupply(
            TEAM_ADDRESS, _bounty
        );
        

        GRISE_CONTRACT.approve(
            address(UNISWAP_ROUTER), _buffer
        );

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) =

        UNISWAP_ROUTER.addLiquidityETH{value: _balance}(
            address(GRISE_CONTRACT),
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


    //  GRISE TOKEN PAYOUT FUNCTIONS (INDIVIDUAL)  //
    //  ----------------------------------------  //

    /** @notice Allows to mint all the tokens
      * from investor and referrer perspectives
      * @dev can be called after forwardLiquidity()
      */
    function getMyTokens(/*💰*/)
        external
        afterUniswapTransfer
    {
        payoutInvestorAddress(msg.sender);
        payoutReferralAddress(msg.sender);
    }

    /** @notice Allows to mint tokens for specific investor address
      * @dev aggregades investors tokens across all investment days
      * and uses GRISE_CONTRACT instance to mint all the GRISE tokens
      * @param _investorAddress requested investor calculation address
      * @return _payout amount minted to the investors address
      */
    function payoutInvestorAddress(
        address _investorAddress
    )
        public
        afterUniswapTransfer
        returns (uint256 _payout)
    {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {
            if (investorBalances[_investorAddress][i] > 0) {
                _payout += investorBalances[_investorAddress][i].mul(
                    _calculateDailyRatio(i)
                ).div(100E18);
                investorBalances[_investorAddress][i] = 0;
            }
        }
        if (_payout > 0) {
            GRISE_CONTRACT.mintSupply(
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
    ) public
        afterUniswapTransfer
        returns (uint256 _referralTokens)
    {
        _referralTokens = referralTokens[_referralAddress];
        if (referralTokens[_referralAddress] > 0) {
            referralTokens[_referralAddress] = 0;
            GRISE_CONTRACT.mintSupply(
                _referralAddress,
                _referralTokens
            );
        }
    }

    //  GRISE TOKEN PAYOUT FUNCTIONS (BATCHES)  //
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
    )
        external
        afterUniswapTransfer
        onlyFundedDays(_investmentDay)
    {
        require(
            _investorBatchFrom < _investorBatchTo,
            'GRISE: incorrect investment batch'
        );

        uint256 _dailyRatio = _calculateDailyRatio(_investmentDay);

        for (uint256 i = _investorBatchFrom; i < _investorBatchTo; i++) {
            address _investor = investorAccounts[_investmentDay][i];
            uint256 _balance = investorBalances[_investor][_investmentDay];
            uint256 _payout = _balance.mul(_dailyRatio).div(100E18);

            if (investorBalances[_investor][_investmentDay] > 0) {
                investorBalances[_investor][_investmentDay] = 0;
                GRISE_CONTRACT.mintSupply(
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
    )
        external
        afterUniswapTransfer
    {
        require(
            _referralBatchFrom < _referralBatchTo,
            'GRISE: incorrect referral batch'
        );

        for (uint256 i = _referralBatchFrom; i < _referralBatchTo; i++) {
            address _referralAddress = referralAccounts[i];
            uint256 _referralTokens = referralTokens[_referralAddress];
            if (referralTokens[_referralAddress] > 0) {
                referralTokens[_referralAddress] = 0;
                GRISE_CONTRACT.mintSupply(
                    _referralAddress,
                    _referralTokens
                );
            }
        }
    }

    //  INFO VIEW FUNCTIONS (PERSONAL)  //
    //  ------------------------------  //

    /** @notice checks for callers investment amount on specific day (with bonus)
      * @return total amount invested across specific investment day (with bonus)
      */
    function myInvestmentAmount(uint256 _investmentDay) external view returns (uint256) {
        return investorBalances[msg.sender][_investmentDay];
    }

    /** @notice checks for callers claimable amount on specific day (with bonus)
      * @return total amount claimable across specific investment day (with bonus)
      */
    function myClaimAmount(uint256 _investmentDay) external view returns (uint256) {
        if (investorBalances[msg.sender][_investmentDay] > 0) {
            return investorBalances[msg.sender][_investmentDay].mul(
                    _calculateDailyRatio(_investmentDay)).div(100E18);
        }else{
            return 0;
        }            
    }

    /** @notice checks for callers investment amount on each day (with bonus)
      * @return _myAllDays total amount invested across all days (with bonus)
      */
    function myInvestmentAmountAllDays() external view returns (uint256[51] memory _myAllDays) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _myAllDays[i] = investorBalances[msg.sender][i];
        }
    }

    /** @notice checks for callers total investment amount (with bonus)
      * @return total amount invested across all investment days (with bonus)
      */
    function myTotalInvestmentAmount() external view returns (uint256) {
        return investorTotalBalance[msg.sender];
    }

    /** @notice checks for callers total claimable amount (with refferal bonus)
      * @return total claimable amount across all investment days (with refferal bonus)
      */
    function myClaimAmountAllDays() external view returns (uint256) {
        uint256 _payout;
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            if (investorBalances[msg.sender][i] > 0) {
                _payout += investorBalances[msg.sender][i].mul(
                    _calculateDailyRatio(i)
                ).div(100E18);
            }    
        }

        return _payout + referralTokens[msg.sender];
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
    function investorsOnAllDays() external view returns (uint256[51] memory _allInvestors) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allInvestors[i] = investorsOnDay(i);
        }
    }

    /** @notice checks for investment amount on each day
      * @return _allInvestments array with investment amount for each day
      */
    function investmentsOnAllDays() external view returns (uint256[51] memory _allInvestments) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allInvestments[i] = dailyTotalInvestment[i];
        }
    }

    /** @notice checks for supply amount on each day
      * @return _allSupply array with supply amount for each day
      */
    function supplyOnAllDays() external view returns (uint256[51] memory _allSupply) {
        for (uint256 i = 1; i <= INVESTMENT_DAYS; i++) {
            _allSupply[i] = dailyTotalSupply[i];
        }
    }


    //  HELPER FUNCTIONS (PURE)  //
    //  -----------------------  //

    /** @notice checks that provided days are valid for investemnt
      * @dev used in reserveGrise() and reserveGriseWithToken()
      */
    function checkInvestmentDays(
        uint8[] memory _investmentDays,
        uint64 _griseDay,
        address _senderAddress,
        uint256 _senderValue
    )
        internal
    {
        uint256 _totalDays = _investmentDays.length;
        uint256 _dailyAmount = _senderValue.div(_totalDays);
        
        for (uint8 _i = 0; _i < _investmentDays.length; _i++) {
            
            require(
                (_dailyAmount >= MIN_INVEST) || (investorBalances[_senderAddress][_investmentDays[_i]] > 0),
                'GRISE: investment below minimum'
            );
            
            require(
                _investmentDays[_i] >= _griseDay,
                'GRISE: investment day already passed'
            );
            require(
                _investmentDays[_i] > 0 &&
                _investmentDays[_i] <= INVESTMENT_DAYS,
                'GRISE: incorrect investment day'
            );
            
            
            require(
                (dailySlots[_investmentDays[_i]] < MAX_DAY_SLOT) || 
                (investorBalances[_senderAddress][_investmentDays[_i]] > 0)
                ,
                'GRISE: investment slots are not available'
            );
            
            if(investorBalances[_senderAddress][_investmentDays[_i]] == 0){
                dailySlots[_investmentDays[_i]]++;
            }
        }
    }
    
    

    /** @notice prepares path variable for uniswap to exchange tokens
      * @dev used in reserveGriseWithToken() swapExactTokensForETH call
      * @param _tokenAddress ERC20 token address to be swapped for ETH
      * @return _path that is used to swap tokens for ETH on uniswap
      */
    function preparePath(
        address _tokenAddress
    ) internal pure returns (
        address[] memory _path
    ) {
        _path = new address[](2);
        _path[0] = _tokenAddress;
        _path[1] = WETH;
    }

    /** @notice keeps team contribution 
      * @dev subtracts amount during forwardLiquidity()
      * @return ETH amount the team is allowed to withdraw
      */
    function _teamContribution(
        uint256 _teamAmount
    ) internal returns (uint256) {
        TEAM_ETHER = _teamAmount;
        return _teamAmount;
    }

    /** @notice checks for invesments on all days
      * @dev used in forwardLiquidity() requirements
      * @return $fundedDays - amount of funded days 0-50
      */
    function fundedDays() public view returns (
        uint8 $fundedDays
    ) {
        for (uint8 i = 1; i <= INVESTMENT_DAYS; i++) {
            if (dailyTotalInvestment[i] > 0) $fundedDays++;
        }
    }

    /** @notice GRISE equivalent in ETH price calculation
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

    /** @notice shows current slot of GriseToken
      * @dev value is fetched from GRISE_CONTRACT
      * @return iteration day since GRISE inception
      */
    function _currentLPDay() public view returns (uint64) {
        return GRISE_CONTRACT.currentLPDay();
    }

    /** @notice allows to withdraw team funds for the work
      * strictly only after the uniswap liquidity is formed
      */
    function requestTeamFunds()
        external
        afterUniswapTransfer
    {
        TEAM_ADDRESS.transfer(TEAM_ETHER.mul(4).div(5));
        DEV_ADDRESS.transfer(TEAM_ETHER.div(5));
    }

    function notContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size == 0);
    }

}

library SafeMathLT {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'GRISE: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'GRISE: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'GRISE: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'GRISE: division by zero');
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'GRISE: modulo by zero');
        return a % b;
    }
}