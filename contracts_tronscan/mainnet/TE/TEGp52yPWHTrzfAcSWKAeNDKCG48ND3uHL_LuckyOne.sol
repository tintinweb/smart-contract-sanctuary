//SourceUnit: lucky1.sol

pragma solidity 0.4.25;

//
//___________________________________________________________________
// _ _ ______
// | | / / /
//--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
// |/ |/ /___) / / ' / ) / / ) /___) / / )
//__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_
//
//
//
//¦¦¦¦¦¦¦¦+¦¦¦¦¦¦+ ¦¦¦¦¦¦+ ¦¦¦+ ¦¦+ ¦¦¦¦¦¦¦¦+ ¦¦¦¦¦¦+ ¦¦¦¦¦¦+ ¦¦+ ¦¦¦¦¦+
//+--¦¦+--+¦¦+--¦¦+¦¦+---¦¦+¦¦¦¦+ ¦¦¦ +--¦¦+--+¦¦+---¦¦+¦¦+--¦¦+¦¦¦¦¦+--¦¦+
// ¦¦¦ ¦¦¦¦¦¦++¦¦¦ ¦¦¦¦¦+¦¦+ ¦¦¦ ¦¦¦ ¦¦¦ ¦¦¦¦¦¦¦¦¦++¦¦¦¦¦¦¦¦¦¦¦
// ¦¦¦ ¦¦+--¦¦+¦¦¦ ¦¦¦¦¦¦+¦¦+¦¦¦ ¦¦¦ ¦¦¦ ¦¦¦¦¦+---+ ¦¦¦¦¦+--¦¦¦
// ¦¦¦ ¦¦¦ ¦¦¦+¦¦¦¦¦¦++¦¦¦ +¦¦¦¦¦ ¦¦¦ +¦¦¦¦¦¦++¦¦¦ ¦¦¦¦¦¦ ¦¦¦
// +-+ +-+ +-+ +-----+ +-+ +---+ +-+ +-----+ +-+ +-++-+ +-+
//
//
// ----------------------------------------------------------------------------
// Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
// Developed by Jesse Busman  ( jesse@jesbus.com )
// ----------------------------------------------------------------------------
//


interface BlockHashStorageContract
{
    function blockHashes(uint256 _blockNumber) external view returns (bytes32 _blockHash);
}

interface InterfaceVOUCHERS
{
    function mintVouchers(address _user, uint256 _mainBetSUN, uint256 _siteBetSUN)  external returns(bool);
}


library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        if (a == 0)
        {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        c = a / b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        assert(b <= a);
        c = a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        c = a + b;
        assert(c >= a);
    }
}



