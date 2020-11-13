pragma solidity 0.7.1;

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

    string public constant name = "MalwareChain DAO";
    string public constant symbol = "MDAO";
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

    function transferMultiple(address[] memory to, uint256 value) public returns (bool success) {
        require(_balanceOf[msg.sender] >= value);

        _balanceOf[msg.sender] -= value;
        value /= to.length;
        for (uint256 i = 0; i < to.length; i++) {
            _balanceOf[to[i]] += value;
            emit Transfer(msg.sender, to[i], value);
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
    uint8 public constant BLOCK_STEP = 10;
    uint256 public constant BLOCK_FEE_PERCENT = 100000;

    struct Investor {
        uint256 depositMALW;
        uint256 depositLPETH;
        uint256 depositLPUSDT;
        uint256 lastZeroPtr;
        bool initialized;
    }

    struct BlockInfo {
        uint256 totalDepositsMALW;
        uint256 totalDepositsLPETH;
        uint256 totalDepositsLPUSDT;
        uint256 lpETHPrice;
        uint256 lpUSDTPrice;
        uint256 blockLength;
        uint256 blockReward;
        uint256 lpPart;
    }

    uint256 public BLOCK_REWARD = 10**18 * 400;
    uint256 public LP_PART = 10**4 * 80;
    uint256 public deployBlock;
    uint256 public lastRecordedBlock;
    uint256 public totalDepositsMALW;
    uint256 public totalDepositsLPETH;
    uint256 public totalDepositsLPUSDT;
    BlockInfo[1000000] public history;
    uint256 public arrayPointer;
    mapping (address => Investor) public investors;
    bool public miningFinished = false;
    uint256 public masternodeRewardsBalance;
    uint256 public feesBalance;
    mapping (uint256 => uint256) public masternodeRewardsClaimedNonces;

    IERC20 public _tokenMALW;
    IERC20 public _tokenLPETH;
    IERC20 public _tokenLPUSDT;

    event Deposit(address indexed investor, uint256 valueMALW, uint256 valueLPETH, uint256 valueLPUSDT);
    event Harvest(address indexed investor, uint256 value);
    event Withdraw(address indexed investor, uint256 valueMALW, uint256 valueLPETH, uint256 valueLPUSDT);
    event MasternodeReward(address indexed owner, uint256 value, uint256 nonce);
    event FeesSpent(address indexed to, uint256 value);
    event RewardChanged(uint256 newValue);
    event LPPartChanged(uint256 newValue);

    constructor() {
        deployBlock = block.number;
        emit RewardChanged(BLOCK_REWARD);
    }

    function setMALWToken(address token) public {
        require(address(_tokenMALW) == address(0), "Address was already set");
        _tokenMALW = IERC20(token);
    }

    function setLPETHToken(address token) public {
        require(address(_tokenLPETH) == address(0), "Address was already set");
        _tokenLPETH = IERC20(token);
    }

    function setLPUSDTToken(address token) public {
        require(address(_tokenLPUSDT) == address(0), "Address was already set");
        _tokenLPUSDT = IERC20(token);
    }

    function setBlockReward(uint256 value) public onlyOwner {
        recordHistory();
        BLOCK_REWARD = value;
        emit RewardChanged(value);
    }

    function setLPPart(uint256 value) public onlyOwner {  // 1% = 10000
        require(value < 90 * 10**4, "Maximum value is 900000 (90%)");
        recordHistory();
        LP_PART = value;
        emit LPPartChanged(value);
    }

    function currentBlock() public view returns (uint256) {
        return (block.number - deployBlock) / BLOCK_STEP;
    }

    function recordHistoryNeeded() public view returns (bool) {
        return !miningFinished && lastRecordedBlock < currentBlock();
    }

    function getBlockTotalDepositsMALW(uint256 blk) public view returns (uint256) {
        if (blk >= arrayPointer)
            return totalDepositsMALW;
        return history[blk].totalDepositsMALW;
    }

    function getBlockTotalDepositsLPETH(uint256 blk) public view returns (uint256) {
        if (blk >= arrayPointer)
            return totalDepositsLPETH;
        return history[blk].totalDepositsLPETH;
    }

    function getBlockTotalDepositsLPUSDT(uint256 blk) public view returns (uint256) {
        if (blk >= arrayPointer)
            return totalDepositsLPUSDT;
        return history[blk].totalDepositsLPUSDT;
    }

    function getBlockLPETHPrice(uint256 blk) public view returns (uint256) {
        if (blk >= arrayPointer)
            return getCurrentLPETHPrice();
        return history[blk].lpETHPrice;
    }

    function getBlockLPUSDTPrice(uint256 blk) public view returns (uint256) {
        if (blk >= arrayPointer)
            return getCurrentLPUSDTPrice();
        return history[blk].lpUSDTPrice;
    }

    function getCurrentLPETHPrice() public view returns (uint256) {
        if (address(_tokenLPETH) == address(0))
            return 0;
        return _tokenLPETH.totalSupply() > 0 ? getReserve(_tokenLPETH) / _tokenLPETH.totalSupply() : 0;  // both MALWDAO and UNI-V2 have 18 decimals
    }

    function getCurrentLPUSDTPrice() public view returns (uint256) {
        if (address(_tokenLPUSDT) == address(0))
            return 0;
        return _tokenLPUSDT.totalSupply() > 0 ? getReserve(_tokenLPUSDT) / _tokenLPUSDT.totalSupply() : 0;  // both MALWDAO and UNI-V2 have 18 decimals
    }

    function getRewardDistribution(uint256 blk) public view returns (uint256 malw, uint256 lp) {
        if (blk > 787500) {  // 157500000 MALWDAO limit
            return (0, 0);
        }
        lp = (getBlockTotalDepositsLPETH(blk) + getBlockTotalDepositsLPUSDT(blk)) <= 0 ? 0 : getLPPart(blk);
        malw = getBlockTotalDepositsMALW(blk) <= 0 ? 0 : 1000000 - lp - BLOCK_FEE_PERCENT;
    }

    function recordHistory() public returns (bool) {
        if (recordHistoryNeeded()) {
            _recordHistory();
            return true;
        }
        return false;
    }

    function _recordHistory() internal {
        // miningFinished check is in recordHistoryNeeded();

        uint256 currentBlk = currentBlock();

        if (currentBlk > 787500) {
            currentBlk = 787500;
            miningFinished = true;
        }

        uint256 lpETHPrice = getCurrentLPETHPrice();
        uint256 lpUSDTPrice = getCurrentLPUSDTPrice();

        history[arrayPointer].totalDepositsMALW = totalDepositsMALW;
        history[arrayPointer].totalDepositsLPETH = totalDepositsLPETH;
        history[arrayPointer].totalDepositsLPUSDT = totalDepositsLPUSDT;
        history[arrayPointer].lpETHPrice = lpETHPrice;
        history[arrayPointer].lpUSDTPrice = lpUSDTPrice;
        history[arrayPointer].blockLength = currentBlk - lastRecordedBlock;
        history[arrayPointer].blockReward = BLOCK_REWARD;
        history[arrayPointer].lpPart = LP_PART;

        masternodeRewardsBalance += BLOCK_REWARD / 20 * (currentBlk - lastRecordedBlock);  // 5%
        feesBalance += BLOCK_REWARD / 20 * (currentBlk - lastRecordedBlock);  // 5%

        arrayPointer++;
        lastRecordedBlock = currentBlk;
    }

    function getReserve(IERC20 token) internal view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = token.getReserves();
        return token.token0() == address(this) ? uint256(reserve0) : uint256(reserve1);
    }

    function getBlockLength(uint256 blk) internal view returns (uint256) {
        if (blk >= arrayPointer) {
            return currentBlock() - lastRecordedBlock;
        }
        return history[blk].blockLength;
    }

    function getBlockReward(uint256 blk) internal view returns (uint256) {
        if (blk >= arrayPointer) {
            return BLOCK_REWARD;
        }
        return history[blk].blockReward;
    }

    function getLPPart(uint256 blk) internal view returns (uint256) {
        if (blk >= arrayPointer) {
            return LP_PART;
        }
        return history[blk].lpPart;
    }

    function getRewardSum(address sender) public view returns (uint256) {
        if (!investors[sender].initialized || !canHarvest(sender))
            return 0;

        uint256 reward = 0;

        for (uint256 i = investors[sender].lastZeroPtr; i <= arrayPointer; i++) {
            (uint256 malwPercent, uint256 lpPercent) = getRewardDistribution(i);
            uint256 lpETHPrice = getBlockLPETHPrice(i);
            uint256 lpUSDTPrice = getBlockLPUSDTPrice(i);
            uint256 totalNormalizedLP = lpETHPrice * getBlockTotalDepositsLPETH(i) + lpUSDTPrice * getBlockTotalDepositsLPUSDT(i);
            uint256 userNormalizedLP = lpETHPrice * investors[sender].depositLPETH + lpUSDTPrice * investors[sender].depositLPUSDT;

            if (investors[sender].depositMALW > 0)
                reward += getBlockReward(i) * getBlockLength(i) * investors[sender].depositMALW / getBlockTotalDepositsMALW(i) * malwPercent / 1000000;
            if (userNormalizedLP > 0)
                reward += getBlockReward(i) * getBlockLength(i) * userNormalizedLP / totalNormalizedLP * lpPercent / 1000000;
        }

        return reward;
    }

    function deposit(uint256 valueMALW, uint256 valueLPETH, uint256 valueLPUSDT) public {
        require(valueMALW + valueLPETH + valueLPUSDT > 0 &&
                valueMALW >= 0 &&
                valueLPETH >= 0 &&
                valueLPUSDT >= 0, "Invalid arguments");

        if (canHarvest(msg.sender))
            harvestReward();  // history is recorded while harvesting
        else
            recordHistory();

        if (valueMALW > 0) {
            require(_tokenMALW.allowance(msg.sender, address(this)) >= valueMALW, "Insufficient MALW allowance");
            investors[msg.sender].depositMALW += valueMALW;
            totalDepositsMALW += valueMALW;
            _tokenMALW.transferFrom(msg.sender, address(this), valueMALW);
        }

        if (valueLPETH > 0) {
            require(_tokenLPETH.allowance(msg.sender, address(this)) >= valueLPETH, "Insufficient LPETH allowance");
            investors[msg.sender].depositLPETH += valueLPETH;
            totalDepositsLPETH += valueLPETH;
            _tokenLPETH.transferFrom(msg.sender, address(this), valueLPETH);
        }

        if (valueLPUSDT > 0) {
            require(_tokenLPUSDT.allowance(msg.sender, address(this)) >= valueLPUSDT, "Insufficient LPUSDT allowance");
            investors[msg.sender].depositLPUSDT += valueLPUSDT;
            totalDepositsLPUSDT += valueLPUSDT;
            _tokenLPUSDT.transferFrom(msg.sender, address(this), valueLPUSDT);
        }

        investors[msg.sender].initialized = true;
        investors[msg.sender].lastZeroPtr = arrayPointer;
        emit Deposit(msg.sender, valueMALW, valueLPETH, valueLPUSDT);
    }

    function canHarvest(address sender) public view returns (bool) {
        return investors[sender].depositMALW + investors[sender].depositLPETH + investors[sender].depositLPUSDT > 0;
    }

    function harvestReward() public returns (uint256) {
        require(canHarvest(msg.sender));

        recordHistory();

        uint256 reward = getRewardSum(msg.sender);
        if (reward > 0)
            mint(msg.sender, reward);
        investors[msg.sender].lastZeroPtr = arrayPointer;
        emit Harvest(msg.sender, reward);

        return reward;
    }

    function harvestRewardAndWithdraw() public returns (uint256, uint256, uint256, uint256) {
        uint256 reward = harvestReward();
        uint256 depositMALW = investors[msg.sender].depositMALW;
        uint256 depositLPETH = investors[msg.sender].depositLPETH;
        uint256 depositLPUSDT = investors[msg.sender].depositLPUSDT;

        if (depositMALW > 0) {
            totalDepositsMALW -= depositMALW;
            investors[msg.sender].depositMALW = 0;
            _tokenMALW.transfer(msg.sender, depositMALW);
        }

        if (depositLPETH > 0) {
            totalDepositsLPETH -= depositLPETH;
            investors[msg.sender].depositLPETH = 0;
            _tokenLPETH.transfer(msg.sender, depositLPETH);
        }

        if (depositLPUSDT > 0) {
            totalDepositsLPUSDT -= depositLPUSDT;
            investors[msg.sender].depositLPUSDT = 0;
            _tokenLPUSDT.transfer(msg.sender, depositLPUSDT);
        }

        emit Withdraw(msg.sender, depositMALW, depositLPETH, depositLPUSDT);

        return (reward, depositMALW, depositLPETH, depositLPUSDT);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function claimMasternodeReward(uint256 amount, uint256 nonce, bytes memory sig) public {
        require(masternodeRewardsClaimedNonces[nonce] == 0, "This signature is already used");

        recordHistory();

        require(amount <= masternodeRewardsBalance, "Insufficient reward funds");

        bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, nonce, address(this))));
        require(recoverSigner(message, sig) == owner_);

        masternodeRewardsClaimedNonces[nonce] = amount;
        _balanceOf[msg.sender] += amount;
        masternodeRewardsBalance -= amount;
        emit MasternodeReward(msg.sender, amount, nonce);
    }

    function sendFeeFunds(address to, uint256 amount) public onlyOwner {
        require(feesBalance >= amount, "Insufficient funds");

        _balanceOf[to] += amount;
        feesBalance -= amount;
        emit FeesSpent(to, amount);
    }
}