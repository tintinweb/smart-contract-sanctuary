pragma solidity 0.4.15;

// visit https://KickTheCoin.com
contract KickTheCoin {
    address houseAddress;
    address creator;
    address owner;
    address airDroper;

    address lastPlayerToKickTheCoin;

    uint kickerCount;

    address firstKicker;
    address secondKicker;

    uint costToKickTheCoin;
    uint numberOfBlocksPerKick;
    uint targetBlockNumber;

    // set to true when game contract should stop new games from starting
    bool isSundown;
    // The blocknumber at which the current sundown grace period will end
    uint sundownGraceTargetBlock;

    // The index is incremented on each new game (via initGame)
    uint gameIndex;

    uint currentValue;

    mapping(address => uint) shares;

    event LatestKicker(uint curGameIndex, address kicker, uint curVal, uint targetBlockNum);
    event FirstKicker(uint curGameIndex, address kicker, uint curVal);
    event SecondKicker(uint curGameIndex, address kicker, uint curVal);
    event Withdraw(address kicker, uint curVal);
    event Winner(uint curGameIndex, address winner, uint curVal);

    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }

    modifier onlyByOwnerAndOnlyIfGameIsNotActive() {
        require(msg.sender == owner && !isGameActive());
        _;
    }

    modifier onlyDuringNormalOperations() {
        require(!isSundown);
        _;
    }

    function KickTheCoin()
    public
    payable
    {
        creator = msg.sender;
        owner = creator;
        houseAddress = creator;
        airDroper = creator;
        gameIndex = 0;
        isSundown = false;
        costToKickTheCoin = 0.17 ether;
        numberOfBlocksPerKick = 5;
        initGame();
    }

    function()
    public
    payable
    {
        kickTheCoin();
    }

    function kickTheCoin()
    public
    payable
    onlyDuringNormalOperations()
    {
        require(msg.value == costToKickTheCoin);

        if (hasWinner()) {
            storeWinnerShare();
            initGame();
        }

        kickerCount += 1;
        processKick();
        lastPlayerToKickTheCoin = msg.sender;
        targetBlockNumber = block.number + numberOfBlocksPerKick;

        LatestKicker(gameIndex, msg.sender, currentValue, targetBlockNumber);
    }

    function withdrawShares()
    public
    {
        if (hasWinner()) {
            storeWinnerShare();
            initGame();
        }
        pullShares(msg.sender);
    }

    function checkShares(address shareHolder)
    public
    constant
    returns (uint)
    {
        return shares[shareHolder];
    }

    function isGameActive()
    public
    constant
    returns (bool)
    {
        return targetBlockNumber >= block.number;
    }

    function hasWinner()
    public
    constant
    returns (bool)
    {
        return currentValue > 0 && !isGameActive();
    }

    function getCurrentValue()
    public
    constant
    returns (uint)
    {
        if (isGameActive()) {
            return currentValue;
        } else {
            return 0;
        }
    }

    function getLastKicker()
    public
    constant
    returns (address)
    {
        if (isGameActive()) {
            return lastPlayerToKickTheCoin;
        } else {
            return address(0);
        }
    }

    function pullShares(address shareHolder)
    public
    {
        var share = shares[shareHolder];
        if (share == 0) {
            return;
        }

        shares[shareHolder] = 0;
        shareHolder.transfer(share);
        Withdraw(shareHolder, share);
    }

    function airDrop(address player)
    public
    payable
    onlyBy(airDroper)
    {
        player.transfer(1);
        if (msg.value > 1) {
            msg.sender.transfer(msg.value - 1);
        }
    }

    function getTargetBlockNumber()
    public
    constant
    returns (uint)
    {
        return targetBlockNumber;
    }

    function getBlocksLeftInCurrentKick()
    public
    constant
    returns (uint)
    {
        if (targetBlockNumber < block.number) {
            return 0;
        }
        return targetBlockNumber - block.number;
    }

    function getNumberOfBlocksPerKick()
    public
    constant
    returns (uint)
    {
        return numberOfBlocksPerKick;
    }

    function getCostToKick()
    public
    constant
    returns (uint)
    {
        return costToKickTheCoin;
    }

    function getCurrentBlockNumber()
    public
    constant
    returns (uint)
    {
        return block.number;
    }

    function getGameIndex()
    public
    constant
    returns (uint)
    {
        return gameIndex;
    }

    function changeOwner(address _newOwner)
    public
    onlyBy(owner)
    {
        owner = _newOwner;
    }

    function changeHouseAddress(address _newHouseAddress)
    public
    onlyBy(owner)
    {
        houseAddress = _newHouseAddress;
    }

    function changeAirDroper(address _airDroper)
    public
    onlyBy(owner)
    {
        airDroper = _airDroper;
    }

    function changeGameParameters(uint _costToKickTheCoin, uint _numberOfBlocksPerKick)
    public
    onlyByOwnerAndOnlyIfGameIsNotActive()
    {
        costToKickTheCoin = _costToKickTheCoin;
        numberOfBlocksPerKick = _numberOfBlocksPerKick;
    }

    function sundown()
    public
    onlyByOwnerAndOnlyIfGameIsNotActive()
    {
        isSundown = true;
        sundownGraceTargetBlock = block.number + 100000;
    }

    function gameIsSundown()
    public
    constant
    returns (bool)
    {
        return isSundown;
    }

    function getSundownGraceTargetBlock()
    public
    constant
    returns (uint)
    {
        return sundownGraceTargetBlock;
    }

    function sunrise()
    public
    onlyByOwnerAndOnlyIfGameIsNotActive()
    {
        isSundown = false;
        sundownGraceTargetBlock = 0;
    }

    function clear()
    public
    {
        if (isSundown &&
        sundownGraceTargetBlock != 0 &&
        sundownGraceTargetBlock < block.number) {
            houseAddress.transfer(this.balance);
        }
    }

    function initGame()
    private
    {
        gameIndex += 1;
        targetBlockNumber = 0;
        currentValue = 0;
        kickerCount = 0;
        firstKicker = address(0);
        secondKicker = address(0);
        lastPlayerToKickTheCoin = address(0);
    }

    function storeWinnerShare()
    private
    {
        var share = currentValue;
        currentValue = 0;
        shares[lastPlayerToKickTheCoin] += share;
        if (share > 0) {
            Winner(gameIndex, lastPlayerToKickTheCoin, share);
        }
    }

    function setShares()
    private
    {
        // 1.0% commission to the house
        shares[houseAddress] += (msg.value * 10)/1000;
        // 2.5% commission to first kicker
        shares[firstKicker] += (msg.value * 25)/1000;
        // 1.5% commission to second kicker
        shares[secondKicker] += (msg.value * 15)/1000;
    }

    function processKick()
    private
    {
        if (kickerCount == 1) {
            currentValue = msg.value; // no commission on first kick
            firstKicker = msg.sender;
            FirstKicker(gameIndex, msg.sender, currentValue);
        } else if (kickerCount == 2) {
            currentValue += msg.value; // no commission on second kick
            secondKicker = msg.sender;
            SecondKicker(gameIndex, msg.sender, currentValue);
        } else {
            // 5% is used. 2.5% for first kicker, 1.5% for second, 1% for house
            // leaving 95% for the winner
            currentValue += (msg.value * 950)/1000;
            setShares();
        }
    }
}

