pragma solidity ^0.4.25;
// expansion on original contract from dav&#39;s stronghands contract

// introducing features:
// Jackpot - 1 in 1000 chance to get jackpot upon losing
// Refund line for loser to get their initial eth back

// eth distribution:
// each game seeds 0.01 eth to buy P3D with
// each game seeds 0.005 eth to the refund line making a minimum payback each 20 games played
// 0.1 eth to play per player each round


// expansion Coded by spielley 

// Thank you for playing Spielleys contract creations.
// spielley is not liable for any contract bugs and exploits known or unknown.
contract Slaughter3D {
    using SafeMath for uint;
    struct Stage {
        uint8 numberOfPlayers;
        uint256 blocknumber;
        bool finalized;
        mapping (uint8 => address) slotXplayer;
        mapping (address => bool) players;
        mapping (uint8 => address) setMN;
        
    }
    
    HourglassInterface constant p3dContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    SPASMInterface constant SPASM_ = SPASMInterface(0xfaAe60F2CE6491886C9f7C9356bd92F688cA66a1);//spielley&#39;s profit sharing payout
    //a small part of every winners share of the sacrificed players offer is used to purchase p3d instead
    uint256 constant private P3D_SHARE = 0.005 ether;
    
    uint8 constant public MAX_PLAYERS_PER_STAGE = 2;
    uint256 constant public OFFER_SIZE = 0.1 ether;
    uint256 public Refundpot;
    uint256 public Jackpot;// 1% of P3D divs to be allocated to the Jackpot
    uint256 public SPASMfee;//1% of P3D divs to be shared with SPASM holders
    mapping(address => uint256) public ETHtoP3Dbymasternode; //eth to buy P3D masternode
    
    uint256 private p3dPerStage = P3D_SHARE * (MAX_PLAYERS_PER_STAGE - 1);
    //not sacrificed players receive their offer back and also a share of the sacrificed players offer 
    uint256 public winningsPerRound = 0.185 ether;
    
    mapping(address => string) public Vanity;
    mapping(address => uint256) private playerVault;
    mapping(uint256 => Stage) public stages;
    mapping(uint256 => address) public RefundWaitingLine;
    mapping(uint256 => address) public Loser;
    uint256 public  NextInLine;//next person to be refunded
    uint256 public  NextAtLineEnd;//next spot to add loser
    uint256 private numberOfFinalizedStages;
    
    uint256 public numberOfStages;
    
    event JackpotWon(address indexed winner, uint256 SizeOfJackpot);
    event SacrificeOffered(address indexed player);
    event SacrificeChosen(address indexed sarifice);
    event EarningsWithdrawn(address indexed player, uint256 indexed amount);
    event StageInvalidated(uint256 indexed stage);
    // UI view functions
    
    function previousstagedata()
        public
        view
        returns(address , address , string  ,address , string  )
    {
        return (Loser[numberOfFinalizedStages],stages[numberOfFinalizedStages].slotXplayer[0],Vanity[stages[numberOfFinalizedStages].slotXplayer[0]],stages[numberOfFinalizedStages].slotXplayer[1],Vanity[stages[numberOfFinalizedStages].slotXplayer[1]]);
    }
    function currentstagedata()
        public
        view
        returns( address , string  ,address , string  )
    {
        return (stages[numberOfStages].slotXplayer[0],Vanity[stages[numberOfStages].slotXplayer[0]],stages[numberOfStages].slotXplayer[1],Vanity[stages[numberOfStages].slotXplayer[1]]);
    }
    function jackpotinfo()
        public
        view
        returns(uint256 SizeOfJackpot )
    {
        return (Jackpot);
    }
    function checkstatus()// true = ready to vallidate
        public
        view
        returns(bool  )
    {
        bool check;
        if(numberOfStages >= numberOfFinalizedStages)
        {
            if(!stages[numberOfFinalizedStages].finalized && stages[numberOfFinalizedStages].numberOfPlayers < MAX_PLAYERS_PER_STAGE && stages[numberOfFinalizedStages].blocknumber != 0)
            {
                check = true;
            }
        }
        return (check);
    }
    function Refundlineinfo()
        public
        view
        returns(address , uint256 ,uint256 , uint256  , string )
    {
        uint256 LengthUnpaidLine = NextAtLineEnd - NextInLine;
        uint256 dividends = p3dContract.myDividends(true);
        return (RefundWaitingLine[NextInLine],LengthUnpaidLine, dividends , Refundpot ,Vanity[RefundWaitingLine[NextInLine]]);
    }
    // expansion functions
    
    // Buy P3D by masternode 
    function Expand(address masternode) public 
    {
    uint256 amt = ETHtoP3Dbymasternode[masternode];
    ETHtoP3Dbymasternode[masternode] = 0;
    if(masternode == 0x0){masternode = 0x989eB9629225B8C06997eF0577CC08535fD789F9;}// raffle3d&#39;s address
    p3dContract.buy.value(amt)(masternode);
    
    }
    //fetch P3D divs
    function DivsToRefundpot ()public
    {
        //allocate p3d dividends to contract 
            uint256 dividends = p3dContract.myDividends(true);
            require(dividends > 0);
            uint256 base = dividends.div(100);
            p3dContract.withdraw();
            SPASM_.disburse.value(base)();// to dev fee sharing contract SPASM
            Refundpot = Refundpot.add(base.mul(94));
            Jackpot = Jackpot.add(base.mul(5)); // allocation to jackpot
            //
    }
    //Donate to losers
    function DonateToLosers ()public payable
    {
            require(msg.value > 0);
            Refundpot = Refundpot.add(msg.value);

    }
    // next loser payout
    function Payoutnextrefund ()public
    {
        //allocate p3d dividends to sacrifice if existing
            uint256 Pot = Refundpot;
            require(Pot > 0.1 ether);
            Refundpot -= 0.1 ether;
            RefundWaitingLine[NextInLine].transfer(0.1 ether);
            NextInLine++;
            //
    }
    //changevanity
    function changevanity(string van , address masternode) public payable
    {
    require(msg.value >= 1  finney);
    Vanity[msg.sender] = van;
    uint256 amt = ETHtoP3Dbymasternode[masternode].add(msg.value);
    ETHtoP3Dbymasternode[masternode] = 0;
    if(masternode == 0x0){masternode = 0x989eB9629225B8C06997eF0577CC08535fD789F9;}// raffle3d&#39;s address
    p3dContract.buy.value(amt)(masternode);
    }
    // Sac dep
    modifier isValidOffer()
    {
        require(msg.value == OFFER_SIZE);
        _;
    }
    
    modifier canPayFromVault()
    {
        require(playerVault[msg.sender] >= OFFER_SIZE);
        _;
    }
    
    modifier hasEarnings()
    {
        require(playerVault[msg.sender] > 0);
        _;
    }
    
    modifier prepareStage()
    {
        //create a new stage if current has reached max amount of players
        if(stages[numberOfStages - 1].numberOfPlayers == MAX_PLAYERS_PER_STAGE) {
           stages[numberOfStages] = Stage(0, 0, false );
           numberOfStages++;
        }
        _;
    }
    
    modifier isNewToStage()
    {
        require(stages[numberOfStages - 1].players[msg.sender] == false);
        _;
    }
    
    constructor()
        public
    {
        stages[numberOfStages] = Stage(0, 0, false);
        numberOfStages++;
    }
    
    function() external payable {}
    
    function offerAsSacrifice(address MN)
        external
        payable
        isValidOffer
        prepareStage
        isNewToStage
    {
        acceptOffer(MN);
        
        //try to choose a sacrifice in an already full stage (finalize a stage)
        tryFinalizeStage();
    }
    
    function offerAsSacrificeFromVault(address MN)
        external
        canPayFromVault
        prepareStage
        isNewToStage
    {
        playerVault[msg.sender] -= OFFER_SIZE;
        
        acceptOffer(MN);
        
        tryFinalizeStage();
    }
    
    function withdraw()
        external
        hasEarnings
    {
        tryFinalizeStage();
        
        uint256 amount = playerVault[msg.sender];
        playerVault[msg.sender] = 0;
        
        emit EarningsWithdrawn(msg.sender, amount); 
        
        msg.sender.transfer(amount);
    }
    
    function myEarnings()
        external
        view
        hasEarnings
        returns(uint256)
    {
        return playerVault[msg.sender];
    }
    
    function currentPlayers()
        external
        view
        returns(uint256)
    {
        return stages[numberOfStages - 1].numberOfPlayers;
    }
    
    function acceptOffer(address MN)
        private
    {
        Stage storage currentStage = stages[numberOfStages - 1];
        
        assert(currentStage.numberOfPlayers < MAX_PLAYERS_PER_STAGE);
        
        address player = msg.sender;
        
        //add player to current stage
        currentStage.slotXplayer[currentStage.numberOfPlayers] = player;
        currentStage.numberOfPlayers++;
        currentStage.players[player] = true;
        currentStage.setMN[currentStage.numberOfPlayers] = MN;
        emit SacrificeOffered(player);
        
        //add blocknumber to current stage when the last player is added
        if(currentStage.numberOfPlayers == MAX_PLAYERS_PER_STAGE) {
            currentStage.blocknumber = block.number;
        }
        
    }
    
    function tryFinalizeStage()
        public
    {
        assert(numberOfStages >= numberOfFinalizedStages);
        
        //there are no stages to finalize
        if(numberOfStages == numberOfFinalizedStages) {return;}
        
        Stage storage stageToFinalize = stages[numberOfFinalizedStages];
        
        assert(!stageToFinalize.finalized);
        
        //stage is not ready to be finalized
        if(stageToFinalize.numberOfPlayers < MAX_PLAYERS_PER_STAGE) {return;}
        
        assert(stageToFinalize.blocknumber != 0);
        
        //check if blockhash can be determined
        if(block.number - 256 <= stageToFinalize.blocknumber) {
            //blocknumber of stage can not be equal to current block number -> blockhash() won&#39;t work
            if(block.number == stageToFinalize.blocknumber) {return;}
                
            //determine sacrifice
            uint8 sacrificeSlot = uint8(blockhash(stageToFinalize.blocknumber)) % MAX_PLAYERS_PER_STAGE;
            uint256 jackpot = uint256(blockhash(stageToFinalize.blocknumber)) % 1000;
            address sacrifice = stageToFinalize.slotXplayer[sacrificeSlot];
            Loser[numberOfFinalizedStages] = sacrifice;
            emit SacrificeChosen(sacrifice);
            
            //allocate winnings to survivors
            allocateSurvivorWinnings(sacrifice);
            
            //check jackpot win
            if(jackpot == 777){
                sacrifice.transfer(Jackpot);
                emit JackpotWon ( sacrifice, Jackpot);
                Jackpot = 0;
            }
            
            
            //add sacrifice to refund waiting line
            RefundWaitingLine[NextAtLineEnd] = sacrifice;
            NextAtLineEnd++;
            
            //set eth to MN for buying P3D 
            ETHtoP3Dbymasternode[stageToFinalize.setMN[1]] = ETHtoP3Dbymasternode[stageToFinalize.setMN[1]].add(0.005 ether);
            ETHtoP3Dbymasternode[stageToFinalize.setMN[1]] = ETHtoP3Dbymasternode[stageToFinalize.setMN[2]].add(0.005 ether);
            
            //add 0.005 ether to Refundpot
            Refundpot = Refundpot.add(0.005 ether);
            //purchase p3d (using ref) deprecated
            //p3dContract.buy.value(p3dPerStage)(address(0x1EB2acB92624DA2e601EEb77e2508b32E49012ef));
        } else {
            invalidateStage(numberOfFinalizedStages);
            
            emit StageInvalidated(numberOfFinalizedStages);
        }
        //finalize stage
        stageToFinalize.finalized = true;
        numberOfFinalizedStages++;
    }
    
    function allocateSurvivorWinnings(address sacrifice)
        private
    {
        for (uint8 i = 0; i < MAX_PLAYERS_PER_STAGE; i++) {
            address survivor = stages[numberOfFinalizedStages].slotXplayer[i];
            if(survivor != sacrifice) {
                playerVault[survivor] += winningsPerRound;
            }
        }
    }
    
    function invalidateStage(uint256 stageIndex)
        private
    {
        Stage storage stageToInvalidate = stages[stageIndex];
        
        for (uint8 i = 0; i < MAX_PLAYERS_PER_STAGE; i++) {
            address player = stageToInvalidate.slotXplayer[i];
            playerVault[player] += OFFER_SIZE;
        }
    }
}

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function withdraw() external;
    function myDividends(bool _includeReferralBonus) external view returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
}
interface SPASMInterface  {
    function() payable external;
    function disburse() external  payable;
}
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}