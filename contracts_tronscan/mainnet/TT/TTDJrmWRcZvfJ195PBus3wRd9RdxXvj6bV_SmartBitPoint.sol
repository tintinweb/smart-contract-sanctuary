//SourceUnit: SmartBitPoint.sol

/*
╔═══╗╔═╗╔═╗╔═══╗╔═══╗╔════╗╔══╗─╔══╗╔════╗╔═══╗╔═══╗╔══╗╔═╗─╔╗╔════╗
║╔═╗║║║╚╝║║║╔═╗║║╔═╗║║╔╗╔╗║║╔╗║─╚╣─╝║╔╗╔╗║║╔═╗║║╔═╗║╚╣─╝║║╚╗║║║╔╗╔╗║
║╚══╗║╔╗╔╗║║║─║║║╚═╝║╚╝║║╚╝║╚╝╚╗─║║─╚╝║║╚╝║╚═╝║║║─║║─║║─║╔╗╚╝║╚╝║║╚╝
╚══╗║║║║║║║║╚═╝║║╔╗╔╝──║║──║╔═╗║─║║───║║──║╔══╝║║─║║─║║─║║╚╗║║──║║──
║╚═╝║║║║║║║║╔═╗║║║║╚╗──║║──║╚═╝║╔╣─╗──║║──║║───║╚═╝║╔╣─╗║║─║║║──║║──
╚═══╝╚╝╚╝╚╝╚╝─╚╝╚╝╚═╝──╚╝──╚═══╝╚══╝──╚╝──╚╝───╚═══╝╚══╝╚╝─╚═╝──╚╝──
international telegram channel: @smartbitpoint
international telegram group: @smartbitpoint_com
international telegram bot: @smartbitpoint_bot
hashtag: #smartbitpoint
*/
pragma solidity 0.5.12;

