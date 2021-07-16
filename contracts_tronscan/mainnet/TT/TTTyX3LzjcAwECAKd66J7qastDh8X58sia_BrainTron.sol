//SourceUnit: braintron.sol

pragma solidity 0.5.10;
contract BrainTron {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 Destiny_Bonus;
        uint40 deposit_time;
        uint256 DROI;
        uint256 DLimit;
    }
    struct usertots
    {
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 HrAmtreferrals;  
        uint256 total_PoolBonus;
        uint256 total_DestinyBonus;
        uint256 LvlIncD;
    }
    struct UsersROI {
    uint40 ROI1ON;
    uint40 ROI2ON;
    uint40 ROI3ON;
    uint40 ROI4ON;
    uint40 ROI5ON;
    }
    address payable public owner;
    address payable public BTron_fund;
    address payable public developer_fee;
    address payable public admin_fee;

    mapping(address => User) public users;
    mapping(address => UsersROI) public usersR;
    mapping(address => usertots) public userTot;
    
    uint256[] public cycles;
    uint256[] public ref_bonuses;

    uint256[] public Daily_ROI; 
    uint256[] public Daily_ROILimit;  
    
    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    //destiny
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sumD;
    mapping(uint256 =>mapping(uint8 => address)) public pool_topD;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount,uint256 LvlNo, uint256 Refs);
    event MissedLevelPayout(address indexed addr, address indexed from, uint256 amount,uint256 LvlNo, uint256 Refs);
    event PoolPayout(address indexed addr, uint256 amount);
    event DestinyPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event WithdrawROIU(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event ownershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DailyROIper(address indexed addr,uint256 indexed R1,uint256 indexed R2, uint256 R3,uint256 R4, uint256 R5);
  
  modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }
    constructor(address payable _owner,address payable _BrainF,address payable _AdminFund,address payable _DevFund) public {
        owner = _owner;
        BTron_fund = _BrainF;
        admin_fee = _AdminFund;
        developer_fee = _DevFund;
        
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
       
        Daily_ROILimit.push(300);
        Daily_ROILimit.push(350);
        Daily_ROILimit.push(400);
        Daily_ROILimit.push(400);
        Daily_ROILimit.push(400);
 
        pool_bonuses.push(40);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);
        
        cycles.push(500);
        cycles.push(1000);
    }

    function() payable external {
        _deposit(msg.sender, msg.value);
    }
    
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

    function _deposit(address _addr, uint256 _amount) private {
        //
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        //
        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= users[_addr].DLimit, "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount, "Bad amount");
            require(_amount == cycles[0] || (_amount%cycles[1])==0, "Bad amount");
        }
        else require(_amount == cycles[0] || (_amount%cycles[1])==0, "Bad amount");
        //
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        userTot[_addr].total_deposits += _amount;
        //
        userTot[_addr].HrAmtreferrals=0;
        userTot[_addr].LvlIncD=0;
        //
        uint256 upldepo=users[users[_addr].upline].deposit_amount;
        //
        if (_amount>=upldepo)
        {
        userTot[users[_addr].upline].HrAmtreferrals+=1;
        }
        //
        users[_addr].DROI=1;
        users[_addr].DLimit=users[_addr].deposit_amount*Daily_ROILimit[0]/100;
        usersR[_addr].ROI1ON=uint40(block.timestamp);
        usersR[_addr].ROI2ON=0;
        usersR[_addr].ROI3ON=0;
        usersR[_addr].ROI4ON=0;
        usersR[_addr].ROI5ON=0;
        //
        total_deposited += _amount;
        //    update Upline ROI   
       _updateUplineROI(_addr);
        //
        emit NewDeposit(_addr, _amount);
       
        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += (_amount* 5)/100;
            emit DirectPayout(users[_addr].upline, _addr, (_amount* 5)/100);
        }

        _pollDeposits(_addr, _amount);
        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        BTron_fund.transfer(_amount * 4/ 100);
        admin_fee.transfer(_amount * 4/ 100);
        developer_fee.transfer(_amount * 4/ 100);
    }
    //
    function _updateUplineROI(address _addr) private {
        for(uint8 i = 1; i <=4; i++) {
            if(userTot[users[_addr].upline].HrAmtreferrals >= i*4) {
                if (users[users[_addr].upline].DROI<(i + 1))
                {
                users[users[_addr].upline].DLimit=users[users[_addr].upline].deposit_amount*Daily_ROILimit[i]/100;
                users[users[_addr].upline].DROI=i + 1;
                if((i + 1)==2 && usersR[users[_addr].upline].ROI2ON==0)
                {
                usersR[users[_addr].upline].ROI2ON=uint40(block.timestamp);
                }
                if((i + 1)==3 && usersR[users[_addr].upline].ROI3ON==0)
                {
                usersR[users[_addr].upline].ROI3ON=uint40(block.timestamp);
                }
                if((i + 1)==4 && usersR[users[_addr].upline].ROI4ON==0)
                {
                usersR[users[_addr].upline].ROI4ON=uint40(block.timestamp);
                }
                if((i + 1)==5 && usersR[users[_addr].upline].ROI5ON==0)
                {
                usersR[users[_addr].upline].ROI5ON=uint40(block.timestamp);
                }
                }
            }
        }
    }
    //
    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += (_amount * 3) / 100;

        address upline = users[_addr].upline;
        if(upline == address(0)) return;
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                //Destiny
                pool_users_refs_deposits_sumD[pool_cycle][_addr] = _amount;
                pool_topD[pool_cycle][0] = _addr;
                //
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                //Destiny
                pool_users_refs_deposits_sumD[pool_cycle][_addr] = _amount;
                pool_topD[pool_cycle][0] = _addr;
                //
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;
                break;
            }
            
        }
    }
    //
    function _refPayout(address _addr, uint256 _amount) private {
        
        address up = users[_addr].upline;
        uint256 r1 = 0;
        uint256 rb=0;
        uint256 bonus=0;
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
          //  if(up == address(0)) break;
          bonus=0;
          rb=0;
          
            rb=users[up].referrals;
            if (up != address(0))
            {
            if (rb>=15) {rb=i + 1;}
            if(rb >= i + 1) {
                bonus = (_amount * ref_bonuses[i]) / 100;
                users[up].match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus,i,rb);
            }
                else 
                { r1+=(_amount * ref_bonuses[i]) / 100;
                 // emit MissedLevelPayout(up, _addr, (_amount * ref_bonuses[i]) / 100,i,rb);
                }
            }
            else 
            {
                r1+=(_amount * ref_bonuses[i]) / 100;
               // emit MissedLevelPayout(up, _addr, (_amount * ref_bonuses[i]) / 100,i,rb);
            }
            up = users[up].upline;
        }
        //
        if (address(this).balance >= r1)
        {
        owner.transfer(r1);
        }
    }
    
    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = (pool_balance*20) /100;
        uint256 draw_amountD = (pool_balance*1) /100;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = (draw_amount * pool_bonuses[i]) / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;
            
            //destiny
            if (pool_cycle==0)
            {
            users[pool_topD[pool_cycle][0]].Destiny_Bonus += draw_amountD;
            pool_balance -= draw_amountD;
            emit DestinyPayout(pool_topD[pool_cycle][0], draw_amountD);
            }
            if (pool_cycle>0)
            {
            users[pool_topD[pool_cycle-1][0]].Destiny_Bonus += draw_amountD;
            pool_balance -= draw_amountD;
            emit DestinyPayout(pool_topD[pool_cycle-1][0], draw_amountD);
            }
            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");
        
        uint256 to_payoutpd=0;
        // Deposit payout
        if(to_payout > 0) {
            
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }
            //
            if (users[msg.sender].deposit_amount <= (users[msg.sender].deposit_payouts+to_payout) && userTot[msg.sender].LvlIncD==0)
            {
            _refPayout(msg.sender, (users[msg.sender].deposit_amount-users[msg.sender].deposit_payouts));
            userTot[msg.sender].LvlIncD=1;
            }
            else if (users[msg.sender].deposit_amount > users[msg.sender].deposit_payouts)
            {
            _refPayout(msg.sender, to_payout);
            }
            //
            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;
            //
        }
        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }
        // Pool payout
        if(users[msg.sender].pool_bonus > 0) {
        uint256 pool_bonus = users[msg.sender].pool_bonus;
        users[msg.sender].pool_bonus -= pool_bonus;
        userTot[msg.sender].total_PoolBonus += pool_bonus;
        to_payout += pool_bonus;
        to_payoutpd+=pool_bonus;
        }
        // Destiny payout
        if(users[msg.sender].Destiny_Bonus > 0) {
        uint256 destiny_Bonus = users[msg.sender].Destiny_Bonus;
        users[msg.sender].Destiny_Bonus -= destiny_Bonus;
        userTot[msg.sender].total_DestinyBonus += destiny_Bonus;
        to_payout += destiny_Bonus;
        to_payoutpd+=destiny_Bonus;
        }
        //Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;
            if(users[msg.sender].payouts + match_bonus > max_payout) {
             match_bonus = max_payout - users[msg.sender].payouts;
            }
          users[msg.sender].match_bonus -= match_bonus;
          users[msg.sender].payouts += match_bonus;
          to_payout += match_bonus;
        }
        //
        if (to_payout>0)
        {
        require(to_payout > 0, "Zero payout");
        
        userTot[msg.sender].total_payouts += (to_payout-to_payoutpd);
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
        }
    }
  function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout=0;
        max_payout =users[_addr].DLimit; //this.maxPayoutOf(users[_addr].deposit_amount,_addr); 
        if(users[_addr].deposit_payouts < max_payout) {
                 uint256 ROI1=0;
                 uint256 ROI2=0;
                 uint256 ROI3=0;
                 uint256 ROI4=0;
                 uint256 ROI5=0;
                 payout=0;
               // emit DailyROIper(_addr,ROI1,ROI2,ROI3,ROI4,ROI5);
            if (users[_addr].DROI==1)
            {
            payout = (((users[_addr].deposit_amount*users[_addr].DROI)/ 100)*((block.timestamp - users[_addr].deposit_time) / 1 days)) - users[_addr].deposit_payouts;
            }
           
            else if (users[_addr].DROI==2)
            {
            ROI1=(users[_addr].deposit_amount * ((usersR[_addr].ROI2ON - users[_addr].deposit_time) / 1 days) / 100 * 1);
            ROI2=(users[_addr].deposit_amount * ((block.timestamp - usersR[_addr].ROI2ON) / 1 days) / 100 * 2);
           
            payout = (ROI1+ROI2) - users[_addr].deposit_payouts;
            }
            else if (users[_addr].DROI==3)
            {
            ROI1=(users[_addr].deposit_amount * ((usersR[_addr].ROI2ON - users[_addr].deposit_time) / 1 days) / 100 * 1);
            ROI2=(users[_addr].deposit_amount * ((usersR[_addr].ROI3ON - usersR[_addr].ROI2ON) / 1 days) / 100 * 2);
            ROI3=(users[_addr].deposit_amount * ((block.timestamp - usersR[_addr].ROI3ON) / 1 days) / 100 * 3);
            
            payout = (ROI1+ROI2+ROI3) - users[_addr].deposit_payouts;
            }
            else if (users[_addr].DROI==4)
            {
            ROI1=(users[_addr].deposit_amount * ((usersR[_addr].ROI2ON - users[_addr].deposit_time) / 1 days) / 100 * 1);
            ROI2=(users[_addr].deposit_amount * ((usersR[_addr].ROI3ON - usersR[_addr].ROI2ON) / 1 days) / 100 * 2);
            ROI3=(users[_addr].deposit_amount * ((usersR[_addr].ROI4ON - usersR[_addr].ROI3ON) / 1 days) / 100 * 3);
            ROI4=(users[_addr].deposit_amount * ((block.timestamp - usersR[_addr].ROI4ON) / 1 days) / 100 * 4);
            
            payout = (ROI1+ROI2+ROI3+ROI4) - users[_addr].deposit_payouts;
            }
            else if (users[_addr].DROI==5)
            {
            ROI1=(users[_addr].deposit_amount * ((usersR[_addr].ROI2ON - users[_addr].deposit_time) / 1 days) / 100 * 1);
            ROI2=(users[_addr].deposit_amount * ((usersR[_addr].ROI3ON - usersR[_addr].ROI2ON) / 1 days) / 100 * 2);
            ROI3=(users[_addr].deposit_amount * ((usersR[_addr].ROI4ON - usersR[_addr].ROI3ON) / 1 days) / 100 * 3);
            ROI3=(users[_addr].deposit_amount * ((usersR[_addr].ROI5ON - usersR[_addr].ROI4ON) / 1 days) / 100 * 4);
            ROI4=(users[_addr].deposit_amount * ((block.timestamp - usersR[_addr].ROI5ON) / 1 days) / 100 * 5);
            
            payout = (ROI1+ROI2+ROI3+ROI4+ROI5) - users[_addr].deposit_payouts;
            }
            
            if((users[_addr].deposit_payouts + payout) > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    
    function userInfo(address _addr) view external returns(address _upline, uint40 _deposit_time, uint256 _deposit_amount, uint256 _payouts,uint256 _direct_bonus, uint256 _pool_bonus, uint256 _match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts,users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
      
    }
    function userInfotot(address _addr) view external returns(uint256 _Total_pool_bonus, uint256 _Total_Destiny,uint256 _Destiny_bonus) {
        return (userTot[_addr].total_PoolBonus,userTot[_addr].total_DestinyBonus,users[_addr].Destiny_Bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 _referrals, uint256 _total_deposits, uint256 _total_payouts, uint256 _total_structure,uint256 _WithLimit,uint256 _DROIR,uint256 _DPayouts) {
        return (users[_addr].referrals, userTot[_addr].total_deposits, userTot[_addr].total_payouts, userTot[_addr].total_structure,users[_addr].DLimit, users[_addr].DROI,users[_addr].deposit_payouts);
    }
     
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }
    
    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;
            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
    
    function poolTopInfoD() view external returns(address[1] memory addrs, uint256[1] memory deps) {
        if (pool_cycle==0)
        {
            addrs[0] = pool_topD[pool_cycle][0];
            deps[0] = pool_users_refs_deposits_sumD[pool_cycle][pool_topD[pool_cycle][0]];
        }
        if (pool_cycle>0)
        {
            addrs[0] = pool_topD[pool_cycle-1][0];
            deps[0] = pool_users_refs_deposits_sumD[pool_cycle-1][pool_topD[pool_cycle-1][0]];
        }
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