contract Owned
{
    address public owner;
    address public newOwner;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor() public
    {
        owner = msg.sender;
    }
    
    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner
    {
        newOwner = _newOwner;
    }
    
    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


//**************************************************************************//
//-------------------    REFERRAL CONTRACT INTERFACE    --------------------//
//**************************************************************************//

interface InterfaceREFERRAL {
    function referrers(address user) external returns(address);
    function updateReferrer(address _user, address _referrer) external returns(bool);
    function payReferrerBonusOnly(address _user,  uint256 _trxAmount ) external returns(bool);
    function payReferrerBonusAndAddReferrer(address _user, address _referrer, uint256 _trxAmount, uint256 _refBonus) external returns(bool);
}


//**************************************************************************//
//-------------------    TOPIA CONTRACT INTERFACE       --------------------//
//**************************************************************************//
interface TRONtopiaInterface
{
    function transfer(address recipient, uint amount) external returns(bool);
    function mintToken(address _user, uint256 _tronAmount)  external returns(bool);
} 


//**************************************************************************//
//---------------------   DIAMOND CONTRACT INTERFACE  ----------------------//
//**************************************************************************//

interface InterfaceDIAMOND
{
    function usersDiamondFrozen(address _user)  external view returns(uint256);
}



/*
PROBABILITY CALCULATIONS:

5 digit number

exactly 0 ones:		chance = 0.1^0 * 0.9^5 * (5c0) = 0.59049
exactly 1 ones:		chance = 0.1^1 * 0.9^4 * (5c1) = 0.32805
exactly 2 ones:		chance = 0.1^2 * 0.9^3 * (5c2) = 0.07290
exactly 3 ones:		chance = 0.1^3 * 0.9^2 * (5c3) = 0.00810
exactly 4 ones:		chance = 0.1^4 * 0.9^1 * (5c4) = 0.00045
exactly 5 ones:		chance = 0.1^5 * 0.9^0 * (5c5) = 0.00001
*/



contract LuckyOne is Owned
{
    using SafeMath for uint256;
    
    
    
    
    //rake variables
    
    uint256 public tempRakePool;
    uint256 public mainRakePool;
    uint256 public mainRakePoolDepositedAllTime;
    uint256 public ownerRakeWithdrawn;
    uint256 public voucherRakeWithdrawn;
    uint256 public diamondRakeWithdrawn;
    uint256 public vaultRakeWithdrawn;
    uint256 public divRakeWithdrawn;
    
    
    uint256 public ownerRakePercent = 20;     //20% of mainRakePool
    uint256 public voucherRakePercent = 20;   //20% of mainRakePool
    uint256 public vaultRakePercent = 20;     //20% of mainRakePool
    uint256 public diamondRakePercent = 20;   //20% of mainRakePool
    uint256 public divRakePercent = 20;       //20% of mainRakePool
    uint256 public globalRakePerMillion = 60000;    //6% of TRX wagered
    
    
    
    
    // Contract settings
    address public topiaTokenContractAddress;
    address public blockHashStorageContractAddress;
    address public dividendContractAddress;
    address public voucherContractAddress;
    address public voucherDividendContractAddress;
    address public vaultContractAddress;
    address public diamondContractAddress;
    address public diamondVoucherContractAddress;
    address public refPoolContractAddress;
    
    
    
    // Game settings
    uint256[8] public amountOfOnes_to_multiplier = [
                   0, // 0 ones: 0 payout
             1000000, // 1 ones: 1x payout
             5000000, // 2 ones: 5x payout
            25000000, // 3 ones: 25x payout
           100000000, // 4 ones: 100x payout
           250000000, // 5 ones: 250x payout
           500000000, // 6 ones: 500x payout
          1000000000  // 7 ones: 1000x payout
    ];
    uint256 public minimumBetTRX = 10;
    uint256 public maximumBetTRX = 25000;
    uint256 public maximumFractionOfContractBalancePayout = 5;
    
    
    
    // Jackpot settings
    uint256 public minimumBetTRXtoQualifyForFullJackpot = 1000;
    uint256 public fullJackpotPayoutPercentage = 75;
    uint256 public lossPromillageIntoJackpot = 10;
    
    
    
    // Misc settings
    uint256 public amountOfOnesToQualifyForRareWins = 3;
    

    //mapping (address => uint256) public accumulatedMintToken;   // total amount of bet of particular player, for minting use, once minting done this value will be zero
    //mapping (address => uint256) public accumulatedMintVoucher;   // total amount of bet of particular player, for minting use, once minting done this value will be zero
    //mapping (address => uint256) public accumulatedMintVoucherSide; // total amount of bet of particular player, for minting use, once minting done this value will be zero
   
    
    // Global state
    uint256 public totalDeposited = 0;
    bool public systemHalted = false;
    uint256 private betExpiredBehaviour = 0;
    // 0: bet is ignored
    // 1: user gets their bet back
    // 2: bet is ignored, system is halted
    // 3: user gets their bet back, system is halted
    
    uint256 public fiveOneJackpotSize = 0;
    uint256 public totalDepositedIntoJackpot = 0;
    
    
    
    // Bet states
    mapping(bytes32 => uint256) public unfinishedBetHash_to_timestamp;
    mapping(address => bytes32) public user_to_lastBetHash;
    
    
    
    
    // Events
    event BetStarted(
        bytes32 indexed _betHash,
        
        uint256 indexed _blockNumber,
        address indexed _gambler,
        
        uint256 _betTRX,
        bytes32 _userSeed,
        bytes32 _uniqueBetId
    );
    event BetExpired(bytes32 indexed _betHash, address indexed _gambler);
    event BetFinished(
        bytes32 indexed _betHash,
        address indexed _gambler,
        
        uint256 _randomNumber,
        uint256 _betTRX,
        uint256 _normalPayout,
        uint256 _jackpotPayout,
        uint256 _profit,
        
        uint256 indexed _timestamp
    );
    event HighRollers(
        bytes32 indexed _betHash,
        address indexed _gambler,
        
        uint256 _randomNumber,
        uint256 _betTRX,
        uint256 _normalPayout,
        uint256 _jackpotPayout,
        uint256 _profit,
        
        uint256 indexed _timestamp
    );
    event RareWins(
        bytes32 indexed _betHash,
        address indexed _gambler,
        
        uint256 _randomNumber,
        uint256 _betTRX,
        uint256 _normalPayout,
        uint256 _jackpotPayout,
        uint256 _profit,
        
        uint256 indexed _timestamp
    );
    
    
    
    // Bet data structure
    struct Bet
    {
        uint256 blockNumber;
        address gambler;
        
        uint256 betTRX;
        bytes32 userSeed;
        bytes32 uniqueBetId;
    }
/*
    function GetValueAndResetMintPending(address user) public returns(uint256,uint256,uint256)
    {
        require(msg.sender == dividendContractAddress, "invalid caller");
        uint256 d1=accumulatedMintToken[user];
        uint256 d2=accumulatedMintVoucher[user];
        uint256 d3=accumulatedMintVoucherSide[user];
        accumulatedMintToken[user] = 0;
        accumulatedMintVoucher[user] = 0;
        accumulatedMintVoucherSide[user] = 0;
        return (d1,d2,d3);
    }


    function GetValueOfMintPending(address user) public view returns(uint256,uint256,uint256)
    {
        uint256 d1=accumulatedMintToken[user];
        uint256 d2=accumulatedMintVoucher[user];
        uint256 d3=accumulatedMintVoucherSide[user];
        return (d1,d2,d3);
    }*/
   
    // Owner settings functions
    
    function setMultipliers(uint256[8] _newMultipliers) external onlyOwner returns (string)
    {
        amountOfOnes_to_multiplier = _newMultipliers;
        return "Multipliers have been successfully updated";
    }
    
    function setMaximumFractionOfContractBalancePayout(uint256 _maximumFractionOfContractBalancePayedOut) external onlyOwner returns (string)
    {
        maximumFractionOfContractBalancePayout = _maximumFractionOfContractBalancePayedOut;
        return "Maximum payout fraction has been successfully updated";
    }
    
    function setMinimumBetTRXtoQualifyForFullJackpot(uint256 _newMinimumBetTRXtoQualifyForFullJackpot) external onlyOwner returns (string)
    {
        minimumBetTRXtoQualifyForFullJackpot = _newMinimumBetTRXtoQualifyForFullJackpot;
        return "Done";
    }
    
    function setFullJackpotPayoutPercentage(uint256 _newFullJackpotPayoutPercentage) external onlyOwner returns (string)
    {
        fullJackpotPayoutPercentage = _newFullJackpotPayoutPercentage;
        return "Full jackpot payout percentage";
    }
    
    function setAmountOfOnesToQualifyForRareWins(uint256 _newAmountOfOnesToQualifyForRareWins) external onlyOwner returns (string)
    {
        amountOfOnesToQualifyForRareWins = _newAmountOfOnesToQualifyForRareWins;
        return "Done";
    }
    
    function setLossPromillageIntoJackpot(uint256 _newLossPromillageIntoJackpot) external onlyOwner returns (string)
    {
        lossPromillageIntoJackpot = _newLossPromillageIntoJackpot;
        return "Loss promillage into jackpot has been updated";
    }
    
    function setMinimumBet(uint256 _newMinimumBet) external onlyOwner returns (string)
    {
        minimumBetTRX = _newMinimumBet;
        return "Minimum bet has been successfully updated";
    }
    
    function setMaximumBet(uint256 _newMaximumBet) external onlyOwner returns (string)
    {
        maximumBetTRX = _newMaximumBet;
        return "Maximum bet has been successfully updated";
    }
    
    function setBetExpiredBehaviour(uint256 _betExpiredBehaviour) external onlyOwner
    {
        betExpiredBehaviour = _betExpiredBehaviour;
    }
    
    function setSystemHalted(bool _systemHalted) external onlyOwner
    {
        systemHalted = _systemHalted;
    }
    





    function createBetObject(
        uint256 _blockNumber,
        address _gambler,
        
        uint256 _betTRX,
        bytes32 _userSeed,
        bytes32 _uniqueBetId
    ) private pure returns (Bet memory bet)
    {
        return Bet({
            blockNumber: _blockNumber,
            gambler: _gambler,
            
            betTRX: _betTRX,
            userSeed: _userSeed,
            uniqueBetId: _uniqueBetId
        });
    }
    
    function calculateBetHash(
        uint256 _blockNumber,
        address _gambler,
        
        uint256 _betTRX,
        bytes32 _userSeed,
        bytes32 _uniqueBetId
    ) public pure returns (bytes32)
    {
        return keccak256(abi.encode(
            _blockNumber,
            _gambler,
            
            _betTRX,
            _userSeed,
            _uniqueBetId
        ));
    }
    
    
    
    
    
    
    
    
    
    function finishBet_and_startBet(
        uint256 _blockNumber,
        address _gambler,
        uint256 _betTRX,
        bytes32 _userSeed,
        bytes32 _uniqueBetId,

        
        address _startBet_referrer,
        uint256 _startBet_betTRX,
        bytes32 _startBet_userSeed,
        bytes32 _startBet_uniqueBetId
    ) external payable returns (bool _finishSuccess)
    {
        startBet(
            _startBet_referrer,
            _startBet_betTRX,
            _startBet_userSeed,
            _startBet_uniqueBetId
        );
        
        return finishBet(
            _blockNumber,
            _gambler,
            _betTRX,
            _userSeed,
            _uniqueBetId
        );
    }
    
    
    
    
    function startBet(
        address _referrer,
        
        uint256 _betTRX,
        bytes32 _userSeed,
        bytes32 _uniqueBetId
    ) payable public returns (bytes32 _newUnfinishedBetHash)
    {
        address player = msg.sender;
        
        require(!systemHalted);
        
        // Prevent bets smaller than the minimum
        require(_betTRX >= minimumBetTRX, "Bet is lower than the minimum bet");
        
        // Prevent bets greater than the maximum
        require(_betTRX <= maximumBetTRX, "Bet is greater than the maximum bet");
        
        // User must have sent the same amount of TRX as the sum of all their bets
        require(msg.value == _betTRX.mul(1e6), "Invalid msg.value");
        
        require(player == tx.origin, "startBet may not be called by a smart contract");
        
        require(_referrer != player, "User cannot refer himself");
        
        // Set referer address if user has usd ref link and does not have any existing referer...
        if (_referrer != address(0x0) && refPoolContractAddress != address(0x0) &&  InterfaceREFERRAL(refPoolContractAddress).referrers(player) == address(0x0) )
        {
            // Set their referral address
            InterfaceREFERRAL(refPoolContractAddress).updateReferrer(player, _referrer);
        }

        //Mint vouchers 
        if(voucherContractAddress != address(0x0)){
            //accumulatedMintVoucher[player] += _betTRX * 1e6;
            //accumulatedMintVoucherSide[player] += 0;
            InterfaceVOUCHERS(voucherContractAddress).mintVouchers(player, _betTRX * 1e6, 0);
        }

        
        
        if(topiaTokenContractAddress != address(0)){
            // Mint tokens depending on how much TRX is received
            uint256 usersDiamondFrozen = InterfaceDIAMOND(diamondVoucherContractAddress).usersDiamondFrozen(player);
        
            uint256 extraMint;
            if(usersDiamondFrozen >= 1000000 && usersDiamondFrozen < 1000000000){
                extraMint = usersDiamondFrozen / 1000000;
            }
            else if (usersDiamondFrozen >= 1000000000)
            {
                extraMint = 1000;
            }            
            //uint256 extraMintValue = msg.value * extraMint / 1000;
            //accumulatedMintToken[player] += msg.value + extraMintValue;
            //TRONtopiaInterface(topiaTokenContractAddress).mintToken(player, msg.value + extraMintValue);
        }
        

        tempRakePool += _betTRX * globalRakePerMillion;
        
        
        // Compute the bet hash
        _newUnfinishedBetHash = calculateBetHash(
            block.number,
            player,
            
            _betTRX,
            _userSeed,
            _uniqueBetId
        );
        
        // This bet must not already exist
        require(unfinishedBetHash_to_timestamp[_newUnfinishedBetHash] == 0, "That bet already exists");
        
        // Store the bet hash
        unfinishedBetHash_to_timestamp[_newUnfinishedBetHash] = block.timestamp;
        user_to_lastBetHash[player] = _newUnfinishedBetHash;

        // Store the bet in event
        emit BetStarted(
            _newUnfinishedBetHash,
            
            block.number,
            player,
            
            _betTRX,
            _userSeed,
            _uniqueBetId
        );
        
        
    }
    
    
    
    
    
    
    
    
    
    
    
    function calculateBetResultWithBlockHash(
        uint256 _blockNumber,
        address _gambler,
        bytes32 _blockHash,
        
        uint256 _betTRX,
        bytes32 _userSeed,
        bytes32 _uniqueBetId
    ) public view returns (
        uint256 _randomNumber,
        uint256 _amountOfOnes,
        uint256 _normalPayout,
        uint256 _jackpotPayout,
        uint256 _profit
    )
    {
        Bet memory bet = createBetObject(
            _blockNumber,
            _gambler,
            
            _betTRX,
            _userSeed,
            _uniqueBetId
        );
        
        bytes32 betHash = calculateBetHash(
            _blockNumber,
            _gambler,
            
            _betTRX,
            _userSeed,
            _uniqueBetId
        );
        
        return calculateBetResultWithBlockHash(
            bet,
            betHash,
            _blockHash
        );
    }
    
    
    function calculateBetResult(
        uint256 _blockNumber,
        address _gambler,
        
        uint256 _betTRX,
        bytes32 _userSeed,
        bytes32 _uniqueBetId
    ) public view returns (
        uint256 _randomNumber,
        uint256 _amountOfOnes,
        uint256 _normalPayout,
        uint256 _jackpotPayout,
        uint256 _profit
    )
    {
        return calculateBetResultWithBlockHash(
            _blockNumber,
            _gambler,
            getBlockHash(_blockNumber),
            
            _betTRX,
            _userSeed,
            _uniqueBetId
        );
    }
    
    function getBlockHash(uint256 _blockNumber) public view returns (bytes32)
    {
        if (_blockNumber < block.number-256 && blockHashStorageContractAddress != address(0x0))
        {
            return BlockHashStorageContract(blockHashStorageContractAddress).blockHashes(_blockNumber);
        }
        else
        {
            return blockhash(_blockNumber);
        }
    }
    
    function calculateBetResult(
        Bet memory _bet,
        bytes32 _betHash
    ) private view returns (
        uint256 _randomNumber,
        uint256 _amountOfOnes,
        uint256 _normalPayout,
        uint256 _jackpotPayout,
        uint256 _profit
    )
    {
        return calculateBetResultWithBlockHash(_bet, _betHash, getBlockHash(_bet.blockNumber));
    }
    
    function calculateBetResultWithBlockHash(
        Bet memory _bet,
        bytes32 _betHash,
        bytes32 _blockHash
    ) private view returns (
        uint256 _randomNumber,
        uint256 _amountOfOnes,
        uint256 _normalPayout,
        uint256 _jackpotPayout,
        uint256 _profit
    )
    {
        // Bet hash must exist
        //require(unfinishedBetHash_to_timestamp[_betHash] != 0, "That bet does not exist or is already finished.");
        
        // Generate random number for main bet & side bet
        require(_blockHash != 0x0, "Too late or too early to calculate bet result.");
        
        bytes32 _randomSeed = keccak256(abi.encode(_blockHash, _betHash));

        
        
        //double RNG logic

        //fist winning number. that number will be anywhere between 0 - 10000000000000000000
        _randomNumber = uint256(_randomSeed) % 10000000000000000000;


        //final winning number from DOUBLE RNG calculation
        _randomNumber = uint256(keccak256(abi.encode(_randomSeed, _randomNumber))) % 10000000;
        
        
        
        
        // Count the amount of 1's
        _amountOfOnes = 0;
        for (uint256 i=0; i<7; i++)
        {
            if (((_randomNumber / (uint256(10) ** i)) % 10) == 1) _amountOfOnes++;
        }
        
        // Calculate the payout
        _normalPayout = _bet.betTRX * amountOfOnes_to_multiplier[_amountOfOnes];
        
        // Limit the payout to the maximum
        uint256 maximumPayout = maxWin();
        if (_normalPayout > maximumPayout)
        {
            _normalPayout = maximumPayout;
        }
        
        // If they won the jackpot...
        if (_amountOfOnes == 7)
        {
            if (_bet.betTRX >= minimumBetTRXtoQualifyForFullJackpot)
            {
                _jackpotPayout = fiveOneJackpotSize * fullJackpotPayoutPercentage / 100;
            }
            else
            {
                _jackpotPayout = fiveOneJackpotSize * fullJackpotPayoutPercentage / 100 * _bet.betTRX / minimumBetTRXtoQualifyForFullJackpot;
            }
        }
        
        if (_normalPayout + _jackpotPayout > _bet.betTRX * 1e6)
        {
            _profit = (_normalPayout + _jackpotPayout).sub(_bet.betTRX * 1e6);
        }
        else
        {
            _profit = 0;
        }
    }
    
    
    function maxWin() public view returns(uint256){
        return (address(this).balance.sub(fiveOneJackpotSize + tempRakePool + mainRakePool)) / maximumFractionOfContractBalancePayout;
    }
    
    
    
    function finishManyBets(
        uint256[] _blockNumber,
        address[] _gambler,
        
        uint256[] _betTRX,
        bytes32[] _userSeed,
        bytes32[] _uniqueBetId,
        
        uint256 _lowLevelGas
    ) public returns (uint256 _amountFinished)
    {
        for (uint256 i=0; i<_gambler.length; i++)
        {
            if (finishBet(
                _blockNumber[i],
                _gambler[i],
                
                _betTRX[i],
                _userSeed[i],
                _uniqueBetId[i]
            )) _amountFinished++;
            
            if (gasleft() < _lowLevelGas)
            {
                break;
            }
        }
    }
    
    
    function finishBet(
        uint256 _blockNumber,
        address _gambler,
        
        uint256 _betTRX,
        bytes32 _userSeed,
        bytes32 _uniqueBetId
    ) public returns (bool _success)
    {
        require(!systemHalted, "System is halted");
        
        Bet memory bet = createBetObject(
            _blockNumber,
            _gambler,
            
            _betTRX,
            _userSeed,
            _uniqueBetId
        );
        
        bytes32 betHash = calculateBetHash(
            _blockNumber,
            _gambler,
            
            _betTRX,
            _userSeed,
            _uniqueBetId
        );
        
        return finishBet(bet, betHash);
    }
    
    function finishBet(
        Bet memory _bet,
        bytes32 _betHash
    ) private returns (bool _success)
    {
        uint256 betTimestamp = unfinishedBetHash_to_timestamp[_betHash];
        
        // If the bet has already been finished, or the bet never existed, do nothing
        if (betTimestamp == 0) { return false; }
        
        // If we can't finish this bet yet, do nothing
        if (_bet.blockNumber >= block.number) { return false; }
        
        // If the bet has expired...
        if (_bet.blockNumber < block.number-256 && (blockHashStorageContractAddress == address(0x0) || BlockHashStorageContract(blockHashStorageContractAddress).blockHashes(_bet.blockNumber) == 0x0))
        {
            emit BetExpired(_betHash, _bet.gambler);
            
            // User gets their bet back
            if (betExpiredBehaviour == 1 || betExpiredBehaviour == 3)
            {
                _bet.gambler.transfer(_bet.betTRX.mul(1e6));
            }
            
            // System is halted
            if (betExpiredBehaviour == 2 || betExpiredBehaviour == 3)
            {
                systemHalted = true;
            }
            
            return false;
        }
        
        // Calculate the result of this bet
        (
            uint256 randomNumber,
            uint256 amountOfOnes,
            uint256 normalPayout,
            uint256 jackpotPayout,
            uint256 profit
        ) = calculateBetResult(
            _bet,
            _betHash
        );
        
        uint256 totalPayout = normalPayout + jackpotPayout;
        
        // Emit events
        emit BetFinished(
            _betHash,
            _bet.gambler,
            randomNumber,
            _bet.betTRX,
            normalPayout,
            jackpotPayout,
            profit,
            
            betTimestamp
        );
        
        if (_bet.betTRX > 10000)
        {
            emit HighRollers(
                _betHash,
                _bet.gambler,
                randomNumber,
                _bet.betTRX,
                normalPayout,
                jackpotPayout,
                profit,
                
                betTimestamp
            );
        }
        
        if (amountOfOnes >= amountOfOnesToQualifyForRareWins)
        {
            emit RareWins(
                _betHash,
                _bet.gambler,
                randomNumber,
                _bet.betTRX,
                normalPayout,
                jackpotPayout,
                profit,
                
                betTimestamp
            );
        }
        
        if (jackpotPayout > 0)
        {
            fiveOneJackpotSize = fiveOneJackpotSize.sub(jackpotPayout);
        }
        
        // If the user lost
        if (totalPayout == 0)
        {
            fiveOneJackpotSize = fiveOneJackpotSize.add(_bet.betTRX * 1e6 * lossPromillageIntoJackpot / 1000);
        }
        
        // Mark bet as finished
        unfinishedBetHash_to_timestamp[_betHash] = 0;
        
        // If the user won anything their referrer gets payed
        if (refPoolContractAddress != address(0x0) && InterfaceREFERRAL(refPoolContractAddress).referrers(_bet.gambler) != address(0x0))
        {
            // Processing referral system fund distribution
            // [?] 0.2% trx to referral if any.
            InterfaceREFERRAL(refPoolContractAddress).payReferrerBonusOnly(_bet.gambler, _bet.betTRX * 1e6);
        }
        
        // Transfer the amount won
        if (totalPayout > 0)
        {
            _bet.gambler.transfer(totalPayout);
        }
        
        return true;
    }
    
    
    function addRakeToMainPool() internal{
        if(tempRakePool > 0){
            mainRakePool += tempRakePool;
            mainRakePoolDepositedAllTime += tempRakePool;
            tempRakePool = 0;
        }
    }
    
    
    function getAvailableOwnerRake() public view returns (uint256){
        uint256 mainRake;
        if(mainRakePoolDepositedAllTime > ownerRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - ownerRakeWithdrawn;
            mainRake = totalRake * ownerRakePercent / 100;
        }
        uint256 tempRake = tempRakePool * ownerRakePercent / 100;
        
        return mainRake + tempRake;
        
    }
    
    
    function getAvailableVoucherRake() public view returns (uint256){
        uint256 mainRake;
        if(mainRakePoolDepositedAllTime > voucherRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - voucherRakeWithdrawn;
            mainRake = totalRake * voucherRakePercent / 100;
        }
        uint256 tempRake = tempRakePool * voucherRakePercent / 100;
        
        return mainRake + tempRake;
        
    }
    
    
    function getAvailableVaultRake() public view returns (uint256){
        uint256 mainRake;
        if(mainRakePoolDepositedAllTime > vaultRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - vaultRakeWithdrawn;
            mainRake = totalRake * vaultRakePercent / 100;
        }
        uint256 tempRake = tempRakePool * vaultRakePercent / 100;
        
        return mainRake + tempRake;
        
    }
    
    function getAvailableDiamondRake() public view returns (uint256){
        uint256 mainRake;
        if(mainRakePoolDepositedAllTime > diamondRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - diamondRakeWithdrawn;
            mainRake = totalRake * diamondRakePercent / 100;
        }
        uint256 tempRake = tempRakePool * diamondRakePercent / 100;
        
        return mainRake + tempRake;
        
    }


    function getAvailableDivRake() public view returns (uint256){
        uint256 mainRake;
        if(mainRakePoolDepositedAllTime > divRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - divRakeWithdrawn;
            mainRake = totalRake * divRakePercent / 100;
        }
        uint256 tempRake = tempRakePool * divRakePercent / 100;
        
        return mainRake + tempRake;
        
    }
    
    
    
    function withdrawOwnerPool() external onlyOwner returns (string)
    {
        //first transfer any outstanding rake from temp to main rake pool
        addRakeToMainPool();
        
        if(mainRakePoolDepositedAllTime > ownerRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - ownerRakeWithdrawn;
            
            //taking % of that
            uint256 finalOwnerRake = totalRake * ownerRakePercent / 100;
            mainRakePool = mainRakePool.sub(finalOwnerRake);
            ownerRakeWithdrawn = mainRakePoolDepositedAllTime;
            
            //transferring rake amount
            msg.sender.transfer(finalOwnerRake);
            
            return "Owner rake withdrawn successfully";
            
        }
        
        return "Nothing to withdraw";
    }

    
    
    function totalTRXbalanceContract() public view returns (uint256)
    {
        return address(this).balance;
    }
    
    

    
    function depositTRXintoJackpot() payable public onlyOwner returns (string)
    {
        totalDepositedIntoJackpot += msg.value;
        fiveOneJackpotSize += msg.value;
        return "Deposit successful";
    }
    
    function withdrawDepositedTRXfromJackpot(uint256 _amountSun) external onlyOwner returns (string)
    {
        require(_amountSun <= totalDepositedIntoJackpot);
        totalDepositedIntoJackpot = totalDepositedIntoJackpot.sub(_amountSun);
        fiveOneJackpotSize = fiveOneJackpotSize.sub(_amountSun);
        msg.sender.transfer(_amountSun);
        return "Withdrawal success";
    }
    
    
    function availableToWithdrawOwner() public view returns(uint256){
        return address(this).balance.sub(fiveOneJackpotSize + tempRakePool + mainRakePool);
    }
    
    
    function manualWithdrawTRX(uint256 amountSUN) public onlyOwner returns (string)
    {
        uint256 availableToWithdraw = address(this).balance.sub(fiveOneJackpotSize + tempRakePool + mainRakePool);
        
        require(availableToWithdraw > amountSUN, 'withdrawing more than available');
        
        owner.transfer(amountSUN);
        return "Transaction successful";
    }
    

    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns (string)
    {
        TRONtopiaInterface(topiaTokenContractAddress).transfer(msg.sender, tokenAmount);
        return "Transaction successful";
    }
    
    function updateContractAddresses(address topiaContract, address voucherContract, address dividendContract, address refPoolContract, address vaultContract, address diamondContract,address diamondVoucherContract, address voucherDividendContract) public onlyOwner returns(string)
    {
        
        topiaTokenContractAddress = topiaContract;
        voucherContractAddress = voucherContract;
        voucherDividendContractAddress = voucherDividendContract;
        dividendContractAddress = dividendContract;
        refPoolContractAddress = refPoolContract;
        vaultContractAddress = vaultContract;
        diamondContractAddress = diamondContract;
        diamondVoucherContractAddress = diamondVoucherContract;
        return "done";
    }


   


    function updateBlockHashStorageContractAddress(address _newBlockHashStorageContractAddress) public onlyOwner returns (string)
    {
        blockHashStorageContractAddress = _newBlockHashStorageContractAddress;
        return "Block hash storage contract address updated";
    }
    
    
    function updateRakePercents(uint256 _ownerRakePercent, uint256 _voucherRakePercent, uint256 _vaultRakePercent, uint256 _diamondRakePercent, uint256 _divRakePercent) external onlyOwner returns (string)
    {
        require(_ownerRakePercent <= 100 && _voucherRakePercent <= 100 && _vaultRakePercent <= 100 && _diamondRakePercent <= 100, 'Invalid amount' );
        ownerRakePercent = _ownerRakePercent;
        voucherRakePercent = _voucherRakePercent;
        vaultRakePercent = _vaultRakePercent;
        diamondRakePercent = _diamondRakePercent;
        divRakePercent = _divRakePercent;
        return "All rake percents updated successfully";
    }

    
    function updateGlobalRakePerMillion(uint256 newGlobalRakePerMillion) external onlyOwner returns (string){
        require(newGlobalRakePerMillion < 1000000, 'Invalid amount');
        globalRakePerMillion = newGlobalRakePerMillion;
        return "globalRakePerMillion updated successfully";
    }
    
    


    

    //-------------------------------------------------//
    //---------------- DIVIDEND SECTION ---------------//
    //-------------------------------------------------//



    function requestDividendPayment(uint256 dividendAmount) public returns(bool)
    {
        require(msg.sender == topiaTokenContractAddress || msg.sender == dividendContractAddress, 'Unauthorised caller');
        msg.sender.transfer(dividendAmount);
        return true;
    }
    
    
    /**
     * This function can be called by voucher contract to request payment of voucherRakePool
     */
    function requestVoucherRakePayment() public returns(bool){
        
        require(msg.sender == voucherDividendContractAddress, 'Unauthorised caller');
        
        //first transfer any outstanding rake from temp to main rake pool
        addRakeToMainPool();
        
        if(mainRakePoolDepositedAllTime > voucherRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - voucherRakeWithdrawn;
            
            //taking % of that
            uint256 finalVoucherRake = totalRake * voucherRakePercent / 100;
            mainRakePool = mainRakePool.sub(finalVoucherRake);
            voucherRakeWithdrawn = mainRakePoolDepositedAllTime;
            
            //transferring rake amount
            msg.sender.transfer(finalVoucherRake);
            
        }
        
        return true;
    }
    
    /**
     * This function can be called by vault contract to request payment of vaultRakePool
     */
    function requestVaultRakePayment() public returns(bool){
        
        require(msg.sender == vaultContractAddress, 'Unauthorised caller');
        
        //first transfer any outstanding rake from temp to main rake pool
        addRakeToMainPool();
        
        if(mainRakePoolDepositedAllTime > vaultRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - vaultRakeWithdrawn;
            
            //taking % of that
            uint256 finalRake = totalRake * vaultRakePercent / 100;
            mainRakePool = mainRakePool.sub(finalRake);
            vaultRakeWithdrawn = mainRakePoolDepositedAllTime;
            
            //transferring rake amount
            msg.sender.transfer(finalRake);
            
        }
        
        return true;
    }


    /**
     * This function can be called by diamond contract to request payment of diamondRakePool
     */
    function requestDiamondRakePayment() public returns(bool){
        
        require(msg.sender == diamondContractAddress, 'Unauthorised caller');
        
        //first transfer any outstanding rake from temp to main rake pool
        addRakeToMainPool();
        
        if(mainRakePoolDepositedAllTime > diamondRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - diamondRakeWithdrawn;
            
            //taking % of that
            uint256 finalRake = totalRake * diamondRakePercent / 100;
            mainRakePool = mainRakePool.sub(finalRake);
            diamondRakeWithdrawn = mainRakePoolDepositedAllTime;
            
            //transferring rake amount
            msg.sender.transfer(finalRake);
            
        }
        
        return true;
    }


    /**
     * This function can be called by dividend contract to request payment of divRakePool
     */
    function requestDivRakePayment(uint256 requestedAmount) public returns(bool){
        
        require(msg.sender == dividendContractAddress, 'Unauthorised caller');
        
        //first transfer any outstanding rake from temp to main rake pool
        addRakeToMainPool();
        
        if(mainRakePoolDepositedAllTime > divRakeWithdrawn ){
            uint256 totalRake = mainRakePoolDepositedAllTime - divRakeWithdrawn;
            
            //taking % of that
            uint256 finalRake = totalRake * divRakePercent / 100;

            //if requestedAmount is higher than available finalRake, then it will simply return false as... 
            //we want to return false because it will break loop in dividend contract 
            //because there is no normal case, when requestedAmount would be higher than finalRake
            if(finalRake < requestedAmount) {return false;}

            mainRakePool = mainRakePool.sub(requestedAmount);
            divRakeWithdrawn = mainRakePoolDepositedAllTime - ((finalRake - requestedAmount) * (100 / divRakePercent) );
            
            //transferring rake amount
            msg.sender.transfer(requestedAmount);
            
        }
        
        return true;
    }
    
    
    /**
        Function to deposit into rake pool
    */
    function manuallyFundRakePools() public payable onlyOwner returns(string){
        require(msg.value > 0, 'Not emough TRX');
        
        tempRakePool += msg.value;
        
        return "Pool funded successfully";
        
    }


    

}