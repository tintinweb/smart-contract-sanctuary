//SourceUnit: SafeMath.sol

pragma solidity ^0.5.8;

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
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
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
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
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
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

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
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
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
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}


//SourceUnit: TripleTronGPL.sol

// Triple Tron Global Powerline
pragma solidity ^0.5.8;

import './SafeMath.sol';

interface TripleTronGlobalInterface {
	function getUserDetails(address _user) external view returns (uint, uint, address);
	function userAddresses(uint _id) external view returns(address);
}
contract TripleTronGPL {
	using SafeMath for uint;

	bool public contractStatus;
	uint public created;
	uint public maxLevel = 6;
	uint public referralLimit = 3;
	uint multiplier = 1000000;
	address public owner;
	address public creator;
	mapping(uint => mapping(address => User)) public users;
	mapping(uint => mapping(uint => uint)) public directReferrals;
	mapping(uint => mapping(uint => uint)) public qualifiedDirectReferrals;
	mapping(address => uint) public usersLevels;
	mapping(uint => uint[]) paymentQueue;
	mapping(uint => uint) paymentCursor;
	mapping(uint => uint) currentPaymentCount;
	mapping(uint => uint) insertCursor;

	TripleTronGlobalInterface main;

	event RegisterUserEvent(address indexed user, address indexed referrer, uint time);
	event BuyLevelEvent(address indexed user, uint indexed level, uint time);
	event GetLevelProfitEvent(address indexed user, address indexed referral, uint indexed level, uint time);

	event Transfer(address from, address to, uint amount, uint time);

	struct User {
		uint id;
		uint referrerID;
		uint sponsorID;
		uint position;
		address[] referrals;
		mapping(uint => uint) levelActivationTime;
		uint created;
	}

	modifier contractActive() {
		require(contractStatus == true);
		_;
	}
	modifier validLevelAmount(uint _level) {
		require(msg.value == levelPrice(_level), 'Invalid level amount sent');
		_;
	}
	modifier userRegistered() {
		(uint id,) = getMainUserInfo(msg.sender);
		require(id != 0, 'User does not exist');
		_;
	}
	modifier validLevel(uint _level) {
		require(_level > 0 && _level <= maxLevel, 'Invalid level entered');
		_;
	}
	modifier onlyCreator() {
		require(msg.sender == creator, 'You are not the creator');
		_;
	}
	modifier onlyOwner() {
		require(msg.sender == owner, 'You are not the owner');
		_;
	}
	modifier onlyForUpgrade() {
		require(paymentQueue[2].length <= 1000);
		_;
	}

	constructor(address _owner, address _main) public {
		contractStatus = true;
		owner = _owner;
		creator = msg.sender;
		created = block.timestamp;

		main = TripleTronGlobalInterface(_main);

		for (uint i = 2; i <= maxLevel; i++) {
			users[i][creator] = User({
				id : 1,
				referrerID : 0,
				sponsorID: 0,
				position: 0,
				referrals : new address[](0),
				created : block.timestamp
			});
			directReferrals[i][1] = 3;
			paymentQueue[i].push(1);
			paymentCursor[i] = 0;
		}
		
		usersLevels[creator] = maxLevel;
	}

	function changeOwner(address newOwner) 
	public 
	onlyOwner() {
		owner = newOwner;
	}

	function changeContractStatus(bool newValue)
	public
	onlyCreator() {
		contractStatus = newValue;
	}

	function() external payable {
		revert();
	}

	function buyLevel(uint _level)
	public
	payable
	userRegistered()
	validLevel(_level)
	contractActive()
	validLevelAmount(_level) {

		for (uint l = _level - 1; l > 1; l--) {
			require(users[l][msg.sender].id > 0, 'Buy previous level first');
		}
		require(users[_level][msg.sender].id == 0, 'Level already active');

		(uint id, address sponsorAddr) = getMainUserInfo(msg.sender);
		require(canUpgrade(id, _level), "You are not qualified to upgrade to this level");

		uint sponsorID = getMainUserID(sponsorAddr);

		directReferrals[_level][sponsorID]++;
		usersLevels[msg.sender] = _level;
		
		users[_level][msg.sender] = User({
			id : id,
			sponsorID: sponsorID,
			referrerID : 0,
			position: 0,
			referrals : new address[](0),
			created : block.timestamp
		});
		
		transferGlobalLevelPayment(_level, msg.sender);
		if (directReferrals[_level][sponsorID] == earningCondition(_level)) {
			// insert to matrix and payment queue
			addToGlobalPool(sponsorAddr, _level);
		}
		if(directReferrals[_level][id] >= earningCondition(_level)) {
			// and to matrix and payment queue
			addToGlobalPool(msg.sender, _level);
		}
		emit BuyLevelEvent(msg.sender, _level, block.timestamp);
	}

	function getMainUserInfo(address _user) internal view returns(uint, address) {
		(,uint _id, address _sponsor) = main.getUserDetails(_user);
		return (_id, _sponsor);
	}

	function getMainUserID(address _user) internal view returns(uint) {
		(uint id,) = getMainUserInfo(_user);
		return id;
	}

	function getUserAddress(uint _id) internal view returns(address) {
		return main.userAddresses(_id);
	}

	function addToGlobalPool(address _user, uint _level) internal {
		if (users[_level][_user].id == 0) {
			return;
		}
		(uint id, address sponsorAddr) = getMainUserInfo(_user);
		qualifiedDirectReferrals[_level][getMainUserID(sponsorAddr)]++;
		address parentAddr = getNextGlobalUpline(_level);
		users[_level][parentAddr].referrals.push(_user);
		users[_level][_user].referrerID = getMainUserID(parentAddr);
		users[_level][_user].position = paymentQueue[_level].length;
		paymentQueue[_level].push(id);
	}

	function getNextGlobalUpline(uint _level) internal returns(address) {
		uint userID = paymentQueue[_level][insertCursor[_level]];
		if (users[_level][getUserAddress(userID)].referrals.length >= referralLimit) {
			insertCursor[_level]++;
			return getNextGlobalUpline(_level);
		}
		return getUserAddress(userID);
	}

	function canReceiveLevelPayment(uint _userID, uint _level) internal view returns (bool){
		if (users[_level][getUserAddress(_userID)].id == 0) {
			return false;
		}
		return directReferrals[_level][_userID] >= earningCondition(_level);
	}

	function canUpgrade(uint _userID, uint _level) internal view returns (bool){
		return (qualifiedDirectReferrals[_level][_userID] >= earningCondition(_level - 1));
	}


	function insertV1User(address _user, uint _id, uint _referrerID, uint _created, 
	uint _level, uint[] memory referralsCount) 
	public
	onlyCreator()
	onlyForUpgrade()
	{
		require(users[2][_user].id == 0, 'User is already registered');

		for (uint l = 2; l <= _level; l++) {
			users[l][_user] = User({
				id : _id,
				referrerID : 0,
				sponsorID: _referrerID,
				position: 0,
				referrals : new address[](0),
				created : _created
			});
			directReferrals[l][_id] = referralsCount[l-1];
			if(directReferrals[l][_id] >= earningCondition(l)) {
				// and to matrix and payment queue
				addToGlobalPool(_user, l);
			}
			emit BuyLevelEvent(_user, l, _created);
		}

		usersLevels[_user] = _level;
	}

	function transferGlobalLevelPayment(uint _level, address _user) internal {
		uint currentID = paymentQueue[_level][paymentCursor[_level]];
		if (users[_level][getUserAddress(currentID)].referrals.length >= referralLimit ||
		 currentPaymentCount[_level] >= referralLimit) {
			movePaymentCursor(_level);
		}
		address userToPay = getUserAddress(paymentQueue[_level][paymentCursor[_level]]);

		if(userToPay == address(0)) {
			userToPay = owner;
		}
		address(uint160(userToPay)).transfer(incentive(_level));
		emit GetLevelProfitEvent(_user, userToPay, _level, block.timestamp);

		address referrer;
		uint sentValue = incentive(_level);

		for (uint i = 1; i < uplines(_level); i++) { // stop at x - 1 as the 1st user was paid outside this loop
			referrer = getUserUpline(userToPay, _level, i);
			if (referrer == address(0)) {
				referrer = owner;
			}
			address(uint160(referrer)).transfer(incentive(_level));
			emit GetLevelProfitEvent(_user, referrer, _level, block.timestamp);
			sentValue += incentive(_level);
		}

		address(uint160(owner)).transfer(msg.value - sentValue);
		currentPaymentCount[_level]++;
	}

	function movePaymentCursor(uint _level) internal {
		currentPaymentCount[_level] = 0;
		if (paymentQueue[_level].length > paymentCursor[_level] + 1) {
			paymentCursor[_level]++;
			return;
		}
		if (paymentCursor[_level] <= 3){
			if(paymentCursor[_level] != 0) {
				paymentCursor[_level] = 0;
			}
			return;
		}
		uint currentID = paymentQueue[_level][paymentCursor[_level]];
		uint parentID = users[_level][getUserAddress(currentID)].referrerID;
		paymentCursor[_level] = users[_level][getUserAddress(parentID)].position + 1;
	}

	function levelPrice(uint _level) public view returns(uint) {
		if(_level == 1) {
			return 100 * multiplier;
		}
		if(_level == 2) {
			return 500 * multiplier;
		}
		if(_level == 3) {
			return 1000 * multiplier;
		}
		if(_level == 4) {
			return 3000 * multiplier;
		}
		if(_level == 5) {
			return 10000 * multiplier;
		}
		return 30000 * multiplier;
	}

	function uplines(uint _level) public pure returns(uint) {
		if(_level == 1) {
			return 5;
		}
		if(_level == 2) {
			return 6;
		}
		if(_level == 3) {
			return 7;
		}
		if(_level == 4) {
			return 8;
		}
		if(_level == 5) {
			return 9;
		}
		return 10;
	}

	function incentive(uint _level) public view returns(uint) {
		if(_level == 1) {
			return 18 * multiplier;
		}
		if(_level == 2) {
			return 75 * multiplier;
		}
		if(_level == 3) {
			return 128 * multiplier;
		}
		if(_level == 4) {
			return 325 * multiplier;
		}
		if(_level == 5) {
			return 1000 * multiplier;
		}
		return 2750 * multiplier;
	}

	function earningCondition(uint _level) public pure returns(uint) {
		if(_level == 1) {
			return 0;
		}
		return 3;
	}

	function getUserUpline(address _user, uint _level, uint height)
	public
	view
	returns (address) {
		if (height <= 0 || _user == address(0)) {
			return _user;
		}
		return getUserUpline(getUserAddress(users[_level][_user].referrerID), _level, height - 1);
	}

	function getUser(address _user, uint _level)
	public
	view
	returns (uint, uint, address[] memory, uint) {
		return (
			users[_level][_user].id, 
			users[_level][_user].referrerID, 
			users[_level][_user].referrals, 
			users[_level][_user].created
		);
	}

	function getUserReferrals(address _user, uint _level)
	public
	view
	returns (address[] memory) {
		return users[_level][_user].referrals;
	}

	function getUserDirectReferralCounts(address _user) public view 
	returns (uint, uint, uint, uint, uint, uint){
		return (
			directReferrals[1][users[1][_user].id],
			directReferrals[2][users[1][_user].id],
			directReferrals[3][users[1][_user].id],
			directReferrals[4][users[1][_user].id],
			directReferrals[5][users[1][_user].id],
			directReferrals[6][users[1][_user].id]
		);
	}

	function getLevelActivationTime(address _user, uint _level)
	public
	view
	returns (uint) {
		return users[_level][_user].created;
	}

	function getUserLevel(address _user) public view returns (uint) {
		return usersLevels[_user];
	}

}