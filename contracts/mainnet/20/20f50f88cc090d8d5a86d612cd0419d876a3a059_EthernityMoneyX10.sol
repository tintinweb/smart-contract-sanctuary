/**
 *Submitted for verification at Etherscan.io on 2020-05-02
*/

pragma solidity >=0.6.3 <0.7.0;


contract EthernityMoneyX10 {
    address public creator;
    uint256 MAX_LEVEL = 2;
    uint256 REFERRALS_LIMIT = 100;
    uint256 LEVEL_EXPIRE_TIME = 30 days;
    uint256 LEVEL_HIGHER_FOUR_EXPIRE_TIME = 10000 days;
    mapping(address => User) public users;
    mapping(uint256 => address) public userAddresses;
    uint256 public last_uid;
    mapping(uint256 => uint256) public feePrice;
    mapping(uint256 => uint256) public directPrice;
    mapping(uint256 => uint256) public levelPrice;
    mapping(uint256 => uint256) public uplinesToRcvEth;
    mapping(address => ProfitsRcvd) public rcvdProfits;
    mapping(address => ProfitsGiven) public givenProfits;
    mapping(address => LostProfits) public lostProfits;

    struct User {
        uint256 id;
        uint256 referrerID;
        address[] referrals;
        mapping(uint256 => uint256) levelExpiresAt;
    }

    struct ProfitsRcvd {
        uint256 uid;
        uint256[] fromId;
        address[] fromAddr;
        uint256[] amount;
    }

    struct LostProfits {
        uint256 uid;
        uint256[] toId;
        address[] toAddr;
        uint256[] amount;
        uint256[] level;
    }

    struct ProfitsGiven {
        uint256 uid;
        uint256[] toId;
        address[] toAddr;
        uint256[] amount;
        uint256[] level;
        uint256[] line;
    }

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

    event RegisterUserEvent(
        address indexed user,
        address indexed referrer,
        uint256 time
    );
    event BuyLevelEvent(
        address indexed user,
        uint256 indexed level,
        uint256 time
    );
    event GetLevelProfitEvent(
        address indexed user,
        address indexed referral,
        uint256 indexed level,
        uint256 time
    );
    event LostLevelProfitEvent(
        address indexed user,
        address indexed referral,
        uint256 indexed level,
        uint256 time
    );

    constructor() public {
        last_uid++;
        creator = msg.sender;
        levelPrice[1] = 0.17 ether;
        levelPrice[2] = 0.35 ether;
        levelPrice[3] = 0.80 ether;
        levelPrice[4] = 1.60 ether;
        levelPrice[5] = 2.50 ether;
        levelPrice[6] = 3.50 ether;
        levelPrice[7] = 6.60 ether;
        levelPrice[8] = 15.20 ether;
        levelPrice[9] = 24.50 ether;
        feePrice[1] = 0.03 ether;
        feePrice[2] = 0.04 ether;
        feePrice[3] = 0.05 ether;
        feePrice[4] = 0.06 ether;
        feePrice[5] = 0.07 ether;
        feePrice[6] = 0.08 ether;
        feePrice[7] = 0.09 ether;
        feePrice[8] = 0.10 ether;
        feePrice[9] = 0.20 ether;
        directPrice[1] = 0.04 ether;
        directPrice[2] = 0.09 ether;
        directPrice[3] = 0.15 ether;
        directPrice[4] = 0.24 ether;
        directPrice[5] = 0.34 ether;
        directPrice[6] = 0.42 ether;
        directPrice[7] = 0.51 ether;
        directPrice[8] = 0.70 ether;
        directPrice[9] = 1.26 ether;
        uplinesToRcvEth[1] = 10;
        uplinesToRcvEth[2] = 11;
        uplinesToRcvEth[3] = 12;
        uplinesToRcvEth[4] = 13;
        uplinesToRcvEth[5] = 14;
        uplinesToRcvEth[6] = 15;
        uplinesToRcvEth[7] = 16;
        uplinesToRcvEth[8] = 17;
        uplinesToRcvEth[9] = 18;

        users[creator] = User({
            id: last_uid,
            referrerID: 0,
            referrals: new address[](0)
        });
        userAddresses[last_uid] = creator;

        for (uint256 i = 1; i <= MAX_LEVEL; i++) {
            users[creator].levelExpiresAt[i] = 1 << 37;
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
        users[msg.sender] = User({
            id: last_uid,
            referrerID: _referrerID,
            referrals: new address[](0)
        });
        userAddresses[last_uid] = msg.sender;
        users[msg.sender].levelExpiresAt[_level] =
            now +
            getLevelExpireTime(_level);
        users[userAddresses[_referrerID]].referrals.push(msg.sender);

        transferLevelPayment(_level, msg.sender);
        emit RegisterUserEvent(msg.sender, userAddresses[_referrerID], now);
    }

    function buyLevel(uint256 _level)
        public
        payable
        userRegistered()
        validLevel(_level)
        validLevelAmount(_level)
    {
        for (uint256 l = _level - 1; l > 0; l--) {
            require(
                getUserLevelExpiresAt(msg.sender, l) >= now,
                "Buy previous level first"
            );
        }

        if (getUserLevelExpiresAt(msg.sender, _level) == 0) {
            users[msg.sender].levelExpiresAt[_level] =
                now +
                getLevelExpireTime(_level);
        } else {
            users[msg.sender].levelExpiresAt[_level] += getLevelExpireTime(
                _level
            );
        }

        transferLevelPayment(_level, msg.sender);
        emit BuyLevelEvent(msg.sender, _level, now);
    }

    function getLevelExpireTime(uint256 _level) public view returns (uint256) {
        if (_level < 5) {
            return LEVEL_EXPIRE_TIME;
        } else {
            return LEVEL_HIGHER_FOUR_EXPIRE_TIME;
        }
    }

    function findReferrer(address _user) public view returns (address) {
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

    function transferLevelPayment(uint256 _level, address _user) internal {
        uint256 height = _level;
        address referrer = getUserUpline(_user, height);

        if (referrer == address(0)) {
            referrer = creator;
        }

        uint256 uplines = uplinesToRcvEth[_level];
        bool chkLostProfit = false;
        address lostAddr;
        
        uint256 eth = msg.value;
        
        for (uint256 i = 1; i <= uplines; i++) {
            referrer = getUserUpline(_user, i);

            if (chkLostProfit) {
                lostProfits[lostAddr].uid = users[referrer].id;
                lostProfits[lostAddr].toId.push(users[referrer].id);
                lostProfits[lostAddr].toAddr.push(referrer);
                lostProfits[lostAddr].amount.push(
                    (msg.value - feePrice[_level] -  directPrice[_level])/ uplinesToRcvEth[_level]
                );
                lostProfits[lostAddr].level.push(getUserLevel(referrer));
                chkLostProfit = false;

                emit LostLevelProfitEvent(referrer, msg.sender, _level, 0);
            }

            if (
                referrer != address(0) &&
                (users[_user].levelExpiresAt[_level] == 0 ||
                    getUserLevelExpiresAt(referrer, _level) < now)
            ) {
                chkLostProfit = true;
                uplines++;
                lostAddr = referrer;
                continue;
            } else {
                chkLostProfit = false;
            }

            if (referrer == address(0)) {
                referrer = creator;
            }

     
            if (
                address(uint160(referrer)).send(
                    (msg.value - feePrice[_level] -  directPrice[_level])/ uplinesToRcvEth[_level]
                )
            ) {
                eth = eth - ((msg.value - feePrice[_level] -  directPrice[_level])/ uplinesToRcvEth[_level]);
            
                rcvdProfits[referrer].uid = users[referrer].id;
                rcvdProfits[referrer].fromId.push(users[msg.sender].id);
                rcvdProfits[referrer].fromAddr.push(msg.sender);
                rcvdProfits[referrer].amount.push(
                    (levelPrice[_level] - feePrice[_level] -  directPrice[_level])/ uplinesToRcvEth[_level]
                );

                givenProfits[msg.sender].uid = users[msg.sender].id;
                givenProfits[msg.sender].toId.push(users[referrer].id);
                givenProfits[msg.sender].toAddr.push(referrer);
                givenProfits[msg.sender].amount.push(
                    (levelPrice[_level] - feePrice[_level] -  directPrice[_level]) / uplinesToRcvEth[_level]
                );
                givenProfits[msg.sender].level.push(getUserLevel(referrer));
                givenProfits[msg.sender].line.push(i);

                emit GetLevelProfitEvent(referrer, msg.sender, _level, now);
            }
            
        }
        
        address directRefer =  userAddresses[users[msg.sender].referrerID];
        
        if (
            address(uint160(directRefer)).send(
                   directPrice[_level]
                )
            ) {
                eth = eth - directPrice[_level];
                rcvdProfits[referrer].uid = users[directRefer].id;
                rcvdProfits[referrer].fromId.push(users[msg.sender].id);
                rcvdProfits[referrer].fromAddr.push(msg.sender);
                rcvdProfits[referrer].amount.push(
                    directPrice[_level]
                );

                givenProfits[msg.sender].uid = users[msg.sender].id;
                givenProfits[msg.sender].toId.push(users[directRefer].id);
                givenProfits[msg.sender].toAddr.push(directRefer);
                givenProfits[msg.sender].amount.push(
                    directPrice[_level]
                );
                givenProfits[msg.sender].level.push(getUserLevel(directRefer));
                givenProfits[msg.sender].line.push(1);

                emit GetLevelProfitEvent(directRefer, msg.sender, _level, now);
            }
            
        if(address(uint160(creator)).send(eth)){
            emit GetLevelProfitEvent(creator, msg.sender, _level, now);
        }


    }

    function getUserUpline(address _user, uint256 height)
        public
        view
        returns (address)
    {
        if (height <= 0 || _user == address(0)) {
            return _user;
        }

        return
            this.getUserUpline(
                userAddresses[users[_user].referrerID],
                height - 1
            );
    }

    function getUserReferrals(address _user)
        public
        view
        returns (address[] memory)
    {
        return users[_user].referrals;
    }

    function getUserProfitsFromId(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return rcvdProfits[_user].fromId;
    }

    function getUserProfitsFromAddr(address _user)
        public
        view
        returns (address[] memory)
    {
        return rcvdProfits[_user].fromAddr;
    }

    function getUserProfitsAmount(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return rcvdProfits[_user].amount;
    }

    function getUserProfitsGivenToId(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return givenProfits[_user].toId;
    }

    function getUserProfitsGivenToAddr(address _user)
        public
        view
        returns (address[] memory)
    {
        return givenProfits[_user].toAddr;
    }

    function getUserProfitsGivenToAmount(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return givenProfits[_user].amount;
    }

    function getUserProfitsGivenToLevel(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return givenProfits[_user].level;
    }

    function getUserProfitsGivenToLine(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return givenProfits[_user].line;
    }

    function getUserLostsToId(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return (lostProfits[_user].toId);
    }

    function getUserLostsToAddr(address _user)
        public
        view
        returns (address[] memory)
    {
        return (lostProfits[_user].toAddr);
    }

    function getUserLostsAmount(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return (lostProfits[_user].amount);
    }

    function getUserLostsLevel(address _user)
        public
        view
        returns (uint256[] memory)
    {
        return (lostProfits[_user].level);
    }

    function getUserLevelExpiresAt(address _user, uint256 _level)
        public
        view
        returns (uint256)
    {
        return users[_user].levelExpiresAt[_level];
    }

    function getUserLevel(address _user) public view returns (uint256) {
        if (getUserLevelExpiresAt(_user, 1) < now) {
            return (0);
        } else if (getUserLevelExpiresAt(_user, 2) < now) {
            return (1);
        } else if (getUserLevelExpiresAt(_user, 3) < now) {
            return (2);
        } else if (getUserLevelExpiresAt(_user, 4) < now) {
            return (3);
        } else if (getUserLevelExpiresAt(_user, 5) < now) {
            return (4);
        } else if (getUserLevelExpiresAt(_user, 6) < now) {
            return (5);
        } else if (getUserLevelExpiresAt(_user, 7) < now) {
            return (6);
        } else if (getUserLevelExpiresAt(_user, 8) < now) {
            return (7);
        } else if (getUserLevelExpiresAt(_user, 9) < now) {
            return (8);
        } else if (getUserLevelExpiresAt(_user, 10) < now) {
            return (9);
        }
    }

    function getUserDetails(address _user)
        public
        view
        returns (uint256, uint256)
    {
        if (getUserLevelExpiresAt(_user, 1) < now) {
            return (1, users[_user].id);
        } else if (getUserLevelExpiresAt(_user, 2) < now) {
            return (2, users[_user].id);
        } else if (getUserLevelExpiresAt(_user, 3) < now) {
            return (3, users[_user].id);
        } else if (getUserLevelExpiresAt(_user, 4) < now) {
            return (4, users[_user].id);
        } else if (getUserLevelExpiresAt(_user, 5) < now) {
            return (5, users[_user].id);
        } else if (getUserLevelExpiresAt(_user, 6) < now) {
            return (6, users[_user].id);
        } else if (getUserLevelExpiresAt(_user, 7) < now) {
            return (7, users[_user].id);
        } else if (getUserLevelExpiresAt(_user, 8) < now) {
            return (8, users[_user].id);
        } else if (getUserLevelExpiresAt(_user, 9) < now) {
            return (9, users[_user].id);
        }
    }

    receive() external payable {
        revert();
    }
}