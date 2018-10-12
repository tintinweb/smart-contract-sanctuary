pragma solidity ^0.4.13;

interface IERC20 {
  function transfer(address _to, uint256 _amount) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
  function balanceOf(address _owner) constant external returns (uint256 balance);
  function approve(address _spender, uint256 _amount) external returns (bool success);
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) external returns (bool success);
  function totalSupply() external constant returns (uint);
}

interface IPrizeCalculator {
    function calculatePrizeAmount(uint _predictionTotalTokens, uint _winOutputTotalTokens, uint _forecastTokens)
        pure
        external
        returns (uint);
}

interface IResultStorage {
    function getResult(bytes32 _predictionId) external returns (uint8);
}

contract Owned {
    address public owner;
    address public executor;
    address public newOwner;
    address public superOwner;
  
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        superOwner = msg.sender;
        owner = msg.sender;
        executor = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "User is not owner");
        _;
    }

    modifier onlySuperOwner {
        require(msg.sender == superOwner, "User is not owner");
        _;
    }

    modifier onlyOwnerOrSuperOwner {
        require(msg.sender == owner || msg.sender == superOwner, "User is not owner");
        _;
    }

    modifier onlyAllowed {
        require(msg.sender == owner || msg.sender == executor || msg.sender == superOwner, "Not allowed");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwnerOrSuperOwner {
        newOwner = _newOwner;
    }

    function transferSuperOwnership(address _newOwner) public onlySuperOwner {
        superOwner = _newOwner;
    }

    function transferExecutorOwnership(address _newExecutor) public onlyOwnerOrSuperOwner {
        emit OwnershipTransferred(executor, _newExecutor);
        executor = _newExecutor;
    }
}

