// DeCentroFund smart contract
// Telegram https://t.me/DeCentroFund
// GitHub https://github.com/DeCentroFund

pragma solidity ^0.4.25;

contract DeCentroFund {

// -----------------------------------
// Variables

    uint constant REFERRAL_PERCENT = 7;
    uint constant DESTROY_TIMEOUT = 3 * 365 days;

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
        uint id, address indexed account, uint amount, uint total, uint time
    );
    event EventReinvest(
        uint id, address indexed account, uint amount, uint total, uint time
    );
    event EventWithdraw(
        uint id, address indexed account, uint amount, uint total, uint time
    );
    event EventUserDestroy(
        uint id, address indexed account, uint amount, uint total, uint time
    );
    event EventReferrerReward(
        uint id, address indexed account, uint amount, uint total, uint time,
        address referral
    );

// -----------------------------------
// Constructor

    constructor() public {
        Fund = address(this);
        Users[Fund].prevUser = Fund;
        Users[Fund].nextUser = Fund;
    }

// -----------------------------------
// Modifiers

    modifier Update() {
        require(msg.sender != Fund && msg.sender != address(0), "Bad address!");
        UserUpdate(msg.sender);
        _;
        if (gasleft() > 200000) FirstUserDestroy();
    }

// -----------------------------------
// Fallback function

    function() external payable {
        if (msg.data.length == 20 && !IsSetReferrer(msg.sender)) {
            address referrer = BytesToAddress(msg.data);
            if (referrer != msg.sender) SetReferrer(msg.sender, referrer);
        }
        Invest();
    }

// -----------------------------------
// Public functions

    function Invest() public payable Update {
        uint amount = msg.value;
        if (amount > 0) {
            address account = msg.sender;
            Users[account].inv += amount;
            Users[Fund].inv += amount;
            In(account, amount);
            emit EventInvest(EventId++, account, amount, Total, now);
        }
    }

    function Reinvest(uint _amount) external Update {
        if (_amount > 0) {
            require(_amount <= MyBalance(), "Not enough balance!");
            address account = msg.sender;
            Users[account].minus += _amount;
            Users[account].rei += _amount;
            Users[Fund].rei += _amount;
            In(account, _amount);
            emit EventReinvest(EventId++, account, _amount, Total, now);
        }
    }

    function Withdraw(uint _amount) external Update {
        if (_amount > 0) {
            require(_amount <= MyBalance(), "Not enough balance!");
            address account = msg.sender;
            Users[account].minus += _amount;
            Users[account].out += _amount;
            Users[Fund].out += _amount;
            emit EventWithdraw(EventId++, account, _amount, Total, now);
            account.transfer(_amount);
        }
    }
    
// -----------------------------------
// Public view functions

    function MyBalance() public view returns (uint) {
        return Balance(msg.sender);
    }

    function MyInvestments() external view returns (uint) {
        return Investments(msg.sender);
    }

    function DaysToMyDestroy() public view returns (uint) {
        return DaysToDestroy(msg.sender);
    }

    function GetData(uint _type) external view returns (uint[20] memory data) {
        address account = msg.sender;
        UsersStruct memory fund = Users[Fund];
        UsersStruct memory user = Users[account];
        bool all = (_type == 0 ? true : false);
        if (_type == 1 || all) data[1] = Total;
        if (_type == 2 || all) data[2] = EventId;
        if (_type == 3 || all) data[3] = UsersNumber;
        if (_type == 4 || all) data[4] = Fund.balance;
        if (_type == 5 || all) data[5] = DaysToNextDestroy();
        if (_type == 6 || all) data[6] = fund.inv;
        if (_type == 7 || all) data[7] = fund.rei;
        if (_type == 8 || all) data[8] = fund.out;
        if (_type == 9 || all) data[9] = fund.ref;
        if (_type == 10 || all) data[10] = MyBalance();
        if (_type == 11 || all) data[11] = UserFund(account);
        if (_type == 12 || all) data[12] = IsActiveUser(account) ? 1 : 0;
        if (_type == 13 || all) data[13] = IsSetReferrer(account) ? 1 : 0;
        if (_type == 14 || all) data[14] = MyReferrals();
        if (_type == 15 || all) data[15] = DaysToMyDestroy();
        if (_type == 16 || all) data[16] = user.inv;
        if (_type == 17 || all) data[17] = user.rei;
        if (_type == 18 || all) data[18] = user.out;
        if (_type == 19 || all) data[19] = user.ref;
    }

