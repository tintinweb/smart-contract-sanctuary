//SourceUnit: Bank.prod.sol

/***** Submitted for verification at Tronscan.org on 2021-01-16
*
*     _____     ______     __         __         ______     ______     ______     ______     __         ______     __   __     ______     ______    
*    /\  __-.  /\  __ \   /\ \       /\ \       /\  __ \   /\  == \   /\  == \   /\  __ \   /\ \       /\  __ \   /\ "-.\ \   /\  ___\   /\  ___\   
*    \ \ \/\ \ \ \ \/\ \  \ \ \____  \ \ \____  \ \  __ \  \ \  __<   \ \  __<   \ \  __ \  \ \ \____  \ \  __ \  \ \ \-.  \  \ \ \____  \ \  __\   
*     \ \____-  \ \_____\  \ \_____\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \_\\"\_\  \ \_____\  \ \_____\ 
*      \/____/   \/_____/   \/_____/   \/_____/   \/_/\/_/   \/_/ /_/   \/_____/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/ \/_/   \/_____/   \/_____/ 
*
*
*    https://DollarBalance.cash
*
*    file: ./DollarBalanceBank.sol
*    time:  2021-01-05
*
*    Copyright (c) 2021 DollarBalance.cash 
*/    

pragma solidity ^0.5.8;

interface IERC20  {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract Context {
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Operator is Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender,'operator: caller is not the operator');
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator) public onlyOwner {
        _transferOperator(newOperator);
    }

    function _transferOperator(address newOperator) internal {
        require(newOperator != address(0),'operator: zero address given for new operator');
        emit OperatorTransferred(address(0), newOperator);
        _operator = newOperator;
    }
}
contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(
            !checkSameOriginReentranted(),
            'ContractGuard: one block, one function'
        );
        require(
            !checkSameSenderReentranted(),
            'ContractGuard: one block, one function'
        );

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

interface IEpoch{
    function getCurEpoch() external view returns (uint256);
    function getCurPeriodTime() external view returns (uint256);
    function nextEpochTime() external view returns (uint256);
}

