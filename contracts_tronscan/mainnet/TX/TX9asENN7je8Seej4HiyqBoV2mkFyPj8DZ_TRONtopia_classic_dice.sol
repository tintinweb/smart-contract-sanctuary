//SourceUnit: classic_dice_game.sol

pragma solidity 0.4.25; 


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

interface interfaceTOKEN
{
    function transfer(address recipient, uint amount) external returns(bool);
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
//---------------------   DIAMOND CONTRACT INTERFACE  ----------------------//
//**************************************************************************//

interface InterfaceDIAMOND
{
    function usersDiamondFrozen(address _user)  external view returns(uint256);
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
//---------------------  DICE GAME MAIN CODE STARTS HERE -------------------//
//**************************************************************************//

contract TRONtopia_classic_dice is owned
{
    using SafeMath for uint256;
    uint256[] public multipliersData;
    address public topiaTokenContractAddress;
    address public dividendContractAddress;
    address public voucherContractAddress;
    address public vaultContractAddress;
    address public diamondContractAddress;
    address public diamondVoucherContractAddress;
    address public refPoolContractAddress;
    uint256 public totalDepositedTRX;
    
    uint256 public maxBetAmount = 500000;
    uint256 public minimumMainBetAmountTRX = 10;
    uint256 public maxWinDivisibleAmount = 50;
    
    bool public systemHalted = false;
    
    uint256 private betExpiredBehaviour = 0;
    // 0: bet is ignored
    // 1: user gets their bet back
    // 2: bet is ignored, system is halted
    // 3: user gets their bet back, system is halted

    mapping (address => uint256) public accumulatedMintToken;   // total amount of bet of particular player, for minting use, once minting done this value will be zero
    mapping (address => uint256) public accumulatedMintVoucher;   // total amount of bet of particular player, for minting use, once minting done this value will be zero
    mapping (address => uint256) public accumulatedMintVoucherSide; // total amount of bet of particular player, for minting use, once minting done this value will be zero


    event BetStarted(bytes32 indexed _betHash, address indexed _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 indexed _blockNumber, uint256[3] _rollIntegerVariables);
    event BetFinished(bytes32 indexed _betHash);
    event BetExpired(bytes32 betHash, address user, uint256 betAmount);
    event BetRefunded(bytes32 indexed _betHash, address indexed _gambler, uint256 _amountRefunded);
    event Roll(address indexed user, uint256 _startNumber, uint256 _endNumber, uint256 _winningNumber, uint256 indexed _value, bool indexed result, uint256 timestamp);
    //event KingTopian(address indexed user, uint256 _prize, uint256 _trxplayed, uint256 timestamp);
    //event UnluckyBunch(address indexed user, uint256 _loose, uint256 _trxplayed, uint256 timestamp);
    event HighRollers(address indexed user, uint256 _startNumber, uint256 _endNumber, uint256 _winningNumber, uint256 _value, uint256 _winamount, bool result, uint256 timestamp);
    event RareWins(address indexed user, uint256 _startNumber, uint256 _endNumber, uint256 _winningNumber, uint256 _value, uint256 _winamount, bool result, uint256 timestamp);
   
    // Fallback function. It just accepts incoming TRX
    function () payable external
    {
    }
    
    constructor() public
    {
        blockHashes.length = ~uint256(0);
    }

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
    }


    // setMultiplierData stores multiplier array data in the contract
    // [985000,492500,328333,246250,197000,164166,140714,123125,109444,98500,89545,82083,75769,70357,65666,61562,57941,54722,51842,49250,46904,44772,42826,41041,39400,37884,36481,35178,33965,32833,31774,30781,29848,28970,28142,27361,26621,25921,25256,24625,24024,23452,22906,22386,21888,21413,20957,20520,20102,19700,19313,18942,18584,18240,17909,17589,17280,16982,16694,16416,16147,15887,15634,15390,15153,14924,14701,14485,14275,14071,13873,13680,13493,13310,13133,12960,12792,12628,12468,12312,12160,12012,11867,11726,11588,11453,11321,11193,11067,10944,10824,10706,10591,10478,10368,10260,10155]
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
        uint256 predictionNumber;
        uint256 rollUnderOrOver;    // 0 = roll under, 1 = roll over
        uint256 mainBetTRX;
    }

