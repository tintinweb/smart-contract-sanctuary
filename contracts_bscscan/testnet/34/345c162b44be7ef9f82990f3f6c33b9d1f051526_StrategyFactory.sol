/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// File: contracts/interfaces/IPredictionMarket.sol
//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

interface IPredictionMarket {
    function conditions(uint256 _index)
        external
        view
        returns (
            string memory market,
            address oracle,
            int256 triggerPrice,
            uint256 settlementTime,
            bool isSettled,
            int256 settledPrice,
            address lowBetToken,
            address highBetToken,
            uint256 totalStakedAbove,
            uint256 totalStakedBelow
        );

    function prepareCondition(
        address _oracle,
        uint256 _settlementTime,
        int256 _triggerPrice,
        string memory _market
    ) external;

    function probabilityRatio(uint256 _conditionIndex)
        external
        view
        returns (uint256 aboveProbabilityRatio, uint256 belowProbabilityRatio);

    function userTotalETHStaked(uint256 _conditionIndex, address userAddress)
        external
        view
        returns (uint256 totalEthStaked);

    function betOnCondition(uint256 _conditionIndex, uint8 _prediction)
        external
        payable;

    function settleCondition(uint256 _conditionIndex) external;

    function claim(uint256 _conditionIndex) external;

    function calculateClaimAmount(uint256 _conditionIndex)
        external
        returns (
            uint8 winningSide,
            uint256 userstake,
            uint256 totalWinnerRedeemable,
            uint256 platformFees
        );

    function getPerUserClaimAmount(uint256 _conditionIndex)
        external
        returns (uint8, uint256);

