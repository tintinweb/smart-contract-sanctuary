/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20
{
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IReceivesBogRandV2
{
    function receiveRandomness(bytes32 hash, uint256 random) external;
}

interface IBogRandOracleV2
{
    // Request randomness with fee in BOG
    function getBOGFee() external view returns (uint256);
    function requestRandomness() external payable returns (bytes32 assignedHash, uint256 requestID);

    // Request randomness with fee in BNB
    function getBNBFee() external view returns (uint256);
    function requestRandomnessBNBFee() external payable returns (bytes32 assignedHash, uint256 requestID);
    
    // Retrieve request details
    enum RequestState { REQUESTED, FILLED, CANCELLED }
    function getRequest(uint256 requestID) external view returns (RequestState state, bytes32 hash, address requester, uint256 gas, uint256 requestedBlock);
    function getRequest(bytes32 hash) external view returns (RequestState state, uint256 requestID, address requester, uint256 gas, uint256 requestedBlock);
    // Get request blocks to use with blockhash as hash seed
    function getRequestBlock(uint256 requestID) external view returns (uint256);
    function getRequestBlock(bytes32 hash) external view returns (uint256);

    // RNG backend functions
    function seed(bytes32 hash) external;
    function getNextRequest() external view returns (uint256 requestID);
    function fulfilRequest(uint256 requestID, uint256 random, bytes32 newHash) external;
    function cancelRequest(uint256 requestID, bytes32 newHash) external;
    function getFullHashReserves() external view returns (uint256);
    function getDepletedHashReserves() external view returns (uint256);
    
    // Events
    event Seeded(bytes32 hash);
    event RandomnessRequested(uint256 requestID, bytes32 hash);
    event RandomnessProvided(uint256 requestID, address requester, uint256 random);
    event RequestCancelled(uint256 requestID);
}

contract NiuRoulette is IReceivesBogRandV2
{
    struct Game
    {
        address player;
        uint256 amount;
        uint256 stake;
    }
    
    struct Bets
    {
        uint256 lowerValue;
        uint256 upperValue;
        uint256 rewardMultiplier;
    }
    
    // game data
    Bets[42] private availableBets;
    bytes32[37] private colors;
    
    mapping(bytes32 => Game) pendingGames;
    
    address public owner; // owner address
    IBEP20 public immutable niu; // NIU token
    bool public initialized = false;
    
    // RNG oracle
    IBogRandOracleV2 public immutable rng;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    // event
    event Roulette(address indexed player, uint256 amount, uint256 stake, uint256 result, uint256 wonAmount);
    
    modifier onlyOwner()
    {
        require(msg.sender == owner, 'Only owner can do this action');
        _;
    }
    
    modifier isInitialized(bool expected)
    {
        require(initialized == expected, 'Error: game initialization');
        _;
    }
    
    constructor(IBEP20 _niu, address rngOracle)
    {
        owner = msg.sender;
        niu = _niu;
        rng = IBogRandOracleV2(rngOracle);
    }
    
    function initialize() external onlyOwner isInitialized(false)
    {
        // INIT INITIAL VALUES
        availableBets[0] = Bets(0, 0, 36);
        colors[0] = 'green';
        
        // INIT EXACT NUMBERS BETS
        for (uint256 i = 1; i < 37; i++)
        {
            availableBets[i] = Bets(i, i, 36);
            colors[i] = (i % 2 == 0) ? bytes32('red') : bytes32('black');
        }
        
        // 1st12 - 2nd12 - 3rd12
        availableBets[37] = Bets(1, 12, 3);
        availableBets[38] = Bets(13, 24, 3);
        availableBets[39] = Bets(25, 36, 3);
        
        // 1to18 - 19to36
        availableBets[40] = Bets(1, 18, 2);
        availableBets[41] = Bets(19, 36, 2);
        
        initialized = true;
    }
    
    function play(uint256 _amount, uint256 _stake) external payable isInitialized(true)
    {
        uint256 playerBalance = niu.balanceOf(msg.sender);
        require(playerBalance >= _amount, 'Not enough tokens to bet this amount');
        require(_stake >= 0 && _stake <= 45, 'Invalid stake');
        
        uint256 fee = rng.getBNBFee();
        require(msg.value >= fee, 'Insufficient fee');
        
        // pay
        niu.transferFrom(msg.sender, address(this), _amount);
        
        (bytes32 hash,) = rng.requestRandomnessBNBFee{value: fee}();
        pendingGames[hash] = Game(msg.sender, _amount, _stake);
    }
    
    // receive randomness from BOG oracle, and process the proper data
    function receiveRandomness(bytes32 hash, uint256 random) external override
    {
        require(msg.sender == address(rng), 'Error: restriction to oracle'); // restriction to oracle
        
        Game memory game = pendingGames[hash];
        Bets memory bet = availableBets[game.stake];
        
        uint256 rand = random % 37; // number between 0 and 36
        uint256 wonAmount = 0;
        if (game.stake < 42 && rand >= bet.lowerValue && rand <= bet.upperValue)
        {
            wonAmount = game.amount * bet.rewardMultiplier;
            safeNiuTransfer(game.player, wonAmount); // reward player
        }
        else if (
            (game.stake == 42 && rand % 2 == 0) || // EVEN
            (game.stake == 43 && rand % 2 != 0) || // ODD
            (game.stake == 44 && colors[rand] == 'red') || // RED
            (game.stake == 45 && colors[rand] == 'black') // BLACK
        )
        {
            wonAmount = game.amount * 2;
            safeNiuTransfer(game.player, wonAmount); // reward player
        }
        else
        {
            niu.transfer(BURN_ADDRESS, game.amount); // burn NIU if game is lost
        }
        
        // emit event
        emit Roulette(game.player, game.amount, game.stake, rand, wonAmount);
        
        delete pendingGames[hash];
    }
    
    // Safe NIU transfer function, just in case if rounding error causes contract's balance not to have enough NIU tokens.
    function safeNiuTransfer(address _to, uint256 _amount) internal
    {
        uint256 balance = niu.balanceOf(address(this));
        if (_amount > balance)
        {
            niu.transfer(_to, balance);
        }
        else
        {
            niu.transfer(_to, _amount);
        }
    }
}