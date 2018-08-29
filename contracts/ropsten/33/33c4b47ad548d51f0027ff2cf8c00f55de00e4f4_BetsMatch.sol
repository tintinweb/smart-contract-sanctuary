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
	
	function power(uint256 a, uint256 b) internal pure returns (uint256 res){ 
		res = 1;
		for (uint i = 0; i < b; i++) {
			res = res * a;
		}
	}

	function multiply(uint a, uint b, uint decimals) internal pure returns(uint){
		return ((a * b) / power(10, (decimals**2)));
	}
}


/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/

contract Ownable {
	address public _owner;

	// event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	/**
	* @dev The Ownable constructor sets the original `owner` of the contract to the sender
	* account.
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
	// for testing don&#39;t need
	// function transferOwnership(address newOwner) public onlyOwner {
	// 	require(newOwner != _owner);
	// 	_transferOwnership(newOwner);
	// }

	/**
	* @dev Transfers control of the contract to a newOwner.
	* @param newOwner The address to transfer ownership to.
	*/
	// for testing don&#39;t need
	// function _transferOwnership(address newOwner) internal {
	// 	require(newOwner != address(0));
	// 	emit OwnershipTransferred(_owner, newOwner);
	// 	_owner = newOwner;
	// }
}

// contract 	Admins is Ownable {
	
// 	mapping(address => bool) internal _moderators;
	
// 	// address public _prevSmartContract;

// 	// address public _nextSmartContract;

// 	// string 	public _version;

// 	// for test
// 	address private _prevSmartContract;

// 	address private _nextSmartContract;

// 	string 	private _version; 

// 	/**
// 	* @dev Construct.
// 	*/
// 	constructor() public {
// 		_prevSmartContract = address(0x0);
// 		_nextSmartContract = address(0x0);
// 		_version = "0.01";
// 		_moderators[msg.sender] = true;
// 	}

// 	function	changeStatusModerator(
// 		address user,
// 		bool status
// 	)
// 		public
// 		notNullAddress(user)
// 		onlyOwner()
// 	{
// 		_moderators[user] = status;
// 	}
	
// 	function 	setNextSmartContract(
// 		address smartContract
// 	)
// 		public
// 		notNullAddress(smartContract)
// 		onlyOwner()
// 	{
// 		_nextSmartContract = smartContract;
// 	}

// 	/**
// 	* @dev Throws if called by any account other than the moderator.
// 	*/
// 	modifier onlyModerator() {
// 		require(_moderators[msg.sender] == true);
// 		_;
// 	}

// 	/**
// 	* @dev Throws if called by null account
// 	* @param user The address to check at zero address
// 	*/
// 	modifier notNullAddress(address user) {
// 		require(user != address(0x0));
// 		_;
// 	}

// 	/**
// 	* 	gets methods
// 	*	@param user The address to get status user
// 	*/
// 	function 	getStatusModerator(address user) public constant returns (bool) {
// 		return 	(_moderators[user]);
// 	}
// }

