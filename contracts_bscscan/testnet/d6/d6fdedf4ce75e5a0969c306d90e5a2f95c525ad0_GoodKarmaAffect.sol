/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

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

contract GoodKarmaAffect {
	using SafeMath for uint;

	bool public contractStatus;
	address public owner;
	address public creator;
	uint public maxLevel = 6;
	uint public referralLimit = 2;
	uint public levelExpireTime = 90 days;
	mapping(address => User) public users;
	mapping(uint => address) public userAddresses;
	uint public last_uid;
	mapping(uint => uint) public levelPrice;
	mapping(uint => uint) public uplines;
	mapping(uint => uint) public incentive;
	mapping(address => ProfitsReceived) public profitsReceived;
	mapping(address => ProfitsLost) public profitsLost;
	uint public levelDown;

	event RegisterUserEvent(address indexed user, address indexed referrer, uint time);
	event BuyLevelEvent(address indexed user, uint indexed level, uint time);
	event GetLevelProfitEvent(address indexed user, address indexed referral, uint indexed level, uint time);
	event LostLevelProfitEvent(address indexed user, address indexed referral, uint indexed level, uint time);

	string public name;
	string public symbol;
	uint public decimals;
	mapping(address => uint) public balances;
	uint public totalSupply;
	uint public rate;
	uint public maxTokenAmount;

	event Transfer(address from, address to, uint amount, uint time);

	struct User {
		uint id;
		uint referrerID;
		address[] referrals;
		mapping(uint => uint) levelExpiresAt;
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
		require(users[msg.sender].id != 0, 'User does not exist');
		_;
	}
	modifier validReferrerID(uint _referrerID) {
		require(_referrerID > 0 && _referrerID <= last_uid, 'Invalid referrer ID');
		require(users[msg.sender].id != _referrerID, 'Refer ID cannot be same as User ID');
		_;
	}
	modifier userNotRegistered() {
		require(users[msg.sender].id == 0, 'User is already registered');
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

	constructor() public {
		contractStatus = true;
		name = "GoodKarmaAffect";
		symbol = "GKA";
		totalSupply = 0;
		decimals = 18;
		rate = 100;
		maxTokenAmount = 500000000 * (10 ** decimals);
		levelDown = 11;
		owner = 0x81ee0425D306FB195687A21BFf9AA52685B81E2D;

		last_uid++;
		creator = msg.sender;
		levelPrice[1] = 1e17;
		levelPrice[2] = 3e17;
		levelPrice[3] = 5e17;
		levelPrice[4] = 7e17;
		levelPrice[5] = 1e18;
		levelPrice[6] = 3e18;
		uplines[1] = 5;
		uplines[2] = 6;
		uplines[3] = 7;
		uplines[4] = 8;
		uplines[5] = 9;
		uplines[6] = 10;
		incentive[1] = 1.8e15;
		incentive[2] = 4.5e15;
		incentive[3] = 1e16;
		incentive[4] = 1e17;
		incentive[5] = 2e17;
		incentive[6] = 3e17;

		users[creator] = User({
		id : last_uid,
		referrerID : 0,
		referrals : new address[](0),
		created : block.timestamp
		});
		userAddresses[last_uid] = creator;

		for (uint i = 1; i <= maxLevel; i++) {
			users[creator].levelExpiresAt[i] = 1 << 37;
		}
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

		if (users[userAddresses[_referrerID]].referrals.length >= referralLimit) {
			_referrerID = users[findReferrer(userAddresses[_referrerID], true, randNum)].id;
		}
		last_uid++;
		users[msg.sender] = User({
		id : last_uid,
		referrerID : _referrerID,
		referrals : new address[](0),
		created : block.timestamp
		});
		userAddresses[last_uid] = msg.sender;
		users[msg.sender].levelExpiresAt[1] = block.timestamp + levelExpireTime;
		users[userAddresses[_referrerID]].referrals.push(msg.sender);

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
			require(getUserLevelExpiresAt(msg.sender, l) >= block.timestamp, 'Buy previous level first');
		}
		if (getUserLevelExpiresAt(msg.sender, _level) == 0) {
			users[msg.sender].levelExpiresAt[_level] = block.timestamp + levelExpireTime;
		} else {
			users[msg.sender].levelExpiresAt[_level] += levelExpireTime;
		}

		transferLevelPayment(_level, msg.sender);
		emit BuyLevelEvent(msg.sender, _level, block.timestamp);
	}

	function findReferrer(address _user, bool traverseDown, uint randNum)
	public
	view
	returns (address) {
		if (users[_user].referrals.length < referralLimit) {
			return _user;
		}

		uint arraySize = 2 * ((2 ** levelDown) - 1);
		uint previousLineSize = 2 * ((2 ** (levelDown - 1)) - 1);
		address referrer;
		address[] memory referrals = new address[](arraySize);
		referrals[0] = users[_user].referrals[0];
		referrals[1] = users[_user].referrals[1];

		for (uint i = 0; i < arraySize; i++) {
			if (users[referrals[i]].referrals.length < referralLimit) {
				referrer = referrals[i];
				break;
			}

			if (i < previousLineSize) {
				referrals[(i + 1) * 2] = users[referrals[i]].referrals[0];
				referrals[(i + 1) * 2 + 1] = users[referrals[i]].referrals[1];
			}
		}

		if (referrer == address(0) && traverseDown == true) {
			if (randNum >= previousLineSize && randNum < arraySize) {
				address childAddress = findReferrer(referrals[randNum], false, randNum);
				if (childAddress != address(0)) {
					referrer = childAddress;
				}
			}

			if (referrer == address(0)) {
				for (uint i = previousLineSize; i < arraySize; i++) {
					address childAddress = findReferrer(referrals[i], false, randNum);
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
			referrer = getUserUpline(_user, i);
			if (referrer == address(0)) {
				referrer = owner;
			}

			if (users[referrer].levelExpiresAt[_level] == 0 || users[referrer].levelExpiresAt[_level] < block.timestamp) {
				profitsLost[referrer].uid = users[referrer].id;
				profitsLost[referrer].toId.push(users[msg.sender].id);
				profitsLost[referrer].toAddr.push(msg.sender);
				profitsLost[referrer].amount.push(incentive[_level]);
				profitsLost[referrer].level.push(_level);

				address(uint160(owner)).transfer(incentive[_level]);
				emit LostLevelProfitEvent(_user, referrer, _level, block.timestamp);
			}
			else {
				profitsReceived[referrer].uid = users[referrer].id;
				profitsReceived[referrer].fromId.push(users[msg.sender].id);
				profitsReceived[referrer].fromAddr.push(msg.sender);
				profitsReceived[referrer].amount.push(incentive[_level]);
				profitsReceived[referrer].level.push(_level);

				address(uint160(referrer)).transfer(incentive[_level]);
				emit GetLevelProfitEvent(_user, referrer, _level, block.timestamp);
			}

			sentValue += incentive[_level];
		}

		address(uint160(owner)).transfer(msg.value - sentValue);
	}

	function getUserUpline(address _user, uint height)
	public
	view
	returns (address) {
		if (height <= 0 || _user == address(0)) {
			return _user;
		}
		return getUserUpline(userAddresses[users[_user].referrerID], height - 1);
	}

	function getUser(address _user)
	public
	view
	returns (uint, uint, address[] memory, uint) {
		return (users[_user].id, users[_user].referrerID, users[_user].referrals, users[_user].created);
	}

	function getUserReferrals(address _user)
	public
	view
	returns (address[] memory) {
		return users[_user].referrals;
	}

	function getUserLevelExpiresAt(address _user, uint _level)
	public
	view
	returns (uint) {
		return users[_user].levelExpiresAt[_level];
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
		if (getUserLevelExpiresAt(_user, 1) < block.timestamp) {
			return (0);
		}
		else if (getUserLevelExpiresAt(_user, 2) < block.timestamp) {
			return (1);
		}
		else if (getUserLevelExpiresAt(_user, 3) < block.timestamp) {
			return (2);
		}
		else if (getUserLevelExpiresAt(_user, 4) < block.timestamp) {
			return (3);
		}
		else if (getUserLevelExpiresAt(_user, 5) < block.timestamp) {
			return (4);
		}
		else if (getUserLevelExpiresAt(_user, 6) < block.timestamp) {
			return (5);
		}
		else {
			return (6);
		}
	}

	function getUserDetails(address _user) public view returns (uint, uint) {
		if (getUserLevelExpiresAt(_user, 1) < block.timestamp) {
			return (0, users[_user].id);
		}
		else if (getUserLevelExpiresAt(_user, 2) < block.timestamp) {
			return (1, users[_user].id);
		}
		else if (getUserLevelExpiresAt(_user, 3) < block.timestamp) {
			return (2, users[_user].id);
		}
		else if (getUserLevelExpiresAt(_user, 4) < block.timestamp) {
			return (3, users[_user].id);
		}
		else if (getUserLevelExpiresAt(_user, 5) < block.timestamp) {
			return (4, users[_user].id);
		}
		else if (getUserLevelExpiresAt(_user, 6) < block.timestamp) {
			return (5, users[_user].id);
		}
		else {
			return (6, users[_user].id);
		}
	}

}