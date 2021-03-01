/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity ^ 0.6.10;


interface ERC20 {
function totalSupply() external view returns(uint256);
function balanceOf(address account) external view returns(uint256);
function transfer(address recipient, uint256 amount) external returns(bool);
function allowance(address owner, address spender) external view returns(uint256);
function approve(address spender, uint256 amount) external returns(bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract BettingExchange{

    using SafeMath for uint256;

     ERC20 public token;

    address public ownerAddress;
    uint256 public _gameId;
    uint public currentid = 1;
    uint256[] category = [20e18, 50e18, 100e18];
    uint256 public intervalTime = 900;
    uint256 public gameDuration = 3600;
    address public buyBack;
    bool public lockStatus;

    struct userDetails {
        uint256 userId;
        uint _userAmt;
        uint deposit_time;
        mapping(uint256 => bool)userStatus;
    }

    struct gameDetails {
        uint256 startTime;
        uint256 endTime;
        bool status;
    }

    struct betDetails {
        uint256 gameid;
        uint256 userCategory;
        bool userStatus;
        mapping(uint => uint)betAmount;
    }

    mapping(address => userDetails)public users;
    mapping(uint256 => address)public userList;
    mapping(uint256 => gameDetails) public game;
    mapping(uint256 => betDetails)public betting;
    mapping(uint256 => mapping(uint256 => bool))public betstatus;
    mapping(uint256 => mapping(bool => uint256))public statusCount;
    mapping(uint256 => bool)public decision;
    mapping(uint256 => mapping(bool => uint))public lossAmt;
    mapping(uint => bool)public gameStatus;
    mapping(uint => uint)public bonusAmount;

    constructor(address _token, address _buyback) public {
        ownerAddress = msg.sender;
        buyBack = _buyback;
        token = ERC20(_token);
        users[ownerAddress].userId = 1;
        addGame(block.timestamp);
    }

    modifier onlyOwner {
        require(msg.sender == ownerAddress, "Only Owner");
        _;
    }

    modifier isLock() {
        require(lockStatus == false, "Witty: Contract Locked");
        _;
    }

    modifier isContractCheck(address _user) {
        require(!isContract(_user), "Witty: Invalid address");
        _;
    }

    function addGame(uint256 _startTime) internal returns(bool) {
        _gameId++;
        require(gameStatus[_gameId] == false);
        game[_gameId].startTime = _startTime.add(intervalTime);
        game[_gameId].endTime = game[_gameId].startTime.add(gameDuration);
        return true;
    }

    function placeBet(uint256 gameId, uint256 _userId, bool _bool, uint256 _category) public isLock returns(bool) {
        require(game[gameId].status == false, "Game expired");
        require(block.timestamp <= game[gameId].startTime, "Game started");
        require(_gameId >= gameId, "Game ID is invalid");
        require(betting[_userId].betAmount[gameId] == 0, "Already bet in this game");
        require(users[userList[_userId]]._userAmt > 0, "Deposit first");
        gameStatus[_gameId] = true;
        betting[_userId].gameid = gameId;
        betting[_userId].userCategory = _category;
        betting[_userId].betAmount[gameId] = users[userList[_userId]]._userAmt.mul(category[_category]).div(100e18);
        uint commission = betting[_userId].betAmount[gameId];
        require(token.transfer(address(this), commission.mul(0.5e18).div(100e18)), "commission not send");
        require(token.transfer(buyBack, commission.mul(0.3e18).div(100e18)), "buyback not send");
        if (_category == 0 || _category == 1) {
            users[userList[_userId]]._userAmt = users[userList[_userId]]._userAmt.sub(betting[_userId].betAmount[gameId].add(commission.mul(0.8e18).div(100e18)));
        }
        else if (_category == 2) {
            users[userList[_userId]]._userAmt = users[userList[_userId]]._userAmt.sub(betting[_userId].betAmount[gameId]);
        }
        betstatus[_userId][gameId] = _bool;
        statusCount[gameId][_bool] = statusCount[gameId][_bool].add(1);
        lossAmt[gameId][_bool] = betting[_userId].betAmount[gameId];
        addGame(game[_gameId].endTime);
        return true;
    }

    function gameDecision(uint _gameid, bool _bool, uint256 amount) public onlyOwner {
        require(block.timestamp >= game[_gameid].endTime, "Game not finished");
        decision[_gameid] = _bool;
        game[_gameid].status = true;
        bonusAmount[_gameid] = bonusAmount[_gameid].add(amount);
    }

    function deposit(uint dep_amount) public isLock {
        currentid++;
        require(token.transferFrom(msg.sender, address(this), dep_amount));
        users[msg.sender]._userAmt = users[msg.sender]._userAmt.add(dep_amount);
        users[msg.sender].deposit_time = block.timestamp;
        users[msg.sender].userId = currentid;
        userList[currentid] = msg.sender;
    }

    function withdraw(uint256 userid_withdraw) public isLock returns(bool) {
        uint amount;
        uint i = 1;
        while (i <= betting[userid_withdraw].gameid) {
            if (users[msg.sender].userStatus[i] == false && block.timestamp >= game[i].endTime && game[i].status == true) {
                if (betstatus[userid_withdraw][i] == decision[i]) {
                    if (statusCount[i][((decision[i] == true) ? false : true)] > 0) {
                        uint _winingTotalAmount = lossAmt[i][((decision[i] == true) ? false : true)];
                        uint count = statusCount[i][decision[i]];
                        _winingTotalAmount = _winingTotalAmount.div(count);
                        amount = _winingTotalAmount.add(betting[userid_withdraw].betAmount[i]);
                    }
                    else {
                        amount = betting[userid_withdraw].betAmount[i].add(bonusAmount[i].div(statusCount[i][decision[i]]));
                        bonusAmount[i] = bonusAmount[i].sub(bonusAmount[i].div(statusCount[i][decision[i]]));
                        statusCount[i][decision[i]] = statusCount[i][decision[i]].sub(1);
                    }
                }

                users[msg.sender].userStatus[i] = true;
                betting[userid_withdraw].betAmount[i] = 0;
            }
            i = i + 1;
        }
        require(token.transfer(msg.sender, amount), "transaction failed");
    }

    function userWithdraw(uint _amount) public isLock {
        require(users[msg.sender]._userAmt > 0, "user has no funds");
        require(_amount <= users[msg.sender]._userAmt, "wrong amount given");
        users[msg.sender]._userAmt = users[msg.sender]._userAmt.sub(_amount);
        token.transfer(msg.sender, _amount);
    }

    function adminWithdraw(uint _amount, address _to) public onlyOwner {
        token.transfer(_to, _amount);
    }

    function addToken(uint amount) public onlyOwner {
        require(token.transferFrom(ownerAddress, address(this), amount));
    }

    function setDuration(uint _intervaltime, uint _gameduration) public onlyOwner {
        intervalTime = _intervaltime;
        gameDuration = _gameduration;
    }

    function contractBalance() public onlyOwner view returns(uint) {
        return token.balanceOf(address(this));
    }

    function failSafe(address _toUser, uint _amount, address _token) external onlyOwner returns(bool) {
        require(_toUser != address(0), "Invalid Address");
        require(token.balanceOf(address(this)) >= _amount, "Witty: insufficient amount");
        token.transfer(_toUser, _amount);
        return true;
    }

    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

    /**
     * @dev isContract: Returns true if account is a contract
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