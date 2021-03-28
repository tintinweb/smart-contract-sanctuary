/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.5;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    function burn(uint256 value) external returns (bool);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract PoolRewardToken {
    mapping (address => uint256) public _balanceOf;

    string public constant name = "Modern Liquidity Token";
    string public constant symbol = "MLT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address account) public view returns (uint256 value) {
        return _balanceOf[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(_balanceOf[msg.sender] >= value);

        _balanceOf[msg.sender] -= value;  // deduct from sender's balance
        _balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferMultiple(address[] memory to, uint256[] memory values) public returns (bool success) {
        require(to.length == values.length);

        for (uint256 i = 0; i < to.length; i++) {
            require(_balanceOf[msg.sender] >= values[i]);

            _balanceOf[msg.sender] -= values[i];
            _balanceOf[to[i]] += values[i];
            emit Transfer(msg.sender, to[i], values[i]);
        }
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= _balanceOf[from]);
        require(value <= _allowances[from][msg.sender]);

        _balanceOf[from] -= value;
        _balanceOf[to] += value;
        _allowances[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) internal {
        totalSupply += value;
        _balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function burn(uint256 value) public returns (bool success) {
        require(value <= _balanceOf[msg.sender]);
        totalSupply -= value;
        _balanceOf[msg.sender] -= value;
        return true;
    }
}

abstract contract Ownable {
    address public owner_;

    constructor() {
        owner_ = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner_)
            _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) owner_ = newOwner;
    }
}

