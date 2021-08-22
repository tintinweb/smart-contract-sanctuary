/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;


contract SmartOneX5 {    
    using SafeMath for uint256;

    uint256 private constant DIVIDER = 1000;
    uint256 private constant MAX_LEVEL = 9;
    uint256 private constant REFERRALS_LIMIT = 2;
    uint256 private constant LEVEL_EXPIRE_TIME = 30 days;
    uint256 private constant LEVEL_HIGHER_FOUR_EXPIRE_TIME = 10000 days;
    
    mapping(uint256 => address) public userAddresses;    
    mapping(address => User) public users;
     
    address payable private creator;
    uint256 public last_uid;
   
    struct User {
        uint256 id;
        uint256 referrerID;
        address[] referrals;
        //uint256[] levelExpiresAt;
        mapping(uint256 => uint256) levelExpiresAt;
    }

    uint256[9] levelPrice = [
        0.11 ether, // => Total - 10% fee | (90% / 5) upline per user
        0.22 ether,
        0.44 ether,
        0.88 ether,
        1.75 ether,
        3.52 ether,
        7.04 ether,
        14.08 ether,
        28.16 ether
    ];

    uint256[9] uplinesDivider = [
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13
    ];
   
    event UserLevelProfit(address indexed user,address referral,uint256 level);

    modifier validLevelAmount(uint256 _level) {
        require(msg.value == levelPrice[_level], "Invalid level amount sent");
        _;
    }

    modifier userRegistered() {
        require(users[msg.sender].id != 0, "User does not exist");
        _;
    }

    modifier validReferrerID(uint256 _referrerID) {
        require(
            _referrerID > 0 && _referrerID <= last_uid,
            "Invalid referrer ID"
        );
        _;
    }

    modifier userNotRegistered() {
        require(users[msg.sender].id == 0, "User is already registered");
        _;
    }

    modifier validLevel(uint256 _level) {
        require(_level > 0 && _level <= MAX_LEVEL, "Invalid level entered");
        _;
    }

    constructor(){
        last_uid++;
        creator = payable(msg.sender);
        
        User storage user = users[msg.sender];
        user.id = last_uid;
        user.referrerID = 0;
        user.referrals =  new address[](0);

        userAddresses[last_uid] = creator;

        for (uint256 i = 1; i <= MAX_LEVEL; i++) {
            users[creator].levelExpiresAt[i] = 1 << 37; // Never expire
        }
    }

    function registerUser(uint256 _referrerID)
        public
        payable
        userNotRegistered()
        validReferrerID(_referrerID)
        validLevelAmount(1)
    {
        uint256 _level = 1;

        if (
            users[userAddresses[_referrerID]].referrals.length >=
            REFERRALS_LIMIT
        ) {
            _referrerID = users[findReferrer(userAddresses[_referrerID])].id;
        }
        
        last_uid++;
        
        User storage user = users[msg.sender];
        user.id = last_uid;
        user.referrerID = _referrerID;
        user.referrals =  new address[](0);

        userAddresses[last_uid] = msg.sender;
        users[msg.sender].levelExpiresAt[_level] = block.timestamp + getLevelExpireTime(_level);
        users[userAddresses[_referrerID]].referrals.push(msg.sender);

        transferLevelPayment(_level, msg.sender);
    }


    function buyLevel(uint256 _level)
        public
        payable
        userRegistered()
        validLevel(_level)
        validLevelAmount(_level)
    {
        for (uint256 l = _level - 1; l > 0; l--) {
            require(getUserLevelExpiresAt(msg.sender, l) >= block.timestamp, "Buy previous level first");
        }

        if (getUserLevelExpiresAt(msg.sender, _level) == 0) {
            users[msg.sender].levelExpiresAt[_level] = block.timestamp + getLevelExpireTime(_level);
        } else {
            users[msg.sender].levelExpiresAt[_level] += getLevelExpireTime(_level);
        }

        transferLevelPayment(_level, msg.sender);
    }

    function getLevelExpireTime(uint256 _level) internal pure returns (uint256) {
        if (_level < 5) {
            return LEVEL_EXPIRE_TIME;
        } else {
            return LEVEL_HIGHER_FOUR_EXPIRE_TIME;
        }
    }

    function findReferrer(address _user) internal view returns (address) {
        if (users[_user].referrals.length < REFERRALS_LIMIT) {
            return _user;
        }

        address[1632] memory referrals;
        referrals[0] = users[_user].referrals[0];
        referrals[1] = users[_user].referrals[1];

        address referrer;

        for (uint256 i = 0; i < 16382; i++) {
            if (users[referrals[i]].referrals.length < REFERRALS_LIMIT) {
                referrer = referrals[i];
                break;
            }

            if (i >= 8191) {
                continue;
            }

            referrals[(i + 1) * 2] = users[referrals[i]].referrals[0];
            referrals[(i + 1) * 2 + 1] = users[referrals[i]].referrals[1];
        }

        require(referrer != address(0), "Referrer not found");
        return referrer;
    }

    function transferLevelPayment(uint256 _level, address _user) internal
    {
        address referrer = getUserUpline(_user, _level);
        
        if (referrer == address(0)) {
            referrer = creator;
        }

        uint256 uplines = uplinesDivider[_level];  
        
        uint256 levelPayment = msg.value;  // Total amount
        uint256 fee = levelPayment.div(100).div(DIVIDER); // Fee 10% of level price
        uint256 userPayment = levelPayment.sub(fee).div(uplines); // User payment 90% of level price
                
        for (uint256 i = 1; i <= uplines; i++) {
            referrer = getUserUpline(_user, i);

            if (
                referrer != address(0) &&
                (users[_user].levelExpiresAt[_level] == 0 ||
                    getUserLevelExpiresAt(referrer, _level) < block.timestamp)
            ) {
                uplines++;
                continue;
            }

            if (referrer == address(0)) {
                referrer = creator;
            }

            levelPayment = levelPayment.sub(userPayment);
            
            payable(referrer).transfer(userPayment);
            emit UserLevelProfit(referrer, msg.sender, _level);
        }

        if(levelPayment > 0){
            creator.transfer(levelPayment);
            emit UserLevelProfit(creator, msg.sender, _level);
        }
    }

    function getUserUpline(address _user, uint256 height) internal view returns (address)
    {
        if (height <= 0 || _user == address(0)) {
            return _user;
        }

        return (userAddresses[users[_user].referrerID]);
    }

    function getUserLevelExpiresAt(address _user, uint256 _level) internal view returns (uint256)
    {
        return users[_user].levelExpiresAt[_level];
    }

    function getUserReferrals(address _user) public view returns (address[] memory)
    {
        return users[_user].referrals;
    }

    function getUserReferralsID(address _user) public view returns (uint256[2] memory)
    {
        uint256[2] memory referrals_id;
        User storage user = users[_user];

        for (uint256 index = 0; index < user.referrals.length; index++) {
            referrals_id[index]= users[user.referrals[index]].id;
        }
        return referrals_id;
    }

    struct Level {
        address user;
        uint256 id;
        uint256 parent_id;
        address[] referrals;
        uint256[2] referrals_id;
    }
    
   
    
    function getUserBranch(address _user) internal view returns(Level[4] memory){
        
        uint256 last_id = 0;

        Level[4] memory branch;
        
        branch[0] = Level({
            id: last_uid,
            parent_id: 0,
            referrals: getUserReferrals(_user),
            referrals_id: getUserReferralsID(_user),
            user: _user
        });
        


        for (uint256 k = 0; k < 4; k++) {

            branch[k+1] = Level({
                id: last_uid,
                parent_id: branch[k].id,
                referrals: getUserReferrals(branch[k].user),
                referrals_id: getUserReferralsID(branch[k].user),
                user: branch[k].user
            });
            
            last_id++;
        }

        return branch;
    }


    function getUserData(address _user) public view
        returns (
            uint256,
            uint256,
            address[] memory,
            uint256[9] memory,
            Level[4] memory
        )
    {
        User storage user = users[_user];
        
        uint256[9] memory levelExpires; 

        for (uint256 i = 0; i < MAX_LEVEL; i++) {
            levelExpires[i] = user.levelExpiresAt[i+1];
        }

        Level[4] memory branch = getUserBranch(_user);
        return (user.id, user.referrerID, user.referrals, levelExpires, branch);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}