pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public newOwner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor(address _owner) public {
    if(_owner == address(0)) {
      owner = msg.sender;
    } else {
      owner = _owner;
    }
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  /**
    * @dev confirm ownership by a new owner
    */
  function confirmOwnership() public {
      require(msg.sender == newOwner);
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
      newOwner = 0x0;
  }
}

/* @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

contract SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ICrowdsaleReservationFund
 * @dev ReservationFund methods used by crowdsale contract
 */

interface ICrowdsaleReservationFund{
	/**
	 * @dev check if contributor has transactions
	 */
	function canCompleteContribution(address contributor) external returns(bool);
	/**
	 * @dev complete contribution
	 * param contributor Contributor&#39;s address
	 */
	function completeContribution(address contributor) external;
	/**
	 * @dev function accepts user&#39;s contributed ether and amount of tokens to issue
	 * param contributor Contributor wallet address
	 * param tokensToIssue Token amount to issue
	 * param _bonusTokensToIssue Bonus token amount to issue
	 */
	 
	 function processContribution(address contributor, uint256 _TokensToIssue, uint256 _bonusTokensToIssue) external payable;
	 
	 /**
	  * @dev function returns current user&#39;s contributed ether amount
	  */
	 function contributionsOf(address contributor) external returns(uint256);
	 
	 /**
	  * @dev function is called on the end of successful crowdsale
	  */
	 function onCrowdsaleEnd() external;
}

interface ISimpleCrowdsale{
	function getSoftCap() external view returns(uint256);
	function isContributorInLists(address isContributorAddress) external view returns(bool);
	function processReservationFundContribution(
		address contributor,
		uint256 tokenAmount,
		uint256 tokenBonusAmount
	) external payable;
}

contract ReservationFund is ICrowdsaleReservationFund, Ownable, SafeMath {
	bool public crowdsaleFinished = false;

	mapping(address => uint256) contributions;
	mapping(address => uint256) tokensToIssue;
	mapping(address => uint256) bonusTokensToIssue;

	ISimpleCrowdsale public crowdsale;

	event RefundPayment(address contributor, uint256 etr_amount);
	event TransferToFund(address contributor, uint256 eth_amount);
	event FinishCrowdsale();

	/**
	 * @dev owner is platform manager that has just set crowdsale address
	 */
	constructor(address _owner) public Ownable(_owner){
	}

	modifier onlyCrowdsale(){
		require(msg.sender == address(crowdsale));
		_;
	}

	/**
	 * @dev set crowdsale once by owner
	 */
	function setCrowdsaleAddress(address crowdsaleAddress) public onlyOwner{
		require(crowdsale == address(0));
		crowdsale = ISimpleCrowdsale(crowdsaleAddress);
	}

	function onCrowdsaleEnd() external onlyCrowdsale {
		crowdsaleFinished = true;
		emit FinishCrowdsale();
	}

	function canCompleteContribution(address contributor) external returns(bool){
		if(crowdsaleFinished){
			return false;
		}
		if(!crowdsale.isContributorInLists(contributor)){
			return false;
		}
		if(contributions[contributor] ==0){
			return false;
		}
		return true;
	}

	/**
	 * @dev Function to check contributions by address
	 */
	function contributionsOf(address contributor) external returns(uint256) {
	    return contributions[contributor];
	}
	
	/**
	 * @dev process crowdsale contribution without whitelist
	 */
	function processContribution(
		address contributor,
		uint256 _tokensToIssue,
		uint256 _bonusTokensToIssue
	) external payable onlyCrowdsale {
		contributions[contributor] = safeAdd(contributions[contributor], msg.value);
		tokensToIssue[contributor] = safeAdd(tokensToIssue[contributor], _tokensToIssue);
		bonusTokensToIssue[contributor] = safeAdd(bonusTokensToIssue[contributor], _bonusTokensToIssue);
	}
	
	/**
	 * @dev complete contribution after if user is whitelisted
	 */
	function completeContribution(address contributor) external {
		require(!crowdsaleFinished);
		require(crowdsale.isContributorInLists(contributor));
		require(contributions[contributor] > 0);

		uint256 eth_amount = contributions[contributor];
		uint256 tokenAmount = tokensToIssue[contributor];
		uint256 tokenBonusAmount = bonusTokensToIssue[contributor];

		contributions[contributor] = 0;
		tokensToIssue[contributor] = 0;
		bonusTokensToIssue[contributor] = 0;

		crowdsale.processReservationFundContribution.value(eth_amount)(contributor, tokenAmount, tokenBonusAmount);
		emit TransferToFund(contributor, eth_amount);
	}

	/**
	 * @dev Refund payments if crowdsale is finalized
	 */
	function refundPayment(address contributor) public {
		require(crowdsaleFinished);
		require(contributions[contributor] > 0 || tokensToIssue[contributor] > 0);
		uint256 amountToRefund = contributions[contributor];

		contributions[contributor] = 0;
		tokensToIssue[contributor] = 0;
		bonusTokensToIssue[contributor = 0];
		
		contributor.transfer(amountToRefund);
		emit RefundPayment(contributor, amountToRefund);
	}
}