    mapping(bytes32 => uint256) public unfinishedBetHash_to_timestamp;
    mapping(address => bytes32) public user_to_lastBetHash;
    
    bytes32[] public blockHashes;
    
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
    function finishManyBets(address[] _gambler, bytes32[] _uniqueBetId, bytes32[] _userSeed, uint256[] _blockNumber, uint256[3][] _rollIntegerVariables, uint256 _lowLevelGas) external
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
        uint256[3] _finishBet_rollIntegerVariables,
        
        
        uint256[3] _startBet_rollIntegerVariables,
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
    * _rollIntegerVariables[0] = _predictionNUmber;
    * _rollIntegerVariables[1] = _rollUnderOrOver;    // 0 = roll under, 1 = roll over
    * _rollIntegerVariables[2] = _amount;
    * 
    **/
    
    function startBet(uint256[3] _rollIntegerVariables, address _referrer, bytes32 _userSeed, bytes32 _uniqueBetId) payable public returns (bytes32 _newUnfinishedBetHash)
    {
        require(!systemHalted, "System is halted");
        
        address player = msg.sender;
        uint256 trxSent = msg.value;
        
        // User must have sent the same amount of TRX as his main bet
        require(trxSent == _rollIntegerVariables[2].mul(1e6), "Invalid msg.value");
        
        // The main bet must be at least the minimum main bet
        require(_rollIntegerVariables[2] >= minimumMainBetAmountTRX, 'Main bet amount too low');
        
        // Prevent bets greater than the maximum bet
        require(_rollIntegerVariables[2] <= maxBetAmount, 'Bet amount too large');
        
        // Ensure that:
        //   _rollIntegerVariables[0] >= 0 && _rollIntegerVariables[0] < 100
        //   _rollIntegerVariables[1] == 0 || _rollIntegerVariables[1] == 1
        require(_rollIntegerVariables[0] >= 0 && _rollIntegerVariables[0] < 100, 'Invalid prediction number');
        require(_rollIntegerVariables[1] == 0 || _rollIntegerVariables[1] == 1, 'Invalid roll under or roll over number');



        if(_rollIntegerVariables[1] == 0) require(_rollIntegerVariables[0] > 0 && _rollIntegerVariables[0] < 96 , 'Invalid prediction number');
        if(_rollIntegerVariables[1] == 1) require(_rollIntegerVariables[0] > 3 && _rollIntegerVariables[0] < 99 , 'Invalid prediction number');
        
        

        // startBet may not be called by another smart contract
        require(player == tx.origin, 'Caller must not be Contract Address');
        
        require(_referrer != player, 'User cannot refer himself');
        
        // Set referer address if user has usd ref link and does not have any existing referer...
        if (_referrer != address(0x0) && InterfaceREFERRAL(refPoolContractAddress).referrers(player) == address(0x0) )
        {
            // Set their referral address
            InterfaceREFERRAL(refPoolContractAddress).updateReferrer(player, _referrer);
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
            uint256 extraMintValue = msg.value * extraMint / 1000;
            accumulatedMintToken[player] += trxSent + extraMintValue;
            //interfaceTOKEN(topiaTokenContractAddress).mintToken(player, trxSent+extraMintValue);
        }
        
        // Mint vouchers
        if(voucherContractAddress != address(0)){
            accumulatedMintVoucher[player] += trxSent;
            //accumulatedMintVoucherSide[player] += 0;
            //InterfaceVOUCHERS(voucherContractAddress).mintVouchers(player, trxSent, 0);
        }
        
        // Compute the bet hash
        _newUnfinishedBetHash = calculateBetHash(
            player,
            _uniqueBetId,
            _userSeed,
            block.number,
            _rollIntegerVariables
        );
        
        // This bet must not already exist
        require(unfinishedBetHash_to_timestamp[_newUnfinishedBetHash] == 0, "That bet already exists");
        
        // Store the bet hash
        unfinishedBetHash_to_timestamp[_newUnfinishedBetHash] = block.timestamp;
        user_to_lastBetHash[player] = _newUnfinishedBetHash;

        // Store the bet in event
        emit BetStarted(_newUnfinishedBetHash, player, _uniqueBetId, _userSeed, block.number, _rollIntegerVariables);
        
        tempRakePool += _rollIntegerVariables[2] * globalRakePerMillion;
    }
    
