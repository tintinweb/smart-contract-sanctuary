pragma solidity ^0.4.24;

contract Sacrific3d {
    
    struct Stage {
        uint8 numberOfPlayers;
        uint256 blocknumber;
        bool finalized;
        mapping (uint8 => address) slotXplayer;
        mapping (address => bool) players;
    }
    
    uint8 constant public MAX_PLAYERS_PER_STAGE = 5;
    uint256 constant public OFFER_SIZE = 0.1 ether;
    uint256 public winningsPerRound = OFFER_SIZE + (OFFER_SIZE / (MAX_PLAYERS_PER_STAGE - 1));
    
    mapping(address => uint256) public playerVault;
    mapping(uint256 => Stage) public stages;
    uint256 public numberOfStages;
    uint256 public numberOfFinalizedStages;
    
    event SacrificeOffered(address indexed player);
    event SacrificeChosen(address indexed sarifice);
    event EarningsWithdrawn(address indexed sarifice, uint256 indexed amount);
    event StageInvalidated(uint256 indexed stage);
    
    modifier isValidOffer()
    {
        require(msg.value == OFFER_SIZE);
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
        
        //try to choose a sacrifice in an already full stage (finalize a stage)
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