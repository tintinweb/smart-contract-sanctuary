//SourceUnit: SmartLotto.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;

contract CareerPlan {
    function addToBalance() external payable;
    function addUserToLevel(address _user, uint _id, uint8 _level) external;
}

contract Lotto {
    function addUser(address user) external;
    function addToRaffle() external payable;
}

contract SmartLotto {
    event SignUpEvent(address indexed _newUser, uint indexed _userId, address indexed _sponsor, uint _sponsorId);
    event NewUserChildEvent(address indexed _user, address indexed _sponsor, uint8 _box, bool _isSmartDirect, uint8 _position);
    event ReinvestBoxEvent(address indexed _user, address indexed currentSponsor, address indexed addrCaller, uint8 _box, bool _isSmartDirect);
    event MissedEvent(address indexed _from, address indexed _to, uint8 _box, bool _isSmartDirect);
    event SentExtraEvent(address indexed _from, address indexed _to, uint8 _box, bool _isSmartDirect);
    event UpgradeStatusEvent(address indexed _user, address indexed _sponsor, uint8 _box, bool _isSmartDirect);

    struct SmartTeamBox {
        bool purchased;
        bool inactive;
        uint reinvests;
        address closedAddr;
        address[] firstLevelChilds;
        address[] secondLevelChilds;
        address currentSponsor;
        uint partnersCount;
    }

    struct SmartDirectBox {
        bool purchased;
        bool inactive;
        uint reinvests;
        address[] childs;
        address currentSponsor;
        uint partnersCount;
    }

    struct User {
        uint id;
        uint partnersCount;
        mapping(uint8=>SmartDirectBox) directBoxes;
        mapping(uint8=>SmartTeamBox) teamBoxes;
        address sponsor;
        uint8 levelCareerPlan;
        bool activeInLottery;
    }

    uint nextId = 1;
    address externalAddress;
    address externalFeeAddress;
    address rootAddress;
    mapping(address=>User) public users;
    mapping(uint=>address) public idLookup;

    CareerPlan careerPlan;
    struct PlanRequirements {
        uint purchasedBoxes;
        uint countReferrers;
    }
    mapping(uint8 => PlanRequirements) levelRequirements;
    Lotto lottery;

    struct Distribution {
        uint user;
        uint lotto;
        uint careerPlan;
        uint owner;
        uint fee;
    }
    mapping(uint8 => Distribution) boxDistribution;
    mapping(uint8 => uint) public boxesValues;

    modifier validSponsor(address _sponsor) {
        require(users[_sponsor].id != 0, "This sponsor does not exists");
        _;
    }

    modifier onlyUser() {
        require(users[msg.sender].id != 0, "This user does not exists");
        _;
    }

    modifier validNewUser(address _newUser) {
        uint32 size;
        assembly {
            size := extcodesize(_newUser)
        }
        require(size == 0, "The new user cannot be a contract");
        require(users[_newUser].id == 0, "This user already exists");
        _;
    }

    modifier validBox(uint _box) {
        require(_box >= 1 && _box <= 14, "Invalid box");
        _;
    }

    constructor(address _externalAddress, address _careerPlanAddress,
        address _lotteryAddress, address _externalFeeAddress, address _rootAddress
    ) public {
        externalAddress = _externalAddress;
        externalFeeAddress = _externalFeeAddress;
        rootAddress = _rootAddress;
        lottery = Lotto(_lotteryAddress);
        initializeValues();
        initializeCareerPlan(_careerPlanAddress);
        User storage root = users[_rootAddress];
        root.id = nextId++;
        idLookup[root.id] = _rootAddress;
        for (uint8 i = 1; i <= 14; i++) {
            root.directBoxes[i].purchased = true;
            root.teamBoxes[i].purchased = true;
        }
    }

    function initializeValues() internal {
        boxesValues[1] = 250 trx;
        boxesValues[2] = 500 trx;
        boxesValues[3] = 1000 trx;
        boxesValues[4] = 2000 trx;
        boxesValues[5] = 4000 trx;
        boxesValues[6] = 8000 trx;
        boxesValues[7] = 16000 trx;
        boxesValues[8] = 32000 trx;
        boxesValues[9] = 64000 trx;
        boxesValues[10] = 128000 trx;
        boxesValues[11] = 256000 trx;
        boxesValues[12] = 512000 trx;
        boxesValues[13] = 1024000 trx;
        boxesValues[14] = 2048000 trx;
        boxDistribution[1] = Distribution({user: 175 trx, lotto: 52.5 trx, careerPlan: 13.5 trx, owner: 8.325 trx, fee: 0.675 trx});
        boxDistribution[2] = Distribution({user: 350 trx, lotto: 105 trx, careerPlan: 27 trx, owner: 16.65 trx, fee: 1.35 trx});
        boxDistribution[3] = Distribution({user: 700 trx, lotto: 210 trx, careerPlan: 54 trx, owner: 33.3 trx, fee: 2.7 trx});
        boxDistribution[4] = Distribution({user: 1400 trx, lotto: 420 trx, careerPlan: 108 trx, owner: 66.6 trx, fee: 5.4 trx});
        boxDistribution[5] = Distribution({user: 2800 trx, lotto: 840 trx, careerPlan: 216 trx, owner: 133.2 trx, fee: 10.8 trx});
        boxDistribution[6] = Distribution({user: 5600 trx, lotto: 1680 trx, careerPlan: 432 trx, owner: 266.4 trx, fee: 21.6 trx});
        boxDistribution[7] = Distribution({user: 11200 trx, lotto: 3360 trx, careerPlan: 864 trx, owner: 532.8 trx, fee: 43.2 trx});
        boxDistribution[8] = Distribution({user: 22400 trx, lotto: 6720 trx, careerPlan: 1728 trx, owner: 1065.6 trx, fee: 86.4 trx});
        boxDistribution[9] = Distribution({user: 44800 trx, lotto: 13440 trx, careerPlan: 3456 trx, owner: 2131.2 trx, fee: 172.8 trx});
        boxDistribution[10] = Distribution({user: 89600 trx, lotto: 26880 trx, careerPlan: 6912 trx, owner: 4262.4 trx, fee: 345.6 trx});
        boxDistribution[11] = Distribution({user: 179200 trx, lotto: 53760 trx, careerPlan: 13824 trx, owner: 8524.8 trx, fee: 691.2 trx});
        boxDistribution[12] = Distribution({user: 358400 trx, lotto: 107520 trx, careerPlan: 27648 trx, owner: 17049.6 trx, fee: 1382.4 trx});
        boxDistribution[13] = Distribution({user: 716800 trx, lotto: 215040 trx, careerPlan: 55296 trx, owner: 34099.2 trx, fee: 2764.8 trx});
        boxDistribution[14] = Distribution({user: 1433600 trx, lotto: 430080 trx, careerPlan: 110592 trx, owner: 68198.4 trx, fee: 5529.6 trx});
    }

    function initializeCareerPlan(address _careerPlanAddress) internal {
        careerPlan = CareerPlan(_careerPlanAddress);
        levelRequirements[1].countReferrers = 10;
        levelRequirements[1].purchasedBoxes = 3;
        levelRequirements[2].countReferrers = 20;
        levelRequirements[2].purchasedBoxes = 6;
        levelRequirements[3].countReferrers = 30;
        levelRequirements[3].purchasedBoxes = 9;
        levelRequirements[4].countReferrers = 40;
        levelRequirements[4].purchasedBoxes = 12;
        levelRequirements[5].countReferrers = 60;
        levelRequirements[5].purchasedBoxes = 14;
    }

    function() external payable {
        if(msg.data.length == 0) return signUp(msg.sender, rootAddress);
        address sponsor;
        bytes memory data = msg.data;
        assembly {
            sponsor := mload(add(data, 20))
        }
        signUp(msg.sender, sponsor);
    }

    function signUp(address payable _newUser, address _sponsor) private validSponsor(_sponsor) validNewUser(_newUser) {
        require(msg.value == 500 * 1e6, "Please enter required amount");

        // user node data
        User storage userNode = users[_newUser];
        userNode.id = nextId++;
        userNode.sponsor = _sponsor;
        userNode.directBoxes[1].purchased = true;
        userNode.teamBoxes[1].purchased = true;
        idLookup[userNode.id] = _newUser;

        users[_sponsor].partnersCount++;
        users[_sponsor].directBoxes[1].partnersCount++;
        users[_sponsor].teamBoxes[1].partnersCount++;
        userNode.directBoxes[1].currentSponsor = _sponsor;
        modifySmartDirectSponsor(_sponsor, _newUser, 1);
        modifySmartTeamSponsor(_sponsor, _newUser, 1);
        emit SignUpEvent(_newUser, userNode.id, _sponsor,  users[_sponsor].id);
    }

    function signUp(address sponsor) external payable {
        signUp(msg.sender, sponsor);
    }

    function buyNewBox(uint8 _matrix, uint8 _box) external payable onlyUser validBox(_box) {
        require(_matrix == 1 || _matrix == 2, "Invalid matrix");
        require(msg.value == boxesValues[_box], "Please enter required amount");
        if (_matrix == 1) {
            require(!users[msg.sender].directBoxes[_box].purchased, "You already bought that box");
            require(users[msg.sender].directBoxes[_box - 1].purchased, "Please bought the boxes prior to this");

            users[msg.sender].directBoxes[_box].purchased = true;
            users[msg.sender].directBoxes[_box - 1].inactive = false;
            address sponsorResult = findSponsor(msg.sender, _box, true);
            users[msg.sender].directBoxes[_box].currentSponsor = sponsorResult;
            modifySmartDirectSponsor(sponsorResult, msg.sender, _box);
            if(users[users[msg.sender].sponsor].directBoxes[_box].purchased) {
                users[users[msg.sender].sponsor].directBoxes[_box].partnersCount++;
                verifyLevelOfUser(users[msg.sender].sponsor);
            }
            emit UpgradeStatusEvent(msg.sender, sponsorResult, _box, true);
        } else {
            require(!users[msg.sender].teamBoxes[_box].purchased, "You already bought that box");
            require(users[msg.sender].teamBoxes[_box - 1].purchased, "Please bought the boxes prior to this");

            users[msg.sender].teamBoxes[_box].purchased = true;
            users[msg.sender].teamBoxes[_box - 1].inactive = false;
            address sponsorResult = findSponsor(msg.sender, _box, false);
            modifySmartTeamSponsor(sponsorResult, msg.sender, _box);
            if(users[users[msg.sender].sponsor].teamBoxes[_box].purchased) {
                users[users[msg.sender].sponsor].teamBoxes[_box].partnersCount++;
                verifyLevelOfUser(users[msg.sender].sponsor);
            }

            emit UpgradeStatusEvent(msg.sender, sponsorResult, _box, false);
        }
        verifyRequirementsForLottery(msg.sender);
    }

    function verifyLevelOfUser(address user) internal {
        if (users[user].levelCareerPlan >= 5) return;
        uint8 level = users[user].levelCareerPlan + 1;
        PlanRequirements memory requirements = levelRequirements[level];
        for(uint8 i = 1; i <= requirements.purchasedBoxes; i++) {
            if(!users[user].directBoxes[i].purchased || !users[user].teamBoxes[i].purchased) return;
            if(users[user].directBoxes[i].partnersCount < requirements.countReferrers
                || users[user].teamBoxes[i].partnersCount < requirements.countReferrers) return;
        }
        users[user].levelCareerPlan = level;
        careerPlan.addUserToLevel(user, users[user].id, level);
    }

    function verifyRequirementsForLottery(address user) internal {
        if (users[user].activeInLottery) return;
        for(uint8 i = 1; i <= 3; i++) {
            if(!users[user].directBoxes[i].purchased || !users[user].teamBoxes[i].purchased)
                return;
        }
        users[user].activeInLottery = true;
        lottery.addUser(user);
    }

    function modifySmartDirectSponsor(address _sponsor, address _user, uint8 _box) private {
        users[_sponsor].directBoxes[_box].childs.push(_user);
        uint8 position = uint8(users[_sponsor].directBoxes[_box].childs.length);
        emit NewUserChildEvent(_user, _sponsor, _box, true, position);
        if (position < 3)
            return applyDistribution(_user, _sponsor, _box, true);
        SmartDirectBox storage directData = users[_sponsor].directBoxes[_box];
        directData.childs = new address[](0);
        if (!users[_sponsor].directBoxes[_box + 1].purchased && _box != 14) directData.inactive = true;
        directData.reinvests++;
        if (rootAddress != _sponsor) {
            address sponsorResult = findSponsor(_sponsor, _box, true);
            directData.currentSponsor = sponsorResult;
            emit ReinvestBoxEvent(_sponsor, sponsorResult, _user, _box, true);
            modifySmartDirectSponsor(sponsorResult, _sponsor, _box);
        } else {
            applyDistribution(_user, _sponsor, _box, true);
            emit ReinvestBoxEvent(_sponsor, address(0), _user, _box, true);
        }
    }

    function findSponsor(address _addr, uint8 _box, bool _isSmartDirect) internal view returns(address) {
        User memory node = users[_addr];
        bool purchased;
        if (_isSmartDirect) purchased = users[node.sponsor].directBoxes[_box].purchased;
        else purchased = users[node.sponsor].teamBoxes[_box].purchased;
        if (purchased) return node.sponsor;
        return findSponsor(node.sponsor, _box, _isSmartDirect);
    }

    function modifySmartTeamSponsor(address _sponsor, address _user, uint8 _box) private {
        SmartTeamBox storage sponsorBoxData = users[_sponsor].teamBoxes[_box];

        if (sponsorBoxData.firstLevelChilds.length < 2) {
            sponsorBoxData.firstLevelChilds.push(_user);
            users[_user].teamBoxes[_box].currentSponsor = _sponsor;
            emit NewUserChildEvent(_user, _sponsor, _box, false, uint8(sponsorBoxData.firstLevelChilds.length));

            if (_sponsor == rootAddress)
                return applyDistribution(_user, _sponsor, _box, false);

            address currentSponsor = sponsorBoxData.currentSponsor;
            users[currentSponsor].teamBoxes[_box].secondLevelChilds.push(_user);

            uint8 len = uint8(users[currentSponsor].teamBoxes[_box].firstLevelChilds.length);

            for(uint8 i = len - 1; i >= 0; i++) {
                if(users[currentSponsor].teamBoxes[_box].firstLevelChilds[i] == _sponsor) {
                    emit NewUserChildEvent(_user, currentSponsor, _box, false, uint8((2 * (i + 1)) + sponsorBoxData.firstLevelChilds.length));
                    break;
                }
            }

            return modifySmartTeamSecondLevel(_user, currentSponsor, _box);
        }

        sponsorBoxData.secondLevelChilds.push(_user);

        if (sponsorBoxData.closedAddr != address(0)) {
            uint8 index;
            if (sponsorBoxData.firstLevelChilds[0] == sponsorBoxData.closedAddr) {
                index = 1;
            }
            modifySmartTeam(_sponsor, _user, _box, index);
            return modifySmartTeamSecondLevel(_user, _sponsor, _box);
        }

        for(uint8 i = 0;i < 2;i++) {
            if(sponsorBoxData.firstLevelChilds[i] == _user) {
                modifySmartTeam(_sponsor, _user, _box, i^1);
                return modifySmartTeamSecondLevel(_user, _sponsor, _box);
            }
        }
        uint8 index = 1;
        if (users[sponsorBoxData.firstLevelChilds[0]].teamBoxes[_box].firstLevelChilds.length <=
            users[sponsorBoxData.firstLevelChilds[1]].teamBoxes[_box].firstLevelChilds.length) {
            index = 0;
        }
        modifySmartTeam(_sponsor, _user, _box, index);
        modifySmartTeamSecondLevel(_user, _sponsor, _box);
    }

    function modifySmartTeam(address _sponsor, address _user, uint8 _box, uint8 _index) private {
        User storage userData = users[_user];
        User storage sponsorData = users[_sponsor];
        address chieldAddress = sponsorData.teamBoxes[_box].firstLevelChilds[_index];
        User storage childData = users[chieldAddress];
        childData.teamBoxes[_box].firstLevelChilds.push(_user);
        uint8 length = uint8(childData.teamBoxes[_box].firstLevelChilds.length);
        uint position = (2**(_index + 1)) + length;
        emit NewUserChildEvent(_user, chieldAddress, _box, false, length);
        emit NewUserChildEvent(_user, _sponsor, _box, false, uint8(position));
        userData.teamBoxes[_box].currentSponsor = chieldAddress;
    }

    function modifySmartTeamSecondLevel(address _user, address _sponsor, uint8 _box) private {
        User storage sponsorData = users[_sponsor];
        if (sponsorData.teamBoxes[_box].secondLevelChilds.length < 4)
            return applyDistribution(_user, _sponsor, _box, false);

        User storage currentSponsorData = users[sponsorData.teamBoxes[_box].currentSponsor];
        address[] memory childs = currentSponsorData.teamBoxes[_box].firstLevelChilds;

        for(uint8 i = 0;i < childs.length;i++) {
            if(childs[i] == _sponsor)
                currentSponsorData.teamBoxes[_box].closedAddr = _sponsor;
        }
        sponsorData.teamBoxes[_box].firstLevelChilds = new address[](0);
        sponsorData.teamBoxes[_box].secondLevelChilds = new address[](0);
        sponsorData.teamBoxes[_box].closedAddr = address(0);
        sponsorData.teamBoxes[_box].reinvests++;

        if (!sponsorData.teamBoxes[_box + 1].purchased && _box != 14)
            sponsorData.teamBoxes[_box].inactive = true;

        if (sponsorData.id == 1) {
            emit ReinvestBoxEvent(_sponsor, address(0), _user, _box, false);
            return applyDistribution(_user, _sponsor, _box, false);
        }
        address sponsorResult = findSponsor(_sponsor, _box, false);
        emit ReinvestBoxEvent(_sponsor, sponsorResult, _user, _box, false);
        modifySmartTeamSponsor(sponsorResult, _sponsor, _box);
    }

    function applyDistribution(address _from, address _to, uint8 _box, bool _isSmartDirect) private {
        (address receiver, bool haveMissed) = getReceiver(_from, _to, _box, _isSmartDirect, false);
        if(!address(uint160(receiver)).send(boxDistribution[_box].user))
            address(uint160(receiver)).transfer(boxDistribution[_box].user);
        if(!address(uint160(externalAddress)).send(boxDistribution[_box].owner))
            address(uint160(externalAddress)).transfer(boxDistribution[_box].owner);
        if(!address(uint160(externalFeeAddress)).send(boxDistribution[_box].fee))
            address(uint160(externalFeeAddress)).transfer(boxDistribution[_box].fee);
        lottery.addToRaffle.value(boxDistribution[_box].lotto)();
        careerPlan.addToBalance.value(boxDistribution[_box].careerPlan)();
        if (haveMissed)
            emit SentExtraEvent(_from, receiver, _box, _isSmartDirect);
    }

    function getReceiver(address _from, address _to, uint8 _box, bool _isSmartDirect, bool _haveMissed) private  returns(address, bool) {
        bool blocked;
        address sponsor;
        if (_isSmartDirect) {
            SmartDirectBox memory directBoxData = users[_to].directBoxes[_box];
            blocked = directBoxData.inactive;
            sponsor = directBoxData.currentSponsor;
        } else {
            SmartTeamBox memory teamBoxData = users[_to].teamBoxes[_box];
            blocked = teamBoxData.inactive;
            sponsor = teamBoxData.currentSponsor;
        }
        if (!blocked) return (_to, _haveMissed);
        emit MissedEvent(_from, _to, _box, _isSmartDirect);
        return getReceiver(_from, sponsor, _box, _isSmartDirect, true);
    }

    function userSmartDirectBoxInfo(address _user, uint8 _box) public view returns(bool, bool, uint, address[] memory, address) {
        SmartDirectBox memory data = users[_user].directBoxes[_box];
        return (data.purchased, data.inactive, data.reinvests,
        data.childs, data.currentSponsor);
    }

    function userSmartTeamBoxInfo(address _user, uint8 _box) public view returns(bool, bool, uint, address, address[] memory, address[] memory, address) {
        SmartTeamBox memory data = users[_user].teamBoxes[_box];
        return (data.purchased, data.inactive, data.reinvests, data.closedAddr,
        data.firstLevelChilds, data.secondLevelChilds, data.currentSponsor);
    }

    function isValidUser(address _user) public view returns (bool) {
        return (users[_user].id != 0);
    }
}