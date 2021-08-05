/**
 *Submitted for verification at Etherscan.io on 2020-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.7.0;

contract ETHPlusX3 {
    address public creator;
    uint256 public last_uid;
    uint256 MAX_LEVEL = 9;
    uint256 REFERRALS_LIMIT = 2;
    uint256 LEVEL_EXPIRE_TIME = 90 days;
    uint256 LEVEL_HIGHER_FOUR_EXPIRE_TIME = 180 days;
    mapping(uint256 => address) public userAddresses;
    mapping(uint256 => uint256) directPrice;
    mapping(uint256 => uint256) levelPrice;
    mapping(address => User) public users;

    struct User {
        uint256 id;
        uint256 referrerID;
        address[] referrals;
        mapping(uint256 => uint256) levelExpiresAt;
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

    event GetLevelProfitEvent(
        address indexed user,
        address indexed referral,
        uint256 referralID,
        uint256 amount
    );

    constructor() public {
        last_uid++;
        creator = msg.sender;
        levelPrice[1] = 0.05 ether;
        levelPrice[2] = 0.72 ether;
        levelPrice[3] = 1.96 ether;
        levelPrice[4] = 4.00 ether;
        levelPrice[5] = 8.10 ether;
        levelPrice[6] = 15.00 ether;
        levelPrice[7] = 20.90 ether;
        levelPrice[8] = 35.40 ether;
        levelPrice[9] = 50.70 ether;
        directPrice[1] = 0.01 ether;
        directPrice[2] = 0.09 ether;
        directPrice[3] = 0.49 ether;
        directPrice[4] = 0.50 ether;
        directPrice[5] = 1.00 ether;
        directPrice[6] = 1.87 ether;
        directPrice[7] = 2.60 ether;
        directPrice[8] = 4.42 ether;
        directPrice[9] = 6.30 ether;

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
    }

    function getLevelExpireTime(uint256 _level)
        internal
        view
        returns (uint256)
    {
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

    function transferLevelPayment(uint256 _level, address _user) internal {
        address referrer = getUserUpline(_user, _level);
        address sender = msg.sender;

        if (referrer == address(0)) {
            referrer = creator;
        }

        uint256 uplines = 3;
        uint256 eth = msg.value;
        uint256 ethToReferrer = (eth - (directPrice[_level] * 2)) / uplines;

        for (uint256 i = 1; i <= uplines; i++) {
            referrer = getUserUpline(_user, i);

            if (
                referrer != address(0) &&
                (users[_user].levelExpiresAt[_level] == 0 ||
                    getUserLevelExpiresAt(referrer, _level) < now)
            ) {
                uplines++;
                continue;
            }

            if (referrer == address(0)) {
                referrer = creator;
            }

            eth = eth - ethToReferrer;

            (bool success, ) = address(uint256(referrer)).call{
                value: ethToReferrer
            }("");
            require(success, "Transfer failed.");
            emit GetLevelProfitEvent(
                referrer,
                sender,
                users[sender].id,
                ethToReferrer
            );
        }

        address directRefer = userAddresses[users[msg.sender].referrerID];

        eth = eth - directPrice[_level];
        (bool success2, ) = address(uint256(directRefer)).call{
            value: directPrice[_level]
        }("");
        require(success2, "Transfer failed.");
        emit GetLevelProfitEvent(
            directRefer,
            sender,
            users[sender].id,
            directPrice[_level]
        );

        (bool success3, ) = address(uint256(creator)).call{value: eth}("");
        require(success3, "Transfer failed.");
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

    function getUserLevelExpiresAt(address _user, uint256 _level)
        public
        view
        returns (uint256)
    {
        return users[_user].levelExpiresAt[_level];
    }

    function getUserReferrals(address _user)
        public
        view
        returns (address[] memory)
    {
        return users[_user].referrals;
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

    receive() external payable {
        revert();
    }
}