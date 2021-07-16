//SourceUnit: Ultimate_Dice.sol

pragma solidity 0.4.25; /*


  _______ _____   ____  _   _ _              _           _____                          _       
 |__   __|  __ \ / __ \| \ | | |            (_)         |  __ \                        | |      
    | |  | |__) | |  | |  \| | |_ ___  _ __  _  __ _    | |__) | __ ___  ___  ___ _ __ | |_ ___ 
    | |  |  _  /| |  | | . ` | __/ _ \| '_ \| |/ _` |   |  ___/ '__/ _ \/ __|/ _ \ '_ \| __/ __|
    | |  | | \ \| |__| | |\  | || (_) | |_) | | (_| |   | |   | | |  __/\__ \  __/ | | | |_\__ \
    |_|  |_|  \_\\____/|_| \_|\__\___/| .__/|_|\__,_|   |_|   |_|  \___||___/\___|_| |_|\__|___/
                                      | |                                                       
                                      |_|                                                       


    ██╗   ██╗██╗  ████████╗██╗███╗   ███╗ █████╗ ████████╗███████╗    ██████╗ ██╗ ██████╗███████╗
    ██║   ██║██║  ╚══██╔══╝██║████╗ ████║██╔══██╗╚══██╔══╝██╔════╝    ██╔══██╗██║██╔════╝██╔════╝
    ██║   ██║██║     ██║   ██║██╔████╔██║███████║   ██║   █████╗      ██║  ██║██║██║     █████╗  
    ██║   ██║██║     ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══╝      ██║  ██║██║██║     ██╔══╝  
    ╚██████╔╝███████╗██║   ██║██║ ╚═╝ ██║██║  ██║   ██║   ███████╗    ██████╔╝██║╚██████╗███████╗
    ╚═════╝ ╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    ╚═════╝ ╚═╝ ╚═════╝╚══════╝
                                                                                                


----------------------------------------------------------------------------------------------------

=== MAIN FEATURES ===
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation 
    => Random Number generation using: block hash, block number, user address, bet amount, bet type and user-provided seed
    => Dividend payout
    => Sidebet Jackpot
    => Topia Freeze Tiers
    => Community Audit by Bug Bounty program


------------------------------------------------------------------------------------------------------
 Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
 Contract designed by Jesse Busman  ( jesse@jesbus.com )
 and by EtherAuthority  ( https://EtherAuthority.io )
------------------------------------------------------------------------------------------------------
*/


//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        if (a == 0) { return 0; }
        c = a * b;
        require(c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        require(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        c = a + b;
        require(c >= a);
    }
}



