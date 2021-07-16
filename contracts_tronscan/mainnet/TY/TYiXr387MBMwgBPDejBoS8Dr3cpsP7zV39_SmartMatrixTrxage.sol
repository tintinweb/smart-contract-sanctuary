//SourceUnit: SmartMatrixTrxage.sol

pragma solidity >=0.4.22 <0.6.0;

contract SmartMatrixTrxage{
    struct User {
        uint256 id;
        address referrer;
        uint256 partnersCount;
        mapping(uint8 => bool) activeJumpLevels;
        mapping(uint8 => bool) activeSlopLevels;
        mapping(uint8 => Jump) jumpMatrix;
        mapping(uint8 => Slop) slopMatrix;
    }

    struct Jump {
        address currentReferrer;
        address[] referrals;
        uint8 blockMeter;
        bool blocked;
        uint256 reinvestCount;
    }

    struct Slop {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint256 reinvestCount;
        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 14;

    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;

    uint256 public lastUserId = 1;
    address public owner;
    address public deploy;
    uint256 public contractDeployTime;

    mapping(uint8 => uint256) public levelPrice;
    mapping(uint8 => uint256) public levelPriceExt;

    event Registration(address indexed user, address indexed referrer, uint256 indexed userId, uint256 referrerId, uint256 amount);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint256 amount);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedTrxReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraTrxDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);

    constructor(address ownerAddress) public {
        levelPrice[1] = 100 * 1e6;
        levelPriceExt[1] = 100 * 1e6;
        uint8 i;
        for (i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
            levelPriceExt[i] = levelPrice[i - 1] * 2;
            if (i >= 4) {
                levelPriceExt[i] += uint256(levelPrice[i] / 100);
            }
        }
        deploy = msg.sender;
        owner = ownerAddress;
        User memory user = User({id: 1, referrer: address(0), partnersCount: uint256(0)});
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        for (i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeJumpLevels[i] = true;
            users[ownerAddress].activeSlopLevels[i] = true;
        }
        contractDeployTime = now;
        emit Registration(ownerAddress, address(0), 1, 0, 0);
    }

    function() external payable {
        if (msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable returns (string memory){
        registration(msg.sender, referrerAddress);
        return "registration successful";
    }

    function registrationCreator(address userAddress, address referrerAddress) external returns (string memory){
        require(msg.sender == deploy, "Invalid Doer");
        require(
            contractDeployTime + 86400 > now,
            "This function is only available for first 24 hours"
        );
        registration(userAddress, referrerAddress);
        return "registration successful";
    }

    function registration(address userAddress, address referrerAddress) private {
        if (!(msg.sender == deploy))
            require(
                msg.value == (levelPrice[1] * 4),
                "Invalid registration amount"
            );
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {size := extcodesize(userAddress)}
        require(size == 0, "cannot be a contract");
        lastUserId++;

        User memory user = User({id: lastUserId, referrer: referrerAddress, partnersCount: 0});
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeJumpLevels[1] = true;
        users[userAddress].activeSlopLevels[1] = true;
        users[referrerAddress].partnersCount++;
        address(uint160(owner)).transfer(levelPrice[1] * 2);
        address freeJumpReferrer = findFreeJumpReferrer(userAddress, 1);
        users[userAddress].jumpMatrix[1].currentReferrer = freeJumpReferrer;
        updateJumpReferrer(userAddress, freeJumpReferrer, 1);
        updateSlopReferrer(userAddress, findFreeSlopReferrer(userAddress, 1), 1);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, msg.value);
    }

    function buyLevelCreator(address userAddress, uint8 matrix, uint8 level) external returns (string memory) {
        require(msg.sender == deploy, "Invalid Donor");
        require(
            contractDeployTime + 86400 > now,
            "This function is only available for first 24 hours"
        );
        buyNewLevelInternal(userAddress, matrix, level);
        return "Level bought successfully";
    }

    function buyNewLevel(uint8 matrix, uint8 level) external payable returns (string memory){
        buyNewLevelInternal(msg.sender, matrix, level);
        return "Level bought successfully";
    }

    function buyNewLevelInternal(address user, uint8 matrix, uint8 level) private {
        require(isUserExists(user), "user is not exists. Register first.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        if (!(msg.sender == deploy))
            require(msg.value == levelPriceExt[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");

        if (level >= 4) {
            address(uint160(owner)).transfer(
                levelPriceExt[level] - levelPrice[level]
            );
        }

        if (matrix == 1) {
            require(
                !users[user].activeJumpLevels[level],
                "level already activated"
            );

            if (users[user].jumpMatrix[level - 1].blocked) {
                users[user].jumpMatrix[level - 1].blocked = false;
                users[user].jumpMatrix[level - 1].blockMeter = 0;
            }

            address freeJumpReferrer = findFreeJumpReferrer(user, level);
            users[user].jumpMatrix[level].currentReferrer = freeJumpReferrer;
            users[user].activeJumpLevels[level] = true;
            updateJumpReferrer(user, freeJumpReferrer, level);

            emit Upgrade(user, freeJumpReferrer, 1, level, msg.value);
        } else {
            require(
                !users[user].activeSlopLevels[level],
                "level already activated"
            );

            if (users[user].slopMatrix[level - 1].blocked) {
                users[user].slopMatrix[level - 1].blocked = false;
            }

            address freeSlopReferrer = findFreeSlopReferrer(user, level);

            users[user].activeSlopLevels[level] = true;
            updateSlopReferrer(user, freeSlopReferrer, level);

            emit Upgrade(user, freeSlopReferrer, 2, level, msg.value);
        }
    }

    function updateJumpReferrer(address userAddress, address referrerAddress, uint8 level) private {
        users[referrerAddress].jumpMatrix[level].referrals.push(userAddress);
        if (users[referrerAddress].jumpMatrix[level].referrals.length < 3) {
            emit NewUserPlace(userAddress, referrerAddress, 1, level, uint8(users[referrerAddress].jumpMatrix[level].referrals.length));
            return sendTRXDividends(referrerAddress, userAddress, 1, level);
        }

        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);
        //close matrix
        users[referrerAddress].jumpMatrix[level].referrals = new address[](0);
        if (
            !users[referrerAddress].activeJumpLevels[level + 1] &&
        level != LAST_LEVEL
        ) {
            users[referrerAddress].jumpMatrix[level].blockMeter++;
            if (users[referrerAddress].jumpMatrix[level].blockMeter == 2) {
                users[referrerAddress].jumpMatrix[level].blocked = true;
            }
        }

        //create new one by recursion
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findJumpReceiver(referrerAddress, level);
            if (users[referrerAddress].jumpMatrix[level].currentReferrer != freeReferrerAddress) {
                users[referrerAddress].jumpMatrix[level]
                .currentReferrer = freeReferrerAddress;
            }
            users[referrerAddress].jumpMatrix[level].reinvestCount++;
            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 1, level);
            updateJumpReferrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendTRXDividends(owner, userAddress, 1, level);
            users[owner].jumpMatrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function findJumpReceiver(address referrerAddress, uint8 level) public view returns (address){
        uint8 count = 0;
        address[] memory candidates = new address[](10);
        address receiver = users[referrerAddress].referrer;
        if (receiver == owner) {
            return receiver;
        }

        // Find candidates
        while (count < 10 && receiver != address(0)) {
            if (users[receiver].activeJumpLevels[level]) {
                candidates[count] = receiver;
                count++;

                uint8 k = count;
                while (k > 1) {
                    if (
                        calcEffectivePartners(candidates[k - 1], level) <=
                        calcEffectivePartners(candidates[k - 2], level)
                    ) {
                        address tmpUserAddr = candidates[k - 2];
                        candidates[k - 2] = candidates[k - 1];
                        candidates[k - 1] = tmpUserAddr;
                        k--;
                    } else {
                        break;
                    }
                }
            }

            receiver = users[receiver].referrer;
        }

        // Build threshold array
        uint256[] memory thresholds = new uint256[](count);
        thresholds[0] = calcEffectivePartners(candidates[0], level);
        for (uint256 i = 1; i < count; i++) {
            thresholds[i] = thresholds[i - 1] +
            calcEffectivePartners(candidates[i], level);
        }

        uint256 rand = generateRandomNum(thresholds[count - 1]);
        for (uint256 j = 0; j < count; j++) {
            if (rand <= thresholds[j]) {
                return candidates[j];
            }
        }

        return owner;
    }

    function calcEffectivePartners(address userAddr, uint8 level) public view returns (uint256 partnersCount){
        // return users[userAddr].partnersCount;
        return users[userAddr].jumpMatrix[level].reinvestCount * 3 + users[userAddr].jumpMatrix[level].referrals.length;
    }

    function generateRandomNum(uint256 upperLimit) public view returns (uint256 rand){
        bytes32 randHash = keccak256(abi.encodePacked(block.coinbase, now));
        return uint256(randHash) % upperLimit;
    }

    function updateSlopReferrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activeSlopLevels[level], "500. Referrer level is inactive");
        if (users[referrerAddress].slopMatrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].slopMatrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, 2, level, uint8(users[referrerAddress].slopMatrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].slopMatrix[level].currentReferrer = referrerAddress;
            if (referrerAddress == owner) {
                return sendTRXDividends(referrerAddress, userAddress, 2, level);
            }

            address ref = users[referrerAddress].slopMatrix[level].currentReferrer;
            users[ref].slopMatrix[level].secondLevelReferrals.push(userAddress);
            uint256 len = users[ref].slopMatrix[level].firstLevelReferrals.length;

            if ((len == 2) && (users[ref].slopMatrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].slopMatrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].slopMatrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            } else if (
                (len == 1 || len == 2) && users[ref].slopMatrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].slopMatrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (len == 2 && users[ref].slopMatrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].slopMatrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }
            return updateSlopReferrerSecondLevel(userAddress, ref, level);
        }
        users[referrerAddress].slopMatrix[level].secondLevelReferrals.push(userAddress);
        if (users[referrerAddress].slopMatrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].slopMatrix[level].firstLevelReferrals[0] == users[referrerAddress].slopMatrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].slopMatrix[level].firstLevelReferrals[0] == users[referrerAddress].slopMatrix[level].closedPart)) {
                updateSlop(userAddress, referrerAddress, level, true);
                return
                updateSlopReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (
                users[referrerAddress].slopMatrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].slopMatrix[level].closedPart
            ) {
                updateSlop(userAddress, referrerAddress, level, true);
                return
                updateSlopReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                updateSlop(userAddress, referrerAddress, level, false);
                return
                updateSlopReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].slopMatrix[level].firstLevelReferrals[1] == userAddress) {
            updateSlop(userAddress, referrerAddress, level, false);
            return
            updateSlopReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].slopMatrix[level].firstLevelReferrals[0] == userAddress) {
            updateSlop(userAddress, referrerAddress, level, true);
            return updateSlopReferrerSecondLevel(userAddress, referrerAddress, level);
        }

        if (users[users[referrerAddress].slopMatrix[level].firstLevelReferrals[0]].slopMatrix[level].firstLevelReferrals.length <=
            users[users[referrerAddress].slopMatrix[level].firstLevelReferrals[1]].slopMatrix[level].firstLevelReferrals.length) {
            updateSlop(userAddress, referrerAddress, level, false);
        } else {
            updateSlop(userAddress, referrerAddress, level, true);
        }
        updateSlopReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateSlop(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].slopMatrix[level].firstLevelReferrals[0]].slopMatrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].slopMatrix[level].firstLevelReferrals[0], 2,
                level, uint8(users[users[referrerAddress].slopMatrix[level].firstLevelReferrals[0]].slopMatrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level,
                2 + uint8(users[users[referrerAddress].slopMatrix[level].firstLevelReferrals[0]].slopMatrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].slopMatrix[level].currentReferrer = users[referrerAddress].slopMatrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].slopMatrix[level].firstLevelReferrals[1]].slopMatrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].slopMatrix[level].firstLevelReferrals[1], 2,
                level, uint8(users[users[referrerAddress].slopMatrix[level].firstLevelReferrals[1]].slopMatrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2, level,
                4 + uint8(users[users[referrerAddress].slopMatrix[level].firstLevelReferrals[1]].slopMatrix[level].firstLevelReferrals.length)
            );
            //set current level
            users[userAddress].slopMatrix[level].currentReferrer = users[referrerAddress].slopMatrix[level].firstLevelReferrals[1];
        }
    }

    function updateSlopReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].slopMatrix[level].secondLevelReferrals.length < 4) {
            return sendTRXDividends(referrerAddress, userAddress, 2, level);
        }

        address[] memory SlopRefs = users[users[referrerAddress].slopMatrix[level].currentReferrer].slopMatrix[level].firstLevelReferrals;
        if (SlopRefs.length == 2) {
            if (SlopRefs[0] == referrerAddress || SlopRefs[1] == referrerAddress) {
                users[users[referrerAddress].slopMatrix[level].currentReferrer].slopMatrix[level].closedPart = referrerAddress;
            } else if (SlopRefs.length == 1) {
                if (SlopRefs[0] == referrerAddress) {
                    users[users[referrerAddress].slopMatrix[level].currentReferrer].slopMatrix[level].closedPart = referrerAddress;
                }
            }
        }

        users[referrerAddress].slopMatrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].slopMatrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].slopMatrix[level].closedPart = address(0);

        if (!users[referrerAddress].activeSlopLevels[level + 1] && level != LAST_LEVEL) {
            users[referrerAddress].slopMatrix[level].blocked = true;
        }

        users[referrerAddress].slopMatrix[level].reinvestCount++;

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeSlopReferrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 2, level);
            updateSlopReferrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendTRXDividends(owner, userAddress, 2, level);
        }
    }

    function findFreeJumpReferrer(address userAddress, uint8 level) public view returns (address){
        while (true) {
            if (users[users[userAddress].referrer].activeJumpLevels[level]) {
                return users[userAddress].referrer;
            }

            userAddress = users[userAddress].referrer;
        }
    }

    function findFreeSlopReferrer(address userAddress, uint8 level) public view returns (address){
        while (true) {
            if (users[users[userAddress].referrer].activeSlopLevels[level]) {
                return users[userAddress].referrer;
            }
            userAddress = users[userAddress].referrer;
        }
    }

    function usersActiveJumpLevels(address userAddress, uint8 level) public view returns (bool){
        return users[userAddress].activeJumpLevels[level];
    }

    function usersActiveSlopLevels(address userAddress, uint8 level) public view returns (bool){
        return users[userAddress].activeSlopLevels[level];
    }

    function usersJumpMatrix(address userAddress, uint8 level) public view returns (address, address[] memory, bool){
        return (users[userAddress].jumpMatrix[level].currentReferrer, users[userAddress].jumpMatrix[level].referrals, users[userAddress].jumpMatrix[level].blocked);
    }

    function usersSlopMatrix(address userAddress, uint8 level) public view returns (address, address[] memory, address[] memory, bool, address){
        return (
        users[userAddress].slopMatrix[level].currentReferrer,
        users[userAddress].slopMatrix[level].firstLevelReferrals,
        users[userAddress].slopMatrix[level].secondLevelReferrals,
        users[userAddress].slopMatrix[level].blocked,
        users[userAddress].slopMatrix[level].closedPart);
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findTrxReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns (address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].jumpMatrix[level].blocked) {
                    emit MissedTrxReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].jumpMatrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].slopMatrix[level].blocked) {
                    emit MissedTrxReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].slopMatrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendTRXDividends(address userAddress, address _from, uint8 matrix, uint8 level) private {
        if (msg.sender != deploy) {
            (address receiver, bool isExtraDividends) = findTrxReceiver(userAddress, _from, matrix, level);

            if (!address(uint160(receiver)).send(levelPrice[level])) {
                return address(uint160(receiver)).transfer(address(this).balance);
            }
            if (isExtraDividends) {
                emit SentExtraTrxDividends(_from, receiver, matrix, level);
            }
        }
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr){
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    function GetJumpListInfo(address user) public view returns(bool[]memory,bool[]memory){
        bool [] memory jumpLevelState =new bool [](LAST_LEVEL);
        bool [] memory blockArr=new bool [](LAST_LEVEL);
        for (uint8 i = 1; i <= LAST_LEVEL; i++){
            jumpLevelState[i-1]=users[user].activeJumpLevels[i];
            blockArr[i-1]=users[user].jumpMatrix[i].blocked;
        }
        return(jumpLevelState, blockArr);
    }
    function GetSlopListInfo(address user) public view returns(bool[]memory,bool[]memory){
        bool [] memory slopLevelState =new bool [](LAST_LEVEL);
        bool [] memory blockArr=new bool [](LAST_LEVEL);
        for (uint8 i = 1; i <= LAST_LEVEL; i++){
            slopLevelState[i-1]=users[user].activeSlopLevels[i];
            blockArr[i-1]=users[user].slopMatrix[i].blocked;
        }
        return(slopLevelState, blockArr);
    }
}