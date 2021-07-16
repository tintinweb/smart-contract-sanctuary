//SourceUnit: CyberTron.sol

pragma solidity ^0.5.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract CyberTron {
    using SafeMath for uint256;

    struct User {
        uint256 pending_payout;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 withdraw_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256[20] total_structure;
        uint256 percent;
        uint256 personal_insurance;
        uint256 deposit_pending_payout;
    }

    address payable public owner;
    uint256  public dev_fee = 10;
    uint256  public admin1_fee = 15;
    uint256  public admin2_fee = 35;
    uint256  public insurance_fee = 100;
    uint256  public general_insurance_fee = 10;
    uint256  public CYCLE = 1 days;
    uint256 public initial_percent = 100;
    uint256 public activation_time = 1610820000; //1610820000;

    address payable public dev_account = address(0x412d338c045af6e8adc66fc2f38f12ca95d412afc0);
    address payable public admin_account1 = address(0x41cd5a6cfd7a57511357535daa07eec2dcebebb97e);
    address payable public admin_account2 = address(0x4155b8898776cd849d657a086fffba41fd9ecf4e25);
    address payable public insurance_account = address(0x41c0fbad94a7a51c4a362b611c9f3d2637d1cbf3e3);
    address payable public general_insurance_account = address(0x41d347b51f1e1e2c9a7872bbe74ebcae4bfaa05592);

    mapping(address => User) public users;

    uint8[] public ref_bonuses;


    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    uint256 public current_percent = initial_percent;
    uint256 public start_time ;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor() public {
        owner = msg.sender;
        start_time = block.timestamp;
        
        ref_bonuses.push(20);
        ref_bonuses.push(15);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(4);
        ref_bonuses.push(4);
        ref_bonuses.push(4);
        ref_bonuses.push(4);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(2);
        ref_bonuses.push(2);

    }

    function() payable external {
        _deposit(msg.sender, msg.value,false);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
           

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;
                 users[_upline].referrals++;
                users[_upline].total_structure[i]++;
                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount , bool _isReinvest) private {
        require(_isReinvest || _amount >= 1e8, "Bad amount");
        require(block.timestamp > activation_time , "NOT STARTED");
        if(start_time < activation_time) start_time = activation_time;

        current_percent = initial_percent + ((block.timestamp - start_time)/CYCLE)*2;

        uint256 pendingPayout = this.payoutOf(_addr);

        if(pendingPayout > 0){
            users[_addr].pending_payout += pendingPayout;
            users[_addr].deposit_pending_payout += pendingPayout;
            users[_addr].withdraw_time = uint40(block.timestamp);
        }
        
        if((users[_addr].deposit_time > 0 && _amount > users[_addr].deposit_amount/4) || users[_addr].deposit_time == 0) {
            users[_addr].percent =  current_percent;
        }

        if(users[_addr].deposit_time == 0) users[_addr].withdraw_time = uint40(block.timestamp);

        if(users[_addr].deposit_payouts + users[_addr].deposit_pending_payout >= this.maxPayoutOf(users[_addr].deposit_amount)){
            users[_addr].payouts = 0;
            users[_addr].withdraw_time = uint40(block.timestamp);
            users[_addr].deposit_amount = _amount;
            users[_addr].deposit_pending_payout = 0;
            users[_addr].deposit_payouts = 0;
        }else{
            users[_addr].deposit_amount += _amount;
        }

        users[_addr].deposit_time = uint40(block.timestamp);
        
        if(!_isReinvest) users[_addr].total_deposits += _amount;

        total_deposited += _amount;

        uint256 devPercentage = (_amount.mul(dev_fee)).div(1000);
        dev_account.transfer(devPercentage);
        uint256 admin1Percentage = (_amount.mul(admin1_fee)).div(1000);
        admin_account1.transfer(admin1Percentage);
        uint256 admin2Percentage = (_amount.mul(admin2_fee)).div(1000);
        admin_account2.transfer(admin2Percentage);
        uint256 general_insurancePercentage = (_amount.mul(general_insurance_fee)).div(1000);
        general_insurance_account.transfer(general_insurancePercentage);
                
        emit NewDeposit(_addr, _amount);
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
                
            users[up].match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = users[up].upline;
        }
    }

    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 20 / 10;
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value,false);
    }

    function withdrawRef() external {
        uint256 payout = 0;
        // Match payout
        if(users[msg.sender].match_bonus > 0) {
            payout = users[msg.sender].match_bonus/2;

            users[msg.sender].match_bonus = 0;
            users[msg.sender].payouts += payout;
            
            _deposit(msg.sender, payout,true);
        }

        require(payout > 0, "Zero payout");

         msg.sender.transfer(payout);
    }


    function withdraw() external {
        (uint256 to_payout) = this.payoutOf(msg.sender) + users[msg.sender].pending_payout;
        
        // Deposit payout
        if(to_payout > 0) {

            users[msg.sender].deposit_payouts += this.payoutOf(msg.sender) + users[msg.sender].deposit_pending_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
             users[msg.sender].deposit_pending_payout = 0;
             users[msg.sender].pending_payout = 0;
        }
          
        require(to_payout > 0, "Zero payout");

        uint256 devPercentage = (to_payout.mul(dev_fee)).div(1000);
        dev_account.transfer(devPercentage);
        uint256 admin1Percentage = (to_payout.mul(admin1_fee)).div(1000);
        admin_account1.transfer(admin1Percentage);
        uint256 admin2Percentage = (to_payout.mul(admin2_fee)).div(1000);
        admin_account2.transfer(admin2Percentage);
        uint256 general_insurancePercentage = (to_payout.mul(general_insurance_fee)).div(1000);
        general_insurance_account.transfer(general_insurancePercentage);

        uint256 insurancePercentage = (to_payout.mul(insurance_fee)).div(1000);
        insurance_account.transfer(insurancePercentage);
        users[msg.sender].personal_insurance += insurancePercentage;
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        users[msg.sender].withdraw_time = block.timestamp;

        msg.sender.transfer(to_payout-insurancePercentage);

        emit Withdraw(msg.sender, to_payout);

    }

    function payoutOf(address _addr)  view external returns(uint256 payout) {
        uint256 max_payout = this.maxPayoutOf(users[_addr].deposit_amount);
        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * users[_addr].percent / 10000 * (block.timestamp - users[_addr].withdraw_time)) / CYCLE;
           
            if(users[_addr].deposit_payouts + payout + users[_addr].deposit_pending_payout >= max_payout) {
                return max_payout - users[_addr].deposit_payouts - users[_addr].deposit_pending_payout;
            }

            return payout;
        }
        return 0;
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(uint256 deposit_amount, uint256 payouts, uint256 match_bonus,uint256 percent,uint256 unclaimed,uint256 referrals,uint256 personal_insurance) {
      
        return (users[_addr].deposit_amount, users[_addr].payouts, users[_addr].match_bonus,users[_addr].percent,this.payoutOf(_addr) + users[_addr].pending_payout,users[_addr].referrals , users[_addr].personal_insurance);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256[20] memory total_structure  ) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure  );
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw , uint256 daily_percent , uint256 _activation_time) {
        return (total_users, total_deposited, total_withdraw  , initial_percent + ((block.timestamp - start_time)/CYCLE)*2 , activation_time) ;
    }

 
}