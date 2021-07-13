/**
 *Submitted for verification at polygonscan.com on 2021-07-13
*/

pragma solidity 0.4.26;
contract RandomContract {
    struct Random {
        uint256 commitment;
        uint256 secret;
        uint256 blockHash;
        uint256 revealdAtBlock;
    }
    Random[] public rands; //Commitment by blocknumber
    mapping(uint256 => uint256) public commitments;
    mapping(address => bool) public operators;
    address public owner;
    address newOwner;
    modifier onlyOperator() {
        require(operators[msg.sender] || msg.sender == owner, "not croupier");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }
    function getQuickRandom(uint256 index, uint256 secret, uint256 revealdAtBlock)
        public
        view
        returns (uint256)
    {
        Random memory rand = rands[index];
        if (revealdAtBlock >= block.number) return 0;
        if (secret == 0) {
            return 0;
        } else {
            uint256 commitment = rand.commitment;
            if (uint256(keccak256(abi.encodePacked((secret)))) != commitment) {
                return 0;
            }
        }
        uint256 blockHash = uint256(blockhash(revealdAtBlock));
        if (blockHash == 0) {
            return 0;
        }
        return secret ^ blockHash;
    }
    function getRandom(uint256 index) public view returns (uint256) {
        Random memory rand = rands[index];
        if (rand.secret == 0 || rand.blockHash == 0) {
            return 0;
        }
        return rand.secret ^ rand.blockHash;
    }
    function commit(uint256 commitment) public onlyOperator {
        require(0 != commitment, "commitment == 0");
        require(
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563 !=
                commitment,
            "secret == 0"
        );
        rands.push(
            Random({
                commitment: commitment,
                secret: 0,
                blockHash: 0,
                revealdAtBlock: 0
            })
        );
        commitments[commitment] = rands.length - 1;
    }
    function reveal(uint256 index, uint256 secret, uint256 blockNumber)
        internal
        onlyOperator
    {
        require(blockNumber < block.number, "Invalid blockNumber");
        require(secret > 0, "Invalid secret");
        uint256 secretCommitment = uint256(
            keccak256(abi.encodePacked((secret)))
        );
        Random storage rand = rands[index];
        require(rand.commitment == secretCommitment, "Invalid secret");
        if (rand.secret != 0) {
            return;
        }
        uint256 blockHash = uint256(blockhash(blockNumber));
        if (blockHash == 0) {
            blockHash = uint256(blockhash(block.number - 1));
            rand.revealdAtBlock = block.number - 1;
        } else {
            rand.revealdAtBlock = blockNumber;
        }
        rand.blockHash = blockHash;
        rand.secret = secret;
    }
    function addOperator(address newOperator) public onlyOwner {
        operators[newOperator] = true;
    }
    function removeOperator(address operator) public onlyOwner {
        operators[operator] = false;
    }
    function transferOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function confirmNewOwner() public {
        require(msg.sender == newOwner, "not new owner");
        owner = newOwner;
    }
}

interface IGame {
    function verifyBet(uint256 v1, uint256 v2, uint256 v3, uint256 v4) external returns (bool);
    function payoutAmount(uint256 number, uint256 betAmount, uint256 v1, uint256 v2, uint256 v3, uint256 v4) external returns (uint);
}

interface ITRC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract GameMasterContract is RandomContract {
    struct Bet {
        address player;
        uint256 amount;
        uint256 randIndex;
        uint256 seed;
        uint256 blockNumber;
        uint256 number;
        address game;
        address token;
        uint256 v1;
        uint256 v2;
        uint256 v3;
        uint256 v4;
    }

    Bet[] public bets;
    uint256 public randIndex;
    bool public STOPPED = false;

    mapping(address => bool) public verifiedGames;
    mapping(address => bool) public verifiedTokens;
    mapping(address => uint256) public minBet;
    mapping(address => uint256) public maxBet;
    mapping(uint256 => mapping(address => uint256)) public betIndex;
    mapping(address => uint256[]) public betsOfPlayer;

    event NewBet(uint256 index);
    event SettleBet(uint256 index, uint256 winAmount);

