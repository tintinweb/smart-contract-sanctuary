/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// File: StrategyStorage.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;


contract StrategyStorage {
    enum StrategyStatus {
        ACTIVE,
        INACTIVE
    }

    struct User {
        uint256 depositAmount;
        uint256 entryCheckpointId;
        uint256 exitCheckpointId;
        uint256 totalProfit;
        uint256 totalLoss;
        bool exited;
        uint256 remainingClaim;
        //totalClaimed = amount + profit - loss
    }

    //strategy details
    StrategyStatus public status;
    IPredictionMarket public predictionMarket;
    address payable public trader;
    string public strategyName;
    uint256 public traderFund;

    uint256 public latestCheckpointId;

    //user details
    mapping(address => User) public userInfo;

    //to get list of users
    address[] public users;
    uint256[] public userAmounts;

    uint256 public totalUserFunds;

    //Fees Percentage
    uint256 public traderFees;

    struct Checkpoint {
        address[] users;
        uint256 totalVolume;
        uint256 totalInvested;
        uint256 totalProfit;
        uint256 totalLoss;
    }

    struct Market {
        uint256 lowBets;
        uint256 highBets;
    }

    mapping(uint256 => Checkpoint) public checkpoints;

    //maps checkpoint -> conditionindex -> market
    mapping(uint256 => mapping(uint256 => Market)) public markets;
    mapping(uint256 => uint256[]) public conditionIndexToCheckpoints;
}

// File: Checkpoint.sol

pragma solidity 0.8.0;


contract Checkpoint is StrategyStorage {
    function addCheckpoint(address[] memory _users, uint256 _totalVolume)
        internal
    {
        Checkpoint storage newCheckpoint = checkpoints[latestCheckpointId++];
        newCheckpoint.users = _users;
        newCheckpoint.totalVolume = _totalVolume;
    }

    function updateCheckpoint(
        uint256 _checkpointId,
        uint256 _totalInvestedChange,
        uint256 _totalProfitChange,
        uint256 _totalLossChange
    ) internal {
        Checkpoint storage existingCheckpoint = checkpoints[_checkpointId];
        existingCheckpoint.totalInvested += _totalInvestedChange;
        existingCheckpoint.totalProfit += _totalProfitChange;
        existingCheckpoint.totalLoss += _totalLossChange;
    }
}

// File: IPredictionMarket.sol

pragma solidity 0.8.0;

interface IPredictionMarket {
    event ConditionPrepared(
        uint256 indexed conditionIndex,
        address indexed oracle,
        uint256 indexed settlementTime,
        int256 triggerPrice,
        address lowBetTokenAddress,
        address highBetTokenAddress
    );

    event UserPrediction(
        uint256 indexed conditionIndex,
        address indexed userAddress,
        uint256 indexed ETHStaked,
        uint8 prediction,
        uint256 timestamp
    );

    event UserClaimed(
        uint256 indexed conditionIndex,
        address indexed userAddress,
        uint256 indexed winningAmount
    );

    event ConditionSettled(
        uint256 indexed conditionIndex,
        int256 indexed settledPrice,
        uint256 timestamp
    );

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

    function calculateClaimAmount(uint256 _conditionIndex) external 
    returns (uint8 winningSide, uint256 userstake, uint256 totalWinnerRedeemable, uint256 platformFees);

    function getPerUserClaimAmount(uint256 _conditionIndex) external returns (uint8, uint256);

    function getBalance(uint256 _conditionIndex, address _user)
        external
        view
        returns (uint256 LBTBalance, uint256 HBTBalance);
}

// File: IBetToken.sol

pragma solidity 0.8.0;

interface IBetToken {

    /**
     * Functions for public variables
     */
    function totalHolders() external returns (uint256);
    function predictionMarket() external returns (address);

    /**
     * Functions overridden in BetToken
     */
    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;

    function burnAll(address _from) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * Functions of Pausable
     */
    function paused() external view returns (bool);    
    /**
     * Functions of ERC20
     */
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view  returns (uint8);
    
    /**
     * Functions of IERC20
     */
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}
// File: Strategy.sol

pragma solidity 0.8.0;




