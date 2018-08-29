pragma solidity ^0.4.13;

contract FishermansFeeCalculator {

	function calculateFee(uint256, uint256) public view returns (uint256);
}

interface KyberProxyInterface{
    function getExpectedRate(address src, address dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);
    function swapTokenToToken(
        address src,
        uint srcAmount,
        address dest,
        uint minConversionRate
    )
        public
        returns(uint);
}

interface ShortFactoryInterface {

    function newShortPosition(
        address[7] addresses,
        uint[4] uints,
        uint32[3] uints32
    ) public returns(address);
}

interface TokenConverter {
	function convert(address, address, address, uint256, uint256) external returns (uint256);
	function getReturn(address, address, address, uint256) external returns (uint256);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
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
}

contract Short is Ownable{
	using SafeMath for uint32;
	using SafeMath for uint;
	using SafeMath for int;
	using SafeMath for uint8;
	//TODO add validation that all parties deposited what they need to operate
	// traded tokens
	ERC20 public shortedToken;
	ERC20 public liquidationToken;

	address public shorter; // address of the shorter

	uint32 public interestRate; // interest payed PER DAY PASSED in shorted coin to loaner - represented in ppm(100 = 0.01%, 100000 = 100%)

	uint public collateralAmount; // amount of collateral the shorter provided - in liquidated tokens
	uint public liquidationTokenAmount; // liquidation tokens that are to be converted back to shorted tokens when position is closed
	uint public shortedTokenAmount; // shorted tokens to give back to loaner when short position is closed

	address public fishermansFeeCalculator; // address of the fishermans fee contract calculator

	uint32 public underCollaterizationRate; // specifies the rate of the shorted token - if the value of the shorted token is above the rate - the position is Undercollaterized - represented in ppm

	uint32 public adminFeeRate;  // Fee (% in ppm) payed from amount of tokens passed to loaner after closing of short position, to monti (admin)
	address admin; // address of the admin (monti)

	uint public shortPositionCreationTime;
	uint public expiryTime; // time after which position becomes expired
	uint public globalExpiryTime; // global expiry time - short becomes expired if on of expiryTime and globalExpiryTime has passed

	KyberProxyInterface public tokenConverter;
	uint8 constant MIN_CONVERSION_AMOUNT = 1;
	uint8 constant MIN_TRANSFER_AMOUNT = 0;
	uint32 private constant MAX_INTEREST_RATE = 1000000;
	uint32 private constant MAX_UNDERCOLLATERIZATION_RATE = 1000000;
	uint  private constant SECONDS_IN_A_DAY = 86400;

	address public approvedTaker; // new shorter to replace the current shorter

    enum ShortPositionState { Open, Closed, Expired, Undercollaterized }
    ShortPositionState public state;

	event ConvertedTokens(address _fromToken, address _toToken, uint _amount, uint _returnAmount);
	event TransferingTokens(uint _toLender, uint _toShorter, uint _toFisherman, uint _toAdmin);

	modifier onlyShorter() {
		require(msg.sender == shorter);
		_;
	}

	modifier onlyAdmin() {
		require(msg.sender == admin);
		_;
	}

	modifier closeable() {
		require(msg.sender == shorter || (msg.sender == owner && state == ShortPositionState.Expired));
		_;
	}

	modifier underCollaterized() {
		if (state != ShortPositionState.Undercollaterized){	
			uint liquidationTokenAmount = liquidationTokenAmount;
			uint minRate;
			(,minRate)=tokenConverter.getExpectedRate(liquidationToken, shortedToken, liquidationTokenAmount);
			uint expectedReturn = minRate.mul(liquidationTokenAmount);
			uint interest = calculateLoanerInterest(shortedTokenAmount);
			require(expectedReturn < (shortedTokenAmount.add(interest)).mul(MAX_UNDERCOLLATERIZATION_RATE) / MAX_UNDERCOLLATERIZATION_RATE.add(underCollaterizationRate));
		}
		_;
	}

	modifier open() {
		require(state == ShortPositionState.Open);
		_;
	}

	modifier closed() {
		require(state == ShortPositionState.Closed);
		_;
	}

	modifier expired() {
		require(now > shortPositionCreationTime.add(globalExpiryTime) || now > shortPositionCreationTime.add(expiryTime));
		_;
	}

	modifier initiallyFunded() {
		require(shortedTokenAmount == shortedToken.balanceOf(this));
		_;
	}

	modifier funded(){
		require(liquidationToken.balanceOf(this) == liquidationTokenAmount.add(collateralAmount));
		_;
	}

	/*
        address _admin, 0
    	address _loaner, 1
    	address _shortedToken, 2
     	address _liquidationToken, 3
     	address _shorter, 4
     	address _tokenConverter, 5
     	address _fishermansFeeCalculator, 6
     	uint _expiryTime, 0
     	uint _globalExpiryTime, 1
     	uint _collateralAmount, 2
     	uint _shortedTokenAmount, 3
     	uint32 _underCollaterizationRate, 0
     	uint32 _interestRate, 1
     	uint32 _adminFee 2
    */
    constructor(address[7] addresses,
                uint[4] uints,
                uint32[3] uints32) {
        admin = addresses[0];
        owner = addresses[1];
		shortedToken = ERC20(addresses[2]);
		liquidationToken = ERC20(addresses[3]);
        shorter = addresses[4];
        tokenConverter = KyberProxyInterface(addresses[5]);
        fishermansFeeCalculator = addresses[6];
        expiryTime = uints[0];
        globalExpiryTime = uints[1];
		collateralAmount = uints[2];
		shortedTokenAmount = uints[3];
		underCollaterizationRate = uints32[0];
		interestRate = uints32[1];
        adminFeeRate = uints32[2];
		shortPositionCreationTime = now;
	}

	/// @dev get the current state of the position
	// function getShortPositionState() public view returns(ShortPositionState) {
	// 	return state;
	// }

	///@dev change the admins address (for fee transfers)
	function changeAdmin(address _newAdmin) public onlyAdmin returns(bool){
		admin = _newAdmin;
		return true;
	}


	/// @dev approve of another address to take the short position as the shorte
	/// @param newShorter  			the address of the new shorter that take the position
	function approveNewShorter(address newShorter) public onlyShorter returns (bool) {
		approvedTaker = newShorter;
		return true;
	}

	/// @dev replace the shorters address to the new shorter - invoked by an approved address
	function replaceShorter() public returns (bool) {
		require (msg.sender == approvedTaker);
		shorter = msg.sender;
		approvedTaker = address(0);
		return true;
	}

	/// @dev Add more collateral to position
	/// @param _amount the amount to add
	function addCollateral(uint _amount) external open {
		collateralAmount = collateralAmount.add(_amount);
		liquidationToken.transferFrom(msg.sender, this, _amount);
	}

	function getExpectedMinReturn(address source, address dest, uint amount) public  view returns (uint minReturn){
		uint minRate;
		(,minRate) = tokenConverter.getExpectedRate(source, dest, amount);
		return minRate.mul(amount);
	}

	/// @dev convert the shorted tokens deposited to the Short contract by loaner - making the short position OPEN
	///		 this must happen right after creating the position
	function convertShortedTokensToLiquidationToken(uint minAmount) external initiallyFunded /*onlyOwner*/ {
		 liquidationTokenAmount = convertTokens(address(shortedToken), address(liquidationToken), shortedToken.balanceOf(this), minAmount);
         state = ShortPositionState.Open;
	}
 
	/// @dev calculate the required amount of liquidationTokens to convert to get the amount needed to filledAmount
	/// @param shortedTokenAmountToFill the amount that is required to fill by the conversion
	function calculateRequiredFillingAmount(uint shortedTokenAmountToFill) internal returns (uint){
		//uint conversionAmount = MIN_CONVERSION_AMOUNT;
		//uint expectedReturn = 0;
		//uint conversionAmountForOneToken = conversionAmount;
		uint liquidationTokenRequiredAmount = 0;
		//uint shortedTokenReturn = 0;
		
		liquidationTokenRequiredAmount = getExpectedMinReturn(shortedToken, liquidationToken, shortedTokenAmountToFill);
		 
		uint sanityCheck = getExpectedMinReturn(liquidationToken, shortedToken,  liquidationTokenRequiredAmount);

		if (sanityCheck < shortedTokenAmountToFill){
			liquidationTokenRequiredAmount = liquidationTokenRequiredAmount.add(1);
		}
		if ( collateralAmount < liquidationTokenRequiredAmount){
			return collateralAmount;
		}
		else{
			return liquidationTokenRequiredAmount;
		}

		
	}

	/// @dev fill the loan difference remaining after position closing conversion, from collateral token
	/// @param shortedAmountToFill amount of shorted tokens needed to fill
	function fillFromCollateral(uint shortedAmountToFill) internal returns (uint) {
			uint liquidationTokensRequiredAmount = calculateRequiredFillingAmount(shortedAmountToFill);
			return convertTokens( address(liquidationToken), address(shortedToken), liquidationTokensRequiredAmount, MIN_CONVERSION_AMOUNT);
	}

	/// @dev Close the short position, convert and transfer funds according to amount loss or won
	function closeShortPosition() public closeable funded{
		//uint shortedTokenBalance = convertTokens(address(liquidationToken), address(shortedToken), liquidationTokenAmount, MIN_CONVERSION_AMOUNT);
		
		// instead of directly converting all LiquidationTokenAmount - we calculate the return for the conversion
		// so if there are profits we would not need to convert twice
		
		
		uint shortedTokenBalance = getExpectedMinReturn(address(liquidationToken), address(shortedToken), liquidationTokenAmount);
		uint shortedTokenToLoanerAmount = shortedTokenAmount;

		uint interest = calculateLoanerInterest(shortedTokenToLoanerAmount);
		shortedTokenToLoanerAmount = shortedTokenToLoanerAmount.add(interest);
		int shortedTokenDifference = int(shortedTokenBalance) - int(shortedTokenToLoanerAmount);

		

		if (shortedTokenDifference < 0) {
			// we can convert all liquidationTokenAmount here 
			shortedTokenBalance = convertTokens(address(liquidationToken), address(shortedToken), liquidationTokenAmount, MIN_CONVERSION_AMOUNT);
			uint filledAmount = fillFromCollateral(uint(- shortedTokenDifference));
			
			// Handle the edge case where there is not enough collateral:
			if (filledAmount < uint(- shortedTokenDifference)){
				transferTokensToParticipants(shortedToken.balanceOf(this) , 0, 0, 0, address(0));

				state = ShortPositionState.Closed;
				return;
			}

		} else {
			// int shorterProfits = int(shortedTokenBalance) - int(shortedTokenToLoanerAmount);
			// uint _liquidationTokenAmount = 0;
			// Check if there are any profits to convert
			// if (shorterProfits >= int(MIN_CONVERSION_AMOUNT)){
			// 	 _liquidationTokenAmount = convertTokens(address(shortedToken), address(liquidationToken), uint(shorterProfits), MIN_CONVERSION_AMOUNT);
			// }
			uint liquidationTokenAmountToConvert = calculateRequiredFillingAmount(shortedTokenToLoanerAmount);
			shortedTokenBalance = convertTokens(address(liquidationToken), address(shortedToken), liquidationTokenAmountToConvert, MIN_CONVERSION_AMOUNT);
		}

		uint adminFee = calculateAdminFee(shortedTokenToLoanerAmount);
		
		shortedTokenToLoanerAmount = shortedTokenToLoanerAmount.sub(adminFee);
		uint liquidationTokensToShorter = liquidationToken.balanceOf(this);
		transferTokensToParticipants(shortedTokenToLoanerAmount , liquidationTokensToShorter, adminFee, 0, address(0));

		state = ShortPositionState.Closed;
	}

	/// @dev calculate fishermans fee for this short position (in shorted tokens)
	 function calculateFishermansFee() public view returns (uint256) {
	 	return FishermansFeeCalculator(fishermansFeeCalculator).calculateFee(shortedTokenAmount, liquidationTokenAmount);
	}

	/// @dev return true if loan length has passed from the loan creation time
	function isShortPositionExpired() public view returns (bool) {
		return (now > shortPositionCreationTime.add(expiryTime));
	}

	/// @dev change short position state to expired if its expiry time passed
	function setShortPositionExpired() public expired {
		state = ShortPositionState.Expired;
	}

	/// @dev change the formula that calculates the fishermans fee
	/// @param newFishermansFeeCalculator - the address of the new calculator to use
	// function changeFisherMansFeeCalculator(address newFishermansFeeCalculator) public onlyOwner {
	// 	fishermansFeeCalculator = newFishermansFeeCalculator;
	// }

	/// @dev liquidate (and close) the position, and transfer tokens according to profit status and caller.
	/// 	 can only be called by a fisherman
	function closeUndercollaterizedPosition() public underCollaterized funded {
		convertTokens(address(liquidationToken) , address(shortedToken), liquidationTokenAmount, MIN_CONVERSION_AMOUNT);

		// calculate the amount of tokens the loaner needs to recieve
		uint shortedAmountToLoaner = shortedTokenAmount;
		uint loanerInterest = calculateLoanerInterest(shortedAmountToLoaner);
		shortedAmountToLoaner = shortedAmountToLoaner.add(loanerInterest);

		// calculate how many shorted tokens are needed to fill the amount that is required to be sent to loaner
		uint shortedTokenBalance = shortedToken.balanceOf(this); // check the balance of contract in shorted token
		int shortedTokenDifference = int(shortedAmountToLoaner) - int(shortedTokenBalance);
		
		// calculate fishermansFee and convert to shorted token from collateral
		uint fishermansFee = calculateFishermansFee();
		//filledAmount = fillFromCollateral(fishermansFee);

		// fill the loan from collateral (+interest)
		uint filledAmount = fillFromCollateral(uint(shortedTokenDifference).add(fishermansFee));
		
		// If we didn&#39;t manage to fill the loan
		if (filledAmount < uint(shortedTokenDifference).add(fishermansFee)){
				transferTokensToParticipants(shortedToken.balanceOf(this).sub(fishermansFee), 0, 0, fishermansFee, msg.sender);

				state = ShortPositionState.Closed;
				return;
			}

		// calculate admin fee from loaner
		uint adminFee = calculateAdminFee(shortedAmountToLoaner);
		shortedAmountToLoaner = shortedAmountToLoaner.sub(adminFee);

		// divide tokens to participants
		uint liquidationTokensToShorter = liquidationToken.balanceOf(this);
		transferTokensToParticipants(shortedAmountToLoaner, liquidationTokensToShorter, adminFee, fishermansFee, msg.sender);

		state = ShortPositionState.Closed;
	}

	/// @dev set the position state to be underCollaterized. modifier checks the undercollaterization condition
	function setUnderCollaterizedPosition() public underCollaterized returns(bool) {
		// if short position is expired we keep it that way
		if(state != ShortPositionState.Expired){
			state = ShortPositionState.Undercollaterized;
		}
		return true;
	}

	/// @dev convert tokens via tokenConverter after approval of converter to transfer the _amount of _fromToken
	/// @param _fromToken					token to convert from
	/// @param _toToken 					token to convert to
	/// @param _amount 						amount to convert
	/// @param _minimunConversionAmount		minimum conversion amount allowed
	function convertTokens(address _fromToken, address _toToken, uint _amount, uint _minimunConversionAmount) internal returns(uint) {
		ERC20(_fromToken).approve(tokenConverter, _amount);
		uint minRate;
		(,minRate) = tokenConverter.getExpectedRate(_fromToken, _toToken, _amount);
		uint conversionResult = tokenConverter.swapTokenToToken(_fromToken, _amount, _toToken , minRate);
		emit ConvertedTokens(_fromToken, _toToken, _amount, conversionResult);
		return conversionResult;
	}

	/// @dev calculated the interest required to pay to loaner
	/// @param _amount the amount of shorted tokens the loaner need to get back without interest
	function calculateLoanerInterest(uint _amount) internal view returns (uint) {
		uint timeDiff = now - shortPositionCreationTime;
		uint daysPassed = timeDiff.div(SECONDS_IN_A_DAY);
		// TODO Should we add 1 to daysPassed? so if the position closed
		//in a certain day the interest would be payed for thiss day too
		return (_amount.mul(interestRate) / MAX_INTEREST_RATE) * (daysPassed.add(1));

	}

	/// @dev calculate the fee the admin will recieve on shorted tokens sent back to loaner
	/// @param _amount amount of shorted tokens that are supposed to be sent back to loaner
	function calculateAdminFee(uint _amount) internal view returns(uint) {
		return _amount.mul(adminFeeRate) / MAX_INTEREST_RATE;
	}

	/// @dev transfer tokens to participants
	/// @param _amountToLoaner 		amount of tokens to send to loaner (shorted tokens)
	/// @param _amountToShorter 	amount of tokens to send to shorter (liquidation tokens)
	/// @param _amountToAdmin 		amount of tokens to send to admin (shorted tokens)
	/// @param _amountToFisherman 	amount to send to fisherman (if existant, in shorted tokens)
	/// @param fisherman 			fishermans address (0 if the is no fisherman)
	function transferTokensToParticipants(
        uint _amountToLoaner,
        uint _amountToShorter,
        uint _amountToAdmin,
        uint _amountToFisherman,
        address fisherman
    )
        internal
        returns(bool)
    {
		emit TransferingTokens(_amountToLoaner, _amountToShorter,_amountToFisherman, _amountToAdmin );
		if (fisherman != address(0)){
			shortedToken.transfer(fisherman, _amountToFisherman);
		}

		if (_amountToLoaner >= MIN_TRANSFER_AMOUNT){
			shortedToken.transfer(owner, _amountToLoaner);
		}
		if (_amountToAdmin >= MIN_TRANSFER_AMOUNT){
			shortedToken.transfer(admin, _amountToAdmin);
		}
		if (_amountToShorter >= MIN_TRANSFER_AMOUNT){
			liquidationToken.transfer(shorter, _amountToShorter);
		}

		return true;
	}

	function terminateShortPosition() public onlyOwner closed{
		selfdestruct(owner);
	}


	/*functions for testing purposes*/
	function isFunded() funded view returns(bool){
		return true;
	}

	function isCloseable() closeable view returns(bool){
		return true;
	}

	function isOpen() view returns(bool){
		return state == ShortPositionState.Open;
	}

}

contract ShortFactory is ShortFactoryInterface, Ownable {

    constructor() {
        owner = msg.sender;
    }

    function newShortPosition(
        /* address _admin,
		address _loaner,
		address _shortedToken,
	 	address _liquidationToken,
	 	address _shorter,
	 	address _tokenConverter,
	 	address _fishermansFeeCalculator,
	 	uint _expiryTime,
	 	uint _globalExpiryTime,
	 	uint _collateralAmount,
	 	uint _shortedTokenAmount,
	 	uint32 _underCollaterizationRate,
	 	uint32 _interestRate,
	 	uint32 _adminFee */
        address[7] addresses,
        uint[4] uints,
        uint32[3] uints32
    )
    public
    //onlyOwner() // TODO why? who deploys the factory? why should it be onlyOwner?
    returns(address)
    {
        address shortPosition = new Short(
            addresses,
    		uints,
    		uints32);
        return shortPosition;
    }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}