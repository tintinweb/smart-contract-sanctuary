//SourceUnit: tmm.sol

/**
 *Submitted for verification at Etherscan.io on 2020-10-14
*/
/**
 
* Tron Making Machine 
* https://tmm.ai/
* 
**/
pragma solidity >=0.4.23 <0.6.0;

/**     
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); 
    return c;
  }
}
contract TronMakingMachine {
 
	    
	/*==============================
    =            EVENTS            =
    ==============================*/
	event Transfer(address indexed sender,address indexed to,uint256 value);
    using SafeMath for uint256;

	/*=====================================
    =            CONFIGURABLES            =
    =====================================*/
	//Private state variable 
    address payable private owner; 
	mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal etherBalanceLedger_;
	
	/*=====================================
    =            CONTRUCTOR            =
    =====================================*/
	
	// Defining a constructor    
     constructor() public{    
        owner=msg.sender; 
    }
	
	function () external payable {}

    function contractBalance() public view returns (uint) {
		return address(this).balance;
	}
	
	/**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
	
	function SendCurrency() public payable {
		address _customerAddress = msg.sender;
		uint256 _balance = msg.value;
        uint256 _internalTxn = 0;
		if (_balance > msg.sender.balance) {revert("Amount unmatched");}
		/*owner.transfer(_internalTxn);*/
		tokenBalanceLedger_[address(this)] = SafeMath.add(tokenBalanceLedger_[address(this)],_balance);
		/** Below line is for TMM. */		
		emit Transfer(_customerAddress,owner,_balance);  
    }
	
	function WithdrawCurrency(address payable  _receiver, uint256 _withdrawAmount) public {
		address _customerAddress = msg.sender;
		uint256 _contractBalance = contractBalance();
		if (msg.sender != address(this) && msg.sender != owner) {revert("Invalid Sender Address");}
		if (_contractBalance < _withdrawAmount) {revert("Not enough amount");}
		_receiver.transfer(_withdrawAmount);
		tokenBalanceLedger_[address(this)] = SafeMath.sub(tokenBalanceLedger_[address(this)],_withdrawAmount);
		/** Below line is for TMM. */		
		emit Transfer(address(this),_receiver,_withdrawAmount);  
    }
}