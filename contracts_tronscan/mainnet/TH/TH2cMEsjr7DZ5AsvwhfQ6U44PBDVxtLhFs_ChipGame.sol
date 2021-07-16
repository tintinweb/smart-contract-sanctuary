//SourceUnit: ChipGame.sol

pragma solidity ^0.5.4;

interface Token {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner_, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;
}

interface TokenSale {
    function getSoldStep() external view returns (uint steps);
    function getRate() external view returns (uint);
}

interface Bank {
    function mine(address playerAddr, uint bet) external;
    function getMiningRate() external view returns (uint);
}

contract Ownable {
    address public owner;

    constructor () internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}


contract Bonus is Ownable {
    struct Dept {
        uint tltSpend;
        uint tltReceive;
        bool alreadyReceive;
    }

    bool public isBonusReady;
    address public bank;

    mapping(address => Dept) public userDepts;

    event ReceiveBonus(address indexed player, uint dept);

    modifier onDeploy() {
        require(!isBonusReady, "Bonus was started");
        _;
    }

    modifier ifReady() {
        if (isBonusReady) {
            _;
        }
    }

    constructor(address _bank) public Ownable() {
        bank = _bank;
    }

    function checkBonus(address player, uint playerTLT) internal ifReady {
        if (userDepts[player].tltSpend > 0 && !userDepts[player].alreadyReceive && playerTLT >= userDepts[player].tltSpend) {
            userDepts[player].alreadyReceive = true;
            uint oneTLT = Bank(bank).getMiningRate() * 10 ** 6;
            uint amount = oneTLT * userDepts[player].tltReceive;
            Bank(bank).mine(player, amount);
            emit ReceiveBonus(player, userDepts[player].tltReceive);
        }
    }

    function setBonus(address player, uint tltSpend, uint tltReceive) external onlyOwner onDeploy {
        userDepts[player] = Dept({tltSpend : tltSpend, tltReceive : tltReceive, alreadyReceive : false});
    }

    function enableBonus() public onlyOwner onDeploy {
        isBonusReady = true;
    }
}

