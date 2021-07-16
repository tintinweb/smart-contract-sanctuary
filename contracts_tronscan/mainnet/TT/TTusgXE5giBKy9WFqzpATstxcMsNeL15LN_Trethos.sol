//SourceUnit: trethose_update.sol

pragma solidity 0.5.8;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Trethos {
    using SafeMath for  uint;
    
    struct User { // user struct
        uint256 cycle; // deposit cycles
        address upline; // referrer
        uint256 referrals; // referrals count
        mapping(uint256 => uint256) payouts; // payout of deposits by cycle
        uint256 direct_bonus; // referral bonus
        uint256 hold_bonus; // matching bonus
        mapping(uint256 => uint256) deposit_amount; // deposit amount by cycle
        uint256 currentCycle; // current deposit cycle
        mapping(uint256 => uint256) deposit_payouts;  // deposit payout by cycle
        mapping(uint256 => uint256) deposit_time; // deposit time by cycle
        uint256 total_deposits; // total deposits
        uint256 total_payouts; // total payout received
        uint256 total_structure; // total upline structures
    }

    address public ownerWallet; // ownerWallet
    address public distributor; // distributor address
    
    uint public minimum_deposit = 250e6; // minimum deposit
    uint public total_withdraw; // contract total withdraw
    uint public lastFeeDistribution = now+21600; 
    uint public communityPool;
    uint public MAX_LIMIT = 25000000e6;
    
    
    
    
    uint[] public cycles = [2e11,5e11,1e12,12e11,15e11,17e11,2e12,2e12,22e11,25e12];
    uint[] public managementFee = [35e5,35e5,25e5,2e6,1e6,1e6];
    uint[] public level = [10,40,70,99,100];
    
    mapping(address => User) public users;
    mapping(uint => mapping(uint => uint)) public levelPrice;
    // mapping(uint => uint) public level;
    mapping(uint => uint) public managementPool;
    
    mapping(uint => address) public management_fee_Wallet;
    mapping(uint => address) public community_fee_Wallet;
    
    
    event Upline(address indexed addr, address indexed upline, uint _downline, uint _level, uint _amount, uint _time);
    event setUpline(address indexed addr, address indexed upline, uint _level, uint _time);
    event NewDeposit(address indexed addr, uint256 amount, uint _time);
    event Withdraw(address indexed addr, uint dailyPayout, uint directBonus, uint holdBonus, uint256 amount, uint _time);
    event LimitReached(address indexed addr, uint256 amount, uint _time);
    event managementFeeEvent(address indexed addr, uint amount, uint time);
    event communityFeeEvent(address indexed addr, uint amount, uint time);
    
    constructor( address _distributor) public {
        ownerWallet = msg.sender;
        distributor = _distributor;
        
        // levels %
        // level - 1
        levelPrice[1][1] = 5e6;
        levelPrice[1][2] = 2e6;
        levelPrice[1][3] = 1e6;
        levelPrice[1][4] = 1e6;
        levelPrice[1][5] = 5e5;
        levelPrice[1][6] = 25e4;
        levelPrice[1][7] = 25e4;
        
        // level - 2
        levelPrice[2][1] = 75e5;
        levelPrice[2][2] = 2e6;
        levelPrice[2][3] = 1e6;
        levelPrice[2][4] = 1e6;
        levelPrice[2][5] = 5e5;
        levelPrice[2][6] = 25e4;
        levelPrice[2][7] = 25e4;
        
        // level - 3
        levelPrice[3][1] = 1e7;
        levelPrice[3][2] = 2e6;
        levelPrice[3][3] = 1e6;
        levelPrice[3][4] = 1e6;
        levelPrice[3][5] = 5e5;
        levelPrice[3][6] = 25e4;
        levelPrice[3][7] = 25e4;
        
        // level - 4
        levelPrice[4][1] = 125e5;
        levelPrice[4][2] = 2e6;
        levelPrice[4][3] = 1e6;
        levelPrice[4][4] = 1e6;
        levelPrice[4][5] = 5e5;
        levelPrice[4][6] = 25e4;
        levelPrice[4][7] = 25e4;
        
        // level - 5
        levelPrice[5][1] = 15e6;
        levelPrice[5][2] = 2e6;
        levelPrice[5][3] = 1e6;
        levelPrice[5][4] = 1e6;
        levelPrice[5][5] = 5e5;
        levelPrice[5][6] = 25e4;
        levelPrice[5][7] = 25e4;
    }

    function setDistributor(address _distributor) public returns(bool){
        require(msg.sender == ownerWallet, "Only owner wallet");
        distributor = _distributor;
        return true;
    }
    
    function setManagementWallets(address[] memory _management_fee_Wallet) public returns(bool){
        require(msg.sender == ownerWallet, "Only owner wallet");
        management_fee_Wallet[1] = _management_fee_Wallet[0];
        management_fee_Wallet[2] = _management_fee_Wallet[1];
        management_fee_Wallet[3] = _management_fee_Wallet[2];
        management_fee_Wallet[4] = _management_fee_Wallet[3];
        management_fee_Wallet[5] = _management_fee_Wallet[4];
        management_fee_Wallet[6] = _management_fee_Wallet[5];
        
        return true;
    }
    
    function setCommunityWallets(address[] memory _community_fee_Wallet) public returns(bool){
        require(msg.sender == ownerWallet, "Only owner wallet");
        community_fee_Wallet[1] = _community_fee_Wallet[0];
        community_fee_Wallet[2] = _community_fee_Wallet[1];
        community_fee_Wallet[3] = _community_fee_Wallet[2];
        community_fee_Wallet[4] = _community_fee_Wallet[3];
        community_fee_Wallet[5] = _community_fee_Wallet[4];
        community_fee_Wallet[6] = _community_fee_Wallet[5];
        community_fee_Wallet[7] = _community_fee_Wallet[6];
        community_fee_Wallet[8] = _community_fee_Wallet[7];
        community_fee_Wallet[9] = _community_fee_Wallet[8];
        community_fee_Wallet[10] = _community_fee_Wallet[9];
        
        return true;
    }
    
    
    function deposit(address _upline) external payable  {
        require(contractCheck(msg.sender) == 0, "cannot be a contract");
        
        _setUpline(msg.sender, _upline, msg.value);
        _deposit(msg.sender, msg.value);
    }
    
    function withdraw() external  {
        require(contractCheck(msg.sender) == 0, "cannot be a contract");
        
        (uint256 to_payout, uint256 max_payout, uint256 _hold_bonus) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts[users[msg.sender].currentCycle] < max_payout, "Full payouts");
        uint[3] memory incomes;
        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts[users[msg.sender].currentCycle].add(to_payout) > max_payout) {
                to_payout = max_payout.sub(users[msg.sender].payouts[users[msg.sender].currentCycle]);
            }
            
            users[msg.sender].deposit_payouts[users[msg.sender].currentCycle] = users[msg.sender].deposit_payouts[users[msg.sender].currentCycle].add(to_payout);
            incomes[0] = to_payout;
            users[msg.sender].payouts[users[msg.sender].currentCycle] = users[msg.sender].payouts[users[msg.sender].currentCycle].add(to_payout);
            users[msg.sender].deposit_time[users[msg.sender].currentCycle] = now;
            
            if(_hold_bonus > 0)
                users[msg.sender].hold_bonus = users[msg.sender].hold_bonus.add(_hold_bonus); // 0.1 % holding bonus
        }
        
        // Direct payout
        if((users[msg.sender].payouts[users[msg.sender].currentCycle] < max_payout) && (users[msg.sender].direct_bonus > 0)) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts[users[msg.sender].currentCycle].add(direct_bonus) > max_payout) {
                direct_bonus = max_payout.sub(users[msg.sender].payouts[users[msg.sender].currentCycle]);
            }

            users[msg.sender].direct_bonus = users[msg.sender].direct_bonus.sub(direct_bonus);
            users[msg.sender].payouts[users[msg.sender].currentCycle] = users[msg.sender].payouts[users[msg.sender].currentCycle].add(direct_bonus);
            to_payout = to_payout.add(direct_bonus);
            incomes[1] = direct_bonus;
        }

        // hold_bonus
        if((users[msg.sender].payouts[users[msg.sender].currentCycle] < max_payout) && (users[msg.sender].hold_bonus > 0)) {
            uint256 hold_bonus = users[msg.sender].hold_bonus;

            if(users[msg.sender].payouts[users[msg.sender].currentCycle].add(hold_bonus) > max_payout) {
                hold_bonus = max_payout.sub(users[msg.sender].payouts[users[msg.sender].currentCycle]);
            }

            users[msg.sender].hold_bonus = users[msg.sender].hold_bonus.sub(hold_bonus);
            users[msg.sender].payouts[users[msg.sender].currentCycle] = users[msg.sender].payouts[users[msg.sender].currentCycle].add(hold_bonus);
            to_payout = to_payout.add(hold_bonus);
            incomes[2] = hold_bonus;
        }

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts = users[msg.sender].total_payouts.add(to_payout);
        total_withdraw = total_withdraw.add(to_payout);

        address(uint160(msg.sender)).transfer(to_payout);

        emit Withdraw(msg.sender, incomes[0], incomes[1], incomes[2], to_payout, now);

        if(users[msg.sender].payouts[users[msg.sender].currentCycle] >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts[users[msg.sender].currentCycle], now);
            users[msg.sender].currentCycle++;
        }
    }
    
    function managementBonusAndCommunityManagerFee() external returns(bool){
        require(distributor != address(0),"Distributor address is not set");
        require(msg.sender == distributor, "only distributor");
        require(lastFeeDistribution <= now, "time didnt expired");
        
        distributeManagementBonus();
        distributeCommunityFee();
        
        lastFeeDistribution = now+21600;
    }
    
    function maxPayoutOf(uint256 _amount) external pure returns(uint256) {
        return _amount.mul(230e5).div(1e7); // maximum payout is set to 218 %
    }

    function payoutOf(address _addr) external view returns(uint256 payout, uint256 max_payout, uint256 holdingBonus) { // 1 daily ROI
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount[users[_addr].currentCycle]);

        if(users[_addr].deposit_payouts[users[msg.sender].currentCycle] < max_payout) {
            uint _days = ((block.timestamp.sub(users[_addr].deposit_time[users[msg.sender].currentCycle])).div(1 days));
            payout = (((users[_addr].deposit_amount[users[_addr].currentCycle].mul(15e5)).div(1e8)).mul(_days));
            
            uint holdBonusOneDay = ((users[_addr].deposit_amount[users[_addr].currentCycle].mul(1e5)).div(1e8));
            
            if(users[_addr].deposit_payouts[users[_addr].currentCycle].add(payout) > max_payout) {
                payout = max_payout.sub(users[_addr].deposit_payouts[users[_addr].currentCycle]);
            }
            
            if(_days > 0){
                _days = _days.sub(1);
                holdingBonus = holdBonusOneDay.mul(_days);
            }
        }
    }
    
    function userInfo(address _user, uint _cycle) external view returns(uint _deposit, uint deposit_payout, uint payout, uint deposit_time, uint total_deposits, uint total_payouts){
        return(users[_user].deposit_amount[_cycle], users[_user].deposit_payouts[_cycle], users[_user].payouts[_cycle],users[_user].deposit_time[_cycle], users[_user].total_deposits, users[_user].total_payouts);
    }
    
    function contractCheck(address _user) public view returns(uint){
        uint32 size;
        
        assembly {
            size := extcodesize(_user)
        }
        
        return size;
    }
    
    function addCycles( uint _cycleLimit) external returns(bool){
        require(msg.sender == ownerWallet, "only ownerWallet");
        require(_cycleLimit > 0, "_cycleLimit must be greather than zero");
        require(_cycleLimit > cycles[cycles.length-1], "_cycleLimit must be greather than previous cycle");
        
        cycles.push(_cycleLimit);
        
        return true;
    }
    
    function distributeManagementBonus( ) internal returns(bool){
        for(uint i=1;i<7;i++){
            if(management_fee_Wallet[i] != address(0)){
                require(address(uint160(management_fee_Wallet[i])).send(managementPool[i]), "management fee transfer failed");                
                emit managementFeeEvent( management_fee_Wallet[i], managementPool[i], now);
                managementPool[i] = 0;
            }
        }
        
        return true;
    }
    
    function distributeCommunityFee() internal returns(bool){
        require(communityPool > 0, "amount must be greather than zero");
         
        uint communityCommission = communityPool.div(10);
        for(uint i=1;i<=10;i++){   
            if(community_fee_Wallet[i] != address(0)){
                require(address(uint160(community_fee_Wallet[i])).send(communityCommission), "management fee transfer failed");
                communityPool = communityPool.sub(communityCommission);
                emit communityFeeEvent( community_fee_Wallet[i], communityCommission, now);
            }
        }
        
        return true;
    }
    
    function checkReferralCount( address _addr) public view returns(uint){
        
        if(users[_addr].referrals >= 0 && users[_addr].referrals <= level[0])
            return 1;
        else if(users[_addr].referrals > level[0] && users[_addr].referrals <= level[1])
            return 2;
        else if(users[_addr].referrals > level[1] && users[_addr].referrals <= level[2])
            return 3;
        else if(users[_addr].referrals > level[2] && users[_addr].referrals <= level[3])
            return 4;
        else if(users[_addr].referrals > level[3] && users[_addr].referrals <= level[4])
            return 5;
        else 
            return 5;
    }
    
    function distributeManagementFeePool( uint _amount) internal returns(bool){
        require( _amount > 0, "amount must be greather than zero");
        
        for(uint i=1;i<7;i++){
            managementPool[i] = managementPool[i].add(_amount.mul(managementFee[i-1]).div(1e8));
        }
        
        return true;
    }
    
    function _setUpline(address _addr, address _upline, uint256 _amount) private { // set 15 generation
        if(users[_addr].upline == address(0) && _upline != _addr && (users[_upline].deposit_time[0] > 0 || _upline == ownerWallet)) { 
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            
            for(uint8 i = 1; i <= 7; i++) {
                if(_upline == address(0)) break;
                
                users[_upline].total_structure++;
                emit setUpline( _addr, _upline, i, now);
                
                _upline = users[_upline].upline;
            }
        }    
        
        _upline = users[_addr].upline;

        for(uint8 i = 1; i <= 7; i++) {
            if(_upline == address(0)) break;
            
            uint _level = checkReferralCount( _upline);
            
            users[_upline].direct_bonus = users[_upline].direct_bonus.add(_amount.mul(levelPrice[_level][i]).div(1e8)); 
            
            emit Upline(_addr, _upline, i, _level, _amount.mul(levelPrice[_level][i]).div(1e8), now);

            _upline = users[_upline].upline;
        }
        
    }

    function _deposit(address _addr, uint256 _amount) private {  // user deposit and pool money distribution
        require(users[_addr].upline != address(0) || _addr == ownerWallet, "No upline");
        require((users[_addr].total_deposits+_amount) <= MAX_LIMIT, "user exist deposit maximum limit");

	   // require(users[_addr].cycle < 50, "Deposit limit reached");

        if(users[_addr].cycle > 0)
            require(_amount >= users[_addr].deposit_amount[users[_addr].cycle-1] && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Deposit must be greather than the previous one");
        else require(_amount >= minimum_deposit && _amount <= cycles[0], "Bad amount");
        
        users[_addr].deposit_amount[users[_addr].cycle] = _amount; // deposit to current cycle.
        users[_addr].deposit_time[users[_addr].cycle] = uint40(block.timestamp);
        users[_addr].total_deposits = users[_addr].total_deposits.add(_amount);
        
        users[_addr].cycle++;
        
        distributeManagementFeePool( _amount);
        
        communityPool = communityPool.add(_amount.mul(25e5).div(1e8));
        
        emit NewDeposit(_addr, _amount, now);
    }
    
}