contract Strategy is Checkpoint {

    event StrategyFollowed(
        address userFollowed,
        uint256 userAmount,
        address trader,
        uint256 checkpointId
    );
    event StrategyUnfollowed(
        address userunFollowed,
        uint256 userAmountClaimed,
        uint256 checkpointId
    );
    event BetPlaced(
        uint256 conditionIndex,
        uint8 side,
        uint256 totalAmount
    );
    modifier isStrategyActive() {
        require(
            status == StrategyStatus.ACTIVE,
            "Strategy::isStrategyActive: STRATEGY_INACTIVE"
        );
        _;
    }

    modifier onlyTrader() {
        require(msg.sender == trader, "Strategy::onlyTrader: INVALID_SENDER");
        _;
    }

    modifier onlyUser() {
        require(
            userInfo[msg.sender].depositAmount > 0,
            "Strategy::onlyTrader: INVALID_USER"
        );
        _;
    }

    constructor(
        address _predictionMarket,
        string memory _name,
        address payable _trader
    ) payable {

        require(
            _trader != address(0),
            "Strategy::constructor:INVALID TRADER ADDRESS."
        );
        require(
            _predictionMarket != address(0),
            "Strategy::constructor:INVALID PREDICTION MARKET ADDRESS."
        );
        require(
            msg.value > 0, 
            "Strategy::constructor: ZERO_FUNDS"
        );

        predictionMarket = IPredictionMarket(_predictionMarket);
        strategyName = _name;
        trader = _trader;
        traderFund += msg.value;

        status = StrategyStatus.ACTIVE;
    }

    function follow() public payable isStrategyActive {
        User storage user = userInfo[msg.sender];

        require(msg.value > 0, "Strategy::follow: ZERO_FUNDS");
        require(
            user.depositAmount == 0,
            "Strategy::follow: ALREADY_FOLLOWING"
        );

        totalUserFunds += msg.value;

        user.depositAmount = msg.value;
        users.push(msg.sender);

        //get total volume (trader + all users)
        addCheckpoint(users, (totalUserFunds + traderFund));
        user.entryCheckpointId = latestCheckpointId;
        emit StrategyFollowed(
         msg.sender,
         msg.value,
         trader,
         latestCheckpointId);
    }

    //unfollow is subjected to fund availability
    function unfollow() public onlyUser {
        User storage user = userInfo[msg.sender];
        user.exitCheckpointId = latestCheckpointId;
        (uint256 userClaimAmount,
        uint256 userTotalProfit,
        uint256 userTotalLoss ) = getUserClaimAmount(user);
        require(userClaimAmount > 0, "Strategy::unfollow: ZERO_CLAIMABLE_AMOUNT");

        (payable(msg.sender)).transfer(userClaimAmount);
        user.totalProfit = userTotalProfit;
        user.totalLoss = userTotalLoss;

        totalUserFunds -= userClaimAmount;
        for (uint256 userIndex = 0; userIndex < users.length; userIndex++){
            if(users[userIndex] == msg.sender) {
                delete users[userIndex];
                break;
            }
        }
        addCheckpoint(users, (totalUserFunds + traderFund));

        emit StrategyUnfollowed(
            msg.sender,
            userClaimAmount,
            latestCheckpointId-1
        );
    }
    //get user claim amount. deduct fees from profit
    // update exitpoint
    // transfer amt
    // add new checkpoint, pop the user from array, update userfund
    // update user(if any)

    // for getting USer claim amount 
    function getUserClaimAmount( User memory userDetails) internal view returns(uint256 userClaimAmount,
        uint256 userTotalProfit,
        uint256 userTotalLoss ){
        for (uint256 cpIndex = userDetails.entryCheckpointId; cpIndex < userDetails.exitCheckpointId; cpIndex++){
            Checkpoint memory cp = checkpoints[cpIndex];
 
            uint256 userProfit = (cp.totalProfit * userDetails.depositAmount)/cp.totalVolume;
            userTotalLoss += (cp.totalLoss * userDetails.depositAmount)/cp.totalVolume;

            userTotalProfit += userProfit - calculateFees(userProfit);            
        }
        userClaimAmount = userDetails.depositAmount + userTotalProfit - userTotalLoss;
        return(userClaimAmount, userTotalProfit, userTotalLoss);
    }

    function removeTraderFund() public onlyTrader {
        if (status == StrategyStatus.ACTIVE) status = StrategyStatus.INACTIVE;
        uint256 amount = getClaimAmount();
        traderFund -= amount;
        trader.transfer(amount);
    }

    // for getting Trader claim amount 
    function getClaimAmount() internal view returns(uint256 traderClaimAmount){
        uint256 traderTotalProfit; 
        uint256 traderTotalLoss; 
        for (uint256 cpIndex = 0; cpIndex < latestCheckpointId; cpIndex++){
            Checkpoint memory cp = checkpoints[cpIndex];
            uint256 traderProfit = (cp.totalProfit * traderFund)/cp.totalVolume;
            traderTotalLoss += (cp.totalLoss * traderFund)/cp.totalVolume;

            uint256 userProfit = cp.totalProfit - traderProfit;
            traderTotalProfit += traderProfit + calculateFees(userProfit);            
        }
        traderClaimAmount = traderFund + traderTotalProfit - traderTotalLoss;
    }

    //fuction to calculate fees
    function calculateFees(uint256 amount) internal view returns (uint256 feeAmount) {
        feeAmount = (amount*traderFees)/10000;
    }

    function bet(
        uint256 _conditionIndex,
        uint8 _side,
        uint256 _amount
    ) public isStrategyActive onlyTrader {
        require(latestCheckpointId>0,"Strategy::bet: NO CHECKPOINT CREATED YET");

        require(users.length > 0,"Strategy::bet: NO USERS EXIST");

        uint256 percentage = (_amount*100)/traderFund ;        
        require(percentage<5,"Strategy::placeBet:INVALID AMOUNT. Percentage > 5");

        uint256 betAmount = ((percentage * totalUserFunds)/100) + _amount ;
        Checkpoint storage checkpoint = checkpoints[latestCheckpointId-1];
        checkpoint.totalInvested += betAmount;
        conditionIndexToCheckpoints[_conditionIndex].push(latestCheckpointId);
        Market memory market;
        if (_side == 0) {
            market.lowBets = betAmount;
        } else {
            market.highBets = betAmount;
        }
        markets[latestCheckpointId][_conditionIndex] = market;

        predictionMarket.betOnCondition{value:betAmount}(_conditionIndex, _side);

        emit BetPlaced(
            _conditionIndex,
            _side,
            betAmount);
    }

    function claim(uint256 _conditionIndex) public isStrategyActive onlyTrader {

        (uint8 winningSide, uint256 perBetPrice) = predictionMarket.getPerUserClaimAmount(
            _conditionIndex
        );
        predictionMarket.claim(
            _conditionIndex
        );

        (
            ,
            ,
            ,
            ,
            ,
            ,
            address lowBetToken,
            address highBetToken,
            ,

        ) = predictionMarket.conditions(_conditionIndex);

        IBetToken highBet = IBetToken(highBetToken);
        IBetToken lowBet = IBetToken(lowBetToken);

        uint256 totalInvested;
        uint256[] memory checkpointList = conditionIndexToCheckpoints[
            _conditionIndex
        ];
        for (uint256 index = 0; index < checkpointList.length; index++) {
            Market memory market = markets[checkpointList[index]][
                _conditionIndex
            ];
            Checkpoint memory cp = checkpoints[checkpointList[index]];

            uint256 profit;
            uint256 loss;

            if (winningSide==1 && market.highBets > 0) {
                profit = market.highBets * perBetPrice;
                loss = market.lowBets;
            } else {
                profit = market.lowBets * perBetPrice;
                loss = market.highBets;
            }

            cp.totalProfit += profit;
            cp.totalLoss += loss;

            totalUserFunds = totalUserFunds + profit - loss;
        }
    }

    function getConditionDetails(uint256 _conditionIndex)
        public
        view
        returns (
            string memory market,
            uint256 settlementTime,
            bool isSettled
        )
    {
        (market, , , settlementTime, isSettled, , , , , ) = (
            predictionMarket.conditions(_conditionIndex)
        );
    }
}

// File: StrategyFactory.sol

pragma solidity 0.8.0;


contract StrategyFactory {
    IPredictionMarket public predictionMarket;
    uint256 public traderId;

    mapping(address => uint256[]) public traderStrategies;

    event CreateStrategy(string trader, uint256 id, uint256 amount, address strategyAddress);

    constructor(address _predictionMarket) {
        require(
            _predictionMarket != address(0),
            "StrategyFactory::constructor:INVALID PRDICTION MARKET ADDRESS."
        );
        predictionMarket = IPredictionMarket(_predictionMarket);
    }

    function createStrategy(string memory _name)
        external
        payable
        returns (uint256)
    {
        require(
            msg.value > 0,
            "StrategyFactory::createStrategy: ZERO_DEPOSIT_FUND"
        );

        traderId = traderId + 1;
        traderStrategies[msg.sender].push(traderId);

        Strategy strategy = new Strategy{value: msg.value}(
            address(predictionMarket),
            _name,
            payable(msg.sender)
        );
        emit CreateStrategy(_name, traderId, msg.value, address(strategy)); 

        return traderId;
    }
}