contract ChipGame is Bonus {
    bool isContractEnable;

    struct Player {
        uint lastPayout;
        uint reinvestTime;
        uint[] chips;
        uint[] buyTime;
        uint[] buyMask;
    }

    address public token;
    address public saleContract;
    address public bankAddress;
    address payable public devWallet;

    uint[9] public chipPrice;
    uint[9] public chipPayoutPerHour;
    uint[9] public chipLifeDays;

    uint public playersCount;
    mapping(address => Player) public players;
    mapping(address => uint) public reinvestMask;

    uint public TLTSpent;
    uint public TRXReceive;
    mapping(address => uint) public TLTSpentOf;
    mapping(address => uint) public TRXReceiveOf;

    modifier isEnabled() {
        require(isContractEnable, "Contract is not enabled");
        _;
    }

    event Donate(address indexed addr, uint amount);
    event BuyChip(address indexed addr, uint chip, uint price);
    event Payout(address indexed addr, uint amount);
    event Reinvest(address indexed addr, uint chip, uint amount);

    constructor(address _token, address _bankWallet, address _saleAddress, address payable _devWallet, address _bank) public Bonus(_bank) {
        token = _token;
        bankAddress = _bankWallet;
        saleContract = _saleAddress;
        devWallet = _devWallet;

        uint tlt = 10000000000;
        uint trxValue = 1000000;

        chipPrice = [
        // First tier chips
        160 * tlt, 640 * tlt, 1280 * tlt,
        // Second tier chips
        704 * tlt, 2816 * tlt, 8448 * tlt,
        // Third tier chips
        1536 * tlt, 9216 * tlt, 18432 * tlt
        ];

        chipPayoutPerHour = [
        // First tier chips
        500000, 2 * trxValue, 4 * trxValue,
        // Second tier chips
        2 * trxValue, 8 * trxValue, 24 * trxValue,
        // Third tier chips
        4 * trxValue, 24 * trxValue, 48 * trxValue
        ];

        chipLifeDays = [
        // First tier chips
        40, 40, 40,
        // Second tier chips
        55, 55, 55,
        // Third tier chips
        80, 80, 80
        ];
    }

    // Setters

    function setDevWallet(address payable newWallet) external onlyOwner {
        devWallet = newWallet;
    }

    function setBankAddress(address newWallet) external onlyOwner {
        bankAddress = newWallet;
    }

    function setTokenSaleContract(address newTokenSale) external onlyOwner {
        saleContract = newTokenSale;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////

    function getAllPlayerCount() external view returns (uint)  {
        return playersCount;
    }

    function getChipsAvailableOf(address user) external view returns (uint chipAvailable) {
        return players[user].chips.length >= 200 ? 200 : players[user].chips.length;
    }

    function playerChipsOf(address user) public view returns (
        uint[] memory playerChips,
        uint[] memory playerChipsTime,
        uint[] memory playerBuyMask
    ) {
        require(user != address(0), "Zero address");
        playerChips = players[user].chips;
        playerChipsTime = players[user].buyTime;
        playerBuyMask = players[user].buyMask;
        return (playerChips, playerChipsTime, playerBuyMask);
    }

    function getPlayerChips() external view returns (
        uint[] memory playerChips,
        uint[] memory playerChipsTime,
        uint[] memory playerBuyMask
    ) {
        return playerChipsOf(msg.sender);
    }

    function calcNewBuyPayouts() public view returns (uint[9] memory newPayoutsPerHour) {
        uint soldStep = TokenSale(saleContract).getSoldStep();
        for (uint chipId = 0; chipId < 9; chipId++) {
            uint initialPayout = chipPayoutPerHour[chipId];
            newPayoutsPerHour[chipId] = initialPayout + initialPayout * soldStep * 5 / 100;
        }
        return newPayoutsPerHour;
    }

    function calcUserPayoutsOf(address addr) public view returns (uint[] memory payoutsPerHour) {
        require(addr != address(0), "Zero address");
        uint steps = TokenSale(saleContract).getSoldStep();
        uint[] memory payoutsPerHour_ = new uint[]( players[addr].chips.length);
        for (uint i = 0; i < players[addr].chips.length && i < 200; i++) {
            uint payout = calcPayout(chipPayoutPerHour[players[addr].chips[i]], players[addr].buyMask[i], steps);
            payoutsPerHour_[i] = payout;
        }
        return payoutsPerHour_;
    }

    function calcPayout(uint initialPayout, uint buyMask, uint steps) public pure returns (uint payoutPerHour) {
        return buyMask + initialPayout * steps / 100;
    }

    function calcBuyMask(uint initialPayout) public view returns (uint payoutPerHour) {
        // 5% - 1%
        return initialPayout + initialPayout * TokenSale(saleContract).getSoldStep() * 4 / 100;
    }

    function getPayoutOf(address addr) public view returns (uint) {
        require(addr != address(0), "Zero address");
        uint value = 0;
        uint lastPayout = players[addr].lastPayout;
        uint steps = TokenSale(saleContract).getSoldStep();
        for (uint i = 0; i < players[addr].chips.length && i < 200; i++) {
            uint buyTime = players[addr].buyTime[i];

            uint timeEnd = buyTime + chipLifeDays[players[addr].chips[i]] * 86400;
            uint from_ = lastPayout > buyTime ? lastPayout : buyTime;
            uint to = now > timeEnd ? timeEnd : now;
            uint payoutPerHour = calcPayout(chipPayoutPerHour[players[addr].chips[i]], players[addr].buyMask[i], steps);

            if (from_ < to) {

                //DEV SET 3600
                value += ((to - from_) / 60) * payoutPerHour;
            }
        }
        return value - reinvestMask[addr];
    }

    // TRX - TLT converters

    function inTLT(uint amount) public view returns (uint) {
        return amount / TokenSale(saleContract).getRate() * 100000;
    }

    function inTRX(uint amountTLT) public view returns (uint) {
        return amountTLT * TokenSale(saleContract).getRate() / 100000;
    }

    //

    function calcPrices(address player) public view returns (uint[9] memory newPrices) {
        require(player != address(0), "Zero address");
        for (uint chipId = 0; chipId < 9; chipId++) {
            newPrices[chipId] = _calcPrice(player, chipId);
        }
        return newPrices;
    }

    function _calcPrice(address player, uint chipId) internal view returns (uint) {
        uint reinvestTime = players[player].reinvestTime;
        uint price = chipPrice[chipId];
        if (reinvestTime > 0 && now > reinvestTime) {
            if (now - reinvestTime > 21 days) {
                return price - price * 30 / 100;
            } else if (now - reinvestTime > 14 days) {
                return price - price * 20 / 100;
            } else if (now - reinvestTime > 7 days) {
                return price - price * 10 / 100;
            }
        }
        return price;
    }

    function getDiscountOf(address player) public view returns (uint) {
        uint reinvestTime = players[player].reinvestTime;
        if (reinvestTime > 0 && now > reinvestTime) {
            if (now - reinvestTime > 21 days) {
                return 30;
            } else if (now - reinvestTime > 14 days) {
                return 20;
            } else if (now - reinvestTime > 7 days) {
                return 10;
            }
        }
        return 0;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _buyChip(address playerAddress, uint chipId, uint price) internal {
        _processTokenExchange(playerAddress, price);
        _processBuyChip(playerAddress, chipId, price);
    }

    function _processTokenExchange(address playerAddress, uint price) internal {
        Token(token).transferFrom(playerAddress, bankAddress, price);
        TLTSpent += price;
        TLTSpentOf[playerAddress] += price;
        checkBonus(playerAddress, TLTSpentOf[playerAddress]);
    }

    function _processBuyChip(address playerAddress, uint chipId, uint price) internal {
        Player storage player = players[playerAddress];
        if (player.chips.length == 0) playersCount += 1;
        player.chips.push(chipId);
        player.buyTime.push(now);
        player.buyMask.push(calcBuyMask(chipPayoutPerHour[chipId]));
        emit BuyChip(playerAddress, chipId, price);
    }

    function _getPayoutToWallet(address payable sender, uint amount) internal {
        sender.transfer(amount);
    }

    //User functions

    function buyChip(uint chipId) external isHuman isEnabled {
        require(chipId < 9, "Overflow");
        require(players[msg.sender].chips.length + 1 <= 200, "Chips limit 200");
        uint price = _calcPrice(msg.sender, chipId);
        require(Token(token).allowance(msg.sender, address(this)) >= price, "Not enough TLT allowed ");
        _buyChip(msg.sender, chipId, price);
    }

    function buyChips(uint chipId, uint amount) external isHuman isEnabled {
        require(amount > 1, "Use buyChip for that transaction");
        require(chipId < 9, "Overflow");
        require(players[msg.sender].chips.length + amount <= 200, "Chips limit 200");
        uint price = _calcPrice(msg.sender, chipId);
        require(Token(token).balanceOf(msg.sender) >= price * amount, "Not enough TLT");
        for (uint i = 0; i < amount; i++) {
            _buyChip(msg.sender, chipId, price);
        }
    }


    function getPayoutToWallet() external payable isHuman isEnabled {
        uint amount = getPayoutOf(msg.sender);
        require(amount > 0, "No payout");
        players[msg.sender].lastPayout = now;
        players[msg.sender].reinvestTime = 0;
        reinvestMask[msg.sender] = 0;
        TRXReceive += amount;
        TRXReceiveOf[msg.sender] += amount;
        _getPayoutToWallet(msg.sender, amount);
        emit Payout(msg.sender, amount);

    }

    function reinvest(uint chipId) external isHuman isEnabled {
        require(chipId < 9, "Overflow");
        uint amount = getPayoutOf(msg.sender);
        require(amount > 0, "No payout");
        uint amountTLT = inTLT(amount);
        uint price = _calcPrice(msg.sender, chipId);
        require(amountTLT >= price && price > 0, "Too small dividends");
        uint chipAmount = (amountTLT / price);
        require(players[msg.sender].chips.length + chipAmount <= 200, "Chips limit 200");
        uint trxVirtualSpend = inTRX(price * chipAmount);
        reinvestMask[msg.sender] += trxVirtualSpend;
        devWallet.transfer(trxVirtualSpend / 10); // 10% commission tokenSale
        if (players[msg.sender].reinvestTime == 0) {
            players[msg.sender].reinvestTime = now;
        }
        for(uint i=0; i < chipAmount; i++) {
            _processBuyChip(msg.sender, chipId, price);
        }
        emit Reinvest(msg.sender, chipId, chipAmount);
    }

    function enableContract() external onlyOwner {
        isContractEnable = true;
    }

    // Donations
    function donate() external payable {
        emit Donate(msg.sender, msg.value);
    }

    function() external payable {
        emit Donate(msg.sender, msg.value);
    }
}