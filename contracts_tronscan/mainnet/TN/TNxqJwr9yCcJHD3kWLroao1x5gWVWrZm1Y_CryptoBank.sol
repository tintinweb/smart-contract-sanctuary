//SourceUnit: cryptobanklive.sol

// File: contracts/SafeMath.sol
pragma solidity ^0.5.14;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Insurance{

    using SafeMath for uint256;
    
    address payable public cryptobank;
    bool public initializeStatus;

    event SendAmount(address receiver, uint256 value);
    
    modifier contractOnly() {
        require(msg.sender == cryptobank, "cryptobank");
        _;
    }

    constructor() public {
        cryptobank = msg.sender;
    }

    function initialize(address payable _cryptobank) external  contractOnly{
        require(initializeStatus == false, 'Insurance: initialized'); 
        cryptobank = _cryptobank;
        initializeStatus = true;
    }
    
    function sendCryptoBank(uint _value) public contractOnly {
        require(getBalance(address(this)) >= _value,"Insurance: contract balance invalid");
        cryptobank.transfer(_value);
        emit SendAmount(cryptobank, _value);
    }

    function getBalance(address _addr) public view returns(uint256) {
        return _addr.balance;
    }
    
    function() external payable {   }

}

contract LuckyDraw{
    using SafeMath for uint256;

    struct game{
        uint ticketID;
        mapping(uint => address) userByTicket;
        bool status;
    }

    CryptoBank private _CryptoBank;

    address payable public cryptoBankContract;
    address payable public insuranceContract;
    uint public constant MAXTICKETS = 100;
    uint public gameId = 1;
    uint[] public priceBonus = [2000 trx, 1500 trx, 1000 trx, 500 trx];
    bool public initializeStatus;

    mapping(address => mapping(uint => uint[])) public tickets;
    mapping(uint => address) public userList;
    mapping(uint => game) public contest;

    event Participate(address indexed _addr, uint _gameid, uint _ticketID);
    event SendAmount(uint _gameID, uint _ticketId,address indexed _to, uint256 value);

    modifier contractOnly() {
        require(msg.sender == cryptoBankContract, "LuckyDraw: cryptobank");
        _;
    }
    
    constructor(address payable _insuranceContract) public {
        insuranceContract = _insuranceContract;
        cryptoBankContract = msg.sender;
    }
    
    function initialize(address payable _cryptobank) external contractOnly{
        require(initializeStatus == false, 'LuckyDraw: initialized'); 
        cryptoBankContract = _cryptobank;
        _CryptoBank = CryptoBank(_cryptobank);
        initializeStatus = true;
    }
    
    function participate(address _addr, uint _amount) public contractOnly {
        uint len = _amount.div(100 trx);

        for (uint i = 0; i < len; i++) {
            contest[gameId].ticketID++; // increment ticket id
            tickets[_addr][gameId].push(contest[gameId].ticketID);
            contest[gameId].userByTicket[contest[gameId].ticketID] = _addr;
            emit Participate(_addr, gameId, contest[gameId].ticketID);

            if (contest[gameId].ticketID == MAXTICKETS) {
                gameId++;
                if (getbalance(insuranceContract) < 10000000 trx) { //note
                    insuranceContract.transfer(1000 trx); // Insurance Contract
                } else {
                    cryptoBankContract.transfer(1000 trx);
                }
            }
        }
    }

    function priceDistribute(uint256[]memory _ticketID, uint _gameID) public contractOnly {
        require(contest[_gameID].ticketID == MAXTICKETS, "LuckyDraw: participate still not closed");
        require(_ticketID.length == 10 , "LuckyDraw: invalid length");
        require(contest[_gameID].status == false, "LuckyDraw: already distributed");
        contest[_gameID].status = true;
        for (uint i = 0; i < (_ticketID.length); i++) {
           if (i == 0) {
                _CryptoBank.price(viewUserByTicket(_gameID, _ticketID[i]), priceBonus[0]);
                emit SendAmount(_gameID,_ticketID[i], viewUserByTicket(_gameID, _ticketID[i]), priceBonus[0]);
            }
            else if (i == 1 ) {
                _CryptoBank.price(viewUserByTicket(_gameID, _ticketID[i]), priceBonus[1]);
                emit SendAmount(_gameID,_ticketID[i], viewUserByTicket(_gameID, _ticketID[i]), priceBonus[1]);
            }
            else if (i >=2 && i<=4) {
                _CryptoBank.price(viewUserByTicket(_gameID, _ticketID[i]), priceBonus[2]);
                emit SendAmount(_gameID, _ticketID[i], viewUserByTicket(_gameID, _ticketID[i]), priceBonus[2]);
            }
            else if (i >= 5 && i <= 9) {
                _CryptoBank.price(viewUserByTicket(_gameID, _ticketID[i]), priceBonus[3]);
                emit SendAmount(_gameID, _ticketID[i], viewUserByTicket(_gameID, _ticketID[i]), priceBonus[3]);
            }
        }
    }
 
    function sendPrice(uint _amount) public contractOnly returns(bool) {
        if (_amount <= getbalance(address(this))) {
            cryptoBankContract.transfer(_amount);
            return true;
        }
    }

    function viewUserByTicket(uint _gameId, uint _ticketID) public view returns(address) {
        return (contest[_gameId].userByTicket[_ticketID]);
    }

    function getbalance(address _addr) public view returns(uint256){
        return _addr.balance;
    }

    function viewGameStruct(uint _gameId) public view returns(uint256 ticketID) {
        return (contest[_gameId].ticketID);
    }
    
    function() external payable { }
}


