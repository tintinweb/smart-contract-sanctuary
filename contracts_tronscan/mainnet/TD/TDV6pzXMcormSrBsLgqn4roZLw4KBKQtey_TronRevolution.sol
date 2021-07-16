//SourceUnit: TronRevolution.sol

pragma solidity ^0.5.4;

contract TronRevolution {

    struct UserStruct {

        address parentId;
        address referrerId;
        uint24 nextLevel;
        uint40 profit;
        uint40 totalIncome;
        bool isRegistered;
        address payable[] childrenIds;

    }
    
    event NewUserEvent(address indexed id, uint surpluses, address referrerId);
    event NewPledgeEvent(address indexed id, uint surpluses);
    event NewPowerEvent(address indexed id, uint surpluses);
    
    
    address payable xtronWallet;
    address payable surplusWallet;
    address payable devWallet;
    address payable marketinWallet;
    address payable communityWallet;

    mapping(address => UserStruct) public users;
    address payable[] public powerMatrix;
    address payable[] public pledgeMatrix;
    
    // uint public leadershipSurplus;
    // uint public powerMatrixSurplus;
    // uint public pledgeMatrixSurplus;
    // uint public otherIncome;
    
    uint public totalUsers;
    //uint public totalSurpluses;
    // uint public totalPowerMatrixIncome;
    // uint public totalPledgeIncome;
    // uint public totalInversionIncome;
    //uint public totalIncome;

    uint constant PERCENT_DIVIDER = 10000;
    uint constant TICKET_PRICE = 200 trx;
    uint constant PLEDGE_PRICE = 100 trx;
    uint constant MAX_LEADERSHIP = 20 trx;
    uint constant MAX_POWER = 56 trx;
    uint constant MAX_PLEDGE = 60 trx;
    uint constant DIRECT_REFERRAL = 30 trx;
    uint[12]  LEADERSHIP_RATES = [4 trx, 3 trx, 2 trx, 1 trx, 1 trx,1 trx,1 trx,1 trx,1 trx,1 trx, 2 trx,2 trx];
    uint[12]  POWER_RATES = [35e5, 35e5, 35e5, 105e5, 70e5, 70e5, 35e5, 35e5, 35e5, 35e5, 35e5, 35e5];
    uint[12]  OVERRIDING_RATES = [100, 75, 50, 25, 25, 25, 25, 25, 25, 25, 50, 50];

    constructor(address payable _root, address payable _xtronWallet, address payable _surplusWallet, address payable _devWallet, address payable _marketingWallet, address payable _communityWallet) public {

        xtronWallet = _xtronWallet;
        surplusWallet = _surplusWallet;
        devWallet = _devWallet;
        marketinWallet = _marketingWallet;
        communityWallet = _communityWallet;
        
        users[_root].isRegistered = true;
        powerMatrix.push(_root);
        pledgeMatrix.push(_root);
        totalUsers++;

    }

    function selectChildNode(address _userId) public view returns (address payable){

        UserStruct storage user = users[_userId];

        if (users[user.childrenIds[0]].nextLevel < users[user.childrenIds[1]].nextLevel && users[user.childrenIds[0]].nextLevel < users[user.childrenIds[2]].nextLevel)
            return user.childrenIds[0];
        else if (users[user.childrenIds[1]].nextLevel < users[user.childrenIds[2]].nextLevel)
            return user.childrenIds[1];
        else
            return user.childrenIds[2];

    }

    function needUpdate(address _userId) public view returns (bool) {

        UserStruct storage parent = users[users[_userId].parentId];

        if (parent.childrenIds.length < 3) return false;

        for (uint i = 0; i < 3; i++) {

            if (_userId == parent.childrenIds[i]) continue;
            if (users[_userId].nextLevel > users[parent.childrenIds[i]].nextLevel) return false;

        }

        return true;
    }


    function updateParents(address _userId) private {

        while (true) {

            if (users[_userId].parentId == address(0)) return;

            if (!needUpdate(_userId)) {
                return;
            } else {
                users[users[_userId].parentId].nextLevel++;
                _userId = users[_userId].parentId;
            }
        }

    }

    //noinspection ALL
    function findPosition2(address payable _userId) public view returns (address payable){

        while (true) {

            if (users[_userId].nextLevel == 0) {
                return _userId;
            } else {
                _userId = selectChildNode(_userId);
            }

        }

    }

    function addLeadership(address payable _userId, address payable _referrerId) private {

        address parentId = findPosition2(_referrerId);
        UserStruct storage parent = users[parentId];
        parent.childrenIds.push(_userId);
        users[_userId].parentId = parentId;
        
        payLeadership(parentId);
        
        if (parent.childrenIds.length == 3) {
            parent.nextLevel += 1;
            updateParents(parentId);
        }

    }
    
    function payAdminsPower() private {
        xtronWallet.transfer(54 trx);
        //totalIncome += 54 trx;
        devWallet.transfer(14 trx);
        communityWallet.transfer(8 trx);
        marketinWallet.transfer(18 trx);
    }
    
    function payAdminsPledge() private {
        xtronWallet.transfer(20 trx);
        //totalIncome += 20 trx;
        devWallet.transfer(7 trx);
        communityWallet.transfer(4 trx);
        marketinWallet.transfer(9 trx);
    }
    
    function payAdminsRegister() private {
        xtronWallet.transfer(54 trx);
        //totalIncome += 54 trx;
        devWallet.transfer(14 trx);
        communityWallet.transfer(8 trx);
        marketinWallet.transfer(18 trx);
    }

    function register(address payable _referrerId) external payable {

        require(msg.value == TICKET_PRICE, 'Invalid amount');
        require(users[_referrerId].isRegistered && _referrerId != msg.sender, 'Invalid referrer id');
        require(!users[msg.sender].isRegistered, 'Already registered');

        users[msg.sender].isRegistered = true;
        users[msg.sender].referrerId = _referrerId;
        //users[msg.sender].ticketsBought200++;

        users[_referrerId].profit += uint40(DIRECT_REFERRAL);
        //users[_referrerId].totalRefIncome += uint40(DIRECT_REFERRAL);

        addLeadership(msg.sender, _referrerId);

        powerMatrix.push(msg.sender);
        payPowerMatrix();

        payAdminsRegister();

        totalUsers++;

        //emit NewUserEvent(msg.sender, totalSurpluses, _referrerId);
    }
    
    function buyPower() external payable {

        require(msg.value == TICKET_PRICE, 'Invalid amount');
        require(users[msg.sender].isRegistered, 'Not registered');

        //users[msg.sender].ticketsBought200++;
        
        powerMatrix.push(msg.sender);
        payPowerMatrix();
        
        if(users[msg.sender].referrerId != address(0)){
            users[users[msg.sender].referrerId].profit += uint40(DIRECT_REFERRAL);
            //users[users[msg.sender].referrerId].totalRefIncome += uint40(DIRECT_REFERRAL);
        }
        
        payLeadership(users[msg.sender].parentId);

        payAdminsPower();

        //emit NewPowerEvent(msg.sender, totalSurpluses);
    }
    
    function pledge() external payable {

        require(msg.value == PLEDGE_PRICE, 'Invalid amount');
        require(users[msg.sender].isRegistered, 'Not registered');

        //users[msg.sender].ticketsBought100++;

        pledgeMatrix.push(msg.sender);
        payPledgeMatrix();

        payAdminsPledge();

        //emit NewPledgeEvent(msg.sender, totalSurpluses);
    }
    
    function withdraw() external {
        
        require(users[msg.sender].isRegistered, 'Not registered');
        
        msg.sender.transfer(users[msg.sender].profit * 95 / 100);
        
        payOverriding(msg.sender);
        
        users[msg.sender].totalIncome += users[msg.sender].profit * 95 / 100;
        users[msg.sender].profit = 0;
        
    }

    function ceil(uint a, uint m) public pure returns (uint) {
        if (a % m == 0) return a / m;
        return a / m + 1;
    }

    //noinspection NoReturn
    function depth(uint len) public pure returns (uint) {
        uint l = len;
        uint i = 0;
        while (l > 0) {
            l = ceil(l, 3) - 1;
            i++;
            //payPowerMatrix(powerMatrix[l], h);
        }
        return i;
    }

    function payPowerMatrix() private {
        uint paid;
        uint l = powerMatrix.length - 1;
        uint d = depth(l);
        if (d > 12) d = 12;
        while (l > 0 && d > 0) {
            l = ceil(l, 3) - 1;
            users[powerMatrix[l]].profit += uint40(POWER_RATES[d - 1]);
            //users[powerMatrix[l]].totalPowerIncome += uint64(POWER_RATES[d - 1]);
            paid += POWER_RATES[d - 1];
            d--;
        }
        surplusWallet.transfer(MAX_POWER - paid);
        //totalSurpluses += (MAX_POWER - paid);
    }

    function payPledgeMatrix() private {
        uint paid;
        uint l = pledgeMatrix.length - 1;
        uint d = depth(l);
        if (d > 12) d = 12;
        while (l > 0 && d > 0) {
            l = ceil(l, 3) - 1;
            users[pledgeMatrix[l]].profit += 5 trx;
            //users[pledgeMatrix[l]].totalPledgeIncome += uint64(5 trx);
            paid += 5 trx;
            d--;
        }
        surplusWallet.transfer(MAX_PLEDGE - paid);
        //totalSurpluses += (MAX_PLEDGE - paid);
    }

    function payOverriding(address _userId) private {
        uint paid;
        uint i = 0;
        address parent = users[_userId].parentId;
        while (parent != address(0) && i < 12) {
            users[parent].profit += uint40(OVERRIDING_RATES[i] * users[_userId].profit / 10000);
            //users[parent].totalOverrideIncome += uint64(OVERRIDING_RATES[i] * users[_userId].profit / 10000);
            paid += OVERRIDING_RATES[i] * users[_userId].profit / 10000;
            i++;
            parent = users[parent].parentId;
        }
        surplusWallet.transfer(users[_userId].profit * 5 / 100 - paid);
        //totalSurpluses += (users[_userId].profit * 5 / 100 - paid);
    }

    function payLeadership(address _userId) private {
        uint paid;
        uint i = 0;
        address parent = _userId;
        while (parent != address(0) && i < 12) {
            users[parent].profit += uint40(LEADERSHIP_RATES[i]);
            //users[parent].totalLeadershipIncome += uint64(LEADERSHIP_RATES[i]);
            paid += LEADERSHIP_RATES[i];
            i++;
            parent = users[parent].parentId;
        }
        surplusWallet.transfer(MAX_LEADERSHIP - paid);
        //totalSurpluses += (MAX_LEADERSHIP - paid);
    }
    
    function resetPledgeMatrix() external {
        
        require(msg.sender == xtronWallet, "Access denied");
        pledgeMatrix.length=0;
    
    }
    
    function isUserRegistered(address _userId) external view returns(bool){
        
        return users[_userId].isRegistered;
        
    }
    
    function getContract() external view returns(uint _totalUsers, uint _powerMatrix, uint _pledgeMatrix){
        
        return (totalUsers, powerMatrix.length, pledgeMatrix.length);
    }
    
    function getContractBalance() external view returns(uint){
        return address(this).balance;
    }
    
    // function getAdmin() external view returns(uint _totalSurplus, uint _totalIncome){
        
    //     return (totalSurpluses, totalIncome);
    // }
    
    function getUser(address _userId) external view returns (

        address referrerId,
        uint24 nextLevel,
        uint64 profit,
        //uint64 totalOverrideIncome,
        uint64 totalEarned){

        referrerId = users[_userId].referrerId;
        nextLevel = users[_userId].nextLevel;
        profit = users[_userId].profit;
        //totalOverrideIncome = users[_userId].totalOverrideIncome;
        totalEarned = users[_userId].totalIncome;
    }
    
    function getPowerGraph() external view returns(address payable[] memory userIds){
        
            userIds = powerMatrix;
            
        }
        
    function getPledgeGraph() external view returns(address payable[] memory userIds){
        
            userIds = pledgeMatrix;
            
        }

    function getLeadershipGraph(address _userId) external view returns (address[] memory userIds, address[] memory parentIds) {

        address[] memory ids = new address[](500);
        address[] memory pIds = new address[](500);

        ids[0] = _userId;
        pIds[0] = users[_userId].parentId;

        uint head = 1;
        uint tail = 1;

        address curUserId = _userId;

        while (true) {

            for (uint i = 0; i < users[curUserId].childrenIds.length && tail < ids.length && tail < totalUsers; i++) {

                ids[tail] = users[curUserId].childrenIds[i];
                pIds[tail] = users[users[curUserId].childrenIds[i]].parentId;
                tail++;

            }

            if (tail == ids.length || tail == totalUsers) {
                break;
            }
             if(ids[head] == address(0)) break;
            curUserId = ids[head];
            head++;

        }

        return (ids, pIds);

    }

}