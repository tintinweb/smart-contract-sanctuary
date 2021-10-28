/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

pragma solidity ^0.4.24;

/**
 * Math operations with safety checks
 */
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal view returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal view returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal view returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal view returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    function safePercent(uint256 a, uint256 b) internal view returns (uint256) {
        return safeDiv(safeMul(a, b), 100);
    }

    function assert(bool assertion) internal view {
        if (!assertion) {
            throw;
        }
    }
}

contract EIP20Interface {

    uint256 public totalSupply;

    uint8 public decimals;

    function balanceOf(address _owner) public view returns (uint256 balance);


    function transfer(address _to, uint256 _value) public;


    function transferFrom(address _from, address _to, uint256 _value) public;


    function approve(address _spender, uint256 _value) public returns (bool success);


    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    function burn(uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ErrorReporter {
    event Failure(uint error);
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        CARD_SOLD_OUT,
        CARD_NOT_EXIST,
        LEVEL_IS_TOP,
        INSUFFICIENT_BALANCE,
        MINING,
        MIN_LIMIT,
        ALREADY_WITHDRAWAL,
        NOT_COMMISSION,
        CONTRACT_PAUSED
    }
    function fail(Error err) internal returns (uint) {
        emit Failure(uint(err));

        return uint(err);
    }
}

contract Game is SafeMath, ErrorReporter {

    struct TotalPower {
        uint256 currentPower;  //当前总算力
        uint256 startBlock;    // 开始计算收益区块；
    }

    struct BlockStep {
        uint256 stepLength;     // 总步长  10 个周期
        uint256 mineBlockNum;   // 挖矿时长28800块 = 24小时
        uint256 gameProfitRate;    // 游戏收益比例   50%
        uint256 mineProfitRate;    // 挖矿收益比例   25%

    }

    mapping(uint256 => address)  public file;
    mapping(uint256 => uint8)  public level;
    mapping(uint256 => uint8)  public gender;
    mapping(uint256 => uint256)  public birthday;
    mapping(uint256 => uint256)  public cardPower;
    mapping(uint256 => uint256)  public cardBlock;
    mapping(uint256 => uint256)  public cardBlockIndex;
    mapping(uint256 => uint256)  public cardPowerRate;
    mapping(uint256 => uint256)  public gameProfit;
    mapping(uint256 => uint256)  public mineCardPower;
    mapping(uint256 => uint256)  public mineBlock;
    mapping(uint256 => uint256)  public mineProfit;
    mapping(uint256 => uint256)  public cardMineBlockIndex;
    mapping(uint256 => uint256)  public withdrawProfit;
    mapping(address => uint256[]) public userCard;

    uint256 public cardAmount;
    uint256 public cardIndex;

    TotalPower public totalPower;
    mapping(uint256 => uint256) public blockTotalPower;  // 块对应的总算力
    uint256[] public powerBlocks;   // 算力变化的块号

    BlockStep public blockStep;
    mapping(uint256 => uint256) public stepBlock;  // 每步对应的块号 11个 [0, 403200, 806400, 1209600, 1612800, 2016000, 2419200, 2822400, 3225600, 3628800, 4032000]
    mapping(uint256 => uint256) public stepProfit; // 每步对应的收益 10个 [1500000000, 1350000000, 1200000000, 1049999999, 900000000, 750000000, 599999999, 449999999, 299999999, 149999999]

    address public admin;

    uint256 powerDecimals;
    uint256 initPower;

    EIP20Interface public buyToken;
    uint256 public buyTokenDecimals;
    uint256 tokenDecimals;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public debugBlockNum;

    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(uint256 => uint256)) public freezeOf;
    mapping(address => mapping(address => uint256)) public allowance;



    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);


    constructor() public {
        admin = msg.sender;
        _balanceOf[msg.sender] = 100000000000000000;
        totalSupply = 100000000000000000;
        // Update total supply
        name = "LULU";
        // Set the name for display purposes
        symbol = "LULU";
        // Set the symbol for display purposes
        decimals = 8;
        // Amount of decimals for display purposes
        admin = msg.sender;
        tokenDecimals = 100000000;
        blockStep.gameProfitRate = 50;
        blockStep.mineProfitRate = 25;
        blockStep.mineBlockNum = 28800;
        cardAmount = 1000;
        cardIndex = 0;

        powerDecimals = 100000000;
        initPower = 500;
        debugBlockNum = block.number;

    }

    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    function setBlockNumber(uint256 num) public returns (uint){
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED);
        }
        debugBlockNum = num;
        return uint(Error.NO_ERROR);
    }

    function getEndMineBlock(address user, uint256 cardNum) public view returns (uint256){
        uint256 userCardIndex = userCard[user][cardNum];
        return safeAdd(mineBlock[userCardIndex], blockStep.mineBlockNum);
    }


    function balanceOf(address user) public view returns (uint256){
        uint256 balance = _balanceOf[user];
        uint256 i = 0;
        for (i = 0; i < userCard[user].length; i++) {
            if (getBlockNumber() > getEndMineBlock(user, i) && freezeOf[user][i] > 0) {
                balance = safeAdd(balance, freezeOf[user][i]);
            }
        }
        return balance;
    }

    function checkBalanceOf(address user) public returns (uint256){
        uint256 balance = _balanceOf[user];
        uint256 i = 0;
        for (i = 0; i < userCard[user].length; i++) {
            if (getBlockNumber() > getEndMineBlock(user, i) && freezeOf[user][i] > 0) {
                balance = safeAdd(balance, freezeOf[user][i]);
                freezeOf[user][i] = 0;
            }
        }
        return balance;
    }


    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        if (_to == 0x0) throw;
        // Prevent transfer to 0x0 address. Use burn() instead
        if (_value <= 0) throw;
        if (balanceOf(msg.sender) < _value) throw;
        // Check if the sender has enough
        if (_balanceOf[_to] + _value < _balanceOf[_to]) throw;
        // Check for overflows
        _balanceOf[msg.sender] = SafeMath.safeSub(checkBalanceOf(msg.sender), _value);
        // Subtract from the sender
        _balanceOf[_to] = SafeMath.safeAdd(_balanceOf[_to], _value);
        // Add the same to the recipient
        Transfer(msg.sender, _to, _value);
        // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value <= 0) throw;
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == 0x0) throw;
        // Prevent transfer to 0x0 address. Use burn() instead
        if (_value <= 0) throw;
        if (balanceOf(_from) < _value) throw;
        // Check if the sender has enough
        if (_balanceOf[_to] + _value < _balanceOf[_to]) throw;
        // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;
        // Check allowance
        _balanceOf[_from] = SafeMath.safeSub(checkBalanceOf(_from), _value);
        // Subtract from the sender
        _balanceOf[_to] = SafeMath.safeAdd(_balanceOf[_to], _value);
        // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function _burn(address user, uint256 _value) internal returns (bool success){
        if (balanceOf(user) < _value) throw;
        // Check if the sender has enough
        if (_value <= 0) throw;
        _balanceOf[user] = SafeMath.safeSub(checkBalanceOf(user), _value);
        // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply, _value);
        // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        return _burn(msg.sender, _value);
    }

    function _freeze(address user, uint256 cardNum, uint256 _value, uint256 endBlock) internal returns (bool success) {
        if (balanceOf(user) < _value) throw;
        if (freezeOf[user][cardNum] != 0) throw;
        // Check if the sender has enough
        if (_value <= 0) throw;
        _balanceOf[user] = SafeMath.safeSub(checkBalanceOf(user), _value);
        // Subtract from the sender
        freezeOf[user][cardNum] = _value;
        // Updates totalSupply
        Freeze(user, _value);
        return true;
    }

    function _unfreeze(address user, uint256 cardNum) internal returns (bool success) {
        if (freezeOf[user][cardNum] > 0) {
            uint256 amount = freezeOf[user][cardNum];
            freezeOf[user][cardNum] = 0;
            _balanceOf[user] = SafeMath.safeAdd(_balanceOf[user], amount);
            Unfreeze(msg.sender, amount);
        }
        return true;
    }


    function setBuyToken(address _value, uint256 _decimals) public returns (uint){
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED);
        }
        buyToken = EIP20Interface(_value);
        buyTokenDecimals = _decimals;
        return uint(Error.NO_ERROR);
    }

    function setCardAmount(uint256 amount) public returns (uint){
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED);
        }
        cardAmount = amount;
        return uint(Error.NO_ERROR);
    }

    function setPower(uint256 initPower, uint256 powerDecimals) public returns (uint){
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED);
        }
        powerDecimals = powerDecimals;
        initPower = initPower;
        return uint(Error.NO_ERROR);
    }


    function rand(uint256 _length) public view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)));
        return random % _length;
    }

    function getPowerRate() public view returns (uint256){
        uint256 randNum = rand(1000);
        if (randNum < 950) {
            return 100;
        } else if (randNum < 980) {
            return 110;
        } else if (randNum < 995) {
            return 120;
        } else {
            return 130;
        }
    }

    function getCardCount(address hold) public view returns (uint256) {
        return userCard[hold].length;
    }

    function getLevel(address hold, uint256 cardNum) public view returns (uint256) {
        uint256 userCardIndex = userCard[hold][cardNum];
        return level[userCardIndex];
    }

    function setStepBlock(uint256[] _stepBlock, uint256[] _stepProfit) public returns (uint) {
        require(_stepBlock.length == _stepProfit.length + 1);
        require(admin == msg.sender);
        uint256 i = 0;
        blockStep.stepLength = _stepProfit.length;
        for (i = 0; i < _stepProfit.length; i++) {
            stepProfit[i] = _stepProfit[i];
        }
        for (i = 0; i < _stepBlock.length; i++) {
            stepBlock[i] = _stepBlock[i];
        }
        return 0;
    }

    function getPassBlock(uint256 blockNum) public view returns (uint) {
        return safeSub(blockNum, totalPower.startBlock);
    }


    function calculateBlockProfit(uint256 start, uint256 end) public view returns (uint256){
        uint256 i = 0;
        uint256 profit = 0;
        uint256 currentBlock;
        start = getPassBlock(start);
        end = getPassBlock(end);
        for (i = 0; i < blockStep.stepLength; i++) {
            if (start >= stepBlock[i] && start < stepBlock[i + 1]) {
                if (end <= stepBlock[i + 1]) {
                    profit += stepProfit[i] * (end - start);
                    return profit;
                } else {
                    profit += stepProfit[i] * (stepBlock[i + 1] - start);
                    start = stepBlock[i + 1];
                }
            }
        }
        return profit;
    }

    function calculateGameBlockProfit(uint256 start, uint256 end) public view returns (uint256){
        uint256 blockProfit = calculateBlockProfit(start, end);
        return safeDiv(safeMul(blockProfit, blockStep.gameProfitRate), 100);
    }

    function calculateMineBlockProfit(uint256 start, uint256 end) public view returns (uint256){
        uint256 blockProfit = calculateBlockProfit(start, end);
        return safeDiv(safeMul(blockProfit, blockStep.mineProfitRate), 100);
    }

    function calculateCardProfit(address hold, uint256 cardNum) public view returns (uint256) {
        uint256 profit = 0;
        uint256 j = 0;
        uint256 lastBlockPower = 0;
        uint256 lastBlock = 0;
        uint256 blockProfit = 0;
        uint256 userCardIndex = userCard[hold][cardNum];
        profit = gameProfit[userCardIndex];
        if (cardPower[userCardIndex] == 0 || totalPower.currentPower == 0) {
            return 0;
        }
        lastBlock = cardBlock[userCardIndex];
        lastBlockPower = blockTotalPower[powerBlocks[cardBlockIndex[userCardIndex]]];
        for (j = cardBlockIndex[userCardIndex]; j < powerBlocks.length; j++) {

            if (powerBlocks[j] <= lastBlock) {
                lastBlockPower = blockTotalPower[powerBlocks[j]];
                continue;
            }

            blockProfit = calculateGameBlockProfit(lastBlock, powerBlocks[j]);
            profit += blockProfit * cardPowerRate[userCardIndex] * cardPower[userCardIndex] / (lastBlockPower * 100);
            lastBlock = powerBlocks[j];
            lastBlockPower = blockTotalPower[powerBlocks[j]];
        }
        blockProfit = calculateGameBlockProfit(lastBlock, getBlockNumber());
        profit += blockProfit * cardPowerRate[userCardIndex] * cardPower[userCardIndex] / (lastBlockPower * 100);

        return profit;
    }

    function calculateMineProfit(address hold, uint256 cardNum) public view returns (uint256){
        uint256 profit = 0;
        uint256 j = 0;
        uint256 lastBlockPower = 0;
        uint256 lastBlock = 0;
        uint256 blockProfit = 0;
        uint256 userCardIndex = userCard[hold][cardNum];
        profit = mineProfit[userCardIndex];
        if (mineCardPower[userCardIndex] == 0 || totalPower.currentPower == 0) {
            return 0;
        }
        lastBlock = mineBlock[userCardIndex];
        lastBlockPower = blockTotalPower[powerBlocks[cardMineBlockIndex[userCardIndex]]];
        for (j = cardMineBlockIndex[userCardIndex]; j < powerBlocks.length; j++) {

            if (powerBlocks[j] <= lastBlock) {
                lastBlockPower = blockTotalPower[powerBlocks[j]];
                continue;
            }
            uint256 endBlock = powerBlocks[j];

            if (powerBlocks[j] > mineBlock[userCardIndex] + blockStep.mineBlockNum) {
                endBlock = mineBlock[userCardIndex] + blockStep.mineBlockNum;
            }

            blockProfit = calculateMineBlockProfit(lastBlock, endBlock);
            profit += blockProfit * cardPowerRate[userCardIndex] * mineCardPower[userCardIndex] / (lastBlockPower * 100);
            if (endBlock >= mineBlock[userCardIndex] + blockStep.mineBlockNum) {
                return profit;
            }
            lastBlock = powerBlocks[j];
            lastBlockPower = blockTotalPower[powerBlocks[j]];
        }
        endBlock = getBlockNumber();
        if (endBlock > mineBlock[userCardIndex] + blockStep.mineBlockNum) {
            endBlock = mineBlock[userCardIndex] + blockStep.mineBlockNum;
        }
        blockProfit = calculateMineBlockProfit(lastBlock, endBlock);
        profit += blockProfit * cardPowerRate[userCardIndex] * mineCardPower[userCardIndex] / (lastBlockPower * 100);


        return profit;
    }

    function getGameProfit(address user) public view returns (uint256){
        uint256 profit = 0;
        uint256 i = 0;
        if (userCard[user].length == 0) {
            return 0;
        }
        for (i = 0; i < userCard[user].length; i++) {
            profit += calculateCardProfit(user, i);
        }
        return profit;
    }

    function getMineProfit(address user) public view returns (uint256){
        uint256 profit = 0;
        uint256 i = 0;
        if (userCard[user].length == 0) {
            return 0;
        }
        for (i = 0; i < userCard[user].length; i++) {
            profit += calculateMineProfit(user, i);
        }
        return profit;
    }

    function getWithdrawProfit(address user) public view returns (uint256){
        uint256 profit = 0;
        uint256 i = 0;
        if (userCard[user].length == 0) {
            return 0;
        }
        for (i = 0; i < userCard[user].length; i++) {
            profit += withdrawProfit[userCard[user][i]];
        }
        return profit;
    }

    function buyCard(address _file) public returns (uint){
        uint256 priceAmount = 252 * buyTokenDecimals;
        if (buyToken.allowance(msg.sender, address(this)) < priceAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_ALLOWANCE);
        }
        if (buyToken.balanceOf(msg.sender) < priceAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_BALANCE);
        }
        if (cardIndex >= cardAmount) {
            return fail(Error.CARD_SOLD_OUT);
        }
        buyToken.transferFrom(msg.sender, address(admin), priceAmount);

        file[cardIndex] = _file;
        cardBlock[cardIndex] = getBlockNumber();
        cardPowerRate[cardIndex] = getPowerRate();
        level[cardIndex] = 1;
        cardPower[cardIndex] = initPower * powerDecimals;
        cardBlockIndex[cardIndex] = powerBlocks.length;
        gameProfit[cardIndex] = 0;
        mineCardPower[cardIndex] = 0;
        mineBlock[cardIndex] = 0;
        mineProfit[cardIndex] = 0;
        cardMineBlockIndex[cardIndex] = 0;
        withdrawProfit[cardIndex] = 0;
        gender[cardIndex] = uint8(rand(2));
        birthday[cardIndex] = now;

        totalPower.currentPower += cardPower[cardIndex];
        blockTotalPower[getBlockNumber()] = totalPower.currentPower;
        powerBlocks.push(getBlockNumber());
        if (totalPower.startBlock == 0) {
            totalPower.startBlock = getBlockNumber();
        }
        userCard[msg.sender].push(cardIndex);
        cardIndex = safeAdd(cardIndex, 1);
        return uint(Error.NO_ERROR);
    }

    function getUpgradePrice(address user, uint256 cardNum) public view returns (uint256){
        uint256 i = 0;
        uint256 userCardIndex = userCard[user][cardNum];
        uint256 amount = 0;
        if (level[userCardIndex] == 0) {
            return 0;
        }

        amount = 300 * powerDecimals;
        for (i = 0; i < level[userCardIndex] - 1; i++) {
            amount += amount * 16 / 100;
        }
        return amount;
    }

    function upgradeCard(uint256 cardNum) public returns (uint){
        uint256 userCardIndex = userCard[msg.sender][cardNum];
        if (level[userCardIndex] == 0) {
            return fail(Error.CARD_NOT_EXIST);
        }
        if (level[userCardIndex] >= 50) {
            return fail(Error.LEVEL_IS_TOP);
        }
        uint256 priceAmount = getUpgradePrice(msg.sender, cardNum);
        if (balanceOf(msg.sender) < priceAmount) {
            return fail(Error.INSUFFICIENT_BALANCE);
        }
        _burn(msg.sender, priceAmount);

        uint256 upgradePower = cardPower[userCardIndex] * 9 / 100;
        gameProfit[userCardIndex] = safeAdd(calculateCardProfit(msg.sender, cardNum), gameProfit[userCardIndex]);
        cardBlock[userCardIndex] = getBlockNumber();
        level[userCardIndex] = level[userCardIndex] + 1;
        cardPower[userCardIndex] = safeAdd(upgradePower, cardPower[userCardIndex]);
        cardBlockIndex[userCardIndex] = powerBlocks.length;

        totalPower.currentPower = safeAdd(totalPower.currentPower, upgradePower);
        blockTotalPower[getBlockNumber()] = totalPower.currentPower;
        powerBlocks.push(getBlockNumber());


        return uint(Error.NO_ERROR);
    }

    function getMineAmount(address user, uint256 cardNum) public view returns (uint256){
        uint256 i = 0;
        uint256 userCardIndex = userCard[user][cardNum];
        uint256 amount = 0;
        if (level[userCardIndex] == 0) {
            return 0;
        }
        amount = 2500 + 500 * (level[userCardIndex] - 1);
        amount = amount * powerDecimals;
        return amount;
    }

    function isMine(address user, uint256 cardNum) public view returns (bool){
        uint256 userCardIndex = userCard[user][cardNum];
        return mineBlock[userCardIndex] != 0 && getEndMineBlock(user, cardNum) > getBlockNumber();
    }

    function getFreezeOf(address user) public view returns (uint256){
        uint256 amount = 0;
        uint256 i = 0;
        for (i = 0; i < userCard[user].length; i++) {
            if (isMine(user, i) && freezeOf[user][i] > 0) {
                amount = safeAdd(amount, freezeOf[user][i]);
            }
        }
        return amount;
    }


    function startMine(uint256 cardNum) public returns (uint){
        uint256 userCardIndex = userCard[msg.sender][cardNum];
        if (level[userCardIndex] == 0) {
            return fail(Error.CARD_NOT_EXIST);
        }
        if (isMine(msg.sender, cardNum)) {
            return fail(Error.MINING);
        }
        uint256 amount = getMineAmount(msg.sender, cardNum);
        if (balanceOf(msg.sender) < amount) {
            return fail(Error.INSUFFICIENT_BALANCE);
        }
        _unfreeze(msg.sender, cardNum);
        _freeze(msg.sender, cardNum, amount, getBlockNumber() + blockStep.mineBlockNum);

        mineProfit[userCardIndex] += calculateMineProfit(msg.sender, cardNum);
        mineBlock[userCardIndex] = getBlockNumber();
        mineCardPower[userCardIndex] = cardPower[userCardIndex];
        cardMineBlockIndex[userCardIndex] = cardBlockIndex[userCardIndex];
        return uint(Error.NO_ERROR);
    }

    function stopMine(uint256 cardNum) public returns (uint){
        if (isMine(msg.sender, cardNum)) {
            uint256 userCardIndex = userCard[msg.sender][cardNum];
            _unfreeze(msg.sender, cardNum);
            mineBlock[userCardIndex] = 0;
            mineCardPower[userCardIndex] = 0;
        }

        return uint(Error.NO_ERROR);
    }

    function withdrawGameProfit() public returns (uint){
        uint256 profit = 0;
        uint256 i = 0;
        if (userCard[msg.sender].length == 0) {
            return fail(Error.CARD_NOT_EXIST);
        }
        for (i = 0; i < userCard[msg.sender].length; i++) {
            gameProfit[userCard[msg.sender][i]] = calculateCardProfit(msg.sender, i);
            withdrawProfit[userCard[msg.sender][i]] += gameProfit[userCard[msg.sender][i]];
            profit += gameProfit[userCard[msg.sender][i]];
            gameProfit[userCard[msg.sender][i]] = 0;
            cardBlock[userCard[msg.sender][i]] = getBlockNumber();
            cardBlockIndex[userCard[msg.sender][i]] = powerBlocks.length - 1;

        }

        if (profit > 0) {
            if (balanceOf(admin) < profit) throw;
            if (_balanceOf[msg.sender] + profit < _balanceOf[msg.sender]) throw;
            _balanceOf[admin] = SafeMath.safeSub(checkBalanceOf(admin), profit);
            _balanceOf[msg.sender] = SafeMath.safeAdd(_balanceOf[msg.sender], profit);
            Transfer(admin, msg.sender, profit);

        }

        return uint(Error.NO_ERROR);
    }

    function withdrawMineProfit() public returns (uint){
        uint256 profit = 0;
        uint256 i = 0;
        if (userCard[msg.sender].length == 0) {
            return fail(Error.CARD_NOT_EXIST);
        }
        for (i = 0; i < userCard[msg.sender].length; i++) {
            uint256 userCardIndex = userCard[msg.sender][i];
            if (mineBlock[userCardIndex] != 0 && getEndMineBlock(msg.sender, i) < getBlockNumber()) {
                mineProfit[userCardIndex] = calculateMineProfit(msg.sender, i);
                mineBlock[userCardIndex] = 0;
                mineCardPower[userCardIndex] = 0;
            }

            withdrawProfit[userCardIndex] += mineProfit[userCardIndex];
            profit += mineProfit[userCardIndex];
            mineProfit[userCardIndex] = 0;

        }

        if (profit > 0) {
            if (balanceOf(admin) < profit) throw;
            if (_balanceOf[msg.sender] + profit < _balanceOf[msg.sender]) throw;
            _balanceOf[admin] = SafeMath.safeSub(checkBalanceOf(admin), profit);
            _balanceOf[msg.sender] = SafeMath.safeAdd(_balanceOf[msg.sender], profit);
            Transfer(admin, msg.sender, profit);

        }

        return uint(Error.NO_ERROR);
    }

}