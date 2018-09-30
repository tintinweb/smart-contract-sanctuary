pragma solidity ^0.4.24;

// DeCentroFund Smart Contract
// Code is published on https://github.com/DeCentroFund
// Telegram channel https://t.me/DeCentroFund

contract DeCentroFund {

// -----------------------------------
// Variables

    uint constant REFERRAL_PERCENT = 1;
    uint constant TIMEOUT_DESTROY = 365 days;

    uint Total;
    uint EventId;
    uint UsersNumber;
    address Fund;

    mapping (address => UsersStruct) Users;
    mapping (address => RefsStruct) Refs;

    struct UsersStruct {
        uint inv;
        uint rei;
        uint out;
        uint ref;
        uint amount;
        uint total;
        uint plus;
        uint minus;
        uint lastUpdate;
        address prevUser;
        address nextUser;
    }
    struct RefsStruct {
        uint referrals;
        address referrer;
    }

    uint constant ACCURACY = 20;
    uint constant LOG_1 = 10 ** ACCURACY;
    uint constant LOG_2 = LOG_1 * 3 / 2;
    uint constant LOG_3 = 405465108108164381978013115464 / 10 ** (30 - ACCURACY);
    uint constant LOG_4 = ACCURACY * 2;

// -----------------------------------
// Events

    event EventInvest(
        uint _id, address indexed _address, uint _amount, uint _total, uint _time
    );
    event EventReInvest(
        uint _id, address indexed _address, uint _amount, uint _total, uint _time
    );
    event EventTakeOut(
        uint _id, address indexed _address, uint _amount, uint _total, uint _time
    );
    event EventUserDestroy(
        uint _id, address indexed _address, uint _amount, uint _total, uint _time
    );
    event EventReferralReward(
        uint _id, address indexed _address, uint _amount, uint _total, uint _time,
        address _referral
    );

// -----------------------------------
// Modifiers

    modifier Update() {
        UserUpdate(msg.sender);
        _;
    }

// -----------------------------------
// Constructor

    constructor() public {
        Fund = address(this);
        Users[Fund].prevUser = Fund;
        Users[Fund].nextUser = Fund;
    }

// -----------------------------------
// Public and external functions

    function() external payable {
        if (msg.data.length == 20) SetReferrer(BytesToAddress(msg.data));
        Invest();
    }

    function Invest() public payable Update returns (bool) {
        if (msg.value > 0) {
            Users[msg.sender].inv += msg.value;
            Users[Fund].inv += msg.value;
            In(msg.value);
            emit EventInvest(++EventId, msg.sender, msg.value, Total, now);
            return true;
        } else CheckTimeout();
    }

    function ReInvest(uint _amount) external Update returns (bool) {
        if (_amount > 0 && _amount <= MyBalance()) {
            Users[msg.sender].minus += _amount;
            Users[msg.sender].rei += _amount;
            Users[Fund].rei += _amount;
            In(_amount);
            emit EventReInvest(++EventId, msg.sender, _amount, Total, now);
            return true;
        } else CheckTimeout();
    }

    function TakeOut(uint _amount) external Update returns (bool) {
        CheckTimeout();
        if (_amount > 0 && _amount <= MyBalance()) {
            Users[msg.sender].minus += _amount;
            Users[msg.sender].out += _amount;
            Users[Fund].out += _amount;
            emit EventTakeOut(++EventId, msg.sender, _amount, Total, now);
            msg.sender.transfer(_amount);
            return true;
        }
    }

    function SetReferrer(address _address) public returns (bool) {
        if (msg.data.length != 20) CheckTimeout();
        if (IsSetReferrer()) return true;
        if (_address != msg.sender) {
            Refs[msg.sender].referrer = _address;
            Refs[_address].referrals++;
            return true;
        }
    }

    function MyBalance() public view returns (uint) {
        return Balance(msg.sender);
    }

    function MyContribution() external view returns (uint) {
        return Users[msg.sender].inv + Users[msg.sender].rei;
    }

    function MyReferrals() public view returns (uint) {
        return Refs[msg.sender].referrals;
    }

    function MyRefReward() external view returns (uint) {
        return Users[msg.sender].ref;
    }

    function DaysToDestroy() public view returns (uint) {
        if (!IsActiveUser(msg.sender)) return 0;
        uint timeFromUpdate = now - Users[msg.sender].lastUpdate;
        if (timeFromUpdate > TIMEOUT_DESTROY) return 0;
        return (TIMEOUT_DESTROY - timeFromUpdate) / 1 days;
    }

    function GetData(uint _type) external view returns (uint[18] data) {
        UsersStruct memory fund = Users[Fund];
        UsersStruct memory user = Users[msg.sender];
        bool all = (_type == 0 ? true : false);
        if (_type == 1 || all) data[1] = Total;
        if (_type == 2 || all) data[2] = EventId;
        if (_type == 3 || all) data[3] = UsersNumber;
        if (_type == 4 || all) data[4] = Fund.balance;
        if (_type == 5 || all) data[5] = fund.inv;
        if (_type == 6 || all) data[6] = fund.rei;
        if (_type == 7 || all) data[7] = fund.out;
        if (_type == 8 || all) data[8] = MyActive();
        if (_type == 9 || all) data[9] = MyBalance();
        if (_type == 10 || all) data[10] = MyPoolBalance();
        if (_type == 11 || all) data[11] = MyReferrer();
        if (_type == 12 || all) data[12] = MyReferrals();
        if (_type == 13 || all) data[13] = DaysToDestroy();
        if (_type == 14 || all) data[14] = user.inv;
        if (_type == 15 || all) data[15] = user.rei;
        if (_type == 16 || all) data[16] = user.out;
        if (_type == 17 || all) data[17] = user.ref;
    }

// -----------------------------------
// Private functions

    function In(uint _amount) private {
        uint reward = _amount * REFERRAL_PERCENT / 100;
        uint amount = _amount - reward;
        Total += amount;
        ReferralReward(reward);
        Users[msg.sender].plus += Rectangle(msg.sender) + Triangle(amount);
        Users[msg.sender].amount += amount;
        Users[msg.sender].total = Total;
    }

    function UserUpdate(address _address) private {
        if (Users[Fund].prevUser != _address) {
            if (!IsActiveUser(_address)) UsersNumber++;
            else FromQueue(_address);
            IntoQueue(_address);
        }
        Users[_address].lastUpdate = now;
    }

    function ReferralReward(uint _reward) private {
        address referrer = Refs[msg.sender].referrer;
        if (!IsActiveUser(referrer)) referrer = Fund;
        Users[referrer].plus += _reward;
        Users[referrer].ref += _reward;
        emit EventReferralReward(++EventId, referrer, _reward, Total, now, msg.sender);
    }

    function IsActiveUser(address _address) private view returns (bool) {
        return Users[_address].lastUpdate != 0;
    }

    function IsSetReferrer() private view returns (bool) {
        return Refs[msg.sender].referrer != 0;
    }

    function IntoQueue(address _address) private {
        address lastUser = Users[Fund].prevUser;
        Users[lastUser].nextUser = _address;
        Users[_address].prevUser = lastUser;
        Users[_address].nextUser = Fund;
        Users[Fund].prevUser = _address;
    }

    function FromQueue(address _address) private {
        address prevUser = Users[_address].prevUser;
        address nextUser = Users[_address].nextUser;
        Users[prevUser].nextUser = nextUser;
        Users[nextUser].prevUser = prevUser;
    }

    function MyReferrer() private view returns (uint) {
        if (IsSetReferrer()) return 1; else return 0;
    }

    function MyActive() private view returns (uint) {
        if (IsActiveUser(msg.sender)) return 1; else return 0;
    }

    function MyPoolBalance() private view returns (uint) {
        return UserPool(msg.sender);
    }

    function Balance(address _address) private view returns (uint) {
        return Minus(UserPool(_address) + Debit(_address), Credit(_address));
    }

    function UserPool(address _address) private view returns (uint) {
        uint usersAmounts = Total - Users[Fund].amount;
        if (usersAmounts == 0) return 0;
        return Minus(Debit(Fund), Credit(Fund)) * Users[_address].amount / usersAmounts;
    }

    function Debit(address _address) private view returns (uint) {
        return Rectangle(_address) + Users[_address].plus;
    }

    function Credit(address _address) private view returns (uint) {
        return Users[_address].minus;
    }

    function Rectangle(address _address) private view returns (uint) {
        UsersStruct memory user = Users[_address];
        if (user.amount == 0 || user.total == Total) return 0;
        return user.amount * NLog(Total * LOG_1 / user.total) / LOG_1;
    }

    function Triangle(uint _amount) private view returns (uint) {
        uint a = Total - _amount;
        if (a == 0) return Total;
        return _amount - NLog(Total * LOG_1 / a) * a / LOG_1;
    }

    function CheckTimeout() private {
        address firstUser = Users[Fund].nextUser;
        if (firstUser != Fund) {
            uint timeDestroy = Users[firstUser].lastUpdate + TIMEOUT_DESTROY;
            if (now > timeDestroy) UserDestroy(firstUser);
        }
    }

    function UserDestroy(address _address) private {
        UsersStruct memory user = Users[_address];
        Users[Fund].plus += user.plus + Rectangle(_address) + Rectangle(Fund);
        Users[Fund].minus += user.minus;
        Users[Fund].amount += user.amount;
        Users[Fund].total = Total;
        FromQueue(_address);
        UsersNumber--;
        emit EventUserDestroy(++EventId, _address, user.inv + user.rei, Total, now);
        delete Users[_address];
    }

// -----------------------------------
// Pure functions

    function NLog(uint x) private pure returns (uint log) {
        while (x >= LOG_2) {
            log += LOG_3;
            x = x * 2 / 3;
        }
        x -= LOG_1;
        uint y = x;
        uint i = 1;
        while (i < LOG_4) {
            log += y / i;
            i++;
            y = y * x / LOG_1;
            log -= y / i;
            i++;
            y = y * x / LOG_1;
        }
    }

    function Minus(uint _a, uint _b) private pure returns (uint) {
        if (_b >= _a) return 0;
        else return _a - _b;
    }

    function BytesToAddress(bytes _data) private pure returns (address) {
        uint result;
        uint mul = 1;
        for (uint i = 20; i > 0; i--) {
            result += uint8(_data[i - 1]) * mul;
            mul = mul * 256;
        }
        return address(result);
    }

// -----------------------------------
// Temp functions
/*
    function ___AllBalance() external pure returns (uint) {
        uint B;
        for (uint i = 0; i < Iters.length; i++) B += Balance(Iters[i]);
        return B;
    }

    function ___test() public pure returns (uint) { ///
        uint x = 115792089237316195423570985008687907853269984665640564039457584007913080214034;
        return 0 - x;
    }
*/
    function ___Kill() public { ///
        selfdestruct(msg.sender);
    }

// -----------------------------------
// End of contract

}