/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

pragma solidity ^0.8.1;

contract Prediction {


address owner;
address marketingAddress;
address feeAddress;
address mgr;
uint256 waitingForBetsTime = 3 minutes; // CHANGE TO 5
uint256 predictionIntervalTime = 3 minutes; // CHANGE TO 15

Token token1; 
Token token2;
Token token3; 

struct Token{
    string _tokenName; 
    string _symbol;
    uint256 _countdownEnd;
    uint256 _lockedEnd;
    bool _isLocked;
    uint256 _startPrice;
    uint256 _endPrice;
    BetsInfo _allBets;
}

constructor(address _mgr, address _marketingAdress, address _feeAddress) public {
    owner = msg.sender;
    mgr = _mgr;
    marketingAddress = _marketingAdress;
    feeAddress = _feeAddress;
}

function transferOwnership(address _newOwner) public onlyOwner {
    owner = _newOwner;
}

function changeMgr(address _newMgr) public onlyOwner {
    mgr = _newMgr;
}

function changeMarketingAddress(address _newMarketingAddress) public onlyOwner {
    marketingAddress = _newMarketingAddress;
}

function changeFeeAddress(address _newFeeAddress) public onlyOwner {
    feeAddress = _newFeeAddress;
}

event StartedCountdown(uint256 token, uint256 CountdownEnd);
event StartedPrediction(uint256 token,uint256 tokenPrice, bool error, uint256 LockedEnd);
event PredictionEnded(uint256 token, uint256 finalPrice, bool up);

modifier onlyMgr{
    require(msg.sender == mgr);
    _;
}

modifier onlyOwner{
    require(msg.sender == owner);
    _;
}

function changeToken1(string memory _tokenName, string memory _symbol) public onlyOwner {
token1 = getToken(_tokenName, _symbol);
}

function changeToken2(string memory _tokenName, string memory _symbol) public onlyOwner {
  token2 = getToken(_tokenName, _symbol);
}

function changeToken3(string memory _tokenName, string memory _symbol) public onlyOwner{
 token3 = getToken(_tokenName, _symbol);
}

function getToken(string memory _tokenName, string memory _symbol) private returns(Token memory) {
  return Token(_tokenName, _symbol, 0, 0, false, 0, 0, BetsInfo(0, 0, 0, 0));
}

uint256 private Token1Amount;
mapping (uint256 => Bet) private Token1Bets; // users betting => Bet Info


struct BetsInfo {
    uint256 upPool;
    uint256 downPool;
    uint256 upBetAmount;
    uint256 downBetAmount;
}


mapping(address => uint256) userBalance;


struct Bet {
    uint256 _amount;
    bool _up;
    address _address;
}


function GetAvailableWithdraw() public view returns(uint256){
    return userBalance[msg.sender];
}

function Withdraw() public {
    require(userBalance[msg.sender] > 0, "You don't have enough balance!");
    uint256 _amount = userBalance[msg.sender];
    userBalance[msg.sender] = 0;
    payable(msg.sender).transfer(_amount);
}

function EndPrediction(uint i, uint256 _endPrice) public onlyMgr {
    if(i == 1){
        bool _up = false;
        if(token1._startPrice < _endPrice) _up = true;

       (uint256 upBets,
        uint256 upAmount,
        uint256 downBets,
        uint256 downAmount) = GetBets(1);
        
        uint256 _pool = downAmount;
        uint256 _sPool = upAmount;
        if(_up) {
            _pool = upAmount;
            _sPool = downAmount;
        }
        
        for(uint _i = 0; Token1Amount > _i; _i++){
            
            if(Token1Bets[_i + 1]._up == _up){
                uint256 _amount = Token1Bets[_i + 1]._amount;
                uint256 _p = getPercent(_amount, _pool);
                uint256 _reward = getFraction(_p, _sPool);
                userBalance[Token1Bets[_i + 1]._address] = _amount + _reward;
                
            } 
            delete Token1Bets[_i + 1];
        }
        
        Token1Amount = 0;
        token1 = getToken(token1._tokenName, token1._symbol);
        emit PredictionEnded(1, _endPrice, _up);
        
        
    } else if(i == 2){
        
    } else if(i ==3) {
        
    } 
}

function getFraction(uint _percent, uint _base) private returns(uint) {
    return (_percent * _base) / 100;
}

function getPercent(uint _part, uint _whole) private returns(uint) {
    uint numerator = _part * 1000;
    require(numerator > _part);
    uint temp = numerator / _whole;
    return temp / 10;
}

function StartPrediction(uint i, uint256 _price) public onlyMgr{ // Error, New Time
    if(i == 1){
        
        (uint256 _up, uint256 _a, uint256 _down, uint256 _b) = GetBets(1);
        if(_up < 1 || _down < 1){
            emit StartedPrediction(1, 0, true, 0);
            return;
        } 
        
        token1._startPrice = _price;
        token1._isLocked = true;
        token1._lockedEnd = token1._countdownEnd + predictionIntervalTime;
        emit StartedPrediction(1, _price, false, token1._lockedEnd);
    } else if(i == 2){
        
    } else if(i ==3) {
        
    } 
}


function StartCountdown(uint i) public onlyMgr{
    if(i == 1){
        token1._isLocked = false;
        token1._countdownEnd = block.timestamp + waitingForBetsTime;
        emit StartedCountdown(1, token1._countdownEnd);
    } else if(i == 2){
        token2._isLocked = false;
        token2._countdownEnd = block.timestamp + waitingForBetsTime;
        emit StartedCountdown(2, token2._countdownEnd);
    } else if(i ==3) {
        token3._isLocked = false;
        token3._countdownEnd = block.timestamp + waitingForBetsTime;
        emit StartedCountdown(3, token3._countdownEnd);
    } 
}

function handleFees() private returns(uint256){
    uint256 _managerFee = getFraction(1, msg.value);
    uint256 _marketingFee = getFraction(3, msg.value);
    uint256 _otherFee = getFraction(2, msg.value);
    payable(mgr).transfer(_managerFee); // 1% fee to handle fees on manager
    payable(marketingAddress).transfer(_marketingFee); // 3% fee for marketing purposes
    payable(feeAddress).transfer(_otherFee); // 2% fee for other purposes
    return (((msg.value - _managerFee) - _marketingFee) - _otherFee); // Total sent amount - 6% fee
}

// TODO: add support for all five tokens :)
function AddBet(uint token, bool up) public payable {
    require(token < 6, "Invalid token!");

    if(token == 1){
        require(!token1._isLocked, "That token is locked! Wait until the prediction is finished!");
        uint256 _amount = handleFees();
        Token1Amount++;
        Token1Bets[Token1Amount]._amount = _amount;
        Token1Bets[Token1Amount]._up = up;
        Token1Bets[Token1Amount]._address = msg.sender;
        if(up){
            token1._allBets.upPool += _amount;
            token1._allBets.upBetAmount++;
        } else{
            token1._allBets.downPool += _amount;
            token1._allBets.downBetAmount++;
        }
        
    } else if(token == 2){
        
    } else if(token == 3){
        
    } 
}


// TODO: finish support for all three tokens
function GetBets(uint i) internal returns(uint256, uint256, uint256, uint256){
    uint256 upBets;
    uint256 upAmount;
    uint256 downBets;
    uint256 downAmount;
    if(i == 1){
        upBets = token1._allBets.upBetAmount;
        upAmount = token1._allBets.upPool;
        downBets = token1._allBets.downBetAmount;
        downAmount = token1._allBets.downPool;
    
    }
    
    return(upBets, upAmount, downBets, downAmount);
}


// TODO: Function to get time left of countdown / locking (public) 

// 1: started (1) not started (0)
// 2: UP Bets (100)
// 3: UP BNB
// 4: DOWN Bets (200)
// 5: DOWN BNB
// 6: Total BNB (300)
// 7: Your BNB (5)
// 8: UP or DOWN (UP 1)
// 9: Token Name
// 10: Token Symbol
// TODO: finish support for all five tokens

function GetStatus(uint _i) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, string memory, string memory) {
    uint256 started = 0;
    uint256 yourBet;
    uint side;
    if(_i == 1){
        // If the prediction is locked, meaning that you can't enter any BNB, the started var will be 1
        if(token1._isLocked){
            started = 1;
        }
        
        // For each bet
        for(uint i = 0; Token1Amount > i; i++){
            
            // If it's your bet, it will add it to the yourBet var
            if(Token1Bets[i + 1]._address == msg.sender){
                yourBet = Token1Bets[i + 1]._amount;
                // Side, 1 means UP and 0 means DOWN
                if(Token1Bets[i + 1]._up){
                    side = 1;
                } else{
                    side = 0;
                }
                break;
            }
        }
        return(started, token1._allBets.upBetAmount, token1._allBets.upPool, token1._allBets.downBetAmount, token1._allBets.downPool, token1._allBets.upPool + token1._allBets.downPool, yourBet, side, token1._tokenName, token1._symbol);
    }
    else return(0, 0, 0, 0, 0, 0, 0, 0, "", "");
}

}