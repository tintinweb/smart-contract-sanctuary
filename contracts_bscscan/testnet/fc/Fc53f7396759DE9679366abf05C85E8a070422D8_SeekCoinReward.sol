/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;
    }
}

contract SeekCoinReward is PriceConsumerV3 {
    using SafeMath for uint256;

    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    address payable public owner;
    address payable public etherchain_fund;
    address payable public admin_fee;

    mapping(address => User) public users;
    uint256[] public cycles;
    uint8[15] public ref_bonuses;
    uint256 constant public INVEST_MIN_AMOUNT = 50e18;
    uint256 constant public BASE_PERCENT = 10;
    uint256[] public REFERRAL_PERCENTS = [100, 50];
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    
    constructor(address payable _owner,address payable _admin_fee) {
        owner = _owner;
        admin_fee =_admin_fee ;

        for(uint i = 0; i < ref_bonuses.length; i++){
            if(i < 10){
                ref_bonuses[i] = 6;    
            } else {
                ref_bonuses[i] = 8;
            }
        }

        cycles.push(5000e18);
        cycles.push(10000e18);
        cycles.push(20000e18);
        cycles.push(40000e18);
    }

    function getUsdt(uint256 _value)view public returns(uint256){
        return(uint256(getLatestPrice()).mul(_value)).div(1e18);   
    }
    
    function getbnb(uint256 _value)view public returns(uint256){
        return(_value.mul(1e18).div(uint256(getLatestPrice())));
    }

    receive() payable external {
        _deposit(payable(msg.sender), msg.value);
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

    function _deposit(address payable _addr, uint256 _amount) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;

            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].deposit_amount), "Deposit already exists");
            require(msg.value >= users[_addr].deposit_amount && msg.value <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= INVEST_MIN_AMOUNT && _amount <= cycles[0], "Bad amount");
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = msg.value;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += msg.value;

        total_deposited += msg.value;
        emit NewDeposit(_addr, msg.value);

        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += msg.value / 10;
            emit DirectPayout(users[_addr].upline, _addr, msg.value / 10);
        }

        admin_fee.transfer(msg.value.mul(5).div(100));
    }
    
    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;

                users[up].match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function deposit(address _upline) payable external {
        _setUpline(msg.sender, _upline);
        uint256 amount =  getUsdt(msg.value);
        _deposit(payable(msg.sender), amount);
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
        total_withdraw += to_payout;

        payable(msg.sender).transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }
    
    
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 31 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100) - users[_addr].deposit_payouts;
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint256 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 match_bonus) {
        return (
            users[_addr].upline,
            users[_addr].deposit_time,
            users[_addr].deposit_amount,
            users[_addr].payouts,
            users[_addr].direct_bonus,
            users[_addr].match_bonus
        );
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (
            users[_addr].referrals,
            users[_addr].total_deposits,
            users[_addr].total_payouts,
            users[_addr].total_structure
        );
    }

    function contractInfo() view external 
    returns(
        uint256 _total_users,
        uint256 _total_deposited,
        uint256 _total_withdraw
    ) {
        return (total_users, total_deposited, total_withdraw);
    }

    
    function getContractBalance()view public returns(uint256){
        return (address(this).balance);
    }
}

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
}