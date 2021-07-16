//SourceUnit: Eletra2live.sol

pragma solidity >=0.4.23 <0.6.0;

contract SmartMatrixElectra {
    struct User {
        uint256 id;
        address referrer;
        uint256 partnersCount;
        uint8 slot;
        uint256 totalEEcBonus;
        mapping(uint8 => bool) activeE3Levels;
        mapping(uint8 => bool) activeE6Levels;
        mapping(uint8 => bool) activeEECLevels;
        mapping(uint8 => address) eecuser;
        mapping(uint8 => E3) E3Matrix;
        mapping(uint8 => E6) E6Matrix;
        mapping(uint8 => EEC) EecMatrix;
    }

    struct E3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint256 reinvestCount;
    }

    struct E6 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint256 reinvestCount;
        address closedPart;
    }

    struct EEC {
        uint256 userserviceFund;
        uint256 userFund;
        uint256 bonus;
        uint256 pendingWithdrawals;
        uint256 payout;
        uint256 user;
        uint256 fulltotalEECFund;
        uint256 EEcdistritefund;
        uint256 totalservicefund;
        uint256 totalEECFund;
        uint256 totaluserbonus;
        uint256 profitperShare;
        mapping(address => uint256) EECuserbonusbalances;
    }

    uint8 public constant LAST_LEVEL = 15;
    address public owner;
    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(uint256 => address) public userIds;
    mapping(uint8 => EEC) public EECc;

    uint256 public lastUserId = 1;
    address public doner;
    address public deployer;
    uint256 public contractDeployTime;

    mapping(uint256 => address) public EECuserAddress;
    mapping(uint8 => uint256) public levelPrice;
    mapping(uint8 => uint256) public bonusPrice;
    mapping(uint256 => mapping(uint256 => address)) levelprice;

    event Registration(
        address indexed user,
        address indexed referrer,
        uint256 indexed userId,
        uint256 referrerId,
        uint256 amount
    );
    event Reinvest(
        address indexed user,
        address indexed currentReferrer,
        address indexed caller,
        uint8 matrix,
        uint8 level
    );
    event Upgrade(
        address indexed user,
        address indexed referrer,
        uint8 matrix,
        uint8 level,
        uint256 amount
    );
    event EECupgrade(address indexed user, uint8 level, uint256 amount);
    event NewUserPlace(
        address indexed user,
        address indexed referrer,
        uint8 matrix,
        uint8 level,
        uint8 place
    );
    event MissedEthReceive(
        address indexed receiver,
        address indexed from,
        uint8 matrix,
        uint8 level
    );
    event SentExtraEthDividends(
        address indexed from,
        address indexed receiver,
        uint8 matrix,
        uint8 level
    );
    event chkvalue(uint256 value);
    event chkvalue1(address value);
    event comment(string msg);

    constructor(address donerAddress) public {
        owner = donerAddress;
        levelPrice[1] = 200 * 10**6;
        levelPrice[2] = 400 * 10**6;
        levelPrice[3] = 800 * 10**6;
        levelPrice[4] = 1600 * 10**6;
        levelPrice[5] = 3200 * 10**6;
        levelPrice[6] = 6400 * 10**6;
        levelPrice[7] = 12800 * 10**6;
        levelPrice[8] = 25600 * 10**6;
        levelPrice[9] = 51200 * 10**6;
        levelPrice[10] = 102400 * 10**6;
        levelPrice[11] = 204800 * 10**6;
        levelPrice[12] = 409600 * 10**6;
        levelPrice[13] = 819200 * 10**6;
        levelPrice[14] = 1638400 * 10**6;
        levelPrice[15]= 3276800 * 10**6;
        
        //----- bonus price-----------
         bonusPrice[1] = 310 * 10 **6;
         bonusPrice[2] = 620 * 10 **6;
         bonusPrice[3] = 1240 * 10 **6;
         bonusPrice[4] = 2480 * 10 **6;
         bonusPrice[5] = 4960 * 10**6;
         bonusPrice[6] = 9920 * 10 **6;
         bonusPrice[7] = 19840 * 10 **6;
         bonusPrice[8] = 39680 * 10 **6;
         bonusPrice[9] = 79360 * 10 **6;
         bonusPrice[10] = 158720 * 10 **6;
         bonusPrice[11] = 317440 * 10 **6;
         bonusPrice[12] = 634880* 10 **6;
         bonusPrice[13] = 1269760 * 10 **6;
         bonusPrice[14] = 2539520 * 10 **6;
         bonusPrice[15] = 5079040 * 10 **6;
        
         
        
        deployer = msg.sender;
        doner = donerAddress;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint256(0),
            totalEEcBonus: uint256(0),
            slot: uint8(0)
        });

        users[donerAddress] = user;
        idToAddress[1] = donerAddress;
        //-----------E3-------------------------
        users[donerAddress].activeE3Levels[1] = true;
        users[donerAddress].activeE3Levels[2] = true;
        users[donerAddress].activeE3Levels[3] = true;
        users[donerAddress].activeE3Levels[4] = true;
        users[donerAddress].activeE3Levels[5] = true;
        users[donerAddress].activeE3Levels[6] = true;
        users[donerAddress].activeE3Levels[7] = true;
        users[donerAddress].activeE3Levels[8] = true;
        users[donerAddress].activeE3Levels[9] = true;
        users[donerAddress].activeE3Levels[10] = true;
        users[donerAddress].activeE3Levels[11] = true;
        users[donerAddress].activeE3Levels[12] = true;
        users[donerAddress].activeE3Levels[13] = true;
        users[donerAddress].activeE3Levels[14] = true;
        users[donerAddress].activeE3Levels[15] = true;
        
        //-------------------E6----------------------
        users[donerAddress].activeE6Levels[1] = true;
        users[donerAddress].activeE6Levels[2] = true;
        users[donerAddress].activeE6Levels[3] = true;
        users[donerAddress].activeE6Levels[4] = true;
        users[donerAddress].activeE6Levels[5] = true;
        users[donerAddress].activeE6Levels[6] = true;
        users[donerAddress].activeE6Levels[7] = true;
        users[donerAddress].activeE6Levels[8] = true;
        users[donerAddress].activeE6Levels[9] = true;
        users[donerAddress].activeE6Levels[10] = true;
        users[donerAddress].activeE6Levels[11] = true;
        users[donerAddress].activeE6Levels[12] = true;
        users[donerAddress].activeE6Levels[13] = true;
        users[donerAddress].activeE6Levels[14] = true;
        users[donerAddress].activeE6Levels[15] = true;
        //-------------------EEC---------------------
        
        users[donerAddress].activeEECLevels[1] = true;
        users[donerAddress].activeEECLevels[2] = true;
        users[donerAddress].activeEECLevels[3] = true;
        users[donerAddress].activeEECLevels[4] = true;
        users[donerAddress].activeEECLevels[5] = true;
        users[donerAddress].activeEECLevels[6] = true;
        users[donerAddress].activeEECLevels[7] = true;
        users[donerAddress].activeEECLevels[8] = true;
        users[donerAddress].activeEECLevels[9] = true;
        users[donerAddress].activeEECLevels[10] = true;
        users[donerAddress].activeEECLevels[11] = true;
        users[donerAddress].activeEECLevels[12] = true;
        users[donerAddress].activeEECLevels[13] = true;
        users[donerAddress].activeEECLevels[14] = true;
        users[donerAddress].activeEECLevels[15] = true;
        
        
        //------------------- EEC investmentt---------
        EECinvestment(donerAddress,1);
        EECinvestment(donerAddress,2);
        EECinvestment(donerAddress,3);
        EECinvestment(donerAddress,4);
        EECinvestment(donerAddress,5);
        EECinvestment(donerAddress,6);
        EECinvestment(donerAddress,7);
        EECinvestment(donerAddress,8);
        EECinvestment(donerAddress,9);
        EECinvestment(donerAddress,10);
        EECinvestment(donerAddress,11);
        EECinvestment(donerAddress,12);
        EECinvestment(donerAddress,13);
        EECinvestment(donerAddress,14);
        EECinvestment(donerAddress,15);
        users[donerAddress].slot = 1;
        userIds[1] = donerAddress;

        contractDeployTime = now;

        emit Registration(donerAddress, address(0), 1, 0, 0);
    }

    function() external payable {
        if (msg.data.length == 0) {
            return registration(msg.sender, doner);
        }

        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress)
        external
        payable
        returns (string memory)
    {
        registration(msg.sender, referrerAddress);
        return "registration successful";
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function registration(address userAddress, address referrerAddress)
        private
    {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        lastUserId++;

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            totalEEcBonus: uint256(0),
            slot: 1
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        users[userAddress].activeE3Levels[1] = true;
        users[userAddress].activeE6Levels[1] = true;
        users[userAddress].activeEECLevels[1] = true;

        userIds[lastUserId] = userAddress;

        users[referrerAddress].partnersCount++;

        address freeE3Referrer = findFreeE3Referrer(userAddress, 1);
        users[userAddress].E3Matrix[1].currentReferrer = freeE3Referrer;
        updateE3Referrer(userAddress, freeE3Referrer, 1);
        updateE6Referrer(userAddress, findFreeE6Referrer(userAddress, 1), 1);
        EECinvestment(userAddress, 1);
        emit Registration(
            userAddress,
            referrerAddress,
            users[userAddress].id,
            users[referrerAddress].id,
            msg.value
        );
    }

    function updateE3Referrer(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        users[referrerAddress].E3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].E3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(
                userAddress,
                referrerAddress,
                1,
                level,
                uint8(users[referrerAddress].E3Matrix[level].referrals.length)
            );
            return sendtrxDividends(referrerAddress, userAddress, 1, level);
        }

        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].E3Matrix[level].referrals = new address[](0);
        if (
            !users[referrerAddress].activeE3Levels[level + 1] &&
            level != LAST_LEVEL
        ) {
            users[referrerAddress].E3Matrix[level].blocked = true;
        }

        //create new one by recursion
        if (referrerAddress != doner) {
            //check referrer active level
            address freeReferrerAddress = findFreeE3Referrer(
                referrerAddress,
                level
            );
            if (
                users[referrerAddress].E3Matrix[level].currentReferrer !=
                freeReferrerAddress
            ) {
                users[referrerAddress].E3Matrix[level]
                    .currentReferrer = freeReferrerAddress;
            }

            users[referrerAddress].E3Matrix[level].reinvestCount++;
            emit Reinvest(
                referrerAddress,
                freeReferrerAddress,
                userAddress,
                1,
                level
            );
            updateE3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendtrxDividends(doner, userAddress, 1, level);
            users[doner].E3Matrix[level].reinvestCount++;
            emit Reinvest(doner, address(0), userAddress, 1, level);
        }
    }

    function profitPerShare(uint256 totalFund, uint256 usrfund)
        private
        returns (uint256)
    {
        require(totalFund > 0 && usrfund > 0, "Invalid fund");
        emit comment("usrfund ");
        emit chkvalue(usrfund);
        emit chkvalue(usrfund);
        uint256 ppf = ((usrfund * 10**6) / totalFund);
        emit comment("ppf");
        emit chkvalue(ppf);
        return ppf;
    }

    function bonusfund(
        address referrerAddress,
        uint8 level,
        uint256 ppf,
        uint256 usrfund
    ) private returns (uint256) {
        users[referrerAddress].EecMatrix[level].bonus = ppf * usrfund;
        emit comment("bonus");
        emit chkvalue(users[referrerAddress].EecMatrix[level].bonus);
        return users[referrerAddress].EecMatrix[level].bonus;
    }

    function withdraw(
        address userAddress,
        uint256 amount,
        uint8 level
    ) public returns (string memory) {
        emit comment("withdraw");
        require(
            EECc[level].EECuserbonusbalances[userAddress] > 0 &&
                amount <= EECc[level].EECuserbonusbalances[userAddress] &&
                EECc[level].EECuserbonusbalances[userAddress] <=
                bonusPrice[level],
            "invalid amount"
        );
        emit chkvalue(EECc[level].EECuserbonusbalances[userAddress]);
        EECc[level].EECuserbonusbalances[userAddress] =
            EECc[level].EECuserbonusbalances[userAddress] -
            amount;
        address(uint160(userAddress)).transfer(amount);
        return "withdraw successfull";
    }

    function bonus(address userAddress, uint8 level)
        public
        view
        returns (uint256)
    {
        return EECc[level].EECuserbonusbalances[userAddress];
    }
    function NetworkFees(uint8 level)
        public
        view
        returns (uint256)
    {
        return EECc[level].totalservicefund;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function EECinvestment(address userAddress, uint8 level) private {
        emit comment("In EEC investment");
        EECuserAddress[++EECc[level].user] = userAddress;
        emit chkvalue(level);
        emit chkvalue(EECc[level].user);
        users[userAddress].EecMatrix[level].userFund = levelPrice[level] / 2;
        EECc[level].fulltotalEECFund += users[userAddress].EecMatrix[level]
            .userFund;
        if (EECc[level].user > 1) {
            emit comment("totaleecinvestment");
            emit chkvalue(EECc[level].user - 1);
            emit chkvalue1(EECuserAddress[EECc[level].user - 1]);
            uint256 fund = levelPrice[level] / 2;
            EECc[level].EEcdistritefund += fund;
            uint256 eecfund = EECdistribute(
                EECuserAddress[EECc[level].user - 1],
                level
            );
            for (uint256 i = EECc[level].user - 1; i > 1; i--) {
                emit comment("---start EEC Distribution-------");
                emit chkvalue(EECc[level].EECuserbonusbalances[EECuserAddress[i - 1]]);
                emit chkvalue(bonusPrice[level]);
                EECc[level].EECuserbonusbalances[EECuserAddress[i - 1]] = EECc[level].EECuserbonusbalances[EECuserAddress[i - 1]] + eecfund;
                emit chkvalue(EECc[level].EECuserbonusbalances[EECuserAddress[i - 1]]);
                if (EECc[level].EECuserbonusbalances[EECuserAddress[i - 1]] <=bonusPrice[level] ) {
                    emit comment("---------Less than 310-----------------");
                      EECc[level].EECuserbonusbalances[EECuserAddress[i - 1]] = EECc[level].EECuserbonusbalances[EECuserAddress[i - 1]];
                } else {
                    emit comment("-----------------greater than 310-----------");
                    EECc[level].EECuserbonusbalances[EECuserAddress[i -
                        1]] = bonusPrice[level];
                }
            }
        }
    }

    function EECdistribute(address userAddress, uint8 level)
        private
        returns (uint256)
    {
        users[userAddress].EecMatrix[level].payout =
            users[userAddress].EecMatrix[level].userFund *
            EECc[level].profitperShare;
        emit comment("--------payout-------");
        emit chkvalue(users[userAddress].EecMatrix[level].payout);
        emit chkvalue(users[userAddress].EecMatrix[level].userFund);
        users[userAddress].EecMatrix[level].userserviceFund =
            (users[userAddress].EecMatrix[level].userFund * 7) /
            100;
        EECc[level].totalservicefund =
            EECc[level].totalservicefund +
            users[userAddress].EecMatrix[level].userserviceFund;
        uint256 userfundWithoutTax = users[userAddress].EecMatrix[level]
            .userFund - users[userAddress].EecMatrix[level].userserviceFund;
        EECc[level].totalEECFund += userfundWithoutTax;
        EECc[level].profitperShare += profitPerShare(
            EECc[level].EEcdistritefund,
            userfundWithoutTax
        );
        emit chkvalue(EECc[level].profitperShare);
        users[userAddress].EecMatrix[level].bonus = bonusfund(
            userAddress,
            level,
            EECc[level].profitperShare,
            users[userAddress].EecMatrix[level].userFund
        );
        emit comment("bonus");
        emit chkvalue(users[userAddress].EecMatrix[level].bonus);
        emit comment("payout check");
        emit chkvalue(users[userAddress].EecMatrix[level].payout);
        users[userAddress].EecMatrix[level].bonus =
            users[userAddress].EecMatrix[level].bonus -
            users[userAddress].EecMatrix[level].payout;   
        emit chkvalue(users[userAddress].EecMatrix[level].bonus);
        EECc[level].totaluserbonus += users[userAddress].EecMatrix[level].bonus;
        users[userAddress].totalEEcBonus += EECc[level].totaluserbonus;
        emit chkvalue(bonusPrice[level]);
        emit chkvalue((users[userAddress].EecMatrix[level].bonus));
        if ((users[userAddress].EecMatrix[level].bonus / 10**6) <= bonusPrice[level]) {
            emit comment("innnerr");
            EECc[level].EECuserbonusbalances[userAddress] =
                users[userAddress].EecMatrix[level].bonus /
                10**6;
            emit comment("----Less EECuserbonusbalances---");
            emit chkvalue(EECc[level].EECuserbonusbalances[userAddress]);
        } else {
            emit comment("----greter EEcuserbonusbalances---");
            EECc[level].EECuserbonusbalances[userAddress] = bonusPrice[level];
        }

        emit chkvalue(bonusPrice[level]);
        return EECc[level].EECuserbonusbalances[userAddress];
    }

    function updateE6Referrer(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        require(
            users[referrerAddress].activeE6Levels[level],
            "500. Referrer level is inactive"
        );

        if (
            users[referrerAddress].E6Matrix[level].firstLevelReferrals.length <
            2
        ) {
            users[referrerAddress].E6Matrix[level].firstLevelReferrals.push(
                userAddress
            );
            emit NewUserPlace(
                userAddress,
                referrerAddress,
                2,
                level,
                uint8(
                    users[referrerAddress].E6Matrix[level]
                        .firstLevelReferrals
                        .length
                )
            );

            //set current level
            users[userAddress].E6Matrix[level]
                .currentReferrer = referrerAddress;
            if (referrerAddress == doner) {
                return sendtrxDividends(referrerAddress, userAddress, 2, level);
            }

            address ref = users[referrerAddress].E6Matrix[level]
                .currentReferrer;
            users[ref].E6Matrix[level].secondLevelReferrals.push(userAddress);

            uint256 len = users[ref].E6Matrix[level].firstLevelReferrals.length;

            if (
                (len == 2) &&
                (users[ref].E6Matrix[level].firstLevelReferrals[0] ==
                    referrerAddress) &&
                (users[ref].E6Matrix[level].firstLevelReferrals[1] ==
                    referrerAddress)
            ) {
                if (
                    users[referrerAddress].E6Matrix[level]
                        .firstLevelReferrals
                        .length == 1
                ) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            } else if (
                (len == 1 || len == 2) &&
                users[ref].E6Matrix[level].firstLevelReferrals[0] ==
                referrerAddress
            ) {
                if (
                    users[referrerAddress].E6Matrix[level]
                        .firstLevelReferrals
                        .length == 1
                ) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (
                len == 2 &&
                users[ref].E6Matrix[level].firstLevelReferrals[1] ==
                referrerAddress
            ) {
                if (
                    users[referrerAddress].E6Matrix[level]
                        .firstLevelReferrals
                        .length == 1
                ) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return updateE6ReferrerSecondLevel(userAddress, ref, level);
        }

        users[referrerAddress].E6Matrix[level].secondLevelReferrals.push(
            userAddress
        );

        if (users[referrerAddress].E6Matrix[level].closedPart != address(0)) {
            if (
                (users[referrerAddress].E6Matrix[level]
                    .firstLevelReferrals[0] ==
                    users[referrerAddress].E6Matrix[level]
                        .firstLevelReferrals[1]) &&
                (users[referrerAddress].E6Matrix[level]
                    .firstLevelReferrals[0] ==
                    users[referrerAddress].E6Matrix[level].closedPart)
            ) {
                updateE6(userAddress, referrerAddress, level, true);
                return
                    updateE6ReferrerSecondLevel(
                        userAddress,
                        referrerAddress,
                        level
                    );
            } else if (
                users[referrerAddress].E6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].E6Matrix[level].closedPart
            ) {
                updateE6(userAddress, referrerAddress, level, true);
                return
                    updateE6ReferrerSecondLevel(
                        userAddress,
                        referrerAddress,
                        level
                    );
            } else {
                updateE6(userAddress, referrerAddress, level, false);
                return
                    updateE6ReferrerSecondLevel(
                        userAddress,
                        referrerAddress,
                        level
                    );
            }
        }

        if (
            users[referrerAddress].E6Matrix[level].firstLevelReferrals[1] ==
            userAddress
        ) {
            updateE6(userAddress, referrerAddress, level, false);
            return
                updateE6ReferrerSecondLevel(
                    userAddress,
                    referrerAddress,
                    level
                );
        } else if (
            users[referrerAddress].E6Matrix[level].firstLevelReferrals[0] ==
            userAddress
        ) {
            updateE6(userAddress, referrerAddress, level, true);
            return
                updateE6ReferrerSecondLevel(
                    userAddress,
                    referrerAddress,
                    level
                );
        }

        if (
            users[users[referrerAddress].E6Matrix[level].firstLevelReferrals[0]]
                .E6Matrix[level]
                .firstLevelReferrals
                .length <=
            users[users[referrerAddress].E6Matrix[level].firstLevelReferrals[1]]
                .E6Matrix[level]
                .firstLevelReferrals
                .length
        ) {
            updateE6(userAddress, referrerAddress, level, false);
        } else {
            updateE6(userAddress, referrerAddress, level, true);
        }

        updateE6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateE6(
        address userAddress,
        address referrerAddress,
        uint8 level,
        bool x2
    ) private {
        if (!x2) {
            users[users[referrerAddress].E6Matrix[level].firstLevelReferrals[0]]
                .E6Matrix[level]
                .firstLevelReferrals
                .push(userAddress);
            emit NewUserPlace(
                userAddress,
                users[referrerAddress].E6Matrix[level].firstLevelReferrals[0],
                2,
                level,
                uint8(
                    users[users[referrerAddress].E6Matrix[level]
                        .firstLevelReferrals[0]]
                        .E6Matrix[level]
                        .firstLevelReferrals
                        .length
                )
            );
            emit NewUserPlace(
                userAddress,
                referrerAddress,
                2,
                level,
                2 +
                    uint8(
                        users[users[referrerAddress].E6Matrix[level]
                            .firstLevelReferrals[0]]
                            .E6Matrix[level]
                            .firstLevelReferrals
                            .length
                    )
            );
            //set current level
            users[userAddress].E6Matrix[level]
                .currentReferrer = users[referrerAddress].E6Matrix[level]
                .firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].E6Matrix[level].firstLevelReferrals[1]]
                .E6Matrix[level]
                .firstLevelReferrals
                .push(userAddress);
            emit NewUserPlace(
                userAddress,
                users[referrerAddress].E6Matrix[level].firstLevelReferrals[1],
                2,
                level,
                uint8(
                    users[users[referrerAddress].E6Matrix[level]
                        .firstLevelReferrals[1]]
                        .E6Matrix[level]
                        .firstLevelReferrals
                        .length
                )
            );
            emit NewUserPlace(
                userAddress,
                referrerAddress,
                2,
                level,
                4 +
                    uint8(
                        users[users[referrerAddress].E6Matrix[level]
                            .firstLevelReferrals[1]]
                            .E6Matrix[level]
                            .firstLevelReferrals
                            .length
                    )
            );
            //set current level
            users[userAddress].E6Matrix[level]
                .currentReferrer = users[referrerAddress].E6Matrix[level]
                .firstLevelReferrals[1];
        }
    }

    function updateE6ReferrerSecondLevel(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        if (
            users[referrerAddress].E6Matrix[level].secondLevelReferrals.length <
            4
        ) {
            return sendtrxDividends(referrerAddress, userAddress, 2, level);
        }

        address[] memory e6 = users[users[referrerAddress].E6Matrix[level]
            .currentReferrer]
            .E6Matrix[level]
            .firstLevelReferrals;

        if (e6.length == 2) {
            if (e6[0] == referrerAddress || e6[1] == referrerAddress) {
                users[users[referrerAddress].E6Matrix[level].currentReferrer]
                    .E6Matrix[level]
                    .closedPart = referrerAddress;
            } else if (e6.length == 1) {
                if (e6[0] == referrerAddress) {
                    users[users[referrerAddress].E6Matrix[level]
                        .currentReferrer]
                        .E6Matrix[level]
                        .closedPart = referrerAddress;
                }
            }
        }

        users[referrerAddress].E6Matrix[level]
            .firstLevelReferrals = new address[](0);
        users[referrerAddress].E6Matrix[level]
            .secondLevelReferrals = new address[](0);
        users[referrerAddress].E6Matrix[level].closedPart = address(0);

        if (
            !users[referrerAddress].activeE6Levels[level + 1] &&
            level != LAST_LEVEL
        ) {
            users[referrerAddress].E6Matrix[level].blocked = true;
        }

        users[referrerAddress].E6Matrix[level].reinvestCount++;

        if (referrerAddress != doner) {
            address freeReferrerAddress = findFreeE6Referrer(
                referrerAddress,
                level
            );

            emit Reinvest(
                referrerAddress,
                freeReferrerAddress,
                userAddress,
                2,
                level
            );
            updateE6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(doner, address(0), userAddress, 2, level);
            sendtrxDividends(doner, userAddress, 2, level);
        }
    }

    function findFreeE3Referrer(address userAddress, uint8 level)
        public
        view
        returns (address)
    {
        while (true) {
            if (users[users[userAddress].referrer].activeE3Levels[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function findFreeE6Referrer(address userAddress, uint8 level)
        public
        view
        returns (address)
    {
        while (true) {
            if (users[users[userAddress].referrer].activeE6Levels[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function findEthReceiver(
        address userAddress,
        address _from,
        uint8 matrix,
        uint8 level
    ) private returns (address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].E3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].E3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].E6Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].E6Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendtrxDividends(
        address userAddress,
        address _from,
        uint8 matrix,
        uint8 level
    ) private {
        if (msg.sender != deployer) {
            (address receiver, bool isExtraDividends) = findEthReceiver(
                userAddress,
                _from,
                matrix,
                level
            );

            if (!address(uint160(receiver)).send(levelPrice[level] / 4)) {
                return
                    address(uint160(receiver)).transfer(address(this).balance);
            }

            if (isExtraDividends) {
                emit SentExtraEthDividends(_from, receiver, matrix, level);
            }
        }
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function usersE3Matrix(address userAddress, uint8 level)
        public
        view
        returns (
            address,
            address[] memory,
            bool
        )
    {
        return (
            users[userAddress].E3Matrix[level].currentReferrer,
            users[userAddress].E3Matrix[level].referrals,
            users[userAddress].E3Matrix[level].blocked
        );
    }

    function usersE6Matrix(address userAddress, uint8 level)
        public
        view
        returns (
            address,
            address[] memory,
            address[] memory,
            bool,
            address
        )
    {
        return (
            users[userAddress].E6Matrix[level].currentReferrer,
            users[userAddress].E6Matrix[level].firstLevelReferrals,
            users[userAddress].E6Matrix[level].secondLevelReferrals,
            users[userAddress].E6Matrix[level].blocked,
            users[userAddress].E6Matrix[level].closedPart
        );
    }

    function usersActiveE3Levels(address userAddress, uint8 level)
        public
        view
        returns (bool)
    {
        return users[userAddress].activeE3Levels[level];
    }

    function usersActiveE6Levels(address userAddress, uint8 level)
        public
        view
        returns (bool)
    {
        return users[userAddress].activeE6Levels[level];
    }

    function priviousSlotPurchase(address user, uint8 level)
        public
        view
        returns (bool status)
    {
        return users[user].activeE3Levels[level - 1];
    }

    function buyNewLevel(uint8 level) external payable returns (string memory) {
        investment(msg.sender, level);
        return "Level bought successfully";
    }

    function investment(address user, uint8 level) private {
        require(isUserExists(user), "user is not exists. Register first.");
        require(msg.value == levelPrice[level], "invalid price");
        // if(!(msg.sender==deployer)) require(msg.value == levelPrice[level]/10 ** 6, "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (level > 1)
            require(
                priviousSlotPurchase(user, level),
                "user is not purchase,first purchase privious slot"
            );

        require(!users[user].activeE3Levels[level], "level already activated");
        users[user].slot++;

        if (users[user].E3Matrix[level - 1].blocked) {
            users[user].E3Matrix[level - 1].blocked = false;
        }

        address freeE3Referrer = findFreeE3Referrer(user, level);
        users[user].E3Matrix[level].currentReferrer = freeE3Referrer;
        users[user].activeE3Levels[level] = true;
        updateE3Referrer(user, freeE3Referrer, level);

        emit Upgrade(user, freeE3Referrer, 1, level, msg.value / 4);

        require(!users[user].activeE6Levels[level], "level already activated");

        if (users[user].E6Matrix[level - 1].blocked) {
            users[user].E6Matrix[level - 1].blocked = false;
        }

        address freeE6Referrer = findFreeE6Referrer(user, level);

        users[user].activeE6Levels[level] = true;
        updateE6Referrer(user, freeE6Referrer, level);

        emit Upgrade(user, freeE6Referrer, 2, level, msg.value / 4);
        EECinvestment(user, level);
        users[user].activeEECLevels[level] = true;
        emit EECupgrade(user, level, (msg.value * 1) / 2);
    }

    function buynewlevelbyAdmin(address user, uint8 level)
        external
        isOwner
        returns (string memory)
    {
        investmentbyadmin(user, level);
        return "Level bought successfully";
    }

    function investmentbyadmin(address user, uint8 level) private {
        require(isUserExists(user), "user is not exists. Register first.");

        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (level > 1)
            require(
                priviousSlotPurchase(user, level),
                "user is not purchase,first purchase privious slot"
            );

        require(!users[user].activeE3Levels[level], "level already activated");
        users[user].slot++;

        if (users[user].E3Matrix[level - 1].blocked) {
            users[user].E3Matrix[level - 1].blocked = false;
        }

        address freeE3Referrer = findFreeE3Referrer(user, level);
        users[user].E3Matrix[level].currentReferrer = freeE3Referrer;
        users[user].activeE3Levels[level] = true;

        require(!users[user].activeE6Levels[level], "level already activated");

        if (users[user].E6Matrix[level - 1].blocked) {
            users[user].E6Matrix[level - 1].blocked = false;
        }
        users[user].activeE6Levels[level] = true;

        users[user].activeEECLevels[level] = true;
    }

    function registrationAdmin(address userAddress, address referrerAddress)
        external
        isOwner
        returns (string memory)
    {
        Admininregister(userAddress, referrerAddress);
        return "registration successful";
    }

    function Admininregister(address userAddress, address referrerAddress)
        private
        returns (string memory)
    {
        require(!isUserExists(userAddress), "user exists");

        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        lastUserId++;

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            totalEEcBonus: 0,
            slot: 1
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        users[userAddress].activeE3Levels[1] = true;
        users[userAddress].activeE6Levels[1] = true;
        users[userAddress].activeEECLevels[1] = true;

        userIds[lastUserId] = userAddress;
        users[referrerAddress].partnersCount++;
    }

    function withdrawNetworkFees(uint8 level)
        public
        payable
        isOwner
        returns (string memory)
    {
        if (EECc[level].totalservicefund > 0) {
            EECc[level].totalservicefund = EECc[level].totalservicefund / 10**6;
            emit chkvalue(EECc[level].totalservicefund);
            (msg.sender).transfer(EECc[level].totalservicefund);
            EECc[level].totalservicefund = 0;
            return "withdraw successfull";
        }
    }
}