    function getBlockHash(uint256 _blockNumber) external view returns (bytes32)
    {
        return blockhash(_blockNumber);
    }
    function getBlockNumber() external view returns (uint256)
    {
        return block.number;
    }
    
    function createBetObject(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[3] _rollIntegerVariables) private pure returns (Bet memory bet)
    {
        return Bet({
            gambler: _gambler,
            uniqueBetId: _uniqueBetId,
            userSeed: _userSeed,
            blockNumber: _blockNumber,
            predictionNumber: _rollIntegerVariables[0],
            rollUnderOrOver: _rollIntegerVariables[1],
            mainBetTRX: _rollIntegerVariables[2]
        });
    }
    
    function calculateBetHash(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[3] _rollIntegerVariables) public pure returns (bytes32)
    {
        return keccak256(abi.encode(
            _gambler,
            _uniqueBetId,
            _userSeed,
            _blockNumber,
            _rollIntegerVariables[0],
            _rollIntegerVariables[1],
            _rollIntegerVariables[2]
        ));
    }
    
    function calculateBetResult(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[3] _rollIntegerVariables) external view returns (uint256 winningNumber, uint256 mainBetWin, uint256 mainBetProfit)
    {
        Bet memory bet = createBetObject(
            _gambler,
            _uniqueBetId,
            _userSeed,
            _blockNumber,
            _rollIntegerVariables
        );
        
        bytes32 betHash = calculateBetHash(
            _gambler,
            _uniqueBetId,
            _userSeed,
            _blockNumber,
            _rollIntegerVariables
        );
        
        return _calculateBetResult(bet, betHash);
    }
    
    
    function calculateBetResultWithBlockHash(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[3] _rollIntegerVariables, bytes32 _blockHash) external view returns (uint256 winningNumber, uint256 mainBetWin, uint256 mainBetProfit )
    {
        Bet memory bet = createBetObject(
            _gambler,
            _uniqueBetId,
            _userSeed,
            _blockNumber,
            _rollIntegerVariables
        );
        
        bytes32 betHash = calculateBetHash(
            _gambler,
            _uniqueBetId,
            _userSeed,
            _blockNumber,
            _rollIntegerVariables
        );
        
        return _calculateBetResultWithBlockHash(bet, betHash, _blockHash);
    }
    
    
    function _calculateBetResult(Bet memory bet, bytes32 betHash) private view returns (uint256 winningNumber, uint256 mainBetWin, uint256 mainBetProfit)
    {
        // Fetch the block hash of the block in which the startBet was confirmed
        bytes32 blockHash;
        if (bet.blockNumber < block.number-256) blockHash = blockHashes[bet.blockNumber];
        else blockHash = blockhash(bet.blockNumber);
        
        return _calculateBetResultWithBlockHash(bet, betHash, blockHash);
    }
    