    function getBalance(uint256 _conditionIndex, address _user)
        external
        view
        returns (uint256 LBTBalance, uint256 HBTBalance);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/StrategyStorage.sol

pragma solidity 0.8.0;

contract StrategyStorage {
    //strategy details
    StrategyStatus public status;
    IPredictionMarket public predictionMarket;

    uint256 internal constant PERCENTAGE_MULTIPLIER = 10000;
    uint256 internal constant MAX_BET_PERCENTAGE = 50000;

    string public strategyName;
    address payable public trader;
    address payable public operator;
    uint256 public initialTraderFunds;
    uint256 public traderClaimedAmount;

    uint256 public userPortfolio;
    uint256 public traderPortfolio;

    uint256 public depositPeriod;
    uint256 public tradingPeriod;

    //Fees Percentage
    //PERCENTAGE_MULTIPLIER decimals
    uint256 public feePercentage = 2000; //default 20%
    uint256 public traderFees;
    bool isFeeClaimed;

    enum StrategyStatus {
        ACTIVE,
        INACTIVE
    }

    uint256 public totalUserActiveMarkets;
    uint256 public totalTraderActiveMarkets;
    uint256 public totalUserFunds;
    struct User {
        uint256 depositAmount;
        uint256 claimedAmount;
        bool exited;
    }

    struct Market {
        uint256 userLowBets;
        uint256 userHighBets;
        uint256 traderLowBets;
        uint256 traderHighBets;
        bool isClaimed;
        uint256 amountClaimed;
    }

    //user details]
    uint256 public totalUsers;
    mapping(address => User) public userInfo;
    mapping(uint256 => Market) public markets;
    //conditionIndex -> 1 -> users
    //conditionIndex -> 0 -> trader
    mapping(uint256 => mapping(uint8 => bool)) public isBetPlaced;

    event StrategyFollowed(address follower, uint256 amount);
    event StrategyUnfollowed(
        address follower,
        uint256 amountClaimed,
        string unfollowType
    );
    event BetPlaced(uint256 conditionIndex, uint8 side, uint256 totalAmount);
    event BetClaimed(
        uint256 conditionIndex,
        uint8 winningSide,
        uint256 amountReceived
    );
    event StrategyInactive();
    event TraderClaimed(uint256 amountClaimed);
    event TraderFeeClaimed(uint256 traderFees);
}

// File: contracts/Strategy.sol

pragma solidity 0.8.0;

contract Strategy is StrategyStorage {
    modifier isStrategyActive() {
        require(
            status == StrategyStatus.ACTIVE,
            "Strategy::isStrategyActive: STRATEGY_INACTIVE"
        );
        _;
    }

    modifier onlyTrader() {
        require(msg.sender == trader, "Strategy::onlyTrader: INVALID_TRADER");
        _;
    }

    modifier onlyUser() {
        require(
            userInfo[msg.sender].depositAmount > 0,
            "Strategy::onlyTrader: INVALID_USER"
        );
        _;
    }

    modifier inDepositPeriod() {
        require(
            depositPeriod >= block.timestamp,
            "Strategy: DEPOSIT_PERIOD_ENDED"
        );
        _;
    }

    modifier inTradingPeriod() {
        require(
            tradingPeriod >= block.timestamp && depositPeriod < block.timestamp,
            "Strategy: TRADING_PERIOD_NOT_STARTED"
        );
        _;
    }

    modifier tradingPeriodEnded() {
        require(
            tradingPeriod < block.timestamp,
            "Strategy: TRADING_PERIOD_ACTIVE"
        );
        _;
    }

    constructor(
        address _predictionMarket,
        string memory _name,
        address payable _trader,
        uint256 _depositPeriod, //time remaining from now
        uint256 _tradingPeriod, //deposit time + trading period
        address payable _operator
    ) payable {
        require(
            _trader != address(0),
            "Strategy::constructor:INVALID TRADER ADDRESS."
        );
        require(
            _predictionMarket != address(0),
            "Strategy::constructor:INVALID PREDICTION MARKET ADDRESS."
        );
        require(msg.value > 0, "Strategy::constructor: ZERO_FUNDS");

        predictionMarket = IPredictionMarket(_predictionMarket);
        strategyName = _name;
        trader = _trader;
        initialTraderFunds = msg.value;
        traderPortfolio = msg.value;
        operator = _operator;

        depositPeriod = block.timestamp + _depositPeriod;
        tradingPeriod = depositPeriod + _tradingPeriod;
        status = StrategyStatus.ACTIVE;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyTrader {
        require(
            feePercentage < 10000,
            "Strategy:setFeePercentage:: FEE_EXCEEDS_LIMIT"
        );
        feePercentage = _feePercentage;
    }

    function follow() external payable isStrategyActive inDepositPeriod {
        User storage user = userInfo[msg.sender];

        require(msg.value > 0, "Strategy::follow: ZERO_FUNDS");
        require(user.depositAmount == 0, "Strategy::follow: ALREADY_FOLLOWING");

        totalUserFunds += msg.value;
        totalUsers++;
        userPortfolio = totalUserFunds;
        user.depositAmount = msg.value;

        emit StrategyFollowed(msg.sender, msg.value);
    }

    /**--------------------------BET PLACE RELATED FUNCTIONS-------------------------- */
    function placeBet(
        uint256 _conditionIndex,
        uint8 _side,
        uint256 _amount
    ) external isStrategyActive onlyTrader {
        require(
            !_isMarketSettled(_conditionIndex),
            "Strategy:placeBet:: MARKET_SETTLED"
        );
        require(
            traderPortfolio >= _amount && _amount > 0,
            "Strategy:placeBet:: INVALID_BET_AMOUNT"
        );

        uint256 betAmount;
        if (
            tradingPeriod >= block.timestamp && depositPeriod < block.timestamp
        ) {
            betAmount = _betInTradingPeriod(_amount, _side, _conditionIndex);
        } else {
            betAmount = _betInDepositPeriod(_amount, _side, _conditionIndex);
        }

        predictionMarket.betOnCondition{value: betAmount}(
            _conditionIndex,
            _side
        );

        emit BetPlaced(_conditionIndex, _side, betAmount);
    }

    //0 - deposit and claiming period
    //1 - trading
    function _updateActiveMarkets(uint256 _conditionIndex, uint8 _scenario)
        internal
    {
        if (_scenario == 1) {
            if (!isBetPlaced[_conditionIndex][1]) {
                isBetPlaced[_conditionIndex][1] = true;
                totalUserActiveMarkets++;
            }
        }
        if (!isBetPlaced[_conditionIndex][0]) {
            isBetPlaced[_conditionIndex][0] = true;
            totalTraderActiveMarkets++;
        }
    }

    function _betInDepositPeriod(
        uint256 _amount,
        uint8 _side,
        uint256 _conditionIndex
    ) internal returns (uint256 betAmount) {
        betAmount = _amount;
        traderPortfolio -= _amount;

        Market storage market = markets[_conditionIndex];
        if (_side == 0) {
            market.traderLowBets += _amount;
        } else {
            market.traderHighBets += _amount;
        }

        _updateActiveMarkets(_conditionIndex, 0);
    }

    function _betInTradingPeriod(
        uint256 _amount,
        uint8 _side,
        uint256 _conditionIndex
    ) internal inTradingPeriod returns (uint256 betAmount) {
        betAmount = _getBetAmount(_amount);
        require(betAmount <= userPortfolio, "Strategy:placeBet OUT_OF_FUNDS");

        userPortfolio -= betAmount;
        traderPortfolio -= _amount;

        Market storage market = markets[_conditionIndex];
        if (_side == 0) {
            market.userLowBets += betAmount;
            market.traderLowBets += _amount;
        } else {
            market.userHighBets += betAmount;
            market.traderHighBets += _amount;
        }

        _updateActiveMarkets(_conditionIndex, 1);
        betAmount += _amount;
    }

    function _getBetAmount(uint256 _amount)
        internal
        view
        returns (uint256 betAmount)
    {
        uint256 percentage = _getPercentage(_amount);
        require(
            percentage < MAX_BET_PERCENTAGE,
            "Strategy::placeBet:: AMOUNT_EXCEEDS_5_PERCENTAGE"
        );
        betAmount =
            (totalUserFunds * percentage) /
            (PERCENTAGE_MULTIPLIER * 100);

        //safety check
        require(betAmount < totalUserFunds);
    }

    function _getPercentage(uint256 _amount)
        internal
        view
        returns (uint256 percentage)
    {
        percentage =
            (_amount * 100 * PERCENTAGE_MULTIPLIER) /
            initialTraderFunds;
    }

    /**--------------------------BET CLAIM RELATED FUNCTIONS-------------------------- */
    function claimBet(uint256 _conditionIndex) external {
        Market storage market = markets[_conditionIndex];
        require(
            isBetPlaced[_conditionIndex][0] || isBetPlaced[_conditionIndex][1],
            "Strategy:claimBet:: NO_BETS"
        );
        require(
            _isMarketSettled(_conditionIndex),
            "Strategy:claimBet:: MARKET_ACTIVE"
        );
        require(!market.isClaimed, "Strategy:claimBet:: ALREADY_CLAIMED");

        uint256 totalLowBets = market.userLowBets + market.traderLowBets;
        uint256 totalHighBets = market.userHighBets + market.traderHighBets;
        if (totalLowBets == 0 && totalHighBets == 0) return;

        if (isBetPlaced[_conditionIndex][1]) totalUserActiveMarkets--;
        totalTraderActiveMarkets--;
        market.isClaimed = true;

        uint256 initialAmount = address(this).balance;
        predictionMarket.claim(_conditionIndex);
        market.amountClaimed = address(this).balance - initialAmount;

        uint8 winningSide = _getWinningSide(_conditionIndex);

        if (winningSide == 1) {
            _updatePortfolio(
                market.amountClaimed,
                totalHighBets,
                market.userHighBets
            );
        } else {
            _updatePortfolio(
                market.amountClaimed,
                totalLowBets,
                market.userLowBets
            );
        }

        emit BetClaimed(_conditionIndex, winningSide, market.amountClaimed);
    }

    function _updatePortfolio(
        uint256 _amountClaimed,
        uint256 _totalBets,
        uint256 _userBets
    ) internal {
        if (_totalBets == 0) return;
        uint256 userPart = (_amountClaimed * _userBets) / _totalBets;
        userPortfolio += userPart;
        traderPortfolio += (_amountClaimed - userPart);
    }

    /**--------------------------MARKET RELATED VIEW FUNCTIONS-------------------------- */
    function _isMarketSettled(uint256 _conditionIndex)
        internal
        view
        returns (bool)
    {
        (, , , uint256 settlementTime, , , , , , ) = predictionMarket
            .conditions(_conditionIndex);
        if (settlementTime > block.timestamp) return false;
        return true;
    }

    function _getWinningSide(uint256 _conditionIndex)
        internal
        view
        returns (uint8)
    {
        (
            ,
            ,
            int256 triggerPrice,
            ,
            ,
            int256 settledPrice,
            ,
            ,
            ,

        ) = predictionMarket.conditions(_conditionIndex);
        if (triggerPrice >= settledPrice) return 0;
        return 1;
    }

    /**--------------------------UNFOLLOW AND CLAIMS-------------------------- */
    function unfollow() external onlyUser {
        require(
            depositPeriod >= block.timestamp || tradingPeriod < block.timestamp,
            "Strategy:unfollow:: CANNOT_CLAIM_IN_TRADING_PERIOD"
        );

        if (depositPeriod >= block.timestamp) {
            _returnUserFunds();
        } else {
            _unfollow();
        }
    }

    function _returnUserFunds() internal {
        User storage user = userInfo[msg.sender];
        require(user.depositAmount != 0, "Strategy:unfollow:: ALREADY_CLAIMED");

        uint256 toClaim = getUserClaimAmount(msg.sender);
        totalUserFunds -= msg.value;
        userPortfolio = totalUserFunds;
        user.depositAmount = 0;

        payable(msg.sender).transfer(toClaim);
        emit StrategyUnfollowed(msg.sender, toClaim, "BEFORE_TRADE");
    }

    function _unfollow() internal {
        require(
            totalUserActiveMarkets == 0,
            "Strategy:unfollow:: MARKET_ACTIVE"
        );
        User storage user = userInfo[msg.sender];
        require(!user.exited, "Strategy:unfollow:: ALREADY_CLAIMED");

        uint256 toClaim = getUserClaimAmount(msg.sender);
        user.exited = true;
        user.claimedAmount = toClaim;
        payable(msg.sender).transfer(toClaim);

        emit StrategyUnfollowed(msg.sender, toClaim, "AFTER_TRADE");
    }

    function getUserClaimAmount(address _user)
        public
        view
        returns (uint256 amount)
    {
        User memory userDetails = userInfo[_user];
        if (userPortfolio > totalUserFunds) {
            uint256 profit = ((userPortfolio - getTraderFees()) *
                userDetails.depositAmount) / totalUserFunds;

            amount = userDetails.depositAmount + profit;
        } else if (userPortfolio == totalUserFunds) {
            amount = userDetails.depositAmount;
        } else {
            uint256 loss = (userPortfolio * userDetails.depositAmount) /
                totalUserFunds;

            amount = userDetails.depositAmount - loss;
        }
    }

    function getTraderFees() public view returns (uint256 fees) {
        fees = 0;
        if (userPortfolio > totalUserFunds) {
            fees = (userPortfolio * feePercentage) / PERCENTAGE_MULTIPLIER;
        }
    }

    function removeTraderFund() external tradingPeriodEnded onlyTrader {
        require(
            totalTraderActiveMarkets == 0,
            "Strategy:removeTraderFund:: MARKET_ACTIVE"
        );
        require(
            traderClaimedAmount == 0,
            "Strategy:removeTraderFund:: ALREADY_CLAIMED"
        );
        traderClaimedAmount = traderPortfolio;
        traderPortfolio = 0;
        initialTraderFunds = 0;

        status = StrategyStatus.INACTIVE;

        trader.transfer(traderClaimedAmount);

        emit StrategyInactive();
        emit TraderClaimed(traderClaimedAmount);
    }

    function claimFees() external onlyTrader {
        require(
            totalUserActiveMarkets == 0,
            "Strategy:removeTraderFund:: MARKET_ACTIVE"
        );
        require(!isFeeClaimed, "Strategy:claimFees:: ALREADY_CLAIMED");
        isFeeClaimed = true;
        traderFees = getTraderFees();

        trader.transfer(traderFees);
        emit TraderFeeClaimed(traderFees);
    }

    function inCaseTokensGetStuck(address _token) external {
        require(
            operator == msg.sender,
            "Strategy:inCaseTokensGetStuck:: INVALID_OPERATOR"
        );
        if (_token != address(0)) {
            IERC20 token = IERC20(_token);
            token.transfer(operator, token.balanceOf(address(this)));
        } else {
            operator.transfer(address(this).balance);
            status = StrategyStatus.INACTIVE;
            emit StrategyInactive();
        }
    }

    receive() external payable {
        require(
            address(predictionMarket) == msg.sender,
            "Strategy:receive:: INVALID_ETH_SOURCE"
        );
    }
}

// File: contracts/StrategyFactory.sol

pragma solidity 0.8.0;

contract StrategyFactory {
    IPredictionMarket public predictionMarket;
    address payable public operator;
    uint256 public strategyID;

    //strategyID -> strategy
    mapping(uint256 => address) public strategies;
    mapping(address => uint256[]) public traderStrategies;

    event StartegyCreated(
        address traderAddress,
        string traderName,
        uint256 id,
        uint256 amount,
        address strategyAddress
    );

    constructor(address _predictionMarket) {
        require(
            _predictionMarket != address(0),
            "StrategyFactory::constructor: INVALID_PREDICTION_MARKET_ADDRESS."
        );
        predictionMarket = IPredictionMarket(_predictionMarket);
        operator = payable(msg.sender);
    }

    function createStrategy(
        string memory _name,
        uint256 _depositPeriod,
        uint256 _tradingPeriod
    ) external payable {
        require(
            msg.value > 0,
            "StrategyFactory::createStrategy: ZERO_DEPOSIT_FUND"
        );

        strategyID = strategyID + 1;
        traderStrategies[msg.sender].push(strategyID);

        Strategy strategy = new Strategy{value: msg.value}(
            address(predictionMarket),
            _name,
            payable(msg.sender),
            _depositPeriod,
            _tradingPeriod,
            operator
        );
        strategies[strategyID] = address(strategy);

        emit StartegyCreated(
            msg.sender,
            _name,
            strategyID,
            msg.value,
            address(strategy)
        );
    }
}