// -----------------------------------
// Private functions

    function In(address _account, uint _amount) private {
        uint reward = _amount * REFERRAL_PERCENT / 100;
        _amount -= reward;
        Total += _amount;
        Users[_account].plus += Rectangle(_account) + Triangle(_amount);
        Users[_account].amount += _amount;
        Users[_account].total = Total;
        if (reward > 0) ReferrerReward(_account, reward);
    }

    function ReferrerReward(address _referral, uint _reward) private {
        address referrer = Referrer(_referral);
        Users[referrer].plus += _reward;
        Users[referrer].ref += _reward;
        if (referrer != Fund) emit EventReferrerReward(
            EventId++, referrer, _reward, Total, now, _referral
        );
    }

    function SetReferrer(address _referral, address _referrer) private {
        Refs[_referral].referrer = _referrer;
        Refs[_referrer].referrals++;
    }

    function UserUpdate(address _account) private {
        if (LastUser() != _account) {
            if (!IsActiveUser(_account)) UsersNumber++;
            else FromQueue(_account);
            IntoQueue(_account);
        }
        Users[_account].lastUpdate = now;
    }

    function IntoQueue(address _account) private {
        address lastUser = LastUser();
        Users[lastUser].nextUser = _account;
        Users[_account].prevUser = lastUser;
        Users[_account].nextUser = Fund;
        Users[Fund].prevUser = _account;
    }

    function FromQueue(address _account) private {
        address prevUser = Users[_account].prevUser;
        address nextUser = Users[_account].nextUser;
        Users[prevUser].nextUser = nextUser;
        Users[nextUser].prevUser = prevUser;
    }

    function FirstUserDestroy() private {
        address firstUser = FirstUser();
        if (DaysToDestroy(firstUser) == 0) UserDestroy(firstUser);
    }

    function UserDestroy(address _account) private {
        if (_account != Fund) {
            UsersStruct memory user = Users[_account];
            Users[Fund].plus += user.plus + Rectangle(_account) + Rectangle(Fund);
            Users[Fund].minus += user.minus;
            Users[Fund].amount += user.amount;
            Users[Fund].total = Total;
            FromQueue(_account);
            UsersNumber--;
            uint investments = Investments(_account);
            delete Users[_account];
            emit EventUserDestroy(EventId++, _account, investments, Total, now);
        }
    }

// -----------------------------------
// Private view functions

    function FirstUser() private view returns (address) {
        return Users[Fund].nextUser;
    }

    function LastUser() private view returns (address) {
        return Users[Fund].prevUser;
    }

    function TimeDestroy(address _account) private view returns (uint) {
        return Users[_account].lastUpdate + DESTROY_TIMEOUT;
    }

    function DaysToDestroy(address _account) private view returns (uint) {
        return Minus(TimeDestroy(_account), now) / 1 days;
    }

    function DaysToNextDestroy() private view returns (uint) {
        return DaysToDestroy(FirstUser());
    }

    function IsActiveUser(address _account) private view returns (bool) {
        return Users[_account].lastUpdate != 0;
    }

    function IsSetReferrer(address _account) private view returns (bool) {
        return Refs[_account].referrer != 0;
    }

    function Referrer(address _account) private view returns (address) {
        address referrer = Refs[_account].referrer;
        if (!IsActiveUser(referrer)) referrer = Fund;
        return referrer;
    }

    function MyReferrals() private view returns (uint) {
        return Refs[msg.sender].referrals;
    }

    function Investments(address _account) private view returns (uint) {
        return Users[_account].inv + Users[_account].rei;
    }

    function Balance(address _account) private view returns (uint) {
        return Minus(Debit(_account) + UserFund(_account), Credit(_account));
    }

    function UserFund(address _account) private view returns (uint) {
        uint usersAmounts = Total - Users[Fund].amount;
        if (usersAmounts == 0) return 0;
        uint fundBalance = Minus(Debit(Fund), Credit(Fund));
        return fundBalance * Users[_account].amount / usersAmounts;
    }

    function Debit(address _account) private view returns (uint) {
        return Rectangle(_account) + Users[_account].plus;
    }

    function Credit(address _account) private view returns (uint) {
        return Users[_account].minus;
    }

    function Rectangle(address _account) private view returns (uint) {
        UsersStruct memory user = Users[_account];
        if (user.total == 0 || user.total == Total) return 0;
        return user.amount * NLog(Total * LOG_1 / user.total) / LOG_1;
    }

    function Triangle(uint _amount) private view returns (uint) {
        uint a = Total - _amount;
        if (a == 0) return Total;
        return _amount - NLog(Total * LOG_1 / a) * a / LOG_1;
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
            log += y / i++;
            y = y * x / LOG_1;
            log -= y / i++;
            y = y * x / LOG_1;
        }
    }

    function Minus(uint a, uint b) private pure returns (uint) {
        if (b >= a) return 0;
        else return a - b;
    }

    function BytesToAddress(bytes memory _data) private pure returns (address) {
        uint result;
        uint mul = 1;
        for (uint i = 20; i > 0; i--) {
            result += uint8(_data[i - 1]) * mul;
            mul *= 256;
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

    function ___test(address _address) public returns (uint) {
        uint start = gasleft();
        FirstUserDestroy();
        UserDestroy(_address);
        return start - gasleft();
    }
*/

    function ___Kill() public { ///
        selfdestruct(msg.sender);
    }

// -----------------------------------
// End of contract

}