pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
		// Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
		// benefit is lost if &#39;b&#39; is also tested.
		if (_a == 0) {
			return 0;
		}

		c = _a * _b;
		assert(c / _a == _b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
		// uint256 c = _a / _b;
		// assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
		return _a / _b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflowы (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		assert(_b <= _a);
		return _a - _b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
		c = _a + _b;
		assert(c >= _a);
		return c;
	}
}

contract Math {
	using SafeMath for uint;

	function power(uint256 a, uint256 b) internal pure returns (uint256 res){
		res = 1;
		for (uint i = 0; i < b; i++) {
			res = res.mul(a);
		}
	}

	function multiply(uint a, uint b, uint decimals) internal pure returns(uint){
		return ((a.mul(b)).div(power(10, (decimals**2))));
	}
}

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/

contract Ownable {
	address internal _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/*
	* @dev The Ownable constructor sets the original `owner` o the contract to the sender account
	*/
	constructor() public {
		_owner = msg.sender;
	}

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner() {
		require(msg.sender == _owner);
		_;
	}

	/**
	* @dev Allows the current owner to transfer control of the contract to a newOwner.
	* @param newOwner The address to transfer ownership to.
	*/
	function transferOwnership(address newOwner) onlyOwner() public {
		require(newOwner != _owner);
		_transferOwnership(newOwner);
	}

	/**
	* @dev Transfers control of the contract to a newOwner.
	* @param newOwner The address to transfer ownership to.
	*/
	function _transferOwnership(address newOwner) internal {
		// require(newOwner != address(0));
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}

	function getOwner() public constant returns(address) {
		return (_owner);
	}
}

/*
* Interface ERC20
*/

contract Token {

	function transfer( address _to, uint256 _value ) public returns ( bool success );
	
	function transferFrom( address _from, address _to, uint256 _value ) public returns ( bool success );
	
	event Transfer( address indexed _from, address indexed _to, uint256 _value );

}

contract 	Admins is Ownable {

	mapping(address => bool) internal _moderators;

	address public _prevSmartContract;

	address public _nextSmartContract;

	string 	public _version;

	/**
	* @dev Construct.
	*/
	constructor() public {
		_prevSmartContract = address(0x0);
		_nextSmartContract = address(0x0);
		_version = "0.01";
		_moderators[msg.sender] = true;
		_moderators[0xA96603Bb6AE590d0f565307BeF31f7936c07DA90] = true;
	}

	function	changeStatusModerator(
		address user,
		bool status
	)
		public
		notNullAddress(user)
		onlyOwner()
	{
		_moderators[user] = status;
	}

	function 	setNextSmartContract(
		address smartContract
	)
		public
		notNullAddress(smartContract)
		onlyOwner()
	{
		_nextSmartContract = smartContract;
	}

	/**
	* @dev Throws if called by any account other than the moderator.
	*/
	modifier onlyModerator() {
		require(_moderators[msg.sender] == true);
		_;
	}

	/**
	* @dev Throws if called by null account
	* @param user The address to check at zero address
	*/
	modifier notNullAddress(address user) {
		require(user != address(0x0));
		_;
	}

	/**
	* 	gets methods
	*	@param user The address to get status user
	*/
	function 	getStatusModerator(address user) public view returns (bool) {
		return 	(_moderators[user]);
	}
}

