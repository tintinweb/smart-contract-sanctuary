pragma solidity ^0.4.21;


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
	
	
	/// @dev check wether target address is a contract or not
    function isNormalUser(address addr) internal view returns (bool) {
		if (addr == address(0)) {
			return false;
		}
        uint size = 0;
        assembly { 
		    size := extcodesize(addr) 
		} 
        return size == 0;
    }
}


/**
 * Math operations with safety checks
 */
contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
 
}



/// @title Interface of contract for partner
/// @author cuilichen
contract PartnerHolder {
    //
    function isHolder() public pure returns (bool);
    
    // Required methods
    function bonusAll() payable public ;
	
	
	function bonusOne(uint id) payable public ;
    
}

/// @title Contract for partner. Holds all partner structs, events and base variables.
/// @author cuilichen
contract Partners is OwnerBase, SafeMath, PartnerHolder {

    event Bought(uint16 id, address newOwner, uint price, address oldOwner);
    
	// data of Casino
    struct Casino {
		uint16 id;
		uint16 star;
		address owner;
		uint price;
		string name;
		string desc;
    }
	
	// address to balance.
	mapping(address => uint) public balances;
	
	
	mapping(uint => Casino) public allCasinos; // key is id
	
	// all ids of casinos
	uint[] public ids;
	
	
	uint public masterCut = 200;
	
	// master balance;
	uint public masterHas = 0;
	
	
	function Partners() public {
		ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
		
	}
	
	function initCasino() public onlyCOO {
		addCasino(5, 100000000000000000, &#39;Las Vegas Bellagio Casino&#39;, &#39;Five star Casino&#39;);
		addCasino(4, 70000000000000000, &#39;London Ritz Club Casino&#39;, &#39;Four star Casino&#39;);
		addCasino(4, 70000000000000000, &#39;Las Vegas Metropolitan Casino&#39;, &#39;Four star Casino&#39;);
		addCasino(4, 70000000000000000, &#39;Argentina Park Hyatt Mendoza Casino&#39;, &#39;Four star Casino&#39;);
		addCasino(3, 30000000000000000, &#39;Canada Golf Thalasso & Casino Resort&#39;, &#39;Three star Casino&#39;);
		addCasino(3, 30000000000000000, &#39;Monaco Monte-Carlo Casino&#39;, &#39;Three star Casino&#39;);
		addCasino(3, 30000000000000000, &#39;Las Vegas Flamingo Casino&#39;, &#39;Three star Casino&#39;);
		addCasino(3, 30000000000000000, &#39;New Jersey Bogota Casino&#39;, &#39;Three star Casino&#39;);
		addCasino(3, 30000000000000000, &#39;Atlantic City Taj Mahal Casino&#39;, &#39;Three star Casino&#39;);
		addCasino(2, 20000000000000000, &#39;Dubai Atlantis Casino&#39;, &#39;Two star Casino&#39;);
		addCasino(2, 20000000000000000, &#39;Germany Baden-Baden Casino&#39;, &#39;Two star Casino&#39;);
		addCasino(2, 20000000000000000, &#39;South Korea Paradise Walker Hill Casino&#39;, &#39;Two star Casino&#39;);
		addCasino(2, 20000000000000000, &#39;Las Vegas Paris Casino&#39;, &#39;Two star Casino&#39;);
		addCasino(2, 20000000000000000, &#39;Las Vegas Caesars Palace Casino&#39;, &#39;Two star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Las Vegas Riviera Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Las Vegas Mandalay Bay Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Las Vegas MGM Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Las Vegas New York Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Las Vegas  Renaissance Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Las Vegas Venetian Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Melbourne Crown Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Macao Grand Lisb Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Singapore Marina Bay Sands Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Malaysia Cloud Top Mountain Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;South Africa Sun City Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Vietnam Smear Peninsula Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Macao Sands Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Bahamas Paradise Island Casino&#39;, &#39;One star Casino&#39;);
		addCasino(1, 10000000000000000, &#39;Philippines Manila Casinos&#39;, &#39;One star Casino&#39;);
	}
	///
	function () payable public {
		//receive ether.
		masterHas = safeAdd(masterHas, msg.value);
	}
	
	/// @dev add a new casino 
	function addCasino(uint16 _star, uint _price, string _name, string _desc) internal 
	{
		uint newID = ids.length + 1;
		Casino memory item = Casino({
			id:uint16(newID),
			star:_star,
			owner:cooAddress,
			price:_price,
			name:_name,
			desc:_desc
		});
		allCasinos[newID] = item;
		ids.push(newID);
	}
	
	/// @dev set casino name and description by coo
	function setCasinoName(uint16 id, string _name, string _desc) public onlyCOO 
	{
		Casino storage item = allCasinos[id];
		require(item.id > 0);
		item.name = _name;
		item.desc = _desc;
	}
	
	/// @dev check wether the address is a casino owner.
	function isOwner( address addr) public view returns (uint16) 
	{
		for(uint16 id = 1; id <= 29; id++) {
			Casino storage item = allCasinos[id];
			if ( item.owner == addr) {
				return id;
			}
		}
		return 0;
	}
	
	/// @dev identify this contract is a partner holder.
	function isHolder() public pure returns (bool) {
		return true;
	}
	
	
	/// @dev give bonus to all partners, and the owners can withdraw it soon.
	function bonusAll() payable public {
		uint total = msg.value;
		uint remain = total;
		if (total > 0) {
			for (uint i = 0; i < ids.length; i++) {
				uint id = ids[i];
				Casino storage item = allCasinos[id];
				uint fund = 0;
				if (item.star == 5) {
					fund = safeDiv(safeMul(total, 2000), 10000);
				} else if (item.star == 4) {
					fund = safeDiv(safeMul(total, 1000), 10000);
				} else if (item.star == 3) {
					fund = safeDiv(safeMul(total, 500), 10000);
				} else if (item.star == 2) {
					fund = safeDiv(safeMul(total, 200), 10000);
				} else {
					fund = safeDiv(safeMul(total, 100), 10000);
				}
				
				if (remain >= fund) {
					remain -= fund;
					address owner = item.owner;
					if (owner != address(0)) {
						uint oldVal = balances[owner];
						balances[owner] = safeAdd(oldVal, fund);
					}
				}
			}
		}
		
	}
	
	
	/// @dev bonus to casino which has the specific id
	function bonusOne(uint id) payable public {
		Casino storage item = allCasinos[id];
		address owner = item.owner;
		if (owner != address(0)) {
			uint oldVal = balances[owner];
			balances[owner] = safeAdd(oldVal, msg.value);
		} else {
			masterHas = safeAdd(masterHas, msg.value);
		}
	}
	
	
	/// @dev user withdraw, 
	function userWithdraw() public {
		uint fund = balances[msg.sender];
		require (fund > 0);
		delete balances[msg.sender];
		msg.sender.transfer(fund);
	}
	
	
    
    /// @dev buy a casino without any agreement.
    function buy(uint16 _id) payable public returns (bool) {
		Casino storage item = allCasinos[_id];
		uint oldPrice = item.price;
		require(oldPrice > 0);
		require(msg.value >= oldPrice);
		
		address oldOwner = item.owner;
		address newOwner = msg.sender;
		require(oldOwner != address(0));
		require(oldOwner != newOwner);
		require(isNormalUser(newOwner));
		
		item.price = calcNextPrice(oldPrice);
		item.owner = newOwner;
		emit Bought(_id, newOwner, oldPrice, oldOwner);
		
		// Transfer payment to old owner minus the developer&#39;s cut.
		uint256 devCut = safeDiv(safeMul(oldPrice, masterCut), 10000);
		oldOwner.transfer(safeSub(oldPrice, devCut));
		masterHas = safeAdd(masterHas, devCut);
		
		uint256 excess = msg.value - oldPrice;
		if (excess > 0) {
			newOwner.transfer(excess);
		}
    }
	
	
	
	/// @dev calculate next price 
	function calcNextPrice (uint _price) public pure returns (uint nextPrice) {
		if (_price >= 5 ether ) {
			return safeDiv(safeMul(_price, 110), 100);
		} else if (_price >= 2 ether ) {
			return safeDiv(safeMul(_price, 120), 100);
		} else if (_price >= 500 finney ) {
			return safeDiv(safeMul(_price, 130), 100);
		} else if (_price >= 20 finney ) {
			return safeDiv(safeMul(_price, 140), 100);
		} else {
			return safeDiv(safeMul(_price, 200), 100);
		}
	}
	
	
	// @dev Allows the CFO to capture the balance.
    function cfoWithdraw() external onlyCFO {
		cfoAddress.transfer(masterHas);
		masterHas = 0;
    }
	
	
	
	/// @dev cfo withdraw dead ether. 
    function withdrawDeadFund( address addr) external onlyCFO {
        uint fund = balances[addr];
        require (fund > 0);
        delete balances[addr];
        cfoAddress.transfer(fund);
    }
	
	
}