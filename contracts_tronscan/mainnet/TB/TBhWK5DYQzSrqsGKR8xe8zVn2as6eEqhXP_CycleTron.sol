//SourceUnit: CycleTron.sol

pragma solidity 0.5.10;

contract CycleTron {

    struct Level {
        uint index;
        bool active;
        address parent;
        bool level1_finished;
        address[] referrals_line1;
        address[] referrals_line2;
        address lastFreeChild;
        uint256 reinvest;
    }

    struct LevelTree{
        uint8 l;
        mapping(uint => address) nodes;
        mapping(uint => bool) enables;

    }
    mapping(uint8 => LevelTree) public levelTrees;

    struct User {
        uint id;
        address referrer;
        uint partnersCount;

        uint borrowAmount;

        address borrowedFrom;

        mapping(uint8 => Level) levels;
        
        mapping(uint8 => X6) x6Matrix;
    }
    
    struct X6 {
        bool active;
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }
    
    uint8 public constant LAST_LEVEL = 9;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;

    mapping(uint => address) public userIds;

    uint public lastUserId = 0;
    
    address public root;
    address public operator;
    
    uint256 public contractDeployTime;
    uint256 public launchTime;
    
    uint public trxe6 = 1e6;

    uint public firstLevelPrice = 100 * trxe6;

    uint public x6Price;

    uint public totalTRX = 0;

    mapping(uint8 => uint) public levelPrice;

    event NewUserPlace(address indexed user, address indexed referrer, uint8 place);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller);
    event MissedEthReceive(address indexed receiver, address indexed from);
    event SentExtraEthDividends(address indexed from, address indexed receiver);

    event NewLevel(address indexed user, uint8 level, uint id);

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);

    modifier isOperator(){
        require(msg.sender == operator, "OperatorOnly");
        _;
    }    

    constructor() public {
        root = 0x1D7b3d9715e9BC32BB7c5E2c68368012E54Bae90;
        operator = msg.sender;
        
        //register root

        contractDeployTime = now;
        launchTime = now;

        levelPrice[1] = firstLevelPrice;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i-1] * 2;
        }

        x6Price = levelPrice[LAST_LEVEL]*2;

        _register(root, address(0), address(0));

        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            _buyLevel(root, i);
        }
        users[root].x6Matrix[1].active = true;
    }
    
    function() external payable {
        require(1==0, "TRX not accepted");
    }

    function register(address referrerAddress, address borrowFrom) public payable returns(uint) {
        //require(now > launchTime, "Not started yet");
        require(!isUserExists(msg.sender), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        require(borrowFrom==address(0) || users[borrowFrom].borrowAmount >= firstLevelPrice, "Lender does not have enough TRX.");
        require(borrowFrom != address(0) || msg.value==firstLevelPrice);

        return _register(msg.sender, referrerAddress, borrowFrom);
    }

    function depositLending() public payable returns(uint) {
        require(isUserExists(msg.sender), "user not exists");
        users[msg.sender].borrowAmount += msg.value;
        return users[msg.sender].borrowAmount;
    }

    function withdrawLending() public{
        require(users[msg.sender].borrowAmount > 0);
        _send(msg.sender, users[msg.sender].borrowAmount);
    }
    
    function _register(address userAddress, address referrerAddress, address borrowFrom) internal returns(uint) {
        lastUserId++;
    
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,

            borrowedFrom: borrowFrom,
            borrowAmount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        userIds[lastUserId] = userAddress;
        users[referrerAddress].partnersCount++;

        if(borrowFrom != address(0)){
            users[borrowFrom].borrowAmount -= firstLevelPrice;
        }

        emit Registration(
            userAddress,
            referrerAddress, 
            lastUserId,
            users[referrerAddress].id
        );

        if(userAddress != root){
            _buyLevel(userAddress, 1);
        }else{
            users[root].levels[1].active = true;
            users[root].levels[1].index = 1;
            levelTrees[1].nodes[1] = root;
            levelTrees[1].enables[1] = true;
            return 1;
        }
    }

    function _buyLevel(address userAddress, uint8 level) internal returns(uint){
        address parent = _findLevelParent(
            users[userAddress].referrer,
            level
        );

        if(userAddress != root){
            address levelParent = _addLevelNode(parent, userAddress, level);
            users[userAddress].levels[level].active = true;
            users[userAddress].levels[level].parent = levelParent;

            uint index = users[levelParent].levels[level].index*2;
            if(users[levelParent].levels[level].level1_finished){
                index += 1;
            }

            users[userAddress].levels[level].index = index;
            levelTrees[level].nodes[index] = userAddress;
            levelTrees[level].enables[index] = true;

            return index;
        }else{
            users[userAddress].levels[level].active = true;
            users[userAddress].levels[level].parent = address(0);
            users[userAddress].levels[level].index = 1;
            levelTrees[level].nodes[1] = userAddress;
            levelTrees[level].enables[1] = true;
            return 1;
        }
    }

    function _lastDepthIndex(uint index, uint last_index) pure internal returns(uint){
        while(true){
            if(last_index <= index*2+1){
                return index*2+1;
            }
            index = index*2 + 1;
        }
    }

    function _firstDepthIndex(uint index, uint last_index) pure internal returns(uint){
        while(true){
            if(index*2 > last_index){
                return index;
            }
            index = index*2;
        }
    }

    function _findFreeNodeByIndex(uint index, uint8 level, 
            uint last_index) view internal returns(address){
        uint[] memory addrs = new uint[](lastUserId);

        uint lIndex = 0;

        if(last_index != 0){
            uint last_depth_index = _lastDepthIndex(index, last_index);
            for(uint k=last_index; k<=last_depth_index ; k++){
                if(levelTrees[level].enables[k]){
                    address addr = levelTrees[level].nodes[k]; 
                    if(!users[addr].levels[level].level1_finished){
                        return addr;
                    }
                    if(levelTrees[level].enables[k*2])
                        addrs[lIndex++] = k*2;
                    if(levelTrees[level].enables[k*2+1])
                        addrs[lIndex++] = k*2+1; 
                }
            }

            uint first_depth_index = _firstDepthIndex(index, last_index*2);
            

            for(uint k=first_depth_index; k < last_index*2; k++){
                if(levelTrees[level].enables[k]){
                    address addr = levelTrees[level].nodes[k]; 
                    if(!users[addr].levels[level].level1_finished){
                        return addr;
                    }
                    if(levelTrees[level].enables[k*2])
                        addrs[lIndex++] = k*2;
                    if(levelTrees[level].enables[k*2+1])
                        addrs[lIndex++] = k*2+1; 
                }   
            }
        }else{
            addrs[lIndex++] = index;
        }

        uint i = 0;
        while(true){
            address addr = levelTrees[level].nodes[addrs[i]]; 
            if(!users[addr].levels[level].level1_finished){
                return addr;
            }
            if(levelTrees[level].enables[addrs[i]*2])
                addrs[lIndex++] = addrs[i]*2;
            if(levelTrees[level].enables[addrs[i]*2+1])
                addrs[lIndex++] = addrs[i]*2+1;
            i++;
        }
    }

  
    function _findFreeNode(address parent, address last_free_child,
        uint8 level) internal view returns(address){
        uint index = users[parent].levels[level].index;
        uint last_index = 0;
        if(last_free_child != address(0)){
            last_index = users[last_free_child].levels[level].index;
        }
        return _findFreeNodeByIndex(index, level, last_index);
    }

    function _addLevelNode(address node, address user, uint8 level) internal returns(address){
        address parent = _findFreeNode(
            node, users[node].levels[level].lastFreeChild,
            level);

        if(parent != node){
            users[node].levels[level].lastFreeChild = parent;
        }
        
        users[parent].levels[level].referrals_line1.push(user);
        users[parent].levels[level].level1_finished = users[parent].levels[level].referrals_line1.length==2;

        if(level == 1 && users[parent].borrowedFrom != address(0)){
            _send(users[parent].borrowedFrom, levelPrice[level]/2);
        }else{
            _send(parent, levelPrice[level]/2);
        }

        address upline = users[parent].levels[level].parent;

        if(upline != address(0)){
            users[upline].levels[level].referrals_line2.push(user);
            if(users[upline].levels[level].referrals_line2.length == 4){
                if(level < LAST_LEVEL){
                    _buyLevel(upline, level+1);
                }else if(level==LAST_LEVEL){
                    _enableX6(upline);
                }
                emit NewLevel(upline, level+1, users[upline].id);
            }    
        }else{
            _send(root, levelPrice[level]/2);
        }
        
        return parent;
    }


    function _enableX6(address user) internal{
        users[user].x6Matrix[1].active = true;
        if(user != root)
            updateX6Referrer(user, findFreeX6Referrer(user));
    }

    function updateX6Referrer(address userAddress, address referrerAddress) private {
        uint8 level = 1;        
        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, referrerAddress, uint8(users[referrerAddress].x6Matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == root) {
                return sendETHDividends(referrerAddress, userAddress);
            }
            
            address ref = users[referrerAddress].x6Matrix[level].currentReferrer;            
            users[ref].x6Matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].x6Matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].x6Matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 4);
                }
            } else if (len == 2 && users[ref].x6Matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].x6Matrix[level].firstLevelReferrals.length == 1) {
                    emit NewUserPlace(userAddress, ref, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 6);
                }
            }

            return updateX6ReferrerSecondLevel(userAddress, ref);
        }
        
        users[referrerAddress].x6Matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].x6Matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x6Matrix[level].closedPart)) {

                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress);
            } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].x6Matrix[level].closedPart) {
                updateX6(userAddress, referrerAddress, level, true);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress);
            } else {
                updateX6(userAddress, referrerAddress, level, false);
                return updateX6ReferrerSecondLevel(userAddress, referrerAddress);
            }
        }

        if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[1] == userAddress) {
            updateX6(userAddress, referrerAddress, level, false);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress);
        } else if (users[referrerAddress].x6Matrix[level].firstLevelReferrals[0] == userAddress) {
            updateX6(userAddress, referrerAddress, level, true);
            return updateX6ReferrerSecondLevel(userAddress, referrerAddress);
        }
        
        if (users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length) {
            updateX6(userAddress, referrerAddress, level, false);
        } else {
            updateX6(userAddress, referrerAddress, level, true);
        }
        
        updateX6ReferrerSecondLevel(userAddress, referrerAddress);
    }

    function updateX6(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[0], uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 2 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[0]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.push(userAddress);
            emit NewUserPlace(userAddress, users[referrerAddress].x6Matrix[level].firstLevelReferrals[1], uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            emit NewUserPlace(userAddress, referrerAddress, 4 + uint8(users[users[referrerAddress].x6Matrix[level].firstLevelReferrals[1]].x6Matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].x6Matrix[level].currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateX6ReferrerSecondLevel(address userAddress, address referrerAddress) private {
        uint8 level = 1;
        if (users[referrerAddress].x6Matrix[level].secondLevelReferrals.length < 4) {
            return sendETHDividends(referrerAddress, userAddress);
        }
        
        address[] memory x6 = users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].firstLevelReferrals;
        
        if (x6.length == 2) {
            if (x6[0] == referrerAddress ||
                x6[1] == referrerAddress) {
                users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
            } else if (x6.length == 1) {
                if (x6[0] == referrerAddress) {
                    users[users[referrerAddress].x6Matrix[level].currentReferrer].x6Matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].x6Matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].x6Matrix[level].closedPart = address(0);

        users[referrerAddress].x6Matrix[level].reinvestCount++;

        if (referrerAddress != root) {
            address freeReferrerAddress = findFreeX6Referrer(referrerAddress);


            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress);
            updateX6Referrer(referrerAddress, freeReferrerAddress);
        } else {
            emit Reinvest(root, address(0), userAddress);
            sendETHDividends(root, userAddress);
        }
    }

    function findFreeX6Referrer(address userAddress) public view returns(address) {
        uint8 level = 1;
        while (true) {
            require(userAddress != address(0), "address 0");
            if (users[users[userAddress].referrer].x6Matrix[level].active) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }


    function sendETHDividends(address userAddress, address _from) private {
        if(msg.sender!=root)
        {
            (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from);

            if(receiver == address(0)){
                receiver = root;
            }


            _send(receiver, x6Price);

            // if (!address(uint160(receiver)).send(x6Price)) {
            //     return address(uint160(receiver)).transfer(address(this).balance);
            // }
        
            if (isExtraDividends) {
                emit SentExtraEthDividends(_from, receiver);
            }
        }
    }

    function findEthReceiver(address userAddress, address _from) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        uint8 level = 1;
        while (true) {
            if (!users[receiver].x6Matrix[level].active) {
                emit MissedEthReceive(receiver, _from);
                isExtraDividends = true;
                receiver = users[receiver].x6Matrix[level].currentReferrer;
            } else {
                return (receiver, isExtraDividends);
            }
        }
    }


    function _findLevelParent(address user, uint8 level) public view returns(address){
        if(user==root || user==address(0)){
            return root;
        }
        if(users[user].levels[level].active){
            return user;
        }
        return _findLevelParent(users[user].referrer, level);
    }

    function _send(address addr, uint amount) private{
        uint transferable = amount <= address(this).balance ?
            amount : address(this).balance;
        if(addr == root){
            address(uint160(root)).transfer(transferable/2);
            address(uint160(operator)).transfer(transferable/2);
        }else{
            address(uint160(addr)).transfer(transferable);
        }
    }

    function levelParent(address user, uint8 level) public view returns(address){
        return users[user].levels[level].parent;
    }
    
    function parents(address user) public view returns (
        uint[100] memory ids,
        address[100] memory addrs,
        uint[100] memory bamounts
    ){
        uint i = 0;
        while(true){
            if(user == address(0)){
                return (ids,addrs,bamounts);
            }
            ids[i] = users[user].id;
            addrs[i] = user;
            bamounts[i] = users[user].borrowAmount;
            i++;

            user = users[user].referrer;
        }
    }

    function userData(address user) public view returns (
        uint[5] memory userInfo,
        bool[10] memory levels, 
        address[2][10] memory levelRefs1,
        address[2][10] memory levelRefs1Uplines,
        address[4][10] memory levelRefs2,
        address[4][10] memory levelRefs2Uplines,
        address[4][10] memory levelRefs2Parents,
        uint[10] memory SCInfo
    )
    {
        for (uint8 i = 0; i < LAST_LEVEL; i++) {
            levels[i] = users[user].levels[i+1].active;

            for(uint8 j=0; j < users[user].levels[i+1].referrals_line1.length; j++){
                address t = users[user].levels[i+1].referrals_line1[j];
                levelRefs1[i][j] = t;
                levelRefs1Uplines[i][j] = users[t].referrer;

            }

            for(uint8 j=0; j < users[user].levels[i+1].referrals_line2.length; j++){
                address u = users[user].levels[i+1].referrals_line2[j];
                if(u != address(0)){
                    levelRefs2[i][j] = u;
                    levelRefs2Parents[i][j] = users[u].levels[i+1].parent;
                    levelRefs2Uplines[i][j] = users[u].referrer;
                }
            }
            
        }

        //x6
        levels[LAST_LEVEL] = users[user].x6Matrix[1].active;
        for(uint8 j=0; j < users[user].x6Matrix[1].firstLevelReferrals.length; j++){
            address t = users[user].x6Matrix[1].firstLevelReferrals[j];
            levelRefs1[LAST_LEVEL][j] = t;
            levelRefs1Uplines[LAST_LEVEL][j] = users[t].referrer;            
        }

        for(uint8 j=0; j < users[user].x6Matrix[1].secondLevelReferrals.length; j++){
            address t = users[user].x6Matrix[1].secondLevelReferrals[j];            
            levelRefs2[LAST_LEVEL][j] = t;
            levelRefs2Parents[LAST_LEVEL][j] = users[t].x6Matrix[1].currentReferrer;
            levelRefs2Uplines[LAST_LEVEL][j] = users[t].referrer;
        }

        userInfo[0] = users[user].id;
        userInfo[1] = users[user].partnersCount;
        userInfo[2] = users[user].x6Matrix[1].reinvestCount;
        userInfo[3] = users[user].borrowAmount;

        SCInfo[0] = totalTRX;
        SCInfo[1] = address(this).balance;
        SCInfo[2] = lastUserId;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    // function updateLaunchTime(uint256 epoch) external isOperator returns (bool) {
    //     launchTime = epoch;
    //     return true;
    // }
}