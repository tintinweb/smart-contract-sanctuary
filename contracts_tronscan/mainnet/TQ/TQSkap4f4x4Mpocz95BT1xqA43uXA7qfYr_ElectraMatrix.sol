//SourceUnit: electraAkLive.sol

pragma solidity >=0.4.23 <0.6.0;

contract ElectraMatrix {
    struct User {
        uint256 id;
        address referrer;
        uint256 partnersCount;
        uint8 slot;
        mapping(uint8 => bool) activeE3Levels;
        mapping(uint8 => bool) activeE6Levels;
        mapping(uint8 => E3) E3Matrix;
        mapping(uint8 => E6) E6Matrix;
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
    
    mapping(uint8 => totalEEC) public totalEECBonus;
    struct totalEEC {
        uint8 level;
        uint256 fullAmount;
        uint256 deductedAmount;
        uint256 profitPerShare;
    }
    
    mapping(address => mapping(uint8 => payWith)) public payoutWithdraw;
    struct payWith {
        uint8 level;
        uint256 payoutAmount;
        uint256 withdrawAmount;
    }
    
    mapping(uint8 => netFeeEEC) public networkFeeEEC;
    struct netFeeEEC {
        uint8 level;
        uint256 totalAmount;
    }

    uint8 public constant LAST_LEVEL = 15;
    address public owner;
    address public superadmin;
    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(uint256 => address) public userIds;

    uint256 public lastUserId = 1;
    address public doner;
    address public deployer;
    uint256 public contractDeployTime;
    bool public contractStatus = false;

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
    event withdrawl(
        uint8 level,
        address indexed receiver,
        uint256 amount);
    event withdrawnetworkfees(
        uint8 level,
        address indexed receiver,
        uint256 amount);
    event chkvalue(uint256 value);
    event chkvalue1(address value);
    event comment(string msg);

    constructor(address donerAddress) public {
        owner = donerAddress;
        superadmin = donerAddress;
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
            referrer: superadmin,
            partnersCount: uint256(0),
            slot: uint8(0)
        });

        users[donerAddress] = user;
        idToAddress[0] = donerAddress;
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
        
        users[donerAddress].slot = 1;
        userIds[1] = donerAddress;

        contractDeployTime = now;

        emit Registration(donerAddress, superadmin, 1, 0, 0);
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
    
    function addTotalEEC(uint8 level, bool adminAdd) private returns (bool) {
        totalEECBonus[level].level = level;
        
        uint256 fullAmountAdd = levelPrice[level] / 2;
        totalEECBonus[level].fullAmount += fullAmountAdd;
        
        uint256 deductedAmountAdd = (fullAmountAdd / 100) * 93;
        totalEECBonus[level].deductedAmount += deductedAmountAdd;
        
        if(adminAdd != true) {
        uint256 networkFeeEECAdd = (fullAmountAdd / 100) * 7;
        networkFeeEEC[level].totalAmount += networkFeeEECAdd;
        
        uint256 profitPerShare = (deductedAmountAdd * 10 ** 6) / totalEECBonus[level].fullAmount;
        totalEECBonus[level].profitPerShare += profitPerShare;
        }
    }
    
    function addPayout(address userAddress,uint8 level) private returns (bool) {
        uint256 totalPayoutAmount = ((levelPrice[level]/2)*totalEECBonus[level].profitPerShare) / 10**6;
        payoutWithdraw[userAddress][level].level = level;
        payoutWithdraw[userAddress][level].payoutAmount = totalPayoutAmount;
    }
    
    function addWithdraw(address userAddress,uint8 level,uint256 withdrawAmount) private returns (bool) {
        payoutWithdraw[userAddress][level].level = level;
        payoutWithdraw[userAddress][level].withdrawAmount += withdrawAmount;
    }
    
    function startContract() public isOwner returns (bool) {
        contractStatus = true;
    }
    
    function pauseContract() public isOwner returns (bool) {
        contractStatus = false;
    }
    
    function bonus(address userAddress, uint8 level) public view returns (uint256,uint256)
    {
        if(users[userAddress].activeE3Levels[level] == true && users[userAddress].activeE6Levels[level] == true) {
            uint256 totalEECBNS = ((levelPrice[level]/2)*totalEECBonus[level].profitPerShare) / 10**6;
            totalEECBNS = totalEECBNS - payoutWithdraw[userAddress][level].payoutAmount;
            uint256 currentEECBNS = totalEECBNS - payoutWithdraw[userAddress][level].withdrawAmount;
            if(totalEECBNS <= bonusPrice[level]) {
                return (totalEECBNS,currentEECBNS);
            } else {
                return (bonusPrice[level],bonusPrice[level]);
            }
            
        } else {
            return (0,0);
        }
    }
    
    function withdrawEEC(address userAddress, uint8 level) public returns (bool)
    {
        if(users[userAddress].activeE3Levels[level] == true && users[userAddress].activeE6Levels[level] == true) {
            uint256 totalEECBNS = ((levelPrice[level]/2)*totalEECBonus[level].profitPerShare) / 10**6;
            totalEECBNS = totalEECBNS - payoutWithdraw[userAddress][level].payoutAmount;
            uint256 currentEECBNS = totalEECBNS - payoutWithdraw[userAddress][level].withdrawAmount;
            
            require(currentEECBNS > 0);
            uint256 finalAmount;
            if((payoutWithdraw[userAddress][level].withdrawAmount + currentEECBNS) <= bonusPrice[level]) {
                finalAmount = currentEECBNS;
            } else {
                if(payoutWithdraw[userAddress][level].withdrawAmount >= bonusPrice[level]) {
                    finalAmount = 0;
                } else {
                    finalAmount = bonusPrice[level] - payoutWithdraw[userAddress][level].withdrawAmount;
                }
            }
            
            address(uint160(userAddress)).transfer(finalAmount);
            emit withdrawl(level,userAddress,finalAmount);
            
            totalEECBonus[level].fullAmount -= finalAmount;
            totalEECBonus[level].deductedAmount -= finalAmount;
            addWithdraw(userAddress,level,finalAmount);
            
            return true;
            
        } else {
            return false;
        }
    }
    
    function NetworkFees(uint8 level) public view returns (uint256)
    {
        return networkFeeEEC[level].totalAmount;
    }
    
    function withdrawNetworkFees(uint8 level) public isOwner returns (bool)
    {
        require (networkFeeEEC[level].totalAmount > 0);
        address(uint160(doner)).transfer(networkFeeEEC[level].totalAmount);
        networkFeeEEC[level].totalAmount = 0;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function registration(address userAddress, address referrerAddress)
        private
    {
        require(contractStatus == true);
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
            slot: 1
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        users[userAddress].activeE3Levels[1] = true;
        users[userAddress].activeE6Levels[1] = true;

        userIds[lastUserId] = userAddress;

        users[referrerAddress].partnersCount++;

        address freeE3Referrer = findFreeE3Referrer(userAddress, 1);
        users[userAddress].E3Matrix[1].currentReferrer = freeE3Referrer;
        updateE3Referrer(userAddress, freeE3Referrer, 1);
        updateE6Referrer(userAddress, findFreeE6Referrer(userAddress, 1), 1);
        
        addTotalEEC(1, false);
        addPayout(userAddress, 1);
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
            emit Reinvest(doner, superadmin, userAddress, 1, level);
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

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
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

        if (users[referrerAddress].E6Matrix[level].closedPart != superadmin) {
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
        users[referrerAddress].E6Matrix[level].closedPart = superadmin;

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
            emit Reinvest(doner, superadmin, userAddress, 2, level);
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
        addTotalEEC(level, false);
        addPayout(user,level);
    }

    function buynewlevelbyAdmin(address user, uint8 level, uint256 amount)
        external
        isOwner
        returns (string memory)
    {
        investmentbyadmin(user, level, amount);
        return "Level bought successfully";
    }

    function investmentbyadmin(address user, uint8 level, uint256 amount) private {
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
        updateE3Referrer(user, freeE3Referrer, level);
        emit Upgrade(user, freeE3Referrer, 1, level, amount / 4);
        require(!users[user].activeE6Levels[level], "level already activated");

        if (users[user].E6Matrix[level - 1].blocked) {
            users[user].E6Matrix[level - 1].blocked = false;
        }
        address freeE6Referrer = findFreeE6Referrer(user, level);
        users[user].activeE6Levels[level] = true;
        updateE6Referrer(user, freeE6Referrer, level);
        users[user].E6Matrix[level].currentReferrer = freeE6Referrer;
        emit Upgrade(user, freeE6Referrer, 2, level, amount / 4);
        
        addTotalEEC(level, true);
    }

    function registrationAdmin(address userAddress, address referrerAddress, uint256 amount)
        external
        isOwner
        returns (string memory)
    {
        Admininregister(userAddress, referrerAddress, amount);
        return "registration successful";
    }

    function Admininregister(address userAddress, address referrerAddress, uint256 amount)
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
            slot: 1
        });

        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        users[userAddress].activeE3Levels[1] = true;
        users[userAddress].activeE6Levels[1] = true;

        userIds[lastUserId] = userAddress;
        users[referrerAddress].partnersCount++;

        address freeE3Referrer = findFreeE3Referrer(userAddress, 1);
        users[userAddress].E3Matrix[1].currentReferrer = freeE3Referrer;
        updateE3Referrer(userAddress, freeE3Referrer, 1);
        updateE6Referrer(userAddress, findFreeE6Referrer(userAddress, 1), 1);
        
        addTotalEEC(1, true);
        emit Registration(
            userAddress,
            referrerAddress,
            users[userAddress].id,
            users[referrerAddress].id,
            amount
        );
    }

}