contract Market is Owned {
    using SafeMath for uint;  

    event PredictionAdded(bytes32 id);
    event ForecastAdded(bytes32 predictionId, bytes32 _forecastId); 
    event PredictionStatusChanged(bytes32 predictionId, PredictionStatus oldStatus, PredictionStatus newStatus);
    event Refunded(bytes32 predictionId, bytes32 _forecastId);
    event PredictionResolved(bytes32 predictionId, uint8 winningOutcomeId);
    event PaidOut(bytes32 _predictionId, bytes32 _forecastId);
    //event Debug(uint index);

    enum PredictionStatus {
        NotSet,    // 0
        Published, // 1
        Resolved,  // 2
        Paused,    // 3
        Canceled   // 4
    }  
    
    struct Prediction {
        uint forecastEndUtc;
        uint fee; // in WEIS       
        PredictionStatus status;    
        uint8 outcomesCount;
        uint8 resultOutcome;
        mapping(bytes32 => Forecast) forecasts;
        mapping(uint8 => uint) outcomeTokens;
        uint initialTokens;  
        uint totalTokens;          
        uint totalForecasts;   
        uint totalTokensPaidout;     
        address resultStorage;   
        address prizeCalculator;
    }

    struct Forecast {    
        address user;
        uint amount;
        uint8 outcomeId;
        uint paidOut;
    }

    struct ForecastIndex {    
        bytes32 predictionId;
        bytes32 forecastId;
    }

    uint8 public constant version = 1;
    address public token;
    bool public paused = true;

    mapping(bytes32 => Prediction) public predictions;

    mapping(address => ForecastIndex[]) public walletPredictions;
  
    uint public totalFeeCollected;

    modifier notPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier statusIsCanceled(bytes32 _predictionId) {
        require(predictions[_predictionId].status == PredictionStatus.Canceled, "Prediction is not canceled");
        _;
    }

    function validatePrediction(bytes32 _id, uint _amount, uint8 _outcomeId) private view {
        require(predictions[_id].status == PredictionStatus.Published, "Prediction is not published");
        require(predictions[_id].forecastEndUtc > now, "Forecasts are over");
        require(predictions[_id].outcomesCount >= _outcomeId && _outcomeId > 0, "Outcome id is not in range");
        require(predictions[_id].fee < _amount, "Amount should be bigger then fee");
    }

    modifier senderIsToken() {
        require(msg.sender == address(token), "Sender is not token");
        _;
    }
    
    function initialize(address _token) external onlyOwnerOrSuperOwner {
        token = _token;
        paused = false;
    }

    // TODO: for testing 1,1929412716 ,3,1,6,0,"0xca35b7d915458ef540ade6068dfe2f44e8fa733c" 
    function addPrediction(
        bytes32 _id,
        uint _forecastEndUtc,
        uint _fee,
        uint8 _outcomesCount,  
        uint _initialTokens,   
        address _resultStorage, 
        address _prizeCalculator) public onlyAllowed notPaused {

        predictions[_id].forecastEndUtc = _forecastEndUtc;
        predictions[_id].fee = _fee;
        predictions[_id].status = PredictionStatus.Published;  
        predictions[_id].outcomesCount = _outcomesCount;
        predictions[_id].initialTokens = _initialTokens;
        predictions[_id].totalTokens = _initialTokens;
        predictions[_id].resultStorage = _resultStorage;
        predictions[_id].prizeCalculator = _prizeCalculator;

        emit PredictionAdded(_id);
    }

    function changePredictionStatus(bytes32 _predictionId, PredictionStatus _status) 
            public 
            onlyAllowed {
        require(predictions[_predictionId].status != PredictionStatus.NotSet, "Prediction not exist");
        require(_status != PredictionStatus.Resolved, "Use resolve function");
        require(_status != PredictionStatus.Canceled, "Use cancel function");
        emit PredictionStatusChanged(_predictionId, predictions[_predictionId].status, _status);
        predictions[_predictionId].status = _status;            
    }

    function cancel(bytes32 _predictionId) public onlyAllowed {    
        emit PredictionStatusChanged(_predictionId, predictions[_predictionId].status, PredictionStatus.Canceled);
        predictions[_predictionId].status = PredictionStatus.Canceled;    
    }

    function resolve(bytes32 _predictionId) public onlyAllowed {
        require(predictions[_predictionId].status == PredictionStatus.Published, "Prediction must be Published"); 

        if (predictions[_predictionId].forecastEndUtc < now) // allow to close prediction earliar
        {
            predictions[_predictionId].forecastEndUtc = now;
        }

        uint8 winningOutcomeId = IResultStorage(predictions[_predictionId].resultStorage).getResult(_predictionId);
        require(winningOutcomeId <= predictions[_predictionId].outcomesCount && winningOutcomeId > 0, "OutcomeId is not valid");

        emit PredictionStatusChanged(_predictionId, predictions[_predictionId].status, PredictionStatus.Resolved);
        predictions[_predictionId].resultOutcome = winningOutcomeId;
        predictions[_predictionId].status = PredictionStatus.Resolved; 
        emit PredictionResolved(_predictionId, winningOutcomeId);
    }

    function payout(bytes32 _predictionId, bytes32 _forecastId) public {
        require(predictions[_predictionId].status == PredictionStatus.Resolved, "Prediction should be resolved");
        require(predictions[_predictionId].resultOutcome != 0, "Outcome should be set");

        IPrizeCalculator calculator = IPrizeCalculator(predictions[_predictionId].prizeCalculator);
        
        Forecast storage forecast = predictions[_predictionId].forecasts[_forecastId];

        if (forecast.paidOut == 0) {
            uint winAmount = calculator.calculatePrizeAmount(
                predictions[_predictionId].totalTokens,
                predictions[_predictionId].outcomeTokens[predictions[_predictionId].resultOutcome],
                forecast.amount
            );
            assert(winAmount > 0);
            assert(IERC20(token).transfer(forecast.user, winAmount));
            forecast.paidOut = winAmount;
            predictions[_predictionId].totalTokensPaidout = predictions[_predictionId].totalTokensPaidout.add(winAmount);
            emit PaidOut(_predictionId, _forecastId);
        }     
    }

    // Owner can refund users forecasts
    function refundUser(bytes32 _predictionId, bytes32 _forecastId) public onlyAllowed {
        require (predictions[_predictionId].status != PredictionStatus.Resolved);
        
        performRefund(_predictionId, _forecastId);
    }
   
    // User can refund when status is CANCELED
    function refund(bytes32 _predictionId, bytes32 _forecastId) public statusIsCanceled(_predictionId) {
        performRefund(_predictionId, _forecastId);
    }

    function performRefund(bytes32 _predictionId, bytes32 _forecastId) private {
        require(predictions[_predictionId].forecasts[_forecastId].paidOut == 0, "Already paid");  

        uint refundAmount = predictions[_predictionId].forecasts[_forecastId].amount;
        predictions[_predictionId].totalTokensPaidout = predictions[_predictionId].totalTokensPaidout.add(refundAmount);        
        predictions[_predictionId].forecasts[_forecastId].paidOut = refundAmount;
                                                    
        assert(IERC20(token).transfer(predictions[_predictionId].forecasts[_forecastId].user, refundAmount)); 
        emit Refunded(_predictionId, _forecastId);
    }

    /// Called by token contract after Approval: this.TokenInstance.methods.approveAndCall()
    // _data = predictionId(32),forecastId(32),outcomeId(1)
    function receiveApproval(address _from, uint _amountOfTokens, address _token, bytes _data) 
            external 
            senderIsToken
            notPaused {    
        require(_amountOfTokens > 0, "amount should be > 0");
        require(_from != address(0), "not valid from");
        require(_data.length == 65, "not valid _data length");
        bytes1 outcomeIdString = _data[64];
        uint8 outcomeId = uint8(outcomeIdString);

        bytes32 predictionIdString = bytesToFixedBytes32(_data,0);
        bytes32 forecastIdString = bytesToFixedBytes32(_data,32);

        validatePrediction(predictionIdString, _amountOfTokens, outcomeId); 
        // Transfer tokens from sender to this contract
        require(IERC20(_token).transferFrom(_from, address(this), _amountOfTokens), "Tokens transfer failed.");

        uint amount = _amountOfTokens.sub(predictions[predictionIdString].fee);
        totalFeeCollected = totalFeeCollected.add(predictions[predictionIdString].fee);

        predictions[predictionIdString].totalTokens = predictions[predictionIdString].totalTokens.add(amount);
        predictions[predictionIdString].totalForecasts++;
        predictions[predictionIdString].outcomeTokens[outcomeId] = predictions[predictionIdString].outcomeTokens[outcomeId].add(amount);
        predictions[predictionIdString].forecasts[forecastIdString] = Forecast(_from, amount, outcomeId, 0);
       
        walletPredictions[_from].push(ForecastIndex(predictionIdString, forecastIdString));

        emit ForecastAdded(predictionIdString, forecastIdString);
    }

    //////////
    // View
    //////////
    function getForecast(bytes32 _predictionId, bytes32 _forecastId) public view returns(address, uint, uint8, uint) {
        return (predictions[_predictionId].forecasts[_forecastId].user,
            predictions[_predictionId].forecasts[_forecastId].amount,
            predictions[_predictionId].forecasts[_forecastId].outcomeId,
            predictions[_predictionId].forecasts[_forecastId].paidOut);
    }

    //////////
    // Safety Methods
    //////////
    function () public payable {
        require(false);
    }

    function withdrawETH() external onlyOwnerOrSuperOwner {
        owner.transfer(address(this).balance);
    }

    function withdrawTokens(uint _amount, address _token) external onlyOwnerOrSuperOwner {
        IERC20(_token).transfer(owner, _amount);
    }

    function pause(bool _paused) external onlyOwnerOrSuperOwner {
        paused = _paused;
    }

    function bytesToFixedBytes32(bytes memory b, uint offset) internal pure returns (bytes32) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}