//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned
{
    address internal owner;
    address internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



//**************************************************************************//
//---------------------  TRONTOPIA CONTRACT INTERFACE  ---------------------//
//**************************************************************************//

interface InterfaceTOPIA
{
    function transfer(address recipient, uint256 amount) external returns(bool);
    function mintToken(address _user, uint256 _tronAmount)  external returns(bool);
}




//**************************************************************************//
//---------------------   VOUCHERS CONTRACT INTERFACE  ---------------------//
//**************************************************************************//

interface InterfaceVOUCHERS
{
    function mintVouchers(address _user, uint256 _mainBetSUN, uint256 _siteBetSUN)  external returns(bool);
}


//**************************************************************************//
//-------------------    REFERRAL CONTRACT INTERFACE    --------------------//
//**************************************************************************//

interface InterfaceREFERRAL {
    function referrers(address user) external returns(address);
    function updateReferrer(address _user, address _referrer) external returns(bool);
    function payReferrerBonusOnly(address _user, uint256 _trxAmount ) external returns(bool);
    function payReferrerBonusAndAddReferrer(address _user, address _referrer, uint256 _trxAmount, uint256 _refBonus) external returns(bool);
}



//**************************************************************************//
//---------------------   DIAMOND CONTRACT INTERFACE  ----------------------//
//**************************************************************************//

interface InterfaceDIAMOND
{
    function usersDiamondFrozen(address _user)  external view returns(uint256);
}


    
//**************************************************************************//
//---------------------  DICE GAME MAIN CODE STARTS HERE -------------------//
//**************************************************************************//

contract TRONtopia_ultimate_dice is owned
{
    using SafeMath for uint256;
    uint256[] private multipliersData;
    address public topiaTokenContractAddress;
    address public dividendContractAddress;
    address public voucherContractAddress;
    address public voucherDividendContractAddress;
    address public vaultContractAddress;
    address public diamondContractAddress;
    address public diamondVoucherContractAddress;
    address public refPoolContractAddress;
    uint256 public totalDepositedTRX;
    uint256 public totalDepositedIntoJackpot;

    

    uint256 private constant  _yin = 1;
    uint256 private constant _yang = 2;
    uint256 private constant _bang = 3;
    uint256 private constant _zero = 4;
    uint256 private constant  _odd = 5;
    uint256 private constant _even = 6; 

    uint256 private yinMultiplier = 21111;
    uint256 private yangMultiplier = 21111;
    uint256 private bangMultiplier = 95000;
    uint256 private zeroMultiplier = 950000;
    uint256 private oddMultiplier = 19000;
    uint256 private evenMultiplier = 19000;
    
    uint256 public maxBetAmount = 500000;
    uint256 public minimumSideBetAmountTRX = 25;
    uint256 public minimumMainBetAmountTRX = 10;
    uint256 private maxWinDivisibleAmount = 50;
    
    // Side bet jackpot
    uint256 public sideBetAmountTRXtoQualifyForMaximumJackpot = 1000;
    uint256 public sideBetLossPercentageForProgressiveJackpot = 10;
    uint256 public maximumPercentageOfJackpotSizeWon = 75;
    uint256 public jackpotSizePercentageToDividendPool = 10;
    uint256 private sideBetJackpotMaxOdd = 1000000;          // 1 Million is highest odd of sidebet jackpot
    uint256 private sideBetJackpotFixNumber = 1000;          // so the odd to get this number would be 1:1000000

    bool public systemHalted = false;
    
    uint256 public voucherRakeStatus = 2;
    // 0: only main bet
    // 1: only side bet
    // 2: both main bet and side bet
    //mapping (address => uint256) public accumulatedMintToken;   // total amount of bet of particular player, for minting use, once minting done this value will be zero
    //mapping (address => uint256) public accumulatedMintVoucher;   // total amount of bet of particular player, for minting use, once minting done this value will be zero
    //mapping (address => uint256) public accumulatedMintVoucherSide; // total amount of bet of particular player, for minting use, once minting done this value will be zero

    uint256 private betExpiredBehaviour = 0;
    // 0: bet is ignored
    // 1: user gets their bet back
    // 2: bet is ignored, system is halted
    // 3: user gets their bet back, system is halted

    event BetStarted(bytes32 indexed _betHash, address indexed _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 indexed _blockNumber, uint256[5] _rollIntegerVariables);
    event BetFinished(bytes32 indexed _betHash);
    event BetExpired(bytes32 betHash, address user, uint256 betAmount);
    event BetRefunded(bytes32 indexed _betHash, address indexed _gambler, uint256 _amountRefunded);
    event Roll(address indexed user, uint256 _startNumber, uint256 _endNumber, uint256 _winningNumber, uint256 indexed _value, bool indexed result, uint256 timestamp);
    event KingTopian(address indexed user, uint256 _prize, uint256 _trxplayed, uint256 timestamp);
    event UnluckyBunch(address indexed user, uint256 _loose, uint256 _trxplayed, uint256 timestamp);
    event HighRollers(address indexed user, uint256 _startNumber, uint256 _endNumber, uint256 _winningNumber, uint256 _value, uint256 _winamount, bool result, uint256 timestamp);
    event RareWins(address indexed user, uint256 _startNumber, uint256 _endNumber, uint256 _winningNumber, uint256 _value, uint256 _winamount, bool result, uint256 timestamp);
    event SideBetRolls(address indexed user, uint256 _winningNumber, uint256 _betValue, uint256 winAmount, uint256 sideBet, bool result, uint256 timestamp);
    event SideBetJackpot(address indexed winner, uint256 lukyNumber, uint256 jackpotAmount);

    // Fallback function. It just accepts incoming TRX
    function () payable external
    {
    }
    
    constructor() public
    {
        blockHashes.length = ~uint256(0);
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



    // setMultiplierData stores multiplier array data in the contract
    // [965000,482500,321667,241250,193000,160833,137857,120625,107222,96500,87727,80417,74231,68929,64333,60313,56765,53611,50789,48250,45952,43864,41957,40208,38600,37115,35741,34464,33276,32167,31129,30156,29242,28382,27571,26806,26081,25395,24744,24125,23537,22976,22442,21932,21444,20978,20532,20104,19694,19300,18922,18558,18208,17870,17545,17232,16930,16638,16356,16083,15820,15565,15317,15078,14846,14621,14403,14191,13986,13786,13592,13403,13219,13041,12867,12697,12532,12372,12215,12063,11914,11768,11627,11488,11353,11221,11092,10966,10843,10722,10604,10489,10376,10266,10158,10208]
    function setMultiplierData(uint256[] memory data) public onlyOwner returns (string)
    {
        multipliersData = data;
        return "Multiplier Added";
    }
    
    function setBetExpiredBehaviour(uint256 _betExpiredBehaviour) external onlyOwner
    {
        betExpiredBehaviour = _betExpiredBehaviour;
    }
    
    function setSystemHalted(bool _systemHalted) external onlyOwner
    {
        systemHalted = _systemHalted;
    }
    
    
    
    struct Bet
    {
        address gambler;
        bytes32 uniqueBetId;
        bytes32 userSeed;
        uint256 blockNumber;
        uint256 startNumber;
        uint256 endNumber;
        uint256 mainBetTRX;
        uint256 sideBetTRX;
        uint256 sideBetType;
    }

    mapping(bytes32 => uint256) public unfinishedBetHash_to_timestamp;
    mapping(address => bytes32) public user_to_lastBetHash;
    
    bytes32[] public blockHashes;
    
    uint256 public currentSideBetJackpotSize = 0;
    
    
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

    
    
    function storeCertainBlockHashes(uint256[] _blockNumbers) external
    {
        for (uint256 i=0; i<_blockNumbers.length; i++)
        {
            uint256 blockNumber = _blockNumbers[i];
            bytes32 blockHash = blockhash(blockNumber);
            if (blockHash != 0x0 && blockHashes[blockNumber] == 0x0)
            {
                blockHashes[blockNumber] = blockHash;
            }
        }
    }
    
    function storeBlockHashesRange(uint256 _firstBlockNumber, uint256 _lastBlockNumber) public
    {
        for (uint256 b=_firstBlockNumber; b<=_lastBlockNumber; b++)
        {
            bytes32 blockHash = blockhash(b);
            if (blockHash != 0x0 && blockHashes[b] == 0x0)
            {
                blockHashes[b] = blockHash;
            }
        }
    }
    
    function storeAllRecentBlockHashes() external
    {
        storeBlockHashesRange(block.number-256, block.number-1);
    }


    // Function to finish multiple bets in one transaction
    function finishManyBets(address[] _gambler, bytes32[] _uniqueBetId, bytes32[] _userSeed, uint256[] _blockNumber, uint256[5][] _rollIntegerVariables, uint256 _lowLevelGas) external
    {
        for (uint256 i=0; i<_gambler.length; i++)
        {
            finishBet(
                _gambler[i],
                _uniqueBetId[i],
                _userSeed[i],
                _blockNumber[i],
                _rollIntegerVariables[i]
            );
            
            if (gasleft() < _lowLevelGas)
            {
                break;
            }
        }
    }
    
    // Function to allow a user to finish their previous bet and start a new one in one transaction.
    function finishBet_and_startBet(
        address _finishBet_gambler,
        bytes32 _finishBet_uniqueBetId,
        bytes32 _finishBet_userSeed,
        uint256 _finishBet_blockNumber,
        uint256[5] _finishBet_rollIntegerVariables,
        
        
        uint256[5] _startBet_rollIntegerVariables,
        address _startBet_referrer,
        bytes32 _startBet_userSeed,
        bytes32 _startBet_uniqueBetId
    ) external payable
    {
        finishBet(
            _finishBet_gambler,
            _finishBet_uniqueBetId,
            _finishBet_userSeed,
            _finishBet_blockNumber,
            _finishBet_rollIntegerVariables
        );
        
        startBet(
            _startBet_rollIntegerVariables,
            _startBet_referrer,
            _startBet_userSeed,
            _startBet_uniqueBetId
        );
    }
    
    
    
    
    /**
    * uint256[] _rollIntegerVariables array contains:
    * _rollIntegerVariables[0] = _startNumber;
    * _rollIntegerVariables[1] = _endNumber;
    * _rollIntegerVariables[2] = _amount;
    * _rollIntegerVariables[3] = _sideBetValue;
    * _rollIntegerVariables[4] = _sideBetType;
    * 
    * Side bet types:
    *   yin = 1
    *   yang = 2
    *   bang = 3
    *   zero = 4
    *   odd = 5
    *   even = 6
    **/
    
    function startBet(uint256[5] _rollIntegerVariables, address _referrer, bytes32 _userSeed, bytes32 _uniqueBetId) payable public returns (bytes32 _newUnfinishedBetHash)
    {
        
        
        require(!systemHalted, "System is halted");
        
        // User must have sent the same amount of TRX as his main bet + his sidebet
        require(msg.value == (_rollIntegerVariables[2].add(_rollIntegerVariables[3])).mul(1e6), "Invalid msg.value");
        
        // The main bet must be at least the minimum main bet
        require(_rollIntegerVariables[2] >= minimumMainBetAmountTRX, 'Main bet amount too low');
        
        // Prevent bets greater than the maximum bet
        require((_rollIntegerVariables[2] + _rollIntegerVariables[3]) <= maxBetAmount, 'Bet amount too large');
        
        // Ensure that:
        //   _rollIntegerVariables[0] >= 0 && _rollIntegerVariables[0] < 100
        //   _rollIntegerVariables[1] >= 0 && _rollIntegerVariables[1] < 100
        //   _rollIntegerVariables[0] <= _rollIntegerVariables[1]
        //   _rollIntegerVariables[1] - _rollIntegerVariables[0] < multipliersData.length
        require(_rollIntegerVariables[1] >= _rollIntegerVariables[0] && _rollIntegerVariables[1] < 100, 'End number must be greater than or equal to start number');
        require(_rollIntegerVariables[1] - _rollIntegerVariables[0] < multipliersData.length, 'Number range too large');
        
        // Validate side bet
        if (_rollIntegerVariables[3] > 0)
        {
            require(_rollIntegerVariables[4] >= 1 && _rollIntegerVariables[4] <= 6, 'Invalid side bet type');
            require(_rollIntegerVariables[3] >= minimumSideBetAmountTRX, 'Side bet amount is below the minimum');
        }
        else
        {
            require(_rollIntegerVariables[4] == 0, 'Side bet type selected, but no side bet value provided');
        }

        // startBet may not be called by another smart contract
        require(msg.sender == tx.origin, 'Caller must not be Contract Address');
        
        require(_referrer != msg.sender, 'User cannot refer himself');
        
        // Set referer address if user has usd ref link and does not have any existing referer...
        if (_referrer != address(0x0) && refPoolContractAddress != address(0x0) &&  InterfaceREFERRAL(refPoolContractAddress).referrers(msg.sender) == address(0x0) )
        {
            // Set their referral address
            InterfaceREFERRAL(refPoolContractAddress).updateReferrer(msg.sender, _referrer);
        }


        
        if(topiaTokenContractAddress != address(0)){
            // Mint tokens depending on how much TRX is received
            uint256 usersDiamondFrozen = InterfaceDIAMOND(diamondVoucherContractAddress).usersDiamondFrozen(msg.sender);
        
            uint256 extraMint;
            if(usersDiamondFrozen >= 1000000 && usersDiamondFrozen < 1000000000){
                extraMint = usersDiamondFrozen / 1000000;
            }
            else if (usersDiamondFrozen >= 1000000000)
            {
                extraMint = 1000;
            }            
            //uint256 extraMintValue = msg.value * extraMint / 1000;
            //accumulatedMintToken[msg.sender] += msg.value + extraMintValue;
            //InterfaceTOPIA(topiaTokenContractAddress).mintToken(msg.sender, msg.value + extraMintValue);
        }
        

        // Mint tokens depending on how much TRX is received
        //InterfaceTOPIA(topiaTokenContractAddress).mintToken(player, msg.value);
        
        if(voucherContractAddress != address(0)){
            uint256 mainBetVouchers;
            uint256 sideBetVouchers;
            if(voucherRakeStatus == 2){
                mainBetVouchers = _rollIntegerVariables[2] * 1e6;
                sideBetVouchers = _rollIntegerVariables[3] * 1e6;
            }
            else if(voucherRakeStatus == 1){
                sideBetVouchers = _rollIntegerVariables[3] * 1e6;
            }
            else{
                mainBetVouchers = _rollIntegerVariables[2] * 1e6;
            }
            //accumulatedMintVoucher[msg.sender] += mainBetVouchers;
            //accumulatedMintVoucherSide[msg.sender] += sideBetVouchers;
            //Mint vouchers 
            InterfaceVOUCHERS(voucherContractAddress).mintVouchers(msg.sender, mainBetVouchers, sideBetVouchers);
        }
        
        // Compute the bet hash
        _newUnfinishedBetHash = calculateBetHash(
            _uniqueBetId,
            _userSeed
        );
        
        // This bet must not already exist
        require(unfinishedBetHash_to_timestamp[_newUnfinishedBetHash] == 0, "That bet already exists");
        
        // Store the bet hash
        unfinishedBetHash_to_timestamp[_newUnfinishedBetHash] = block.timestamp;
        user_to_lastBetHash[msg.sender] = _newUnfinishedBetHash;

        // Store the bet in event
        emit BetStarted(_newUnfinishedBetHash, msg.sender, _uniqueBetId, _userSeed, block.number, _rollIntegerVariables);
        
        tempRakePool += (_rollIntegerVariables[2] + _rollIntegerVariables[3]) * globalRakePerMillion;
    }
    
    function getBlockHash(uint256 _blockNumber) external view returns (bytes32)
    {
        return blockhash(_blockNumber);
    }
    function getBlockNumber() external view returns (uint256)
    {
        return block.number;
    }
    
    function createBetObject(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[5] _rollIntegerVariables) private pure returns (Bet memory bet)
    {
        return Bet({
            gambler: _gambler,
            uniqueBetId: _uniqueBetId,
            userSeed: _userSeed,
            blockNumber: _blockNumber,
            startNumber: _rollIntegerVariables[0],
            endNumber: _rollIntegerVariables[1],
            mainBetTRX: _rollIntegerVariables[2],
            sideBetTRX: _rollIntegerVariables[3],
            sideBetType: _rollIntegerVariables[4]
        });
    }
    
    function calculateBetHash(bytes32 _uniqueBetId, bytes32 _userSeed) public pure returns (bytes32)
    {
        
        //3 params are removed and please ignore its compiler warning as that is done so that less GUI change to do. and they do not harm anything.
        return keccak256(abi.encode(
            _uniqueBetId,
            _userSeed
        ));
    }
    
    function calculateBetResult(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[5] _rollIntegerVariables) external view returns (uint256 winningNumber, uint256 mainBetWin, uint256 mainBetProfit, uint256 sideBetWin, uint256 sideBetProfit, uint256 sideBetJackpotWinAmount, uint256 winningNumberForSidebetJackpot)
    {
        Bet memory bet = createBetObject(
            _gambler,
            _uniqueBetId,
            _userSeed,
            _blockNumber,
            _rollIntegerVariables
        );
        
        bytes32 betHash = calculateBetHash(
            _uniqueBetId,
            _userSeed
        );
        
        return _calculateBetResult(bet, betHash);
    }
    
    
    function calculateBetResultWithBlockHash(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[5] _rollIntegerVariables, bytes32 _blockHash) external view returns (uint256 winningNumber, uint256 mainBetWin, uint256 mainBetProfit, uint256 sideBetWin, uint256 sideBetProfit, uint256 sideBetJackpotWinAmount, uint256 winningNumberForSidebetJackpot)
    {
        Bet memory bet = createBetObject(
            _gambler,
            _uniqueBetId,
            _userSeed,
            _blockNumber,
            _rollIntegerVariables
        );
        
        bytes32 betHash = calculateBetHash(
            _uniqueBetId,
            _userSeed
        );
        
        return _calculateBetResultWithBlockHash(bet, betHash, _blockHash);
    }
    
    
    function _calculateBetResult(Bet memory bet, bytes32 betHash) private view returns (uint256 winningNumber, uint256 mainBetWin, uint256 mainBetProfit, uint256 sideBetWin, uint256 sideBetProfit, uint256 sideBetJackpotWinAmount, uint256 winningNumberForSidebetJackpot)
    {
        // Fetch the block hash of the block in which the startBet was confirmed
        bytes32 blockHash;
        if (bet.blockNumber < block.number-256) blockHash = blockHashes[bet.blockNumber];
        else blockHash = blockhash(bet.blockNumber);
        
        return _calculateBetResultWithBlockHash(bet, betHash, blockHash);
    }
    
    function _calculateBetResultWithBlockHash(Bet memory bet, bytes32 betHash, bytes32 blockHash) private view returns (uint256 winningNumber, uint256 mainBetWin, uint256 mainBetProfit, uint256 sideBetWin, uint256 sideBetProfit, uint256 sideBetJackpotWinAmount, uint256 winningNumberForSidebetJackpot)
    {
        // Block hash must be non-zero
        require(blockHash != 0x0, "Too late or too early to calculate bet result.");
        
        // Generate random number for main bet & side bet
        bytes32 _randomSeed = keccak256(abi.encode(blockHash, betHash));
        
        //fist winning number. that number will be anywhere between 0 - 1000000000
        winningNumber = uint256(_randomSeed) % 1000000000;


        //final winning number from DOUBLE RNG calculation
        winningNumber = uint256(keccak256(abi.encode(_randomSeed, winningNumber))) % 100;
        
        // If there was a sidebet...
        if (bet.sideBetTRX > 0)
        {
            // Generate random number for side bet jackpot
            winningNumberForSidebetJackpot = uint256(keccak256(abi.encode(_randomSeed, uint256(1)))) % sideBetJackpotMaxOdd;
            
            // If they won the sidebet jackpot...
            if (winningNumberForSidebetJackpot == sideBetJackpotFixNumber)
            {
                // Calculate the jackpot amount won
                
                // If the sidebet does not qualify for the full jackpot...
                if (bet.sideBetTRX < sideBetAmountTRXtoQualifyForMaximumJackpot)
                {
                    sideBetJackpotWinAmount =
                        currentSideBetJackpotSize
                        * maximumPercentageOfJackpotSizeWon / 100
                        * bet.sideBetTRX / sideBetAmountTRXtoQualifyForMaximumJackpot;
                }
                
                // If the sidebet does qualify for the full jackpot...
                else
                {
                    sideBetJackpotWinAmount =
                        currentSideBetJackpotSize
                        * maximumPercentageOfJackpotSizeWon / 100;
                }
            }
            
            // If they did not win the sidebet jackpot...
            else
            {
                sideBetJackpotWinAmount = 0;
            }
        }

        // Calculate the amount won from the main bet
        if (winningNumber >= bet.startNumber && winningNumber <= bet.endNumber)
        {
            // rollIntegerVariables[1] - rollIntegerVariables[0]   ==   the amount of winning numbers - 1
            mainBetWin = bet.mainBetTRX * multipliersData[bet.endNumber - bet.startNumber] * 100;
            mainBetProfit = mainBetWin - (bet.mainBetTRX * 1e6);
        }
        else
        {
            mainBetWin = 0;
            mainBetProfit = 0;
        }

        // Calculate the amount won from the sidebet
        sideBetWin = _calculateSideBetWin(winningNumber, bet.sideBetType, bet.sideBetTRX);
        if (sideBetWin > 0)
        {
            sideBetProfit = sideBetWin - (bet.sideBetTRX * 1e6);
        }
        
        // Winnings must be limited to the configured fraction of the contract's balance
        if (mainBetProfit + sideBetProfit > maxWin())
        {
            mainBetWin = bet.mainBetTRX * 1e6;
            sideBetWin = bet.sideBetTRX * 1e6;
            mainBetProfit = 0;
            sideBetProfit = 0;
        }
    }
    
    
    function maxWin() public view returns(uint256){
        return (address(this).balance.sub(currentSideBetJackpotSize + tempRakePool + mainRakePool )) / maxWinDivisibleAmount;
    }
    
    

    function finishBet(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[5] _rollIntegerVariables) public
    {
        require(!systemHalted, "System is halted");
        
        Bet memory bet = createBetObject(
            _gambler,
            _uniqueBetId,
            _userSeed,
            _blockNumber,
            _rollIntegerVariables
        );
        
        bytes32 betHash = calculateBetHash(
            _uniqueBetId,
            _userSeed
        );
        
        finishBet(bet, betHash);
    }
    
    function finishBet(Bet memory bet, bytes32 betHash) private
    {
        uint256 betTimestamp = unfinishedBetHash_to_timestamp[betHash];
        
        // If the bet has already been finished, do nothing
        if (betTimestamp == 0) { return; }
        
        // If we can't finish this bet yet, do nothing
        if (bet.blockNumber >= block.number) { return; }

        // If the bet has expired...
        if (bet.blockNumber < block.number-256 && blockHashes[bet.blockNumber] == 0x0)
        {
            // Mark bet as finished
            unfinishedBetHash_to_timestamp[betHash] = 0;
            emit BetExpired(betHash, bet.gambler, (bet.mainBetTRX + bet.sideBetTRX) * 1e6);
            
            // User gets their bet back
            if (betExpiredBehaviour == 1 || betExpiredBehaviour == 3)
            {
                bet.gambler.transfer((bet.mainBetTRX + bet.sideBetTRX) * 1e6);
            }
            
            // System is halted
            if (betExpiredBehaviour == 2 || betExpiredBehaviour == 3)
            {
                systemHalted = true;
            }
            
            return;
        }
        
        
        
        
        (uint256 _winningNumber, uint256 mainBetWin, , uint256 sideBetWin, , uint256 sideBetJackpotWinAmount, uint256 sideBetJackpotRandomNumber) = _calculateBetResult(
            bet, betHash
        );
        
        
        
        
        
        // Emit main bet events
        emit Roll(bet.gambler, bet.startNumber, bet.endNumber, _winningNumber, bet.mainBetTRX, mainBetWin > 0, betTimestamp);
        if (mainBetWin > 0)
        {
            emit KingTopian(bet.gambler, mainBetWin, bet.mainBetTRX, betTimestamp);
            
            // If the main bet was greater than 10000 TRX
            if (bet.mainBetTRX > 10000)
            {
                emit HighRollers(bet.gambler, bet.startNumber, bet.endNumber, _winningNumber, bet.mainBetTRX, mainBetWin, true, betTimestamp);
            }
            
            // If the amount of winning numbers was <= 5   (5% or less chance to win)
            if ((bet.endNumber - bet.startNumber) < 5)
            {
                emit RareWins(bet.gambler, bet.startNumber, bet.endNumber, _winningNumber, bet.mainBetTRX, mainBetWin, true, betTimestamp);
            }
        }
        
        else
        {
            emit UnluckyBunch(bet.gambler, bet.mainBetTRX, bet.mainBetTRX, betTimestamp);
        }
        
        
        
        // Emit side bet events
        if (bet.sideBetTRX > 0)
        {
            emit SideBetRolls(bet.gambler, _winningNumber, bet.sideBetTRX, sideBetWin, bet.sideBetType, sideBetWin > 0, betTimestamp); 
        }
        
        
        // Emit side bet jackpot events
        if (sideBetJackpotWinAmount > 0)
        {
            emit SideBetJackpot(bet.gambler, sideBetJackpotRandomNumber, sideBetJackpotWinAmount);
        }
        
        
        
        
        // Mark bet as finished
        unfinishedBetHash_to_timestamp[betHash] = 0;
        emit BetFinished(betHash);
        
        
        
        
        // If there was a jackpot win...
        if (sideBetJackpotWinAmount > 0)
        {
            // Add the configured percentage of the jackpot pool to the dividend pool
            currentSideBetJackpotSize = currentSideBetJackpotSize.sub(currentSideBetJackpotSize * jackpotSizePercentageToDividendPool / 100);
            
            // Decrease the current size of the jackpot by the part they won
            currentSideBetJackpotSize = currentSideBetJackpotSize.sub(sideBetJackpotWinAmount);
        }
        
        
        // If there was a sidebet loss...
        if (bet.sideBetTRX > 0 && sideBetWin == 0)
        {
            currentSideBetJackpotSize = currentSideBetJackpotSize.add(bet.sideBetTRX * 1e6 * sideBetLossPercentageForProgressiveJackpot / 100);
        }
        
        
        
        // If the user won their main bet, their sidebet or both, their referrer gets payed
        uint256 wageredAmount = (bet.mainBetTRX + bet.sideBetTRX) * 1e6 ;
        if (wageredAmount > 0 && refPoolContractAddress != address(0x0) &&  InterfaceREFERRAL(refPoolContractAddress).referrers(bet.gambler) != address(0x0))
        {
            
            // Processing referral system fund distribution
            // [✓] 0.2% trx to referral if any.
            InterfaceREFERRAL(refPoolContractAddress).payReferrerBonusOnly(bet.gambler, wageredAmount);
        }
        
        
        
        // Transfer the amount won
        uint256 totalWin = mainBetWin + sideBetWin + sideBetJackpotWinAmount;
        if (totalWin > 0)
        {
            bet.gambler.transfer(totalWin);
        }
    }
    

    function adminRefundBet(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[5] _rollIntegerVariables) external onlyOwner returns (bool _success)
    {
        require(!systemHalted, "System is halted");
    
        require(_blockNumber < block.number - 100, "Too early to refund bet. Please wait 100 blocks.");
        
        bytes32 betHash = calculateBetHash(
            _uniqueBetId,
            _userSeed
        );
        
        if (unfinishedBetHash_to_timestamp[betHash] == 0)
        {
            return false;
        }
        else
        {
            unfinishedBetHash_to_timestamp[betHash] = 0;
            _gambler.transfer((_rollIntegerVariables[2] + _rollIntegerVariables[3]) * 1e6);
            emit BetRefunded(betHash, _gambler, (_rollIntegerVariables[2] + _rollIntegerVariables[3]) * 1e6);
            return true;
        }
    }
    
    function _calculateSideBetWin(uint256 _winningNumber, uint256 _sideBetType, uint256 _sideBetValue) private view returns (uint256)
    {
        if (_sideBetType != 0)
        {
            uint256 firstNumber = _winningNumber / 10;
            uint256 lastNumber  = _winningNumber % 10;
            
            if (_sideBetType == _yin)
            {
                if (firstNumber > lastNumber)
                {
                    return _sideBetValue * yinMultiplier * 100;
                }
            }
            else if (_sideBetType == _yang)
            {
                if (firstNumber < lastNumber)
                {
                    return _sideBetValue * yangMultiplier * 100;
                }
            }
            else if (_sideBetType == _bang)
            {
                if (_winningNumber == 0 || _winningNumber == 11 || _winningNumber == 22 || _winningNumber == 33 || _winningNumber == 44 || _winningNumber == 55 || _winningNumber == 66 || _winningNumber == 77 || _winningNumber == 88 || _winningNumber == 99)
                {
                    return _sideBetValue * bangMultiplier * 100;
                }
            }
            else if (_sideBetType == _zero)
            {
                if (_winningNumber == 0)
                {
                    return _sideBetValue * zeroMultiplier * 100;
                }
            }
            else if (_sideBetType == _odd)
            {
                if (_winningNumber % 2 != 0)
                {
                    return _sideBetValue * oddMultiplier * 100;
                }
            }
            else if (_sideBetType == _even)
            {
                if (_winningNumber % 2 == 0)
                {
                    return _sideBetValue * evenMultiplier * 100; 
                }
            }
        }
        
        return 0;
    }

    
    /**
        This functions allows the owner to update the sidebet jackpot variables
    */
    function updateSideBetJackpot(
        uint256 _sideBetJackpotMaxOdd,
        uint256 _sideBetJackpotFixNumber,
        uint256 _sideBetAmountTRXtoQualifyForMaximumJackpot,
        uint256 _maximumPercentageOfJackpotSizeWon,
        uint256 _sideBetLossPercentageForProgressiveJackpot,
        uint256 _jackpotSizePercentageToDividendPool
    ) public onlyOwner returns(string)
    {
        require(_maximumPercentageOfJackpotSizeWon <= 100);
        require(_jackpotSizePercentageToDividendPool <= 100);
        require(_maximumPercentageOfJackpotSizeWon + _jackpotSizePercentageToDividendPool <= 100);
        require(_sideBetLossPercentageForProgressiveJackpot <= 100);
        
        sideBetJackpotMaxOdd = _sideBetJackpotMaxOdd;    
        sideBetJackpotFixNumber = _sideBetJackpotFixNumber;
        sideBetAmountTRXtoQualifyForMaximumJackpot = _sideBetAmountTRXtoQualifyForMaximumJackpot;
        maximumPercentageOfJackpotSizeWon = _maximumPercentageOfJackpotSizeWon;
        sideBetLossPercentageForProgressiveJackpot = _sideBetLossPercentageForProgressiveJackpot;
        jackpotSizePercentageToDividendPool = _jackpotSizePercentageToDividendPool;
        
        return "Sidebet Jackpot variables updated successfully";
    }
    
    
    function depositIntoSideBetJackpot() public payable returns (string)
    {
        totalDepositedIntoJackpot += msg.value;
        currentSideBetJackpotSize += msg.value;
        return "Successfully deposited into jackpot";
    }
    
    function withdrawDepositedJackpot(uint256 _amountSun) public onlyOwner returns (string)
    {
        totalDepositedIntoJackpot = totalDepositedIntoJackpot.sub(_amountSun);
        currentSideBetJackpotSize = currentSideBetJackpotSize.sub(_amountSun);
        
        msg.sender.transfer(_amountSun);
        
        return "Successful withdrawal from jackpot";
    }
    
    
    function availableToWithdrawOwner() public view returns(uint256){
        return address(this).balance.sub(currentSideBetJackpotSize + tempRakePool + mainRakePool);
    }



    /**
        This function lets owner to withdraw TRX as much he deposited.
        Thus there is NO "exit scam" possibility, as there is no other way to take TRX out of this contract
    */
    function manualWithdrawTRX(uint256 amountSUN) public onlyOwner returns(string)
    {
        uint256 availableToWithdraw = address(this).balance.sub(currentSideBetJackpotSize + tempRakePool + mainRakePool);
        
        require(availableToWithdraw > amountSUN, 'withdrawing more than available');

        //transferring the TRX to owner
        owner.transfer(amountSUN);

        return "Transaction successful";
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

    
    
    
    /**
        Function allows owner to update the Topia contract address
    */
    function updateContractAddresses(address topiaContract, address voucherContract, address dividendContract, address refPoolContract, address vaultContract, address diamondContract,address diamondVoucherContract,address voucherDividendContract) public onlyOwner returns(string)
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

    

    /**
        Function allows owner to update the sidebet multiplier variables
    */
    function updateSidebetMultipliers(uint256 yinMultiplier_, uint256 yangMultiplier_, uint256 bangMultiplier_, uint256 zeroMultiplier_, uint256 oddMultiplier_, uint256 evenMultiplier_) public onlyOwner returns(string)
    {
        yinMultiplier = yinMultiplier_;
        yangMultiplier = yangMultiplier_;
        bangMultiplier = bangMultiplier_;
        zeroMultiplier = zeroMultiplier_;
        oddMultiplier = oddMultiplier_;
        evenMultiplier = evenMultiplier_;

        return("side bet multipliers updated successfully");
    }


    /**
        Function to change max bet amount and max bet divisible amount.
    */
    function updateMaxBetMaxWin(uint256 maxBetAmount_, uint256 maxWinDivisibleAmount_  ) public onlyOwner returns(string)
    {
        maxBetAmount = maxBetAmount_;
        maxWinDivisibleAmount = maxWinDivisibleAmount_;

        return("Max bet and max win updated successfully");
    }

    /**
        Function to change minimum side bet amount
    */
    function updateMinimumSideBetAmount(uint256 minimumSideBetAmountTRX_) public onlyOwner returns(string)
    {
        minimumSideBetAmountTRX = minimumSideBetAmountTRX_;
       
        return("Minimum sidebet amount updated successfully");
    }
    
    /**
        Function to change minimum main bet amount
    */
    function updateMinimumMainBetAmount(uint256 minimumMainBetAmountTRX_) public onlyOwner returns(string)
    {
        minimumMainBetAmountTRX = minimumMainBetAmountTRX_;
        
        return("Minimum sidebet amount updated successfully");
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
    

    
    
    /**
        This function  called by token contract, while actual dividend distribution
        This also will be called by Dividend contract, to take some excessive fund to reduce the risk of loss in case of attack!!
    */
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
    
    /**
        Function to update voucherRakeStatus
    */
    function updateVoucherRakeStatus(uint256 _0_1_2) public onlyOwner returns(string)
    {
        require(_0_1_2 > 0, 'Invalid Amount');
        voucherRakeStatus = _0_1_2;

        return "Voucher Rake Status updated";
    }
    
    
}