    function _calculateBetResultWithBlockHash(Bet memory bet, bytes32 betHash, bytes32 blockHash) private view returns (uint256 winningNumber, uint256 mainBetWin, uint256 mainBetProfit)
    {
        // Block hash must be non-zero
        require(blockHash != 0x0, "Too late or too early to calculate bet result.");
        
        // Generate random number for main bet 
        bytes32 _randomSeed = keccak256(abi.encode(blockHash, betHash));
        
        
        //fist winning number. that number will be anywhere between 0 - 1000000000
        winningNumber = uint256(_randomSeed) % 1000000000;


        //final winning number from DOUBLE RNG calculation
        winningNumber = uint256(keccak256(abi.encode(_randomSeed, winningNumber))) % 100;
        
        


        // Calculate the amount won from the main bet
        // user will win only either (1) lucky number is more than  prediction number as well as it is roll over bet, or.. 
        // (2) lucky number is less than  prediction number and it is roll under bet
        if ( winningNumber > bet.predictionNumber && bet.rollUnderOrOver == 1 )
        {   //this is for roll over
            
            //example to get multiplier from its array: if I roll over 56, then I have around 43 (98-56) winning numbers giving approx 43% of winning chance.. So we take 43th of element from our multiplier array
            mainBetWin = bet.mainBetTRX * multipliersData[98 - bet.predictionNumber] * 100;
            mainBetProfit = mainBetWin - (bet.mainBetTRX * 1e6);
        }
        else if(winningNumber < bet.predictionNumber && bet.rollUnderOrOver == 0)
        {   //this is for roll under

            //for roll under case, prediction number will never be zero. so no overflow!
            mainBetWin = bet.mainBetTRX * multipliersData[bet.predictionNumber - 1] * 100;
            mainBetProfit = mainBetWin - (bet.mainBetTRX * 1e6);

        }
        else
        {
            mainBetWin = 0;
            mainBetProfit = 0;
        }

        
        // Winnings must be limited to the configured fraction of the contract's balance
        if (mainBetProfit  > maxWin())
        {
            mainBetWin = bet.mainBetTRX * 1e6;
            mainBetProfit = 0;
        }
    }
    
    
    function maxWin() public view returns(uint256){
        return (address(this).balance.sub(tempRakePool + mainRakePool)) / maxWinDivisibleAmount;
    }
    
    

    function finishBet(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[3] _rollIntegerVariables) public
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
            _gambler,
            _uniqueBetId,
            _userSeed,
            _blockNumber,
            _rollIntegerVariables
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
            emit BetExpired(betHash, bet.gambler, (bet.mainBetTRX) * 1e6);
            
            // User gets their bet back
            if (betExpiredBehaviour == 1 || betExpiredBehaviour == 3)
            {
                bet.gambler.transfer((bet.mainBetTRX ) * 1e6);
            }
            
            // System is halted
            if (betExpiredBehaviour == 2 || betExpiredBehaviour == 3)
            {
                systemHalted = true;
            }
            
