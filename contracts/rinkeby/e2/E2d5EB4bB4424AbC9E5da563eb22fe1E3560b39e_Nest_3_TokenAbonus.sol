/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// File: Lib/AddressPayable.sol

pragma solidity 0.6.0;

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}
// File: Lib/SafeMath.sol

pragma solidity 0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: NestAbonus/Nest_3_TokenAbonus.sol

pragma solidity 0.6.0;



/**
 * @title Dividend logic
 * @dev Some operations about dividend,logic and asset separation
 */
contract Nest_3_TokenAbonus {
    using address_make_payable for address;
    using SafeMath for uint256;
    
    ERC20 _nestContract;
    Nest_3_TokenSave _tokenSave;                                                                //  Lock-up contract
    Nest_3_Abonus _abonusContract;                                                              //  ETH bonus pool
    Nest_3_VoteFactory _voteFactory;                                                            //  Voting contract
    Nest_3_Leveling _nestLeveling;                                                              //  Leveling contract
    address _destructionAddress;                                                                //  Destroy contract address
    
    uint256 _timeLimit = 168 hours;                                                             //  Bonus period
    uint256 _nextTime = 1596168000;                                                             //  Next bonus time
    uint256 _getAbonusTimeLimit = 60 hours;                                                     //  During of triggering calculation of bonus
    uint256 _times = 0;                                                                         //  Bonus ledger
    uint256 _expectedIncrement = 3;                                                             //  Expected bonus increment ratio
    uint256 _expectedSpanForNest = 100000000 ether;                                             //  NEST expected bonus increment threshold
    uint256 _expectedSpanForNToken = 1000000 ether;                                             //  NToken expected bonus increment threshold
    uint256 _expectedMinimum = 100 ether;                                                       //  Expected minimum bonus
    uint256 _savingLevelOne = 10;                                                               //  Saving threshold level 1
    uint256 _savingLevelTwo = 20;                                                               //  Saving threshold level 2 
    uint256 _savingLevelTwoSub = 100 ether;                                                     //  Function parameters of savings threshold level 2  
    uint256 _savingLevelThree = 30;                                                             //  Function parameters of savings threshold level 3
    uint256 _savingLevelThreeSub = 600 ether;                                                   //  Function parameters of savings threshold level 3
    
    mapping(address => uint256) _abonusMapping;                                                 //  Bonus pool snapshot - token address (NEST or NToken) => number of ETH in the bonus pool 
    mapping(address => uint256) _tokenAllValueMapping;                                          //  Number of tokens (circulation) - token address (NEST or NToken) ) => total circulation 
    mapping(address => mapping(uint256 => uint256)) _tokenAllValueHistory;                      //  NEST or NToken circulation snapshot - token address (NEST or NToken) => number of periods => total circulation 
    mapping(address => mapping(uint256 => mapping(address => uint256))) _tokenSelfHistory;      //  Personal lockup - NEST or NToken snapshot token address (NEST or NToken) => period => user address => total circulation
    mapping(address => mapping(uint256 => bool)) _snapshot;                                     //  Whether snapshot - token address (NEST or NToken) => number of periods => whether to take a snapshot
    mapping(uint256 => mapping(address => mapping(address => bool))) _getMapping;               //  Receiving records - period => token address (NEST or NToken) => user address => whether received
    
    //  Log token address, amount
    event GetTokenLog(address tokenAddress, uint256 tokenAmount);
    
   /**
    * @dev Initialization method
    * @param voteFactory Voting contract address
    */
    constructor (address voteFactory) public {
        // Nest_3_VoteFactory voteFactoryMap = Nest_3_VoteFactory(address(voteFactory));
        // _voteFactory = voteFactoryMap; 
        // _nestContract = ERC20(address(voteFactoryMap.checkAddress("nest")));
        // _tokenSave = Nest_3_TokenSave(address(voteFactoryMap.checkAddress("nest.v3.tokenSave")));
        // address payable addr = address(voteFactoryMap.checkAddress("nest.v3.abonus")).make_payable();
        // _abonusContract = Nest_3_Abonus(addr);
        // address payable levelingAddr = address(voteFactoryMap.checkAddress("nest.v3.leveling")).make_payable();
        // _nestLeveling = Nest_3_Leveling(levelingAddr);
        // _destructionAddress = address(voteFactoryMap.checkAddress("nest.v3.destruction"));
    }
    
    /**
    * @dev Modify voting contract
    * @param voteFactory Voting contract address
    */
    function changeMapping(address voteFactory) public onlyOwner {
        // Nest_3_VoteFactory voteFactoryMap = Nest_3_VoteFactory(address(voteFactory));
        // _voteFactory = voteFactoryMap; 
        // _nestContract = ERC20(address(voteFactoryMap.checkAddress("nest")));
        // _tokenSave = Nest_3_TokenSave(address(voteFactoryMap.checkAddress("nest.v3.tokenSave")));
        // address payable addr = address(voteFactoryMap.checkAddress("nest.v3.abonus")).make_payable();
        // _abonusContract = Nest_3_Abonus(addr);
        // address payable levelingAddr = address(voteFactoryMap.checkAddress("nest.v3.leveling")).make_payable();
        // _nestLeveling = Nest_3_Leveling(levelingAddr);
        // _destructionAddress = address(voteFactoryMap.checkAddress("nest.v3.destruction"));
    }
    
    function setSave(address add) public {
        _tokenSave = Nest_3_TokenSave(address(add));
    }
    
    /**
    * @dev Deposit 
    * @param amount Deposited amount
    * @param token Locked token address
    */
    function depositIn(uint256 amount, address token) public {
        // uint256 nowTime = now;
        // uint256 nextTime = _nextTime;
        // uint256 timeLimit = _timeLimit;
        // if (nowTime < nextTime) {
        //     //  Bonus triggered
        //     require(!(nowTime >= nextTime.sub(timeLimit) && nowTime <= nextTime.sub(timeLimit).add(_getAbonusTimeLimit)));
        // } else {
        //     //  Bonus not triggered
        //     uint256 times = (nowTime.sub(_nextTime)).div(_timeLimit);
        //     //  Calculate the time when bonus should be started
        //     uint256 startTime = _nextTime.add((times).mul(_timeLimit));  
        //     //  Calculate the time when bonus should be stopped
        //     uint256 endTime = startTime.add(_getAbonusTimeLimit);                                                                    
        //     require(!(nowTime >= startTime && nowTime <= endTime));
        // }
        _tokenSave.depositIn(amount, token, address(msg.sender));                 
    }
    
    /**
    * @dev Withdrawing
    * @param amount Withdrawing amount
    * @param token Token address
    */
    function takeOut(uint256 amount, address token) public {
        require(amount > 0, "Parameter needs to be greater than 0");                                                                
        require(amount <= _tokenSave.checkAmount(address(msg.sender), token), "Insufficient storage balance");
        // if (token == address(_nestContract)) {
        //     require(!_voteFactory.checkVoteNow(address(tx.origin)), "Voting");
        // }
        _tokenSave.takeOut(amount, token, address(msg.sender));                                                             
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
    
    /**
    * @dev Receiving
    * @param token Receiving token address
    */
    function getAbonus(address token) public {
        uint256 tokenAmount = _tokenSave.checkAmount(address(msg.sender), token);
        require(tokenAmount > 0, "Insufficient storage balance");
        reloadTime();
        reloadToken(token);                                                                                                      
        uint256 nowTime = now;
        require(nowTime >= _nextTime.sub(_timeLimit) && nowTime <= _nextTime.sub(_timeLimit).add(_getAbonusTimeLimit), "Not time to draw");
        require(!_getMapping[_times.sub(1)][token][address(msg.sender)], "Have received");                                     
        _tokenSelfHistory[token][_times.sub(1)][address(msg.sender)] = tokenAmount;                                         
        require(_tokenAllValueMapping[token] > 0, "Total flux error");
        uint256 selfNum = tokenAmount.mul(_abonusMapping[token]).div(_tokenAllValueMapping[token]);
        require(selfNum > 0, "No limit available");
        _getMapping[_times.sub(1)][token][address(msg.sender)] = true;
        _abonusContract.getETH(selfNum, token,address(msg.sender)); 
        emit GetTokenLog(token, selfNum);
    }
    
    /**
    * @dev Update bonus time and stage ledger
    */
    function reloadTime() private {
        uint256 nowTime = now;
        //  The current time must exceed the bonus time
        if (nowTime >= _nextTime) {                                                                                                 
            uint256 time = (nowTime.sub(_nextTime)).div(_timeLimit);
            uint256 startTime = _nextTime.add((time).mul(_timeLimit));                                                              
            uint256 endTime = startTime.add(_getAbonusTimeLimit);                                                                   
            if (nowTime >= startTime && nowTime <= endTime) {
                _nextTime = getNextTime();                                                                                      
                _times = _times.add(1);                                                                                       
            }
        }
    }
    
    /**
    * @dev Snapshot of the amount of tokens
    * @param token Receiving token address
    */
    function reloadToken(address token) private {
        if (!_snapshot[token][_times.sub(1)]) {
            levelingResult(token);                                                                                          
            _abonusMapping[token] = _abonusContract.getETHNum(token); 
            _tokenAllValueMapping[token] = allValue(token);
            _tokenAllValueHistory[token][_times.sub(1)] = allValue(token);
            _snapshot[token][_times.sub(1)] = true;
        }
    }
    
    /**
    * @dev Leveling settlement
    * @param token Receiving token address
    */
    function levelingResult(address token) private {
        uint256 steps;
        if (token == address(_nestContract)) {
            steps = allValue(token).div(_expectedSpanForNest);
        } else {
            steps = allValue(token).div(_expectedSpanForNToken);
        }
        uint256 minimumAbonus = _expectedMinimum;
        for (uint256 i = 0; i < steps; i++) {
            minimumAbonus = minimumAbonus.add(minimumAbonus.mul(_expectedIncrement).div(100));
        }
        uint256 thisAbonus = _abonusContract.getETHNum(token);
        if (thisAbonus > minimumAbonus) {
            uint256 levelAmount = 0;
            if (thisAbonus > 5000 ether) {
                levelAmount = thisAbonus.mul(_savingLevelThree).div(100).sub(_savingLevelThreeSub);
            } else if (thisAbonus > 1000 ether) {
                levelAmount = thisAbonus.mul(_savingLevelTwo).div(100).sub(_savingLevelTwoSub);
            } else {
                levelAmount = thisAbonus.mul(_savingLevelOne).div(100);
            }
            if (thisAbonus.sub(levelAmount) < minimumAbonus) {
                _abonusContract.getETH(thisAbonus.sub(minimumAbonus), token, address(this));
                _nestLeveling.switchToEth.value(thisAbonus.sub(minimumAbonus))(token);
            } else {
                _abonusContract.getETH(levelAmount, token, address(this));
                _nestLeveling.switchToEth.value(levelAmount)(token);
            }
        } else {
            uint256 ethValue = _nestLeveling.tranEth(minimumAbonus.sub(thisAbonus), token, address(this));
            _abonusContract.switchToEth.value(ethValue)(token);
        }
    }
    
     // Next bonus time, current bonus deadline, ETH number, NEST number, NEST participating in bonus, bonus to receive, approved amount, balance, whether bonus can be paid 
    function getInfo(address token) public view returns (uint256 nextTime, uint256 getAbonusTime, uint256 ethNum, uint256 tokenValue, uint256 myJoinToken, uint256 getEth, uint256 allowNum, uint256 leftNum, bool allowAbonus)  {
        uint256 nowTime = now;
        if (nowTime >= _nextTime.sub(_timeLimit) && nowTime <= _nextTime.sub(_timeLimit).add(_getAbonusTimeLimit) && _times > 0 && _snapshot[token][_times.sub(1)]) {
            //  Bonus have been triggered, and during the time of this bonus, display snapshot data 
            allowAbonus = _getMapping[_times.sub(1)][token][address(msg.sender)];
            ethNum = _abonusMapping[token];
            tokenValue = _tokenAllValueMapping[token];
        } else {
            //  Display real-time data 
            ethNum = _abonusContract.getETHNum(token);
            tokenValue = allValue(token);
            allowAbonus = _getMapping[_times][token][address(msg.sender)];
        }
        myJoinToken = _tokenSave.checkAmount(address(msg.sender), token);
        if (allowAbonus == true) {
            getEth = 0; 
        } else {
            getEth = myJoinToken.mul(ethNum).div(tokenValue);
        }
        nextTime = getNextTime();
        getAbonusTime = nextTime.sub(_timeLimit).add(_getAbonusTimeLimit);
        allowNum = ERC20(token).allowance(address(msg.sender), address(_tokenSave));
        leftNum = ERC20(token).balanceOf(address(msg.sender));
    }
    
    /**
    * @dev View next bonus time 
    * @return Next bonus time 
    */
    function getNextTime() public view returns (uint256) {
        uint256 nowTime = now;
        if (_nextTime > nowTime) { 
            return _nextTime; 
        } else {
            uint256 time = (nowTime.sub(_nextTime)).div(_timeLimit);
            return _nextTime.add(_timeLimit.mul(time.add(1)));
        }
    }
    
    /**
    * @dev View total circulation 
    * @return Total circulation
    */
    function allValue(address token) public view returns (uint256) {
        if (token == address(_nestContract)) {
            uint256 all = 10000000000 ether;
            uint256 leftNum = all.sub(_nestContract.balanceOf(address(_voteFactory.checkAddress("nest.v3.miningSave")))).sub(_nestContract.balanceOf(address(_destructionAddress)));
            return leftNum;
        } else {
            return ERC20(token).totalSupply();
        }
    }
    
    /**
    * @dev View bonus period
    * @return Bonus period
    */
    function checkTimeLimit() public view returns (uint256) {
        return _timeLimit;
    }
    
    /**
    * @dev View duration of triggering calculation of bonus
    * @return Bonus period
    */
    function checkGetAbonusTimeLimit() public view returns (uint256) {
        return _getAbonusTimeLimit;
    }
    
    /**
    * @dev View current lowest expected bonus
    * @return Current lowest expected bonus
    */
    function checkMinimumAbonus(address token) public view returns (uint256) {
        uint256 miningAmount;
        if (token == address(_nestContract)) {
            miningAmount = allValue(token).div(_expectedSpanForNest);
        } else {
            miningAmount = allValue(token).div(_expectedSpanForNToken);
        }
        uint256 minimumAbonus = _expectedMinimum;
        for (uint256 i = 0; i < miningAmount; i++) {
            minimumAbonus = minimumAbonus.add(minimumAbonus.mul(_expectedIncrement).div(100));
        }
        return minimumAbonus;
    }
    
    /**
    * @dev Check whether the bonus token is snapshoted
    * @param token Token address
    * @return Whether snapshoted
    */
    function checkSnapshot(address token) public view returns (bool) {
        return _snapshot[token][_times.sub(1)];
    }
    
    /**
    * @dev Check the expected bonus incremental ratio
    * @return Expected bonus increment ratio
    */
    function checkeExpectedIncrement() public view returns (uint256) {
        return _expectedIncrement;
    }
    
    /**
    * @dev View expected minimum bonus
    * @return Expected minimum bonus
    */
    function checkExpectedMinimum() public view returns (uint256) {
        return _expectedMinimum;
    }
    
    /**
    * @dev View savings threshold
    * @return Save threshold
    */
    function checkSavingLevelOne() public view returns (uint256) {
        return _savingLevelOne;
    }
    function checkSavingLevelTwo() public view returns (uint256) {
        return _savingLevelTwo;
    }
    function checkSavingLevelThree() public view returns (uint256) {
        return _savingLevelThree;
    }
    
    /**
    * @dev View NEST liquidity snapshot
    * @param token Locked token address
    * @param times Bonus snapshot period
    */
    function checkTokenAllValueHistory(address token, uint256 times) public view returns (uint256) {
        return _tokenAllValueHistory[token][times];
    }
    
    /**
    * @dev View personal lock-up NEST snapshot
    * @param times Bonus snapshot period
    * @param user User address
    * @return The number of personal locked NEST snapshots
    */
    function checkTokenSelfHistory(address token, uint256 times, address user) public view returns (uint256) {
        return _tokenSelfHistory[token][times][user];
    }
    
    // View the period number of bonus
    function checkTimes() public view returns (uint256) {
        return _times;
    }
    
    // NEST expected bonus increment threshold
    function checkExpectedSpanForNest() public view returns (uint256) {
        return _expectedSpanForNest;
    }
    
    // NToken expected bonus increment threshold
    function checkExpectedSpanForNToken() public view returns (uint256) {
        return _expectedSpanForNToken;
    }
    
    // View the function parameters of savings threshold level 3
    function checkSavingLevelTwoSub() public view returns (uint256) {
        return _savingLevelTwoSub;
    }
    
    // View the function parameters of savings threshold level 3
    function checkSavingLevelThreeSub() public view returns (uint256) {
        return _savingLevelThreeSub;
    }
    
    /**
    * @dev Update bonus period
    * @param hour Bonus period (hours)
    */
    function changeTimeLimit(uint256 hour) public onlyOwner {
        require(hour > 0, "Parameter needs to be greater than 0");
        _timeLimit = hour.mul(1 hours);
    }
    
    /**
    * @dev Update collection period
    * @param hour Collection period (hours)
    */
    function changeGetAbonusTimeLimit(uint256 hour) public onlyOwner {
        require(hour > 0, "Parameter needs to be greater than 0");
        _getAbonusTimeLimit = hour;
    }
    
    /**
    * @dev Update expected bonus increment ratio
    * @param num Expected bonus increment ratio
    */
    function changeExpectedIncrement(uint256 num) public onlyOwner {
        require(num > 0, "Parameter needs to be greater than 0");
        _expectedIncrement = num;
    }
    
    /**
    * @dev Update expected minimum bonus
    * @param num Expected minimum bonus
    */
    function changeExpectedMinimum(uint256 num) public onlyOwner {
        require(num > 0, "Parameter needs to be greater than 0");
        _expectedMinimum = num;
    }
    
    /**
    * @dev  Update saving threshold
    * @param threshold Saving threshold
    */
    function changeSavingLevelOne(uint256 threshold) public onlyOwner {
        _savingLevelOne = threshold;
    }
    function changeSavingLevelTwo(uint256 threshold) public onlyOwner {
        _savingLevelTwo = threshold;
    }
    function changeSavingLevelThree(uint256 threshold) public onlyOwner {
        _savingLevelThree = threshold;
    }
    
    /**
    * @dev Update the function parameters of savings threshold level 2
    */
    function changeSavingLevelTwoSub(uint256 num) public onlyOwner {
        _savingLevelTwoSub = num;
    }
    
    /**
    * @dev Update the function parameters of savings threshold level 3
    */
    function changeSavingLevelThreeSub(uint256 num) public onlyOwner {
        _savingLevelThreeSub = num;
    }
    
    /**
    * @dev Update NEST expected bonus incremental threshold
    * @param num Threshold
    */
    function changeExpectedSpanForNest(uint256 num) public onlyOwner {
        _expectedSpanForNest = num;
    }
    
    /**
    * @dev Update NToken expected bonus incremental threshold
    * @param num Threshold
    */
    function changeExpectedSpanForNToken(uint256 num) public onlyOwner {
        _expectedSpanForNToken = num;
    }
    
    receive() external payable {
        
    }
    
    // Administrator only
    modifier onlyOwner(){
        require(_voteFactory.checkOwners(address(msg.sender)), "No authority");
        _;
    }
}

// NEST and NToken lock-up contracts
interface Nest_3_TokenSave {
    function depositIn(uint256 num, address token, address target) external;
    function checkAmount(address sender, address token) external view returns(uint256);
    function takeOut(uint256 num, address token, address target) external;
}

// ETH bonus pool
interface Nest_3_Abonus {
    function getETH(uint256 num, address token, address target) external;
    function getETHNum(address token) external view returns (uint256);
    function switchToEth(address token) external payable;
}

// Leveling contract
interface Nest_3_Leveling {
    function tranEth(uint256 amount, address token, address target) external returns (uint256);
    function switchToEth(address token) external payable;
}

// Voting factory contract
interface Nest_3_VoteFactory {
    // Check if there is a vote currently participating
    function checkVoteNow(address user) external view returns(bool);
    // Check address
    function checkAddress(string calldata name) external view returns (address contractAddress);
    // Check whether the administrator
    function checkOwners(address man) external view returns (bool);
}

// ERC20 contract
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}