contract MiningPool is PoolRewardToken, Ownable {
    uint256 public constant MAX_SUPPLY = 35000000 * 10**18;
    uint8 public constant INITIAL_BLOCK_STEP = 255;

    struct Investor {
        uint256[14] deposits;
        uint256 lastZeroPtr;
        uint256[14] depositUnlockTime;
        bool initialized;
    }

    struct BlockInfo {
        uint256[14] totalDeposits;
        uint256[14] poolRewards;
        uint8 blockStep;
        uint256 pointLength;
        uint256 pointBlock;
        uint256 pointStartEthereumBlock;
        uint256 pointEndEthereumBlock;
    }

    uint8 public BLOCK_STEP = INITIAL_BLOCK_STEP;
    uint256 public deployBlock;
    uint256 public lastRecordedBlock;
    BlockInfo[1000000] public history;
    uint256 public arrayPointer;
    mapping (address => Investor) public investors;
    bool public miningFinished = false;
    uint256 public feesBalance;

    IERC20[14] public tokens;
    uint256 public feeAmount = 25714285714285717;  // 1.26 / .98 * .02
    uint256[14] public poolRewards = [10**18 * 12 / 10, 10**18 * 6 / 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];  // total: 1.26 tkns
    uint256[14] public totalDeposits = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint256[14] public lockDurations = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint256[14] public minDeposits = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];


    event Deposit(address indexed investor, uint256 indexed token, uint256 value);
    event Harvest(address indexed investor, uint256 value);
    event Withdraw(address indexed investor, uint256 indexed token, uint256 value);
    event FeesSpent(address indexed to, uint256 value);
    event StepChanged(uint8 newValue);
    event LockDurationChanged(uint256[14] values);
    event PoolRewardsChanged(uint256[14] values);
    event MinDepositsChanged(uint256[14] values);

    constructor() {
        deployBlock = block.number;
        emit StepChanged(BLOCK_STEP);
        emit LockDurationChanged(lockDurations);

        history[0].poolRewards = poolRewards;
        history[0].blockStep = BLOCK_STEP;
        history[0].pointStartEthereumBlock = history[0].pointEndEthereumBlock = deployBlock;

        arrayPointer++;
    }

    function setTokenAddress(uint index, address token) public {
        require(address(tokens[index]) == address(0), "Address was already set");
        tokens[index] = IERC20(token);
    }

    function setBlockStep(uint8 value) public onlyOwner {
        recordHistory();
        BLOCK_STEP = value;
        emit StepChanged(value);
    }

    function setLockDurations(uint256[14] memory v) public onlyOwner {
        lockDurations = v;
        emit LockDurationChanged(v);
    }

    function setMinDeposits(uint256[14] memory v) public onlyOwner {
        minDeposits = v;
        emit MinDepositsChanged(v);
    }

    // subtract 2% when setting pool rewards
    function setPoolRewards(uint256[14] memory v) public onlyOwner {
        recordHistory();
        uint256 sum = v[0] + v[1] + v[2] + v[3] + v[4] + v[5] + v[6] + v[7] + v[8] + v[9] + v[10] + v[11] + v[12] + v[13];
        feeAmount = sum * 2 / 98;  // 2% from given 98%
        poolRewards = v;
        emit PoolRewardsChanged(v);
    }

    function currentBlock() public view returns (uint256) {
        BlockInfo memory prevBlock = history[arrayPointer-1];
        return prevBlock.pointBlock + (block.number - prevBlock.pointEndEthereumBlock) / BLOCK_STEP;
    }

    function getBlockTotalDeposits(uint256 ptr) public view returns (uint256[14] memory) {
        if (ptr >= arrayPointer)
            return totalDeposits;
        return history[ptr].totalDeposits;
    }

    function getPoolRewards(uint256 ptr) public view returns (uint256[14] memory) {
        if (miningFinished)
            return [uint256(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        if (ptr >= arrayPointer)
            return poolRewards;
        return history[ptr].poolRewards;
    }

    function getPointLength(uint256 ptr) public view returns (uint256) {  //
        if (ptr >= arrayPointer)
            return currentBlock() - history[arrayPointer-1].pointBlock;
        return history[ptr].pointLength;
    }

    function recordHistory() public returns (bool) {
        if (recordHistoryNeeded()) {
            _recordHistory();
            return true;
        }
        return false;
    }

    function recordHistoryNeeded() public view returns (bool) {
        return !miningFinished && lastRecordedBlock < currentBlock();
    }

    function _recordHistory() internal {
        // miningFinished check is in recordHistoryNeeded();

        uint256 currentBlk = currentBlock();

        BlockInfo memory prevBlock = history[arrayPointer-1];
        uint256 pointLength = currentBlk - prevBlock.pointBlock;
        history[arrayPointer].totalDeposits = totalDeposits;
        history[arrayPointer].poolRewards = poolRewards;
        history[arrayPointer].pointLength = pointLength;
        history[arrayPointer].blockStep = BLOCK_STEP;
        history[arrayPointer].pointBlock = currentBlk;
        history[arrayPointer].pointStartEthereumBlock = prevBlock.pointEndEthereumBlock;
        history[arrayPointer].pointEndEthereumBlock = prevBlock.pointEndEthereumBlock + pointLength * BLOCK_STEP;

        feesBalance += pointLength * feeAmount;

        arrayPointer++;
        lastRecordedBlock = currentBlk;
    }

    function getRewardSum(address sender) public view returns (uint256) {
        Investor memory investor = investors[sender];

        if (!investor.initialized || !canHarvest(sender))
            return 0;

        uint256[14] memory deposits = investor.deposits;

        uint256 reward = 0;

        for (uint256 i = investor.lastZeroPtr; i <= arrayPointer; i++) {
            uint256[14] memory poolRewards_ = getPoolRewards(i);
            uint256[14] memory totalDeposits_ = getBlockTotalDeposits(i);
            uint256 pointLength = getPointLength(i);
            for (uint256 j = 0; j < 14; j++) {
                uint256 td = totalDeposits_[j];
                if (td == 0) continue;
                uint256 pr = poolRewards_[j];
                uint256 d = deposits[j];
                reward += pr * pointLength * d / td;
            }
        }

        return reward;
    }

    function _deposit(uint256 tokenIndex, uint256 amount) internal {
        require(amount > 0, "Invalid amount");
        require(amount >= minDeposits[tokenIndex] || msg.sender == owner_, "Amount is too little");

        if (canHarvest(msg.sender))
            harvestReward();  // history is recorded while harvesting
        else
            recordHistory();

        require(tokens[tokenIndex].allowance(msg.sender, address(this)) >= amount, "Insufficient token allowance");
        investors[msg.sender].deposits[tokenIndex] += amount;
        totalDeposits[tokenIndex] += amount;
        tokens[tokenIndex].transferFrom(msg.sender, address(this), amount);

        investors[msg.sender].initialized = true;
        investors[msg.sender].lastZeroPtr = arrayPointer;
        investors[msg.sender].depositUnlockTime[tokenIndex] = block.timestamp + lockDurations[tokenIndex];
        emit Deposit(msg.sender, tokenIndex, amount);
    }

    function deposit0(uint256 amount) public {
        _deposit(0, amount);
    }

    function deposit1(uint256 amount) public {
        _deposit(1, amount);
    }

    function deposit2(uint256 amount) public {
        _deposit(2, amount);
    }

    function deposit3(uint256 amount) public {
        _deposit(3, amount);
    }

    function deposit4(uint256 amount) public {
        _deposit(4, amount);
    }

    function deposit5(uint256 amount) public {
        _deposit(5, amount);
    }

    function deposit6(uint256 amount) public {
        _deposit(6, amount);
    }

    function deposit7(uint256 amount) public {
        _deposit(7, amount);
    }

    function deposit8(uint256 amount) public {
        _deposit(8, amount);
    }

    function deposit9(uint256 amount) public {
        _deposit(9, amount);
    }

    function deposit10(uint256 amount) public {
        _deposit(10, amount);
    }

    function deposit11(uint256 amount) public {
        _deposit(11, amount);
    }

    function deposit12(uint256 amount) public {
        _deposit(12, amount);
    }

    function deposit13(uint256 amount) public {
        _deposit(13, amount);
    }

    function canHarvest(address sender) public view returns (bool) {
        Investor memory investor = investors[sender];
        return investor.deposits[0] + investor.deposits[1] +
               investor.deposits[2] + investor.deposits[3] +
               investor.deposits[4] + investor.deposits[5] +
               investor.deposits[6] + investor.deposits[7] +
               investor.deposits[8] + investor.deposits[9] +
               investor.deposits[10] + investor.deposits[11] +
               investor.deposits[12] + investor.deposits[13] > 0;
    }

    function harvestReward() public returns (uint256) {
        require(canHarvest(msg.sender));

        if (miningFinished)
            return 0;

        recordHistory();

        uint256 reward = getRewardSum(msg.sender);
        if (reward > MAX_SUPPLY - totalSupply)
            reward = MAX_SUPPLY - totalSupply;

        if (reward > 0)
            mint(msg.sender, reward);
        investors[msg.sender].lastZeroPtr = arrayPointer;
        emit Harvest(msg.sender, reward);

        if (totalSupply == MAX_SUPPLY) {
            recordHistory();
            miningFinished = true;
        }

        return reward;
    }

    function _withdraw(uint256 tokenIndex) internal returns (uint256 reward, uint256 value) {
        require(investors[msg.sender].deposits[tokenIndex] > 0, "Nothing to withdraw");
        require(investors[msg.sender].depositUnlockTime[tokenIndex] < block.timestamp, "This token could not be withdrawn right now, please wait for unlock");

        reward = harvestReward();
        value = investors[msg.sender].deposits[tokenIndex];

        emit Withdraw(msg.sender, tokenIndex, value);

        totalDeposits[tokenIndex] -= value;
        investors[msg.sender].deposits[tokenIndex] = 0;
        tokens[tokenIndex].transfer(msg.sender, value);
    }

    function withdraw0() public returns (uint256, uint256) {
        return _withdraw(0);
    }

    function withdraw1() public returns (uint256, uint256) {
        return _withdraw(1);
    }

    function withdraw2() public returns (uint256, uint256) {
        return _withdraw(2);
    }

    function withdraw3() public returns (uint256, uint256) {
        return _withdraw(3);
    }

    function withdraw4() public returns (uint256, uint256) {
        return _withdraw(4);
    }

    function withdraw5() public returns (uint256, uint256) {
        return _withdraw(5);
    }

    function withdraw6() public returns (uint256, uint256) {
        return _withdraw(6);
    }

    function withdraw7() public returns (uint256, uint256) {
        return _withdraw(7);
    }

    function withdraw8() public returns (uint256, uint256) {
        return _withdraw(8);
    }

    function withdraw9() public returns (uint256, uint256) {
        return _withdraw(9);
    }

    function withdraw10() public returns (uint256, uint256) {
        return _withdraw(10);
    }

    function withdraw11() public returns (uint256, uint256) {
        return _withdraw(11);
    }

    function withdraw12() public returns (uint256, uint256) {
        return _withdraw(12);
    }

    function withdraw13() public returns (uint256, uint256) {
        return _withdraw(13);
    }

    function sendFeeFunds(address to, uint256 amount) public onlyOwner {
        require(feesBalance >= amount, "Insufficient funds");

        _balanceOf[to] += amount;
        feesBalance -= amount;
        emit FeesSpent(to, amount);
    }

    function getInvestor(address addr) public view returns (uint256[14] memory deposits, uint256 lastZeroPtr, uint256[14] memory depositUnlockTime, bool initialized) {
        Investor memory investor = investors[addr];
        deposits = investor.deposits;
        lastZeroPtr = investor.lastZeroPtr;
        depositUnlockTime = investor.depositUnlockTime;
        initialized = investor.initialized;
    }

    /* function getRewardSumDebug() public returns (uint256) {
        return getRewardSum(msg.sender);
    }

    function getBlocks() public view returns (uint256) {
        return block.number;
    } */
}