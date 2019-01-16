pragma solidity ^0.4.24;

contract Sacrific3d {
    
    struct Stage {
        uint8 numberOfPlayers;
        uint256 blocknumber;
        bool finalized;
        mapping (uint8 => address) slotXplayer;
        mapping (address => bool) players;
    }
    
    HourglassInterface constant p3dContract = HourglassInterface(0x0476E4CCf7f2cB1C3C8ff47F4D69159e2704D6d3);
   
    //a small part of every winners share of the sacrificed players offer is used to purchase p3d instead
    uint256 constant private P3D_SHARE = 0.005 ether;
    
    uint8 constant public MAX_PLAYERS_PER_STAGE = 5;
    uint256 constant public OFFER_SIZE = 0.1 ether;
    
    uint256 private p3dPerStage = P3D_SHARE * (MAX_PLAYERS_PER_STAGE - 1);
    //not sacrificed players receive their offer back and also a share of the sacrificed players offer 
    uint256 public winningsPerRound = OFFER_SIZE + OFFER_SIZE / (MAX_PLAYERS_PER_STAGE - 1) - P3D_SHARE;
    
    mapping(address => uint256) private playerVault;
    mapping(uint256 => Stage) private stages;
    uint256 private numberOfFinalizedStages;
    
    uint256 public numberOfStages;
    
    event SacrificeOffered(address indexed player);
    event SacrificeChosen(address indexed sarifice);
    event EarningsWithdrawn(address indexed player, uint256 indexed amount);
    event StageInvalidated(uint256 indexed stage);
    
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
           stages[numberOfStages] = Stage(0, 0, false);
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
    
    function offerAsSacrifice()
        external
        payable
        isValidOffer
        prepareStage
        isNewToStage
    {
        acceptOffer();
        
        //try to choose a sacrifice in an already full stage (finalize a stage)
        tryFinalizeStage();
    }
    
    function offerAsSacrificeFromVault()
        external
        canPayFromVault
        prepareStage
        isNewToStage
    {
        playerVault[msg.sender] -= OFFER_SIZE;
        
        acceptOffer();
        
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
    
    function acceptOffer()
        private
    {
        Stage storage currentStage = stages[numberOfStages - 1];
        
        assert(currentStage.numberOfPlayers < MAX_PLAYERS_PER_STAGE);
        
        address player = msg.sender;
        
        //add player to current stage
        currentStage.slotXplayer[currentStage.numberOfPlayers] = player;
        currentStage.numberOfPlayers++;
        currentStage.players[player] = true;
        
        emit SacrificeOffered(player);
        
        //add blocknumber to current stage when the last player is added
        if(currentStage.numberOfPlayers == MAX_PLAYERS_PER_STAGE) {
            currentStage.blocknumber = block.number;
        }
    }
    
    function tryFinalizeStage()
        private
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
            address sacrifice = stageToFinalize.slotXplayer[sacrificeSlot];
            
            emit SacrificeChosen(sacrifice);
            
            //allocate winnings to survivors
            allocateSurvivorWinnings(sacrifice);
            
            //allocate p3d dividends to sacrifice if existing
            uint256 dividends = p3dContract.myDividends(true);
            if(dividends > 0) {
                p3dContract.withdraw();
                playerVault[sacrifice]+= dividends;
            }
            
            //purchase p3d (using ref)
            p3dContract.buy.value(p3dPerStage)(address(0x8948E4B00DEB0a5ADb909F4DC5789d20D0851D71));
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
}