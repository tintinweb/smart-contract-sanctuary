// CryptoRabbit Source code

pragma solidity ^0.4.18;


/// @title A base contract to control ownership
/// @author cuilichen
contract OwnerBase {

    // The addresses of the accounts that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;
    
    /// constructor
    function OwnerBase() public {
       ceoAddress = msg.sender;
       cfoAddress = msg.sender;
       cooAddress = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }


    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCFO The address of the new COO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCOO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}



/**
 * 
 * @title Interface for contracts conforming to fighters camp
 * @author cuilichen
 */
contract FighterCamp {
    
    //
    function isCamp() public pure returns (bool);
    
    // Required methods
    function getFighter(uint _tokenId) external view returns (uint32);
    
}


/// @title Base contract for combat
/// @author cuilichen
contract RabbitArena is OwnerBase {
    
	event FightersReady(uint32 season);
    event SeasonWinner(uint32 season, uint winnerID);
    
	
    struct Fighter {
        uint tokenID;
        uint32 strength;
    }
	
    //where are fighters from
    FighterCamp public theCamp; 
	
	
	mapping (uint => Fighter) soldiers;
	
	
	uint32[] public seasons;
    
    
	uint32 public matchDay;
	
	
	/// @dev constructor
	function RabbitArena(address _camp) public {
		FighterCamp tmp = FighterCamp(_camp);
        require(tmp.isCamp());
        theCamp = tmp;
	}
    
    
    
    /// @dev set camp for this contract
    function setBaseInfo(address _camp) external onlyCOO {
        FighterCamp tmp = FighterCamp(_camp);
        require(tmp.isCamp());
        theCamp = tmp;
    }
	
	
	/// @dev release storaged data, to save gas fee.
	function releaseOldData() internal {
		for (uint i = 0; i < seasons.length; i++) {
            uint _season = seasons[i];
			for (uint j = 0; j < 8; j++) {
				uint key = _season * 1000 + j;
				delete soldiers[key];
			}
        }
		delete seasons;// seasons.length --> 0
	}

    
    /// @dev set 8 fighters for a season, prepare for combat.
    function setFighters(uint32 _today, uint32 _season, uint[] _tokenIDs) external onlyCOO {
		require(_tokenIDs.length == 8);
		
		if (matchDay != _today) {
			releaseOldData();
			matchDay = _today;
		}
		seasons.push(_season);// a new season
		
        //record fighter datas
        for(uint i = 0; i < 8; i++) {
            uint tmpID = _tokenIDs[i];
            
            Fighter memory soldier = Fighter({
                tokenID: tmpID,
				strength: theCamp.getFighter(tmpID)
            });
			
			uint key = _season * 1000 + i;
            soldiers[key] = soldier;
        }
        
        //fire the event
        emit FightersReady(_season);
    }
    
    
    /// @dev get fighter property
    function getFighterInfo(uint32 _season, uint32 _index) external view returns (
        uint outTokenID,
        uint32 outStrength
    ) {
		require(_index < 8);
		uint key = _season * 1000 + _index;
        
        Fighter storage soldier = soldiers[key];
		require(soldier.strength > 0);
        
        outTokenID = soldier.tokenID;
        outStrength = soldier.strength;
    }
    
    
    /// @dev process a combat
    /// @param _season The round for combat
    /// @param _seed The seed from the users
    function processOneCombat(uint32 _season, uint32 _seed) external onlyCOO 
    {
        uint[] memory powers = new uint[](8);
        
		uint sumPower = 0;
        uint i = 0;
		uint key = 0;
        for (i = 0; i < 8; i++) {
			key = _season * 1000 + i;
            Fighter storage soldier = soldiers[key];
            powers[i] = soldier.strength;
            sumPower = sumPower + soldier.strength;
        }
        
        uint sumValue = 0;
		uint tmpPower = 0;
        for (i = 0; i < 8; i++) {
            tmpPower = powers[i] ** 5;//
            sumValue += tmpPower;
            powers[i] = sumValue;
        }
        uint singleDeno = sumPower ** 5;
        uint randomVal = _getRandom(_seed);
        
        uint winner = 0;
        uint shoot = sumValue * randomVal * 10000000000 / singleDeno / 0xffffffff;
        for (i = 0; i < 8; i++) {
            tmpPower = powers[i];
            if (shoot <= tmpPower * 10000000000 / singleDeno) {
                winner = i;
                break;
            }
        }
		
		key = _season * 1000 + winner;
		Fighter storage tmp = soldiers[key];        
        emit SeasonWinner(_season, tmp.tokenID);
    }
    
    
    /// @dev give a seed and get a random value between 0 and 0xffffffff.
    /// @param _seed an uint32 value from users
    function _getRandom(uint32 _seed) pure internal returns(uint32) {
        return uint32(keccak256(_seed));
    }
}