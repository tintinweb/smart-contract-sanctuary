/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

pragma solidity 0.7.0;


interface IPredictionMarket {


    struct ConditionInfo {
        string market;
        address oracle;
        int256 triggerPrice;
        uint256 settlementTime;
        bool isSettled;
        int256 settledPrice;
        address lowBetToken;
        address highBetToken;
        uint256 totalStakedAbove;
        uint256 totalStakedBelow;
    }

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


    function prepareCondition(
        address _oracle,
        uint256 _settlementTime,
        int256 _triggerPrice,
        string memory _market
    ) external ;

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
        payable ;

    function settleCondition(uint256 _conditionIndex) external ;

    function claim(uint256 _conditionIndex) external ;
    
    //totalPayout - Payout to be distributed among winners(total eth staked by loosing side)
    //winnersTotalETHStaked - total eth staked by the winning side
    function getClaimAmount(
        uint256 totalPayout,
        uint256 winnersTotalETHStaked,
        uint256 userStake
    )
        external
        pure
        returns (uint256 totalWinnerRedeemable, uint256 platformFees);
    

    function getBalance(uint256 _conditionIndex, address _user)
        external
        view
        returns (uint256 LBTBalance, uint256 HBTBalance);

}

contract Strategy {
    uint256 public volume;
    uint256 public tradersCount;
    
    struct Trader {
      uint256 traderId;
      string name;
    }
    
    struct Market {
      uint256 conditionIndex;
      uint256 highBetAmount;
	  uint256 lowBetAmount;
	  uint256 amountLeft;
	  uint256 amountClaimed;
    }
    
    struct Bet {
      uint256 conditionIndex;
      uint256 amountPlaced;
      uint256 amountClaimed;
    }
    
    mapping (address => Trader) public traders;
    mapping (address => uint256) public userInfo;
    mapping (address => Bet[] ) public bets;
    
    IPredictionMarket public predictionMarket;
    
    constructor(address _predictionMarket){
        predictionMarket = IPredictionMarket(_predictionMarket);
    }
    
    function createStrategy(string memory _name) public {
        tradersCount += 1;
        Trader memory trader = Trader({
            traderId: tradersCount,
            name: _name
        });

        traders[msg.sender] = trader;
    }
    
    function addFund() public payable{
        userInfo[msg.sender] += msg.value;
        volume += msg.value;
    }
    
    function bet(address _userAddress, uint256 _conditionIndex, uint8 _side, uint256 _proportion) public {
        uint256 totalAmountFunded = userInfo[_userAddress];
        uint256 betAmount = totalAmountFunded * (_proportion/100);
        Bet memory newBet = Bet({
            conditionIndex: _conditionIndex,
            amountPlaced: betAmount,
            amountClaimed: 0
        });
        bets[_userAddress].push(newBet);
        predictionMarket.betOnCondition{value:betAmount}(_conditionIndex, _side);
    }
    
    function claim(address _userAddress, uint256 _conditionIndex) public {
        predictionMarket.claim(_conditionIndex);
    }
}