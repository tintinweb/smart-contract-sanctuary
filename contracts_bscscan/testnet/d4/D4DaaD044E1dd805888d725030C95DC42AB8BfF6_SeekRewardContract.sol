/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

pragma solidity 0.8.6;



// interface Seekreward{
//     function name() external view returns(string memory);
//     function symbol() external view returns(string memory);
//     function decimals() external view returns(uint8);
//     function totalSupply() external view returns(uint256);
//     function balanceOf(address owner) external view returns(uint256);
//     function transfer(address to, uint256 amount) external returns(bool);
//     function transferFrom(address from, address to, uint256 amount) external returns(bool);
//     function approve(address spender, uint256 amount) external returns(bool);
//     function allowance(address owner, address spender) external view returns(uint256);
//     function burnBalance(address _addr, uint _amount) external;
//     function mint(address _tokenHolder, uint256 _amount, bytes calldata _data, bytes calldata _operatorData) external;
//     function defaultOperators() external view returns(address[] memory);

//     // solhint-disable-next-line no-simple-event-func-name
//     event Transfer(address indexed from, address indexed to, uint256 amount);
//     event Approval(address indexed owner, address indexed spender, uint256 amount);
// }


library SafeMath {

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        // require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers.
     * (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. 
     * (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
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


contract SeekRewardContract is PriceConsumerV3{

    using SafeMath for uint256;

    // Investor details
    struct user {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 referalBonus;
        uint256 matchBonus;
        uint256 depositAmount;
        uint256 depositPayouts;
        uint40 depositTime;
        uint256 totalDeposits;
        uint256 totalStructure;
        uint256 remainingBalance;
    }
    
    // Mapping users details by address
    mapping(address => user)public users;

    // Contract status
    bool public lockStatus;
    // Admin1 address
    address payable public admin1;
    // Admin2 address
    address payable public admin2;
    // Total levels
    uint[]public Levels;
    // Total users count
    uint256 public totalUsers = 1;
    // Total deposit amount.
    uint256 public totalDeposited;
    // Total withdraw amount
    uint256 public totalWithdraw;

    // Matching bonus event
    event MatchBonus(address indexed from, address indexed to, uint value, uint time);
    // Withdraw event
    event Withdraw(address indexed from, uint value, uint time);
    // Deposit event
    event Deposit(address indexed from, address indexed refer, uint value, uint time);
    // Admin withdraw event
    event AdminEarnings(address indexed user, uint value, uint time);
    // User withdraw limt event
    event LimitReached(address indexed from, uint value, uint time);
   
    /**
     * @dev Initializes the contract setting the owners and token.
     */
    constructor(address payable  _owner1, address payable  _owner2)  {
        admin1 = _owner1;
        admin2 = _owner2;
        //Levels maximum amount
        Levels.push(50e18);
        Levels.push(3000e18);
        Levels.push(10000e18);
        Levels.push(50000e18);
        Levels.push(100000e18);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == admin1, "SeekReward: Only Owner");
        _;
    }

    /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, "SeekReward: Contract Locked");
        _;
    }

    /**
     * @dev Throws if called by other contract
     */
    modifier isContractCheck(address _user) {
        require(!isContract(_user), "SeekReward: Invalid address");
        _;
    }
    
    function getUsdt(uint256 _value)view public returns(uint256){
     return(_value/uint256(getLatestPrice()))*1e8;   
    }
    
    function _setUpline(address _addr, address _upline) private {
        if (users[_addr].upline == address(0) && _upline != _addr && _addr != admin1 && 
           (users[_upline].depositTime > 0 || _upline == admin1)) {
            users[_addr].upline = _upline;
            users[_upline].referrals = users[_upline].referrals.add(1);
            totalUsers++;
            for (uint8 i = 0; i < 21; i++) { // For update total structure for uplines
                if (_upline == address(0)) break;
                users[_upline].totalStructure++;
                _upline = users[_upline].upline;
            }
        }
    }
    
    receive()payable external{
        
    }

    function _deposit(address _addr) private {
        require(_addr != address(0) || _addr == admin1, "No upline");
        if (users[_addr].depositTime > 0) {
            users[_addr].cycle++;
            require(users[_addr].payouts >= this.maxPayoutOf(users[_addr].depositAmount),
            "SeekReward: Deposit already exists");
            require(msg.value >= users[_addr].depositAmount && msg.value <= Levels[users[_addr].cycle > getUsdt(Levels.length - 1) ?Levels.length - 1 : users[_addr].cycle],  "SeekReward: Bad amount");
        }
        else {
            require(msg.value >= getUsdt(Levels[0]) && msg.value <= getUsdt(Levels[1]),"SeekReward: Bad amount");
        }

        users[_addr].payouts = 0;
        users[_addr].depositAmount = msg.value;
        users[_addr].depositPayouts = 0;
        users[_addr].depositTime = uint40(block.timestamp);
        users[_addr].referalBonus = 0;
        users[_addr].matchBonus = 0;
        users[_addr].totalDeposits = users[_addr].totalDeposits.add(msg.value);
        totalDeposited = totalDeposited.add(msg.value);

        address upline = users[_addr].upline;
        address up = users[users[_addr].upline].upline;

        if (upline != address(0)) {

            if(!(users[upline].payouts >= this.maxPayoutOf(users[upline].depositAmount))){
                
            users[upline].referalBonus = users[upline].referalBonus.add(msg.value.mul(10).div(100));
            
            }
        }
        if (up != address(0)) {
            
            if(!(users[up].payouts >= this.maxPayoutOf(users[up].depositAmount))){
                
            users[up].referalBonus = users[up].referalBonus.add(msg.value.mul(5).div(100));
            
            }
            
        }

        uint adminFee = msg.value.mul(5).div(100);
        admin1.transfer( adminFee.div(2)); // 2.5% admin1
        admin2.transfer(adminFee.div(2)); // 2.5% admin2
        adminFee = 0;
        emit Deposit(_addr, users[_addr].upline, msg.value, block.timestamp);
    }

    function deposit(address _upline) external payable isLock isContractCheck(msg.sender) {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender);
    }
    
    function _matchBonus(address _user, uint _amount,uint256 _amount1) private {
        address up = users[_user].upline;
        for (uint i = 1; i <= 15; i++) { // For matching bonus
            if (up == address(0)) 
            
            users[admin1].matchBonus = users[admin1].matchBonus.add(_amount); 
            
            if (i==5 && i==6) {
                    if(users[up].referrals >= 5){
                        
                        if(!(users[up].payouts >= this.maxPayoutOf(users[up].depositAmount))){
                
                                users[up].matchBonus = users[up].matchBonus.add(_amount);
                    emit MatchBonus(_user, up, _amount, block.timestamp);
            }

                
                    }
                else {
                 users[admin1].matchBonus = users[admin1].matchBonus.add(_amount);    
                }
            }
                
                if (i>=11) {
                    if(users[up].referrals >= 10){
                        
                        
        if(!(users[up].payouts >= this.maxPayoutOf(users[up].depositAmount))){
             
                    users[up].matchBonus = users[up].matchBonus.add(_amount1);
                    emit MatchBonus(_user, up, _amount, block.timestamp);   
            }

                        
                        
                }
                
                else {
                 users[admin1].matchBonus = users[admin1].matchBonus.add(_amount);    
                }
                }
                else if (users[up].referrals >= i+1) {
                    
                    
                               
        if(!(users[up].payouts >= this.maxPayoutOf(users[up].depositAmount))){
             
                    users[up].matchBonus = users[up].matchBonus.add(_amount);
                    emit MatchBonus(_user, up, _amount, block.timestamp);
            }
                    
                }
                
                else {
                 users[admin1].matchBonus = users[admin1].matchBonus.add(_amount);    
                }
                
                up = users[up].upline;
            }
            
            
        }
    

    function withdraw() external isLock {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        require(msg.sender != admin1, "SeekReward: only for users");
        require(users[msg.sender].payouts < max_payout, "SeekReward: Full payouts");
        
        uint256 dummyrefferal;
        uint256 dummymatrixcommision;
        uint256 dummyremainingBalance;
        // Deposit payout
        if (to_payout > 0) {
            if (users[msg.sender].payouts.add(to_payout) > max_payout) {
                to_payout = max_payout.sub(users[msg.sender].payouts);
            }
            users[msg.sender].depositPayouts = users[msg.sender].depositPayouts.add(to_payout);
            users[msg.sender].payouts = users[msg.sender].payouts.add(to_payout);
            _matchBonus(msg.sender, to_payout.mul(6).div(100),to_payout.mul(1).div(100));
        }
        
        
        //refferal bonus
        dummyrefferal=users[msg.sender].referalBonus;
        if (users[msg.sender].payouts < max_payout && users[msg.sender].referalBonus > 0) {
            if (users[msg.sender].payouts.add(users[msg.sender].referalBonus) > max_payout) {
                
                users[msg.sender].referalBonus = max_payout.sub(users[msg.sender].payouts);
                users[msg.sender].remainingBalance=users[msg.sender].referalBonus.add(dummyrefferal.sub(users[msg.sender].referalBonus));
            
            }
            users[msg.sender].payouts = users[msg.sender].payouts.add(users[msg.sender].referalBonus);
            to_payout = to_payout.add(users[msg.sender].referalBonus);
            users[msg.sender].referalBonus = users[msg.sender].referalBonus.sub(users[msg.sender].referalBonus);
        }
        users[msg.sender].referalBonus = 0;
        

        // matching bonus
        dummymatrixcommision=users[msg.sender].matchBonus;
        if (users[msg.sender].payouts < max_payout && users[msg.sender].matchBonus > 0) {
            if (users[msg.sender].payouts.add(users[msg.sender].matchBonus) > max_payout) {
                users[msg.sender].matchBonus = max_payout.sub(users[msg.sender].payouts);
        users[msg.sender].remainingBalance=users[msg.sender].remainingBalance.add(dummymatrixcommision.sub(users[msg.sender].matchBonus));
            }
            users[msg.sender].payouts = users[msg.sender].payouts.add(users[msg.sender].matchBonus);
            to_payout = to_payout.add(users[msg.sender].matchBonus);
            users[msg.sender].matchBonus = users[msg.sender].matchBonus.sub(users[msg.sender].matchBonus);
        }
        users[msg.sender].matchBonus = 0;
        
        

        if (users[msg.sender].payouts < max_payout || users[msg.sender].remainingBalance > 0) {
            if  (users[msg.sender].payouts.add(users[msg.sender].remainingBalance) > max_payout) {
                dummyremainingBalance = max_payout.sub(users[msg.sender].payouts);
                    users[msg.sender].payouts = users[msg.sender].payouts.add(dummyremainingBalance);
                   to_payout = to_payout.add(dummyremainingBalance);
                users[msg.sender].remainingBalance = (users[msg.sender].remainingBalance).sub(dummyremainingBalance);
                }
                else{
                    users[msg.sender].payouts = users[msg.sender].payouts.add(users[msg.sender].remainingBalance);
                   to_payout = to_payout.add(users[msg.sender].remainingBalance);
                   users[msg.sender].remainingBalance=0;
                }
        
            // users[msg.sender].remainingBalance=users[msg.sender].remainingBalance.add(dummyremainingBalance.sub(users[msg.sender].remainingBalance));
            
        }
        
        
    
        totalWithdraw = totalWithdraw.add(to_payout);
        admin1.transfer( to_payout); // Daily roi and matching bonus
        emit Withdraw(msg.sender, to_payout, block.timestamp);

        if (users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts, block.timestamp);
        }
    }

    /**
     * @dev adminWithdraw: owner invokes the function
     * owner can get referbonus, matchbonus 
     */
    function adminWithdraw() external onlyOwner {
        uint amount;
        if (users[admin1].referalBonus > 0) {
            amount = amount.add(users[admin1].referalBonus);
            users[admin1].referalBonus = 0;
        }
        if (users[admin1].matchBonus > 0) {
            amount = amount.add(users[admin1].matchBonus);
            users[admin1].matchBonus = 0;
        }
        admin1.transfer( amount); //Referal bonus and matching bonus
        emit AdminEarnings(admin1, amount, block.timestamp);
    }

    /**
     * @dev maxPayoutOf: Amount calculate by 210 percentage
     */
    function maxPayoutOf(uint256 _amount) external pure returns(uint256) {
        return _amount.mul(210).div(100);
    }

    /**
     * @dev payoutOf: Users daily ROI and maximum payout will be show
     */
    function payoutOf(address _addr) external view returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].depositAmount);
        if (users[_addr].depositPayouts < max_payout) {
            // payout = users[_addr].depositAmount).mul(block.timestamp
            // .sub(users[_addr].depositTime).div(1 days).div(100).sub(users[_addr].depositPayouts); // Daily roi
            
            payout = ((users[_addr].depositAmount * (block.timestamp - users[_addr].depositTime)) / 10 seconds / 100) - users[_addr].depositPayouts;
          
            if (users[_addr].payouts.add(payout) > max_payout) {
                payout = max_payout.sub(users[_addr].payouts);
            }
// if(users[_addr].payouts.add(payout).add(users[_addr].remainingBalance.add(users[_addr].referalBonus).add(users[_addr].matchBonus))>max_payout){
//                     payout=0; 
//                 }
            
        }
        return (payout,max_payout);
    }

    /**
     * @dev userInfo: Returns upline,depositTime,depositAmount,payouts,match_bonus
     */
    function userInfo(address _addr) external view returns(address upline, uint40 deposit_time,
    uint256 deposit_amount, uint256 payouts, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].depositTime, users[_addr].depositAmount,
                users[_addr].payouts, users[_addr].matchBonus);
    }

    /**
     * @dev userInfoTotals: Returns users referrals count, totalDeposit, totalStructure
     */
    function userInfoTotals(address _addr) external view returns(uint256 referrals,
    uint256 total_deposits, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].totalDeposits, users[_addr].totalStructure);
    }

    /**
     * @dev contractInfo: Returns total users, totalDeposited, totalWithdraw
     */
    function contractInfo() external view returns(uint256 _total_users, uint256 _total_deposited,
    uint256 _total_withdraw) {
        return (totalUsers, totalDeposited, totalWithdraw);
    }

    /**
     * @dev contractLock: For contract status
     */
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

    /**
     * @dev failSafe: Returns transfer token
     */
    function failSafe(address payable _toUser, uint _amount) external onlyOwner returns(bool) {
        require(_toUser != address(0), "Invalid Address");
        require((address(this).balance) >= _amount, "SeekReward: insufficient amount");
        _toUser.transfer( _amount);
        return true;
    }

    /**
     * @dev isContract: Returns true if account is a contract
     */
    function isContract(address _account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(_account)
        }
        if (size != 0)
            return true;
        return false;
    }
}