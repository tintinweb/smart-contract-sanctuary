pragma solidity ^0.4.25;

contract DroneWars {
    
    /*=================================
    =             EVENTS              =
    =================================*/
    
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    
    
    /*=================================
    =         CONFIGURABLES           =
    ==================================*/
    uint256 internal ACTIVATION_TIME = 1543054333;  // when hives can be created
    
    uint256 internal hiveCost_ = 0.075 ether;
    uint256 internal droneCost_ = 0.01 ether;
    
    uint8 internal amountHives_ = 8;
    uint8 internal dronesPerDay_ = 20;
	bool internal executorAlive_ = true;
	bool internal conquested_ = true;
    
    
    /*=================================
    =             DATASET             =
    =================================*/
    address internal administrator_;
    address internal fundAddress_;
    uint256 internal pot_;
    mapping (address => uint256) internal vaults_;
    
    address internal executor_;
    address[] internal hives_;
    address[] internal drones_;
    
    uint256 internal DEATH_TIME;
    uint256 internal dronePopulation_;
    
    
    /*=================================
    =         PUBLIC FUNCTIONS        =
    =================================*/
    constructor() 
        public 
    {
        executor_ = address(this);
        administrator_ = 0x28436C7453EbA01c6EcbC8a9cAa975f0ADE6Fff1;
        fundAddress_ = 0x1E2F082CB8fd71890777CA55Bd0Ce1299975B25f;
    }
	
	function startNewRound() 
		public 
	{
		// Executor must be dead
		require(!executorAlive_);
		
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
		uint256 _balance = vaults_[_player];
		
		// Player must have ether in vault
		require(_balance > 0);
		
		// withdraw everything
		vaults_[_player] = 0;
		
		// payouts
		_player.transfer(_balance);
	}
	
	function createCarrierFromVault()
		public 
	{
		address _player = msg.sender;
		
		// Player must have enough ether available in vault
		require(vaults_[_player] >= hiveCost_);
		vaults_[_player] = vaults_[_player] - hiveCost_;
		
		_createHiveInternal(_player);
	}
	
	function createInterceptorFromVault()
		public 
	{
		address _player = msg.sender;
		
		// Player must have enough ether available in vault
		require(vaults_[_player] >= droneCost_);
		vaults_[_player] = vaults_[_player] - droneCost_;
		
		_createDroneInternal(_player);
	}    
    
	// WALLET
    function createCarrier() 
		public 
		//payable
	{
        address _player = msg.sender;
        
		//require(msg.value == hiveCost_);			// requires exact amount of ether
        
        _createHiveInternal(_player);
    }	
    
    function createInterceptor()
        public 
		//payable
    {
		address _player = msg.sender;
		
		//require(msg.value == droneCost_);			// requires exact amount of ether
        
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
    
    function executor()
        public
        view
        returns(address)
    {
        return executor_;
    }
    
    function executorAlive() 
        public
        view
        returns(bool)
    {
        return executorAlive_;
    }
    
    function getPot()
        public
        view
        returns(uint256)
    {
        return pot_;
    }
    
    
    /*=================================
    =        PRIVATE FUNCTIONS        =
    =================================*/
	function _createDroneInternal(address _player) 
		internal 
	{
	    require(hives_.length == amountHives_);    	// all hives must be created
		require(executorAlive_);					// Executor must be alive
	    
	    // check if certain amount of Drones have been built
	    // otherwise round ends
	    if (now > DEATH_TIME) {
	        if (drones_.length - dronePopulation_ >= dronesPerDay_) {
	            dronePopulation_ = drones_.length;			// remember last drone population
	            DEATH_TIME = DEATH_TIME + 24 hours;		// set new death time limit
	        } else {
	            executorAlive_ = false;
	            conquested_ = false;
	            return;
	        }
	    }
	    
		// release new drone
        drones_.push(_player);
        
		// try to kill the Executor
		_figthExecutor(_player);
	}
	
	function _createHiveInternal(address _player) 
		internal 
	{
	    require(now >= ACTIVATION_TIME);                                // round starts automatically at this time
	    require(hives_.length < amountHives_);                          // limited hive amount
        //require(!ownsHive(_player), "Player already owns a hive");    // does not own a hive yet
        
		// open hive
        hives_.push(_player);
        
        // activate death time of 24 hours
        if (hives_.length == amountHives_) {
            DEATH_TIME = now + 24 hours;
        }
	}
    
    function _figthExecutor(address _player)
        internal
    {
        uint256 _drones = drones_.length;
        
        // is that Drone the killer?
        uint256 _drone = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _player, _drones))) % 289;
        
		// Executor has been killed
		if (_drone == 42) {
			executorAlive_ = false;
		}
    }
    
    /**
     * Payout Executor, Hives and Drone Squad
     */
    function _payout()
        internal
    {
        // total values
        uint256 _hivesIncome = 8 * hiveCost_;
        uint256 _dronesIncome = drones_.length * droneCost_;
        pot_ = pot_ + _hivesIncome + _dronesIncome; // old pot may feeds this round
        uint256 _fee = pot_ / 10;       // 10%
        pot_ = pot_ - _fee;             // 90% residual
        
        // relative values
        uint256 _toExecutor =   (_hivesIncome * 7) / 10 +   // 70% from Hives to Executor
                                (_dronesIncome * 3) / 100;  // 3% from Drones to Executor
        uint256 _toHives = (_dronesIncome * 415) / 1000;    // 41,5% from Drones to Hives
        uint256 _toHive = _toHive / 8;
        uint256 _toDrones = pot_ - _toHives - _toExecutor;  // residual goes to squad
        uint256 _toDrone = 0;
        
        // only payout Hives and Drones if they have conquested
        if (conquested_) {
            // payout hives
            for (uint8 i = 0; i < 8; i++) {
                address _ownerHive = hives_[i];
                vaults_[_ownerHive] = vaults_[_ownerHive] + _toHive;
                pot_ = pot_ - _toHive;
            }
            
            // payout drones
            uint256 _squadSize;
            if (drones_.length >= 4) { _squadSize = 4; }				// 4 drones available
    		else                     { _squadSize = drones_.length; }	// less than 4 drones available
    		_toDrone = _toDrones / _squadSize;
            
            // iterate 1-4 drones
            for (uint256 j = (drones_.length - _squadSize); j < drones_.length; j++) {
                address _ownerDrone = drones_[j];
                vaults_[_ownerDrone] = vaults_[_ownerDrone] + _toDrone;
                pot_ = pot_ - _toDrone;
            }
        }
        
        // payout Executor if contract is not queen
        if (executor_ != address(this)) {
            vaults_[executor_] = vaults_[executor_] + _toExecutor;
            pot_ = pot_ - _toExecutor;
        }
        
        // payout Fee
        vaults_[fundAddress_] = vaults_[fundAddress_] + _fee;
    }
	
	/**
	 * Prepare next round by resetting all values to default
	 */
	function _resetGame() 
		internal 
	{
		address _winner = drones_[drones_.length - 1];
		
		executor_ = _winner;
		hives_.length = 0;
		drones_.length = 0;
		dronePopulation_ = 0;
		
		executorAlive_ = true;
		conquested_ = true;
		
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
}