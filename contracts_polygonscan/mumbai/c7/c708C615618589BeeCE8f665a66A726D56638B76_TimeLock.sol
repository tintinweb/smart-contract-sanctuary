pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


interface Mintable is IERC20 {
    function mintTo(address to, uint256 value) external returns (bool);
}

contract TimeLock is Ownable {

    using SafeMath for uint;

    Mintable token;

    struct LockBoxStruct {
        address beneficiary;
        uint total;
        uint balance;
        uint payed;
        uint depositTime;
        uint unvested;
    }

    struct poolData {
        string name;
        uint lockPeriod;
        uint periodLength;
        uint periodsNumber;
        uint percent;
        bool exists;
        uint startTime;
        uint cap;
        uint deposited;
        uint withdrawn;
    }

    struct poolName {
        string name;
    }

    uint public percent;

    uint public poolsCount;

    poolName[] poolNamesArray;

    mapping (string => mapping (address => LockBoxStruct[] )) public boxPool;
    mapping (string => poolData) public poolLockTime;

    event LogLockBoxDeposit(address sender, uint amount, uint releaseTime, string pool);
    event LogLockBoxWithdrawal(address receiver, uint amount);
    event PoolAdded(string name);

    constructor(address tokenContract) public {
        token = Mintable(tokenContract);
        percent = 10000; // 100% * 100

        _addPool("marketing", 1 * 5 days, 5 days, 4, 2500, now, 1000000e8);
        _addPool("privateSale",1 * 5 days, 5 days, 4, 2500, now, 1000000e8);
    }

    function _addPool(string memory name, uint lockPeriod, uint periodLength, uint periodsNumber, uint percentPerNumber, uint startTime, uint cap)
    internal returns(bool success) {
        require(!poolLockTime[name].exists, "Pool: already exists");
        require(periodsNumber.mul(percentPerNumber) <= percent, "Pool: percents exceeded limit");
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

    function addPool(string memory name, uint lockPeriod, uint periodLength, uint periodsNumber, uint percentPerNumber, uint startTime, uint cap) onlyOwner
    public returns(bool success) {
        _addPool(name, lockPeriod, periodLength, periodsNumber, percentPerNumber, startTime, cap);
        return true;
    }

    function deposit(address beneficiary, uint amount, string memory _poolName, uint _unvestedAmount) onlyOwner
    public returns(bool success) {
        require(poolLockTime[_poolName].exists, "Pool: not exists");
        require(poolLockTime[_poolName].deposited.add(amount) < poolLockTime[_poolName].cap, "Pool: cap exceded");

        LockBoxStruct memory l;
        l.beneficiary = beneficiary;
        l.balance = amount;
        l.total = amount;
        l.payed = 0;
        l.depositTime = poolLockTime[_poolName].startTime;
        l.unvested = _unvestedAmount;
        boxPool[_poolName][beneficiary].push(l);
        poolLockTime[_poolName].deposited = poolLockTime[_poolName].deposited.add(amount);
        emit LogLockBoxDeposit(msg.sender, amount, poolLockTime[_poolName].lockPeriod, _poolName);
        return true;
    }


    function withdraw(uint lockBoxNumber, address beneficiary, string memory _poolName)
    public payable returns(bool success) {
        LockBoxStruct storage l = boxPool[_poolName][beneficiary][lockBoxNumber];
        require(l.beneficiary == msg.sender && l.balance > 0, "Benefeciary does not exists");
        uint _unlockTime = l.depositTime.add(poolLockTime[_poolName].lockPeriod);
        require(_unlockTime > now, "Funds locked");

        uint amount = _calculateUnlockedTokens(beneficiary, lockBoxNumber, _poolName);
        if (l.unvested > 0) {
            l.unvested = 0;
        }
        l.balance = l.balance.sub(amount);
        l.payed = l.payed.add(amount);
        require(token.mintTo(msg.sender, amount), "Cannot mint to beneficiary");
        poolLockTime[_poolName].withdrawn = poolLockTime[_poolName].withdrawn.add(amount);
        emit LogLockBoxWithdrawal(msg.sender, amount);
        return true;
    }

    function getMapCount(address beneficiary, string memory _poolName)
    public view returns (uint) {
        return boxPool[_poolName][beneficiary].length;
    }

    function getSingleBeneficiaryStruct(string memory _poolName, address beneficiary, uint id)
    public view returns (uint256, uint256, uint256, uint256) {

        uint _balance = boxPool[_poolName][beneficiary][id].balance;
        uint _vesting = poolLockTime[_poolName].periodsNumber;
        uint _rule = poolLockTime[_poolName].periodLength;
        uint _percent = poolLockTime[_poolName].percent;
        return (_balance, _vesting, _rule, _percent);
    }

    function getBeneficiaryStructs(string memory _poolName, address beneficiary)
    public view returns (LockBoxStruct[] memory) {
        LockBoxStruct[] memory boxes = boxPool[_poolName][beneficiary];
        uint256 boxCount = getMapCount(beneficiary, _poolName);
        for (uint i = 0; i < boxCount; i++) {
            LockBoxStruct memory LBS = boxes[i];
            boxes[i] = LBS;
        }

        return boxes;
    }


    function getPools()
    public view returns (poolName[] memory){
        poolName[] memory pools = poolNamesArray;
        for (uint i = 0; i < poolsCount; i++) {
            poolName memory pool = pools[i];
            pools[i] = pool;
        }
        return pools;
    }

    function getTokensAvailable(string memory _poolName, address beneficiary, uint id)
    public view returns (uint256) {
        uint amount = _calculateUnlockedTokens(beneficiary, id, _poolName);
        return amount;
    }

    function _calculateUnlockedTokens(address _beneficiary, uint256 _boxNumber, string memory _poolName)
    private
    view
    returns (uint256)
    {
        LockBoxStruct memory box = boxPool[_poolName][_beneficiary][_boxNumber];
        poolData memory pool = poolLockTime[_poolName];
        uint256 _cliff = pool.lockPeriod;
        uint256 _periodLength = pool.periodLength;
        uint256 _periodAmount = box.balance * pool.percent / percent;
        uint256 _periodsNumber = pool.periodsNumber;
        uint256 _unvestedAmount = box.unvested;

        if (now < box.depositTime.add(_cliff)) {
            return _unvestedAmount;
        }

        uint256 periods = now.sub(box.depositTime.add(_cliff)).div(_periodLength);
        periods = periods > _periodsNumber ? _periodsNumber : periods;
        return _unvestedAmount.add(periods.mul(_periodAmount));
    }

    function fundContract() payable public returns (bool) {
        return true;
    }

    function withdrawFromContract() onlyOwner payable public returns (bool) {
        msg.sender.transfer(address(this).balance);
        return true;
    }

}