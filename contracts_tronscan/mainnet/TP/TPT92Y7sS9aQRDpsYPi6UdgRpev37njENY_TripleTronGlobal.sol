//SourceUnit: TripleTronGlobal.sol

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

contract TripleTronGlobal {
	using SafeMath for uint;

	bool public contractStatus;
	uint public created;
	uint public levelDown;
	uint public last_uid;
	uint public maxLevel = 6;
	uint public referralLimit = 3;
	address public owner;
	address public creator;
	mapping(uint => mapping(address => User)) public users;
	mapping(uint => address) public userAddresses;
	mapping(uint => uint) public levelPrice;
	mapping(uint => uint) public uplines;
	mapping(uint => uint) public incentive;
	mapping(uint => mapping(uint => uint)) public directReferrals;
	mapping(address => uint) public usersLevels;
	mapping(uint => uint[]) paymentQueue;
	mapping(uint => uint) paymentCursor;
	mapping(uint => uint) earningCondition;
	mapping(address => ProfitsReceived) public profitsReceived;
	mapping(address => ProfitsLost) public profitsLost;

	event RegisterUserEvent(address indexed user, address indexed referrer, uint time);
	event BuyLevelEvent(address indexed user, uint indexed level, uint time);
	event GetLevelProfitEvent(address indexed user, address indexed referral, uint indexed level, uint time);
	event LostLevelProfitEvent(address indexed user, address indexed referral, uint indexed level, uint time);

	uint public decimals;
	uint public totalSupply;
	uint public rate;
	uint public maxTokenAmount;
	string public name;
	string public symbol;
	mapping(address => uint) public balances;

	event Transfer(address from, address to, uint amount, uint time);

	struct User {
		uint id;
		uint referrerID;
		uint sponsorID;
		address[] referrals;
		address[] directReferrals;
		mapping(uint => uint) levelActivationTime;
		uint created;
	}

	struct ProfitsReceived {
		uint uid;
		uint[] fromId;
		address[] fromAddr;
		uint[] amount;
		uint[] level;
	}
		
	struct ProfitsLost {
		uint uid;
		uint[] toId;
		address[] toAddr;
		uint[] amount;
		uint[] level;
	}

	modifier contractActive() {
		require(contractStatus == true);
		_;
	}
	modifier validLevelAmount(uint _level) {
		require(msg.value == levelPrice[_level], 'Invalid level amount sent');
		_;
	}
	modifier userRegistered() {
		require(users[1][msg.sender].id != 0, 'User does not exist');
		_;
	}
	modifier validReferrerID(uint _referrerID) {
		require(_referrerID > 0 && _referrerID <= last_uid, 'Invalid referrer ID');
		require(users[1][msg.sender].id != _referrerID, 'Refer ID cannot be same as User ID');
		_;
	}
	modifier userNotRegistered() {
		require(users[1][msg.sender].id == 0, 'User is already registered');
		_;
	}
	modifier validLevel(uint _level) {
		require(_level > 0 && _level <= maxLevel, 'Invalid level entered');
		_;
	}
	modifier checkTotalSupply() {
		require(_getTokenAmount(msg.value).add(totalSupply) < maxTokenAmount, "Maximum token amount crossed");
		_;
	}
	modifier checkTotalSupplyWithAmount(uint amount) {
		require(amount.add(totalSupply) < maxTokenAmount, "Maximum token amount crossed");
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
		require(last_uid <= 1000, 'The last id has past the v1 last id');
		_;
	}

	constructor(address _owner) public {
		contractStatus = true;
		name = "TripleTron";
		symbol = "TPX";
		owner = _owner;
		creator = msg.sender;
		created = block.timestamp;
		totalSupply = 0;
		decimals = 3;
		rate = 100;
		maxTokenAmount = 500000000 * (10 ** decimals);
		levelDown = 5;
		uint multiplier = 1000000;
		levelPrice[1] = 100 * multiplier;
		levelPrice[2] = 500 * multiplier;
		levelPrice[3] = 1000 * multiplier;
		levelPrice[4] = 3000 * multiplier;
		levelPrice[5] = 10000 * multiplier;
		levelPrice[6] = 30000 * multiplier;
		uplines[1] = 5;
		uplines[2] = 6;
		uplines[3] = 7;
		uplines[4] = 8;
		uplines[5] = 9;
		uplines[6] = 10;
		incentive[1] = 18 * multiplier;
		incentive[2] = 75 * multiplier;
		incentive[3] = 128 * multiplier;
		incentive[4] = 325 * multiplier;
		incentive[5] = 1000 * multiplier;
		incentive[6] = 2750 * multiplier;
		earningCondition[1] = 0;
		earningCondition[2] = 3;
		earningCondition[3] = 3;
		earningCondition[4] = 3;
		earningCondition[5] = 3;
		earningCondition[6] = 3;

		last_uid++;
		for (uint i = 1; i <= maxLevel; i++) {
			users[i][creator] = User({
				id : last_uid,
				referrerID : 0,
				sponsorID: 0,
				referrals : new address[](0),
				directReferrals : new address[](0),
				created : block.timestamp
			});
			directReferrals[i][last_uid] = maxLevel * 3;
			if (i > 1) {
				paymentQueue[i].push(last_uid);

			}
		}
		
		userAddresses[last_uid] = creator;
		usersLevels[creator] = maxLevel;
	}

	function changeOwner(address newOwner) 
	public 
	onlyOwner() {
		owner = newOwner;
	}

	function changeLevelPrice1(uint newValue)
	public
	onlyCreator() {
		levelPrice[1] = newValue;
	}

	function changeLevelPrice2(uint newValue)
	public
	onlyCreator() {
		levelPrice[2] = newValue;
	}

	function changeLevelPrice3(uint newValue)
	public
	onlyCreator() {
		levelPrice[3] = newValue;
	}

	function changeLevelPrice4(uint newValue)
	public
	onlyCreator() {
		levelPrice[4] = newValue;
	}

	function changeLevelPrice5(uint newValue)
	public
	onlyCreator() {
		levelPrice[5] = newValue;
	}

	function changeLevelPrice6(uint newValue)
	public
	onlyCreator() {
		levelPrice[6] = newValue;
	}

	function changeUplines1(uint newValue)
	public
	onlyCreator() {
		uplines[1] = newValue;
	}

	function changeUplines2(uint newValue)
	public
	onlyCreator() {
		uplines[2] = newValue;
	}

	function changeUplines3(uint newValue)
	public
	onlyCreator() {
		uplines[3] = newValue;
	}

	function changeUplines4(uint newValue)
	public
	onlyCreator() {
		uplines[4] = newValue;
	}

	function changeUplines5(uint newValue)
	public
	onlyCreator() {
		uplines[5] = newValue;
	}

	function changeUplines6(uint newValue)
	public
	onlyCreator() {
		uplines[6] = newValue;
	}

	function changeIncentive1(uint newValue)
	public
	onlyCreator() {
		incentive[1] = newValue;
	}

	function changeIncentive2(uint newValue)
	public
	onlyCreator() {
		incentive[2] = newValue;
	}

	function changeIncentive3(uint newValue)
	public
	onlyCreator() {
		incentive[3] = newValue;
	}

	function changeIncentive4(uint newValue)
	public
	onlyCreator() {
		incentive[4] = newValue;
	}

	function changeIncentive5(uint newValue)
	public
	onlyCreator() {
		incentive[5] = newValue;
	}

	function changeIncentive6(uint newValue)
	public
	onlyCreator() {
		incentive[6] = newValue;
	}

	function changeEarningCondition(uint _level, uint value) public onlyCreator() {
		earningCondition[_level] = value;
	}

	function changeContractStatus(bool newValue)
	public
	onlyCreator() {
		contractStatus = newValue;
	}

	function changeLevelDown(uint newValue)
	public
	onlyCreator() {
		levelDown = newValue;
	}

	function() external payable {
		revert();
	}

	function transfer(address receiver, uint amount) public {
		require(amount <= balances[msg.sender], "Insufficient balance.");

		balances[msg.sender] = balances[msg.sender].sub(amount);
		balances[receiver] = balances[receiver].add(amount);

		emit Transfer(msg.sender, receiver, amount, block.timestamp);
	}

	function mint(uint amount)
	public
	onlyCreator()
	checkTotalSupplyWithAmount(amount) {
		balances[creator] = balances[creator].add(amount);
		totalSupply = totalSupply.add(amount);
	}

	function balanceOf(address _user) public view returns (uint) {
		return balances[_user];
	}

	function _getTokenAmount(uint _weiAmount) internal view returns (uint) {
		uint tokenAmount = _weiAmount;
		tokenAmount = tokenAmount.mul(rate);
		tokenAmount = tokenAmount.div(100 * (10 ** decimals));
		return tokenAmount;
	}

	function registerUser(uint _referrerID, uint randNum)
	public
	payable
	userNotRegistered()
	validReferrerID(_referrerID)
	checkTotalSupply()
	contractActive()
	validLevelAmount(1) {
		uint amount = _getTokenAmount(msg.value);
		balances[msg.sender] = balances[msg.sender].add(amount);
		totalSupply = totalSupply.add(amount);

		directReferrals[1][_referrerID] += 1;
		users[1][userAddresses[_referrerID]].directReferrals.push(msg.sender);
		uint sponsorID = _referrerID;
		if (users[1][userAddresses[_referrerID]].referrals.length >= referralLimit) {
			_referrerID = users[1][findReferrer(userAddresses[_referrerID], 1, true, randNum)].id;
		}
		last_uid++;
		users[1][msg.sender] = User({
			id : last_uid,
			referrerID : _referrerID,
			sponsorID: sponsorID,
			referrals : new address[](0),
			directReferrals : new address[](0),
			created : block.timestamp
		});

		userAddresses[last_uid] = msg.sender;
		usersLevels[msg.sender] = 1;
		users[1][userAddresses[_referrerID]].referrals.push(msg.sender);

		transferLevelPayment(1, msg.sender);

		emit RegisterUserEvent(msg.sender, userAddresses[_referrerID], block.timestamp);
	}

	function buyLevel(uint _level)
	public
	payable
	userRegistered()
	validLevel(_level)
	checkTotalSupply()
	contractActive()
	validLevelAmount(_level) {
		uint amount = _getTokenAmount(msg.value);
		balances[msg.sender] = balances[msg.sender].add(amount);
		totalSupply = totalSupply.add(amount);

		for (uint l = _level - 1; l > 0; l--) {
			require(users[l][msg.sender].id > 0, 'Buy previous level first');
		}
		require(users[_level][msg.sender].id == 0, 'Level already active');

		directReferrals[_level][users[1][msg.sender].sponsorID]++;
		uint _referrerID = getUserToPay(_level);
		
		users[_level][msg.sender] = User({
			id : users[1][msg.sender].id,
			sponsorID: users[1][msg.sender].sponsorID,
			referrerID : _referrerID,
			referrals : new address[](0),
			directReferrals: new address[](0),
			created : block.timestamp
		});
		usersLevels[msg.sender] = _level;
		users[_level][userAddresses[_referrerID]].referrals.push(msg.sender);
		paymentQueue[_level].push(users[1][msg.sender].id);
		transferLevelPayment(_level, msg.sender);
		emit BuyLevelEvent(msg.sender, _level, block.timestamp);
	}

	function getUserToPay(uint _level) internal returns(uint) {
		uint _default;
		for(uint i = paymentCursor[_level]; i < paymentQueue[_level].length; i++) {
			uint userID = paymentQueue[_level][paymentCursor[_level]];
			if(users[_level][userAddresses[userID]].referrals.length >= referralLimit) {
				paymentCursor[_level]++;
				continue;
			}
			// default to the first free account
			if(_default == 0) {
				_default = userID;
			}
			if (canReceiveLevelPayment(userID, _level)) {
				return userID;
			}
			(paymentQueue[_level][i], paymentQueue[_level][paymentCursor[_level]]) = (paymentQueue[_level][paymentCursor[_level]], paymentQueue[_level][i]);
		}
		// the last person on the queue is now ocupying the first position. let's move him back
		paymentQueue[_level].push(paymentQueue[_level][paymentCursor[_level]]);
		paymentCursor[_level]++;
		// 22950
		// 40050 => 
		// 150200 => 30% => platinum
		// 405000 => 120,000 => 30%

		return _default;
	}

	function canReceiveLevelPayment(uint _userID, uint _level) internal returns (bool){
		if (directReferrals[_level][_userID] == 0) {
			uint count;
			for(uint i = 0; i < users[1][userAddresses[_userID]].referrals.length; i++){
				if (users[_level][users[1][userAddresses[_userID]].referrals[i]].id > 0) {
					count ++;
				}
			}
			directReferrals[_level][_userID] = count;
		}
		return directReferrals[_level][_userID] >= earningCondition[_level];
	}


	function insertV1User(address _user, uint _id, uint _referrerID, uint _created, uint _level, uint cumDirectDownlines, uint randNum) 
	public
	onlyCreator()
	onlyForUpgrade()
	{
		require(users[1][_user].id == 0, 'User is already registered');
		if (users[1][userAddresses[_referrerID]].referrals.length >= referralLimit) {
			_referrerID = users[1][findReferrer(userAddresses[_referrerID], 1, true, randNum)].id;
		}
		if (_id > last_uid) {
			last_uid = _id;
		}
		
		users[1][_user] = User({
			id : _id,
			referrerID : _referrerID,
			sponsorID: _referrerID,
			referrals : new address[](0),
			directReferrals : new address[](0),
			created : _created
		});
		userAddresses[_id] = _user;
		users[1][userAddresses[_referrerID]].referrals.push(userAddresses[_id]);
		users[1][userAddresses[_referrerID]].directReferrals.push(userAddresses[_id]);
		directReferrals[1][_referrerID]++;

		insertV1LevelPayment(1, userAddresses[_id]);
		emit RegisterUserEvent(userAddresses[_id], userAddresses[_referrerID], _created);

		for (uint l = 2; l <= _level; l++) {
			uint _refID = users[l][findReferrer(userAddresses[1], l, true, randNum)].id;
			users[l][userAddresses[_id]] = User({
				id : _id,
				referrerID : _refID,
				sponsorID: _referrerID,
				referrals : new address[](0),
				directReferrals : new address[](0),
				created : _created
			});
			users[l][userAddresses[_refID]].referrals.push(userAddresses[_id]);
			paymentQueue[l].push(_id);
			if (cumDirectDownlines/3 >= l) {
				directReferrals[l][_id] = 3;
			}
			emit BuyLevelEvent(userAddresses[_id], l, _created);
		}

		usersLevels[userAddresses[_id]] = _level;
	}

	function updateDirectReferralCount() public onlyCreator() onlyForUpgrade() {
		for(uint id = 1; id <= last_uid; id++) {
			for (uint level = 1; level <= maxLevel; level++) {
				if (directReferrals[level][id] == 0) {
					uint count;
					for(uint i = 0; i < users[1][userAddresses[id]].referrals.length; i++) {
						if(users[level][users[1][userAddresses[id]].referrals[i]].created > 0) {
							count++;
						}
					}
					directReferrals[level][id] = count;
				}
			}
		}
	}

	function findReferrer(address _user, uint level, bool traverseDown, uint randNum)
	public
	view
	returns (address) {
		if (users[level][_user].referrals.length < referralLimit) {
			return _user;
		}

		uint arraySize = 3 * ((3 ** levelDown) - 1);
		uint previousLineSize = 3 * ((3 ** (levelDown - 1)) - 1);
		address referrer;
		address[] memory referrals = new address[](arraySize);
		referrals[0] = users[level][_user].referrals[0];
		referrals[1] = users[level][_user].referrals[1];
		referrals[2] = users[level][_user].referrals[2];

		for (uint i = 0; i < arraySize; i++) {
			if (users[level][referrals[i]].referrals.length < referralLimit) {
				referrer = referrals[i];
				break;
			}

			if (i < previousLineSize) {
				referrals[(i + 1) * 3] = users[level][referrals[i]].referrals[0];
				referrals[(i + 1) * 3 + 1] = users[level][referrals[i]].referrals[1];
				referrals[(i + 1) * 3 + 2] = users[level][referrals[i]].referrals[2];
			}
		}

		if (referrer == address(0) && traverseDown == true) {
			if (randNum >= previousLineSize && randNum < arraySize) {
				address childAddress = findReferrer(referrals[randNum], level, false, randNum);
				if (childAddress != address(0)) {
					referrer = childAddress;
				}
			}

			if (referrer == address(0)) {
				for (uint i = previousLineSize; i < arraySize; i++) {
					address childAddress = findReferrer(referrals[i], level, false, randNum);
					if (childAddress != address(0)) {
						referrer = childAddress;
						break;
					}
				}
			}
			require(referrer != address(0), 'Referrer not found');
		}

		return referrer;
	}

	function transferLevelPayment(uint _level, address _user) internal {
		address referrer;
		uint sentValue = 0;

		for (uint i = 1; i <= uplines[_level]; i++) {
			referrer = getUserUpline(_user, _level, i);
			if (referrer == address(0)) {
				referrer = owner;
			}
			if (canReceiveLevelPayment(users[1][referrer].id, _level)) {
				profitsReceived[referrer].uid = users[_level][referrer].id;
				profitsReceived[referrer].fromId.push(users[_level][msg.sender].id);
				profitsReceived[referrer].fromAddr.push(msg.sender);
				profitsReceived[referrer].amount.push(incentive[_level]);
				profitsReceived[referrer].level.push(_level);

				address(uint160(referrer)).transfer(incentive[_level]);
				emit GetLevelProfitEvent(_user, referrer, _level, block.timestamp);
			} else {
				profitsLost[referrer].uid = users[_level][referrer].id;
				profitsLost[referrer].toId.push(users[_level][msg.sender].id);
				profitsLost[referrer].toAddr.push(msg.sender);
				profitsLost[referrer].amount.push(incentive[_level]);
				profitsLost[referrer].level.push(_level);

				address(uint160(owner)).transfer(incentive[_level]);
				emit LostLevelProfitEvent(_user, referrer, _level, block.timestamp);
			}
			sentValue += incentive[_level];
		}

		address(uint160(owner)).transfer(msg.value - sentValue);
	}

	function insertV1LevelPayment(uint _level, address _user) internal {
		address referrer;

		for (uint i = 1; i <= uplines[_level]; i++) {
			referrer = getUserUpline(_user, _level, i);
			if (referrer == address(0)) {
				referrer = owner;
			}

			profitsReceived[referrer].uid = users[_level][referrer].id;
			profitsReceived[referrer].fromId.push(users[_level][msg.sender].id);
			profitsReceived[referrer].fromAddr.push(msg.sender);
			profitsReceived[referrer].amount.push(incentive[_level]);
			profitsReceived[referrer].level.push(_level);

			emit GetLevelProfitEvent(_user, referrer, _level, block.timestamp);
		}
	}

	function getUserUpline(address _user, uint _level, uint height)
	public
	view
	returns (address) {
		if (height <= 0 || _user == address(0)) {
			return _user;
		}
		return getUserUpline(userAddresses[users[_level][_user].referrerID], _level, height - 1);
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

	function getUserRecruit(address _user)
	public
	view
	returns (uint) {
		return directReferrals[1][users[1][_user].id];
	}

	function getLevelActivationTime(address _user, uint _level)
	public
	view
	returns (uint) {
		return users[_level][_user].created;
	}

	function getUserProfits(address _user)
	public
	view
	returns (uint[] memory, address[] memory, uint[] memory, uint[] memory){
		return (profitsReceived[_user].fromId, profitsReceived[_user].fromAddr, profitsReceived[_user].amount, profitsReceived[_user].level);
	}

	function getUserLosts(address _user)
	public
	view
	returns (uint[] memory, address[] memory, uint[] memory, uint[] memory){
		return (profitsLost[_user].toId, profitsLost[_user].toAddr, profitsLost[_user].amount, profitsLost[_user].level);
	}

	function getUserLevel(address _user) public view returns (uint) {
		if (getLevelActivationTime(_user, 1) == 0) {
			return (0);
		}
		else if (getLevelActivationTime(_user, 2) == 0) {
			return (1);
		}
		else if (getLevelActivationTime(_user, 3) == 0) {
			return (2);
		}
		else if (getLevelActivationTime(_user, 4) == 0) {
			return (3);
		}
		else if (getLevelActivationTime(_user, 5) == 0) {
			return (4);
		}
		else if (getLevelActivationTime(_user, 6) == 0) {
			return (5);
		}
		else {
			return (6);
		}
	}

	function getUserDetails(address _user) public view returns (uint, uint, address) {
		if (getLevelActivationTime(_user, 1) == 0) {
			return (0, users[1][_user].id, userAddresses[users[1][_user].sponsorID]);
		}
		else if (getLevelActivationTime(_user, 2) == 0) {
			return (1, users[1][_user].id, userAddresses[users[1][_user].sponsorID]);
		}
		else if (getLevelActivationTime(_user, 3) == 0) {
			return (2, users[2][_user].id, userAddresses[users[1][_user].sponsorID]);
		}
		else if (getLevelActivationTime(_user, 4) == 0) {
			return (3, users[3][_user].id, userAddresses[users[1][_user].sponsorID]);
		}
		else if (getLevelActivationTime(_user, 5) == 0) {
			return (4, users[4][_user].id, userAddresses[users[1][_user].sponsorID]);
		}
		else if (getLevelActivationTime(_user, 6) == block.timestamp) {
			return (5, users[5][_user].id, userAddresses[users[1][_user].sponsorID]);
		}
		else {
			return (6, users[6][_user].id, userAddresses[users[1][_user].sponsorID]);
		}
	}

}