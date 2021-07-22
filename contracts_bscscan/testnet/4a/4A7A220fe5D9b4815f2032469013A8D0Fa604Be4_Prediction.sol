/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

pragma solidity ^0.8.1;

contract Prediction {


address private owner;
address private marketingAddress;
address private feeAddress;
address private mgr;
uint256 private waitingForBetsTime = 1 minutes; // CHANGE TO 5
uint256 private predictionIntervalTime = 1 minutes; // CHANGE TO 15

Token private token1; 
Token private token2;
Token private token3; 

uint256 marketingFees;
uint256 otherFees;

uint256 private totalUpBNB;
uint256 private totalDownBNB;
uint256 private totalUpBets;
uint256 private totalDownBets;

mapping(address => bool) admins;

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

constructor(address _mgr, address _marketingAdress, address _feeAddress) {
    owner = msg.sender;
    admins[owner] = true;
    mgr = _mgr;
    marketingAddress = _marketingAdress;
    feeAddress = _feeAddress;
}

function addAdmin(address _newAdmin) onlyOwner public {
    require(admins[_newAdmin] == false);
    admins[_newAdmin] = true;
}

function removeAdmin(address _existingAdmin) onlyOwner public{
    require(admins[_existingAdmin] == true, "That address isn't an admin!");
    admins[_existingAdmin] = false;
}

modifier onlyAdmin(){
    require(admins[msg.sender] == true, "You are not an admin!");
    _;
}

function getFeeAddress() public view onlyAdmin returns(address){
    return feeAddress;
}

function getMarketingAddress() public view onlyAdmin returns(address){
    return marketingAddress;
}

function withdrawOtherFees() public onlyAdmin {
    require(otherFees > 0);
    payable(feeAddress).transfer(otherFees);
}

function withdrawMarketingFees() public onlyAdmin {
    require(marketingFees > 0);
    payable(marketingAddress).transfer(marketingFees);
}

function getAvailableFees() public view onlyAdmin returns(uint256, uint256){
    return(
    marketingFees,
    otherFees
        );
}

function getTotalStats() public view onlyAdmin returns(uint256, uint256, uint256, uint256){
    return(
     totalUpBNB,
     totalDownBNB,
     totalUpBets,
     totalDownBets
    );
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

event StartedCountdown(uint256 indexed token, uint256 CountdownEnd);
event StartedPrediction(uint256 indexed token,uint256 tokenPrice, bool error, uint256 LockedEnd);
event PredictionEnded(uint256 indexed token, uint256 finalPrice, bool indexed up);

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
uint256 private Token2Amount;
mapping (uint256 => Bet) private Token2Bets; // users betting => Bet Info
uint256 private Token3Amount;
mapping (uint256 => Bet) private Token3Bets; // users betting => Bet Info

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
        totalDownBets += downBets;
        totalDownBNB += downAmount;
        totalUpBets += upBets;
        totalUpBNB += upAmount;
        
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

function getFraction(uint _percent, uint _base) private pure returns(uint) {
    return (_percent * _base) / 100;
}

function getPercent(uint _part, uint _whole) private pure returns(uint) {
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
    uint256 _internalTransactionsFee = getFraction(1, msg.value);
    payable(mgr).transfer(_otherFee);
    marketingFees += _marketingFee;
    otherFees += _otherFee;
    return (((msg.value - _managerFee) - _marketingFee) - _otherFee) - _internalTransactionsFee; // Total sent amount - 7% fee (another 1% for internal transactions)
}

function AddBet(uint token, bool up) public payable {
    require(token < 6, "Invalid token!");
    require(msg.value > 30000000000000000, "Minimum depoit is 0.03 BNB!");
    require(!isBetting(token), "You can't place more than 1 bet!");
    
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
        require(!token2._isLocked, "That token is locked! Wait until the prediction is finished!");
        uint256 _amount = handleFees();
        Token2Amount++;
        Token2Bets[Token2Amount]._amount = _amount;
        Token2Bets[Token2Amount]._up = up;
        Token2Bets[Token2Amount]._address = msg.sender;
        if(up){
            token2._allBets.upPool += _amount;
            token2._allBets.upBetAmount++;
        } else{
            token2._allBets.downPool += _amount;
            token2._allBets.downBetAmount++;
        }
    } else if(token == 3){
        require(!token3._isLocked, "That token is locked! Wait until the prediction is finished!");
        uint256 _amount = handleFees();
        Token3Amount++;
        Token3Bets[Token3Amount]._amount = _amount;
        Token3Bets[Token3Amount]._up = up;
        Token3Bets[Token3Amount]._address = msg.sender;
        if(up){
            token3._allBets.upPool += _amount;
            token3._allBets.upBetAmount++;
        } else{
            token3._allBets.downPool += _amount;
            token3._allBets.downBetAmount++;
        }
    } 
}

function GetBets(uint i) internal view returns(uint256, uint256, uint256, uint256){
    uint256 upBets;
    uint256 upAmount;
    uint256 downBets;
    uint256 downAmount;
    if(i == 1){
        upBets = token1._allBets.upBetAmount;
        upAmount = token1._allBets.upPool;
        downBets = token1._allBets.downBetAmount;
        downAmount = token1._allBets.downPool;
    
    } else if(i == 2){
        upBets = token2._allBets.upBetAmount;
        upAmount = token2._allBets.upPool;
        downBets = token2._allBets.downBetAmount;
        downAmount = token2._allBets.downPool;
    } else if(i == 3){
        upBets = token3._allBets.upBetAmount;
        upAmount = token3._allBets.upPool;
        downBets = token3._allBets.downBetAmount;
        downAmount = token3._allBets.downPool;
    }
    
    return(upBets, upAmount, downBets, downAmount);
}


function getTokenTime(uint i) public view returns(uint256){
    if(i == 1){
        if(token1._isLocked){
            return token1._lockedEnd;
        } else{
            return token1._countdownEnd;
        }
    } else if(i == 2){
                if(token2._isLocked){
            return token2._lockedEnd;
        } else{
            return token2._countdownEnd;
        }
    } else if(i == 3){
                if(token3._isLocked){
            return token3._lockedEnd;
        } else{
            return token3._countdownEnd;
        }
    }
} 

function isBetting(uint i) public view returns(bool){
    if(i == 1) {
        for(uint i = 0; Token1Amount > i; i++){
        
            if(Token1Bets[i + 1]._address == msg.sender){
                return true;
            }
        }
    } else if(i == 2){
        for(uint i = 0; Token1Amount > i; i++){
        
            if(Token1Bets[i + 1]._address == msg.sender){
                return true;
            }
        }
    } else if(i == 3){
        for(uint i = 0; Token3Amount > i; i++){
        
            if(Token3Bets[i + 1]._address == msg.sender){
                return true;
            }
        }
    }
    return false;
    
}

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
    } else if(_i == 2){
        // If the prediction is locked, meaning that you can't enter any BNB, the started var will be 1
        if(token2._isLocked){
            started = 1;
        }
        
        // For each bet
        for(uint i = 0; Token2Amount > i; i++){
            
            // If it's your bet, it will add it to the yourBet var
            if(Token2Bets[i + 1]._address == msg.sender){
                yourBet = Token2Bets[i + 1]._amount;
                // Side, 1 means UP and 0 means DOWN
                if(Token2Bets[i + 1]._up){
                    side = 1;
                } else{
                    side = 0;
                }
                break;
            }
        }
        return(started, token2._allBets.upBetAmount, token2._allBets.upPool, token2._allBets.downBetAmount, token2._allBets.downPool, token2._allBets.upPool + token2._allBets.downPool, yourBet, side, token2._tokenName, token2._symbol);
    } else if(_i == 3){
        // If the prediction is locked, meaning that you can't enter any BNB, the started var will be 1
        if(token3._isLocked){
            started = 1;
        }
        
        // For each bet
        for(uint i = 0; Token3Amount > i; i++){
            
            // If it's your bet, it will add it to the yourBet var
            if(Token3Bets[i + 1]._address == msg.sender){
                yourBet = Token3Bets[i + 1]._amount;
                // Side, 1 means UP and 0 means DOWN
                if(Token3Bets[i + 1]._up){
                    side = 1;
                } else{
                    side = 0;
                }
                break;
            }
        }
        return(started, token3._allBets.upBetAmount, token3._allBets.upPool, token3._allBets.downBetAmount, token3._allBets.downPool, token3._allBets.upPool + token3._allBets.downPool, yourBet, side, token3._tokenName, token3._symbol);
    }
    else return(0, 0, 0, 0, 0, 0, 0, 0, "", "");
}

}