contract SmartBitPoint {
    uint public currUserID = 1;
    address public lastUser;
    address public owner;
    uint public START_PRICE = 300 trx;
    mapping (uint => uint) public StatsLevel;
    struct User {
        uint id;
        uint currentLevel;
        bool unlimited;
        uint referrerB;
        uint referrerT;
        uint referrerL;
        address[] referralsB;
        address[] referralsT;
        address[] referralsL;
        mapping (uint => uint) countGetMoney;
        mapping (uint => uint) countLostMoney;
    }
    mapping (address => User) public mapusers;
    mapping (uint => address) public usersAddress;
    bool private ContractInit;

    event regLevelEvent(address indexed _user, address indexed _referrer, uint indexed _type, uint _id, uint _time);
    event buyLevelEvent(address indexed _user, uint indexed _level, uint _time);
    event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint indexed _level, uint _time);
    event lostMoneyForLevelEvent(address indexed _user, address indexed _referral, uint indexed _level, uint _time);

    modifier onlyOwner { require(msg.sender == owner, "Access only owner"); _; }
    modifier userRegistered(address _user) { require(mapusers[_user].id != 0, 'User not exist'); _; }
    modifier validPrice(uint _price) { require(_price > 0 && _price % 3 == 0, 'Invalid price'); _; }
    modifier validAddress(address _user) { require(_user != address(0), "Zero address"); _; }

    constructor() public {
        require(!ContractInit,"This contract inited");
        owner = msg.sender;
        lastUser = owner;
        mapusers[owner] = User({ id: 1, currentLevel: 120, unlimited: true, referrerB: 0, referrerT: 0, referrerL: 0, referralsB: new address[](0), referralsT: new address[](0), referralsL: new address[](0) });
        usersAddress[1] = owner;
        ContractInit = true;
    }

    function () external payable {
        revert("Invalid Transaction");
    }

    function regUser(address _referrer) external payable returns(string memory){
        regUserPrivate(msg.sender, _referrer);
        return "SignUp is completed";
    }

    function regUserManual(address _user, address _referrer) external payable returns(string memory){
        regUserPrivate(_user, _referrer);
        return "SignUp is completed";
    }

    function regUserPrivate(address _user, address _referrer) private {
        require(msg.value == START_PRICE, 'Invalid sum');
        require(_user.isContract == false, "Contracts are not supported");
        require(mapusers[_referrer].id != 0, "Incorrect referrer");
        require(mapusers[_user].id == 0, "User exist");
        uint bone = mapusers[_referrer].id;
        uint two = bone;
        if(mapusers[_referrer].referralsB.length >= 2)
            bone = mapusers[findFreeReferrerB(_referrer)].id;
        if(mapusers[_referrer].referralsT.length >= 3)
            two = mapusers[findFreeReferrerT(_referrer)].id;
        currUserID++;
        mapusers[_user] = User({ id: currUserID, currentLevel: 1, unlimited: false, referrerB: bone, referrerT: two, referrerL: mapusers[_referrer].id, referralsB: new address[](0), referralsT: new address[](0), referralsL: new address[](0) });
        usersAddress[currUserID] = _user;
        address _referrerB = usersAddress[bone];
        address _referrerT = usersAddress[two];
        mapusers[_referrerB].referralsB.push(_user);
        mapusers[_referrerT].referralsT.push(_user);
        mapusers[_referrer].referralsL.push(_user);
        StatsLevel[1]++;
        payForLevel(_referrerB,_user,1);
        payForLevel(_referrerT,_user,1);
        payForLevel(_referrer,_user,1);
        lastUser = _user;
        emit regLevelEvent(_user, _referrerB, 1, currUserID, now);
        emit regLevelEvent(_user, _referrerT, 2, currUserID, now);
        emit regLevelEvent(_user, _referrer, 3, currUserID, now);
    }

    function buyLevel() external payable returns(string memory){
        buyLevelPrivate(msg.sender);
        return "Level successfully activated";
    }

    function buyLevelManual(address _user) external payable returns(string memory){
        buyLevelPrivate(_user);
        return "Level successfully activated";
    }

    function buyLevelPrivate(address _user) private {
        require(msg.value != START_PRICE, 'Invalid sum');
        uint level;
        if(msg.value % 3 == 0){
            level = msg.value/START_PRICE;
        }
        require(level > 0, 'Invalid sum');
        require(mapusers[_user].id != 0, "Buy first level");
        require(mapusers[_user].unlimited == false, 'You have unlimited levels');
        if(mapusers[_user].currentLevel >= level) revert('Level is already activated');
        if(mapusers[_user].currentLevel+1 != level) revert('Buy previous level');
        mapusers[_user].currentLevel = level;
        StatsLevel[level]++;
        payForLevel(findFreeReferralB(_user,level),_user,level);
        payForLevel(findFreeReferralT(_user,level),_user,level);
        payForLevel(findFreeReferralL(_user,level),_user,level);
        emit buyLevelEvent(_user, level, now);
    }

    function payForLevel(address _referrer, address _user, uint _level) private {
        if(address(uint160(_referrer)).send(msg.value/3)) {
            emit getMoneyForLevelEvent(_referrer, _user, _level, now);
            mapusers[_referrer].countGetMoney[_level]++;
        }
    }

    function findFreeReferrerB(address _user) public view returns(address) {
        if(mapusers[_user].referralsB.length < 2) return _user;
        address[] memory referrals = new address[](254);
        referrals[0] = mapusers[_user].referralsB[0];
        referrals[1] = mapusers[_user].referralsB[1];
        for(uint i=0; i<254;i++){
            if(mapusers[referrals[i]].referralsB.length < 2) return referrals[i];
            if(i > 125) continue;
            referrals[(i + 1) * 2] = mapusers[referrals[i]].referralsB[0];
            referrals[(i + 1) * 2 + 1] = mapusers[referrals[i]].referralsB[1];
        }
        return lastUser;
    }
    function findFreeReferrerT(address _user) public view returns(address) {
        if(mapusers[_user].referralsT.length < 3) return _user;
        address[] memory referrals = new address[](363);
        referrals[0] = mapusers[_user].referralsT[0];
        referrals[1] = mapusers[_user].referralsT[1];
        referrals[2] = mapusers[_user].referralsT[2];
        for(uint i=0; i<363;i++){
            if(mapusers[referrals[i]].referralsT.length < 3) return referrals[i];
            if(i > 119) continue;
            referrals[(i + 1) * 3] = mapusers[referrals[i]].referralsT[0];
            referrals[(i + 1) * 3 + 1] = mapusers[referrals[i]].referralsT[1];
            referrals[(i + 1) * 3 + 2] = mapusers[referrals[i]].referralsT[2];
        }
        return lastUser;
    }

    function findFreeReferralB(address _user, uint _level) private returns(address) {
        uint height = _level;
        address referrer = usersAddress[mapusers[_user].referrerB];
        while (referrer != address(0)) {
            height--;
            if(height == 0){
                if(mapusers[referrer].currentLevel >= _level || mapusers[referrer].unlimited) return referrer;
                emit lostMoneyForLevelEvent(referrer, _user, _level, now);
                mapusers[referrer].countLostMoney[_level]++;
                height = _level;
            }
            referrer = usersAddress[mapusers[referrer].referrerB];
        }
        return owner;
    }
    function findFreeReferralT(address _user, uint _level) private returns(address) {
        uint height = _level;
        address referrer = usersAddress[mapusers[_user].referrerT];
        while (referrer != address(0)) {
            height--;
            if(height == 0){
                if(mapusers[referrer].currentLevel >= _level || mapusers[referrer].unlimited) return referrer;
                emit lostMoneyForLevelEvent(referrer, _user, _level, now);
                mapusers[referrer].countLostMoney[_level]++;
                height = _level;
            }
            referrer = usersAddress[mapusers[referrer].referrerT];
        }
        return owner;
    }
    function findFreeReferralL(address _user, uint _level) private returns(address) {
        address referrer = usersAddress[mapusers[_user].referrerL];
        while (referrer != address(0)) {
            if(mapusers[referrer].currentLevel >= _level || mapusers[referrer].unlimited) return referrer;
            emit lostMoneyForLevelEvent(referrer, _user, _level, now);
            mapusers[referrer].countLostMoney[_level]++;
            referrer = usersAddress[mapusers[referrer].referrerL];
        }
        return owner;
    }

    function viewUserReferralsB(address _user) external view returns(address[] memory) {
        return mapusers[_user].referralsB;
    }
    function viewUserReferralsT(address _user) external view returns(address[] memory) {
        return mapusers[_user].referralsT;
    }
    function viewUserReferralsL(address _user) external view returns(address[] memory) {
        return mapusers[_user].referralsL;
    }

    function getCountGetMoney(address _user, uint _level) external view returns(uint) {
        return mapusers[_user].countGetMoney[_level];
    }
    function getCountLostMoney(address _user, uint _level) external view returns(uint) {
        return mapusers[_user].countLostMoney[_level];
    }

    function getUserInfo(address _user) external view returns(uint,uint,bool,uint[3] memory,address[3] memory){
        return (mapusers[_user].id,mapusers[_user].currentLevel,mapusers[_user].unlimited,
        [mapusers[_user].referrerB,mapusers[_user].referrerT,mapusers[_user].referrerL],
        [usersAddress[mapusers[_user].referrerB], usersAddress[mapusers[_user].referrerT],usersAddress[mapusers[_user].referrerL]]);
    }

    function setUserLevel(address _user,uint _level) external onlyOwner userRegistered(_user) {
        mapusers[_user].currentLevel = _level;
    }
    function setStartPrice(uint _price) external onlyOwner validPrice(_price) {
        START_PRICE = _price * 0.001 trx;
    }
    function setUserUnlimited(address _user) external onlyOwner userRegistered(_user) {
        mapusers[_user].unlimited = true;
    }
    function delUserUnlimited(address _user) external onlyOwner userRegistered(_user) {
        mapusers[_user].unlimited = false;
    }

    function setOwner(address _user) external onlyOwner validAddress(_user) userRegistered(_user) { owner = _user; }
    function surPlus() external onlyOwner { address(uint160(owner)).transfer(address(this).balance); }
}