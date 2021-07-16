//SourceUnit: TronAdoChain.sol

pragma solidity 0.5.10;
contract TronAdoChain {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40  deposit_time;
        uint256 DROI;
        uint256 DLimit;
    }
    struct usertots
    {
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 Dlmts;
    }
    address payable public owner;
    address payable public Platform_fee;
    address payable public developer_fee;
    address payable public admin_fee;

    mapping(address => User) public users;
    mapping(address => usertots) public userTot;
    
    uint256[] public cycles;
    uint256[] public ref_bonuses;

    uint256[] public Daily_ROI; 
    uint256[] public Daily_ROILimit;
    uint256[] public LevelInc;  
  
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount,uint256 LvlNo, uint256 Refs);
    event MissedLevelPayout(address indexed addr, address indexed from, uint256 amount,uint256 LvlNo, uint256 Refs);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
  
  modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }
    constructor(address payable _owner,address payable _Platformfee,address payable _AdminFee,address payable _DevFund) public {
        owner = _owner;
        Platform_fee = _Platformfee;
        admin_fee = _AdminFee;
        developer_fee = _DevFund;
        
        ref_bonuses.push(3);
        ref_bonuses.push(5);
        ref_bonuses.push(8);
        ref_bonuses.push(9);
        ref_bonuses.push(10);
        ref_bonuses.push(20);
        ref_bonuses.push(30);
       
        Daily_ROILimit.push(310);
        cycles.push(100);

	    LevelInc.push(1);
        LevelInc.push(2);
        LevelInc.push(3);
        LevelInc.push(4);
        LevelInc.push(5);
        LevelInc.push(7);
        LevelInc.push(10);
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
        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            require(users[_addr].payouts >= users[_addr].DLimit, "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount, "Bad amount");
            require(_amount%cycles[0]==0 && _amount>=cycles[0], "Bad amount");
        }
        else require(_amount%cycles[0]==0 && _amount>=cycles[0], "Bad amount");
        //
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        userTot[_addr].total_deposits += _amount;
        //
        users[_addr].match_bonus=0;
        
        users[_addr].DROI=1;
        users[_addr].DLimit=users[_addr].deposit_amount*Daily_ROILimit[0]/100;
        userTot[_addr].Dlmts=Daily_ROILimit[0];
        
        total_deposited += _amount;
        //
        emit NewDeposit(_addr, _amount);       
        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += (_amount* 15)/100;
            emit DirectPayout(users[_addr].upline, _addr, (_amount* 15)/100);
        }
        //
        Platform_fee.transfer(_amount * 5/ 100);
        admin_fee.transfer(_amount * 3/ 100);
        developer_fee.transfer(_amount * 1/ 100);
        //
    }
    
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;
        uint256 r1 = 0;
        uint256 rb=0;
        uint256 bonus=0;
        uint256 DepAmt= users[_addr].DLimit;
        require(_amount<=DepAmt,"Profit must be less from Damt!");
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) 
        {
          //  if(up == address(0)) break;
            bonus=0;
            rb=0;
            rb=users[up].referrals;
            //
            if (up != address(0))
            {
               if(rb >= LevelInc[i]) 
                {
                    bonus = (_amount * ref_bonuses[i]) / 100;
                    //
                    if (bonus<_amount && bonus>0 && _amount<=DepAmt)
                    {
                    users[up].match_bonus += bonus;
                    emit MatchPayout(up, _addr, bonus,i,rb);
                    }
                    //
                }
                else{ r1+=(_amount * ref_bonuses[i]) / 100;}
            }
            //
          else{ r1+=(_amount * ref_bonuses[i]) / 100;}
                up = users[up].upline;
        }
        //Missing levels
        if (r1>0)
        {
            emit MissedLevelPayout(owner,_addr,r1,DepAmt,_amount);
            if (address(this).balance >= r1 && r1<=DepAmt && _amount<=DepAmt)
            {//Missing matching level will transfer to contract owner
            owner.transfer(r1);
            }
        }
    }
   
    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(users[msg.sender].payouts < max_payout, "Full payouts");
        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }
            //
            if (to_payout<=max_payout)
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
        userTot[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
        msg.sender.transfer(to_payout);
        emit Withdraw(msg.sender, to_payout);
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
    function userInfo(address _addr) view external returns(uint256 _WithLimit, uint256 _deposit_amount, uint256 _payouts,uint256 _direct_bonus, uint256 _match_bonus) {
        return (users[_addr].DLimit, users[_addr].deposit_amount, users[_addr].payouts,users[_addr].direct_bonus, users[_addr].match_bonus);
    }
    function userInfotot(address _addr) view external returns(uint40 _deposit_time,uint256 _Dlmts) {
        return (users[_addr].deposit_time,userTot[_addr].Dlmts);
    }
    function userInfoTotals(address _addr) view external returns(address _upline,uint256 _referrals, uint256 _total_deposits, uint256 _total_payouts, uint256 _total_structure,uint256 _DROIR,uint256 _DPayouts) {
        return (users[_addr].upline,users[_addr].referrals, userTot[_addr].total_deposits, userTot[_addr].total_payouts, userTot[_addr].total_structure, users[_addr].DROI,users[_addr].deposit_payouts);
    }
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (total_users, total_deposited, total_withdraw);
    }
}