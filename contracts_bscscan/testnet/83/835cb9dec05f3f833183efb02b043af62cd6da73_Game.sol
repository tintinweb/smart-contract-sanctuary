/**
 *Submitted for verification at BscScan.com on 2021-10-21
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
        mapping(uint256 => uint256) blockTotalPower;  // 块对应的总算力
        uint256[] blocks;   // 算力变化的块号
        uint256 startBlock;    // 开始计算收益区块；
    }

    struct CardPower {
        address file;
        uint8 level;       // 卡级别
        uint256 cardPower;  // 持有卡的级别
        uint256 cardBlock;  // 持有卡的区块号
        uint256 cardBlockIndex;  // 持有卡的区块号的索引
        uint256 cardPowerRate;  // 卡算力增加倍数  100、110、120、130 除以 100
        //        uint8 cardType;       // 卡类型
        uint256 gameProfit;         // 挖矿收益
        uint256 mineCardPower;      // 挖矿时的算力
        uint256 mineBlock;  // 开始挖矿号
        uint256 mineProfit;         // 收益
        uint256 cardMineBlockIndex;  // 持有卡的区块号的索引
        uint256 withdrawProfit;      // 已经提取收益
    }

    struct BlockStep {
        uint256 stepLength;     // 总步长  10 个周期
        uint256 mineBlockNum;   // 挖矿时长28800块 = 24小时
        uint256 gameProfitRate;    // 游戏收益比例   50%
        uint256 mineProfitRate;    // 挖矿收益比例   25%
        mapping(uint256 => uint256) stepBlock;  // 每步对应的块号 11个 [0, 403200, 806400, 1209600, 1612800, 2016000, 2419200, 2822400, 3225600, 3628800, 4032000]
        mapping(uint256 => uint256) stepProfit; // 每步对应的收益 10个 [1500000000, 1350000000, 1200000000, 1049999999, 900000000, 750000000, 599999999, 449999999, 299999999, 149999999]
    }


    uint256 public cardAmount;
    TotalPower public totalPower;
    BlockStep blockStep;
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

    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(uint256 => uint256)) public freezeOf;
    //    mapping(address => mapping(uint256 => uint256)) public unfreezeBlock;
    mapping(address => mapping(address => uint256)) public allowance;


    mapping(address => CardPower[])  public cardHold;    // 升级后存进的收益

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

    }

    function getEndMineBlock(address user, uint256 cardNum) public view returns (uint256){
        CardPower card = cardHold[msg.sender][cardNum];

        return safeAdd(card.mineBlock, block.number);
    }

    function balanceOf(address user) public view returns (uint256){
        uint256 balance = _balanceOf[user];
        uint256 i = 0;
        for (i = 0; i < cardHold[user].length; i++) {
            if (block.number > getEndMineBlock(user, i) && freezeOf[user][i] > 0) {
                balance = safeAdd(balance, freezeOf[user][i]);
            }
        }
        return balance;
    }

    function checkBalanceOf(address user) public returns (uint256){
        uint256 balance = _balanceOf[user];
        uint256 i = 0;
        for (i = 0; i < cardHold[user].length; i++) {
            if (block.number > getEndMineBlock(user, i) && freezeOf[user][i] > 0) {
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


    function setBuyToken(address value, uint256 Decimals) public returns (uint){
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED);
        }
        buyToken = EIP20Interface(value);
        buyTokenDecimals = Decimals;
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
        return cardHold[hold].length;
    }

    function setStepBlock(uint256[] stepBlock, uint256[] stepProfit) public returns (uint) {
        require(stepBlock.length == stepProfit.length + 1);
        require(admin == msg.sender);
        uint256 i = 0;
        blockStep.stepLength = stepProfit.length;
        for (i = 0; i < stepProfit.length; i++) {
            blockStep.stepProfit[i] = stepProfit[i];
        }
        for (i = 0; i < stepBlock.length; i++) {
            blockStep.stepBlock[i] = stepBlock[i];
        }
        return 0;
    }

    function getPassBlock(uint256 startBlock) internal view returns (uint) {
        return safeSub(block.number, startBlock);
    }


    function calculateBlockProfit(uint256 start, uint256 end) public view returns (uint256){
        uint256 i = 0;
        uint256 profit = 0;
        uint256 currentBlock;
        start = getPassBlock(start);
        end = getPassBlock(end);
        currentBlock = start;
        for (i = 0; i < blockStep.stepLength; i++) {
            if (start >= blockStep.stepBlock[i] && start < blockStep.stepBlock[i + 1]) {
                if (end <= blockStep.stepBlock[i + 1]) {
                    profit += blockStep.stepProfit[i] * (end - currentBlock);
                    return profit;
                } else {
                    profit += blockStep.stepProfit[i] * (blockStep.stepBlock[i + 1] - blockStep.stepBlock[i]);
                }
            }
        }
        return profit;
    }

    function calculateGameBlockProfit(uint256 start, uint256 end) public view returns (uint256){
        uint256 blockProfit = calculateBlockProfit(start, end);
        return blockProfit * blockStep.gameProfitRate / 100;
    }

    function calculateMineBlockProfit(uint256 start, uint256 end) public view returns (uint256){
        uint256 blockProfit = calculateBlockProfit(start, end);
        return blockProfit * blockStep.mineProfitRate / 100;
    }

    function calculateCardProfit(address hold, uint256 cardNum) public view returns (uint256) {
        uint256 profit = 0;
        uint256 j = 0;
        uint256 lastBlockPower = 0;
        uint256 lastBlock = 0;
        uint256 endBock = 0;
        CardPower card = cardHold[hold][cardNum];
        profit = card.gameProfit;
        if (card.cardPower == 0 || totalPower.currentPower == 0) {
            return 0;
        }
        lastBlock = card.cardBlock;
        for (j = card.cardBlockIndex; j < totalPower.blocks.length + 1; j++) {

            if (totalPower.blocks[j] <= lastBlock) {
                continue;
            }
            endBock = totalPower.blocks[j];
            if (j == totalPower.blocks.length) {
                endBock = block.number;
            }
            lastBlockPower = totalPower.blockTotalPower[j];
            uint256 blockProfit = calculateGameBlockProfit(lastBlock, totalPower.blocks[j]);
            profit += blockProfit * card.cardPowerRate * card.cardPower / (lastBlockPower * 100);

            lastBlock = totalPower.blocks[j];
        }
        return profit;
    }

    function calculateMineProfit(address hold, uint256 cardNum) public view returns (uint256){
        uint256 profit = 0;
        uint256 j = 0;
        uint256 lastBlockPower = 0;
        uint256 lastBlock = 0;
        CardPower card = cardHold[hold][cardNum];
        profit = card.mineProfit;
        if (card.mineCardPower == 0 || totalPower.currentPower == 0) {
            return 0;
        }
        lastBlock = card.mineBlock;
        for (j = card.cardMineBlockIndex; j < totalPower.blocks.length + 1; j++) {

            if (totalPower.blocks[j] <= lastBlock) {
                continue;
            }
            uint256 endBlock = totalPower.blocks[j];
            if (j == totalPower.blocks.length) {
                endBlock = block.number;
            }
            if (totalPower.blocks[j] > card.mineBlock + blockStep.mineBlockNum) {
                endBlock = card.mineBlock + blockStep.mineBlockNum;
            }
            lastBlockPower = totalPower.blockTotalPower[j];
            uint256 blockProfit = calculateGameBlockProfit(lastBlock, endBlock);
            profit += blockProfit * card.cardPowerRate * card.mineCardPower / (lastBlockPower * 100);
            if (totalPower.blocks[j] > card.mineBlock + blockStep.mineBlockNum) {
                return profit;
            }
            lastBlock = totalPower.blocks[j];
        }
        return profit;
    }


    function buyCard(address file) public returns (uint){
        uint256 priceAmount = 252 * buyTokenDecimals;
        if (buyToken.allowance(msg.sender, address(this)) < priceAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_ALLOWANCE);
        }
        if (buyToken.balanceOf(msg.sender) < priceAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_BALANCE);
        }
        if (cardAmount < 1) {
            return fail(Error.CARD_SOLD_OUT);
        }
        buyToken.transferFrom(msg.sender, address(this), priceAmount);

        CardPower card;
        card.file = file;
        card.cardBlock = block.number;
        card.cardPowerRate = getPowerRate();
        card.level = 1;
        card.cardPower = initPower * powerDecimals;
        card.cardBlockIndex = totalPower.blocks.length;
        cardHold[msg.sender].push(card);
        totalPower.currentPower += card.cardPower;
        totalPower.blockTotalPower[block.number] = totalPower.currentPower;
        totalPower.blocks.push(block.number);
        if (totalPower.startBlock == 0) {
            totalPower.startBlock = block.number;
        }

        return uint(Error.NO_ERROR);
    }

    function getUpgradePrice(address user, uint256 cardNum) public view returns (uint256){
        uint256 i = 0;
        CardPower card = cardHold[msg.sender][cardNum];
        uint256 amount = 0;
        if (card.level == 0) {
            return 0;
        }

        amount = tokenDecimals * 300;
        for (i = 0; i < card.level - 1; i++) {
            amount += amount * 100 / 16;
        }
        return amount;
    }

    function upgradeCard(uint256 cardNum) public returns (uint){

        CardPower card = cardHold[msg.sender][cardNum];
        if (card.level == 0) {
            return fail(Error.CARD_NOT_EXIST);
        }
        if (card.level >= 50) {
            return fail(Error.LEVEL_IS_TOP);
        }
        uint256 priceAmount = getUpgradePrice(msg.sender, cardNum);
        if (balanceOf(msg.sender) < priceAmount) {
            return fail(Error.INSUFFICIENT_BALANCE);
        }
        _burn(msg.sender, priceAmount);

        uint256 upgradePower = card.cardPower * 100 / 9;
        card.gameProfit += calculateCardProfit(msg.sender, cardNum);
        card.cardBlock = block.number;
        card.level += 1;
        card.cardPower += upgradePower;
        card.cardBlockIndex = totalPower.blocks.length;

        totalPower.currentPower += upgradePower;
        totalPower.blockTotalPower[block.number] = totalPower.currentPower;
        totalPower.blocks.push(block.number);


        return uint(Error.NO_ERROR);
    }

    function getMineAmount(address user, uint256 cardNum) public view returns (uint256){
        uint256 i = 0;
        CardPower card = cardHold[msg.sender][cardNum];
        uint256 amount = 0;
        if (card.level == 0) {
            return 0;
        }
        amount = 2500 + 500 * (card.level - 1);
        return amount;
    }

    function isMine(address user, uint256 cardNum) public view returns (bool){
        CardPower card = cardHold[msg.sender][cardNum];
        return card.mineBlock != 0 && getEndMineBlock(user, cardNum) > block.number;
    }


    function startMine(uint256 cardNum) public returns (uint){
        CardPower card = cardHold[msg.sender][cardNum];
        if (card.level == 0) {
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
        _freeze(msg.sender, cardNum, amount, block.number + blockStep.mineBlockNum);

        card.mineProfit += calculateMineProfit(msg.sender, cardNum);
        card.mineBlock = block.number;
        card.mineCardPower = card.cardPower;
        card.cardMineBlockIndex = card.cardBlockIndex;
        return uint(Error.NO_ERROR);
    }

    function stopMine(uint256 cardNum) public returns (uint){
        if (isMine(msg.sender, cardNum)) {
            CardPower card = cardHold[msg.sender][cardNum];
            _unfreeze(msg.sender, cardNum);
            card.mineBlock = 0;
            card.mineCardPower = 0;
        }

        return uint(Error.NO_ERROR);
    }

    function getGameProfit() public returns (uint){
        CardPower[] cardList = cardHold[msg.sender];
        uint256 profit = 0;
        uint256 i = 0;
        if (cardList.length == 0) {
            return fail(Error.CARD_NOT_EXIST);
        }
        for (i = 0; i < cardList.length; i++) {
            cardList[i].gameProfit += calculateCardProfit(msg.sender, i);
            profit += cardList[i].gameProfit;
            cardList[i].gameProfit = 0;
            cardList[i].cardBlock = block.number;
            cardList[i].cardBlockIndex = totalPower.blocks.length;
            cardList[i].withdrawProfit += cardList[i].gameProfit;
        }
        if (profit > 0) {
            transferFrom(admin, msg.sender, profit);
        }

        return uint(Error.NO_ERROR);
    }

    function getMineProfit() public returns (uint){
        CardPower[] cardList = cardHold[msg.sender];
        uint256 profit = 0;
        uint256 i = 0;
        if (cardList.length == 0) {
            return fail(Error.CARD_NOT_EXIST);
        }
        for (i = 0; i < cardList.length; i++) {
            cardList[i].mineProfit += calculateMineProfit(msg.sender, i);
            profit += cardList[i].mineProfit;
            cardList[i].withdrawProfit += cardList[i].mineProfit;
        }
        if (profit > 0) {
            transferFrom(admin, msg.sender, profit);
        }

        return uint(Error.NO_ERROR);
    }

}