contract Balance is Ownable{
	using SafeMath for uint;

	mapping(address => uint) public _balanceOf;

	address public _liquidatePool;
	
	event DepositEth(address user, uint amountDeposit, uint balanceNow);

	event WithdrawEthForUser(address user, uint amountWithdraw, uint balanceNow);

	event WithdrawLiquidatePool(
		address owner,
		uint amountWithdraw,
		uint balanceLiquidatePool
	);

	event DepositLiquidatePool(
		address user,
		uint amountDeposit,
		uint balanceLiquidatePool
	);

	constructor(/*address liquidatePool*/) public {
		/*require(liquidatePool != address(0x0));*/
		_liquidatePool = msg.sender; // for testing
	}

	// function 	depositEth() notZero(msg.value) payable public {
	// 	require(msg.sender != _liquidatePool);

	// 	_balanceOf[msg.sender] = _balanceOf[msg.sender].add(msg.value);
	// 	emit DepositEth(msg.sender, msg.value, _balanceOf[msg.sender]);
	// }

	/* 
	** Функционал вывода денег для пользователей. 
	*/
	// function 	withdrawEthForUser(uint amountWithdraw) notZero(amountWithdraw) public {
	// 	require(msg.sender != _liquidatePool);

	// 	_balanceOf[msg.sender] = _balanceOf[msg.sender].sub(amountWithdraw);
	// 	msg.sender.transfer(amountWithdraw);
	// 	emit WithdrawEthForUser(msg.sender, amountWithdraw, _balanceOf[msg.sender]);
	// }

	/*
	** С любого адресса можно пополнять депозит ликвидити пула.
	*/
	// function 	depositLiquidateThePool() notZero(msg.value) payable public {
	// 	_balanceOf[_liquidatePool] = _balanceOf[_liquidatePool].add(msg.value);
	// 	emit DepositLiquidatePool(msg.sender, msg.value, _balanceOf[_liquidatePool]);
	// }

	/* 
	** Тоже самое что и withdrawEth только можно модифицировать под нужни админа,
	** не затрагивая функционал для пользователей
	*/
	// function 	withdrawLiquidatePool(
	// 	uint amountWithdraw
	// )
	// 	notZero(amountWithdraw)
	// 	onlyOwner()
	// 	public
	// {
	// 	_balanceOf[_liquidatePool] = _balanceOf[_liquidatePool].sub(amountWithdraw);
	// 	msg.sender.transfer(amountWithdraw);
	// 	emit WithdrawLiquidatePool(
	// 		msg.sender,
	// 		amountWithdraw,
	// 		_balanceOf[_liquidatePool]
	// 	);
	// }

	modifier 	notZero(uint amount) { 
		require(amount != 0);
		_;
	}
}

