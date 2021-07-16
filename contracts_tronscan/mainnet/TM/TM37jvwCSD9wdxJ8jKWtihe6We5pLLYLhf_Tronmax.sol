//SourceUnit: Tronmax.sol

pragma solidity 0.5.14;
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Tronmax{
    using SafeMath for uint256;

        struct UserStruct{
        bool isExist;
        uint id;
        uint investID;
        uint referer;
        uint totalEarnings;
        address[] referals;
        uint lastwithdrawtime;
        mapping(uint => investDetails) Investment;
        mapping(uint => uint) autoinvestCount;
    }

    struct investDetails{
        uint package;
        uint deposittime;
        uint depositamount;
        uint ROIEarned;
        uint HoldEarned;
        uint totalInvestEarned;
        uint reinvestcount;
        uint reinvestamount;
        uint contractBonus;
        uint roicalc;
        uint lastWithdrawal;
        bool withdrawlstatus;
    }

    struct packageStruct{
        uint min;
        uint max;
        uint ROI;
        uint stakeDays;
    }

    struct bonusStruct{
        uint totaldeposit;
        uint reachamt;
    }

    uint public totaldeposit;
    address public owner;
    uint public curruserid = 1;
    bool public lockStatus;
    uint public withdrawcalc = 1 days;
    uint public holdingcalc = 43200;

    event levelBonusEvent(address indexed _user, address indexed _referral, uint256 _value, uint _time, uint uplinecount);
    event investEvent(uint _package, address indexed _from, address indexed _to, uint _investID, uint currentId, uint _investamount, uint _time);
    event WithdrawalEvent(uint _package, address indexed _from, uint _investID, uint _amount, uint _time);
    event AutoInvestEvent(address _user, uint _reinvestID, uint _package, uint _investID, uint _amount, uint _time);
    event ContractBonusEvent(uint _package, uint _time, uint bonus);
    event referenceWithdraw(address indexed _from, uint value, uint time);
    event holdingBonus(address indexed _from, uint value, uint time);
    event contractBonusWithdraw(address indexed _from, uint value, uint time);

    mapping(uint => bonusStruct)public bonuspay;
    mapping(address => UserStruct)public users;
    mapping(uint => address)public userlist;
    mapping(uint => uint)public levelBonus;
    mapping(uint => packageStruct)public package;
    mapping(uint => uint[]) public contractBonusTimeStamp;
    mapping(uint => mapping(uint => uint)) public contractBonusIndex;
    mapping(uint => uint) public contractBonusPercent;
    mapping(uint => uint) public packageLimitReached;
    mapping(address => uint)public refAmount;

    constructor(address owneraddres)public{
        owner = owneraddres;

        UserStruct memory userstruct;
        userstruct = UserStruct({
            isExist: true,
            id: curruserid,
            investID: 0,
            referer: 0,
            totalEarnings: 0,
            referals: new address[](0),
            lastwithdrawtime: block.timestamp
        });

        users[owner] = userstruct;
        userlist[1] = owner;

        packageStruct memory packagestruct;

        packagestruct = packageStruct({
            min: 100 trx,
            max: 10000 trx,
            ROI: 5 trx,
            stakeDays: 30 days
        });

        package[1] = packagestruct;

        packagestruct = packageStruct({
            min: 11000 trx,
            max: 100000 trx,
            ROI: 7.5 trx,
            stakeDays: 20 days
        });


        package[2] = packagestruct;

        packagestruct = packageStruct({
            min: 101000 trx,
            max: 1000000 trx,
            ROI: 10 trx,
            stakeDays: 15 days
        });

        package[3] = packagestruct;

        packagestruct = packageStruct({
            min: 1100000 trx,
            max: 100000000 trx,
            ROI: 15 trx,
            stakeDays: 10 days
        });

        package[4] = packagestruct;

        bonusStruct memory bonusstruct;

        bonusstruct = bonusStruct({
            totaldeposit: 0,
            reachamt: 1000000 trx
        });
        bonuspay[1] = bonusstruct;

        bonusstruct = bonusStruct({
            totaldeposit: 0,
            reachamt: 10000000 trx
        });
        bonuspay[2] = bonusstruct;

        bonusstruct = bonusStruct({
            totaldeposit: 0,
            reachamt: 100000000 trx
        });
        bonuspay[3] = bonusstruct;

        bonusstruct = bonusStruct({
            totaldeposit: 0,
            reachamt: 1000000000  trx
        });
        bonuspay[4] = bonusstruct;

        levelBonus[1] = 5 trx;
        levelBonus[2] = 3 trx;
        levelBonus[3] = 2 trx;
        levelBonus[4] = 1 trx;
        levelBonus[5] = 0.5 trx;

        contractBonusPercent[1] = 0.5 trx;
        contractBonusPercent[2] = 1 trx;
        contractBonusPercent[3] = 1.5 trx;
        contractBonusPercent[4] = 2 trx;

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier isLock() {
        require(lockStatus == false, "Contract Locked");
        _;
    }
    modifier isPackage(uint _package) {
        require((_package > 0) && (_package < 5), "invalid package ID");
        _;
    }

    modifier isContractcheck(address user) {
        require(!isContract(user), "Invalid address");
        _;
    }

    function invest(uint _package, uint _refid)public isLock isPackage(_package) isContractcheck(msg.sender) payable{
        require((msg.value >= package[_package].min) && (msg.value <= package[_package].max), "Invalid Price");
        if (users[msg.sender].isExist == false) { // user registration
            require((_refid > 0) && (_refid <= curruserid), "wrong id");

            curruserid++;

            UserStruct memory userstruct;
            userstruct = UserStruct({
                isExist: true,
                id: curruserid,
                investID: 0,
                referer: _refid,
                totalEarnings: 0,
                referals: new address[](0),
                lastwithdrawtime: block.timestamp
            });

            users[msg.sender] = userstruct;
            userlist[curruserid] = msg.sender;

            users[userlist[_refid]].referals.push(msg.sender);

            referralpaylevel(userlist[users[msg.sender].referer], msg.value, 1);
        }

        users[msg.sender].investID++; // Investment increment
        users[msg.sender].Investment[users[msg.sender].investID].package = _package; // package ID
        users[msg.sender].Investment[users[msg.sender].investID].depositamount = msg.value; // deposit amount
        users[msg.sender].Investment[users[msg.sender].investID].deposittime = block.timestamp; // deposit time
        users[msg.sender].Investment[users[msg.sender].investID].lastWithdrawal = block.timestamp;
        users[msg.sender].Investment[users[msg.sender].investID].withdrawlstatus = false; // withdrawal status
        totaldeposit = totaldeposit.add(msg.value); // total users deposit
        bonuspay[_package].totaldeposit = bonuspay[_package].totaldeposit.add(msg.value);

        emit investEvent(_package, msg.sender, userlist[users[msg.sender].referer], users[msg.sender].investID, users[msg.sender].id, msg.value, block.timestamp);

        if (bonuspay[_package].totaldeposit >= bonuspay[_package].reachamt)
            bonus(_package);

        if (users[msg.sender].autoinvestCount[_package] == 0)
            autoInvest(users[msg.sender].investID, _package);
    }

    function withdraw(uint _investID) public isLock  {

        require(users[msg.sender].isExist == true, "user not found");
        require(users[msg.sender].Investment[_investID].depositamount > 0, "user has no amount");
        require(users[msg.sender].Investment[_investID].withdrawlstatus == false, "already withdrawl");
        require(((block.timestamp - users[msg.sender].lastwithdrawtime).div(withdrawcalc)) >= 1, "withdraw per day once");

        uint _endtime = block.timestamp;

        if (_endtime >= users[msg.sender].Investment[_investID].deposittime.add(package[users[msg.sender].Investment[_investID].package].stakeDays))
            _endtime = users[msg.sender].Investment[_investID].deposittime.add(package[users[msg.sender].Investment[_investID].package].stakeDays);

        if ((users[msg.sender].Investment[_investID].lastWithdrawal == users[msg.sender].Investment[_investID].deposittime) && (block.timestamp > _endtime)) {
            // contract bonus  // ----
            uint contractBonuses = findContractBonusStatus(users[msg.sender].Investment[_investID].package, users[msg.sender].Investment[_investID].lastWithdrawal, _endtime);

            if (contractBonuses > 0) {
                uint contractBonusPercentage = users[msg.sender].Investment[_investID].depositamount.mul(contractBonusPercent[users[msg.sender].Investment[_investID].package]).div(100 trx);
                contractBonuses = contractBonusPercentage.mul(contractBonuses);
                users[msg.sender].Investment[_investID].contractBonus = users[msg.sender].Investment[_investID].contractBonus.add(contractBonuses);
            }
        }
        
        (uint TotalBonus, uint holding) = _payout(msg.sender, _investID);
        users[msg.sender].lastwithdrawtime = block.timestamp;
        users[msg.sender].Investment[_investID].roicalc = users[msg.sender].Investment[_investID].roicalc.add(TotalBonus);
        users[msg.sender].Investment[_investID].HoldEarned = users[msg.sender].Investment[_investID].HoldEarned.add(holding);

        if (TotalBonus > 0) {
            uint _reinvestAmount = TotalBonus.mul(40 trx).div(100 trx);

            TotalBonus = TotalBonus.sub(_reinvestAmount);
            users[msg.sender].Investment[users[msg.sender].Investment[_investID].package].reinvestamount = users[msg.sender].Investment[users[msg.sender].Investment[_investID].package].reinvestamount.add(_reinvestAmount);
            users[msg.sender].Investment[_investID].ROIEarned = users[msg.sender].Investment[_investID].ROIEarned.add(TotalBonus);
            users[msg.sender].Investment[_investID].totalInvestEarned = users[msg.sender].Investment[_investID].totalInvestEarned.add(TotalBonus);
            users[msg.sender].Investment[_investID].lastWithdrawal = block.timestamp;

            require(msg.sender.send(TotalBonus), "Bonus transfer failed");

            if (users[msg.sender].Investment[_investID].lastWithdrawal > users[msg.sender].Investment[_investID].deposittime.add(package[users[msg.sender].Investment[_investID].package].stakeDays))
                users[msg.sender].Investment[_investID].withdrawlstatus = true;
            emit WithdrawalEvent(users[msg.sender].Investment[_investID].package, msg.sender, _investID, TotalBonus, block.timestamp);
        }

    }

    function _payout(address user, uint _investID)public view returns(uint _ROI, uint _holdamount){

        uint endtime = block.timestamp;
        // uint _ROIAmount;
        uint dayscount;
        uint stakeEndTime = users[user].Investment[_investID].deposittime.add(package[users[user].Investment[_investID].package].stakeDays);

        if (endtime > stakeEndTime) endtime = stakeEndTime;

        dayscount = endtime.sub(users[user].Investment[_investID].deposittime).div(withdrawcalc);

        if (dayscount > 0) {
            _ROI = ((users[user].Investment[_investID].depositamount.mul(package[users[user].Investment[_investID].package].ROI)).div(100 trx)).mul(dayscount);
            _ROI = (_ROI.sub(users[user].Investment[_investID].roicalc));
        }
        //hold view
        uint holdingDays;
        if ((users[user].Investment[_investID].lastWithdrawal == users[user].Investment[_investID].deposittime) && (block.timestamp > stakeEndTime)) {
            holdingDays = block.timestamp.sub(stakeEndTime).div(holdingcalc);

            if (holdingDays > 0) {
                _holdamount = ((users[user].Investment[_investID].depositamount.mul(0.08 trx)).div(100 trx)).mul(holdingDays);
            }

        }
    }

    function Viewcontractbonus(address user, uint _investID)public view returns(uint _contractbonus){
        uint endtime = block.timestamp;
        if (endtime >= users[user].Investment[_investID].deposittime.add(package[users[user].Investment[_investID].package].stakeDays))
            endtime = users[user].Investment[_investID].deposittime.add(package[users[user].Investment[_investID].package].stakeDays);

        if ((users[user].Investment[_investID].lastWithdrawal == users[user].Investment[_investID].deposittime) && (block.timestamp > endtime)) {
            // contract bonus  // ----
            uint contractBonuses = findContractBonusStatus(users[user].Investment[_investID].package, users[user].Investment[_investID].lastWithdrawal, endtime);

            if (contractBonuses > 0) {
                uint contractBonusPercentage = users[user].Investment[_investID].depositamount.mul(contractBonusPercent[users[user].Investment[_investID].package]).div(100 trx);
                contractBonuses = contractBonusPercentage.mul(contractBonuses);
                users[user].Investment[_investID].contractBonus.add(contractBonuses);
                _contractbonus = users[user].Investment[_investID].contractBonus.add(contractBonuses);
            }
        }
    }

    function autoInvest(uint _investID, uint _package) internal {
        users[msg.sender].autoinvestCount[_package]++;
        users[msg.sender].investID++;

        uint amount = users[msg.sender].Investment[_investID].depositamount.mul(15).div(10);

        amount = amount.mul(40).div(100);

        users[msg.sender].Investment[users[msg.sender].investID].package = _package;
        users[msg.sender].Investment[users[msg.sender].investID].depositamount = amount;
        users[msg.sender].Investment[users[msg.sender].investID].deposittime = block.timestamp.add(package[users[msg.sender].Investment[_investID].package].stakeDays);
        users[msg.sender].Investment[users[msg.sender].investID].lastWithdrawal = block.timestamp.add(package[users[msg.sender].Investment[_investID].package].stakeDays);
        users[msg.sender].Investment[users[msg.sender].investID].withdrawlstatus = false;
        totaldeposit = totaldeposit.add(amount);
        bonuspay[_package].totaldeposit = bonuspay[_package].totaldeposit.add(amount);

        emit AutoInvestEvent(msg.sender, _investID, users[msg.sender].Investment[_investID].package, users[msg.sender].investID, amount, block.timestamp);
    }

    function referralpaylevel(address _refer, uint _amount, uint _level)internal{
        uint _bonus = _amount.mul(levelBonus[_level]).div(100 trx);

        if (_refer == address(0))
            _refer = owner;


        refAmount[_refer] = refAmount[_refer].add(_bonus);
        emit levelBonusEvent(msg.sender, _refer, _bonus, block.timestamp, _level);

        _level++;

        if (_level <= 5)
            referralpaylevel(userlist[users[_refer].referer], _amount, _level);

    }

    function refWithdraw()public{
        require(refAmount[msg.sender] > 0, "no reference balance");
        uint amount = refAmount[msg.sender];
        refAmount[msg.sender] = 0;
        require(address(uint160(msg.sender)).send(amount));
        emit referenceWithdraw(msg.sender, amount, block.timestamp);
    }

    function _contractbonuswithdraw(uint _investID)public{
        require(users[msg.sender].Investment[_investID].contractBonus > 0, "no contract bonus");
        uint amount = users[msg.sender].Investment[_investID].contractBonus;
        users[msg.sender].Investment[_investID].contractBonus = 0;
        require(address(uint160(msg.sender)).send(amount), "contract bonus withdraw failed");
        emit contractBonusWithdraw(msg.sender, amount, block.timestamp);
    }

    function holdwithdraw(uint _investID)public{
        require(users[msg.sender].Investment[_investID].HoldEarned > 0, "no hold amount");
        uint amount = users[msg.sender].Investment[_investID].HoldEarned;
        users[msg.sender].Investment[_investID].HoldEarned = 0;
        require(address(uint160(msg.sender)).send(amount), "hold withdraw failed");
        emit holdingBonus(msg.sender, amount, block.timestamp);
    }

    function bonus(uint _package)internal{ // Contract bonus calculation
        uint calculation = (bonuspay[_package].totaldeposit).div(bonuspay[_package].reachamt);
        if ((calculation > 0) && (packageLimitReached[_package] != calculation))
            setContractBonus(_package, block.timestamp, calculation);
    }

    function setContractBonus(uint _package, uint _time, uint _bonusReached) internal returns(bool){ // set contract bonus.
        contractBonusTimeStamp[_package].push(_time);
        contractBonusIndex[_package][_time] = _bonusReached;
        packageLimitReached[_package] = _bonusReached;
        emit ContractBonusEvent(_package, _time, _bonusReached);
        return true;
    }

    function findContractBonusStatus(uint _package, uint _startTime, uint _endTime) internal view returns(uint){ // find contract bonus using investment time.
        if (contractBonusTimeStamp[_package].length > 0) {
            uint _contractBonusTimeStamp;
            for (uint i = 0; i < contractBonusTimeStamp[_package].length; i++) {
                if ((contractBonusTimeStamp[_package][i] <= _startTime) || (_endTime <= contractBonusTimeStamp[_package][i].add(withdrawcalc)))
                    _contractBonusTimeStamp = _contractBonusTimeStamp.add(contractBonusIndex[_package][contractBonusTimeStamp[_package][i]]);
            }
            return _contractBonusTimeStamp;
        }
    }

    function failSafe(address payable _toUser, uint _amount) onlyOwner external returns(bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }

    function contractLock(bool _lockStatus) onlyOwner external returns(bool) {
        lockStatus = _lockStatus;
        return true;
    }

    function viewUserInvestment(address _user, uint _investID)public view returns(uint, uint, uint, bool, uint){
        return (users[_user].Investment[_investID].package,
            users[_user].Investment[_investID].deposittime,
            users[_user].Investment[_investID].depositamount,
            users[_user].Investment[_investID].withdrawlstatus,
            users[_user].autoinvestCount[users[_user].Investment[_investID].package]

        );
    }

    function viewUserInvestmentEarnings(address _user, uint _investID)public view returns(uint, uint, uint, uint){
        return (users[_user].Investment[_investID].ROIEarned,
            users[_user].Investment[_investID].HoldEarned,
            users[_user].Investment[_investID].totalInvestEarned,
            users[_user].Investment[_investID].reinvestamount

        );
    }

    function isContract(address account) public view returns(bool) {
        uint32 size;
        assembly {
            size:= extcodesize(account)
        }
        if (size != 0)
            return true;

        return false;
    }

}