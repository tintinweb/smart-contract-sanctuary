pragma solidity ^0.4.25;


contract Prosperity {
	/**
     * Withdraws all of the callers earnings.
     */
	function withdraw() public;
	
	/**
     * Retrieve the dividends owned by the caller.
     * If `_includeReferralBonus` is 1/true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate. 
     */ 
    function myDividends(bool _includeReferralBonus) public view returns(uint256);
}


contract Fund {
    using SafeMath for *;
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // administrators can:
    // -> change add or remove devs
    // they CANNOT:
    // -> change contract addresses
    // -> change fees
    // -> disable withdrawals
    // -> kill the contract
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrator_ == _customerAddress);
        _;
    }
    
    
    /*================================
    =            DATASETS            =
    ================================*/
    address internal administrator_;
    address internal lending_;
    address internal freeFund_;
    address[] public devs_;
	
	// token exchange contract
	Prosperity public tokenContract_;
    
    // distribution percentages
    uint8 internal lendingShare_ = 50;
    uint8 internal freeFundShare_ = 20;
    uint8 internal devsShare_ = 30;
    
    
    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/
    constructor()
        public 
    {
        // set addresses
        administrator_ = 0xA1bAeAaC24AeC31FBF0F8895bf8177cDB7Ccc759;
        lending_ = 0x25dA1B71a689697589Df09C9E5b8394C2a8Fc7e2;
        freeFund_ = 0xA1bAeAaC24AeC31FBF0F8895bf8177cDB7Ccc759;
        
        // Add devs
        devs_.push(0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825);
        devs_.push(0x6134DD437C51423410BE01aBB8D7CEe427B90481);
        devs_.push(0xd2e67b7678c2AFEe6C3Bf3E698Aa19F1d6fc0746);
    }
    
    /**
     * Distribute ether to lending, freeFund and devs
     */
    function pushEther()
        public
    {
		// get dividends (mainly referral)
		if (myDividends(true) > 0) {
			tokenContract_.withdraw();
		}
		
		// current balance (after withdraw)
        uint256 _balance = getTotalBalance();
        
		// distributed reinvestments
        if (_balance > 0) {
            uint256 _ethDevs      = _balance.mul(devsShare_).div(100);          // total of 30%
            uint256 _ethFreeFund  = _balance.mul(freeFundShare_).div(100);      // total of 20%
            uint256 _ethLending   = _balance.sub(_ethDevs).sub(_ethFreeFund);   // approx. 50%
            
            lending_.transfer(_ethLending);
            freeFund_.transfer(_ethFreeFund);
            
            uint256 _devsCount = devs_.length;
            for (uint8 i = 0; i < _devsCount; i++) {
                uint256 _ethDevPortion = _ethDevs.div(_devsCount);
                address _dev = devs_[i];
                _dev.transfer(_ethDevPortion);
            }
        }
    }
    
    /**
     * Add a dev to the devs fund pool.
     */
    function addDev(address _dev)
        onlyAdministrator()
        public
    {
        // address must not be dev before, we do not want duplicates
        require(!isDev(_dev), "address is already dev");
        
        devs_.push(_dev);
    }
    
    /**
     * Remove a dev from the devs fund pool.
     */
    function removeDev(address _dev)
        onlyAdministrator()
        public
    {
        // address must be dev before, we need a dev address to be able to remove him
        require(isDev(_dev), "address is not a dev");
        
        // get index and delte dev
        uint8 index = getDevIndex(_dev);
        
        // close gap in dev list
        uint256 _devCount = getTotalDevs();
        for (uint8 i = index; i < _devCount - 1; i++) {
            devs_[i] = devs_[i+1];
        }
        delete devs_[devs_.length-1];
        devs_.length--;
    }
    
    
    /**
     * Check if given address is dev or not
     */
    function isDev(address _dealer) 
        public
        view
        returns(bool)
    {
        uint256 _devsCount = devs_.length;
        
        for (uint8 i = 0; i < _devsCount; i++) {
            if (devs_[i] == _dealer) {
                return true;
            }
        }
        
        return false;
    }
    
    
    // VIEW FUNCTIONS
    function getTotalBalance() 
        public
        view
        returns(uint256)
    {
        return address(this).balance;
    }
    
    function getTotalDevs()
        public 
        view 
        returns(uint256)
    {
        return devs_.length;
    }
	
	function myDividends(bool _includeReferralBonus)
		public
		view
		returns(uint256)
	{
		return tokenContract_.myDividends(_includeReferralBonus);
	}
    
    
    // INTERNAL FUNCTIONS
    /**
     * Check index of given address
     */
    function getDevIndex(address _dev)
        internal
        view
        returns(uint8)
    {
        uint256 _devsCount = devs_.length;
        
        for (uint8 i = 0; i < _devsCount; i++) {
            if (devs_[i] == _dev) {
                return i;
            }
        }
    }
	
	// SETTER
	/**
	 * Set the token contract
	 */
	function setTokenContract(address _tokenContract)
		onlyAdministrator()
		public
	{
		tokenContract_ = Prosperity(_tokenContract);
	}
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}