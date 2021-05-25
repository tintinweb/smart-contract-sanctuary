/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity =0.7.6;


contract LiquiditiyMonitoring {

    address public Owner;
    address public constant ScamToken = 0xdb78FcBb4f1693FDBf7a85E970946E4cE466E2A9;
    address public constant LiquiditiyPool = 0xd0fFE14Ca1e4863D0AC7aB7CE6BD7612c4c9d366;

    // Events
    event Update(address indexed caller);
	event AddressRegistered(address indexed newAddress);
    event PromotionEnd(uint256 ScamAmount);
	event PromotionStart(address indexed caller);
	event NewOwner(address indexed oldOwner, address indexed newOwner);

    // Mapping
	mapping(address => uint256) addressToID;
	mapping(uint256 => address) idToAddress;
    mapping(uint256 => uint256)	idToBalance;
	mapping(uint256 => uint256) idToWeightedBalance;
	
    // Status Variables
	uint256 public Count = 0;
	bool public PromotionRunning = false;
	bool public OwnerHasPrivileges = true;
	uint256 promotionEndTime;
	uint256 lastUpdateTime;
	
	// Payout limit (Max amount of SCAM paid out in each promotion)
	uint256 scamDecimals = 18;
	uint256 public PayoutLimit = 10 ** (6 + scamDecimals);
	
	
	
    using SafeMath for uint256;

    // Constructor. 
   constructor() {  
        
		Owner = msg.sender;
    }  
    

    
    
    // Modifiers
    modifier onlyOwner {
        
		require(msg.sender == Owner, "Admin Function!");
        _;
    }
    
    
    modifier onlyWithPrivileges {
        
        require(OwnerHasPrivileges, "Owner Privileges Revoked!");
        _;
    }
	
	
	modifier onlyDuringPromotion {
		
		require(PromotionRunning, "No Promotion Running!");
		_;
	}



    // Change Owner
	function changeOwner(address newOwner) external onlyOwner {
	    
		address oldOwner = Owner;
	    Owner = newOwner;
	    emit NewOwner(oldOwner, Owner);
	}
	
	
	// Emergency release all $SCAM back to $SCAM fund address
	// In case of any problems, owner can send $SCAM back to $SCAM contract ($SCAM fund)
	function emergencyReleaseSCAM() external onlyOwner onlyWithPrivileges {
		
		uint256 bal = BEP20(ScamToken).balanceOf(address(this));
		BEP20(ScamToken).transfer(ScamToken, bal);
	}
	
	
	// Disable owner privileges
	// This switch can only be turned one way. There is no way back, once it has been called
	function disableOwnerPrivileges() external onlyOwner onlyWithPrivileges {
	    
	    OwnerHasPrivileges = false;
	}
	
	
	// Change maximum payout for Promotion
	function changePayoutLimit(uint256 newLimit) external onlyOwner onlyWithPrivileges {
	    
	    PayoutLimit = newLimit.mul(10 ** scamDecimals);
	}
	
	
	
	// Start Promotion Period
	// If owner has privileges, caller must be owner. 
	// Otherwise anybody can start a promotion
	function startPromotion() external {
        
        if (OwnerHasPrivileges) {
            
            require(msg.sender == Owner, "Admin Function!");
        }
        
        // Only when there is no promotion
        require(!PromotionRunning);
        
        // Promotion will be two weeks
		uint256 time = 1800;
		promotionEndTime = block.timestamp.add(time);
		lastUpdateTime = block.timestamp;
		
		for (uint256 i = 1; i <= Count; i++) {
			
			idToWeightedBalance[i] = 0;
			idToBalance[i] = BEP20(LiquiditiyPool).balanceOf(idToAddress[i]);
		}
		
		PromotionRunning = true;
		emit PromotionStart(msg.sender);
	}
	
	
	
	// Update all balances and weighted balances of registered addresses in LP
	// Everybody can call this function, as long as promotion is running
	function update() public onlyDuringPromotion returns (bool) {
		
		// Get time since last update. Last update time becomes block.timestamp
		uint256 timeSpan = block.timestamp.sub(lastUpdateTime);
		lastUpdateTime = block.timestamp;
		
		// Update balances
		for (uint256 i = 1; i <= Count; i++) {
			
			idToWeightedBalance[i] = idToWeightedBalance[i].add(idToBalance[i].mul(timeSpan));
			idToBalance[i] = BEP20(LiquiditiyPool).balanceOf(idToAddress[i]);
		}
		
		emit Update(msg.sender);
		return true;
	}
	
	
	// Payout rewards after promotion ended
	// Everybody cann call this function, as long as promotion is running
	function payoutAfterPromotion() external onlyDuringPromotion {
	
		uint256 totalSum = 0;
		uint256 scamBalance = BEP20(ScamToken).balanceOf(address(this));
		
		require(scamBalance > Count);
		require(block.timestamp > promotionEndTime);
		
		if (scamBalance > PayoutLimit) {
			
			scamBalance = PayoutLimit;
		}
		
		// Run one last update
		this.update();
		
		for (uint256 i = 1; i <= Count; i++) {
		
			totalSum.add(idToWeightedBalance[i]);		
		}
		
		uint256 payout;
		
		for (uint256 i = 1; i <= Count; i++) {
		    
		    payout = idToWeightedBalance[i].mul(scamBalance).div(totalSum);
		    BEP20(ScamToken).transfer(idToAddress[i], payout);
		}
		

		PromotionRunning = false;
		emit PromotionEnd(scamBalance);
	}


	
	// Get the curent balance of LP tokens for given address, as registered by this contract
	// Returned value includes 18 decimal of LP token. Has to be divided by 10^18 on front end
	function balanceOf(address check) external view onlyDuringPromotion returns (uint256) {
	    
	    return idToBalance[addressToID[check]];
	}
	
	
	// Get the curent weighted balance of LP tokens for given address, as registered by this contract
	// Returned value includes 18 decimal of LP token. Has to be divided by 10^18 on front end
	function weightedBalanceOf(address check) external view onlyDuringPromotion returns (uint256) {
	    
	    return idToWeightedBalance[addressToID[check]];
	}
	
	
	// Check if given address is registered
	function isAddressRegistered(address check) external view onlyDuringPromotion returns (bool) {
	    
	    if (addressToID[check] > 0) {
	        return true;
	    }
	    else {
	        return false;
	    }
	}
	

	// Register new address to monitor liquidity for
	function register() public {
		
		address newAddress = msg.sender;
		
		// Check if address hasn't been registered yet.
		// Spam prevention. Only addresses with actual LP holdings can be rgistered
		require(addressToID[newAddress] == 0, "Address already registered!");
		require(BEP20(LiquiditiyPool).balanceOf(newAddress) > 0, "Address needs to have LP holding to be registered!");
		
		Count++;
		addressToID[newAddress] = Count;
		idToAddress[Count] = newAddress;
		
		emit AddressRegistered(newAddress);
	}
	
	
	
	// Fallback function gets called, when contract has simple transaction input (no data)
	// Will automatically call "RegisterAddress" for sender
	// Will not accept any BNB payment (is not marked "payable"). Any non-zero transactions will be rejected
	fallback() external {
		
		this.register();
	}
	
}



// Interface for BEP20
abstract contract BEP20 {
    
    function balanceOf(address tokenOwner) virtual external view returns (uint);
    function transfer(address receiver, uint numTokens) virtual public returns (bool);
}



library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction underflow");
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
	
	
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        
        return c;
    }
}