            return;
        }
        
        
        
        
        (uint256 _winningNumber, uint256 mainBetWin,) = _calculateBetResult(
            bet, betHash
        );
        
        
        
        
        
        // Emit main bet events
        emit Roll(bet.gambler, bet.predictionNumber, bet.rollUnderOrOver, _winningNumber, bet.mainBetTRX, mainBetWin > 0, betTimestamp);
        if (mainBetWin > 0)
        {
            //emit KingTopian(bet.gambler, mainBetWin, bet.mainBetTRX, betTimestamp);
            
            // For high rollers: If the main bet was greater than 10000 TRX
            if (bet.mainBetTRX >= 10000)
            {
                emit HighRollers(bet.gambler, bet.predictionNumber, bet.rollUnderOrOver, _winningNumber, bet.mainBetTRX, mainBetWin, true, betTimestamp);
            }
            
            // For rare wins: If the amount of winning numbers was < 5   (5% or less chance to win) 
            if ( (bet.predictionNumber < 5 && bet.rollUnderOrOver == 0) || (bet.predictionNumber > 94 && bet.rollUnderOrOver == 1 ) )
            {
                emit RareWins(bet.gambler, bet.predictionNumber, bet.rollUnderOrOver, _winningNumber, bet.mainBetTRX, mainBetWin, true, betTimestamp);
            }

        }
        
        else
        {
            //emit UnluckyBunch(bet.gambler, bet.mainBetTRX, bet.mainBetTRX, betTimestamp);
        }
        
        
        
        // Mark bet as finished
        unfinishedBetHash_to_timestamp[betHash] = 0;
        emit BetFinished(betHash);
        
    
        // referrer gets payed
        if (InterfaceREFERRAL(refPoolContractAddress).referrers(bet.gambler) != address(0x0))
        {
            
            // Processing referral system fund distribution
            // [?] 0.2% trx to referral if any.
            InterfaceREFERRAL(refPoolContractAddress).payReferrerBonusOnly(bet.gambler, bet.mainBetTRX  * 1e6);
        }
        
        
        
        // Transfer the amount won
        uint256 totalWin = mainBetWin;
        if (totalWin > 0)
        {
            bet.gambler.transfer(totalWin);
        }
    }
    

    function adminRefundBet(address _gambler, bytes32 _uniqueBetId, bytes32 _userSeed, uint256 _blockNumber, uint256[3] _rollIntegerVariables) external onlyOwner returns (bool _success)
    {
        require(!systemHalted, "System is halted");
    
        require(_blockNumber < block.number - 100, "Too early to refund bet. Please wait 100 blocks.");
        
        bytes32 betHash = calculateBetHash(
            _gambler,
            _uniqueBetId,
            _userSeed,
            _blockNumber,
            _rollIntegerVariables
        );
        
        if (unfinishedBetHash_to_timestamp[betHash] == 0)
        {
            return false;
        }
        else
        {
            unfinishedBetHash_to_timestamp[betHash] = 0;
            _gambler.transfer((_rollIntegerVariables[2] ) * 1e6);
            emit BetRefunded(betHash, _gambler, (_rollIntegerVariables[2] ) * 1e6);
            return true;
        }
    }
    



    /** 
        This function just gives total balance of contract
    */
    function totalTRXbalanceContract() public view returns(uint256)
    {
        return address(this).balance;
    }
    
    
    
    function availableToWithdrawOwner() public view returns(uint256){
        return address(this).balance.sub(tempRakePool + mainRakePool);
    }
    


    /**
        This function lets owner to withdraw TRX as much he deposited.
        Thus there is NO "exit scam" possibility, as there is no other way to take TRX out of this contract
    */
    function manualWithdrawTRX(uint256 amountSUN) public onlyOwner returns(string)
    {
        uint256 availableToWithdraw = address(this).balance.sub(tempRakePool + mainRakePool);
        
        require(availableToWithdraw > amountSUN, 'withdrawing more than available');

        //transferring the TRX to owner
        owner.transfer(amountSUN);

        return "Transaction successful";
    }
    
    
    /**
        Just in rare case, owner wants to transfer Tokens from contract to owner address
    */
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string)
    {
        // no need for overflow checking as that will be done in transfer function
        interfaceTOKEN(topiaTokenContractAddress).transfer(msg.sender, tokenAmount);
        
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
    function updateContractAddresses(address topiaContract, address voucherContract, address dividendContract, address vaultContract, address diamondContract,address diamondVoucherContract, address refPoolContract) public onlyOwner returns(string)
    {

        topiaTokenContractAddress = topiaContract;
        voucherContractAddress = voucherContract;
        dividendContractAddress = dividendContract;
        vaultContractAddress = vaultContract;
        diamondContractAddress = diamondContract;
        diamondVoucherContractAddress = diamondVoucherContract; 
        refPoolContractAddress = refPoolContract;

        return "Addresses updated successfully";
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
        Function to change minimum main bet amount
    */
    function updateMinimumMainBetAmount(uint256 minimumMainBetAmountTRX_) public onlyOwner returns(string)
    {
        minimumMainBetAmountTRX = minimumMainBetAmountTRX_;
        
        return("Minimum main bet amount updated successfully");
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
        
        require(msg.sender == voucherContractAddress, 'Unauthorised caller');
        
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