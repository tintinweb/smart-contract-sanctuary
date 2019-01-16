pragma solidity ^0.4.25;

contract DroneWars {
    
    /*=================================
    =             EVENTS              =
    =================================*/
	event onHiveCreated (
        address indexed player,
		uint256 number,
		uint256 time
    );
	
	event onDroneCreated (
        address indexed player,
		uint256 number,
		uint256 time
    );
	
	event onEnemyDestroyed (
		address indexed player,
		uint256 time
	);
    
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
	modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrator_ == _customerAddress);
        _;
    }
    
    
    /*=================================
    =         CONFIGURABLES           =
    ==================================*/
    uint256 internal ACTIVATION_TIME = 1543054333;  // when hives can be created
    
    uint256 internal hiveCost_ = 0.075 ether;
    uint256 internal droneCost_ = 0.01 ether;
	
	uint256 internal hiveXCommanderFee_ = 50;	// 50% from Hives to Commander
	uint256 internal droneXCommanderFee_ = 15;	// 15% from Drones to Commander
    uint256 internal droneXHiveFee_ = 415;		// 41.5% from Drones to Commander (base 1000)
	
    uint8 internal amountHives_ = 8;
    uint8 internal dronesPerDay_ = 20;			// default 20
	bool internal conquesting_ = true;
	bool internal conquested_ = false;
    
    
    /*=================================
    =             DATASET             =
    =================================*/
    address internal administrator_;
    address internal fundTHCAddress_;
	address internal fundP3DAddress_;
    uint256 internal pot_;
    mapping (address => Pilot) internal pilots_;
    
    address internal commander_;
    address[] internal hives_;
    address[] internal drones_;
    
    //uint256 internal DEATH_TIME;
    uint256 internal dronePopulation_;
    
    
    /*=================================
    =         PUBLIC FUNCTIONS        =
    =================================*/
    constructor() 
        public 
    {
        commander_ = address(this);
        administrator_ = 0x3AbFc04246fD8567677c9bcF0Aa923f2Cd132f06;
        fundTHCAddress_ = administrator_;
		fundP3DAddress_ = administrator_;
    }
	
	function startNewRound() 
		public 
	{
		// Conquesting needs to be finished
		require(!conquesting_);
		
		// payout everybody into their vaults
		_payout();
		
		// reset all values
		_resetGame();
	}
	
	// VAULT
	function withdrawVault() 
		public 
	{
		address _player = msg.sender;
		uint256 _balance = pilots_[_player].vault;
		
		// Player must have ether in vault
		require(_balance > 0);
		
		// withdraw everything
		pilots_[_player].vault = 0;
		
		// payouts
		_player.transfer(_balance);
	}
	
	function createCarrierFromVault()
		public 
	{
		address _player = msg.sender;
		uint256 _vault = pilots_[_player].vault;
		
		// Player must have enough ether available in vault
		require(_vault >= hiveCost_);
		pilots_[_player].vault = _vault - hiveCost_;
		
		_createHiveInternal(_player);
	}
	
	function createDroneFromVault()
		public 
	{
		address _player = msg.sender;
		uint256 _vault = pilots_[_player].vault;
		
		// Player must have enough ether available in vault
		require(_vault >= droneCost_);
		pilots_[_player].vault = _vault - droneCost_;
		
		_createDroneInternal(_player);
	}    
    
	// WALLET
    function createCarrier() 
		public 
		payable
	{
        address _player = msg.sender;
        
		require(msg.value == hiveCost_);			// requires exact amount of ether
        
        _createHiveInternal(_player);
    }	
    
    function createDrone()
        public 
		payable
    {
		address _player = msg.sender;
		
		require(msg.value == droneCost_);			// requires exact amount of ether
        
        _createDroneInternal(_player);
    }
    
    /* View Functions and Helpers */
    function openAt()
        public
        view
        returns(uint256)
    {
        return ACTIVATION_TIME;
    }
    
    function amountHives()
        public
        view
        returns(uint256)
    {
        return hives_.length;
    }
    
    function currentSize() 
        public
        view
        returns(uint256) 
    {
        return drones_.length;
    }
	
	function populationIncrease()
		public
		view
		returns(uint256)
	{
		return drones_.length - dronePopulation_;
	}
    
    function commander()
        public
        view
        returns(address)
    {
        return commander_;
    }
    
    function conquesting() 
        public
        view
        returns(bool)
    {
        return conquesting_;
    }
    
    function getPot()
        public
        view
        returns(uint256)
    {
		// total values
        uint256 _hivesIncome = hives_.length * hiveCost_;		// total hives pot addition
        uint256 _dronesIncome = drones_.length * droneCost_;	// total drones pot addition
        uint256 _pot = pot_ + _hivesIncome + _dronesIncome; 	// old pot may feeds this round
		uint256 _fee = _pot / 10;       						// 10%
        _pot = _pot - _fee;										// 90% residual
        return _pot;
    }
	
	function vaultOf(address _player)
		public
		view
		returns(uint256)
	{
		return pilots_[_player].vault;
	}
	
	function lastFlight(address _player)
		public
		view
		returns(uint256)
	{
		return pilots_[_player].lastFlight;
	}
    
    
    /*=================================
    =        PRIVATE FUNCTIONS        =
    =================================*/
	function _createDroneInternal(address _player) 
		internal 
	{
	    require(hives_.length == amountHives_);    					// all hives must be created
		require(conquesting_);										// Conquesting must be in progress
		require(now > pilots_[_player].lastFlight + 60 seconds);	// 1 drone per minute per address
	    
	    // check if certain amount of Drones have been built
	    // otherwise round ends
	    /*if (now > DEATH_TIME) {
	        if (populationIncrease() >= dronesPerDay_) {
	            dronePopulation_ = drones_.length;		// remember last drone population
	            DEATH_TIME = DEATH_TIME + 24 hours;		// set new death time limit
				
				// after increasing death time, "now" can still have exceeded it
				if (now > DEATH_TIME) {
					conquesting_ = false;
					return;
				}
	        } else {
	            conquesting_ = false;
	            return;
	        }
	    }*/
	    
		// release new drone
        drones_.push(_player);
		pilots_[_player].lastFlight = now;
		
		emit onDroneCreated(_player, drones_.length, now);
        
		// try to kill the Enemy
		_figthEnemy(_player);
	}
	
	function _createHiveInternal(address _player) 
		internal 
	{
	    require(now >= ACTIVATION_TIME);                                // round starts automatically at this time
	    require(hives_.length < amountHives_);                          // limited hive amount
        //require(!ownsHive(_player), "Player already owns a hive");      // does not own a hive yet
        
		// open hive
        hives_.push(_player);
        
        // activate death time of 24 hours
        /*if (hives_.length == amountHives_) {
            DEATH_TIME = now + 24 hours;
        }*/
		
		emit onHiveCreated(_player, hives_.length, now);
	}
    
    function _figthEnemy(address _player)
        internal
    {
        uint256 _drones = drones_.length;
        
        // is that Drone the killer?
        uint256 _drone = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _player, _drones))) % 289;
        
		// Enemy has been killed
		if (_drone == 42) {
			conquesting_ = false;
			conquested_ = true;
			
			emit onEnemyDestroyed(_player, now);
		}
    }
    
    /**
     * Payout Commander, Hives and Drone Squad
     */
    function _payout()
        internal
    {
        // total values
        uint256 _hivesIncome = amountHives_ * hiveCost_;
        uint256 _dronesIncome = drones_.length * droneCost_;
        uint256 _pot = pot_ + _hivesIncome + _dronesIncome; 	// old pot may feeds this round
		uint256 _fee = _pot / 10;       						// 10%
        _pot = _pot - _fee;										// 90% residual
		_hivesIncome = (_hivesIncome * 9) / 10;
        _dronesIncome = (_dronesIncome * 9) / 10;
		
        // relative values
        uint256 _toCommander = (_hivesIncome * hiveXCommanderFee_) / 100 +		// 50% from Hives to Commander
                               (_dronesIncome * droneXCommanderFee_) / 100;  	// 15% from Drones to Commander
        uint256 _toHives = (_dronesIncome * droneXHiveFee_) / 1000;    			// 41,5% from Drones to Hives
        uint256 _toHive = _toHives / 8;											// 1/8 to each hive
        uint256 _toDrones = _pot - _toHives - _toCommander; 					// residual goes to squad
        
        // only payout Hives and Drones if they have conquested
        if (conquested_) {
            // payout hives
            for (uint8 i = 0; i < 8; i++) {
                address _ownerHive = hives_[i];
                pilots_[_ownerHive].vault = pilots_[_ownerHive].vault + _toHive;
                _pot = _pot - _toHive;
            }
            
            // payout drones
            uint256 _squadSize;
            if (drones_.length >= 4) { _squadSize = 4; }				// 4 drones available
    		else                     { _squadSize = drones_.length; }	// less than 4 drones available
            
            // iterate 1-4 drones
            for (uint256 j = (drones_.length - _squadSize); j < drones_.length; j++) {
                address _ownerDrone = drones_[j];
                pilots_[_ownerDrone].vault = pilots_[_ownerDrone].vault + (_toDrones / _squadSize);
                _pot = _pot - (_toDrones / _squadSize);
            }
        }
        
        // payout Commander if contract is not queen
        if (commander_ != address(this)) {
            pilots_[commander_].vault = pilots_[commander_].vault + _toCommander;
            _pot = _pot - _toCommander;
        }
        
        // payout Fee
        fundTHCAddress_.transfer(_fee / 2);		// 50% -> THC
		fundP3DAddress_.transfer(_fee / 2);		// 50% -> P3D
		
		// excess goes to next rounds pot
		pot_ = _pot;
    }
	
	/**
	 * Prepare next round by resetting all values to default
	 */
	function _resetGame() 
		internal 
	{
		address _winner = drones_[drones_.length - 1];
		
		commander_ = _winner;
		hives_.length = 0;
		drones_.length = 0;
		dronePopulation_ = 0;
		
		conquesting_ = true;
		conquested_ = false;
		
		ACTIVATION_TIME = now + 5 minutes;
	}
    
    /* Helper */
    function ownsHive(address _player) 
        internal
        view
        returns(bool)
    {
        for (uint8 i = 0; i < amountHives_; i++) {
            if (hives_[i] == _player) {
                return true;
            }
        }
        
        return false;
    }
    
    
    /*=================================
    =            DATA TYPES           =
    =================================*/
	struct Pilot {
		uint256 vault;
		uint256 lastFlight;
    }
}