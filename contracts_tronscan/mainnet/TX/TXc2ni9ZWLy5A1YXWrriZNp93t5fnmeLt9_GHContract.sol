//SourceUnit: GHContract.sol

pragma solidity ^0.5.10;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    //using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        //require(address(token).isContract(), "SafeERC20: call to non-contract");
        require(Address.isContract(address(token)), "SafeERC20: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Model {
  enum MODELTYPE {A,B,C}
  uint256[6] internal PLANS_PERCENTS = [500, 2000, 1000, 11000, 13000, 2000];
  uint256[6] internal PLANS_PERIODS = [5 days, 15 days, 3 days, 10 days, 20 days, 30 days];
  uint256[15] internal MODEL_A_REWARDS_PERCENTS =[100,50,60,20,20,20,20,20,20,20,30,30,30,30,30];
  uint256[15] internal MODEL_B_REWARDS_PERCENTS =[30,10,20,2,2,2,2,2,2,2,5,5,5,5,5];
  uint256[15] internal MODEL_C_REWARDS_PERCENTS =[30,10,20,2,2,2,2,2,2,2,5,5,5,5,5];
  uint256[15][6] internal MODEL_REWARDS_PERCENTS;
  
  uint256 public constant decimals = 1e18;
  uint256[7] internal MODEL_AB_DEPOSIT_LIMIT =[1000*decimals,5000*decimals,10000*decimals,50000*decimals,100000*decimals,500000*decimals,1000000*decimals];
  uint8[3] internal VIP_REWARD_PERCENTS = [0,5,10];
  constructor() public{
      MODEL_REWARDS_PERCENTS[0] = MODEL_A_REWARDS_PERCENTS;
      MODEL_REWARDS_PERCENTS[1] = MODEL_A_REWARDS_PERCENTS;
      MODEL_REWARDS_PERCENTS[2] = MODEL_A_REWARDS_PERCENTS;
      MODEL_REWARDS_PERCENTS[3] = MODEL_B_REWARDS_PERCENTS;
      MODEL_REWARDS_PERCENTS[4] = MODEL_B_REWARDS_PERCENTS;
	  MODEL_REWARDS_PERCENTS[5] = MODEL_C_REWARDS_PERCENTS;
  }
  //Query contract type(A 0,B 1,C 2)
  function modelBlong2(uint8 depositType) internal pure returns (MODELTYPE tys){
      require(depositType>=0&&depositType<6,"depositType error");
      if(depositType==0||depositType==1||depositType==2){
          return MODELTYPE.A;
      }else if(depositType==3||depositType==4){
          return MODELTYPE.B;
      }else{
          return MODELTYPE.C;
      }
    }
    
    function modelIsBlong2(uint8 depositType,MODELTYPE tys) internal pure returns (bool){
       return modelBlong2(depositType)==tys;
    }

}
contract GHContract is Model{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public GH;
    constructor(address _gh) public {
        a3Valve = A3Valve(0,false,CREATE_TIME);
        GH = IERC20(_gh);
    }
    struct Deposit {
        //contract NO
        uint256 id;
        //investment amount
        uint256 amount;
        //Contract Subdivision type0~5
        uint8 modelType;
        uint256 freezeTime;
        //Withdrawal amount
        uint256 withdrawn;
        //Total incentive amount pledged
        uint256 loanLimit;
        //Last withdrawal time
        uint256 lastWithdrawn;
        //After shots
        uint256 afterVoting;
    }
    
    struct Player{
        //Referral address
        address payable referrer;
        //Whether to activate the recommended link (need to invest more than 100 HG in Contract A)
        bool linkEnable;
        //Recommended awards
        uint256 referralReward;
        //Current pledge record
        Deposit[] deposits;
        //As the first recharge mark, activate after completion
        bool active;
        //recommended
        uint256 refsCount;
        //User VIP level
        uint8 vip;
        //A,B,C total investment
        uint256[3] accumulatives;
        //The last time the contract expires
        uint256 expirationTime;
        //Total team size
        uint256 teamCount;
        //Total number of HG deposits
        uint256 playerDepositAmount;
        //Total number of HG extracted
        uint256 playerWithdrawAmount;
        //Team performance
        uint256 teamPerformance;
        
        uint256 lastWithdrawTime;
    }
    
    uint256 totalDepositAmount;
    
    uint256 totalWithdrawAmount;
 
    struct A3Valve{
        //The previous day total capital pool
        uint256 previousTotalSupply;
        //Whether the A3 contract is activated
        bool opening;
        //The day before the funds count time
        uint256 previousRecordTime;
    }

    //Minimum recharge amount
    uint256 public constant MINIMAL_DEPOSIT = 1000*decimals; 
	//Maximum recharge amount
    uint256 public constant MAXIMAL_DEPOSIT = 1000000*decimals; 
	
    uint256 public constant DESTORY_LIMIT = 1000*decimals; 
    //Transaction record delimiter
    uint256 private constant ROWS_IN_DEPOSIT = 10;
    //Total number of transaction types
    uint8 private constant DEPOSITS_TYPES_COUNT = 6;
    //Transaction records show the total
    uint256 private constant POSSIBLE_DEPOSITS_ROWS_COUNT = 200; 
    //Vip1 shall accumulate the amount of recharge
    uint256 private constant VIP1 = 500000*decimals; 
    //The amount of viP2 recharge should be accumulated
    uint256 private constant VIP2 = 1000000*decimals; 
    //Number of players
    uint256 public playersCount;
    //Recharge counter
    uint256 public depositsCounter;
    //The restart time of the capital pool
    uint256 public clearStartTime;
    mapping(address => Player) public players;
    //A3 contract switch
    A3Valve public a3Valve;
    //Contract start time
    uint256 private constant CREATE_TIME = 1627776000;
    //Activity start time
    uint256 private constant START_TIME = 1627776000;
    uint256 private constant ONE_DAY = 1 days;
    //Withdrawal cooldown time
    uint256 private constant WITHDRAW_DURATION = 8 hours;
    //The total team bonus is 3.3
    uint8 private constant teamRewardLimit = 33;
    uint8 private constant ROWS = 10;   
    //Capital pool version
    uint256 public version;
	//The player version
    mapping(address => uint256) public versionMaps;
    //Reward to be extracted
    mapping(address => uint256) private referRewardMap;
    event NewDeposit(
        uint256 depositId,
        address account,
        address referrer,
        uint8 modelType,
        uint256 amount
    );
    event Withdraw(address account,  uint256 originalAmount, uint256 level_percent, uint256 amount);
    event TransferReferralReward(address player, uint256 amount);   
    event AllocateReferralReward(address ref, address player,uint256 _amount,uint256 percent, uint8 modelType,uint256 refReward);
    event TakeAwayDeposit(address account, uint8 depositType, uint256 amount);   
    
    function getA3Status() public view returns(bool){
        return a3Valve.opening;
    }

    function getDuration() public view returns (uint256 ){
        return now.sub(CREATE_TIME).div(ONE_DAY).add(1);
    }
    //Access to investment restrictions 0~6
    function _getPayType() internal view returns(uint256){
        uint256  _duration = now.sub(CREATE_TIME).div(ONE_DAY);
        
        if(_duration<3){
            _duration = 2;
        }
        if(_duration>6){
             _duration = 6;
        }
        return _duration;
    }
    
    function referRewardMaps(address player) external view returns(uint256){
        if(!checkUpdate(player)){
            return referRewardMap[player];
        }
    }
    //Check whether the limit is exceeded
    function _checkDepositLimit(uint256 _amount,uint8 payType) private view returns (bool){
        if(_getPayType()<payType){
            return false;
        }
        uint256 dictAmount = MODEL_AB_DEPOSIT_LIMIT[payType];
        
        if(dictAmount!=_amount){
            return false;
        }else{
            return true;
        }
    }
    //Check whether contract B exceeds the limit
    function _checkBOverLimit(uint8 modelType,uint256 _amount,address _player) private view returns (bool){
        if(modelIsBlong2(modelType,MODELTYPE.B)){
            if(_getTypeTotal(msg.sender,MODELTYPE.B).add(_amount)>players[_player].accumulatives[2]){
                return true;
            }
        }
    }
    //Team Performance statistics
    function _teamCount(address _ref,uint256 amount,bool active) private{
        address player = _ref;
        for (uint256 i = 0; i < MODEL_REWARDS_PERCENTS[0].length; i++) {
            if (player == address(0)||!players[player].linkEnable) {
                break;
            }
            if(!active){
                players[player].teamCount++;
            }           
            players[player].teamPerformance = players[player].teamPerformance.add(amount);
            player = players[player].referrer;
        }
    }
    //Update A3 switching time
    modifier _updateA3Time() {
        uint256 _duration = now.sub(a3Valve.previousRecordTime).div(ONE_DAY);
        if(_duration>0){
            a3Valve.previousRecordTime = a3Valve.previousRecordTime.add(_duration.mul(ONE_DAY));
            a3Valve.previousTotalSupply = getBalance();
        }
        _;
    }
    //Update A3 switch status
    modifier _updateA3Status(){
        _;
        uint256 previousTotalSupply = a3Valve.previousTotalSupply;        
        if(previousTotalSupply==uint256(0)){
            a3Valve.opening = false;
        }else if(previousTotalSupply>getBalance()){
            //Drop more than 10% to open A3
            if((previousTotalSupply.sub(getBalance())).mul(100).div(previousTotalSupply)>10){
                a3Valve.opening=true;
            }
        }else{
            //Increase more than 20% to close A3
            if((getBalance().sub(previousTotalSupply)).mul(100).div(previousTotalSupply)>20){
                a3Valve.opening=false;
            }
        }
            
    }  
    //pledge
    function makeDeposit(address payable ref, uint8 modelType,uint8 payType,uint256 depositAmount) external _checkPoolInit _checkPlayerInit(msg.sender) _updateA3Time _updateA3Status {
        
        
        //Verify whether the activity starts
        require(now>=START_TIME,"Activity not started");
        Player storage player = players[msg.sender];
        //Verify that the contract type is correct
        require(modelType <= DEPOSITS_TYPES_COUNT, "Wrong deposit type");
        //Check recharge amount
        require(
            depositAmount >= MINIMAL_DEPOSIT&&depositAmount <=MAXIMAL_DEPOSIT,
            "Beyond the limit"
        );
        //require(modelType!=2||a3Valve.opening,"a3 is not opening");
		if(modelType==2){
			require(a3Valve.opening,"a3 is not opening");
		}
        
        //Do not recommend yourself
        require(player.active || ref != msg.sender, "Referal can't refer to itself");
        //Check whether the recharge amount is in compliance
        require(modelIsBlong2(modelType,MODELTYPE.C)||_checkDepositLimit(depositAmount,payType),"Type error");
        require(!_checkBOverLimit(modelType,depositAmount,msg.sender),"exceed the limit");        
        //PROJECT_LEADER.transfer(msg.value.mul(LEADER_COMMISSION).div(100));
        //MAINTAINER.transfer(msg.value.mul(MAINTAINER_COMMISSION).div(100));
        
        bool isActive = player.active;
        
        //Statistics of new registered users
        if (!player.active) {
            playersCount = playersCount.add(1);
            player.active = true;
            if(players[ref].linkEnable){
                player.referrer = ref;
                players[ref].refsCount = players[ref].refsCount.add(1);
            }
        }
        
        _teamCount(player.referrer,depositAmount,isActive);
        //A contract activates the referral link
        if(modelIsBlong2(modelType,MODELTYPE.A)){
            if(!player.linkEnable){
                player.linkEnable = true;
            }
        }
        //Calculate the pledge reward
        uint256 amount = depositAmount.mul(PLANS_PERCENTS[modelType]).div(10000);
        depositsCounter = depositsCounter.add(1);
        player.deposits.push(
            Deposit({
                id: depositsCounter,
                amount: depositAmount,
                modelType: modelType,
                freezeTime: now,
                loanLimit: amount,
                withdrawn: 0,
                lastWithdrawn: now,
                afterVoting: 0
            })
        );

        uint8 _type = uint8(modelBlong2(modelType));
        player.accumulatives[_type] = player.accumulatives[_type].add(depositAmount);

        if(modelIsBlong2(modelType,MODELTYPE.C)){
            if(player.vip<2){
                //500 thousand HG account is automatically upgraded to VIP1 account
                if(player.accumulatives[_type]>=VIP1){
                    player.vip = 1;
                    //1 million HG account is automatically upgraded to VIP2 account
                    if(player.accumulatives[_type]>=VIP2){
                        player.vip = 2;
                    }
                }
            }
        }
        
        //Expiration date of contract
        uint256 _expirationTime = now.add(PLANS_PERIODS[modelType]);
        //User becomes invalid user time
        if(_expirationTime>player.expirationTime){
            player.expirationTime = _expirationTime;
        }
        player.playerDepositAmount = player.playerDepositAmount.add(depositAmount);
        totalDepositAmount = totalDepositAmount.add(depositAmount);
        
        GH.safeTransferFrom(msg.sender,address(this),depositAmount);
        emit NewDeposit(depositsCounter, msg.sender, _getReferrer(msg.sender), modelType, depositAmount);
    }
    
    function getBalance() private view returns (uint256){
        return GH.balanceOf(address(this));
    }
    
    
    function _withdraw(address payable _wallet, uint256 _amount) private {
        require(getBalance() >= _amount, "HG not enougth");
        GH.safeTransfer(_wallet,_amount);
    }
    //Out this operation
    function takeAwayDeposit(uint256 depositId) external _checkPoolDestory _checkPoolInit _checkPlayerInit(msg.sender) _updateA3Time _updateA3Status returns (uint256) {
        Player storage player = players[msg.sender];
        require(player.lastWithdrawTime.add(WITHDRAW_DURATION)<now,"error");
        //Check the serial number of contract
        require(depositId < player.deposits.length, "Out of range");
        Deposit memory deposit = player.deposits[depositId];
        //Check whether the revenue is extracted
        require(deposit.withdrawn>=deposit.loanLimit.mul(99).div(100), "First need to withdraw reward");
        //Check whether the contract expires
        require(
            deposit.freezeTime.add(PLANS_PERIODS[deposit.modelType]) <= block.timestamp,
            "Not allowed now"
        );
        //Type B contracts do not support withdrawals
        require(!modelIsBlong2(deposit.modelType,MODELTYPE.B),"Unsupported type");  
        //Check whether the amount is sufficient
        require(getBalance() >= deposit.amount, "HG not enought");
        if (depositId < player.deposits.length.sub(1)) {
          player.deposits[depositId] = player.deposits[player.deposits.length.sub(1)];
        }
        player.deposits.pop();        
        player.lastWithdrawTime = now;
        player.playerWithdrawAmount = player.playerWithdrawAmount.add(deposit.amount);
        totalWithdrawAmount = totalWithdrawAmount.add(deposit.amount);
        GH.safeTransfer(msg.sender,deposit.amount);
        emit TakeAwayDeposit(msg.sender, deposit.modelType, deposit.amount);
    }
    function _getReferrer(address _player) private view returns (address payable) {
        return players[_player].referrer;
    }
    //Obtain A, B, C type of effective total investment
    function _getTypeTotal(address _player,MODELTYPE tys) private view returns(uint256 totalAmount) {
        if(!checkUpdate(_player)){
            Player memory player = players[_player];
            uint256 _typeTotal = 0;
            if(player.expirationTime>now){
                for(uint256 i =0;i<player.deposits.length;i++){
                    Deposit memory _deposit = player.deposits[i];
                    //Obtain a valid contract
                    if(modelIsBlong2(_deposit.modelType,tys)&&_deposit.freezeTime.add(PLANS_PERIODS[_deposit.modelType])>now){
                        _typeTotal = _typeTotal.add(_deposit.amount);
                    }
                }
            }
            return _typeTotal;
        }
       
    }    
    function _getTeamTotalLimit(address _player) public view returns (uint256 teamTotalLimit){
        return players[_player].accumulatives[0].mul(teamRewardLimit).div(10);
    }
    //Allocate team rewards
    function allocateTeamReward(uint256 _amount, address _player, uint8 modelType) private {
        address player = _player;
        address payable ref = _getReferrer(player);
        uint256 refReward;
        for (uint256 i = 0; i < MODEL_REWARDS_PERCENTS[modelType].length; i++) {            
            //Illegal referrer to skip
            if (ref == address(0x0)||!players[ref].linkEnable) {
                break;
            }
            //Invalid user
            if(players[ref].expirationTime<now){
                break;
            }
            //Invalid user
            if(checkUpdate(_player)){
                break;
            }            
            if(players[ref].refsCount<i.add(1)){
                continue;
            }
            refReward = (_amount.mul(MODEL_REWARDS_PERCENTS[modelType][i]).div(1000));
            //Award cap A class investment 3.3 times
            uint256 teamTotalLimit = _getTeamTotalLimit(ref);
            //No reward will be given beyond the limit
            if(players[ref].referralReward.add(refReward)>teamTotalLimit){
                if(players[ref].referralReward<teamTotalLimit){
                    refReward = teamTotalLimit.sub(players[ref].referralReward);
                }else{
                    refReward = 0; 
                }
            }
            //User recommendation reward
            players[ref].referralReward = players[ref].referralReward.add(refReward);            
            referRewardMap[ref] = referRewardMap[ref].add(refReward);
            emit AllocateReferralReward(ref, player, _amount,MODEL_REWARDS_PERCENTS[modelType][i], modelType, refReward);
            player = ref;
            ref = players[ref].referrer;
        }
    }    
    function withdrawReferReward() external _checkPoolDestory _checkPoolInit _checkPlayerInit(msg.sender) _updateA3Time _updateA3Status returns (uint256){
        uint256 refReward = referRewardMap[msg.sender];
        require(players[msg.sender].lastWithdrawTime.add(WITHDRAW_DURATION)<now,"error");
        require(refReward>0,"error ");
        require(getBalance() >= refReward,"error");
        GH.safeTransfer(msg.sender,refReward);
        players[msg.sender].playerWithdrawAmount = players[msg.sender].playerWithdrawAmount.add(refReward);
        totalWithdrawAmount = totalWithdrawAmount.add(refReward);
        referRewardMap[msg.sender] = 0;
        players[msg.sender].lastWithdrawTime = now;        
        emit TransferReferralReward(msg.sender, refReward);
    }
    
     function getLastWithdrawTime(address _player) external  view returns (uint256 withdrawTime){
        if(!checkUpdate(_player)){
            return players[_player].lastWithdrawTime;
        }
    }  
    
    //Extractable income
    function outputReward(address _player,uint256 depositId) public view returns (uint256){
        if(!checkUpdate(_player)){
            Player memory player = players[_player];
            Deposit memory deposit = player.deposits[depositId];
            if(modelIsBlong2(deposit.modelType,MODELTYPE.C)){
                return deposit.loanLimit.sub(deposit.withdrawn);
            }
            if(deposit.freezeTime.add(PLANS_PERIODS[deposit.modelType])<=now){
                return deposit.loanLimit.sub(deposit.withdrawn);
            }else{
                return deposit.loanLimit.mul(now.sub(deposit.lastWithdrawn)).div(PLANS_PERIODS[deposit.modelType]);
            }
        }    
    }
    //Withdrawal loan amount
     function withdrawReward(uint256 depositId) external _checkPoolDestory _checkPoolInit _checkPlayerInit(msg.sender) _updateA3Time _updateA3Status returns (uint256) {
        Player storage player = players[msg.sender];
        require(player.lastWithdrawTime.add(WITHDRAW_DURATION)<now,"less than 8 hours");
        require(depositId < player.deposits.length, "Out of range");
        Deposit storage deposit = player.deposits[depositId];
        uint256 currTime = now;
        //require(modelIsBlong2(deposit.modelType,MODELTYPE.C)||deposit.lastWithdrawn.add(WITHDRAW_DURATION)<currTime||deposit.freezeTime.add(PLANS_PERIODS[deposit.modelType]) <= block.timestamp, "less than 8 hours");
        
        uint256 amount = outputReward(msg.sender,depositId);
        require(amount!=0,"Already withdrawn");
        deposit.withdrawn = deposit.withdrawn.add(amount);
        deposit.lastWithdrawn = currTime;
        require(deposit.withdrawn<=deposit.loanLimit,"error ");
        
        if(modelIsBlong2(deposit.modelType,MODELTYPE.B)){
            if(deposit.withdrawn==deposit.loanLimit){
                if (depositId < player.deposits.length.sub(1)) {
                  player.deposits[depositId] = player.deposits[player.deposits.length.sub(1)];
                }
                player.deposits.pop();
            }
        }
        uint256 _vipReward;
        if(deposit.modelType!=2){
            _vipReward= getVipReward(player.vip,amount);
            allocateTeamReward(amount,msg.sender,deposit.modelType);
        }
        player.playerWithdrawAmount = player.playerWithdrawAmount.add(amount.add(_vipReward));
        totalWithdrawAmount = totalWithdrawAmount.add(amount.add(_vipReward));
        player.lastWithdrawTime = now;
        _withdraw(msg.sender, amount.add(_vipReward));
        emit Withdraw(msg.sender, deposit.amount, PLANS_PERCENTS[deposit.modelType], amount.add(_vipReward));
        return amount.add(_vipReward);
    }
    function getVipReward(uint8 _vip,uint256 amount) internal view returns(uint256){
        return amount.mul(VIP_REWARD_PERCENTS[_vip]).div(100);
    }   
    modifier _checkPlayerInit(address _player){        
        if(checkUpdate(_player)){
            clearPlayer(_player);
        }
        _;
    }
	//Verify that the user version number is consistent with the current version
    function checkUpdate(address _player) private view returns (bool){
        uint256 subVersion = version.sub(versionMaps[_player]);
        if(subVersion==0){
            return false;
        }else if(subVersion==1){
            if(now.sub(clearStartTime)<ONE_DAY){
                return false;
            }else{
                return true;
            }
        }else{
            return true;
        }
    }
    
    //The pool is below the DESTORY_LIMIT, triggering a restart
    modifier _checkPoolDestory(){
        _;
        if(clearStartTime==0){
            if(getBalance()<DESTORY_LIMIT){
                clearStartTime = now;
                version = version.add(1);
            }
        }
    }
    //Inconsistent version Numbers user clears transaction records
    function clearPlayer(address _player) private{
        Player storage player = players[_player];
        delete player.deposits;
        player.expirationTime = 0;
        player.lastWithdrawTime = 0;
        referRewardMap[_player] = 0;
        versionMaps[_player] = version;
    }
    //Verify that the pool is restarted
    modifier _checkPoolInit() {
        if(clearStartTime!=0){
            if(now.sub(clearStartTime)>=ONE_DAY){
                clearStartTime = 0;
            }
        }
        _;
    }
	//The entire network information
    function getGlobalStats() external view returns (uint256[5] memory stats) {
        stats[0] = totalDepositAmount;
        stats[1] = getBalance();
        stats[2] = totalWithdrawAmount;
        stats[3] = playersCount;
        stats[4] = clearStartTime;
        if(clearStartTime!=0){
            if(now.sub(clearStartTime)>ONE_DAY){
                stats[4] = 0;
            }
        }
        
    }
    //The pledge to record
    function getDeposits(address _player) public view returns (uint256[POSSIBLE_DEPOSITS_ROWS_COUNT] memory deposits) {
        if(!checkUpdate(_player)){
            Player memory player = players[_player];
            for (uint256 i = 0; i < player.deposits.length; i++) {
                uint256[ROWS_IN_DEPOSIT] memory deposit = depositStructToArray(i,player.deposits[i]);
                for (uint256 row = 0; row < ROWS_IN_DEPOSIT; row++) {
                    deposits[i.mul(ROWS_IN_DEPOSIT).add(row)] = deposit[row];
                }
            }
        }    
        
    }
	//paging
    function getDeposits(address _player,uint256 page) public view returns (uint256[100] memory deposits) {
        Player memory player = players[_player];
        
        if(!checkUpdate(_player)){
            uint256 start = page.mul(ROWS);
            uint256 init = start;
            uint256 _totalRow = player.deposits.length;
            if(start.add(ROWS)<_totalRow){
                _totalRow = start.add(ROWS);
            }
            for (start; start < _totalRow; start++) {
                uint256[ROWS_IN_DEPOSIT] memory deposit = depositStructToArray(start,player.deposits[start]);
                for (uint256 row = 0; row < ROWS_IN_DEPOSIT; row++) {
                    deposits[(start.sub(init)).mul(ROWS_IN_DEPOSIT).add(row)] = deposit[row];
                }
            }
        }
        
    }
	//Personal information
    function getPersonalStats(address _player) external view returns (uint256[14] memory stats) {
        Player memory player = players[_player];        
        stats[0] = player.accumulatives[0];
        stats[1] = _getTypeTotal(_player,MODELTYPE.A);
        stats[2] = player.accumulatives[1];
        stats[3] = _getTypeTotal(_player,MODELTYPE.B);
        stats[4] = player.accumulatives[2];
        stats[5] = _getTypeTotal(_player,MODELTYPE.C);        
        uint256 teamTotalLimit = _getTeamTotalLimit(_player);        
        if(teamTotalLimit<player.referralReward){
            stats[6] = 0;
        }else{
            stats[6] = teamTotalLimit.sub(player.referralReward);
        }
        stats[7] = player.referralReward;
        stats[8] = player.vip;
        stats[9] = player.refsCount;
        stats[10] = player.teamCount;
        stats[11] = player.playerDepositAmount;
        stats[12] = player.playerWithdrawAmount;
        stats[13] = player.teamPerformance;        
    }
    function depositStructToArray(uint256 depositId,Deposit memory deposit) private view returns (uint256[ROWS_IN_DEPOSIT] memory depositArray) {
        depositArray[0] = depositId;
        depositArray[1] = deposit.amount;
        depositArray[2] = deposit.modelType;
        depositArray[3] = PLANS_PERCENTS[deposit.modelType].add(deposit.afterVoting.mul(1000));
        depositArray[4] = PLANS_PERIODS[deposit.modelType];
        depositArray[5] = deposit.freezeTime;
        depositArray[6] = deposit.withdrawn;
        depositArray[7] = deposit.loanLimit;
        depositArray[8] = deposit.id;
        depositArray[9] = deposit.lastWithdrawn;
    }
}