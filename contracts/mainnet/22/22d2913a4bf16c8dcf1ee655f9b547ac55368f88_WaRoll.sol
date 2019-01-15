pragma solidity ^0.4.24;

contract WaRoll {

    struct BetData {
        uint gameId;
        address player;
        uint amount;
        uint value;
        uint blockNum;
        bytes betData;
    }

    uint constant private FEE_PERCENT = 1;
    uint constant private MIN_FEE = 0.0003 ether;

    uint constant private MIN_STAKE = 0.001 ether;
    uint constant private MAX_STAKE = 10 ether;

    uint constant private ROULETTE_BASE_STAKE = 0.01 ether;

    uint constant private TYPE_ROLL = 0;
    uint constant private TYPE_ROULETTE = 1;
    uint constant private ROLL_MAX_MOD = 100;
    uint constant private ROULETTE_MAX_MOD = 37;

    mapping(bytes32 => BetData) private bets;

    address private owner;
    address private signer;
    address public croupier;

    event BetEvent(uint gamdId, bytes32 commit, bytes data);
    event RollPayment(address player, uint gameId, uint payAmount, uint value, uint result, uint betAmount, uint betValue, bytes32 betTx);
    event RoulettePayment(address player, uint gameId, uint payAmount, uint value, uint result, uint betAmount, bytes32 betTx, bytes betData);
    event PaymentFail(address player, uint amount);

    constructor() public payable {
        owner = msg.sender;
        signer = msg.sender;
        croupier = msg.sender;
    }

    modifier ownerOnly(){
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier croupierOnly(){
        require(msg.sender == croupier, "not croupier");
        _;
    }

    modifier validSignAndBlock(uint blockNum, bytes32 commit, bytes32 r, bytes32 s){
        require(blockNum >= block.number, "commit has expired");
        bytes32 v1 = keccak256(abi.encodePacked(uint40(blockNum), commit));
        require(signer == ecrecover(v1, 27, r, s) || signer == ecrecover(v1, 28, r, s), "signer valid error");
        _;
    }

    function setCroupier(address c) public ownerOnly {
        croupier = c;
    }

    function setSigner(address c) public ownerOnly {
        signer = c;
    }


    function kill() public ownerOnly {
        selfdestruct(owner);
    }

    function doRollBet(uint value, uint expiredBlockNum, bytes32 commit, bytes32 r, bytes32 s) public payable validSignAndBlock(expiredBlockNum, commit, r, s) {
        require(value >= 1 && value <= ROLL_MAX_MOD - 3, "invalid value");
        uint stake = msg.value;
        require(stake >= MIN_STAKE && stake <= MAX_STAKE);
        BetData storage bet = bets[commit];
        require(bet.player == address(0));
        bet.gameId = TYPE_ROLL;
        bet.value = value;
        bet.amount = stake;
        bet.player = msg.sender;
        bet.blockNum = block.number;
        emit BetEvent(bet.gameId, commit, new bytes(0));
    }

    function doRouletteBet(bytes data, uint expiredBlockNum, bytes32 commit, bytes32 r, bytes32 s) public payable validSignAndBlock(expiredBlockNum, commit, r, s) {
        uint stake = msg.value;
        validRouletteBetData(data, stake);
        BetData storage bet = bets[commit];
        require(bet.player == address(0));
        bet.gameId = TYPE_ROULETTE;
        bet.betData = data;
        bet.amount = stake;
        bet.player = msg.sender;
        bet.blockNum = block.number;
        emit BetEvent(bet.gameId, commit, data);
    }

    function validRouletteBetData(bytes data, uint amount) pure private {
        uint length = uint8(data[0]);
        require(data.length == length * 2 + 1);
        uint total = 0;
        for (uint i = 0; i < length; i ++) {
            total += uint8(data[2 + i * 2]);
        }
        require(total * ROULETTE_BASE_STAKE == amount);
    }

    function doResult(uint value, bytes32 blockHash, bytes32 betTx, uint paymentMutiplier) public croupierOnly payable {
        bytes32 commit = keccak256(abi.encodePacked(value));
        BetData storage bet = bets[commit];
        require(blockhash(bet.blockNum) == blockHash);
        if (bet.gameId == TYPE_ROLL) {
            doRollResult(value, bet, betTx);
        } else if (bet.gameId == TYPE_ROULETTE) {
            doRouletteResult(value, bet, betTx, paymentMutiplier);
        }
    }

    function doRollResult(uint value, BetData bet, bytes32 betTx) private croupierOnly {
        uint result = (value % ROLL_MAX_MOD) + 1;
        uint betAmount = bet.amount;
        uint payAmount = 0;
        if (result <= bet.value) {
            uint fee = betAmount / 100 * FEE_PERCENT;
            if (fee < MIN_FEE) {
                fee = MIN_FEE;
            }
            payAmount = (betAmount - fee) * ROLL_MAX_MOD / bet.value;
        }
        if (bet.player.send(payAmount)) {
            emit RollPayment(bet.player, bet.gameId, payAmount, value, result, bet.amount, bet.value, betTx);
        } else {
            emit PaymentFail(bet.player, payAmount);
        }
    }

    function doRouletteResult(uint value, BetData bet, bytes32 betTx, uint paymentMutiplier) private croupierOnly {
        uint result = value % ROULETTE_MAX_MOD;
        uint payAmount = ROULETTE_BASE_STAKE * paymentMutiplier;
        if (bet.player.send(payAmount)) {
            emit RoulettePayment(bet.player, bet.gameId, payAmount, value, result, bet.amount, betTx, bet.betData);
        } else {
            emit PaymentFail(bet.player, payAmount);
        }
    }


    function() public payable {
    }

    function withdraw(address add, uint amount) ownerOnly payable public {
        add.transfer(amount);
    }
}