contract DollarBalanceBank is ContractGuard,Operator{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IEpoch epoch;
    IERC20 cash;

    struct User{
        uint256 id;
        address addr;
        uint256 ref;
        uint256 refSum;
        uint256 bonus;
        uint256 epoch; 
    }

    struct UserStakeInfo {
        uint256 amount;
        uint256 time;
        uint256 userRewardPerTokenPaid;
        uint256 rewards;
    }


    struct Bank {
        IERC20 lp;  //lp token
        uint256 decimals;
        uint256 reward;
        uint256 weight;
        uint256 startTime;
        uint256 secReward;
        uint256 periodFinish;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 totalSupply;
        uint256 currentPeriod;
    }

    uint256 public userIndex;
    uint256 public bankIndex;

    bool public initialized = false;
    uint256 public refRewardRate;
    uint256 public refRewardEpochMax;
    mapping(uint256=>User) public indexToUser;
    mapping(address=>uint256) public addrToUserId;
    mapping(uint256 => mapping(address => UserStakeInfo)) public bidToUserStakeInfo;
    mapping(uint256 => uint256) public bidToTotalRewards;
    mapping(uint256 => Bank) public indexToBank;
    constructor () public {
        refRewardRate=500;
        refRewardEpochMax=10;
    }
    function init(address _cash,address _epoch,address _operator) public onlyOneBlock onlyOwner{
        require(!initialized,'Already initialized');
        initialized=true;
        cash =IERC20(_cash); 
        epoch=IEpoch(_epoch);
        transferOperator(_operator);
    }
    event BankRewardAdded(uint256 indexed bid, uint256 reward);
    event UserAdded(uint256 indexed uid, address user);

    event Staked(address indexed user, uint256 indexed bid, uint256 indexed tid);
    event Withdrawn(address indexed user, uint256 indexed bid, uint256 amount);
    event BankRewardPaid(address indexed user, uint256 indexed bid, uint256 reward);
    event UserBonusPaid(address indexed user, uint256 bonus);
    event RefRewardRateChanged(address indexed operator,uint256 pre,uint256 rate);
    event BankWeightChanged(address indexed operator,uint256 pre,uint256 weight);
    event RefRewardEpochMaxChanged(address indexed operator,uint256 pre,uint256 max);
   
  
    function addBank(address _token,uint256 _decimals,uint256 _weight, uint256 _startTime,uint256 _reward) external onlyOneBlock onlyOwner{
        require(_token.isContract(), "Error: LP token error!");
        
        bankIndex++;
        uint256 startTime = block.timestamp > _startTime ? block.timestamp : _startTime;
        uint256 periodFinish = epoch.nextEpochTime();
        uint256 secReward=0;
        if(_reward>0){
            secReward=_reward.div(epoch.getCurPeriodTime());
            bidToTotalRewards[bankIndex] = _reward;
            emit BankRewardAdded(bankIndex, _reward);
        }
        indexToBank[bankIndex] = Bank({
            lp: IERC20(_token),
            decimals:_decimals,
            weight:_weight,
            reward : _reward,
            startTime : startTime,
            periodFinish : periodFinish,
            secReward : secReward,
            lastUpdateTime : startTime,
            rewardPerTokenStored : 0,
            totalSupply : 0,
            currentPeriod : 0
        });
    }

    function register(uint256 _refId) public checkUser(msg.sender,_refId) {}    

    function setRefRewardRate(uint256 _rate) external onlyOwner{
        uint256 pre=refRewardRate;
        refRewardRate=_rate;
        emit RefRewardRateChanged(msg.sender,pre,refRewardRate);
    }
    function setRefRewardEpochMax(uint256 _max) external onlyOwner{
        uint256 pre=refRewardEpochMax;
        refRewardEpochMax=_max;
        emit RefRewardEpochMaxChanged(msg.sender,pre,refRewardEpochMax);
    }
    function setBankWeight(uint256 _bid,uint256 _weight) external onlyOwner{
        require(bankIndex>=_bid,'the bank not exist');
        Bank storage bank=indexToBank[_bid];
        uint256 pre=bank.weight;
        bank.weight=_weight;
        emit BankWeightChanged(msg.sender,pre,bank.weight);
    }
   
    function lastTimeRewardApplicable(uint256 _ptime) public view returns (uint256) {
        return Math.min(block.timestamp, _ptime);
    }

    function rewardPerToken(uint256 _bid) public view returns (uint256) {
        Bank memory bank = indexToBank[_bid];
        if (bank.totalSupply == 0) {
            return bank.rewardPerTokenStored;
        }
        return bank.rewardPerTokenStored.add(
            lastTimeRewardApplicable(bank.periodFinish)
            .sub(bank.lastUpdateTime)
            .mul(bank.secReward)
            .mul(10 ** bank.decimals)
            .div(bank.totalSupply)
        );
    }
  

    function earned(uint256 _bid, address _account) view public  returns (uint256) {
        Bank memory bank = indexToBank[_bid];
        UserStakeInfo memory stake = bidToUserStakeInfo[_bid][_account];
       
        uint256 calculatedEarned = stake.amount
        .mul(rewardPerToken(_bid).sub(stake.userRewardPerTokenPaid))
        .div(10 ** bank.decimals)
        .add(stake.rewards);
        return calculatedEarned;
    }


    function _formatRewards(address _account,uint256 _reward) internal returns(uint256){
        uint256 refReward=0;
        User memory user=indexToUser[addrToUserId[_account]];
        if(user.ref>0){
            uint256 curEpoch=epoch.getCurEpoch();
            if(curEpoch-user.epoch<=refRewardEpochMax){
                refReward=_reward.mul(refRewardRate).div(1e4);
                if(refReward>0){
                    User storage refUser=indexToUser[user.ref];
                    refUser.bonus=refUser.bonus.add(refReward);
                }
            }
        }
     
        return _reward.sub(refReward);
    }

    
    
    function stake(uint256 _bid,uint256 _amount,uint256 _refId) public onlyOneBlock checkUser(msg.sender, _refId) checkBank(_bid) {
        _updateReward(_bid, msg.sender);
        require(_amount>0,"Cannot stake 0");
        Bank storage bank = indexToBank[_bid];
        bank.lp.safeTransferFrom(msg.sender, address(this), _amount);
        UserStakeInfo storage stake = bidToUserStakeInfo[_bid][msg.sender];
        bank.totalSupply = bank.totalSupply.add(_amount);
        stake.amount = stake.amount.add(_amount);
        stake.time=now;
        emit Staked(msg.sender, _bid, _amount);
    }

    function withdraw(uint256 _bid,uint256 _refId)  public onlyOneBlock checkUser(msg.sender, _refId)  {
        _updateReward(_bid, msg.sender);
        UserStakeInfo storage stake = bidToUserStakeInfo[_bid][msg.sender];
        uint256 amount=stake.amount;
        require(amount>0,'Cannot withdraw 0');
        stake.amount =0;
        Bank storage bank = indexToBank[_bid];
        bank.totalSupply = bank.totalSupply.sub(amount);
        bank.lp.safeTransfer(msg.sender,amount);
        emit Withdrawn(msg.sender, _bid, amount);
    }
    function withdrawBonus(uint256 _refId) public onlyOneBlock checkUser(msg.sender,_refId) {
        User storage user=indexToUser[addrToUserId[msg.sender]];
        require(user.bonus>0,"Not referral Bonus");
        uint256 bon=user.bonus;
        user.bonus=0;
        cash.safeTransferFrom(operator(),msg.sender, bon);
        emit UserBonusPaid(msg.sender, bon);
    }
    function exit(uint256 _bid,uint256 _refId) external{
        settle(_bid,_refId);
        withdraw(_bid,_refId);
    }


    function settle(uint256 _bid,uint256 _refId) public checkUser(msg.sender,_refId) checkBank(_bid) {
        uint256 reward=_updateReward(_bid, msg.sender);
        if(reward>0){
            reward=_formatRewards(msg.sender,reward);
            UserStakeInfo storage stake=bidToUserStakeInfo[_bid][msg.sender];
            stake.rewards = 0;
            cash.safeTransferFrom(operator(),msg.sender, reward);
            emit BankRewardPaid(msg.sender, _bid, reward);
        }

    }
   
    
     function _updateReward(uint256 _bid, address _account) internal returns(uint256){
        Bank storage bank = indexToBank[_bid];
        uint256 rewardPerTokenStored = rewardPerToken(_bid);
        bank.rewardPerTokenStored = rewardPerTokenStored;
        bank.lastUpdateTime = lastTimeRewardApplicable(bank.periodFinish);
        if (_account != address(0)) {
            UserStakeInfo storage stake=bidToUserStakeInfo[_bid][_account];
            stake.rewards = earned(_bid, _account);
            stake.userRewardPerTokenPaid = rewardPerTokenStored;
            return stake.rewards;
        }
        return 0;
    }
    function _getTotalBankWeight() internal returns (uint256){
        uint256 total=0;
        for (uint256 i = 1; i <= bankIndex; i++) {
            total=total.add(indexToBank[i].weight);
        }
        return total;
    }
    function allocateSeigniorage(uint256 _amount) external onlyOperator {
        require(bankIndex>0,'No bank is open yet');
        uint256 totalWeight=_getTotalBankWeight();
        for (uint256 i = 1; i <= bankIndex; i++) {
            Bank storage bank= indexToBank[i];
            bank.rewardPerTokenStored=rewardPerToken(i); 
            bank.currentPeriod++;
            bool hasReward=_amount>0&&bank.weight>0;
            bank.reward =hasReward?bank.weight.mul(_amount).div(totalWeight):0;
            bank.lastUpdateTime = now;
            bank.secReward = hasReward?bank.reward.div(epoch.getCurPeriodTime()):0;
            bank.periodFinish = epoch.nextEpochTime();
            if(hasReward){
                bidToTotalRewards[i]=bidToTotalRewards[i].add(bank.reward);
                emit BankRewardAdded(i, bank.reward);
            }
        }
    }

     modifier checkUser(address _account,uint256 _refId){
        uint256 uid=addrToUserId[_account];
        if(uid==0){
            uint256 refId=0;
            User storage ref=indexToUser[_refId];
            if(ref.id>0){
                refId=ref.id;
                ref.refSum++;
            }
            userIndex++;
            indexToUser[userIndex]=User(userIndex,_account,refId,0,0,epoch.getCurEpoch());
            addrToUserId[_account]=userIndex;
            emit UserAdded(userIndex,_account);
        }
        _;
        
    }

    modifier checkBank(uint256 _bid){
        require(_bid>0&&bankIndex >= _bid, "the bank not exist");
        require(indexToBank[_bid].startTime>0, "the bank has not started yet");
        _;
    }
    
}

// ******** library *********/

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: TRC20 operation did not succeed");
        }
    }
}

//math

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// safeMath

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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