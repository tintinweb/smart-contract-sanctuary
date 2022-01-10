pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract TimeLock is Ownable {

    using SafeMath for uint256;

    uint256 public percent;
    uint256 public poolsCount;
    poolName[] poolNamesArray;
    IERC20 token;

    mapping(string => mapping(address => LockBoxStruct[])) public boxPool;
    mapping(string => poolData) public poolLockTime;
    mapping(address => LPLocker[]) public liquidityLocker;

    struct LockBoxStruct {
        address beneficiary;
        uint256 total;
        uint256 balance;
        uint256 payed;
        uint256 depositTime;
        uint256 periodsPassed;
    }

    struct poolData {
        string name;
        uint256 lockPeriod;
        uint256 periodLength;
        uint256 periodsNumber;
        uint256 percent;
        bool exists;
        uint256 startTime;
        uint256 cap;
        uint256 deposited;
        uint256 withdrawn;
    }

    struct bulkDeposit {
        address beneficiary;
        uint256 amount;
    }

    struct poolName {
        string name;
    }

    struct LPLocker {
        address lp;
        uint256 amount;
        uint256 tillBlockTime;
    }

    event LogLockBoxDeposit(
        address sender,
        uint256 amount,
        uint256 releaseTime,
        string pool
    );
    event LogLockBoxWithdrawal(address receiver, uint256 amount);
    event PoolAdded(string name);

    constructor(address tokenContract) {
        token = IERC20(tokenContract);
        percent = 1000000; // 100% * 10000   / 1% = 10000
    }

    function lockLPToken(address LP, uint256 amount, uint256 lockTimeSeconds) external onlyOwner {
        require(lockTimeSeconds < 630720000, "Lock: period should be less than 20 years");
        LPLocker memory lock;
        IERC20 lpToken = IERC20(LP);
        require(lpToken.transferFrom(_msgSender(), address(this), amount), "LP: transferFrom error");
        lock.amount = amount;
        lock.lp = LP;
        lock.tillBlockTime = block.timestamp.add(lockTimeSeconds);
        liquidityLocker[LP].push(lock);
    }

    function continueLock(address LP, uint256 id, uint256 lockTimeSeconds) external onlyOwner {
        require(lockTimeSeconds < 630720000, "Lock: period should be less than 20 years");
        liquidityLocker[LP][id].tillBlockTime = liquidityLocker[LP][id].tillBlockTime.add(lockTimeSeconds);
    }

    function withdrawLocked(address LP, uint256 id) external onlyOwner {
        require(id < liquidityLocker[LP].length, "Locker: wrong id");
        LPLocker memory lock = liquidityLocker[LP][id];
        require(block.timestamp > lock.tillBlockTime, "Locker: LP tokens still locked");
        require(IERC20(lock.lp).transfer(_msgSender(), lock.amount), "Locker: unable to transfer");
        liquidityLocker[LP][id] = liquidityLocker[LP][liquidityLocker[LP].length.sub(1)];
        liquidityLocker[LP].pop();
    }

    function addPool(
        string calldata name,
        uint256 lockPeriod,
        uint256 periodLength,
        uint256 periodsNumber,
        uint256 percentPerNumber,
        uint256 startTime,
        uint256 cap
    ) external onlyOwner returns (bool success) {
        _addPool(
            name,
            lockPeriod,
            periodLength,
            periodsNumber,
            percentPerNumber,
            startTime,
            cap
        );
        return true;
    }

    function bulkUploadDeposits(bytes calldata data, string calldata _poolName)
    external
    onlyOwner
    {
        bulkDeposit[] memory depositArray = abi.decode(data, (bulkDeposit[]));
        for (uint8 i = 0; i < depositArray.length; i++) {
            deposit(
                depositArray[i].beneficiary,
                depositArray[i].amount,
                _poolName
            );
        }
    }

    function withdraw(
        uint256 lockBoxNumber,
        address beneficiary,
        string calldata _poolName
    ) external returns (bool) {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        LockBoxStruct storage l = boxPool[_poolName][_msgSender()][
        lockBoxNumber
        ];
        require(l.balance > 0, "Beneficiary does not exists");
        uint256 _unlockTime = l.depositTime.add(
            poolLockTime[_poolName].lockPeriod
        );
        require(_unlockTime < block.timestamp, "Funds locked");

        (uint256 amount, uint256 periods) = _calculateUnlockedTokens(
            beneficiary,
            lockBoxNumber,
            _poolName
        );

        l.balance = l.balance.sub(amount);
        l.payed = l.payed.add(amount);
        l.periodsPassed = periods;
        require(
            token.balanceOf(address(this)) >= amount && amount > 0,
            "Wrong amount or balance"
        );
        require(
            token.transfer(_msgSender(), amount),
            "Cannot send to beneficiary"
        );
        poolLockTime[_poolName].withdrawn = poolLockTime[_poolName]
        .withdrawn
        .add(amount);
        emit LogLockBoxWithdrawal(_msgSender(), amount);
        return true;
    }

    function getBeneficiaryStructs(string calldata _poolName, address beneficiary)
    external
    view
    returns (LockBoxStruct[] memory)
    {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        return boxPool[_poolName][beneficiary];
    }

    function getPools() external view returns (poolName[] memory) {
        return poolNamesArray;
    }

    function getTokensAvailable(
        string calldata _poolName,
        address beneficiary,
        uint256 id
    )
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        (uint256 amount, uint256 periods) = _calculateUnlockedTokens(
            beneficiary,
            id,
            _poolName
        );
        poolData memory pool = poolLockTime[_poolName];
        uint256 timeToUnlock = pool.startTime.add(pool.lockPeriod) >
        block.timestamp
        ? pool.startTime.add(pool.lockPeriod).sub(block.timestamp)
        : 0;
        return (amount, timeToUnlock, periods);
    }

    function deposit(
        address beneficiary,
        uint256 amount,
        string memory _poolName
    ) public onlyOwner returns (bool success) {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        require(
            poolLockTime[_poolName].deposited.add(amount) <=
            poolLockTime[_poolName].cap,
            "Pool: cap exceded"
        );

        LockBoxStruct memory l;
        l.beneficiary = beneficiary;
        l.balance = amount;
        l.total = amount;
        l.payed = 0;
        l.depositTime = poolLockTime[_poolName].startTime;
        l.periodsPassed = 0;
        boxPool[_poolName][beneficiary].push(l);
        poolLockTime[_poolName].deposited = poolLockTime[_poolName]
        .deposited
        .add(amount);
        require(
            token.transferFrom(_msgSender(), address(this), amount),
            "Unable to transfer"
        );
        emit LogLockBoxDeposit(
            _msgSender(),
            amount,
            poolLockTime[_poolName].lockPeriod,
            _poolName
        );
        return true;
    }

    function getMapCount(address beneficiary, string memory _poolName)
    external
    view
    returns (uint256)
    {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        return boxPool[_poolName][beneficiary].length;
    }

    function _setAmount(uint256 amount) internal pure returns (uint256) {
        uint256 oneToken = 1e18;
        return oneToken.mul(amount);
    }

    function _addPool(
        string memory name,
        uint256 lockPeriod,
        uint256 periodLength,
        uint256 periodsNumber,
        uint256 percentPerNumber,
        uint256 startTime,
        uint256 cap
    ) internal returns (bool success) {
        require(!poolLockTime[name].exists, "Pool: already exists");
        require(
            periodsNumber.mul(percentPerNumber) <= percent,
            "Pool: percents exceeded limit"
        );

        poolName memory pD;
        poolLockTime[name].name = name;
        poolLockTime[name].lockPeriod = lockPeriod;
        poolLockTime[name].periodLength = periodLength;
        poolLockTime[name].periodsNumber = periodsNumber;
        poolLockTime[name].percent = percentPerNumber;
        poolLockTime[name].cap = cap;
        poolLockTime[name].exists = true;
        poolLockTime[name].startTime = startTime;
        poolLockTime[name].deposited = 0;
        poolLockTime[name].withdrawn = 0;
        poolsCount = poolsCount.add(1);

        pD.name = name;
        poolNamesArray.push(pD);
        emit PoolAdded(name);
        return true;
    }

    function _calculateUnlockedTokens(
        address _beneficiary,
        uint256 _boxNumber,
        string memory _poolName
    ) private view returns (uint256, uint256) {
        LockBoxStruct memory box = boxPool[_poolName][_beneficiary][_boxNumber];
        poolData memory pool = poolLockTime[_poolName];
        uint256 _cliff = pool.lockPeriod;
        uint256 _periodLength = pool.periodLength;
        uint256 _periodAmount = (box.total * pool.percent) / percent;
        uint256 _periodsNumber = pool.periodsNumber;

        if(box.depositTime.add(_cliff) > block.timestamp) {
            return (0, 0);
        }

        uint256 periods = block.timestamp.sub(box.depositTime.add(_cliff)).div(
            _periodLength
        );
        periods = periods > _periodsNumber ? _periodsNumber : periods;
        uint256 periodsToSend = periods.sub(box.periodsPassed);

        if (box.periodsPassed == _periodsNumber && box.total.sub(box.payed) > 0) {
            return (box.total.sub(box.payed), periods);
        }

        return (periodsToSend.mul(_periodAmount), periods);
    }
}