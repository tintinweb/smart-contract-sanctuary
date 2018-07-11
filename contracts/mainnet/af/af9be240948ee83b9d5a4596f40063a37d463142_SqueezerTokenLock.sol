pragma solidity 0.4.24;

contract ERC20Interface {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract SqueezerTokenLock {
    ERC20Interface constant public SQR_TOKEN = ERC20Interface(0x6E7c9606Ac5BCC0123Ee97F8399E6F28aaFB70e0);
    uint constant public SQR_TOKEN_DECIMALS = 18;
    uint constant public SQR_TOKEN_MULTIPLIER = 10**SQR_TOKEN_DECIMALS;
    address constant public PLATFORM_WALLET = 0xA76A464f409b5570a92b657E08FE23f9C4956068;
    address constant public TEAM_WALLET = 0x20de53dA97703BCB465A44D6067775e80536237E;
    uint constant public PLATFORM_MONTHLY = (56250000 * SQR_TOKEN_MULTIPLIER) / 12;
    uint constant public TEAM_MONTHLY = (37500000 * SQR_TOKEN_MULTIPLIER) / 24;
    uint96 constant AUG_15_2018 = 1534291200;
    uint96 constant SEP_15_2018 = 1536969600;
    uint96 constant OCT_15_2018 = 1539561600;
    uint96 constant NOV_15_2018 = 1542240000;
    uint96 constant DEC_15_2018 = 1544832000;
    uint96 constant JAN_15_2019 = 1547510400;
    uint96 constant FEB_15_2019 = 1550188800;
    uint96 constant MAR_15_2019 = 1552608000;
    uint96 constant APR_15_2019 = 1555286400;
    uint96 constant MAY_15_2019 = 1557878400;
    uint96 constant JUN_15_2019 = 1560556800;
    uint96 constant JUL_15_2019 = 1563148800;
    uint96 constant AUG_15_2019 = 1565827200;
    uint96 constant SEP_15_2019 = 1568505600;
    uint96 constant OCT_15_2019 = 1571097600;
    uint96 constant NOV_15_2019 = 1573776000;
    uint96 constant DEC_15_2019 = 1576368000;
    uint96 constant JAN_15_2020 = 1579046400;
    uint96 constant FEB_15_2020 = 1581724800;
    uint96 constant MAR_15_2020 = 1584230400;
    uint96 constant APR_15_2020 = 1586908800;
    uint96 constant MAY_15_2020 = 1589500800;
    uint96 constant JUN_15_2020 = 1592179200;
    uint96 constant JUL_15_2020 = 1594771200;
    uint constant public TOTAL_LOCKS = 37;
    uint8 public unlockStep;

    struct Lock {
        uint96 releaseDate;
        address receiver;
        uint amount;
    }

    Lock[TOTAL_LOCKS] public locks;

    event Released(uint step, uint date, address receiver, uint amount);

    constructor() public {
        uint index = 0;
        _addLock(index++, AUG_15_2018, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, AUG_15_2018, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, SEP_15_2018, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, SEP_15_2018, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, OCT_15_2018, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, OCT_15_2018, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, NOV_15_2018, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, NOV_15_2018, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, DEC_15_2018, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, DEC_15_2018, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, JAN_15_2019, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, JAN_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, FEB_15_2019, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, FEB_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, MAR_15_2019, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, MAR_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, APR_15_2019, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, APR_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, MAY_15_2019, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, MAY_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, JUN_15_2019, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, JUN_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, JUL_15_2019, PLATFORM_WALLET, PLATFORM_MONTHLY);
        _addLock(index++, JUL_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, AUG_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, SEP_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, OCT_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, NOV_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, DEC_15_2019, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, JAN_15_2020, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, FEB_15_2020, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, MAR_15_2020, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, APR_15_2020, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, MAY_15_2020, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, JUN_15_2020, TEAM_WALLET, TEAM_MONTHLY);
        _addLock(index++, JUL_15_2020, TEAM_WALLET, TEAM_MONTHLY);
    }

    function _addLock(uint _index, uint96 _releaseDate, address _receiver, uint _amount) internal {
        locks[_index].releaseDate = _releaseDate;
        locks[_index].receiver = _receiver;
        locks[_index].amount = _amount;
    }

    function unlock() public returns(bool) {
        uint8 step = unlockStep;
        bool success = false;
        while (step < TOTAL_LOCKS) {
            Lock memory lock = locks[step];
            if (now < lock.releaseDate) {
                break;
            }
            require(SQR_TOKEN.transfer(lock.receiver, lock.amount), &#39;Transfer failed&#39;);
            delete locks[step];
            emit Released(step, lock.releaseDate, lock.receiver, lock.amount);
            success = true;
            step++;
        }
        unlockStep = step;
        return success;
    }

    function () public {
        unlock();
    }

    function recoverTokens(ERC20Interface _token) public returns(bool) {
        // Don&#39;t allow recovering SQR Token till the end of lock.
        if (_token == SQR_TOKEN && (now < JUL_15_2020 || unlockStep != TOTAL_LOCKS)) {
            return false;
        }
        return _token.transfer(PLATFORM_WALLET, _token.balanceOf(this));
    }
}