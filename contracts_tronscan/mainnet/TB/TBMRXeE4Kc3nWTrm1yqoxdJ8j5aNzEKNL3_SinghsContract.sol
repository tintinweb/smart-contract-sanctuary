//SourceUnit: singhs-contract-near-to-final.sol

// SPDX-License-Identifier: BSD-3-Clause
/**
*
*
*           88                         88                        88
*           ""                         88                        ""
*                                      88
* ,adPPYba, 88 8b,dPPYba,   ,adPPYb,d8 88,dPPYba,  ,adPPYba,     88  ,adPPYba,
* I8[    "" 88 88P'   `"8a a8"    `Y88 88P'    "8a I8[    ""     88 a8"     "8a
*  `"Y8ba,  88 88       88 8b       88 88       88  `"Y8ba,      88 8b       d8
* aa    ]8I 88 88       88 "8a,   ,d88 88       88 aa    ]8I 888 88 "8a,   ,a8"
* `"YbbdP"' 88 88       88  `"YbbdP"Y8 88       88 `"YbbdP"' 888 88  `"YbbdP"'
*                         aa,    ,88
*                           "Y8bbdP"
*/

pragma solidity 0.5.9;

contract SinghsContract {

    struct UserAccount {
        uint32 id;
        uint32 directSales;
        address sponsor;
        bool exists;
        uint8[] activeSlot;

        mapping(uint8 => S3) s3Slots;
        mapping(uint8 => S9) s9Slots;
    }

    struct S3 {
        address sponsor;
        uint32 directSales;
        uint16 cycleCount;
        uint8 passup;
        uint8 reEntryCheck;
        uint8 placements;
    }

    struct S9 {
        address sponsor;
        uint32 directSales;
        uint16 cycleCount;
        uint8 passup;
        uint8 cyclePassup;
        uint8 reEntryCheck;
        uint8 placementPosition;
        address[] firstLevel;
        address placedUnder;
        uint8 lastOneLevelCount;
        uint8 lastTwoLevelCount;
        uint8 lastThreeLevelCount;
    }

    mapping(address => UserAccount) public userAccounts;
    mapping(uint32 => address) public idToUserAccount;
    mapping(uint8 => uint) public s3LevelPrice;
    mapping(uint8 => uint) public s9LevelPrice;

    address public owner;
    uint32 public lastId;
    uint8 public constant S3_LAST_LEVEL = 10;
    uint8 public constant S9_LAST_LEVEL = 11;
    uint internal reentry_status;
    uint internal constant ENTRY_ENABLED = 1;
    uint internal constant ENTRY_DISABLED = 2;

    modifier isOwner(address _ownerAddress) {
        require(owner == _ownerAddress, "Restricted Access!");
        _;
    }

    modifier isUserAccount(address _addr) {
        require(userAccounts[_addr].exists, "Register Account First");
        _;
    }

    modifier blockEntry() {

        require(reentry_status != ENTRY_DISABLED, "Security Entry Block");
        reentry_status = ENTRY_DISABLED;
        _;

        reentry_status = ENTRY_ENABLED;
    }

    event registerEvent(uint indexed userId, address indexed user, address indexed sponsor);
    event purchaseLevelEvent(address user, address sponsor, uint8 matrix, uint8 level);
    event positionS3Event(address user, address sponsor, uint8 level, uint8 placement, bool passup);
    event positionS9Event(address user, address sponsor, uint8 level, uint8 placementPosition, address placedUnder, bool passup);
    event cycleCompleteEvent(address indexed user, address fromPosition, uint8 matrix, uint8 level);
    event reEntryEvent(address indexed user, address reEntryFrom, uint8 matrix, uint8 level);
    event passupEvent(address indexed user, address passupFrom, uint8 matrix, uint8 level);
    event payoutEvent(address indexed user, address payoutFrom, uint8 matrix, uint8 level);

    constructor(address _user) public {

        owner = msg.sender;

        reentry_status = ENTRY_ENABLED;

        s3LevelPrice[1] = 250 * 1e6;
        s9LevelPrice[1] = 250 * 1e6;

        createAccount(_user, _user, true);

        setPositionS3(_user, _user, _user, 1, true);
        setPositionS9(_user, _user, _user, 1, true, false);

        for (uint8 i = 2; i <= S3_LAST_LEVEL; i++) {
            s3LevelPrice[i] = s3LevelPrice[i-1] * 2;
            setPositionS3(_user, _user, _user, i, true);
        }

         for (uint8 i = 2; i <= S9_LAST_LEVEL; i++) {
            s9LevelPrice[i] = s9LevelPrice[i-1] * 2;
            setPositionS9(_user, _user, _user, i, true, false);
        }
    }

    function() external payable {

        if(msg.data.length == 0) {
            registrationEntry(msg.sender, idToUserAccount[1]);
        }

        registrationEntry(msg.sender, bytesToAddress(msg.data));
    }


    function doRegistration(address _sponsor) external payable blockEntry() {
        registrationEntry(msg.sender, _sponsor);
    }

    function registrationEntry(address _user, address _sponsor) internal  {

        require((s3LevelPrice[1] * 2) == msg.value, "500 TRX Require to register!");

        createAccount(_user, _sponsor, false);

        userAccounts[_sponsor].directSales++;

        setPositionS3(_user, _sponsor, _sponsor, 1, false);
        setPositionS9(_user, _sponsor, _sponsor, 1, false, true);

        doS3Payout(_user, 1);
    }

    function createAccount(address _user, address _sponsor, bool _initial) internal {

        require(!userAccounts[_user].exists, "Already a Singhs Account");

        if (_initial == false) {
            require(userAccounts[_sponsor].exists, "Sponsor doesnt exists");
        }

        lastId++;

        userAccounts[_user] = UserAccount({
            id: lastId,
            sponsor: _sponsor,
            exists: true,
            directSales: 0,
            activeSlot: new uint8[](2)
        });

        idToUserAccount[lastId] = _user;

        emit registerEvent(lastId, _user, _sponsor);

    }

    function purchaseLevel(uint8 _matrix, uint8 _level) external payable isUserAccount(msg.sender) {

        require(userAccounts[msg.sender].exists, "User not exists, Buy First Level");

        require(_matrix == 1 || _matrix == 2, "Invalid Sings Matrix");

        address sponsor = userAccounts[msg.sender].sponsor;

        if (_matrix == 1) {

            require(_level > 1 && _level <= S3_LAST_LEVEL, "Invalid s3 Level");

            require(msg.value == s3LevelPrice[_level], "Invalid s3 Price");

            require(userAccounts[msg.sender].activeSlot[0] < _level, "s3 level already activated");

            setPositionS3(msg.sender, sponsor, findActiveSponsor(msg.sender, sponsor, 0, _level, true), _level, false);

            emit purchaseLevelEvent(msg.sender, sponsor, _matrix, _level);

            doS3Payout(msg.sender, _level);


        } else {

            require(_level > 1 && _level <= S9_LAST_LEVEL, "Invalid s9 Level");

            require(msg.value == s9LevelPrice[_level], "Invalid s9 Price");

            require(userAccounts[msg.sender].activeSlot[1] < _level, "s9 level already activated");

            setPositionS9(msg.sender, sponsor, findActiveSponsor(msg.sender, sponsor, 1, _level, true), _level, false, true);

            emit purchaseLevelEvent(msg.sender, sponsor, _matrix, _level);
        }



    }

    function setPositionS3(address _user, address _realSponsor, address _sponsor, uint8 _level, bool _initial) internal {

        UserAccount storage userAccount = userAccounts[_user];

        userAccount.activeSlot[0] = _level;

        userAccount.s3Slots[_level] = S3({
            sponsor: _sponsor, placements: 0, directSales: 0, cycleCount: 0, passup: 0, reEntryCheck: 0
        });

        if (_initial == true) {
            return ;
        }
        else if (_realSponsor == _sponsor) {
            userAccounts[_realSponsor].s3Slots[_level].directSales++;
        } else {
            userAccount.s3Slots[_level].reEntryCheck = 1; // This user place under other User
        }

        sponsorParentS3(_user, _sponsor, _level, false);

    }

    function sponsorParentS3(address _user, address _sponsor, uint8 _level, bool passup) internal {

        S3 storage slot = userAccounts[_sponsor].s3Slots[_level];

        emit positionS3Event(_user, _sponsor, _level, (slot.placements+1), passup);

        if (slot.placements >= 2) {

            emit cycleCompleteEvent(_sponsor, _user, 1, _level); // Finish Cycle of Sponsor Parent

            slot.placements = 0;
            slot.cycleCount++;

            if (_sponsor != idToUserAccount[1]) {
                slot.passup++;
                sponsorParentS3(_sponsor, slot.sponsor, _level, true);
            }

        } else {
            slot.placements++;
        }
    }

    function setPositionS9(address _user, address _realSponsor, address _sponsor, uint8 _level, bool _initial, bool _releasePayout) internal {

        UserAccount storage userAccount = userAccounts[_user];

        userAccount.activeSlot[1] = _level;

        userAccount.s9Slots[_level] = S9({
            sponsor: _sponsor, directSales: 0, cycleCount: 0, passup: 0, reEntryCheck: 0,
            placementPosition: 0, placedUnder: _sponsor, firstLevel: new address[](0), lastOneLevelCount: 0, lastTwoLevelCount:0, lastThreeLevelCount: 0, cyclePassup: 0
        });

        if (_initial == true) {
            return;
        } else if (_realSponsor == _sponsor) {
            userAccounts[_realSponsor].s9Slots[_level].directSales++;
        } else {
            userAccount.s9Slots[_level].reEntryCheck = 1; // This user place under other User
        }

        sponsorParentS9(_user, _sponsor, _level, false, _releasePayout);
    }

    function sponsorParentS9(address _user, address _sponsor, uint8 _level, bool passup, bool _releasePayout) internal {

        S9 storage userAccountSlot = userAccounts[_user].s9Slots[_level];
        S9 storage slot = userAccounts[_sponsor].s9Slots[_level];

        if (slot.firstLevel.length < 3) {

            if (slot.firstLevel.length == 0) {
                userAccountSlot.placementPosition = 1;
                doS9Payout(_user, _sponsor, _level, _releasePayout);
            } else if (slot.firstLevel.length == 1) {
                userAccountSlot.placementPosition = 2;
                doS9Payout(_user, slot.placedUnder, _level, _releasePayout);
                if (_sponsor != idToUserAccount[1]) {
                    slot.passup++;
                }

            } else {
                userAccountSlot.placementPosition = 3;
                if (_sponsor != idToUserAccount[1]) {
                    slot.passup++;
                }
            }

            userAccountSlot.placedUnder = _sponsor;
            slot.firstLevel.push(_user);

            emit positionS9Event(_user, _sponsor, _level, userAccountSlot.placementPosition, userAccountSlot.placedUnder, passup);

            setPositionsAtLastLevelS9(_user, _sponsor, slot.placedUnder, slot.placementPosition, _level, _releasePayout);
        }
        else {

            S9 storage slotUnderOne = userAccounts[slot.firstLevel[0]].s9Slots[_level];
            S9 storage slotUnderTwo = userAccounts[slot.firstLevel[1]].s9Slots[_level];
            S9 storage slotUnderThree = userAccounts[slot.firstLevel[2]].s9Slots[_level];


            if (slotUnderOne.firstLevel.length < 3 && slot.lastOneLevelCount < 7) {

                if (slotUnderOne.firstLevel.length == 0) {

                    userAccountSlot.placementPosition = 1;
                    userAccountSlot.placedUnder = slot.firstLevel[0];
                    slot.lastOneLevelCount += 1;
                    doS9Payout(_user, userAccountSlot.placedUnder, _level, _releasePayout);

                } else if (slotUnderOne.firstLevel.length == 1) {

                    userAccountSlot.placementPosition = 2;
                    userAccountSlot.placedUnder = slot.firstLevel[0];
                    slot.lastOneLevelCount += 2;
                    doS9Payout(_user, slotUnderOne.placedUnder, _level, _releasePayout);
                    if (_sponsor != idToUserAccount[1]) { slotUnderOne.passup++; }

                } else {

                    userAccountSlot.placementPosition = 3;
                    userAccountSlot.placedUnder = slot.firstLevel[0];
                    slot.lastOneLevelCount += 4;

                    if (_sponsor != idToUserAccount[1]) {

                        slotUnderOne.passup++;

                        if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {
                            slot.cyclePassup++;
                        }
                        else {
                            doS9Payout(_user, slotUnderOne.placedUnder, _level, _releasePayout);
                        }
                    }
                }
            }
            else if (slotUnderTwo.firstLevel.length < 3 && slot.lastTwoLevelCount < 7) {

                if (slotUnderTwo.firstLevel.length == 0) {

                    userAccountSlot.placementPosition = 1;
                    userAccountSlot.placedUnder = slot.firstLevel[1];
                    slot.lastTwoLevelCount += 1;
                    doS9Payout(_user, userAccountSlot.placedUnder, _level, _releasePayout);

                } else if (slotUnderTwo.firstLevel.length == 1) {

                    userAccountSlot.placementPosition = 2;
                    userAccountSlot.placedUnder = slot.firstLevel[1];
                    slot.lastTwoLevelCount += 2;
                    doS9Payout(_user, slotUnderTwo.placedUnder, _level, _releasePayout);
                    if (_sponsor != idToUserAccount[1]) { slotUnderTwo.passup++; }

                } else {

                    userAccountSlot.placementPosition = 3;
                    userAccountSlot.placedUnder = slot.firstLevel[1];
                    slot.lastTwoLevelCount += 4;

                    if (_sponsor != idToUserAccount[1]) {

                        slotUnderTwo.passup++;

                        if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {
                            slot.cyclePassup++;
                        }
                        else {
                            doS9Payout(_user, slotUnderTwo.placedUnder, _level, _releasePayout);
                        }
                    }
                }
            }
            else {

                if (slotUnderThree.firstLevel.length == 0) {

                    userAccountSlot.placementPosition = 1;
                    userAccountSlot.placedUnder = slot.firstLevel[2];
                    slot.lastThreeLevelCount += 1;
                    doS9Payout(_user, userAccountSlot.placedUnder, _level, _releasePayout);

                } else if (slotUnderThree.firstLevel.length == 1) {

                    userAccountSlot.placementPosition = 2;
                    userAccountSlot.placedUnder = slot.firstLevel[2];
                    slot.lastThreeLevelCount += 2;
                    doS9Payout(_user, slotUnderThree.placedUnder, _level, _releasePayout);
                    if (_sponsor != idToUserAccount[1]) { slotUnderThree.passup++; }

                } else {

                    userAccountSlot.placementPosition = 3;
                    userAccountSlot.placedUnder = slot.firstLevel[2];
                    slot.lastThreeLevelCount += 4;
                    if (_sponsor != idToUserAccount[1]) {

                        slotUnderThree.passup++;
                        if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {
                            slot.cyclePassup++;
                        }
                        else {
                            doS9Payout(_user, slotUnderThree.placedUnder, _level, _releasePayout);
                        }
                    }
                }
            }

            if (userAccountSlot.placedUnder != idToUserAccount[1]) {
                userAccounts[userAccountSlot.placedUnder].s9Slots[_level].firstLevel.push(_user);
            }

            emit positionS9Event(_user, _sponsor, _level, userAccountSlot.placementPosition, userAccountSlot.placedUnder, passup);
        }


        if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {

            emit cycleCompleteEvent(_sponsor, _user, 2, _level);

            slot.firstLevel = new address[](0);
            slot.lastOneLevelCount = 0;
            slot.lastTwoLevelCount = 0;
            slot.lastThreeLevelCount = 0;
            slot.cycleCount++;

            if (_sponsor != idToUserAccount[1]) {
                sponsorParentS9(_user, slot.sponsor, _level, true, _releasePayout);
            }
        }

    }

    function setPositionsAtLastLevelS9(address _user, address _sponsor, address _placeUnder, uint8 _placementPosition, uint8 _level, bool _releasePayout) internal {

        S9 storage slot = userAccounts[_placeUnder].s9Slots[_level];

        if (slot.placementPosition == 0 && _sponsor == idToUserAccount[1]) {

            return;
        }

        if (_placementPosition == 1) {

            if ((slot.lastOneLevelCount & 1) == 0) { slot.lastOneLevelCount += 1; }
            else if ((slot.lastOneLevelCount & 2) == 0) { slot.lastOneLevelCount += 2; }
            else { slot.lastOneLevelCount += 4; }

        }
        else if (_placementPosition == 2) {

            if ((slot.lastTwoLevelCount & 1) == 0) { slot.lastTwoLevelCount += 1; }
            else if ((slot.lastTwoLevelCount & 2) == 0) {slot.lastTwoLevelCount += 2; }
            else {slot.lastTwoLevelCount += 4; }

        }
        else {

            if ((slot.lastThreeLevelCount & 1) == 0) { slot.lastThreeLevelCount += 1; }
            else if ((slot.lastThreeLevelCount & 2) == 0) { slot.lastThreeLevelCount += 2; }
            else { slot.lastThreeLevelCount += 4; }
        }

        if ((slot.lastOneLevelCount + slot.lastTwoLevelCount + slot.lastThreeLevelCount) == 21) {

            emit cycleCompleteEvent(_placeUnder, _user, 2, _level);

            slot.firstLevel = new address[](0);
            slot.lastOneLevelCount = 0;
            slot.lastTwoLevelCount = 0;
            slot.lastThreeLevelCount = 0;
            slot.cycleCount++;

            if (_sponsor != idToUserAccount[1]) {
                sponsorParentS9(_user, slot.sponsor, _level, true, _releasePayout);
            }
        }
        else {

            S9 storage userAccountSlot = userAccounts[_user].s9Slots[_level];

            if (userAccountSlot.placementPosition == 3) {

                doS9Payout(_user, _placeUnder, _level, _releasePayout);
            }
        }
    }

    function doS3Payout(address _user, uint8 _level) internal {

        address receiver = findPayoutReceiver(_user, 0, _level);

        emit payoutEvent(receiver, _user, 1, _level);

        if (!address(uint160(receiver)).send(s3LevelPrice[_level])) {
            return address(uint160(idToUserAccount[1])).transfer(s3LevelPrice[_level]);
        }

    }

    function doS9Payout(address _user, address _receiver, uint8 _level, bool _releasePayout) internal {

        if (_releasePayout == false) {
            return;
        }

        emit payoutEvent(_receiver, _user, 2, _level);

        if (!address(uint160(_receiver)).send(s9LevelPrice[_level])) {
            return address(uint160(idToUserAccount[1])).transfer(s9LevelPrice[_level]);
        }

    }

    function findPayoutReceiver(address _user, uint8 _matrix, uint8 _level) internal returns (address) {

        address from;
        address receiver;

        if (_matrix == 0)
        {
            receiver = userAccounts[_user].s3Slots[_level].sponsor;

            while (true) {

                S3 storage s3Slot = userAccounts[receiver].s3Slots[_level];

                if (s3Slot.passup == 0) {
                    return receiver;
                }

                s3Slot.passup--;
                from = receiver;
                receiver = s3Slot.sponsor;

                if (_level > 1 && s3Slot.reEntryCheck > 0) {
                    reEntryS3(from, _level);
                }
            }
        }
        else {

            receiver = userAccounts[_user].s9Slots[_level].placedUnder;

            while(true) {

                S9 storage s9Slot = userAccounts[receiver].s9Slots[_level];

                if (s9Slot.passup == 0 && s9Slot.cyclePassup == 0) {
                    return receiver;
                }

                if (s9Slot.passup > 0) {
                    s9Slot.passup--;
                    receiver = s9Slot.placedUnder;
                }
                else {

                    s9Slot.cyclePassup--;
                    from = receiver;
                    receiver = s9Slot.sponsor;

                    if (_level > 1 && s9Slot.reEntryCheck > 0) {
                        reEntryS9(from, _level); // If Reentry then shuffle the Sponsor Parent with Real Parent
                    }
                }
            }
        }
    }

    function reEntryS3(address _user, uint8 _level) internal {

        S3 storage slot = userAccounts[_user].s3Slots[_level];
        bool reentry = false;

        slot.reEntryCheck++;

        if (slot.reEntryCheck >= 2) {
            address sponsor = userAccounts[_user].sponsor; // Real Sponsor

            if (userAccounts[sponsor].activeSlot[0] >= _level) {
                slot.reEntryCheck = 0;
                reentry = true;
            } else {

                sponsor = findActiveSponsor(_user, sponsor, 0, _level, false);
                if (slot.sponsor != sponsor && userAccounts[sponsor].activeSlot[0] >= _level) {
                    reentry = true;
                }
            }

            if (reentry == true) {
                slot.sponsor = sponsor;
                emit reEntryEvent(sponsor, _user, 1, _level);
            }
        }
    }

    function reEntryS9(address _user, uint8 _level) internal {

        S9 storage slot = userAccounts[_user].s9Slots[_level];
        bool reentry = false;

        slot.reEntryCheck++;

        if (slot.reEntryCheck >= 2) {

            address sponsor = userAccounts[_user].sponsor; // Real Sponsor

            if (userAccounts[sponsor].activeSlot[1] >= _level) {
                slot.reEntryCheck = 0;
                reentry = true;
            }
            else {
                sponsor = findActiveSponsor(_user, sponsor, 1, _level, false);
                if (slot.sponsor != sponsor && userAccounts[sponsor].activeSlot[1] >= _level) {
                    reentry = true;
                }
            }

            if (reentry == true) {
                slot.sponsor = sponsor;
                emit reEntryEvent(slot.sponsor, _user, 2, _level);
            }
        }
    }

    function findActiveSponsor(address _user, address _sponsor, uint8 _matrix, uint8 _level, bool _doEmit) internal returns (address) {

        address sponsorAddress = _sponsor;

        while (true) {

            if (userAccounts[sponsorAddress].activeSlot[_matrix] >= _level) {
                return sponsorAddress;
            }

            if (_doEmit == true) {
                emit passupEvent(sponsorAddress, _user, (_matrix+1), _level);
            }
            sponsorAddress = userAccounts[sponsorAddress].sponsor;
        }

    }

    function getAccountId() external view returns (uint) {
        return userAccounts[msg.sender].id;
    }

    function getAccountAddress(uint32 userId) external view returns (address) {
        return idToUserAccount[userId];
    }

    function usersS33Matrix(address _user, uint8 _level) public view returns(address, uint8, uint32, uint16) {

        return (userAccounts[_user].s3Slots[_level].sponsor,
                userAccounts[_user].s3Slots[_level].placements,
                userAccounts[_user].s3Slots[_level].directSales,
                userAccounts[_user].s3Slots[_level].cycleCount);
    }

    function usersS93Matrix(address _user, uint8 _level) public view returns(address, address, uint8, uint32, uint16, address[] memory, uint8, uint8, uint8, uint8) {

        S9 storage slot = userAccounts[_user].s9Slots[_level];

        return (slot.sponsor,
                slot.placedUnder,
                slot.placementPosition,
                slot.directSales,
                slot.cycleCount,
                slot.firstLevel,
                slot.lastOneLevelCount,
                slot.lastTwoLevelCount,
                slot.lastThreeLevelCount,
                slot.passup);
    }

    function setupUserAccount(address _user, address _sponsor, uint8 _level) external isOwner(msg.sender) {

        createAccount(_user, _sponsor, false);

        setupLevel(_user, 1, _level);
        setupLevel(_user, 2, _level);

    }

    function setupLevel(address _user, uint8 _matrix, uint8 _level) public isOwner(msg.sender) isUserAccount(_user) {

        require((_matrix == 1 || _matrix == 2), "Invalid Singhs Matrix");

        if (_matrix == 1) {
            require((_level > 0 && _level <= S3_LAST_LEVEL), "Invalid s3 Slot");
        }
        else {
            require((_level > 0 && _level <= S9_LAST_LEVEL), "Invalid s9 Slot");
        }

        uint8 matrix = _matrix - 1;
        uint8 activeSlot = userAccounts[_user].activeSlot[matrix];
        address sponsor = userAccounts[_user].sponsor;

        require((activeSlot < _level), "Already active at this Slot");

        for (uint8 num = (activeSlot + 1); num <= _level; num++) {

            emit purchaseLevelEvent(_user, sponsor, _matrix, num);

            if (matrix == 0) {
                setPositionS3(_user, sponsor, findActiveSponsor(_user, sponsor, 0, num, true), num, false);
            } else {
                setPositionS9(_user, sponsor, findActiveSponsor(_user, sponsor, 0, num, true), num, false, false);
            }
        }
    }
    function bytesToAddress(bytes memory _source) private pure returns (address addr) {
        assembly {
            addr := mload(add(_source, 20))
        }
    }
}