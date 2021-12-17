/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

/** Arthur **/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract MyDiamondTeam {
    using SafeMath for uint256;

     struct User {
        uint256 checkpoint;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 total_direct_deposits;
        uint256 total_payouts;
        uint256 total_structure;
        uint256 total_downline_deposit;
        uint256 deposit_time;
        address[] downlines;
    }

    struct Airdrop {
        //Airdrop tracking
        uint256 airdrops;
        uint256 airdrops_received;
        uint256 last_airdrop;
    }

    address payable public owner;
    address payable public project;
    address payable public marketing;

    uint256 public REFERRAL = 50;
    uint256 public PROJECT = 80;
	uint256 public MARKETING = 20;
    uint256 public RESERVED = 50;
    uint256 public AIRDROP = 50; 
    uint256 public REINVEST_BONUS = 50;
    uint256 public MAX_PAYOUT = 3650;
    uint256 public BASE_PERCENT = 15;
    uint256 public TIME_STEP = 1 days;
    uint256 constant public PERCENTS_DIVIDER = 1000;

    mapping(address => User) public users;
    mapping(uint256 => address) public id2Address;
    mapping(address => Airdrop) public airdrops;

    uint8[] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint256 public pool_last_draw = block.timestamp;
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_reinvested;
    uint256 public total_airdrops;

    bool public started;
    uint256 public MIN_INVEST = 1 * 1e17; //0.1 BNB
    uint256 public MAX_WALLET_DEPOSIT = 25 ether; //25 BNB
    uint256 public MAX_PAYOUT_PROJECT = 100000;
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
	event ReinvestedDeposit(address indexed user, uint256 amount);
    event NewAirdrop(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    constructor(address payable ownerAddress, address payable projectAddress, address payable marketingAddress) {
        require(!isContract(ownerAddress) && !isContract(projectAddress) && !isContract(marketingAddress));
        owner = ownerAddress;
		project = projectAddress;
		marketing = marketingAddress;

        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(7);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        pool_bonuses.push(25);
        pool_bonuses.push(20);
        pool_bonuses.push(15);
        pool_bonuses.push(10);
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    //deposit_amount -- can only be done by the project address for first deposit.
    function deposit() payable external {
        _deposit(msg.sender, msg.value);
    }

    //deposit with upline
    function deposit(address _upline) payable external {
        require(started, "Contract not yet started.");
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    //invest
    function _deposit(address _addr, uint256 _amount) private {
        if (!started) {
    		if (msg.sender == project) {
    			started = true;
    		} else revert("Contract not yet started.");
    	}
        
        require(users[_addr].upline != address(0) || _addr == project, "No upline");
        require(_amount >= MIN_INVEST, "Mininum investment not met.");
        require(users[_addr].total_direct_deposits.add(_amount) <= MAX_WALLET_DEPOSIT, "Max deposit limit reached.");
        users[_addr].deposit_amount += _amount;
        users[_addr].deposit_time = block.timestamp;
        users[_addr].total_direct_deposits += _amount;
		users[_addr].checkpoint = block.timestamp;
        total_deposited += _amount;

        emit NewDeposit(_addr, _amount);
        if(users[_addr].upline != address(0)) {
            //direct referral bonus 5%
            users[users[_addr].upline].direct_bonus += _amount.mul(REFERRAL).div(PERCENTS_DIVIDER);
            emit DirectPayout(users[_addr].upline, _addr, _amount.mul(REFERRAL).div(PERCENTS_DIVIDER));
        }

        _poolDeposits(_addr, _amount);
        _downLineDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        //pay fees
        fees(_amount);
    }

    function checkUplineValid(address _addr, address _upline) external view returns (bool isValid) {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != project && (users[_upline].deposit_time > 0 || _upline == project)) {
            isValid = true;        }
    }

    function _setUpline(address _addr, address _upline) private {
        if(this.checkUplineValid(_addr, _upline)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            users[_upline].downlines.push(_addr);

            emit Upline(_addr, _upline);
            id2Address[total_users] = _addr;
            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _poolDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100;

        address upline = users[_addr].upline;

        if(upline == address(0) || upline == project) return;

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

    function _downLineDeposits(address _addr, uint256 _amount) private {
      address _upline = users[_addr].upline;
      for(uint8 i = 0; i < ref_bonuses.length; i++) {
          if(_upline == address(0)) break;

          users[_upline].total_downline_deposit = users[_upline].total_downline_deposit.add(_amount);
          _upline = users[_upline].upline;
      }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < 15; i++) {
            if(up == address(0)) break;

            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;

                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = block.timestamp;
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function withdraw() external {
        if (!started) {
			revert("Contract not yet started.");
		}
        
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(users[msg.sender].payouts < max_payout, "Max payout already received.");

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

        // Pool payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
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

        require(to_payout > 0, "User has zero dividends payout.");
        //check for withdrawal tax and get final payout.
        to_payout = this.withdrawalTaxPercentage(to_payout);
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
        users[msg.sender].checkpoint = block.timestamp;

        //pay investor

        uint256 payout = to_payout.sub(fees(to_payout));
        payable(address(msg.sender)).transfer(payout);
        emit Withdraw(msg.sender, payout);
        //max payout of 
        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    //re-invest direct deposit payouts and direct referrals.
    function reinvest() external {
		if (!started) {
			revert("Not started yet");
		}

        uint256 to_reinvest = this.payoutToReinvest(msg.sender);

        // Deposit payout
        if(to_reinvest > 0) {
            to_reinvest = users[msg.sender].payouts;
        }

        // Direct payout
        uint256 direct_bonus = users[msg.sender].direct_bonus;
        users[msg.sender].direct_bonus -= direct_bonus;
        to_reinvest += direct_bonus;

        // Pool payout
        uint256 pool_bonus = users[msg.sender].pool_bonus;
        users[msg.sender].pool_bonus -= pool_bonus;
        to_reinvest += pool_bonus;
        
        // Match payout
        uint256 match_bonus = users[msg.sender].match_bonus;
        users[msg.sender].match_bonus -= match_bonus;
        to_reinvest += match_bonus;    

        require(to_reinvest > 0, "User has zero dividends payout.");
        //add 5% more bonus for reinvest action.
        to_reinvest = to_reinvest.add(to_reinvest.mul(REINVEST_BONUS).div(PERCENTS_DIVIDER));
        users[msg.sender].deposit_amount += to_reinvest;
        users[msg.sender].deposit_time = block.timestamp;
        /** to_reinvest will not be added to total_deposits, new deposits will only be added here. **/
        //users[msg.sender].total_deposits += to_reinvest;
        total_reinvested += to_reinvest;
        users[msg.sender].checkpoint = block.timestamp;
        emit ReinvestedDeposit(msg.sender, to_reinvest);
        
        _poolDeposits(msg.sender, to_reinvest);

        _downLineDeposits(msg.sender, to_reinvest);

        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }
	}

    //max payout per user is 300% including initial investment.
    function maxPayoutOf(uint256 _amount) view external returns(uint256) {
        return _amount * MAX_PAYOUT / 1000;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {

        max_payout = ((_addr == project || _addr == marketing)  
                ? this.maxPayoutP(users[_addr].deposit_amount) 
                : this.maxPayoutOf(users[_addr].deposit_amount));

        if(users[_addr].deposit_payouts < max_payout) {
            
            if (users[_addr].deposit_time > users[_addr].checkpoint) {
                payout = (users[_addr].deposit_amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(users[_addr].deposit_time))
						.div(TIME_STEP);
            }else{
                payout = (users[_addr].deposit_amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(users[_addr].checkpoint))
						.div(TIME_STEP);
            }

            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }


    function airdrop(address payable _to) payable external {

        address _addr = msg.sender;
        uint256 _amount = msg.value;

        // transfer to recipient        
        uint256 project_fee = _amount.mul(AIRDROP).div(PERCENTS_DIVIDER); // 5% tax on airdrop
        uint256 payout = _amount.sub(project_fee);
        project.transfer(project_fee);
        _to.transfer(_amount);

        //Make sure _to exists in the system; we increase
        require(users[_to].upline != address(0), "_to not found");

        //Fund to deposits (not a transfer)
        users[_to].deposit_amount += payout;
        users[_to].deposit_time = block.timestamp;

        //User stats
        airdrops[_addr].airdrops += payout;
        airdrops[_addr].last_airdrop = block.timestamp;
        airdrops[_to].airdrops_received += payout;

        //Keep track of overall stats
        total_airdrops += payout;

        emit NewAirdrop(_addr, _to, payout, block.timestamp);
        emit NewDeposit(_to, payout);
    }

    function payoutToReinvest(address _addr) view external returns(uint256 payout) {
        if (users[_addr].deposit_time > users[_addr].checkpoint) {
                payout = (users[_addr].deposit_amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(users[_addr].deposit_time))
						.div(TIME_STEP);
        }else{
            payout = (users[_addr].deposit_amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(users[_addr].checkpoint))
						.div(TIME_STEP);
        }
    }

    function fees(uint256 amount) internal returns(uint256){
        uint256 proj = amount.mul(PROJECT).div(PERCENTS_DIVIDER);
        uint256 market = amount.mul(MARKETING).div(PERCENTS_DIVIDER);
        project.transfer(proj);
        marketing.transfer(market);
        return proj.add(market);
    }

    function maxPayoutP(uint256 _amount) view external returns(uint256) {
        return _amount * MAX_PAYOUT_PROJECT / 1000;
    }

    function withdrawalTaxPercentage(uint256 to_payout) view external returns(uint256 finalPayout) {
      uint256 contractBalance = address(this).balance;
	  
      if (to_payout < contractBalance.mul(10).div(PERCENTS_DIVIDER)) {           // 0% tax if amount is  <  1% of contract balance
          finalPayout = to_payout; 
      }else if(to_payout >= contractBalance.mul(10).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(50).div(PERCENTS_DIVIDER));  // 5% tax if amount is >=  1% of contract balance
      }else if(to_payout >= contractBalance.mul(20).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(100).div(PERCENTS_DIVIDER)); //10% tax if amount is >=  2% of contract balance
      }else if(to_payout >= contractBalance.mul(30).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(150).div(PERCENTS_DIVIDER)); //15% tax if amount is >=  3% of contract balance
      }else if(to_payout >= contractBalance.mul(40).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(200).div(PERCENTS_DIVIDER)); //20% tax if amount is >=  4% of contract balance
      }else if(to_payout >= contractBalance.mul(50).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(250).div(PERCENTS_DIVIDER)); //25% tax if amount is >=  5% of contract balance
      }else if(to_payout >= contractBalance.mul(60).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(300).div(PERCENTS_DIVIDER)); //30% tax if amount is >=  6% of contract balance
      }else if(to_payout >= contractBalance.mul(70).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(350).div(PERCENTS_DIVIDER)); //35% tax if amount is >=  7% of contract balance
      }else if(to_payout >= contractBalance.mul(80).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(400).div(PERCENTS_DIVIDER)); //40% tax if amount is >=  8% of contract balance
      }else if(to_payout >= contractBalance.mul(90).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(450).div(PERCENTS_DIVIDER)); //45% tax if amount is >=  9% of contract balance
      }else if(to_payout >= contractBalance.mul(100).div(PERCENTS_DIVIDER)){
          finalPayout = to_payout.sub(to_payout.mul(500).div(PERCENTS_DIVIDER)); //50% tax if amount is >= 10% of contract balance
      }
    }

    /*
        Only external call
    */

    function userInfo(address _addr) view external returns(address upline, uint256 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoAirdrop(address _addr) view external returns(uint256 last_airdrop) {
        return (airdrops[_addr].last_airdrop);
    }

    function userSponsorInfo(address _addr) view external returns(address upline, address[] memory downlines) {
        return (users[_addr].upline, users[_addr].downlines);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure,uint256 total_downline_deposit, uint256 airdrops_total, uint256 airdrops_received) {
        return (users[_addr].referrals, users[_addr].total_direct_deposits, users[_addr].total_payouts, users[_addr].total_structure, users[_addr].total_downline_deposit, airdrops[_addr].airdrops, airdrops[_addr].airdrops_received);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider, uint256 _total_airdrops) {
        return (total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]], total_airdrops);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }

    function getBlockTimeStamp() public view returns (uint256) {
	    return block.timestamp;
	}

    /** SETTERS **/

    function CHANGE_OWNERSHIP(address value) external {
        require(msg.sender == owner, "Admin use only");
        owner = payable(value);
    }

    function CHANGE_PROJECT_WALLET(address value) external {
        require(msg.sender == owner, "Admin use only");
        project = payable(value);
    }

    function CHANGE_MARKETING_WALLET(address value) external {
        require(msg.sender == owner, "Admin use only");
        marketing = payable(value);
    }

    function CHANGE_PROJECT_FEE(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 10 && value <= 100);
        PROJECT = value;
    }

    function CHANGE_MARKETING_FEE(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 10 && value <= 50);
        MARKETING = value;
    }

    function CHANGE_RESERVED_FEE(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value <= 50);
        RESERVED = value;
    }

    function CHANGE_AIRDROPD_FEE(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value <= 50);
        AIRDROP = value;
    }

    function SET_REFERRAL_PERCENT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 10 &&value <= 100);
        REFERRAL = value;
    }

    function SET_REINVEST_BONUS(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value <= 500);
        REINVEST_BONUS = value;
    }

    function SET_MAX_PAYOUT_PROJECT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 3000 && value <= 1000000); 
        MAX_PAYOUT_PROJECT = value;
    }

    function SET_MAX_PAYOUT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 3000 && value <= 5000); 
        MAX_PAYOUT = value;
    }

    function SET_INVEST_MIN(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        MIN_INVEST = value * 1e17;
    }

    function SET_MAX_WALLET_DEPOSIT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        MAX_WALLET_DEPOSIT = value * 1 ether;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}