contract BalanceToken is Admins, Math {

	address public _token;

	mapping(address => uint) public _balanceOf;

	address public _liquidatePool;

	event TransferToken(address to, address from, uint amount);

	event Deposit(address token, address user, uint amountDeposit, uint balanceNow);

	event WithdrawForUser(address token, address user, uint amount, uint balanceNow);

	event WithdrawLiquidatePool(
		address token,
		address owner,
		uint amount,
		uint balanceLiquidatePool
	);

	event DepositLiquidatePool(
		address token,
		address user,
		uint amountDeposit,
		uint balanceLiquidatePool
	);

	constructor(/*address liquidatePool*/) public {
		/*require(liquidatePool != address(0x0));*/
		_liquidatePool = msg.sender; // for testing
		_token = 0x8345BE4100f7a455822836aB77DAaa82Ee4ABFAD;
	}

	function 	depositToken(uint amount) notZero(amount) public {
		require(msg.sender != _liquidatePool);
		
		_balanceOf[msg.sender] = (_balanceOf[msg.sender].add(amount));
		if (Token(_token).transferFrom(msg.sender, this, amount) == false) {
			revert();
		}
		emit Deposit(_token, msg.sender, amount , _balanceOf[msg.sender]);
	}


	function 	withdrawTokenForUser(uint amount) notZero(amount) public {
		_balanceOf[msg.sender] = _balanceOf[msg.sender].sub(amount);
		if (Token(_token).transfer(msg.sender, amount) == false) {
			revert();
		}
		emit WithdrawForUser(_token, msg.sender, amount, _balanceOf[msg.sender]);
	}

	function 	depositLiquidateThePool(uint amount) notZero(amount) public {
		_balanceOf[_liquidatePool] = _balanceOf[_liquidatePool].add(amount);
		if (Token(_token).transferFrom(msg.sender, this, amount) == false) {
			revert();
		}
		emit DepositLiquidatePool(
			_token,
			msg.sender,
			amount,
			 _balanceOf[_liquidatePool]
		);
	}

	function 	withdrawLiquidatePool(
		uint amount
	)
		notZero(amount)
		onlyOwner()
		public
	{
		_balanceOf[_liquidatePool] = _balanceOf[_liquidatePool].sub(amount);
		if (Token(_token).transfer(msg.sender, amount) == false) {
			revert();
		}
		emit WithdrawLiquidatePool(
			_token,
			msg.sender,
			amount,
			_balanceOf[_liquidatePool]
		);
	}

	function transferToken(
		address user,
		uint amount
	)
		public
		onlyModerator()
	{
		_balanceOf[_liquidatePool] = _balanceOf[_liquidatePool].sub(amount);
		_balanceOf[user] = _balanceOf[user].add(amount);
		emit TransferToken(msg.sender, user, amount);
	}

	modifier 	notZero(uint amount) {
		require(amount != 0);
		_;
	}
}