    constructor() public {
        owner = msg.sender;
        randIndex = 1;
        bets.push(
            Bet({
                player: address(0x0),
                amount: 0,
                randIndex: 0,
                seed: 0,
                blockNumber: 0,
                number: 0,
                game: address(0x0),
                token: address(0x0),
                v1: 0,
                v2: 0,
                v3: 0,
                v4: 0
            })
        );
        minBet[address(0x0)] = 0.1 ether;
        maxBet[address(0x0)] = 20 ether;
        commit(1);
    }
    modifier notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "not support smart contract");
        require(msg.sender == tx.origin, "not support smart contract");
        _;
    }

    modifier notStop() {
        require(STOPPED != true, "stopped");
        _;
    }

    function () public payable {}

    function withdraw(address token) public onlyOwner {
        if (address(token) == address(0x0)) {
            owner.transfer(address(this).balance);
        }
        else {
            ITRC20(token).transfer(owner, ITRC20(token).balanceOf(this));
        }
    }

    function setRandIndex(uint256 i) public onlyOperator {
        require(i > randIndex, "invalid value");
        randIndex = i;
    }

    function toggleGame(address game) public onlyOwner {
        verifiedGames[game] = !verifiedGames[game];
    }

    function toggleToken(address token) public onlyOwner {
        verifiedTokens[token] = !verifiedTokens[token];
        if (verifiedTokens[token]) {
            minBet[token] = 0.1 ether;
            maxBet[token] = 20 ether;
        }
    }

    function setMinBet(address token, uint256 min) public onlyOwner {
        minBet[token] = min;
    }

    function setMaxBet(address token, uint256 max) public onlyOwner {
        maxBet[token] = max;
    }

    function toggleStop() public onlyOwner {
        STOPPED = !STOPPED;
    }

    function bet(address game, address token, uint256 value, uint256 seed, uint256 v1, uint256 v2, uint256 v3, uint256 v4)
        public payable notContract notStop
    {
        require(betIndex[block.number][msg.sender] == 0, "cannot bet in same block");
        require(rands.length > randIndex, "Cannot bet");
        require(verifiedGames[game], "Not support this game");
        uint256 betValue = 0;
        if (token == address(0x0)) {
            require(msg.value >= minBet[token], "value too small");
            require(msg.value <= maxBet[token], "value too big");

            betValue = msg.value;
        }
        else {
            require(verifiedTokens[token], "Not support this game");
            require(value >= minBet[token], "value too small");
            require(value <= maxBet[token], "value too big");
            ITRC20(token).transferFrom(msg.sender, address(this), value);
            betValue = value;
        }
        require(IGame(game).verifyBet(v1, v2, v3, v4), "Invalid data");

        betIndex[block.number][msg.sender] = bets.length;
        bets.push(
            Bet({
                player: msg.sender,
                seed: seed,
                amount: betValue,
                randIndex: randIndex,
                blockNumber: block.number,
                number: 0,
                game: game,
                token: token,
                v1: v1,
                v2: v2,
                v3: v3,
                v4: v4
            })
        );
        betsOfPlayer[msg.sender].push(bets.length - 1);
        emit NewBet(bets.length - 1);
        randIndex += 1;
    }

    function settleByIndex(uint256 index, uint256 secret) public onlyOperator returns (uint256) {
        if (index == 0) return 0;
        Bet storage settleBet = bets[index];
        if (settleBet.number != 0) {
            return settleBet.number;
        }
        reveal(settleBet.randIndex, secret, settleBet.blockNumber);
        uint256 number = super.getRandom(settleBet.randIndex) ^ settleBet.seed;
        settleBet.number = number;
        uint256 winAmount = IGame(settleBet.game)
            .payoutAmount(number, settleBet.amount, settleBet.v1, settleBet.v2, settleBet.v3, settleBet.v4);
        if (winAmount > 0) {
            if (settleBet.token == address(0x0)) {
                settleBet.player.transfer(winAmount);
            }
            else {
                ITRC20(settleBet.token).transfer(settleBet.player, winAmount);
            }
        }
        emit SettleBet(index, winAmount);
        return number;
    }

    function settle(uint256 blockNumber, address player, uint256 secret, uint256 newCommitment) public onlyOperator returns (uint256) {
        uint256 index = betIndex[blockNumber][player];

        if (newCommitment != 0) {
            commit(newCommitment);
        }

        settleByIndex(index, secret);
    }
    function getNumberOfBets(address player) public view returns (uint256) {
        if (player == address(0x0)) {
            return bets.length;
        }
        else {
            return betsOfPlayer[player].length;
        }
    }
}