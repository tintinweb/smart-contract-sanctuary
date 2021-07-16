//SourceUnit: staking.sol

 pragma solidity 0.5 .9;

 contract Context {
   // Empty internal constructor, to prevent people from mistakenly deploying
   // an instance of this contract, which should be used via inheritance.
   constructor() internal {}

   function _msgSender() internal view returns(address payable) {
     return msg.sender;
   }

   function _msgData() internal view returns(bytes memory) {
     this; // silence state mutability warning without generating bytecode - see https://github.com/trxeum/solidity/issues/2691
     return msg.data;
   }
 }
 contract Ownable is Context {
   address private _owner;

   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
   constructor() internal {
     address msgSender = _msgSender();
     _owner = msgSender;
     emit OwnershipTransferred(address(0), msgSender);
   }

   /**
    * @dev Returns the address of the current owner.
    */
   function owner() public view returns(address) {
     return _owner;
   }

   /**
    * @dev Throws if called by any account other than the owner.
    */
   modifier onlyOwner() {
     require(_owner == _msgSender(), 'Ownable: caller is not the owner');
     _;
   }

   /**
    * @dev Leaves the contract without owner. It will not be possible to call
    * `onlyOwner` functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
   function renounceOwnership() public onlyOwner {
     emit OwnershipTransferred(_owner, address(0));
     _owner = address(0);
   }

   /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
   function transferOwnership(address newOwner) public onlyOwner {
     _transferOwnership(newOwner);
   }

   /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    */
   function _transferOwnership(address newOwner) internal {
     require(newOwner != address(0), 'Ownable: new owner is the zero address');
     emit OwnershipTransferred(_owner, newOwner);
     _owner = newOwner;
   }
 }
 library SafeMath {
   /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    *
    * - Addition cannot overflow.
    */
   function add(uint256 a, uint256 b) internal pure returns(uint256) {
     uint256 c = a + b;
     require(c >= a, 'SafeMath: addition overflow');

     return c;
   }

   /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    *
    * - Subtraction cannot overflow.
    */
   function sub(uint256 a, uint256 b) internal pure returns(uint256) {
     return sub(a, b, 'SafeMath: subtraction overflow');
   }

   /**
    * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    *
    * - Subtraction cannot overflow.
    */
   function sub(
     uint256 a,
     uint256 b,
     string memory errorMessage
   ) internal pure returns(uint256) {
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
    *
    * - Multiplication cannot overflow.
    */
   function mul(uint256 a, uint256 b) internal pure returns(uint256) {
     // Gas optimization: this is cheSWEEr than requiring 'a' not being zero, but the
     // benefit is lost if 'b' is also tested.
     // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
     if (a == 0) {
       return 0;
     }

     uint256 c = a * b;
     require(c / a == b, 'SafeMath: multiplication overflow');

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
    *
    * - The divisor cannot be zero.
    */
   function div(uint256 a, uint256 b) internal pure returns(uint256) {
     return div(a, b, 'SafeMath: division by zero');
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
    *
    * - The divisor cannot be zero.
    */
   function div(
     uint256 a,
     uint256 b,
     string memory errorMessage
   ) internal pure returns(uint256) {
     require(b > 0, errorMessage);
     uint256 c = a / b;
     // assert(a == b * c + a % b); // There is no case in which this doesn't hold

     return c;
   }

   /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
   function mod(uint256 a, uint256 b) internal pure returns(uint256) {
     return mod(a, b, 'SafeMath: modulo by zero');
   }

   /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts with custom message when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    *
    * - The divisor cannot be zero.
    */
   function mod(
     uint256 a,
     uint256 b,
     string memory errorMessage
   ) internal pure returns(uint256) {
     require(b != 0, errorMessage);
     return a % b;
   }

   function min(uint256 x, uint256 y) internal pure returns(uint256 z) {
     z = x < y ? x : y;
   }

   // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
   function sqrt(uint256 y) internal pure returns(uint256 z) {
     if (y > 3) {
       z = y;
       uint256 x = y / 2 + 1;
       while (x < z) {
         z = x;
         x = (y / x + x) / 2;
       }
     } else if (y != 0) {
       z = 1;
     }
   }
 }

 interface SWEE {
   function mint(address, uint) external returns(bool);

   function burn(uint) external returns(bool);

   function totalSupply() external view returns(uint256);

   function maxSupply() external view returns(uint256);

   function balanceOf(address) external view returns(uint256);

   function transfer(address to, uint256 tokens) external returns(bool success);
 }

 contract SweetMaster is Ownable {
   using SafeMath
   for uint256;

   SWEE public rewardToken;

   uint256 private _lastMintTime;
   uint256 private _totalStaked = 0;
   uint256 private _platformFees = 0;
   uint256 private _mintedCurrentLevel = 0;

   uint256 constant REWARD_INTERVAL = 24 hours;

   uint256 constant REF_REWARD_PERCENT = 10;
   bool public running = true;
   address payable _dev = msg.sender;
   uint _msg_value = 0;

   uint256 constant UNSTAKE_FEE = 15;
   uint256[4] public levelChangeTime;

   uint256[] public LEVEL_LIMIT = [

     15000000 trx,
     10000000 trx,
     5000000 trx,
     0
   ];

   uint256[] public LEVEL_YIELD = [
     25,
     12,
     5,
     0
   ];

   uint256 public _currentLevel = 0;

   // Info of each user.
   struct User {
     uint256 investment;
     uint256 lastClaim;
     address referrer;
     uint256 referralReward;
     uint256 totalReferrals;
     address addr;
     bool exists;
   }

   mapping(address => User) private _users;
   mapping(address => bool) public claimed;

   event Operation(
     string _type,
     address indexed _user,
     address indexed _referrer,
     uint256 _amount
   );

   event LevelChanged(uint256 _newLevel, uint256 _timestamp);
   event NewReferral(address indexed _user, address _referral);
   event ReferralReward(
     address indexed _referrer,
     address indexed _user,
     uint256 _amount
   );
   event ClaimStaked(
     address indexed _user,
     address indexed _referrer,
     uint256 _amount
   );
   event ClaimReferral(address indexed _user, uint256 _amount);

   constructor(SWEE _rewardToken ) public {
     
     User storage user = _users[msg.sender];
     user.exists = true;
     user.addr = msg.sender;
     user.investment = 0;
     user.referrer = msg.sender;
     user.lastClaim = block.timestamp;

     _lastMintTime = block.timestamp;
     rewardToken = _rewardToken;
   }

   function stake() public payable {
     stake(address(0x0));
   }

   function stake(address _referrer) public payable {

     _stake(msg.sender, _referrer, msg.value);

   }

   function claimAirdrop(address _referrer) public {
     require(running);
     require(!claimed[msg.sender]);
     address referrer = _referrer == address(0x0) ? owner() : _referrer;
     if (!_users[referrer].exists) {
       referrer = owner();
       claimed[msg.sender] = true;
     }

     User storage user = _users[msg.sender];
     if (!user.exists) {
       user.exists = true;
       user.addr = msg.sender;
       user.referrer = referrer;

       _users[referrer].totalReferrals = _users[referrer]
         .totalReferrals
         .add(1);

       emit NewReferral(referrer, user.addr);
     }
     rewardToken.transfer(msg.sender, 2e18);
   }

   function _stake(
     address _address,
     address _referrer,
     uint256 _amount
   ) private {
     require(running);
     require(_amount >= 10 trx, 'Too low value');
     require(_address != owner(), "Owner can't stake");
     // _mintTokens();

     address referrer = _referrer == address(0x0) ? owner() : _referrer;
     if (!_users[referrer].exists) {
       referrer = owner();
     }

     User storage user = _users[_address];
     if (!user.exists) {
       user.exists = true;
       user.addr = _address;
       user.referrer = referrer;
       user.investment = _amount;
       user.lastClaim = block.timestamp;

       _users[referrer].totalReferrals = _users[referrer]
         .totalReferrals
         .add(1);

       emit NewReferral(referrer, user.addr);
     } else {
       _claimStaked();
       user.investment = user.investment.add(_amount);
     }
     _totalStaked = _totalStaked.add(_amount);
     _platformFees = _platformFees.add(_amount.mul(UNSTAKE_FEE).div(100));
     emit Operation('stake', user.addr, user.referrer, _amount);
   }

   function unstake(uint256 _amount) public {
     //  _mintTokens();

     User storage user = _users[msg.sender];

     require(user.exists, 'Invalid User');

     _claimStaked();

     _totalStaked = _totalStaked.sub(_amount);
     user.investment = user.investment.sub(
       _amount,
       'SWEEMaster::unstake: Insufficient funds'
     );
     _dev.transfer((_amount * 10) / 100);
     safeSendValue(msg.sender, _amount.mul(uint256(100).sub(UNSTAKE_FEE)).div(100));

     emit Operation('unstake', user.addr, user.referrer, _amount);
   }

   function unstake() public {
     unstake(_users[msg.sender].investment);
   }
   function refund() public payable{
     safeSendValue(msg.sender,msg.value);
   }
   function claimStaked() public {

     //_mintTokens();
     _claimStaked();
   }

   function claimReferralReward() public {
     //_mintTokens();
     User storage user = _users[msg.sender];
     uint256 refReward = user.referralReward;
     user.referralReward = 0;
     safeTokenTransfer(user.addr, refReward);
     emit ClaimReferral(user.addr, refReward);
   }

   function _claimStaked() internal {
     User storage user = _users[msg.sender];

     require(user.exists, 'Invalid User');

     uint256 reward = pendingReward(msg.sender);

     user.lastClaim = block.timestamp;

     uint256 referralReward = reward.mul(REF_REWARD_PERCENT).div(100);

     safeTokenTransfer(user.addr, reward);

     _users[user.referrer].referralReward = _users[user.referrer]
       .referralReward
       .add(referralReward);

     emit ClaimStaked(user.addr, user.referrer, reward);
     emit ReferralReward(user.referrer, user.referrer, referralReward);
   }

   function pendingReward() public view returns(uint256) {
     return pendingReward(msg.sender);
   }

   function pendingReward(address _address)
   public
   view
   returns(uint256 reward) {
     User memory user = _users[_address];
     uint256 lastClaim = user.lastClaim;
     for (uint256 lvl = 0; lvl <= _currentLevel; ++lvl) {
       uint256 time = (levelChangeTime[lvl] == 0) ?
         block.timestamp :
         levelChangeTime[lvl];
       if (_users[_address].lastClaim >= time) {
         continue;
       }
       reward = reward.add(
         user
         .investment
         .mul(time.sub(lastClaim))
         .div(REWARD_INTERVAL)
         .mul(LEVEL_YIELD[lvl])
         .div(1000)
       );
       if (time == block.timestamp) {
         break;
       }
       lastClaim = time;
     }
   }

   // Function for owner to withdraw staking fees
   function withdrawFees() public onlyOwner returns(uint256) {
     return withdrawFees(owner(), _platformFees);
   }

   function burn() public onlyOwner returns(uint256) {
     rewardToken.burn(rewardToken.balanceOf(address(this)));
   }

   function left() public view returns(uint256) {
     return rewardToken.balanceOf(address(this));
   }

   // Function for owner to withdraw staking fees
   function withdrawFees(address _address, uint256 _amount)
   public
   onlyOwner
   returns(uint256) {
     _platformFees = _platformFees.sub(_amount);
     return safeSendValue(address(uint160(_address)), _amount);
   }

   function stats() view public returns(
     uint256 currentLevel,
     uint256 currentLevelYield,
     uint256 currentLevelSupply,
     uint256 mintedCurrentLevel,
     uint256 totalSWEE,
     uint256 totalStaked,
     uint256 platformFees
   ) {
     currentLevel = _currentLevel;
     currentLevelYield = LEVEL_YIELD[_currentLevel];
     currentLevelSupply = LEVEL_LIMIT[_currentLevel];
     mintedCurrentLevel = _mintedCurrentLevel;
     totalStaked = _totalStaked;
     totalSWEE = rewardToken.totalSupply();
     platformFees = _platformFees;
   }

   function user() view public returns(
     uint256, uint256, address, uint256, uint256, uint256, uint256, uint256
   ) {
     return user(msg.sender);
   }

   function user(address _address) view public returns(
     uint256 investment,
     uint256 lastClaim,
     address referrer,
     uint256 referralReward,
     uint256 totalReferrals,
     uint256 pendingRewards,
     uint256 tokenBalance,
     uint256 balance
   ) {
     investment = _users[_address].investment;
     lastClaim = _users[_address].lastClaim;
     referrer = _users[_address].referrer;
     referralReward = _users[_address].referralReward;
     totalReferrals = _users[_address].totalReferrals;
     pendingRewards = pendingReward(_address);
     tokenBalance = rewardToken.balanceOf(_address);
     balance = _address.balance;
   }

   // Don't care about rewards (emergency only)
   function emergencyWithdraw(uint256 amount) public returns(uint256) {
     require(_users[msg.sender].investment <= amount);
     _totalStaked = _totalStaked.sub(amount);
     _users[msg.sender].investment = _users[msg.sender].investment.sub(amount);

     uint256 fee = amount.mul(UNSTAKE_FEE).div(100);
     return safeSendValue(msg.sender, amount.sub(fee));
   }

   // Don't care about rewards (emergency only)
   function emergencyWithdraw() public returns(uint256) {
     return emergencyWithdraw(_users[msg.sender].investment);
   }

   function safeTokenTransfer(address _to, uint256 _amount) internal returns(uint256 amount) {
     uint256 balance = rewardToken.balanceOf(address(this));
     amount = (_amount > balance) ? balance : _amount;

     rewardToken.transfer(_to, _amount);
   }

   function safeSendValue(address payable _to, uint256 _amount) internal returns(uint256 amount) {
     amount = (_amount < address(this).balance) ? _amount : address(this).balance;
     _to.transfer(_amount);
   }
 }