pragma solidity 0.5.10;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address initialOwner) public {
        require(initialOwner != address(0));
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
}

contract TriangleRooms is Ownable, ReentrancyGuard {
    enum State {Stopped, Paused, Game, Drawing}
    State public state = State.Stopped;

    uint256 _nextPrice;
    uint256 _nextPrize;
    uint256 _nextLimit;

    uint256 public blockDelay;

    uint256 public gameCount;

    mapping(address => mapping(uint256 => uint256)) internal _tickets;
    mapping(uint256 => bytes32) internal _blockhashes;
    mapping(uint256 => Round) internal _rounds;

    struct Round {
        uint256 price;
        uint256 prize;
        uint256 limit;
        uint256 sold;
        uint256 futureblock;
        mapping(uint256 => address payable) players;
    }

    uint256 public availableFee;
    Wallet[] public wallets;

    struct Wallet {
        address payable account;
        uint256 share;
    }

    event RoundStarted(uint256 gameCount);
    event NewPlayer(
        address indexed addr,
        uint256 amount,
        uint256 available,
        uint256 gameCount
    );
    event PayBack(address indexed addr, uint256 value, string cause);
    event AllBetsAreIn(uint256 tickets, uint256 gameCount);
    event FutureBlock(uint256 blocknumber, uint256 delay, uint256 gameCount);
    event GameOver(
        uint256 gameCount,
        uint256 futureblock,
        bytes32 hash,
        uint256 seed,
        uint256 winnerTicket,
        address indexed winner,
        uint256 prize,
        uint256 fee
    );

    modifier onState(State requiredState) {
        require(_isState(requiredState), "Wrong state");
        _;
    }

    modifier notOnPause() {
        require(!_isState(State.Stopped) && !_isState(State.Paused));
        _;
    }

    constructor(
        uint256 price,
        uint256 prize,
        uint256 limit,
        uint256 delay,
        address payable initialWallet
    ) public Ownable(msg.sender) {
        require(delay > 0);
        setParameters(price, prize, limit);
        wallets.push(Wallet(initialWallet, 10000));
        blockDelay = delay;
    }

    function start(
        address payable[] calldata addresses,
        uint256[] calldata amounts
    ) external payable onlyOwner onState(State.Stopped) {
        require(addresses.length == amounts.length, "Arrays are not equal");

        _startRound();

        Round storage round = _rounds[gameCount];

        uint256 totalValue;
        for (uint256 i = 0; i < addresses.length; i++) {
            round.players[round.sold] = addresses[i];
            round.sold += amounts[i];

            _tickets[addresses[i]][gameCount] += amounts[i];

            emit NewPlayer(
                addresses[i],
                amounts[i],
                round.limit - round.sold,
                gameCount
            );

            totalValue += amounts[i] * round.price;
        }

        require(
            totalValue <= round.limit * round.price,
            "Round limit overflow"
        );
        require(msg.value >= totalValue, "Not enough of ether");

        uint256 change = msg.value - totalValue;
        if (change > 0) {
            if (msg.sender.send(change)) {
                emit PayBack(msg.sender, change, "Limit");
            }
        }

        if (round.sold >= round.limit) {
            state = State.Drawing;
            emit AllBetsAreIn(round.sold, gameCount);
            draw();
        }
    }

    function() external payable {
        if (_isState(State.Game)) {
            play();
        } else if (_isState(State.Drawing)) {
            bool result = draw();
            if (!result && msg.value > 0) {
                if (msg.sender.send(msg.value)) {
                    emit PayBack(msg.sender, msg.value, "Draw");
                }
            }
        } else revert();
    }

    function play() public payable notOnPause nonReentrant {
        if (_isState(State.Game)) {
            Round storage round = _rounds[gameCount];

            uint256 amount = msg.value / round.price;

            require(amount > 0);

            uint256 change;
            string memory comment;
            uint256 available = getAvailableTickets();

            if (amount > available) {
                amount = available;
                change = msg.value - (available * round.price);
                comment = "Limit";
            } else if (msg.value > amount * round.price) {
                change = msg.value % round.price;
                comment = "Change";
            }

            if (amount > 0) {
                round.players[round.sold] = msg.sender;
                round.sold += amount;

                _tickets[msg.sender][gameCount] += amount;
            }

            emit NewPlayer(
                msg.sender,
                amount,
                round.limit - round.sold,
                gameCount
            );

            if (round.sold >= round.limit) {
                state = State.Drawing;
                emit AllBetsAreIn(round.sold, gameCount);
            }

            if (change > 0) {
                if (msg.sender.send(change)) {
                    emit PayBack(msg.sender, change, comment);
                }
            }
        }

        if (_isState(State.Drawing)) {
            draw();
        }
    }

    function draw() public payable onState(State.Drawing) returns (bool) {
        Round storage round = _rounds[gameCount];

        if (round.futureblock == 0 || block.number > round.futureblock + 254) {
            round.futureblock = block.number + blockDelay;

            emit FutureBlock(round.futureblock, blockDelay, gameCount);
            return false;
        }

        require(
            block.number > round.futureblock,
            "Awaiting for the future block"
        );

        uint256 fee = address(this).balance - round.prize - msg.value;
        availableFee += fee;

        (
            uint256 futureblock,
            bytes32 hash,
            uint256 seed,
            uint256 winnerTicket,
            address payable winnerAddr
        ) = getRoundWinner(gameCount);
        _blockhashes[futureblock] = hash;
        (winnerAddr.send(round.prize));

        emit GameOver(
            gameCount,
            futureblock,
            hash,
            seed,
            winnerTicket,
            winnerAddr,
            round.prize,
            fee
        );

        _startRound();

        if (msg.value >= _rounds[gameCount].price) {
            play();
        } else if (msg.value > 0) {
            if (msg.sender.send(msg.value)) {
                emit PayBack(msg.sender, msg.value, "Change");
            }
        }

        return true;
    }

    function _startRound() internal {
        gameCount++;

        Round storage round = _rounds[gameCount];

        round.price = _nextPrice;
        round.prize = _nextPrize;
        round.limit = _nextLimit;

        state = State.Game;

        emit RoundStarted(gameCount);
    }

    function donate() external payable {}

    function pause() external onlyOwner onState(State.Game) {
        state = State.Paused;
    }

    function unpause() external onlyOwner onState(State.Paused) {
        state = State.Game;
    }

    function setWallets(
        address payable[] memory initialWallets,
        uint256[] memory shares
    ) public onlyOwner {
        require(initialWallets.length == shares.length);

        if (availableFee > 0) {
            withdrawFee();
        }

        delete wallets;

        uint256 totalShare;
        for (uint256 i = 0; i < initialWallets.length; i++) {
            require(!_isContract(initialWallets[i]));
            wallets.push(Wallet(initialWallets[i], shares[i]));
            totalShare += shares[i];
        }

        require(totalShare == 10000, "Total sum of shares must be 10000");
    }

    function setParameters(
        uint256 newPrice,
        uint256 newPrize,
        uint256 newLimit
    ) public onlyOwner {
        require(newPrice > 0 && newPrize > 0 && newLimit > 0);
        require(newPrize < newPrice * newLimit);

        _nextPrice = newPrice;
        _nextPrize = newPrize;
        _nextLimit = newLimit;
    }

    function withdrawFee() public onlyOwner {
        uint256 payout = availableFee;
        if (payout > 0) {
            availableFee = 0;
            for (uint256 i; i < wallets.length; i++) {
                wallets[i].account.transfer(
                    (payout * wallets[i].share) / 10000
                );
            }
        }
    }

    function withdrawERC20(address ERC20Token, address recipient)
        external
        onlyOwner
    {
        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);
    }

    function getRoundWinner(uint256 roundIdx)
        public
        view
        returns (
            uint256 futureblock,
            bytes32 hash,
            uint256 seed,
            uint256 winnerTicket,
            address payable winnerAddr
        )
    {
        require(roundIdx <= gameCount);

        futureblock = getRoundFutureBlock(roundIdx);
        hash = getBlockHash(futureblock);
        seed = getSeed(hash);
        winnerTicket = getWinnerTicket(roundIdx, seed);
        winnerAddr = getWinnerAddress(roundIdx, winnerTicket);

        return (futureblock, hash, seed, winnerTicket, winnerAddr);
    }

    function getRoundFutureBlock(uint256 roundIdx)
        public
        view
        returns (uint256 blocknumber)
    {
        blocknumber = _rounds[roundIdx].futureblock;
        return blocknumber;
    }

    function getBlockHash(uint256 blocknumber)
        public
        view
        returns (bytes32 hash)
    {
        require(block.number > blocknumber, "Awaiting for the future block");

        if (block.number < blocknumber + 254) {
            hash = blockhash(blocknumber);
        } else {
            hash = _blockhashes[blocknumber];
        }

        return hash;
    }

    function getSeed(bytes32 hash) public pure returns (uint256 seed) {
        require(hash > 0, "Hash is the zero value");
        return uint256(hash);
    }

    function getWinnerTicket(uint256 roundIdx, uint256 seed)
        public
        view
        returns (uint256 winnerTicket)
    {
        require(roundIdx <= gameCount);

        winnerTicket = (seed % _rounds[roundIdx].limit) + 1;

        return winnerTicket;
    }

    function getWinnerAddress(uint256 roundIdx, uint256 winnerTicket)
        public
        view
        returns (address payable winnerAddr)
    {
        require(roundIdx <= gameCount);

        Round storage round = _rounds[roundIdx];

        for (uint256 i = 0; i <= winnerTicket; i++) {
            if (round.players[winnerTicket - i] != address(0)) {
                winnerAddr = round.players[winnerTicket - i];
                break;
            }
        }

        return winnerAddr;
    }

    function getRoundParameters(uint256 roundIdx)
        public
        view
        returns (
            uint256 price,
            uint256 prize,
            uint256 limit
        )
    {
        Round memory round = _rounds[roundIdx];

        return (round.price, round.prize, round.limit);
    }

    function getCurrentParameters()
        external
        view
        returns (
            uint256 price,
            uint256 prize,
            uint256 limit
        )
    {
        return getRoundParameters(gameCount);
    }

    function getNextParameters()
        external
        view
        returns (
            uint256 price,
            uint256 prize,
            uint256 limit
        )
    {
        return (_nextPrice, _nextPrize, _nextLimit);
    }

    function getAvailableTickets() public view returns (uint256) {
        Round memory round = _rounds[gameCount];
        return (round.limit - round.sold);
    }

    function getTicketsOf(address account, uint256 roundIdx)
        external
        view
        returns (uint256)
    {
        return _tickets[account][roundIdx];
    }

    function getCurrentTicketsOf(address account)
        external
        view
        returns (uint256)
    {
        return _tickets[account][gameCount];
    }

    function _isState(State requiredState) internal view returns (bool) {
        return (state == requiredState);
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}