// visit https://KickTheCoin.com
contract WithdrawFromKickTheCoin {
    address public owner;
    address public ktcAddress;
    bool public ktcAddressIsSet;

    function WithdrawFromKickTheCoin()
    public
    {
        owner = msg.sender;
        ktcAddressIsSet = false;
    }

    function setKtcAddress(address _ktcAddress, bool isImmutable)
    public
    {
        require(!ktcAddressIsSet);
        ktcAddressIsSet = isImmutable;
        ktcAddress = _ktcAddress;
    }

    function getKtcAddress()
    public
    constant
    returns (address)
    {
        return ktcAddress;
    }

    function getOwner()
    public
    constant
    returns (address)
    {
        return owner;
    }

    function release()
    public
    {
        owner.transfer(this.balance);
    }

    function()
    public
    {
        KickTheCoin ktc = KickTheCoin(ktcAddress);
        ktc.pullShares(msg.sender);
    }
}

// Visit https://KickTheCoin.com
contract KickTheCoinFactory {

    address[] public games;
    address[] public founders;

    mapping(address => address[]) founderToCreatedGames;
    mapping(address => uint) gameToBlockCreated;
    mapping(address => address) gameToWithdraw;

    address public admin;
    address public coldAdmin = 0x46937732313A6c856354f4E5Ea012DfD10186B9A;
    uint public costToCreateGame;
    bool public isDisabled;

    event GameCreated(address founder, address _game, address _withdraw, uint _costToKickTheCoin, uint _numberOfBlocksPerKick);

    function KickTheCoinFactory() {
        admin = msg.sender;
        isDisabled = false;
    }

    function createGame(uint _costToKickTheCoin, uint _numberOfBlocksPerKick)
    public
    payable
    {
        require(!isDisabled);

        if (costToCreateGame > 0) {
            require(msg.value == costToCreateGame);
        }

        if (msg.value > 0) {
            admin.transfer(msg.value);
        }

        KickTheCoin _game = new KickTheCoin();
        _game.changeGameParameters(_costToKickTheCoin, _numberOfBlocksPerKick);
        games.push(_game);
        if (founderToCreatedGames[msg.sender].length == 0) {
            founders.push(msg.sender);
        }
        founderToCreatedGames[msg.sender].push(_game);

        WithdrawFromKickTheCoin _withdraw = new WithdrawFromKickTheCoin();
        _withdraw.setKtcAddress(_game, true);
        gameToWithdraw[_game] = _withdraw;

        gameToBlockCreated[_game] = block.number;
        GameCreated(msg.sender, _game, _withdraw, _costToKickTheCoin, _numberOfBlocksPerKick);
    }

    function setDisabled(bool _isDisabled)
    {
        require(msg.sender == admin);
        isDisabled = _isDisabled;
    }

    function setCostToCreateGame(uint _costToCreateGame)
    public
    {
        require(msg.sender == admin);
        costToCreateGame = _costToCreateGame;
    }

    function setAdmin(address _newAdmin)
    public
    {
        require(msg.sender == admin || msg.sender == coldAdmin);
        admin = _newAdmin;
    }

    function getFoundersGames(address _founder)
    public
    constant
    returns (address[])
    {
        return founderToCreatedGames[_founder];
    }

    function getWithdraw(address _game)
    public
    constant
    returns(address _withdraw)
    {
        _withdraw = gameToWithdraw[_game];
    }

    function getInfo()
    constant
    returns (
        address[] _games,
        address[] _founders,
        address _admin,
        uint _costToCreateGame,
        bool _isDisabled
    )
    {
        _games = games;
        _isDisabled = isDisabled;
        _admin = admin;
        _costToCreateGame = costToCreateGame;
        _founders = founders;
    }

    function()
    payable
    {
        admin.transfer(msg.value);
    }

}