contract CryptoBank{

    using SafeMath for uint256;
    struct user{
        uint cycle;
        address upline;
        uint referrals;
        uint payouts;
        uint deposit_amount;
        uint deposit_payouts;
        uint roi;
        uint deposit_time;
        uint withdraw_time;
        uint total_deposits;
        uint total_payouts;
        uint depositCycle;
        uint limitReached;
        mapping(uint => bonus) Bonus;
    }
    
    struct bonus{
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 referral_bonus;
        uint256 downline_bonus;
        uint256 deposit_bonus;
        uint limitReachedAmount;
        uint limitAmountReceived;
        uint lastWithdraw;
    }
    LuckyDraw private _luckydrawInstance;
    Insurance private _insuranceInstance;
    
    address payable public InsuranceContract;
    address payable public LuckyDrawContract;
    address payable public adminFee;
    address payable public marketingfee;
    address payable public platformfee;
    address payable public masterId;
    uint256[] public cycles = [100000 trx, 250000 trx, 500000 trx, 750000 trx, 1000000 trx, 1250000 trx];
    uint8[] public downline_bonuses = [30, 10, 10, 10, 10, 8, 8, 8, 8, 8, 5, 5, 5, 5, 5, 3, 3, 3, 3, 3];
    uint8[] public pool_bonuses = [5, 3, 2];
    uint8[] public referral_bonuses = [5, 3, 2];
    uint256 public pool_last_draw = block.timestamp;
    uint256 public referral_last_draw= block.timestamp;
    uint256 public pool_cycle;
    uint256 public referral_cycle;
    uint256 public total_users = 1;
    uint256 public total_deposited; 
    uint256 public total_withdraw;
    bool public lockStatus;
    bool public status;

    mapping(address => user) public users;
    mapping(uint256 => mapping(address => uint256)) public pool_users_deposits;
    mapping(uint8 => address) public pool_top;
    mapping(address => mapping(uint256 => uint256)) public referralBalance;
    mapping(uint256 => mapping(address => uint256)) public referral_userData;
    mapping(uint8 => address) public referral_top;
    mapping(address => uint256) public gameBalance;

    event Upline(address indexed addr, address indexed upline);
    event Deposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event DownlinePayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint256 totalDeposit);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    modifier platform(){
        require(msg.sender == masterId, "platform");
        _;
    }
    
    modifier isLock() {
        require(lockStatus == false, "contract locked");
        _;
    }

    modifier contractOnly(){
        require(msg.sender == LuckyDrawContract, "lucyDraw");
        _;
    }

    constructor(address payable _adminFee, address payable _marketingFee, address payable _platformFee, bool _status,
                address payable _insurance, address payable _luckydraw) public {
        masterId = msg.sender;
        adminFee = _adminFee;
        marketingfee = _marketingFee;
        platformfee = _platformFee;
        
        InsuranceContract = _insurance;
        LuckyDrawContract = _luckydraw;
        _insuranceInstance = Insurance(InsuranceContract);
        _luckydrawInstance =  LuckyDraw(LuckyDrawContract);
      
         lockStatus = _status;
    }
    
    function() external payable { }
    
    function _setUpline(address _addr, address _upline) private {
        if ((users[_addr].upline == address(0)) && (_upline != _addr) && (_addr != masterId) && ((users[_upline].deposit_time > 0) || (_upline == masterId))) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            total_users++;
            emit Upline(_addr, _upline);
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require((users[_addr].upline != address(0)) || (_addr == masterId), "No upline");
        require(available(_addr) >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists"); // change

        if (users[_addr].deposit_amount > 0) {
            if ((_amount >= users[_addr].deposit_amount + ((users[_addr].deposit_amount*25)/100)) && (_amount > cycles[users[_addr].cycle]) && (users[_addr].cycle < 5)) { users[_addr].cycle++; }
            require(_amount >= users[_addr].deposit_amount + ((users[_addr].deposit_amount*25)/100) && (_amount <= cycles[users[_addr].cycle]), "Bad Amount");
        }
        else { require(_amount >= 100 trx && _amount <= cycles[0], "Bad Amount"); }
            
        (uint256 to_payout,) = this.payoutOf(_addr);
        
        if (to_payout > 0) { users[_addr].Bonus[1].deposit_bonus = users[_addr].Bonus[1].deposit_bonus.add((to_payout)); }
        
        users[_addr].deposit_amount = _amount; // deposit amount
        users[_addr].deposit_payouts = 0; // payout of deposit income
        users[_addr].roi = 0; // DROI payout
        users[_addr].deposit_time = uint40(block.timestamp); // deposit time 
        users[_addr].total_deposits += _amount; // total deposits 
        total_deposited = total_deposited+(_amount);  // all user's total deposit
        users[_addr].depositCycle++; // increase user total deposit count
        users[_addr].withdraw_time = block.timestamp; // withdrawal  time
        users[_addr].Bonus[1].limitReachedAmount = 0; // amount on max limit reached
        users[_addr].Bonus[1].limitAmountReceived = 0; // amount on max limit reached
        if(availableEarnings(_addr) >= this.maxPayoutOf(users[_addr].total_deposits)){
            users[_addr].limitReached = block.timestamp + 10 seconds ; // maximum limit reached time
        } else {
            users[_addr].limitReached = block.timestamp; // maximum limit reached time
        }
        emit Deposit(_addr, _amount);

        if (users[_addr].upline != address(0)) {
            (uint256 _payout, ) = this.payoutOf(users[_addr].upline);
            users[users[_addr].upline].Bonus[1].direct_bonus = users[users[_addr].upline].Bonus[1].direct_bonus.add((_amount).div(10));
            _limitReached(users[_addr].upline, _payout);
            
            emit DirectPayout(users[_addr].upline, _addr, _amount.div(10));
        }
        
        if ((pool_last_draw + (1 days)) < block.timestamp) { _drawPool(); }
        
        if ((referral_last_draw + (1 days)) < block.timestamp) { _drawReferralPool(); }
        
        _pollDeposits(_addr, _amount);
        _referralDeposits(_addr, _amount);

        adminFee.transfer( ((_amount*2)/100)); // adminFee 2% fee
        platformfee.transfer(((_amount*6)/100)); // Platform 6% fee
        marketingfee.transfer(((_amount*2)/100)); // Marketing 2% fee

        if (getbalance(InsuranceContract) < 10000000 trx) {     InsuranceContract.transfer(((_amount*1)/100)); }  // Insurance Contract
    }
    
    function _limitReached(address _addr, uint _payout) internal {
        uint256 _maxpayout = this.maxPayoutOf(users[_addr].deposit_amount);
        
        if((users[_addr].deposit_payouts == _maxpayout) ){ return;}

        if(((_payout+totalIncome(_addr)) >= this.maxPayoutOf(users[_addr].total_deposits)) && (users[_addr].limitReached == users[_addr].deposit_time)){    
            users[_addr].limitReached = block.timestamp;
            users[_addr].Bonus[1].limitReachedAmount = _payout;
        }
    }
    
    function _pollDeposits(address _addr, uint256 _amount) private {

        pool_users_deposits[pool_cycle][_addr] = _amount;
        for (uint8 i = 0; i < pool_bonuses.length; i++) {
            if (pool_top[i] == _addr) break;
            if (pool_top[i] == address(0)) {
                pool_top[i] = _addr;
                break;
            }
            if (pool_users_deposits[pool_cycle][_addr] > pool_users_deposits[pool_cycle][pool_top[i]]) {
                for (uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if (pool_top[j] == _addr) {
                        for (uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }
                for (uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }
                pool_top[i] = _addr;
                break;
            }
        }
    }

    function _referralDeposits(address _addr, uint256 _amount) private {

        address upline = users[_addr].upline;
        referralBalance[upline][referral_cycle] = referralBalance[upline][referral_cycle].add(_amount);

        if (upline == address(0)) return;

        referral_userData[referral_cycle][upline] = referral_userData[referral_cycle][upline].add(1);
        for (uint8 i = 0; i < referral_bonuses.length; i++) {

            if (referral_userData[referral_cycle][upline] < 5) return;

            if (referral_top[i] == upline) {
                break;
            }

            if (referral_top[i] == address(0)) {
                referral_top[i] = upline;
                break;
            }
        }
    }

    function _downlinePayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for (uint8 i = 0; i < 20; i++) {
            if (up == address(0)) break;

            if ((users[up].referrals >= i + 1 ) || (up == masterId)) {
                uint256 _bonus = (_amount.mul((downline_bonuses[i]))).div(100);
                (uint256 _payout, ) = this.payoutOf(up);
                
                users[up].Bonus[1].downline_bonus = users[up].Bonus[1].downline_bonus.add(_bonus);
                _limitReached(up, _payout);
                emit DownlinePayout(up, _addr, _bonus);
            }
            up = users[up].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);

        for (uint8 i = 0; i < pool_bonuses.length; i++) {
            if (pool_top[i] == address(0)) break;
            uint256 draw_amount = pool_users_deposits[pool_cycle][pool_top[i]];
            uint256 win = (draw_amount.mul(pool_bonuses[i])).div(100);
            (uint256 _payout, ) = this.payoutOf(pool_top[i]);
            users[pool_top[i]].Bonus[1].pool_bonus = users[pool_top[i]].Bonus[1].pool_bonus.add(win);
            _limitReached(pool_top[i], _payout);
            emit PoolPayout(pool_top[i], win);
        }
        for (uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
        pool_cycle++;
    }

    function _drawReferralPool() private {
        referral_last_draw= uint40(block.timestamp);

        for (uint8 i = 0; i < referral_bonuses.length; i++) {
            if (referral_top[i] == address(0)) break;

            uint256 win = (referralBalance[referral_top[i]][referral_cycle].mul(referral_bonuses[i])).div(100);
            (uint256 _payout, ) = this.payoutOf(referral_top[i]);
            users[referral_top[i]].Bonus[1].referral_bonus = users[referral_top[i]].Bonus[1].referral_bonus.add(win);
            _limitReached(referral_top[i], _payout);
            emit ReferralPayout(referral_top[i], win,referralBalance[referral_top[i]][referral_cycle]);
            referralBalance[referral_top[i]][referral_cycle]= 0;
        }
        for (uint8 i = 0; i < referral_bonuses.length; i++) {
            referral_top[i] = address(0);
        }
        referral_cycle++;
    }

    function deposit(address _upline) external payable isLock {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external isLock {
        address payable _user = msg.sender; 
        (uint256 to_payout, ) = this.payoutOf(_user);

        uint256 max_payout = this.maxPayoutOf(users[_user].total_deposits);
         
        require(users[_user].payouts < max_payout, "Full payouts");
        require((users[_user].Bonus[1].lastWithdraw == 0) || (users[_user].Bonus[1].lastWithdraw.add((1 days)) < block.timestamp), "User Withdraw per days once");
        uint256 limit = 25000 trx; 
        // Deposit payout
        if ( (to_payout > 0)) {
            
            if (users[_user].payouts.add(to_payout) > max_payout) {
                to_payout = max_payout.sub(users[_user].payouts);
            }
            if(to_payout > limit) { 
                uint256 _payout = to_payout;
                to_payout = limit;
                _payout = _payout.sub(to_payout);
            }
            users[_user].payouts = users[_user].payouts.add(to_payout);
            users[_user].deposit_payouts = users[_user].deposit_payouts.add(to_payout);
            users[_user].roi = users[_user].roi+to_payout;
            
            if(users[_user].deposit_time != users[_user].limitReached){
                users[_user].Bonus[1].limitAmountReceived = users[_user].Bonus[1].limitAmountReceived.add(to_payout);
            }
            _downlinePayout(_user, to_payout);
        }
        // Direct payout
        if ((users[_user].payouts < max_payout) && (users[_user].Bonus[1].direct_bonus > 0) && to_payout < limit) {
            uint256 direct_bonus = users[_user].Bonus[1].direct_bonus;
            if (users[_user].payouts.add(direct_bonus) > max_payout) {
                direct_bonus = max_payout.sub(users[_user].payouts);
            }
            if (to_payout.add(direct_bonus) > limit) {
                direct_bonus = uint256(limit).sub(to_payout);
            }
            users[_user].Bonus[1].direct_bonus = users[_user].Bonus[1].direct_bonus.sub(direct_bonus);
            users[_user].payouts = users[_user].payouts.add(direct_bonus);
             _setDepositPayouts(_user, direct_bonus);
            to_payout = to_payout.add(direct_bonus);
        }
        // Pool payout
        if ((users[_user].payouts < max_payout) && (users[_user].Bonus[1].pool_bonus > 0) && to_payout < limit) {
            uint256 pool_bonus = users[_user].Bonus[1].pool_bonus;
            if (users[_user].payouts.add(pool_bonus) > max_payout) {
                pool_bonus = max_payout.sub(users[_user].payouts);
            }
            if (to_payout.add(pool_bonus) > limit) {
                pool_bonus = uint256(limit).sub(to_payout);
            }
            users[_user].Bonus[1].pool_bonus = users[_user].Bonus[1].pool_bonus.sub(pool_bonus);
            users[_user].payouts = users[_user].payouts.add(pool_bonus);
            to_payout = to_payout.add(pool_bonus);
            _setDepositPayouts(_user, pool_bonus);
        }
        // Downline payout
        if ((users[_user].payouts < max_payout) && (users[_user].Bonus[1].downline_bonus > 0) && to_payout < limit) {
            uint256 downline_bonus = users[_user].Bonus[1].downline_bonus;
            if (users[_user].payouts.add(downline_bonus) > max_payout) {
                downline_bonus = max_payout.sub(users[_user].payouts);
            }
            if (to_payout.add(downline_bonus) > limit) {
                downline_bonus = uint256(limit).sub(to_payout);
            }
            users[_user].Bonus[1].downline_bonus = users[_user].Bonus[1].downline_bonus.sub(downline_bonus);
            users[_user].payouts = users[_user].payouts.add(downline_bonus);
            to_payout = to_payout.add(downline_bonus);
            _setDepositPayouts(_user, downline_bonus);
        }
        // Referrnal payouts
        if ((users[_user].payouts < max_payout) && (users[_user].Bonus[1].referral_bonus > 0) && to_payout < limit) {
            uint256 referral_bonus = users[_user].Bonus[1].referral_bonus;
            if (users[_user].payouts.add(referral_bonus) > max_payout) {
                referral_bonus = max_payout.sub(users[_user].payouts);
            }
            if (to_payout.add(referral_bonus) > limit) {
                referral_bonus = uint256(limit).sub(to_payout);
            }
            users[_user].Bonus[1].referral_bonus = users[_user].Bonus[1].referral_bonus.sub(referral_bonus);
            users[_user].payouts = users[_user].payouts.add(referral_bonus);
            to_payout = to_payout.add(referral_bonus);
            _setDepositPayouts(_user, referral_bonus);
        }
        // Deposit_bonus payouts
        if ((users[_user].payouts < max_payout) && (users[_user].Bonus[1].deposit_bonus > 0) && to_payout < limit) {
            uint256 deposit_bonus = users[_user].Bonus[1].deposit_bonus;
            if (users[_user].payouts.add(deposit_bonus) > max_payout) {
                deposit_bonus = max_payout.sub(users[_user].payouts);
            }
            if (to_payout.add(deposit_bonus) > limit) {
                deposit_bonus = uint256(limit).sub(to_payout);
            }
            users[_user].Bonus[1].deposit_bonus = users[_user].Bonus[1].deposit_bonus.sub(deposit_bonus);
            users[_user].payouts = users[_user].payouts.add(deposit_bonus);
            to_payout = to_payout.add(deposit_bonus);
        }
        // Luckydraw payouts
        if ((users[_user].payouts < max_payout) && (gameBalance[_user] > 0) && to_payout < limit) {
            uint256 gameBonus = gameBalance[_user];
            if (users[_user].payouts.add(gameBonus) > max_payout) {
                gameBonus = max_payout.sub(users[_user].payouts);
            }
            if (to_payout.add(gameBonus) > limit) {
                gameBonus = limit.sub(to_payout);
            }
            if (_luckydrawInstance.sendPrice(gameBonus)) {
                gameBalance[_user] = gameBalance[_user].sub(gameBonus);
                users[_user].payouts = users[_user].payouts.add(gameBonus);
                to_payout = to_payout.add(gameBonus);
            }
          _setDepositPayouts(_user, gameBonus);
        }
        require(to_payout > 0, "Zero payout");
        users[_user].total_payouts += to_payout;
        total_withdraw += to_payout;
        users[_user].withdraw_time = block.timestamp;
        users[_user].Bonus[1].lastWithdraw = block.timestamp;
        uint256 contractBalance = getbalance(address(this));

        if ((to_payout > contractBalance) && (users[_user].depositCycle == 1)) {
            _insuranceInstance.sendCryptoBank(to_payout);
            _user.transfer(to_payout.sub(((to_payout*1)/100)));
        }else {
            _user.transfer(to_payout.sub( ((to_payout*1)/100)));
        }
        if (getbalance(InsuranceContract) < 10000000 trx) {
            InsuranceContract.transfer(((to_payout*1)/100)); // Insurance Contract
        }
 
        emit Withdraw(_user, to_payout);

        if (users[_user].payouts >= max_payout) {
            emit LimitReached(_user, users[_user].payouts);
        }
    }
    
    function _setDepositPayouts(address _addr, uint256 _bonus) internal {
        if(users[_addr].deposit_payouts < this.maxPayoutOf(users[_addr].deposit_amount) ){
           if(users[_addr].deposit_payouts+_bonus <= this.maxPayoutOf(users[_addr].deposit_amount)){
                users[_addr].deposit_payouts = users[_addr].deposit_payouts+_bonus;
            }
            else if(users[_addr].deposit_payouts+_bonus > this.maxPayoutOf(users[_addr].deposit_amount)){
                users[_addr].deposit_payouts = this.maxPayoutOf(users[_addr].deposit_amount);
            }
        }
    }

    function luckDrawContest() external payable isLock {
        require( status == false , "paused");
        require(users[msg.sender].total_deposits > 0, "Invalid");
       // User Wallet Investment
        require((msg.value.mod(100 trx) == 0) && (msg.value >= 100 trx), "invalid Amount");
        LuckyDrawContract.transfer(msg.value); // Lucky Draw Contract
        _luckydrawInstance.participate(msg.sender, msg.value);// Lucky Draw participate
    }
    
    function masterWithdraw() public{
        address _user = msg.sender; 
        require(masterId == _user, "invalid");
      
        uint256 limit = 25000 trx; 
        uint256 to_payout;
        // Direct payout
        uint256 direct_bonus = users[_user].Bonus[1].direct_bonus;
        if (to_payout.add(direct_bonus) > limit) {
            direct_bonus = uint256(limit).sub(to_payout);
        }
        users[_user].Bonus[1].direct_bonus = users[_user].Bonus[1].direct_bonus.sub(direct_bonus);
        to_payout = to_payout.add(direct_bonus);
        
        // Downline payout
        uint256 downline_bonus = users[_user].Bonus[1].downline_bonus;
        if (to_payout.add(downline_bonus) > limit) {
            downline_bonus = uint256(limit).sub(to_payout);
        }
        users[_user].Bonus[1].downline_bonus = users[_user].Bonus[1].downline_bonus.sub(downline_bonus);
        to_payout = to_payout.add(downline_bonus);
        
        // Referrnal payouts
        uint256 referral_bonus = users[_user].Bonus[1].referral_bonus;
        if (to_payout.add(referral_bonus) > limit) {
            referral_bonus = uint256(limit).sub(to_payout);
        }
        users[_user].Bonus[1].referral_bonus = users[_user].Bonus[1].referral_bonus.sub(referral_bonus);
        to_payout = to_payout.add(referral_bonus);
        
        require(to_payout > 0, "Zero payout");
        total_withdraw += to_payout;
        masterId.transfer(to_payout);
    
        emit Withdraw(_user, to_payout);
    }

    function luckyDrawPriceDistrube(uint256[]memory userID, uint _gameID) public platform {
        _luckydrawInstance.priceDistribute(userID, _gameID);
    }

    function maxPayoutOf(uint256 _amount) external pure returns(uint256) {
        return (_amount.mul(30)).div(10);
    }

    function payoutOf(address _addr) external view returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
        
        if(users[_addr].deposit_time == users[_addr].limitReached){
            uint256 _totalIncome = totalIncome(_addr);
            
            if ((users[_addr].deposit_payouts < max_payout)) {
                uint256 ctime = block.timestamp;
                
                if(ctime > (users[_addr].deposit_time.add(150 days))){ ctime = users[_addr].deposit_time.add(150 days); } //150 days; 
                
                payout = (users[_addr].deposit_amount.mul((ctime.sub(users[_addr].deposit_time)).div( (1 days))).div(50)).sub(users[_addr].roi);
                
                if (users[_addr].deposit_payouts.add(payout) > max_payout) { payout = max_payout.sub(users[_addr].deposit_payouts); }
                
                if ((_totalIncome + payout) > this.maxPayoutOf(users[_addr].total_deposits)){
                    uint256 _payout = this.maxPayoutOf(users[_addr].total_deposits) - _totalIncome;
                
                    if(_payout < payout){  payout = _payout; }
                }
            }
            
            return (payout,max_payout);    
        }
        else{
                if(users[_addr].Bonus[1].limitAmountReceived >= users[_addr].Bonus[1].limitReachedAmount) { return (payout,max_payout); }
                
                payout = users[_addr].Bonus[1].limitReachedAmount.sub(users[_addr].Bonus[1].limitAmountReceived);
                return (payout,max_payout);
            }
    }
    
    function totalIncome(address _addr) public view returns(uint256 total) {
        return (users[_addr].payouts+users[_addr].Bonus[1].direct_bonus+users[_addr].Bonus[1].pool_bonus+users[_addr].Bonus[1].downline_bonus+ users[_addr].Bonus[1].referral_bonus+users[_addr].Bonus[1].deposit_bonus+ gameBalance[_addr]);
    }
    
    function setStaus(bool _status) public platform {
        lockStatus = _status;
    }
    
    function price(address _addr, uint _amount) public contractOnly{
        (uint256 _payout, ) = this.payoutOf(_addr);
        gameBalance[_addr] += _amount;
        _limitReached(_addr, _payout);
    }

    function setLuckDrawStaus(bool _status) public platform {
        status = _status;
    }
    
    function userInfo(address _addr) external view returns(address upline, uint256 deposit_amount, uint256 payouts) {
        return (users[_addr].upline, users[_addr].deposit_amount, users[_addr].payouts);
    }

    function bonusInfo(address _addr) external view returns(uint256 directbonus, uint256 poolbonus, uint256 downlinebonus, uint256 refbonus, uint256 depositBonus, uint256 luckyDraw,uint256 limitReachedAmount) {
        return (users[_addr].Bonus[1].direct_bonus, users[_addr].Bonus[1].pool_bonus, users[_addr].Bonus[1].downline_bonus, users[_addr].Bonus[1].referral_bonus, users[_addr].Bonus[1].deposit_bonus, gameBalance[_addr],users[_addr].Bonus[1].limitReachedAmount);
    }

    function limitReachedInfo(address _addr) external view returns( uint256 limitReachedAmount, uint256 lastWithdraw) {
        return (users[_addr].Bonus[1].limitReachedAmount,users[msg.sender].Bonus[1].lastWithdraw);
    }

    function userInfoTotals(address _addr) external view returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts);
    }

    function contractInfo() external view returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _pool_last_draw, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw,  pool_users_deposits[pool_cycle][pool_top[0]]);
    }

    function availableEarnings(address _user) public view returns(uint) {
        (uint256 to_payout, ) = this.payoutOf(_user);

        uint _totalEarnings = users[_user].Bonus[1].direct_bonus;
        _totalEarnings = _totalEarnings.add(users[_user].Bonus[1].pool_bonus);
        _totalEarnings = _totalEarnings.add(users[_user].Bonus[1].downline_bonus);
        _totalEarnings = _totalEarnings.add(users[_user].Bonus[1].referral_bonus);
        _totalEarnings = _totalEarnings.add(gameBalance[_user]);
        _totalEarnings = _totalEarnings.add(users[_user].Bonus[1].deposit_bonus);
        _totalEarnings = _totalEarnings.add(to_payout);
        _totalEarnings = _totalEarnings.add(users[_user].payouts);

        return _totalEarnings;
    }
    
    function available(address _user) public view returns(uint) {
        (uint256 to_payout, ) = this.payoutOf(_user);

        uint _totalEarnings = users[_user].Bonus[1].direct_bonus;
        _totalEarnings = _totalEarnings.add(users[_user].deposit_payouts);
        _totalEarnings = _totalEarnings.add(users[_user].Bonus[1].pool_bonus);
        _totalEarnings = _totalEarnings.add(users[_user].Bonus[1].downline_bonus);
        _totalEarnings = _totalEarnings.add(users[_user].Bonus[1].referral_bonus);
        _totalEarnings = _totalEarnings.add(gameBalance[_user]);
        _totalEarnings = _totalEarnings.add(to_payout);

        return _totalEarnings;
    }

    function poolTopInfo() external view  returns(address[4] memory addrs, uint256[4] memory deps) {
        for (uint8 i = 0; i < pool_bonuses.length; i++) {
            if (pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_deposits[pool_cycle][pool_top[i]];
        }
    }
    
    function referralsTopInfo() external view  returns(address[4] memory addrs, uint256[4] memory refr) {
        for (uint8 i = 0; i < referral_bonuses.length; i++) {
            if (referral_top[i] == address(0)) break;

            addrs[i] = referral_top[i];
            refr[i] = referral_userData[referral_cycle][referral_top[i]];
        }
    }
    
    function getbalance(address _addr)public view returns(uint256)   {
        return _addr.balance;
    }
}