contract BetsMatch is Ownable, Balance, Math {
	using SafeMath for uint;

	uint public constant MIN_ETHER_BET = (1 ether / 100);

	struct Event {
		bytes32[] hashLibra;
		bool closed;
	}

	struct Libra {
		bytes16[] conditions;
		uint8 numberWinCondition;
	}
	
	struct Bet {
		address user;
		uint amountBet;
		uint amountBetReward;
		uint coef;
		bytes16 condition;
		bool verified;
		bool end;
	}

	/* For bets */
	mapping(bytes32 => Bet) public _bets;
	
	/* For Condition */
	mapping(bytes16 => mapping(uint => bytes32)) public _betOfCondition;

	mapping(bytes16 => bytes32) public _parentOfCondtion;

	mapping(bytes16 => uint) public _sizeCondition;

	mapping(bytes16 => uint) public _amountCloseBetInCondtion;
	
	/* Event */
	mapping(bytes32 => Event) private _events;

	/* Libra */
	mapping(bytes32 => Libra) private _libra;
	
	event CreateEvent(
		bytes32 hashEvent,
		bytes32[] arrayHashLibra,
		bytes16[] arrayHashConditions,
		uint[] arraySize
	);

	event CreateBet(
		bytes32 hashEvent,
		bytes32 hashLibra,
		bytes16 hashCondition,
		bytes32 hashBet,
		address user,
		uint amountBet,
		uint coef
	);

	event AcceptBet(
		bytes32 hashEvent,
		bytes32 hashLibra,
		bytes32 hashBet,
		bool status
	);

    event CancelBet(address user, bytes32 bet);
	
/*
	constructor() public {
		// some code
	}

	function () public payable { 
		revert();
	}
*/
	/**
	* @dev Function for create event with Libra.
	*/
	function 	createEvent(
		bytes32 hashEvent,
		bytes32[] arrayHashLibra,
		bytes16[] arrayHashConditions,
		uint[] arraySize	
	)
		onlyOwner() // onlyModerator()
		sizeArrayCompare(arrayHashConditions.length, arraySize)
		public
	{
		require(_events[hashEvent].hashLibra.length == 0); // Protection against reuse
		for (uint i = 0; i < arrayHashLibra.length; i++) {
			require(_libra[arrayHashLibra[i]].conditions.length == 0); // Protection against reuse
		}

		Event memory currentEvent = Event(arrayHashLibra,false);
		_events[hashEvent] = currentEvent;
		createLibra(arrayHashLibra, arrayHashConditions, arraySize);
		emit CreateEvent(hashEvent, arrayHashLibra, arrayHashConditions, arraySize);
	}

	/**
	* @dev Function for create Bet, with payable.
	* Availabe for players. 
	*/
	function 	createBetWithPayable(
		bytes32 hashEvent,
		bytes32 hashLibra,
		bytes16 hashCondition,
		bytes32 hashBet,
		uint coef
	)
		public
		payable
	{
		createBet(hashEvent, hashLibra, hashCondition, hashBet, msg.value, coef);
	}

// 	/**
// 	* @dev Function for create Bet, across deposit in smart-contract.
// 	* Availabe for players.
// 	*/
	// function 	createBetAcrossDeposit(
	// 	bytes32 hashEvent,
	// 	bytes32 hashLibra,
	// 	bytes16 hashCondition,
	// 	uint amountBet,
	// 	uint coef
	// )
	// 	public
	// {
	// 	require(_balanceOf[msg.sender] >= amountBet);

	// 	_balanceOf[msg.sender] = _balanceOf[msg.sender].sub(amountBet);
	// 	createBet(hashEvent, hashLibra, hashCondition, amountBet, coef);
	// }

	/**
	*	@dev Function for cancel Bet, availabe for players.
	* 	mvp cancelBet
	*/
	function 	cancelBet(bytes32 hashBet) public {
		require(_bets[hashBet].end == true && _bets[hashBet].verified == false);
		require(_bets[hashBet].amountBet > 0);

		uint amount = _bets[hashBet].amountBet;
		_bets[hashBet].amountBet = 0;
		_bets[hashBet].user.transfer(amount);
		emit CancelBet(msg.sender, hashBet);
	}

	/**
	* @dev Function for accept Bet. Availabe for Admin and moderators.
	*/
	function 	acceptBet(
		bytes32 hashEvent,
		bytes32 hashLibra,
		bytes32 hashBet,
		bool status
	)
		onlyOwner() // onlyModerator()
		notCloseEvent(hashEvent)
		public
	{
		require(_parentOfCondtion[_bets[hashBet].condition] == hashLibra); // проверка что весы относятся к той ставке.
		require(_bets[hashBet].verified == false && _bets[hashBet].end == false);

		bytes16 condition = _bets[hashBet].condition;
		if (status) {
			_betOfCondition[condition][_sizeCondition[condition]] = hashBet;
			_bets[hashBet].verified = true;
			_sizeCondition[condition] += 1;
		}
		else {
			_bets[hashBet].end = true;
		}
		emit AcceptBet(hashEvent, hashLibra, hashBet, status);
	}

	function 	recordingResultsOfBet(
		bytes32 hashEvent,
		bytes32[] hashLibra,
		uint8[] numberWinCondition
	)
		onlyOwner() // onlyModerator()
		notCloseEvent(hashEvent)
		public
	{
		require(hashLibra.length == numberWinCondition.length);
		require(_events[hashEvent].hashLibra.length > 0);
		
		for (uint i = 0; i < hashLibra.length; i++) {
			require(_libra[hashLibra[i]].conditions.length >= numberWinCondition[i]); // protected overflow
			_libra[hashLibra[i]].numberWinCondition = numberWinCondition[i];
		}
		closeEvent(hashEvent);
	}

	function 	closeBets(
		bytes32 hashEvent,
		bytes32 hashLibra,
		uint 	numberCondition,
		uint 	quantityBets
	)
		onlyOwner() // onlyModerator
		public
	{
		require(_events[hashEvent].closed == true);
		require(numberCondition <= _libra[hashLibra].conditions.length);

		uint amount;
		bytes32 hashBet;
		bytes16 hashCondition = _libra[hashLibra].conditions[numberCondition];
		uint i = _amountCloseBetInCondtion[hashCondition];
		uint j = 0;
		while (j < quantityBets) {
		    if (_betOfCondition[hashCondition][i] == bytes32(0)) {
		        break ;
		    }
			hashBet = _betOfCondition[hashCondition][i];
			_bets[hashBet].end = true;
			if (_bets[hashBet].condition == getWinConditionInLibra(hashLibra)) {
				amount = _bets[hashBet].amountBetReward;
				_bets[hashBet].amountBetReward = 0;
				_balanceOf[_liquidatePool] = _balanceOf[_liquidatePool].sub(amount);
				_balanceOf[_bets[hashBet].user] = _balanceOf[_bets[hashBet].user].add(amount);
			}
			else {
				amount = _bets[hashBet].amountBet;
				_bets[hashBet].amountBet = 0;
				_balanceOf[_liquidatePool] = _balanceOf[_liquidatePool].add(amount);
			}
			i += 1;
			j += 1;
		}
		_amountCloseBetInCondtion[hashCondition] = i;
	}


	function 	createLibra(
		bytes32[] arrayHashLibra,
		bytes16[] arrayHashConditions,
		uint[] arraySize
	)
		internal
	{
		uint elem = 0;
		for (uint j = 0; j < arraySize.length; j++) {
			for (uint i = 0; i < arraySize[j]; i++) {
				_libra[arrayHashLibra[j]].conditions.push(arrayHashConditions[elem]);
				require(_parentOfCondtion[arrayHashConditions[elem]] == bytes32(0x0)); // Protection against reuse
				_parentOfCondtion[arrayHashConditions[elem]] = arrayHashLibra[j]; // To reduce the cost of Tx in createBet for user.
				elem += 1;
			}
		}
	}

	/* Getter */

	function 	getInfoLibra(
		bytes32 hashLibra
	)
		view
		public
		returns(bytes16[], uint8)
	{
		return (
			_libra[hashLibra].conditions,
			_libra[hashLibra].numberWinCondition
		);
	}

	function getWinConditionInLibra(
		bytes32 hashLibra
	)
		public
		constant
		returns(bytes16)
	{
		return (_libra[hashLibra].conditions[_libra[hashLibra].numberWinCondition]);
	}

	function 	getArrayHashLibry(bytes32 hashEvent) view public returns(bytes32[]) {
		return _events[hashEvent].hashLibra;
	}

	function 	transferReward(uint amount, address user) internal notZero(amount) {
		user.transfer(amount);
	}

	function 	closeEvent(bytes32 hashEvent) internal {
		require(_events[hashEvent].closed == false);

		_events[hashEvent].closed = true;
	}

	function 	createBet(
		bytes32 hashEvent,
		bytes32 hashLibra,
		bytes16 hashCondition,
		bytes32 hashBet,
		uint amountBet,
		uint coef // 3 == 0.03; 30 == 0.3; 300; == 3;
	)
		notCloseEvent(hashEvent)
		notZero(amountBet)
		notZero(coef)
		internal
	{
		require(_events[hashEvent].hashLibra.length != 0); // если весов нету значет евента нету
		require(_libra[hashLibra].conditions.length != 0); // существует ли весы
		require(_parentOfCondtion[hashCondition] == hashLibra); // существует ли условие в данных весах
		require(_bets[hashBet].user == address(0x0)); // не занят ли данный хеш ставки
		require(amountBet >= MIN_ETHER_BET);

		// 100 потому что нужно добавить два нуля, 2 потому что количество цифр после запятой
		uint amountBetReward = multiply(amountBet * 100, coef, 2);
		Bet memory bet = Bet(
			msg.sender,
			amountBet,
			amountBetReward,
			coef,
			hashCondition,
			false,
			false
		);
		_bets[hashBet] = bet;
		emit CreateBet(
			hashEvent,
			hashLibra,
			hashCondition,
			hashBet,
			msg.sender,
			amountBet,
			coef
		);
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

	modifier notCloseEvent(bytes32 hash) { 
		require(_events[hash].closed == false);
		_; 
	}

	modifier 	deadline(uint time) { 
		require (now >= time); 
		_;
	}
}