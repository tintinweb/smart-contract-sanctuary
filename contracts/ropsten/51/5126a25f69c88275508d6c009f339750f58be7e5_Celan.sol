/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

pragma solidity 0.6.0;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
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
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
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
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
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


contract Celan {

    using SafeMath for uint256;

    // Registered users details
    struct UserStruct {
        bool isExist;
        uint id;
        uint currentLevel;
        uint referer;
        uint referalEarnings;
        address[] referals;
        mapping(uint => bool)activeLevel;
    }

    // Owner address
    address public owner;
    // Pool bonus amount
    uint public poolBonus;
    // Total levels
    uint constant NUMBEROFLEVELS = 10;
    // Users currentId
    uint public currentId = 2;
    // PoolMembers list
    address[] public poolMembers;
    // Contract status
    bool public lockStatus;

    // Referal commission event
    event Referalcommission(address indexed to, uint level, uint value);
    // Direct referer commission event
    event Directrefercommission(address indexed from, address indexed to, uint value);
    // Pool commission event
    event Poolperson(address indexed to, uint amount);
    // Registration event
    event Registration(address indexed from, address indexed to, uint level, uint value, uint time, address indexed directrefer);
    // Buy level event
    event Buylevel(address indexed from, uint level, uint value, uint time);

    // Mapping users details by address
    mapping(address => UserStruct)public users;
    // Mapping users address by Id
    mapping(uint => address)public userList;
    // Mapping price for each levels
    mapping(uint => uint)public levelPrice;
    // Mapping counts for payment
    mapping(address => uint)public loopCheck;
    // Mapping levels for upline 
    mapping(uint => uint)public referalUpline;
    // Mapping poolstatus for every users
    mapping(address => bool)public pollStatus;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Celan: Only Owner");
        _;
    }

    /**
     * @dev Throws if lockStatus in true
     */
    modifier isLock() {
        require(lockStatus == false, "Celan: Contract Locked");
        _;
    }

    /**
     * @dev Throws if called by other contract
     */
    modifier isContractcheck(address _user) {
        require(!isContract(_user), "Celan: Invalid address");
        _;
    }
    
    /**
     * @dev Initializes the contract setting the _ownerAddress as the initial owner.
     */
    constructor(address _ownerAddress) public {
        owner = _ownerAddress;

        UserStruct memory userstruct;
        userstruct = UserStruct({
            isExist: true,
            id: 1,
            currentLevel: NUMBEROFLEVELS,
            referer: 0,
            referalEarnings: 0,
            referals: new address[](0)
        });
        users[owner] = userstruct;
        userList[1] = owner;

        // Owner active 10levels
        for (uint i = 1; i <= NUMBEROFLEVELS; i++) {
            users[owner].activeLevel[i] = true;
        }

        // Levels levelprice
        levelPrice[1] = 0.05 ether;
        for (uint i = 2; i <= NUMBEROFLEVELS; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }

        // Minimum referal count by each level
        referalUpline[1] = 3;
        for (uint i = 2; i <= NUMBEROFLEVELS; i++) {
            referalUpline[i] = referalUpline[i - 1] + 1;
        }
    }

    /**
     * @dev register: User register with level 1 price 
     * 30% for directReferer, 10% for pool bonus, 60% for uplines.
     * @param _referid: user give referid for reference purpose
     * @param _level: initaially for registering level will be 1
     */
    function register(uint _referid, uint _level) public isLock isContractcheck(msg.sender) payable {
        require(users[msg.sender].isExist == false, "Celan: User already exist");
        require(_level == 1, "Celan: For registration level should be given as 1");
        require(msg.value == levelPrice[_level], "Celan: Invalid price");
        require(_referid <= currentId, "Celan: Invalid id");
        uint referLimit = 2;
        address directAddress;

        if (users[userList[_referid]].referals.length >= referLimit) {
            directAddress = userList[_referid];
        }
        else {
            directAddress = userList[_referid];
        }
        if (users[userList[_referid]].referals.length >= referLimit) {
            _referid = users[findFreeReferrer(userList[_referid])].id;
        }
        _userRegister(msg.sender, _referid, _level, msg.value, directAddress);
    }

    function _userRegister(address _user, uint _referid, uint _level, uint _amount, address _directAddress) internal {
        UserStruct memory userstruct;
        userstruct = UserStruct({
            isExist: true,
            id: currentId,
            currentLevel: _level,
            referer: _referid,
            referalEarnings: 0,
            referals: new address[](0)
        });

        users[_user] = userstruct;
        userList[currentId] = _user;
        users[_user].activeLevel[1] = true;
        users[userList[_referid]].referals.push(_user);
        currentId++;

        uint poolPercentage = (_amount.mul(10 ether)).div(100 ether); // 10% amount for pool bonus
        uint directbonus = (_amount.mul(30 ether)).div(100 ether); // 30% for directrefer bonus
        poolBonus = poolBonus.add(poolPercentage);
        require(address(uint160(userList[_referid])).send(directbonus), "Celan: Direct bonus failed");
        uint amount = _amount.sub(poolPercentage.add(directbonus));
        _paylevel(userList[_referid], _level, amount.div(referalUpline[_level]));
        emit Directrefercommission(_user, userList[_referid], directbonus);
        emit Registration(_user, userList[_referid], _level, _amount, block.timestamp, _directAddress);

    }

    /**
     * @dev buyLevel: User can buy next level.User can move one by one no skipping levels
     * @param _level: Passing level for buy next level and calculate levelprice.
     */
    function buyLevel(uint _level) public isLock payable {
        require(users[msg.sender].isExist == true, "Celan: User not register yet");
        require(msg.value == levelPrice[_level], "Celan: Incorrect level price");
        require(users[msg.sender].currentLevel + 1 == _level, "Celan: Level should be next to current level");
        if (_level == NUMBEROFLEVELS && msg.sender != owner) {
            poolMembers.push(msg.sender);
        }

        users[msg.sender].activeLevel[_level] = true;
        users[msg.sender].currentLevel = _level;

        uint poolPercentage = (msg.value.mul(10 ether)).div(100 ether); // 10% for pool bonus
        uint directbonus = (msg.value.mul(30 ether)).div(100 ether); // 30% for directrefer
        poolBonus = poolBonus.add(poolPercentage);
        uint amount = msg.value.sub(poolPercentage.add(directbonus));

        loopCheck[msg.sender] = 0;
        _directShare(msg.sender, userList[users[msg.sender].referer], _level, directbonus);
        _paylevel(userList[users[msg.sender].referer], _level, amount.div(referalUpline[_level]));

        emit Buylevel(msg.sender, _level, msg.value, block.timestamp);
    }
    
    function _directShare(address _user, address _refer, uint _level, uint _amount) internal {
        if (users[_refer].activeLevel[_level] != true) {
            address ref = userList[users[_refer].referer];
            _directShare(_user, ref, _level, _amount);
        }
        else {
            require(address(uint160(_refer)).send(_amount), "Celan: Direct bonus failed");
            emit Directrefercommission(_user, _refer, _amount);
        }
    }

    function _paylevel(address _referer, uint _level, uint _amount) internal {
        if (_referer == address(0)) {  // if there is no referer admmin asign to be referer
            _referer = owner;
        }
        if (loopCheck[msg.sender] < referalUpline[_level]) {
            users[_referer].referalEarnings = users[_referer].referalEarnings.add(_amount);
            require(address(uint160(_referer)).send(_amount), "Celan: Level commission failed");
            emit Referalcommission(_referer, _level, _amount);
            loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
            address ref = userList[users[_referer].referer];
            _paylevel(ref, _level, _amount);
        }
    }

    /**
     * @dev findFreeReferrer: Check the refer either having space or find new refer
     * @param _user: passing address for check his referal length
     */
    function findFreeReferrer(address _user) public view returns(address) {
        uint referLimit = 2;
        if (users[_user].referals.length < referLimit) {
            return _user;
        }
        address[] memory referrals = new address[](126);
        referrals[0] = users[_user].referals[0];
        referrals[1] = users[_user].referals[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint i = 0; i < 126; i++) {
            if (users[referrals[i]].referals.length == referLimit) {
                if (i < 62) {
                    referrals[(i + 1) * 2] = users[referrals[i]].referals[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]].referals[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, 'Celan: No Free Referrer');
        return freeReferrer;
    }

    /**
     * @dev poolPercent: Distribute the poolbonus who completed 10 levels.
     * User eligible for poolbonus onetime.
     * Minimium 0.1 ether wants to go for each user.
     * Function invokes by owner.
     */
    function poolPercent() public onlyOwner {
        require(poolMembers.length != 0, "Celan: No users in pool members");
        uint _poolmember = poolMembers.length.mul(0.1 ether);
        require(poolBonus >= _poolmember, "Celan: Not sufficient amount for all members");

        if (poolMembers.length > 0) {
            for (uint i = 0; i < poolMembers.length; i++) {
                if (pollStatus[poolMembers[i]] == false && poolMembers[i] != address(0)) {
                    require(address(uint160(poolMembers[i])).send(poolBonus.div(poolMembers.length)), "Celan: Pool transaction failed");
                    pollStatus[poolMembers[i]] = true;
                    emit Poolperson(poolMembers[i], poolBonus.div(poolMembers.length));
                }
            }
            poolBonus = 0;
        }
    }

    /**
     * @dev viewUsers: Return users referals and active status
     */
    function viewUsers(address _user, uint _level) public view returns(address[]memory, bool) {
        return (users[_user].referals,
            users[_user].activeLevel[_level]);
    }

    /**
     * @dev failSafe: Returns transfer ether
     */
    function failSafe(address payable _toUser, uint _amount) public onlyOwner returns(bool) {
        require(_toUser != address(0), "Celan: Invalid Address");
        require(address(this).balance >= _amount, "Celan: Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }

    /**
     * @dev contractLock: For contract status
     */
    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
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