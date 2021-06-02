/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;



interface SwissToken {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract BettingExchange{

    using SafeMath for uint256;
    
    // Token instance
    SwissToken public token;

    // global variables
    
    //Admin address
    address public ownerAddress;
    //ID for game
   // uint256 public _gameId;
    //assigning current Id
    uint public currentid = 1;
    //Betting factor could be 20%, 50% and 100%
    uint256[] category = [20e18, 50e18, 100e18];
    //assigning intervalTime for betting
    uint256 public intervalTime = 900;
    //assigning gameDuration for game
    uint256 public gameDuration = 3600;
    //buyback for reducting 0.3% from betting amount
    address public buyBack;
    //Contract status
    bool public lockStatus;
    uint public pairId;

    //Investor details
    struct userDetails {
        uint256 userId;
        uint _userAmt;
        uint deposit_time;
        uint betEarned;
        mapping(uint256 => bool)userStatus;
    }
    //game details
    struct gameDetails {
        uint256 startTime;
        uint256 endTime;
        bool status;
    }
    //bet details
    struct betDetails {
        uint256 gameid;
        uint256 userCategory;
        mapping(uint =>mapping(uint => uint))betAmount;
    }

    mapping(address => userDetails)public users;
    mapping(uint256 => address)public userList;
    mapping(uint256 => mapping(uint256 => gameDetails)) public game;
    mapping(uint256 => betDetails)public betting;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))public betstatus;
    mapping(uint256 => mapping(uint256 => mapping(bool => uint)))public lossAmt;
    mapping(uint256 => mapping(uint256 => mapping(bool => uint256)))public statusCount;
    mapping(uint256 => mapping(uint256 => bool))public decision;
    mapping(uint256 => mapping(uint256 => bool))public gameStatus;
    mapping(uint => mapping(uint => address[]))public betUsers;
    mapping(uint => uint)public gameId;
    mapping(address => mapping(uint => uint))public userEarned;
    
    //Withdraw event
    event UserWithdraw(address indexed from,uint amount,uint time);
    //Deposit event
    event UserDeposit(address indexed from,uint amount,uint time);
    //Bet event
    event PlaceBet(address indexed from,uint amount,uint time,uint pairid,uint gameid);
    event Decision(address indexed from,uint gameid,bool status,uint time);
    event AdminWithdraw(address indexed from,address indexed to,uint amount,uint time);
    event AddGame(uint gameid,uint pairid,uint starttime,uint endtime);

    /**
    * dev Initializes the contract setting the owners, token, buyback, userId for admin to start up game and game current time.
    */
    constructor(address _token, address _buyback) public {
        ownerAddress = msg.sender;
        buyBack = _buyback;
        token = SwissToken(_token);
        users[ownerAddress].userId = 1;
        userList[1] = ownerAddress;
    }

    /**
    * dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    }

    /**
    * dev Throws if lockStatus is true
    */
    modifier isLock() {
        require(lockStatus == false, "Betting: Contract Locked");
        _;
    }

    /**
    * dev Throws if called by other contract
    */
    modifier isContractCheck(address _user) {
        require(!isContract(_user), "Betting: Invalid address");
        _;
    }

    /**
     *  dev addGame: once contract get deployed betting time starts
     */
    function addGame(uint _pairid,uint256 _startTime) internal returns(bool) {
        //_gameId++;
        gameId[_pairid]++;
        require(gameStatus[_pairid][gameId[_pairid]] == false);
        game[_pairid][gameId[_pairid]].startTime = _startTime.add(intervalTime);
        game[_pairid][gameId[_pairid]].endTime = game[_pairid][gameId[_pairid]].startTime.add(gameDuration);
        emit AddGame(_pairid,gameId[_pairid],game[_pairid][gameId[_pairid]].startTime,
        game[_pairid][gameId[_pairid]].endTime);
        return true;
        
    }
    
    // Owner can add game
    function setGame(uint _pairId)public onlyOwner{
        addGame(_pairId,block.timestamp);
    }

    /**
     *  dev placeBet: users can placeBet by giving gameId, _userId, decision of bet _bool, _category.
     *  number of next gameid will be created when each users place bet in current game.
     *  user should give userid, gameId, decision for game & category to placeBet within a betting period get ends.
     *  when user bet, then users deposit amount will be taken for betting according to user category.
     *  once user placed bet, 0.5% and 0.3% commission will be taken from every users betAmount
     */
    function placeBet(uint _pairId,uint256 _gameId, uint256 _userId, bool _bool, uint256 _category) public isLock returns(bool) {
        require(game[_pairId][_gameId].status == false, "Game expired");
        require(block.timestamp <= game[_pairId][_gameId].startTime, "Game started");
        require(gameId[_pairId] >= _gameId, "Game ID is invalid");
        require(betting[_userId].betAmount[_pairId][_gameId] == 0, "Already bet in this game");
        require(users[userList[_userId]]._userAmt > 0, "Deposit first");
        gameStatus[_pairId][_gameId] = true;
        betting[_userId].gameid = _gameId;
        betting[_userId].userCategory = _category;
        betting[_userId].betAmount[_pairId][_gameId] = users[userList[_userId]]._userAmt.mul(category[_category]).div(100e18);
        uint commission = betting[_userId].betAmount[_pairId][_gameId];
        betting[_userId].betAmount[_pairId][_gameId] = betting[_userId].betAmount[_pairId][_gameId].sub(commission.mul(0.8e18).div(100e18));
        require(token.transfer(address(this), commission.mul(0.5e18).div(100e18)), "commission not send");
        require(token.transfer(buyBack, commission.mul(0.3e18).div(100e18)), "buyback not send");
        if (_category == 0 || _category == 1) {
            users[userList[_userId]]._userAmt = users[userList[_userId]]._userAmt.sub(commission);
        }
        else if (_category == 2) {
            users[userList[_userId]]._userAmt = 0;
        }
        betstatus[_pairId][_userId][_gameId] = _bool;
        statusCount[_pairId][_gameId][_bool] = statusCount[_pairId][_gameId][_bool].add(1);
        lossAmt[_pairId][_gameId][_bool] = lossAmt[_pairId][_gameId][_bool].add(betting[_userId].betAmount[_pairId][_gameId]);
        betUsers[_pairId][_gameId].push(userList[_userId]);
        addGame(_pairId,game[_pairId][gameId[_pairId]].endTime);
        emit PlaceBet(msg.sender,betting[_userId].betAmount[_pairId][_gameId],block.timestamp,_pairId,_gameId);
        return true;
    }

     /*
     *dev gameDecision: Only admin will make a decison for game, once game time starts.
     *params _gameid: to set game decision by giving _gameid
     *params _bool: to set game decision by giving decision of wager
     *Once game decision had beed made, winners share will be decided proportionally 
     */
    function gameDecision(uint _pairid,uint _gameid, bool _bool) public onlyOwner {
        require(block.timestamp >= game[_pairid][_gameid].endTime, "Game not finished");
        require(game[_pairid][_gameid].status == false, "Game expired");
        uint winAmount;
        uint calculation;
        uint amount;
        decision[_pairid][_gameid] = _bool;
        game[_pairid][_gameid].status = true;
        for(uint i = 0; i<betUsers[_pairid][_gameid].length; i++){
            if(betstatus[_pairid][users[betUsers[_pairid][_gameid][i]].userId][_gameid] == decision[_pairid][_gameid]){
                 if (statusCount[_pairid][_gameid][((decision[_pairid][_gameid] == true) ? false : true)] > 0) {
                        winAmount = lossAmt[_pairid][_gameid][decision[_pairid][_gameid]];
                        uint totalLossAmount = lossAmt[_pairid][_gameid][((decision[_pairid][_gameid] == true) ? false : true)];
                        calculation = (totalLossAmount.mul(1e18)).div(winAmount);
                        amount = (betting[users[betUsers[_pairid][_gameid][i]].userId].betAmount[_pairid][_gameid].mul(calculation));
                        amount = amount.div(1e18);
                        betting[users[betUsers[_pairid][_gameid][i]].userId].betAmount[_pairid][_gameid] = betting[users[betUsers[_pairid][_gameid][i]].userId].betAmount[_pairid][_gameid].add(amount);
                        users[betUsers[_pairid][_gameid][i]].betEarned = users[betUsers[_pairid][_gameid][i]].betEarned.add(betting[users[betUsers[_pairid][_gameid][i]].userId].betAmount[_pairid][_gameid]);
                        userEarned[betUsers[_pairid][_gameid][i]][_gameid] = userEarned[betUsers[_pairid][_gameid][i]][_gameid].add(users[betUsers[_pairid][_gameid][i]].betEarned);
                        betting[users[betUsers[_pairid][_gameid][i]].userId].betAmount[_pairid][_gameid] = 0;
                 }
                 else{
                      users[betUsers[_pairid][_gameid][i]].betEarned =  users[betUsers[_pairid][_gameid][i]].betEarned.add( betting[users[betUsers[_pairid][_gameid][i]].userId].betAmount[_pairid][_gameid]);
                      userEarned[betUsers[_pairid][_gameid][i]][_gameid] = userEarned[betUsers[_pairid][_gameid][i]][_gameid].add(users[betUsers[_pairid][_gameid][i]].betEarned);
                      betting[users[betUsers[_pairid][_gameid][i]].userId].betAmount[_pairid][_gameid] = 0;
                 }
            }
            else if(betstatus[_pairid][users[betUsers[_pairid][_gameid][i]].userId][_gameid] != decision[_pairid][_gameid]){
                if (statusCount[_pairid][_gameid][decision[_pairid][_gameid]]  == 0){
                     users[betUsers[_pairid][_gameid][i]].betEarned = users[betUsers[_pairid][_gameid][i]].betEarned.add(betting[users[betUsers[_pairid][_gameid][i]].userId].betAmount[_pairid][_gameid]);
                     userEarned[betUsers[_pairid][_gameid][i]][_gameid] = userEarned[betUsers[_pairid][_gameid][i]][_gameid].add(users[betUsers[_pairid][_gameid][i]].betEarned);
                }
            }
        }
    }

    /*
     * dev deposit: User deposit with 1 seek token
     * param dep_amount: user deposit amount
     */
    function deposit(uint dep_amount) public isLock {
        require(dep_amount > 0,"No amount given");
        require(token.transferFrom(msg.sender, address(this), dep_amount));
         
        users[msg.sender]._userAmt = users[msg.sender]._userAmt.add(dep_amount);
        users[msg.sender].deposit_time = block.timestamp;
        if (users[msg.sender].userId == 0) {
        currentid++;
        users[msg.sender].userId = currentid;
        userList[users[msg.sender].userId] = msg.sender;
        
        }
        
        emit UserDeposit(msg.sender,dep_amount,block.timestamp);
    }

    /*
    *dev withdraw: users can withdraw their winning or lossing amount accordingly to wager
    *param userid_withdraw: user need to give their userid to withdraw their total earning in this wager
    *When all user win or loss the wager, then the bet amount from the user except (0.8%) commission amount will be given to user itself
    */
    function withdraw(uint256 userid_withdraw) public isLock returns(bool) {
        require(msg.sender != ownerAddress,"Only user can withdraw");
        require(users[msg.sender].userId == userid_withdraw,"Incorrect user id");
        uint amount;
        if(users[userList[userid_withdraw]].betEarned > 0){
            amount = users[userList[userid_withdraw]].betEarned;
            users[userList[userid_withdraw]].betEarned = 0;
            
        }
        amount = amount.add(users[userList[userid_withdraw]]._userAmt);
        users[userList[userid_withdraw]]._userAmt = 0;
        require(token.transfer(msg.sender, amount), "transaction failed");
        emit UserWithdraw(msg.sender,amount,block.timestamp);
        return true;
    }
    
    /**
     * dev viewStatus: Returns users referrals count, totalDeposit, totalStructure
     */
    function viewStatus(uint _pairid,uint gameid)public view returns(bool){
        require(game[_pairid][gameid].status == true, "Decision not yet set");
        if (decision[_pairid][gameid] == betstatus[_pairid][users[msg.sender].userId][gameid]){
            return true;
        }
        else{
            return false;
        }
    }
    
    /**
    * dev viewDetails: Returns gameid,userCategory,betAmount,userStatus
    */
    function viewDetails(uint _pairid, uint id,uint gameid)public view returns(uint,uint,uint,bool){
        return (betting[id].gameid,
                betting[id].userCategory,
                betting[id].betAmount[_pairid][gameid],
                users[userList[id]].userStatus[gameid]);
    }

    /**
     * dev adminWithdraw: owner invokes the function
     * owner can get referbonus, match bonus 
     */
    function adminWithdraw(uint _amount, address _to) public onlyOwner {
        token.transfer(_to, _amount);
    }

    /**
     * dev addToken: only admin can addToken if, contract balance get zero value when it comes for bet share to winners
     */
    function addToken(uint amount) public onlyOwner {
        require(token.transferFrom(ownerAddress, address(this), amount));
    }

    /**
     * dev setDuration: only Admin can set intervalTime & gameDuration for game and bet duration
     * param intervalTime 
     * param gameDuration
     */
    function setDuration(uint _intervaltime, uint _gameduration) public onlyOwner {
        intervalTime = _intervaltime;
        gameDuration = _gameduration;
    }

    /**
     * dev contractBalance: Returns total balance in contract
     */
    function contractBalance() public onlyOwner view returns(uint) {
        return token.balanceOf(address(this));
    }

    /**
     * dev Contract balance withdraw
     * param _toUser  receiver addrress
     * param _amount  withdraw amount
     */ 
    function failSafe(address _toUser, uint _amount) external onlyOwner returns(bool) {
        require(_toUser != address(0), "Invalid Address");
        require(token.balanceOf(address(this)) >= _amount, "Witty: insufficient amount");
        token.transfer(_toUser, _amount);
        return true;
    }

    /**
     * dev To lock/unlock the contract
     * param _lockStatus  status in bool
     */
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

    /**
     * dev isContract: Returns true if account is a contract
     */
    function isContract(address _account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(_account)
        }
        if (size != 0)
            return true;
        return false;
    }
}