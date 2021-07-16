//SourceUnit: pv.sol


pragma solidity ^0.5.4;


contract PV {

    address owner;
    bool initialized = false;
    uint priceVault = 4200 * (10 ** 6);
    uint public numberSecuence = 0;
    uint public vaultsCompleted = 0;
    uint public totalRounds = 5;
    uint public CountLevels = 30;

    struct ConfigsStruct {
        address developer;
        address dev_1;
        address fund;
        uint lastUser;
        uint earnings;
        uint earningsVault;
    }

    struct UserStruct {
        bool isExist;
        bool pay;
        uint id;
        uint referrerID;
        uint referredUsers;
        uint buys;
        uint earnings;
        uint profit;
        uint repurchase;
        uint rounds;
        uint finish;
        bool grace;
    }

    struct UserVaultStruct {
        bool isExist;
        uint idVault;
        uint total;
    }

    struct VaultUserStruct {
        bool isExist;
        bool pay;
        address user;
        uint sequence;
        uint payment_received;
    }

    mapping (uint => ConfigsStruct) public configs;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    mapping (uint => mapping (uint => address)) public userChild;
    mapping (address => UserVaultStruct) public usersVault;
    mapping (uint => VaultUserStruct) public vaultsUsers;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner == msg.sender, "Only the owner");
        _;
    }

    function setAddrFund(address _addr) external onlyOwner {
        configs[0].fund = _addr;
    }

    function setAddrDeveloper(address _addr) external onlyOwner {
        configs[0].developer = _addr;
    }

    function changePrice(uint _price) external onlyOwner {
        priceVault = _price;
    }

    function init(address _developer, address _dev_1, address _fund) external onlyOwner {
        require(initialized == false, "Error, the contract has already been initialized");
        ConfigsStruct memory configs_struct;
        configs_struct = ConfigsStruct({
            developer: _developer,
            dev_1: _dev_1,
            fund: _fund,
            lastUser: 0,
            earnings: 0,
            earningsVault: 0
        });
        configs[0] = configs_struct;
        createUser(0, _dev_1);
        createVault(_dev_1, 0, true);
        initialized = true;
    }

    function createUser(uint _sponsorID, address _user) private {
        configs[0].lastUser++;
        UserStruct memory userStruct;
        userStruct = UserStruct({
            isExist: true,
            pay: true,
            id: configs[0].lastUser,
            referrerID: _sponsorID,
            referredUsers: 0,
            buys: 1,
            earnings: 0,
            profit: 0,
            repurchase: 0,
            rounds: 0,
            finish: now + 60 days,
            grace: false
        });
        users[_user] = userStruct;
        userList[configs[0].lastUser] = _user;
        users[userList[_sponsorID]].referredUsers++;
        userChild[_sponsorID][users[userList[_sponsorID]].referredUsers] = _user;
    }

    function sendEarning(address _addr_, uint _earning_, uint _action) private {
        if(now <= users[_addr_].finish){
            uint totalEarning = 0;
            uint earningSendETH = 0;
            uint restEarning = 0;
            if(_action == 1){
                totalEarning = users[_addr_].repurchase + _earning_;
                if(totalEarning > priceVault){
                    earningSendETH = totalEarning - priceVault;
                    users[_addr_].earnings += earningSendETH;
                    users[_addr_].profit += earningSendETH;
                    users[_addr_].repurchase += _earning_ - earningSendETH;
                    restEarning = earningSendETH;
                } else {
                    users[_addr_].repurchase += _earning_;
                }
                if(users[_addr_].repurchase >= priceVault){
                    users[_addr_].pay = true;
                    users[_addr_].profit = restEarning;
                    users[_addr_].repurchase = 0;
                    users[_addr_].buys += 1;
                    users[_addr_].rounds++;
                    if(users[_addr_].rounds >= totalRounds){
                        if(users[_addr_].grace == false){
                            users[_addr_].pay = false;
                            users[_addr_].finish = now + 3 days;
                            users[_addr_].grace = true;
                        }
                    }
                }
                if(earningSendETH > 0){
                    sendEth(_addr_, earningSendETH);
                }
            } else {
                totalEarning = users[_addr_].profit + _earning_;
                if(totalEarning > (priceVault*1)){
                    earningSendETH = priceVault - users[_addr_].profit;
                    users[_addr_].earnings += earningSendETH;
                    users[_addr_].profit += earningSendETH;
                    restEarning = _earning_ - earningSendETH;
                } else {
                    earningSendETH = _earning_;
                    users[_addr_].earnings += _earning_;
                    users[_addr_].profit += _earning_;
                }
                if(users[_addr_].profit >= (priceVault*1)){
                    users[_addr_].pay = false;
                    users[_addr_].repurchase = restEarning;
                }
                if(earningSendETH > 0){
                    sendEth(_addr_, earningSendETH);
                }
            }
        }
    }

    function setCountLevels(uint x) external onlyOwner {
        CountLevels = x;
    }

    function searchUserActive(address _addr, uint _now, uint _count) public view returns (address) {
        _addr = userList[users[_addr].referrerID];
        if(users[_addr].isExist && _count < CountLevels){
            if(_now <= users[_addr].finish){
                if(users[_addr].pay){
                    return _addr;
                } else {
                    _addr = searchUserActive(_addr, _now, (_count+1));
                }
            } else {
                _addr = searchUserActive(_addr, _now, (_count+1));
            }
            return _addr;
        } else {
            return address(0);
        }
    }

    function searchUserActiveNetwork(address _addr, uint _now, uint _count) public view returns (address) {
        _addr = userList[users[_addr].referrerID];
        if(users[_addr].isExist && _count < CountLevels){
            if(getReferrerActives(_addr, _now) >= 3){
                if(_now <= users[_addr].finish){
                    if(users[_addr].pay){
                        return _addr;
                    } else {
                        _addr = searchUserActiveNetwork(_addr, _now, (_count+1));
                    }
                } else {
                    _addr = searchUserActiveNetwork(_addr, _now, (_count+1));
                }
            } else {
                _addr = searchUserActiveNetwork(_addr, _now, (_count+1));
            }
            return _addr;
        } else {
            return address(0);
        }
    }

    function sendPaymentsNetwork(uint _sponsorID, uint _now) private {
        address referrerLevel = address(0);
        uint percentageSponsor = 35;
        address _addr_ = userList[_sponsorID];
        uint _earning_ = (priceVault * percentageSponsor / 100);
        if(_now <= users[_addr_].finish){
            if(users[_addr_].pay == false){
                sendEarning(_addr_, _earning_, 1);
                _addr_ = searchUserActive(_addr_, _now, 0);
            }
        } else {
            _addr_ = searchUserActive(_addr_, _now, 0);
        }
        if(_addr_ != address(0)){
            sendEarning(_addr_, _earning_, 0);
        }
        referrerLevel = getUserReferrerLast(userList[_sponsorID]);
        for(uint i = 1; i<=6; i++){
            if(referrerLevel != address(0)){
                if(i == 1){percentageSponsor = 6;}
                else if(i == 2){percentageSponsor = 7;}
                else if(i == 3){percentageSponsor = 8;}
                else if(i == 4){percentageSponsor = 9;}
                else if(i == 5){percentageSponsor = 10;}
                else if(i == 6){percentageSponsor = 11;}
                _earning_ = msg.value * percentageSponsor / 100;
                address referrerAddress = referrerLevel;
                if(getReferrerActives(referrerAddress, _now) < 3){
                    referrerAddress = searchUserActiveNetwork(referrerAddress, _now, 0);
                }
                if(_now <= users[referrerAddress].finish){
                    if(users[referrerAddress].pay == false){
                        sendEarning(referrerAddress, _earning_, 1);
                        referrerAddress = searchUserActiveNetwork(referrerAddress, _now, 0);
                    }
                } else {
                    referrerAddress = searchUserActiveNetwork(referrerAddress, _now, 0);
                }
                if(referrerAddress != address(0)){
                    sendEarning(referrerAddress, _earning_, 0);
                }
                referrerLevel = getUserReferrerLast(referrerLevel);
            } else {
                break;
            }
        }
    }

    function buyPackage(address referrer) external payable {
        require(users[referrer].isExist, "Sponsor not Exists");
        NewUser(users[referrer].id, msg.sender);
    }

    function Repurchase() external payable {
        require(users[msg.sender].isExist, "User not Exists");
        require(users[msg.sender].rounds >= 5, "User not inactive");
        users[msg.sender].pay = true;
        users[msg.sender].rounds = 0;
        users[msg.sender].finish = now + 60 days;
        users[msg.sender].profit = 0;
        users[msg.sender].repurchase = 0;
        users[msg.sender].grace = false;
        configs[0].earnings += priceVault;
        sendBalanceDeveloper();
        sendPaymentsNetwork(users[msg.sender].referrerID, now);
        sendBalanceFund();
    }

    function PayAnotherAccount(uint _sponsorID, address _user) external payable {
        require(users[msg.sender].isExist, "User Payment not Exists");
        NewUser(_sponsorID, _user);
    }

    function NewUser(uint _sponsorID, address _user) private {
        require(!users[_user].isExist, "User Exists");
        require(users[userList[_sponsorID]].isExist, "Sponsor not Exists");
        require(msg.value == priceVault, 'Incorrect Value');
        configs[0].earnings += priceVault;
        createUser(_sponsorID, _user);
        sendBalanceDeveloper();
        sendPaymentsNetwork(_sponsorID, now);
        sendBalanceFund();
        emit eventNewUser(_user, userList[_sponsorID], now);
    }

    function createVault(address _user, uint _payment, bool _check) private {
        if(_check == true){
            UserVaultStruct memory user_vault_struct;
            user_vault_struct = UserVaultStruct({
                isExist: true,
                idVault: numberSecuence,
                total: 1
            });
            usersVault[_user] = user_vault_struct;
        } else {
            usersVault[_user].idVault = numberSecuence;
            usersVault[_user].total++;
        }
        VaultUserStruct memory vault_user_struct;
        vault_user_struct = VaultUserStruct({
            isExist: true,
            pay: true,
            user: _user,
            sequence: numberSecuence,
            payment_received: _payment
        });
        vaultsUsers[numberSecuence] = vault_user_struct;
        numberSecuence++;
    }

    function buyVault(address _user) external payable {
        require(users[_user].isExist, "User not Exists");
        require(!usersVault[_user].isExist, "User Exists");
        require(msg.value == priceVault, 'Incorrect Value');
        require(getReferrerActives(_user, now) >= 3, "You need 3 direct users actives");
        configs[0].earningsVault += priceVault;
        createVault(_user, 0, true);
        sendBalanceDeveloper();
        sendVaults();
        sendBalanceFund();
        emit eventBuyVault(_user, now);
    }

    function sendVaults() private {
        uint totalVault = vaultsCompleted;
        for(uint i = totalVault; i < (totalVault+3); i++){
            if(vaultsUsers[i].pay == true && vaultsUsers[i].payment_received < 3){
                sendPaymentVault(i);
            }
        }
    }

    function sendPaymentVault(uint i) private {
        uint _amount = msg.value * 30 / 100;
        sendEth(vaultsUsers[i].user, _amount);
        vaultsUsers[i].payment_received++;
        if(vaultsUsers[i].payment_received >= 3){
            vaultsUsers[i].pay = false;
            vaultsCompleted++;
            createVault(vaultsUsers[i].user, 0, false);
        }
    }

    function sendEth(address _user, uint _amount) private {
        if( _amount > 0 ){
            address(uint160(_user)).transfer(_amount);
        }
    }

    function sendBalanceDeveloper() private {
        if(address(this).balance > 0){
            uint _amount = address(this).balance * 10 / 100;
            address(uint160(configs[0].developer)).transfer(_amount);
        }
    }

    function sendBalanceFund() private {
        if(address(this).balance > 0){
            address(uint160(configs[0].fund)).transfer(address(this).balance);
        }
    }

    function getUserReferrerLast(address _user) public view returns (address) {
        if( users[_user].referrerID != 0 ){
            return userList[users[_user].referrerID];
        } else {
            return address(0);
        }
    }

    function getReferrerActives(address _user, uint _now) public view returns (uint) {
        if( users[_user].referredUsers < 3 ){
            return users[_user].referredUsers;
        } else {
            uint total = 0;
            for(uint i = 1; i<=users[_user].referredUsers; i++){
                if(_now <= users[_user].finish){
                    total++;
                    if(total >= 3){
                        break;
                    }
                }
            }
            return total;
        }
    }

    function getUserStatusReferrers(address _user, uint _now) public view returns (bool) {
        uint t_r = getReferrerActives(_user, _now);
        if(t_r >= 3){
            if(_now <= users[_user].finish){
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    event eventNewUser(address _user, address indexed _sponsor, uint indexed _time);
    event eventBuyVault(address indexed _user, uint indexed _time);

}