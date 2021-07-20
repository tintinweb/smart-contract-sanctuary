pragma solidity 0.8.3;

// SPDX-License-Identifier: MIT





contract CoinFlip {
    address payable owner;
    address public croupier;

    uint256 public WIN_COEFFICIENT = 195;

    // Maximum amount to bet
    uint256 public MIN_BET = 0.1 ether;
    uint256 public MAX_BET = 10 ether;

    enum GameState {PENDING, WON, LOST}

    struct Game {
        uint256 id;
        address payable player;
        uint256 bet;
        uint256 prize;
        uint256 choice;
        uint256 result;
        GameState state;
    }

    mapping(bytes32 => Game) public games;

    bytes32[] public listGames;

    uint256 public totalGamesCount;

    event GameCreated(
        address indexed player,
        uint256 bet,
        uint256 choice,
        bytes32 seed
    );

    event GamePlayed(
        address indexed player,
        uint256 bet,
        uint256 prize,
        uint256 choice,
        uint256 result,
        bytes32 indexed seed,
        GameState state
    );

    constructor() public payable {
        owner = payable(msg.sender);
        croupier = msg.sender;
    }

    // Modifier for functions that can only be ran by the owner
    modifier onlyOwner() {
        require(msg.sender == owner, 'Only the owner can run this function.');
        _;
    }

    // Modifier for functions that can only be ran by the croupier
    modifier onlyCroupier() {
        require(
            msg.sender == croupier,
            'Only the croupier can run this function.'
        );
        _;
    }

    // Check that the rate is between min and max bet
    modifier betInRange() {
        require(MIN_BET <= msg.value && msg.value <= MAX_BET, 'Rate is not between min and max bet');
        _;
    }

    function play(uint256 _choice, bytes32 _seed) public payable betInRange {
        require(_choice == 0 || _choice == 1, 'Choice should be 0 or 1');

        uint256 possiblePrize = msg.value * WIN_COEFFICIENT / 100;
        require(
            possiblePrize < address(this).balance,
            'Insufficent funds on contract to cover the bet'
        );

        Game storage game = games[_seed];

        require(games[_seed].bet == 0x0, 'Seed already used');

        game.player = payable(msg.sender);
        game.bet = msg.value;
        game.choice = _choice;
        game.state = GameState.PENDING;

        totalGamesCount++;
        listGames.push(_seed);

        emit GameCreated(
            game.player,
            game.bet,
            game.choice,
            _seed
        );
    }

    function confirm(
        bytes32 _seed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public onlyCroupier returns (address) {
        Game storage game = games[_seed];

        require(game.state == GameState.PENDING, 'Game already played');

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _seed));

        // require(ecrecover(prefixedHash, _v, _r, _s) == croupier, 'Invalid signature');

        game.result = uint256(_s) % 2;
        
        if (game.choice == game.result) {
            game.prize = game.bet * WIN_COEFFICIENT / 100;
            game.player.transfer(game.prize);
            game.state = GameState.WON;
        } else {
            game.prize = 0;
            game.state = GameState.LOST;
        }

        emit GamePlayed(
            game.player,
            game.bet,
            game.prize,
            game.choice,
            game.result,
            _seed,
            game.state
        );
    }

    function setBetRange(uint256 min, uint256 max) public onlyOwner {
        MIN_BET = min;
        MAX_BET = max;
    }

    function setWinCoefficient(uint256 amount)
        public
        onlyOwner
        returns (uint256)
    {
        WIN_COEFFICIENT = amount;
        return WIN_COEFFICIENT;
    }

    function setCroupier(address addr) public onlyOwner {
        croupier = addr;
    }

    function withdrawFunds(uint256 amount) public onlyOwner {
        owner.transfer(amount);
    }

    // Function to destroy the contract and send funds to a specific address
    // Requirements:
    // msg.sender is a seller
    function destroyContract() public onlyOwner {
        selfdestruct(owner);
    }

    receive() external payable {}

    // Fallback function
    fallback() external {}
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}