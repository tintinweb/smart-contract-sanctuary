/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity 0.5.16;

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }
}


contract Celan {

    using SafeMath for uint256;
        // Registered users details
    struct UserStruct{
        bool isExist;
        uint id;
        uint currentLevel;
        uint referer;
        uint referalEarnings;
        address[] referals;
        mapping(uint => bool)activeLevel;
    }

    // owner address
    address public owner;
    // pool bonus percentage
    uint public poolBonus;
    // Total levels
    uint public lastLevel = 10;
    // users currentId
    uint public currentId = 2;
    // poolMembers list
    address[] public poolMembers;
    // contract status
    bool public lockStatus;

    //Referal commission event
    event Referalcommission(address indexed to, uint level, uint value);
    //Direct refer commission event
    event Directrefercommission(address indexed from, address indexed to, uint value);
    //pool commission event
    event Poolperson(address indexed to, uint amount);
    //Registration event
    event Registration(address indexed from, address indexed to, uint level, uint value, uint time, address indexed directrefer);
    // Buylevel event
    event Buylevel(address indexed from, uint level, uint value, uint time);

    // mapping users details by address
    mapping(address => UserStruct)public users;
    // mapping users address by Id
    mapping(uint => address)public userList;
    // mapping price by levels
    mapping(uint => uint)public levelPrice;
    // mapping counts for payment purpose
    mapping(address => uint)public loopCheck;
    // mapping levels for upline 
    mapping(uint => uint)public referalUpline;
    // mapping status by address
    mapping(address => bool)public pollStatus;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }

    modifier isContractcheck(address _user) {
        require(!isContract(_user), "Invalid address");
        _;
    }

    constructor(address _ownerAddress)public{
        owner = _ownerAddress;

        UserStruct memory userstruct;
        userstruct = UserStruct({
            isExist: true,
            id: 1,
            currentLevel: lastLevel,
            referer: 0,
            referalEarnings: 0,
            referals: new address[](0)
        });
        users[owner] = userstruct;
        userList[1] = owner;

        //owner active 10levels
        for (uint i = 1; i <= lastLevel; i++) {
            users[owner].activeLevel[i] = true;
        }

        //Levels levelprice
        levelPrice[1] = 0.05 ether;
        for (uint i = 2; i <= 10; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }

        // upline counts
        referalUpline[1] = 3;
        for (uint i = 2; i <= 10; i++) {
            referalUpline[i] = referalUpline[i - 1] + 1;
        }
    }
    
    /**
    * @dev  : User register with level 1 price 
    * 30% for directReferer, 10% for pool bonus, 60% for uplines.
    * @param _referid : user give referid for reference purpose
    * @param _level : initaially for registering level will be 1
    */

    function register(uint _referid, uint _level) public isLock isContractcheck(msg.sender)  payable {
        require(users[msg.sender].isExist == false, "User already exist");
        require(_level == 1, "wrong level given");
        require(msg.value == levelPrice[_level], "invalid price");
        require(_referid <= currentId, "invalid id");
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

        _userregister(msg.sender, _referid, _level, msg.value, directAddress);
    }

    function _userregister(address _user, uint _referid, uint _level, uint _amount, address _directAddress) internal {
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

        uint poolpercentage = (_amount.mul(10 ether)).div(100 ether);
        uint directbonus = (_amount.mul(30 ether)).div(100 ether);
        poolBonus = poolBonus.add(poolpercentage);
        require(address(uint160(userList[_referid])).send(directbonus), "direct bonus failed");
        uint amount = _amount.sub(poolpercentage.add(directbonus));
        _paylevel(userList[_referid], _level, amount.div(referalUpline[_level]));
        emit Directrefercommission(_user, userList[_referid], directbonus);
        emit Registration(_user, userList[_referid], _level, _amount, block.timestamp, _directAddress);
       
    }
    
    /**
    * @dev  : User can buy next level.
    * @param _level : Giving level for buy another level user can move one by one no skipping levels
    */
    
    function buyLevel(uint _level) public isLock payable {
        require(users[msg.sender].isExist == true, "register first");
        require(msg.value == levelPrice[_level], "incorrect price");
        require(users[msg.sender].currentLevel + 1 == _level, "wrong level given");
        if (_level == lastLevel && msg.sender != owner) {
            poolMembers.push(msg.sender);
        }

        users[msg.sender].activeLevel[_level] = true;
        users[msg.sender].currentLevel = _level;

        uint poolpercentage = (msg.value.mul(10 ether)).div(100 ether);
        uint directbonus = (msg.value.mul(30 ether)).div(100 ether);
        poolBonus = poolBonus.add(poolpercentage);
        uint amount = msg.value.sub(poolpercentage.add(directbonus));
        _directShare(msg.sender, userList[users[msg.sender].referer], _level, directbonus);
        loopCheck[msg.sender] = 0;
        _paylevel(userList[users[msg.sender].referer], _level, amount.div(referalUpline[_level]));
        emit Buylevel(msg.sender, _level, msg.value, block.timestamp);
    }

    function _directShare(address _user, address _refer, uint _level, uint _amount) internal {
        if (users[_refer].activeLevel[_level] != true) {
            address ref = userList[users[_refer].referer];
            _directShare(_user, ref, _level, _amount);

        }

        else {
            require(address(uint160(_refer)).send(_amount), "direct bonus failed");
            emit Directrefercommission(_user, _refer, _amount);
        }
    }
    
    function _paylevel(address _referer, uint _level, uint _amount) internal {
        if (_referer == address(0)) {
            _referer = owner;
        }

        if (loopCheck[msg.sender] < referalUpline[_level]) {
            users[_referer].referalEarnings = users[_referer].referalEarnings.add(_amount);
            require(address(uint160(_referer)).send(_amount), "transfer level  failed");
            emit Referalcommission(_referer, _level, _amount);
            loopCheck[msg.sender] = loopCheck[msg.sender].add(1);
            address ref = userList[users[_referer].referer];
            _paylevel(ref, _level, _amount);
        }
    }

    /**
    * @dev findFreeReferrer : Check the refer either having space or find new refer
    * @param _user:passing address for check his referal length
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
        require(!noFreeReferrer, 'No Free Referrer');
        return freeReferrer;
    }

    /**
    * @dev poolPercent : Distribute the poolbonus to selected person call by onlyowner.
    * 
    */

    function poolPercent() public onlyOwner {
        require(poolMembers.length != 0, "no members");
        uint _poolmember = poolMembers.length.mul(0.1 ether);
        require(poolBonus >= _poolmember, "not sufficient amount for all");

        if (poolMembers.length > 0) {
            for (uint i = 0; i < poolMembers.length; i++) {
                require(pollStatus[poolMembers[i]] == false, "Already pool selected");
                require(poolMembers[i] != address(0), "transaction failed");
                require(address(uint160(poolMembers[i])).send(poolBonus.div(poolMembers.length)), "Transaction failed");
                pollStatus[poolMembers[i]] = true;
                emit Poolperson(poolMembers[i], poolBonus.div(poolMembers.length));
            }
            poolBonus = 0;
        }
    }
    
    function viewUsers(address _user, uint _level) public view returns(address[]memory, bool){
        return (users[_user].referals,
            users[_user].activeLevel[_level]);
    }

    function failSafe(address payable _toUser, uint _amount) public onlyOwner returns(bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
    /**
    * @dev : For contract status
    */

    function contractLock(bool _lockStatus) public onlyOwner returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }
    
    /**
    * @dev : For address check
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