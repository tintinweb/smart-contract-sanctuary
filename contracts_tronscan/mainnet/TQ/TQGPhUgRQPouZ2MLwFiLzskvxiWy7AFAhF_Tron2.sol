//SourceUnit: Tron2.sol

pragma solidity ^0.5.12;

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

contract Context {


    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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


library TransferHelper {
    
    function safeTransferTrx(address to, uint256 value) internal {
       (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper::safeTransferTRX: TRX transfer failed');
    }
    
}

interface PrizePool {
    
    function allotPrize(address lucky, uint256 amount) external;
    
    function withdraw(address payable lucky,uint256 amount) external returns (uint256);
    
    function availableBalance(address contractAddress) external view returns(uint256);
    
    function prizes(address contractAddress,address userAddress) external view returns(uint256);
    
    function clearPrize(address lucky) external;
}

interface RecommendPool {
    
    function allotBonus(address[5] calldata ranking,uint256 timePointer) external  returns (uint256);
    
    function withdraw(address payable ref,uint256 amount) external returns (uint256);
    
    function prizes(address contractAddress,address userAddress) external view returns(uint256);
    
    function availableBalance(address userAddress) external view returns(uint256);
}

contract Tron2Config{

    uint256 public constant CREATE_TIME = 1607947200;
    //Activity start time
    uint256 public constant START_TIME = 1607947200;
    //one day
    uint256 public constant ONE_DAY = 1 days;
    //Withdrawal cooldown time
    uint256 public constant WITHDRAW_DURATION = 4 hours;
    //Total number of transaction types
    uint8 public constant DEPOSITS_TYPES_COUNT = 3;
    //The total team bonus is 3.3
    uint8 public constant WITHDRAW_MUL = 33;
    //Minimum recharge amount
    uint256 public constant MINIMAL_DEPOSIT = 100 trx;
    //Maximum recharge amount
    uint256 public constant MAXIMAL_DEPOSIT = 100000 trx;
    
    uint256 public constant STEP = 5000 trx;
    
    uint256 public luckyPrizeLimit = 10000 trx;

    uint256[3] public overLimit = [100,50,100];
    
    uint256[3] public earn_percent = [1,1,20];
    
    uint256[3] public luckyPercentLimit = [0,50,100];
    
    uint256[15] public MODEL_REWARDS_PERCENTS = [20,10,15,5,5,5,5,5,5,5,6,6,6,6,6];


    uint256 public LEADER_PERCENT = 8;
    uint256 public TRON1_PERCENT = 5;
    uint256 public RECOMMEND_PERCENT = 5;
    uint256 public LUCKY_PERCENT = 2;
        
    uint256 public freeze_cycle = 30 days;
    
   
}


contract Tron2 is Ownable,Tron2Config{
    using SafeMath for uint256;
    
    constructor(address payable _leaderPoolAddress,address payable _tron1PoolAddress,address payable _prizePoolAdress,address payable _recommendPoolAddress) public payable {
        
        leaderPoolAddress = _leaderPoolAddress;
        tron1PoolAddress = _tron1PoolAddress;
        prizePoolAdress = _prizePoolAdress;
        recommendPoolAddress = _recommendPoolAddress;
        
        prizePool = PrizePool(_prizePoolAdress);
        recommendPool = RecommendPool(_recommendPoolAddress);
    }

    struct Deposit {
        //contract id
        uint256 id;
        //investment amount
        uint256 amount;
        //Contract Subdivision type0~5
        uint8 modelType;
        //
        uint256 freezeTime;
        //Withdrawal amount
        uint256 withdrawn;

    }

    struct Player{

        address payable referrer;

        bool linkEnable;

        uint256 referralReward;

        Deposit[] deposits;

        bool active;
        
        bool again;

        uint256 refsCount;

        uint256[3] accumulatives;

        uint256 teamCount;

        uint256 playerDepositAmount;

        uint256 playerWithdrawAmount;

        uint256 teamPerformance;

        uint256 withdrawTime;
        
        uint256 withdrawal;

    }


    uint256[5] public rankPercent = [5,4,3,2,1];

    PrizePool public prizePool;
    RecommendPool public recommendPool;
    //THsAnwCaBdcH1pKDZbB4RUZhxXjiTgWDRJ
    address payable private leaderPoolAddress;
    //TBAV29wUeLacDG6BxaHE8uEUqF8MFPupEx
    address payable public tron1PoolAddress;
    address payable private prizePoolAdress;
    address payable private recommendPoolAddress;
    
    

    mapping(address => Player) public players;
    mapping(uint256 => mapping(address => uint256)) public performances;
    mapping(uint256 => address[5]) public performanceRank;

    //mapping(address => uint256) public luckyPrizes;
    mapping(address => uint256) public referRewards;
    //mapping(address => uint256) public performances;

    uint256 totalDepositAmount;
    uint256 totalWithdrawAmount;

    //Number of players
    uint256 public playersCount;
    //Recharge counter
    uint256 private depositsCounter;
    
    uint256 public timePointer;
    
    event MakeDeposit(address indexed userAddress,address indexed ref,uint256 amount);
    
    event WithdrawYield(address indexed userAddress,uint256 amount,uint256 available);
    
    event Refund(address indexed userAddress,uint256 amount);
    
    event WithdrawReferReward(address indexed userAddress,uint256 amount,uint256 available);
    
    event WithdrawLuckyPrize(address indexed userAddress,uint256 amount,uint256 available);
    
    event WithdrawRecommend(address indexed userAddress,uint256 amount,uint256 available);
    
    event AllocateTeamReward(address indexed userAddress,address indexed refAddress,uint256 amount,uint256 available);
    
    event DestroyContractA(address indexed userAddress);
     
    
    //销毁A合约
    modifier destroyContractA(){
        _;
        
        if(extractable(msg.sender)==0){
            players[msg.sender].deposits[0] = createDeposit(0,0,0);
            players[msg.sender].again = true;
            referRewards[msg.sender] = 0;
            prizePool.clearPrize(msg.sender);
            
            emit DestroyContractA(msg.sender);
        }
    }
    

    function _checkOverLimit(uint8 modelType,uint256 amount,uint256[3] memory accumulatives) private view {
        uint256 baseAmount = accumulatives[0];

        if(modelType!=0){
            require(accumulatives[modelType].add(amount)<=baseAmount.mul(overLimit[modelType]).div(100),"Beyond the limit");
        }

    }

    //Team Performance statistics
    function _teamCount(address _ref,uint256 amount,bool active) private{
        address player = _ref;
        for (uint256 i = 0; i < 15; i++) {
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

    function _genDepositId(uint8 modelType,uint256 amount) private  returns (uint256) {

        uint8 addType = 1;
        uint256 lastStep = address(this).balance.div(STEP);
        uint256 nextStep = address(this).balance.add(amount).div(STEP);
        uint256 step = nextStep.sub(lastStep).mul(4);

        uint256 lastNum = block.number.mod(10);
        
        return depositsCounter = depositsCounter.add(addType).add(step).add(lastNum);
    }

    function _active(address payable ref,address userAddress) private {
        //Statistics of new registered users
        if (!players[userAddress].active) {
            playersCount = playersCount.add(1);
            players[userAddress].active = true;
            if(players[ref].linkEnable){
                players[userAddress].referrer = ref;
                players[ref].refsCount = players[ref].refsCount.add(1);
            }

            players[userAddress].deposits.push(createDeposit(0,0,0));
        }
    }
    
    function _allotPool(uint256 amount) private {
        
        leaderPoolAddress.transfer(amount.mul(LEADER_PERCENT).div(100));
        tron1PoolAddress.transfer(amount.mul(TRON1_PERCENT).div(100));
        //TransferHelper.safeTransferTrx(tron1PoolAddress,msg.value.mul(TRON1_PERCENT).div(100));
        TransferHelper.safeTransferTrx(recommendPoolAddress,msg.value.mul(RECOMMEND_PERCENT).div(100));
        TransferHelper.safeTransferTrx(prizePoolAdress,msg.value.mul(LUCKY_PERCENT).div(100));
        
    }
    
    function _luckyDeposit(uint256 amount,uint256 luckyId,Player storage player) private returns (uint256 luckyPrize,uint8 luckyType) {
        if(!player.linkEnable){
            player.linkEnable = true;
        }
        
        if(luckyId.mod(20) == 0){
            luckyType = 1;
            if(luckyId.mod(100) == 0){
                luckyType = 2;
            }
        }
        
        luckyPrize = amount.mul(luckyPercentLimit[luckyType]).div(100);
        
        if(prizePool.availableBalance(address(this))>=luckyPrize){
            if(luckyPrize>0){
                prizePool.allotPrize(msg.sender,luckyPrize);
            }
        }

    }
    
    function createDeposit(uint256 depositId,uint8 modelType,uint256 amount) private view returns(Deposit memory deopist){

        deopist = Deposit({
            id: depositId,
            amount: amount,
            modelType: modelType,
            freezeTime: now,
            withdrawn: 0
        });
    }
    
    function shootOut(address[5] memory rankingList,address userAddress) public view returns (uint256 sn,uint256 minPerformance){
        
        minPerformance = performances[duration()][rankingList[0]];
        for(uint8 i =0;i<5;i++){
            if(rankingList[i]==userAddress){
                return (5,0);
            }
            if(performances[duration()][rankingList[i]]<minPerformance){
                minPerformance = performances[duration()][rankingList[i]];
                sn = i;
            }
        }
        
        return (sn,minPerformance);
    }
    
    function _updateRanking(address userAddress) private {
        address[5] memory rankingList = performanceRank[duration()];
        
        
        (uint256 sn,uint256 minPerformance) = shootOut(rankingList,userAddress);
        if(sn!=5){
            if(minPerformance<performances[duration()][userAddress]){
                rankingList[sn] = userAddress;
            }
            performanceRank[duration()] = rankingList;
        }
    }
    
    
    
    function sortRanking(uint256 _duration) public view returns(address[5] memory ranking){
        ranking = performanceRank[_duration];
        
        address tmp;
        for(uint8 i = 1;i<5;i++){
            for(uint8 j = 0;j<5-i;j++){
                if(performances[_duration][ranking[j]]<performances[_duration][ranking[j+1]]){
                    tmp = ranking[j];
                    ranking[j] = ranking[j+1];
                    ranking[j+1] = tmp;
                }
            }
        }
        return ranking;
    }
    
    modifier settleBonus(){
        
		settlePerformance();
        
        _;
    }
    
    function settlePerformance() public {
        
        if(timePointer<duration()){
            address[5] memory rankingList = sortRanking(timePointer);
            recommendPool.allotBonus(rankingList,timePointer);
            timePointer = duration();
        }
    }
    
    function _statistics(address ref,uint256 amount) private{
        if(ref!=address(0)){
           performances[duration()][ref] = performances[duration()][ref].add(amount); 
        }
        
    }

    function makeDeposit(address payable ref, uint8 modelType) public payable settleBonus returns (bool) {

        require(now>=START_TIME,"Activity not started");
		require(!Address.isContract(msg.sender),"not allow");
        require(msg.value.mod(100 trx)==0,"Only multiples of 100 are supported");
        //Verify that the contract type is correct
        require(modelType <= DEPOSITS_TYPES_COUNT, "Wrong deposit type");
        //Check recharge amount
        Player storage player = players[msg.sender];
        if(player.again&&modelType==0){
            require(msg.value>= MINIMAL_DEPOSIT&&msg.value <=MAXIMAL_DEPOSIT*10,"Beyond the limit");
        }else{
            require(msg.value>= MINIMAL_DEPOSIT&&msg.value <=MAXIMAL_DEPOSIT,"Beyond the limit");
        }
        

        
        require(player.active || ref != msg.sender, "Referal can't refer to itself");

        _checkOverLimit(modelType,msg.value,player.accumulatives);

        bool isActive = player.active;

        _active(ref,msg.sender);
        
        
        if(modelType == 0){
            require(player.deposits[0].id == 0,"There can only be one A contract");
            _statistics(player.referrer,msg.value);
        }

        _teamCount(player.referrer,msg.value,isActive);
        
        _allotPool(msg.value);

        uint256 depositId = _genDepositId(modelType,msg.value);
        
        if(modelType==0){
            _luckyDeposit(msg.value,depositId,player);
            player.deposits[0] = createDeposit(depositId,modelType,msg.value);
        }else{
            player.deposits.push(createDeposit(depositId,modelType,msg.value));
        }


        player.accumulatives[modelType] = player.accumulatives[modelType].add(msg.value);

        player.playerDepositAmount = player.playerDepositAmount.add(msg.value);
        
        _updateRanking(player.referrer);

        totalDepositAmount = totalDepositAmount.add(msg.value);
        
        
        emit MakeDeposit(msg.sender,ref,msg.value);

    }
    
    
    function withdrawYield(uint256 id) public settleBonus destroyContractA returns (uint256){
        
        Player storage player = players[msg.sender];
        require(player.withdrawTime.add(WITHDRAW_DURATION)<now,"error");
        require(id < player.deposits.length, "Out of range");
        Deposit storage deposit = player.deposits[id];
        
        uint256 _income = income(msg.sender,id);
        
        require(_income>0,"Already withdrawn");
        
        (uint256 available,) = quota(msg.sender,_income);
        
        require(available>0,"The withdrawal limit is 0");
        
        deposit.withdrawn = deposit.withdrawn.add(available);
        
        player.playerWithdrawAmount = player.playerWithdrawAmount.add(available);
        
        player.withdrawal = player.withdrawal.add(available);
        
        totalWithdrawAmount = totalWithdrawAmount.add(available);
        player.withdrawTime = now;
        
        msg.sender.transfer(available);
        _allocateTeamReward(available,msg.sender);
        
        emit WithdrawYield(msg.sender,_income,available);
        return available;
    }
    
    
    function refund(uint256 id) public settleBonus {
        
        Player storage player = players[msg.sender];
        require(player.withdrawTime.add(WITHDRAW_DURATION)<now,"error");
        //Check the serial number of contract
        require(id < player.deposits.length, "Out of range");
        Deposit memory deposit = player.deposits[id];
        
        require(deposit.modelType!=0,"unsupport type");
        
        uint256 _income = income(msg.sender,id);
        (uint256 available,) = quota(msg.sender,_income);
        
        
        require(available==0,"Please draw the proceeds first");
        
        
        if(deposit.modelType==2){
            require(deposit.freezeTime.add(freeze_cycle) <= now,"Not allowed now");
        }
        
        require(address(this).balance >= deposit.amount, "TRX not enought");
        
        if (id < player.deposits.length.sub(1)) {
          player.deposits[id] = player.deposits[player.deposits.length.sub(1)];
        }
        player.deposits.pop();        
        player.withdrawTime = now;
        player.playerWithdrawAmount = player.playerWithdrawAmount.add(deposit.amount);
        totalWithdrawAmount = totalWithdrawAmount.add(deposit.amount);
        msg.sender.transfer(deposit.amount);
        
        emit Refund(msg.sender,deposit.amount);
    }
    
    
    function withdrawReferReward() external settleBonus destroyContractA returns (uint256){
        uint256 refReward = referRewards[msg.sender];
        require(players[msg.sender].withdrawTime.add(WITHDRAW_DURATION)<now,"error");
        require(refReward>0,"error ");
        
        (uint256 available,) = quota(msg.sender,refReward);
        
        
        require(address(this).balance >= available,"error");
        
        players[msg.sender].playerWithdrawAmount = players[msg.sender].playerWithdrawAmount.add(available);
        
        players[msg.sender].withdrawal = players[msg.sender].withdrawal.add(available);
        totalWithdrawAmount = totalWithdrawAmount.add(available);
        referRewards[msg.sender] = referRewards[msg.sender].sub(available);
        players[msg.sender].withdrawTime = now;
        msg.sender.transfer(available);
        
        emit WithdrawReferReward(msg.sender,refReward,available);
        return available;
    }
    
    
    function withdrawLuckyPrize() external settleBonus destroyContractA returns(uint256){
        
        require(players[msg.sender].withdrawTime.add(WITHDRAW_DURATION)<now,"error");
        
        uint256 prize = prizePool.prizes(address(this),msg.sender);
        
        (uint256 available,) = quota(msg.sender,prize);
        
        players[msg.sender].playerWithdrawAmount = players[msg.sender].playerWithdrawAmount.add(available);
        
        players[msg.sender].withdrawal = players[msg.sender].withdrawal.add(available);
        totalWithdrawAmount = totalWithdrawAmount.add(available);
        players[msg.sender].withdrawTime = now;
        
        prizePool.withdraw(msg.sender,available);
        
        emit WithdrawLuckyPrize(msg.sender,prize,available);
        
        return available;
    }
    
    
    function withdrawRecommend() external settleBonus destroyContractA returns(uint256){
        
        require(players[msg.sender].withdrawTime.add(WITHDRAW_DURATION)<now,"error");
        
        uint256 recommend = recommendPool.prizes(address(this),msg.sender);
        
        (uint256 available,) = quota(msg.sender,recommend);
        
        players[msg.sender].playerWithdrawAmount = players[msg.sender].playerWithdrawAmount.add(available);
        players[msg.sender].withdrawal = players[msg.sender].withdrawal.add(available);
        
        totalWithdrawAmount = totalWithdrawAmount.add(available);
        players[msg.sender].withdrawTime = now;
        
        recommendPool.withdraw(msg.sender,available);
        
        emit WithdrawRecommend(msg.sender,recommend,available);
        return available;
    }
    
    
    function _allocateTeamReward(uint256 _amount, address _player) private {
        address player = _player;
        address payable ref = players[_player].referrer;
        uint256 refReward;
        for (uint256 i = 0; i < MODEL_REWARDS_PERCENTS.length; i++) {            
            //Illegal referrer to skip
            if (ref == address(0x0)||!players[ref].linkEnable) {
                break;
            }
            //Invalid user
            if(players[ref].deposits[0].id==0){
                break;
            }
         
            if(players[ref].refsCount<i.add(1)){
                continue;
            }
            
            refReward = (_amount.mul(MODEL_REWARDS_PERCENTS[i]).div(100));
            
            (uint256 available,) = quota(ref,refReward);
            
            
            emit AllocateTeamReward(player,ref,refReward,available);
            //User recommendation reward
            players[ref].referralReward = players[ref].referralReward.add(refReward);            
            referRewards[ref] = referRewards[ref].add(available);
            player = ref;
            ref = players[ref].referrer;
            
            
        }
    }    
    

    function duration() public view returns(uint256){
        return duration(START_TIME);
    }

    function duration(uint256 startTime) public view returns(uint256){
        if(now<startTime){
            return 0;
        }else{
            return now.sub(startTime).div(ONE_DAY);
        }
    }

    //收益
    function income(address userAddress,uint256 depositId) public view returns(uint256) {

        Deposit memory deposit = players[userAddress].deposits[depositId];
        Deposit memory deposit0 = players[userAddress].deposits[0];
        
        uint256 freezeTime = deposit.freezeTime;
        
        bool stop;
        
        if(deposit0.freezeTime>freezeTime){
            freezeTime = deposit0.freezeTime;
            stop = true;
        }

        uint256 _duration = duration(freezeTime);
        if(deposit.modelType == 2){
            if(deposit.withdrawn==0){
                if(stop){
                    return 0;
                }else{
                    return deposit.amount.mul(earn_percent[deposit.modelType]).div(100);
                }
            }else{
                return 0;
            }
            
        }else{
            return deposit.amount.mul(earn_percent[deposit.modelType]).div(100).mul(_duration).sub(deposit.withdrawn);
        }
    }
    
    function nextGrant(address userAddress,uint256 depositId) public view returns(uint256){
        
        Deposit memory deposit = players[userAddress].deposits[depositId];
        Deposit memory deposit0 = players[userAddress].deposits[0];
        
        uint256 freezeTime = deposit.freezeTime;
        
        bool stop;
        
        if(deposit0.freezeTime>freezeTime){
            freezeTime = deposit0.freezeTime;
            stop = true;
        }
        
        uint256 _duration = duration(freezeTime);
        if(deposit.modelType == 2){
            return 0;
        }else{
            return freezeTime.add(_duration.add(1).mul(ONE_DAY));
        }
    }
    
    //提款上限
    function withdrawLimit(address userAddress) public view returns(uint256) {
        return players[userAddress].accumulatives[0].mul(WITHDRAW_MUL).div(10);
    }
    
    //可提取
    function extractable(address userAddress) public view returns (uint256) {
        if(players[userAddress].withdrawal>=withdrawLimit(userAddress)){
            return 0;
        }else{
            return withdrawLimit(userAddress).sub((players[userAddress].withdrawal));
        }
    }
    
    //输出可提取金额
    function quota(address userAddress,uint256 input) public view returns (uint256 available,uint256 undeliverable){
        
        uint256 extractableAmount = extractable(userAddress);
        
        if(input>extractableAmount){
            available = extractableAmount;
            undeliverable = input.sub(extractableAmount);
        }else{
            available = input;
            undeliverable = 0;
        }
        return (available,undeliverable);
    }
    
    function accumulatives(address userAddress) public view returns(uint256[3] memory){
        return players[userAddress].accumulatives;
    }
    
    
    function userRanking(uint256 _duration) external view returns(address[5] memory addressList,uint256[5] memory performanceList,uint256[5] memory refsCounts,uint256[5] memory preEarn){
        
        addressList = sortRanking(_duration);
        uint256 credit = recommendPool.availableBalance(address(this));
        for(uint8 i = 0;i<5;i++){
            refsCounts[i] = players[addressList[i]].refsCount;
            preEarn[i] = credit.mul(rankPercent[i]).div(100);
            performanceList[i] = performances[_duration][addressList[i]];
        }
        
    }
    
    function inRank(address userAddress) private view returns(uint256){
        address[5] memory ranking = sortRanking(timePointer);
        for(uint8 i = 0;i<5;i++){
            if(ranking[i]==userAddress){
                uint256 credit = recommendPool.availableBalance(address(this));
                return credit.mul(rankPercent[i]).div(100);
            }
        }
    }
 

    function awardDetails(address userAddress) external view returns(uint256 luckyPrize,uint256 recommendAward,uint256 referReward){
        
       if(timePointer<duration()){
            recommendAward = recommendAward.add(inRank(userAddress));
        }
        
        luckyPrize = prizePool.prizes(address(this),userAddress);
        recommendAward = recommendAward.add(recommendPool.prizes(address(this),userAddress));
        referReward = referRewards[userAddress];
        
    }
    
    	//The entire network information
    function getGlobalStats() external view returns (uint256[6] memory stats) {
        stats[0] = totalDepositAmount;
        stats[1] = address(this).balance;
        stats[2] = prizePool.availableBalance(address(this));
        stats[3] = recommendPool.availableBalance(address(this));
        stats[4] = playersCount;
        stats[5] = START_TIME.add(duration().add(1).mul(ONE_DAY));
        
    
    }
    
    function getPersonalStats(address _player) external view returns (uint256[14] memory stats){
        Player memory player = players[_player];        
        stats[0] = player.accumulatives[0];
        stats[1] = player.accumulatives[1];
        stats[2] = player.accumulatives[0].mul(overLimit[1]).div(100);
        stats[3] = player.accumulatives[2];
        stats[4] = player.accumulatives[0];
        stats[5] = withdrawLimit(_player);
        stats[6] = player.refsCount;
        stats[7] = player.teamCount;
        stats[8] = player.teamPerformance;
        stats[9] = player.playerDepositAmount;
        stats[10] = player.playerWithdrawAmount;
        stats[11] = extractable(_player);
        if(player.deposits.length==0){
           stats[12] = 0;
        }else{
           stats[12] = player.deposits[0].amount; 
        }
        
        stats[13] = player.withdrawTime;
    }
    
    //paging
    function getDeposits(address _player,uint256 page) public view returns (uint256[100] memory deposits) {
        Player memory player = players[_player];
        
        uint256 start = page.mul(10);
        uint256 init = start;
        uint256 _totalRow = player.deposits.length;
        if(start.add(10)<_totalRow){
            _totalRow = start.add(10);
        }
        for (start; start < _totalRow; start++) {
            uint256[10] memory deposit = depositStructToArray(start,player.deposits[start]);
            for (uint256 row = 0; row < 10; row++) {
                deposits[(start.sub(init)).mul(10).add(row)] = deposit[row];
            }
        }
        
        
    }
    
    function depositStructToArray(uint256 depositId,Deposit memory deposit) private view returns (uint256[10] memory depositArray) {
        depositArray[0] = depositId;
        depositArray[1] = deposit.amount;
        depositArray[2] = deposit.modelType;
        depositArray[3] = earn_percent[deposit.modelType];
        depositArray[4] = freeze_cycle;
        depositArray[5] = deposit.freezeTime;
        depositArray[6] = deposit.withdrawn;
        depositArray[7] = 0;
        depositArray[8] = deposit.id;
        depositArray[9] = 0;
    }

}