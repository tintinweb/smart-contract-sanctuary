/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

pragma solidity >=0.5.14;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BEP20 {
    function mint(
        address reciever,
        uint256 value,
        bytes32[3] memory _mrs,
        uint8 _v
    ) public returns (bool);

    function transfer(address to, uint256 value) public returns (bool);
}

contract NEKT {
    using SafeMath for uint256;

    struct UserStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        uint256 currentLevel;
        uint256 totalEarningUSDT;
        address[] referral;
        mapping(uint256 => uint256) levelExpired;
    }

    BEP20 Token;
    address public ownerAddress;
    uint256 public adminFee = 5;
    uint256 public currentId = 0;
    uint256 public PERIOD_LENGTH = 1500 days;
    uint256 referrer1Limit = 2;
    IBEP20 usdt = IBEP20(0x782Fa023d087bD05FF2082d41363FA72F6CcaC4E);

    mapping(uint256 => uint256) public LEVEL_PRICE;
    mapping(address => UserStruct) public users;
    mapping(uint256 => address) public userList;
    mapping(address => mapping(uint256 => uint256)) public EarnedUsdt;
    mapping(address => uint256) public loopCheck;
    mapping(address => uint256) public createdDate;

    event regLevelEvent(
        address indexed UserAddress,
        address indexed ReferrerAddress,
        uint256 Time
    );
    event buyLevelEvent(
        address indexed UserAddress,
        uint256 Levelno,
        uint256 Time
    );
    event getMoneyForLevelEvent(
        address indexed UserAddress,
        uint256 UserId,
        address indexed ReferrerAddress,
        uint256 ReferrerId,
        uint256 Levelno,
        uint256 LevelPrice,
        uint256 Time
    );
    event lostMoneyForLevelEvent(
        address indexed UserAddress,
        uint256 UserId,
        address indexed ReferrerAddress,
        uint256 ReferrerId,
        uint256 Levelno,
        uint256 LevelPrice,
        uint256 Time
    );

    constructor() public {
        ownerAddress = msg.sender;

        // Level_Price
        LEVEL_PRICE[1] = 10 ether;
        LEVEL_PRICE[2] = 20 ether;
        LEVEL_PRICE[3] = 40 ether;
        LEVEL_PRICE[4] = 80 ether;
        LEVEL_PRICE[5] = 160 ether;
        LEVEL_PRICE[6] = 320 ether;
        LEVEL_PRICE[7] = 640 ether;
        LEVEL_PRICE[8] = 1280 ether;

        UserStruct memory userStruct;
        currentId = currentId.add(1);

        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: 0,
            currentLevel: 1,
            totalEarningUSDT: 0,
            referral: new address[](0)
        });
        users[ownerAddress] = userStruct;
        userList[currentId] = ownerAddress;

        for (uint256 i = 1; i <= 8; i++) {
            users[ownerAddress].currentLevel = i;
            users[ownerAddress].levelExpired[i] = 55555555555;
        }
    }

    function regUser(uint256 _referrerID) external {
        require(users[msg.sender].isExist == false, "User exist");
        require(
            _referrerID > 0 && _referrerID <= currentId,
            "Incorrect referrer Id"
        );
        require(
            usdt.transferFrom(msg.sender, address(this), LEVEL_PRICE[1]),
            "Insufficient value"
        );

        if (users[userList[_referrerID]].referral.length >= referrer1Limit)
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;

        UserStruct memory userStruct;
        currentId++;

        userStruct = UserStruct({
            isExist: true,
            id: currentId,
            referrerID: _referrerID,
            currentLevel: 1,
            totalEarningUSDT: 0,
            referral: new address[](0)
        });

        users[msg.sender] = userStruct;
        userList[currentId] = msg.sender;
        users[msg.sender].levelExpired[1] = now.add(PERIOD_LENGTH);
        users[userList[_referrerID]].referral.push(msg.sender);
        loopCheck[msg.sender] = 0;
        createdDate[msg.sender] = now;

        payForLevel(
            0,
            1,
            msg.sender,
            ((LEVEL_PRICE[1].mul(adminFee)).div(10**20)),
            LEVEL_PRICE[1]
        );

        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function buyLevel(uint256 _level) external {
        require(users[msg.sender].isExist, "User not exist");
        require(_level > 0 && _level <= 12, "Incorrect level");

        if (_level == 1) {
            require(
                usdt.transferFrom(msg.sender, address(this), LEVEL_PRICE[1]),
                "Insufficient value"
            );
            users[msg.sender].levelExpired[1] = users[msg.sender]
                .levelExpired[1]
                .add(PERIOD_LENGTH);
            users[msg.sender].currentLevel = 1;
        } else {
            require(
                usdt.transferFrom(
                    msg.sender,
                    address(this),
                    LEVEL_PRICE[_level]
                ),
                "Insufficient value"
            );

            users[msg.sender].currentLevel = _level;
            for (uint256 i = _level - 1; i > 0; i--)
                require(
                    users[msg.sender].levelExpired[i] >= now,
                    "Buy the previous level"
                );

            if (users[msg.sender].levelExpired[_level] == 0)
                users[msg.sender].levelExpired[_level] = now + PERIOD_LENGTH;
            else users[msg.sender].levelExpired[_level] += PERIOD_LENGTH;
        }
        loopCheck[msg.sender] = 0;

        payForLevel(
            0,
            _level,
            msg.sender,
            ((LEVEL_PRICE[_level].mul(adminFee)).div(10**20)),
            LEVEL_PRICE[_level]
        );

        emit buyLevelEvent(msg.sender, _level, now);
    }

    function payForLevel(
        uint256 _flag,
        uint256 _level,
        address _userAddress,
        uint256 _adminPrice,
        uint256 _amt
    ) internal {
        address[8] memory referer;

        if (_flag == 0) {
            if (_level == 1) {
                referer[0] = userList[users[_userAddress].referrerID];
            } else if (_level == 2) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[0] = userList[users[referer[1]].referrerID];
            } else if (_level == 3) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[0] = userList[users[referer[2]].referrerID];
            } else if (_level == 4) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[0] = userList[users[referer[3]].referrerID];
            } else if (_level == 5) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[4] = userList[users[referer[3]].referrerID];
                referer[0] = userList[users[referer[4]].referrerID];
            } else if (_level == 6) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[4] = userList[users[referer[3]].referrerID];
                referer[5] = userList[users[referer[4]].referrerID];
                referer[0] = userList[users[referer[5]].referrerID];
            } else if (_level == 7) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[4] = userList[users[referer[3]].referrerID];
                referer[5] = userList[users[referer[4]].referrerID];
                referer[6] = userList[users[referer[5]].referrerID];
                referer[0] = userList[users[referer[6]].referrerID];
            } else if (_level == 8) {
                referer[1] = userList[users[_userAddress].referrerID];
                referer[2] = userList[users[referer[1]].referrerID];
                referer[3] = userList[users[referer[2]].referrerID];
                referer[4] = userList[users[referer[3]].referrerID];
                referer[5] = userList[users[referer[4]].referrerID];
                referer[6] = userList[users[referer[5]].referrerID];
                referer[7] = userList[users[referer[6]].referrerID];
                referer[0] = userList[users[referer[7]].referrerID];
            }
        } else if (_flag == 1) {
            referer[0] = userList[users[_userAddress].referrerID];
        }
        if (!users[referer[0]].isExist) referer[0] = userList[1];

        if (loopCheck[msg.sender] >= 8) {
            referer[0] = userList[1];
        }
        if (users[referer[0]].levelExpired[_level] >= now) {
            require(
                usdt.transfer(referer[0], LEVEL_PRICE[_level].sub(LEVEL_PRICE[_level].div(20))),
                "Insufficient value"
            );
            
            //5% admin charges
             require(
                usdt.transfer(ownerAddress, LEVEL_PRICE[_level].div(20)),
                "Insufficient value"
            );
            users[referer[0]].totalEarningUSDT = users[referer[0]]
                .totalEarningUSDT
                .add(LEVEL_PRICE[_level]);
            EarnedUsdt[referer[0]][_level] = EarnedUsdt[referer[0]][_level].add(
                LEVEL_PRICE[_level]
            );
            emit getMoneyForLevelEvent(
                msg.sender,
                users[msg.sender].id,
                referer[0],
                users[referer[0]].id,
                _level,
                LEVEL_PRICE[_level],
                now
            );
        } else {
            if (loopCheck[msg.sender] < 8) {
                loopCheck[msg.sender] = loopCheck[msg.sender].add(1);

                emit lostMoneyForLevelEvent(
                    msg.sender,
                    users[msg.sender].id,
                    referer[0],
                    users[referer[0]].id,
                    _level,
                    LEVEL_PRICE[_level],
                    now
                );

                payForLevel(1, _level, referer[0], _adminPrice, _amt);
            }
        }
    }

    // function failSafe(address payable _toUser, uint256 _amount)
    //     public
    //     returns (bool)
    // {
    //     require(msg.sender == ownerAddress, "only Owner Wallet");
    //     require(_toUser != address(0), "Invalid Address");
    //     require(
    //         usdt.balanceOf(address(this)) >= _amount,
    //         "Insufficient balance"
    //     );

    //     usdt.transfer(_toUser, _amount);
    //     return true;
    // }

    function updateFeePercentage(uint256 _adminFee) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        adminFee = _adminFee;
        return true;
    }

    function updatePrice(uint256 _level, uint256 _price) public returns (bool) {
        require(msg.sender == ownerAddress, "only OwnerWallet");

        LEVEL_PRICE[_level] = _price;
        return true;
    }

    function findFreeReferrer(address _userAddress)
        public
        view
        returns (address)
    {
        if (users[_userAddress].referral.length < referrer1Limit)
            return _userAddress;

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].referral[0];
        referrals[1] = users[_userAddress].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 254; i++) {
            if (users[referrals[i]].referral.length == referrer1Limit) {
                if (i < 126) {
                    referrals[(i + 1) * 2] = users[referrals[i]].referral[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]].referral[
                        1
                    ];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, "No Free Referrer");
        return freeReferrer;
    }

    function getTotalEarnedUSDT() public view returns (uint256) {
        uint256 totalUSDT;
        for (uint256 i = 1; i <= currentId; i++) {
            totalUSDT = totalUSDT.add(users[userList[i]].totalEarningUSDT);
        }
        return totalUSDT;
    }

    function viewUserReferral(address _userAddress)
        external
        view
        returns (address[] memory)
    {
        return users[_userAddress].referral;
    }

   
}