contract BetsMatch is BalanceToken {

	uint public constant MIN_ETHER_BET = (1 ether / 100);

	struct Event {
		bytes16[] hashMarketItem;
		bool closed;
		bool closeSuccess;
	}

	struct MarketItem {
		bytes16[] outcomes;
		uint8 numberWinOutcome;
		bytes16 hashEventParent;
	}

	struct Bet {
		address user;
		uint amountBet;
		uint amountBetReward;
		uint coef;
		bytes16 outcome;
		bool verified;
		bool end;
	}

	struct Outcome {
		bytes16 hashMarketItem;
		bytes16[] bet;
		uint amountCloseBet;
	}

	/* For bets */
	mapping(bytes16 => Bet) public _betsMapping;

	/* For outcome */

	mapping(bytes16 => Outcome) public _outcomeMapping;

	/* Event */
	mapping(bytes16 => Event) private _eventsMapping;

	/* MarketItem */
	mapping(bytes16 => MarketItem) private _marketItemMapping;

	event CloseBetsHead(
		bytes16 hashEvent,
		bytes16 hashMarketItem,
		bytes16 hashOutcome
	);

	event CreateBet(
		bytes16 hashEvent,
		bytes16 hashMarketItem,
		bytes16 hashBet
	);

	event CloseBet(bytes16 hashBet, bool status);

	event CancelBet(address user, bytes16 bet);  

	/**
	* @dev Function for create event with MarketItem.
	*/
	function 	createEvent(
		bytes16 hashEvent,
		bytes16[] arrayHashMarketItem,
		bytes16[] arrayHashOutcome,
		uint[] arraySize
	)
		onlyModerator()
		sizeArrayCompare(arrayHashOutcome.length, arraySize)
		notEmptyArrayBytes16(arrayHashMarketItem)
		notEmptyArrayBytes16(arrayHashOutcome)
		notEmptyArrayUint(arraySize)
		public
	{
		require(hashEvent != bytes16(0x0));
		require(_eventsMapping[hashEvent].hashMarketItem.length == 0); // Protection against reuse
		for (uint i = 0; i < arrayHashMarketItem.length; i++) {
			require(_marketItemMapping[arrayHashMarketItem[i]].hashEventParent == bytes16(0x0)); // Protection against reuse
		}

		Event memory currentEvent = Event(arrayHashMarketItem, false, false);
		_eventsMapping[hashEvent] = currentEvent;
		createMarketItem(hashEvent, arrayHashMarketItem, arrayHashOutcome, arraySize);
	}

	function 	addMarketItem(
		bytes16 hashEvent,
		bytes16 hashMarketItem,
		bytes16[] arrayHashOutcome
	)
		onlyModerator()
		notCloseEvent(hashEvent)
		notEmptyArrayBytes16(_eventsMapping[hashEvent].hashMarketItem)
		public
	{
		require(hashEvent != bytes16(0x0) && hashMarketItem != bytes16(0x0));
		if (_marketItemMapping[hashMarketItem].hashEventParent == bytes16(0x0)) {
			_eventsMapping[hashEvent].hashMarketItem.push(hashMarketItem);
			_marketItemMapping[hashMarketItem].hashEventParent = hashEvent;
		}
		for (uint i = 0; i < arrayHashOutcome.length; i++) {
			require(_outcomeMapping[arrayHashOutcome[i]].hashMarketItem == bytes16(0x0)); // Protection against reuse outcome
			require(arrayHashOutcome[i] != bytes16(0x0));

			_marketItemMapping[hashMarketItem].outcomes.push(arrayHashOutcome[i]);
			_outcomeMapping[arrayHashOutcome[i]].hashMarketItem = hashMarketItem;
		}
	}

	/**
	* @dev Function for create Bet, across deposit in smart-contract.
	* Availabe for players.
	*/
	function 	createBetAcrossDeposit(
		bytes16 hashEvent,
		bytes16 hashMarketItem,
		bytes16 hashOutcome,
		bytes16 hashBet,
		uint amountBet,
		uint coef
	)
		public
	{
		require(_balanceOf[msg.sender] >= amountBet);

		_balanceOf[msg.sender] = _balanceOf[msg.sender].sub(amountBet);
		createBet(hashEvent, hashMarketItem, hashOutcome, hashBet, amountBet, coef);
	}

	/**
	*	@dev Function for cancel Bet, availabe for players.
	* 	mvp cancelBet
	*/
	function 	cancelBet(
		bytes16 hashBet
	)
		public
		notZero(_betsMapping[hashBet].amountBet)
	{
		require(hashBet != bytes16(0x0));
		require(_betsMapping[hashBet].end == true && _betsMapping[hashBet].verified == false);
		require(msg.sender == _betsMapping[hashBet].user);

		uint amount = _betsMapping[hashBet].amountBet;
		_betsMapping[hashBet].amountBet = 0;
		_balanceOf[_betsMapping[hashBet].user] = _balanceOf[_betsMapping[hashBet].user].add(amount);
		emit CancelBet(msg.sender, hashBet);
	}

	/**
	* @dev Function for accept Bet. Availabe for Admin and moderators.
	*/
	function 	acceptBet(
		bytes16 hashEvent,
		bytes16 hashMarketItem,
		bytes16 hashBet,
		bool status
	)
		onlyModerator()
		notCloseEvent(hashEvent)
		public
	{
		require(hashEvent != bytes16(0x0));
		require(_outcomeMapping[_betsMapping[hashBet].outcome].hashMarketItem == hashMarketItem); // проверка что весы относятся к той ставке.
		require(_betsMapping[hashBet].verified == false && _betsMapping[hashBet].end == false); // проверка что ставка не проверялась еще

		bytes16 outcome = _betsMapping[hashBet].outcome;
		if (status) {
			_outcomeMapping[outcome].bet.push(hashBet);
			_betsMapping[hashBet].verified = true;
		}
		else {
			_betsMapping[hashBet].end = true;
		}
	}

	function 	recordingResultsOfBet(
		bytes16 hashEvent,
		bytes16[] hashMarketItem,
		uint8[] numberWinOutcome
	)
		onlyModerator()
		notCloseEvent(hashEvent)
		notEmptyArrayBytes16(_eventsMapping[hashEvent].hashMarketItem)
		public
	{
		require(hashMarketItem.length == numberWinOutcome.length);
		require(hashEvent != bytes16(0x0));

		for (uint i = 0; i < hashMarketItem.length; i++) {
			require(_marketItemMapping[hashMarketItem[i]].hashEventParent == hashEvent); // проверка что хеш весов есть в данном евенте
			require(_marketItemMapping[hashMarketItem[i]].outcomes.length >= numberWinOutcome[i]); // protected overflow
			_marketItemMapping[hashMarketItem[i]].numberWinOutcome = numberWinOutcome[i];
		}
		_eventsMapping[hashEvent].closeSuccess = true;
		_eventsMapping[hashEvent].closed = true;
	}

	function 	cancelEvent(
		bytes16 hashEvent
	)
		public
		onlyModerator()
	{
		require(hashEvent != bytes16(0x0));

		if (_eventsMapping[hashEvent].closeSuccess == true) {
			_eventsMapping[hashEvent].closeSuccess = false;
		}
		if (_eventsMapping[hashEvent].closed == false) {
			_eventsMapping[hashEvent].closed = true;
		}
	}

	function 	closeBetsIfEventNotSuccess(
		bytes16 hashEvent,
		bytes16 hashMarketItem,
		uint numberOutcome,
		uint quantityBets
	)
		public
		onlyModerator()
	{
		require(hashEvent != bytes16(0x0) && hashMarketItem != bytes16(0x0));
		require(_eventsMapping[hashEvent].closeSuccess == false);
		require(_eventsMapping[hashEvent].closed == true);
		require(numberOutcome <= _marketItemMapping[hashMarketItem].outcomes.length);

		uint amount;
		bytes16 hashBet;
		address user;
		bytes16 hashOutcome = _marketItemMapping[hashMarketItem].outcomes[numberOutcome];

		require(quantityBets.add(_outcomeMapping[hashOutcome].amountCloseBet) <= _outcomeMapping[hashOutcome].bet.length);
		uint i = _outcomeMapping[hashOutcome].amountCloseBet;
		for (uint j = 0; j < quantityBets; j++) {
			hashBet = _outcomeMapping[hashOutcome].bet[i];
			user = _betsMapping[hashBet].user;
			_betsMapping[hashBet].end = true;
			amount = _betsMapping[hashBet].amountBet;
			_betsMapping[hashBet].amountBet = 0;
			_balanceOf[user] = _balanceOf[user].add(amount);
			emit CloseBet(hashBet, false);
			i += 1;
		}
		_outcomeMapping[hashOutcome].amountCloseBet = i;
		emit CloseBetsHead(hashEvent, hashMarketItem, hashOutcome);
	}

	function 	closeBets(
		bytes16 hashEvent,
		bytes16 hashMarketItem,
		uint 	numberOutcome,
		uint 	quantityBets
	)
		onlyModerator()
		parentMarketItem(hashEvent, hashMarketItem)
		notZero(quantityBets)
		public
	{
		require(hashEvent != bytes16(0x0) && hashMarketItem != bytes16(0x0));
		require(numberOutcome <= _marketItemMapping[hashMarketItem].outcomes.length);
		require(_eventsMapping[hashEvent].closeSuccess == true);
		require(_eventsMapping[hashEvent].closed == true);

		uint amount;
		bytes16 hashBet;
		bytes16 hashOutcome = _marketItemMapping[hashMarketItem].outcomes[numberOutcome];

		require(quantityBets.add(_outcomeMapping[hashOutcome].amountCloseBet) <= _outcomeMapping[hashOutcome].bet.length);
		uint i = _outcomeMapping[hashOutcome].amountCloseBet;
		for (uint j = 0; j < quantityBets; j++) {
			hashBet = _outcomeMapping[hashOutcome].bet[i];
			_betsMapping[hashBet].end = true;
			if (_betsMapping[hashBet].outcome == getWinOutcome(hashMarketItem)) {
				amount = _betsMapping[hashBet].amountBetReward;
				_betsMapping[hashBet].amountBetReward = 0;
				_balanceOf[_liquidatePool] = _balanceOf[_liquidatePool].sub(amount);
				_balanceOf[_betsMapping[hashBet].user] = _balanceOf[_betsMapping[hashBet].user].add(amount);
				emit CloseBet(hashBet, true);
			}
			else {
				amount = _betsMapping[hashBet].amountBet;
				_betsMapping[hashBet].amountBet = 0;
				_balanceOf[_liquidatePool] = _balanceOf[_liquidatePool].add(amount);
				emit CloseBet(hashBet, false);
			}
			i += 1;
		}
		_outcomeMapping[hashOutcome].amountCloseBet = i;
		emit CloseBetsHead(hashEvent, hashMarketItem, hashOutcome);
	}

	/* Getter */

	function 	getInfoMarketItem(
		bytes16 hashMarketItem
	)
		view
		public
		returns(bytes16[], uint8)
	{
		return (
			_marketItemMapping[hashMarketItem].outcomes,
			_marketItemMapping[hashMarketItem].numberWinOutcome
		);
	}

	function getWinOutcome(
		bytes16 hashMarketItem
	)
		public
		constant
		returns(bytes16)
	{
		require(_marketItemMapping[hashMarketItem].outcomes.length != 0);
		return (_marketItemMapping[hashMarketItem].outcomes[_marketItemMapping[hashMarketItem].numberWinOutcome]);
	}

	function 	getArrayHashMarketItem(bytes16 hashEvent) view public returns(bytes16[]) {
		return _eventsMapping[hashEvent].hashMarketItem;
	}

	/* 
	* @param coef - (3==0.03)(30==0.3)(300==3)(255==2.55)
	*/
	function 	createBet(
		bytes16 hashEvent,
		bytes16 hashMarketItem,
		bytes16 hashOutcome,
		bytes16 hashBet,
		uint amountBet,
		uint coef
	)
		notCloseEvent(hashEvent)
		parentMarketItem(hashEvent, hashMarketItem)
		notZero(amountBet)
		notZero(coef)
		notEmptyArrayBytes16(_eventsMapping[hashEvent].hashMarketItem)
		notEmptyArrayBytes16(_marketItemMapping[hashMarketItem].outcomes)
		internal
	{
		require(hashBet != bytes16(0x0));
		require(_outcomeMapping[hashOutcome].hashMarketItem == hashMarketItem); // существует ли условие в данных весах
		require(_betsMapping[hashBet].user == address(0x0)); // не занят ли данный хеш ставки
		require(amountBet >= MIN_ETHER_BET);

		/* 100 потому что нужно добавить два нуля, 2 потому что количество цифр после запятой */
		uint amountBetReward = multiply(amountBet * 100, coef, 2);
		Bet memory bet = Bet(
			msg.sender,
			amountBet,
			amountBetReward,
			coef,
			hashOutcome,
			false,
			false
		);
		_betsMapping[hashBet] = bet;
		emit CreateBet(hashEvent, hashMarketItem, hashBet);
	}

	function 	createMarketItem(
		bytes16 hashEvent,
		bytes16[] arrayHashMarketItem,
		bytes16[] arrayHashOutcome,
		uint[] arraySize
	)
		internal
	{
		uint elem = 0;
		for (uint j = 0; j < arraySize.length; j++) {
			require(arrayHashMarketItem[j] != bytes16(0x0));
			_marketItemMapping[arrayHashMarketItem[j]].hashEventParent = hashEvent;
			for (uint i = 0; i < arraySize[j]; i++) {
				require(_outcomeMapping[arrayHashOutcome[elem]].hashMarketItem == bytes16(0x0));
				require(arrayHashOutcome[elem] != bytes16(0x0));
				_marketItemMapping[arrayHashMarketItem[j]].outcomes.push(arrayHashOutcome[elem]);
				_outcomeMapping[arrayHashOutcome[elem]].hashMarketItem = arrayHashMarketItem[j];
				elem += 1;
			}
		}
	}

	/** Modifiers */

	modifier 	sizeArrayCompare(uint len, uint[] arraySize) {
		uint size = 0;
		for (uint i = 0; i < arraySize.length; i++) {
			size += arraySize[i];
		}
		require (size == len);
		_;
	}

	modifier notCloseEvent(bytes16 hash) {
		require(_eventsMapping[hash].closed == false);
		_;
	}

	modifier notEmptyArrayBytes16(bytes16[] array) {
		require(array.length != 0);
		_;
	}

	modifier notEmptyArrayUint(uint[] array) {
		require(array.length != 0);
		_;
	}

	modifier 	deadline(uint time) {
		require (now >= time);
		_;
	}

	modifier 	notZeroBytes16(bytes16 h) {
		require(h != bytes16(0x0));
		_;
	}

	modifier parentMarketItem(bytes16 hashEvent, bytes16 hashMarketItem) {
		require (_marketItemMapping[hashMarketItem].hashEventParent == hashEvent);
		_;
	}
}