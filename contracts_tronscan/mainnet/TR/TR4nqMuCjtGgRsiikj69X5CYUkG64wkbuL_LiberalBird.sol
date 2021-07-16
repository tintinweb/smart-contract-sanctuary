//SourceUnit: LiberalBird.sol

pragma solidity >= 0.5.8;

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
contract LiberalBird {
	using SafeMath for uint;

    bool public active;
	bool public allowPush;
    uint public referralLimit;
    uint public lastID;
    uint public registrationFee;
	uint public levelDown;
	uint public interestRate;
    address public creator;
    mapping(uint => uint) incentives;
	mapping(uint => uint) teamEarnings;
	mapping(uint => uint) public generations;
	mapping(uint => uint) public changeLevelCount;
	mapping(uint => uint) public completionCount;
	mapping(uint => uint) internal devFund;
	mapping(uint => uint) public availableBalance;
	mapping(address => uint) internal directReferrals;
	mapping(uint => uint) internal debts;
	mapping(uint => uint) internal creditRatio;
    mapping(uint => address) public userAddresses;
    mapping(address => User) public users;
    // mapping user address => level => leg => count
	mapping(address => mapping(uint => mapping(uint => uint))) matrixCount;

	event RegisterUserEvent(address indexed user, address indexed referrer, uint time);
	event GetLevelProfitEvent(address indexed user, address indexed referral, uint indexed level, uint time);

    struct User {
        uint id;
        uint referralID;
		uint blockLevel;
		uint level;
        uint created;
		uint totalEarnings;
        address[] referrals;
    }

    modifier contractActive() {
        require(active == true);
        _;
    }
	modifier validRegistrationAmount() {
		require(msg.value == registrationFee, 'Invalid registration fee sent');
		_;
	}
	modifier userRegistered() {
		require(users[msg.sender].id != 0, 'User does not exist');
		_;
	}
	modifier validReferralID(uint _referralID) {
		require(_referralID > 0 && _referralID <= lastID, 'Invalid referrer ID');
		require(users[msg.sender].id != _referralID, 'Refer ID cannot be same as User ID');
		_;
	}
	modifier userNotRegistered(address _addr) {
		require(users[_addr].id == 0, 'User is already registered');
		_;
	}
	modifier onlyCreator() {
		require(msg.sender == creator, 'You are not the creator');
		_;
	}

    constructor() public {
        creator = msg.sender;
		active = true;
		allowPush = true;
		referralLimit = 3;
		uint multiplier = 1000000;
        registrationFee = 200 * multiplier;
        lastID++;
		levelDown = 5;
		generations[1] = 6;
		generations[2] = 6;
		generations[3] = 6;
		generations[4] = 6;
		generations[5] = 6;

		changeLevelCount[1] = 182;
		changeLevelCount[2] = 164;
		changeLevelCount[3] = 109;
		changeLevelCount[4] = 91;
		changeLevelCount[5] = 363;

		completionCount[1] = 363;
		completionCount[2] = 363;
		completionCount[3] = 363;
		completionCount[4] = 363;
		completionCount[5] = 363;

		incentives[1] = 5445 * multiplier;
		incentives[2] = 54354 * multiplier;
		incentives[3] = 565017 * multiplier;
		incentives[4] = 3296270 * multiplier;
		incentives[5] = 0 * multiplier;
		
		teamEarnings[1] = 90 * multiplier;
		teamEarnings[2] = 816 * multiplier;
		teamEarnings[3] = 6670 * multiplier;
		teamEarnings[4] = 36322 * multiplier;
		teamEarnings[5] = 219475 * multiplier;

		creditRatio[0] = 25 * multiplier;
		creditRatio[1] = 25 * multiplier;
		creditRatio[2] = 25 * multiplier;
		creditRatio[3] = 25 * multiplier;
		creditRatio[4] = 25 * multiplier;
		creditRatio[5] = 25 * multiplier;

		interestRate = 5;

		devFund[1] = 850 * multiplier;
		devFund[2] = 3700 * multiplier;
		devFund[3] = 9550 * multiplier;
		devFund[4] = 15725 * multiplier;
		devFund[5] = 25321 * multiplier;
		devFund[6] = 32543 * multiplier;

		users[creator] = User({
			id : lastID,
			referralID: 0,
			blockLevel: 1,
			level:5,
			created : block.timestamp,
			totalEarnings: 0,
			referrals : new address[](0)
		});
		userAddresses[lastID] = creator;
    }

	function changeRegFee(uint value) public onlyCreator() {
		registrationFee = value;
	}

	function changeIncentive(uint level, uint value) public onlyCreator() {
		incentives[level] = value;
	}

	function changeTeamEarning(uint level, uint value) public onlyCreator() {
		teamEarnings[level] = value;
	}

	function changeGeneration(uint level, uint value) public onlyCreator() {
		generations[level] = value;
	}

	function updateChangeLevelCount(uint level, uint value) public onlyCreator() {
		changeLevelCount[level] = value;
	}

	function changeCompletionCount(uint level, uint value) public onlyCreator() {
		completionCount[level] = value;
	}
	
	function changeDevFund(uint level, uint value) public onlyCreator() {
		devFund[level] = value;
	}
	
	function changeCreditRatio(uint level, uint value) public onlyCreator() {
		creditRatio[level] = value;
	}
	
	function changeInterestRate(uint value) public onlyCreator() {
		interestRate = value;
	}

	function() external payable {
		revert();
	}

	function addFund()
	public
	payable
	{
	}

	function registerUser(address _addr, uint _referralID, uint randNum)
	public
	payable
	userNotRegistered(_addr)
	validReferralID(_referralID)
	contractActive()
	validRegistrationAmount() {
		directReferrals[userAddresses[_referralID]]++;
		User memory referrer = users[findReferrer(userAddresses[_referralID], true, randNum)];
		lastID++;
		users[_addr] = User({
			id : lastID,
			referralID: referrer.id,
			blockLevel: referrer.blockLevel+1,
			level:0,
			created : block.timestamp,
			totalEarnings: 0,
			referrals : new address[](0)
		});
		userAddresses[lastID] = _addr;
		users[userAddresses[referrer.id]].referrals.push(_addr);

		if (users[userAddresses[referrer.id]].referrals.length >= referralLimit) {
			changeLevel(userAddresses[referrer.id], 1);
		}

		emit RegisterUserEvent(_addr, userAddresses[referrer.id], block.timestamp);
	}

	function changeLevel(address _user, uint _level)
	internal
	{
		if (_level > 5) {
			return;
		}
		if (users[_user].level >= _level) {
			return;
		}

		if(debts[users[_user].id] > 0) {
			return;
		}

		users[_user].level = _level;
		// pay the user pending payments for this level
		uint amount = teamMembers(_user, _level) * teamEarnings[_level];
		if (teamMembers(_user, _level) == completionCount[_level]) {
			amount = amount.add(incentives[_level]);
		} 
		if (amount > 0) {
			users[_user].totalEarnings = amount.add(users[_user].totalEarnings);
			payUser(_user, amount); 
		}

		for (uint b = 1; b <= generations[_level]; b++) {
			address upline = getUserUpline(_user, b);
			if(upline == address(0)) {
				continue;
			}
			int leg = findLeg(_user, upline, int(generations[_level]));
			if (leg == -1) {
				continue;
			}

			if(teamMembers(upline, _level) == completionCount[_level] || matrixCount[upline][_level][uint(leg)] >= completionCount[_level]/3) {
				continue;
			}
			matrixCount[upline][_level][uint(leg)]++; 
			// even if the user is in the lower level, the increament above will be used in paying him when he reaches here
			if(users[upline].level < _level) {
				continue;
			}

			// pay the upline the drop bonus
			amount = teamEarnings[_level];
			if (teamMembers(upline, _level) == completionCount[_level]) {
				amount = amount.add(incentives[_level]);
			} 
			if (amount > 0) {
				users[upline].totalEarnings = amount.add(users[upline].totalEarnings);
				payUser(upline, amount);
			}
			if(teamMembers(upline, _level) == changeLevelCount[_level]) {
				changeLevel(upline, users[upline].level+1);
			}
		}

		if(teamMembers(_user, _level) == changeLevelCount[_level]) {
			changeLevel(_user, users[_user].level+1);
		}
	}

	function payUser(address _user, uint _amount) internal {
		if (debts[users[_user].id] > 0) {
			uint amountToPay = debts[users[_user].id];
			if (amountToPay > _amount) {
				amountToPay = _amount;
			}
			payDebt(_user, amountToPay);
			_amount = _amount.sub(amountToPay);
		}
		if (_amount <= 0) {
			return;
		}
		if ( allowPush && _amount > 0) {
			address(uint160(_user)).transfer(_amount);
			return;
		}
		availableBalance[users[_user].id] = availableBalance[users[_user].id].add(_amount);
	}

	function withdraw(uint _amount) public userRegistered() returns(bool) {
		require(_amount > 0);
		require(availableBalance[users[msg.sender].id] >= _amount);
		availableBalance[users[msg.sender].id] = availableBalance[users[msg.sender].id].sub(_amount);
		address(uint160(msg.sender)).transfer(_amount);
		return true;
	}

	function findLeg(address _user, address upline, int _depth)
	internal
	returns(int)
	{
		if (_depth <= -1) {
			return -1;
		}
		if (userAddresses[users[_user].referralID] == upline) {
			for (uint i = 0; i < users[upline].referrals.length; i++) {
				if (users[upline].referrals[i] == _user) {
					return int(i);
				}
			}
			return -1;
		}
		return findLeg(userAddresses[users[_user].referralID], upline, _depth -1);
	}

	function teamMembers(address _user, uint _level)
	public
	view
	returns(uint) {
		return matrixCount[_user][_level][0].add(matrixCount[_user][_level][1]).add(matrixCount[_user][_level][2]);
	}

	function findReferrer(address _user, bool traverseDown, uint randNum)
	public
	view
	returns (address) {
		if (users[_user].referrals.length < referralLimit) {
			return _user;
		}

		uint arraySize = 3 * ((3 ** levelDown) - 1);
		uint previousLineSize = 3 * ((3 ** (levelDown - 1)) - 1);
		address referrer;
		address[] memory referrals = new address[](arraySize);
		referrals[0] = users[_user].referrals[0];
		referrals[1] = users[_user].referrals[1];
		referrals[2] = users[_user].referrals[2];

		for (uint i = 0; i < arraySize; i++) {
			if (users[referrals[i]].referrals.length < referralLimit) {
				referrer = referrals[i];
				break;
			}

			if (i < previousLineSize) {
				referrals[(i + 1) * 3] = users[referrals[i]].referrals[0];
				referrals[(i + 1) * 3 + 1] = users[referrals[i]].referrals[1];
				referrals[(i + 1) * 3 + 2] = users[referrals[i]].referrals[2];
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

	function sendMonthlyDevExpense(uint _level) 
	public
	onlyCreator()
	{
		address(uint160(creator)).transfer(devFund[_level]);
	}

	function getUserUpline(address _user, uint height)
	public
	view
	returns (address) {
		if (height <= 0 || _user == address(0)) {
			return _user;
		}
		return getUserUpline(userAddresses[users[_user].referralID], height - 1);
	}

	function getUser(address _user)
	public
	view
	returns (uint, uint, address[] memory, uint) {
		return (users[_user].id, users[_user].referralID, users[_user].referrals, users[_user].created);
	}

	function getUserReferrals(address _user)
	public
	view
	returns (address[] memory) {
		return users[_user].referrals;
	}

	function getUserLevel(address _user) public view returns (uint) {
		return users[_user].level;
	}

	function getUserDetails(address _user) public view returns (uint, uint, uint) {
		return (users[_user].level, users[_user].id, users[_user].totalEarnings);
	}

	function getUserProfits(address _user) public view returns (uint) {
		return (users[_user].totalEarnings);
	}

	function getLevelEarning(address _user, uint _level) public view returns (uint) {
		uint amount = 0;
		uint downlines = teamMembers(_user, _level);
		amount = downlines.mul(teamEarnings[_level]);
		if (downlines >= completionCount[_level]) {
			amount = amount.add(incentives[_level]);
		}
		return amount;
	}

	function getUserRecruit(address _user) public view returns (uint) {
		return directReferrals[_user];
	}

	// Lending
	function availableCredit(uint _id) public view returns (uint) {
		uint amount;
		for(uint l = 1; l <= 5; l++) {
			if (users[userAddresses[_id]].level >= l) {
				uint downlines = teamMembers(userAddresses[_id], l);
				if (downlines < completionCount[l]) {
					amount = creditRatio[l] * downlines;
				}
			}
		}
		
		return amount;
	}

	function borrow(uint _amount) public userRegistered() {
		require(availableCredit(users[msg.sender].id) >= _amount, "You cannot borrow the specified amount");
		debts[users[msg.sender].id] = _amount.add(debts[users[msg.sender].id]);
		address(uint160(msg.sender)).transfer(_amount);
	}

	function payDebt() public payable userRegistered() {
		payDebt(msg.sender, msg.value);
	}

	function payDebt(address _user, uint _amount) internal {
		require(_amount <= debts[users[_user].id], "Invalid amount sent");
		debts[users[_user].id] = debts[users[_user].id].sub(_amount);
		if(debts[users[_user].id] <= 0) {
			if (teamMembers(_user, users[_user].level) >= changeLevelCount[users[_user].level]) {
				changeLevel(_user, users[_user].level+1);
			}
		}
	}

	function calculateInterest() public onlyCreator() {
		for(uint id = 1; id <= lastID; id++) {
			if(debts[id] <= 0) {
				continue;
			}
			debts[id] = debts[id].add((interestRate/30)/100 * debts[id]);
		}
	}

	function getUSerDebt(address _user) public view returns(uint) {
		return debts[users[_user].id];
	}
}