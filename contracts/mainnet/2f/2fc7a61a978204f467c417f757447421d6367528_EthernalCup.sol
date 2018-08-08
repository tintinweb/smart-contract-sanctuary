pragma solidity 0.4.23;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
  	require(msg.sender != address(0));

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}


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
	// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract EthernalCup is Ownable {
	using SafeMath for uint256;


	/// Buy is emitted when a national team is bought
	event Buy(
		address owner,
		uint country,
		uint price
	);

	event BuyCup(
		address owner,
		uint price
	);

	uint public constant LOCK_START = 1531663200; // 2018/07/15 2:00pm (UTC)
	uint public constant LOCK_END = 1500145200; // 2018/07/15 19:00pm (UTC)
	uint public constant TOURNAMENT_ENDS = 1531677600; // 2018/07/15 18:00pm (UTC)

	int public constant BUY_INCREASE = 20;

	uint startPrice = 0.1 ether;

	// The way the purchase occurs, the purchase will pay 20% more of the current price
	// so the actual price is 30 ether
	uint cupStartPrice = 25 ether;

	uint public constant DEV_FEE = 3;
	uint public constant POOL_FEE = 5;

	bool public paused = false;

	// 0 "Russia"
	// 1 "Saudi Arabia
	// 2 "Egypt"
	// 3 "Uruguay"
	// 4 "Morocco"
	// 5 "Iran"
	// 6 "Portugal"
	// 7 "Spain"
	// 8 "France"
	// 9 "Australia"
	// 10 "Peru"
	// 11 "Denmark"
	// 12 "Argentina"
	// 13 "Iceland"
	// 14 "Croatia"
	// 15 "Nigeria"
	// 16 "Costa Rica
	// 17 "Serbia"
	// 18 "Brazil"
	// 19 "Switzerland"
	// 20 "Germany"
	// 21 "Mexico"
	// 22 "Sweden"
	// 23 "Korea Republic
	// 24 "Belgium"
	// 25 "Panama"
	// 26 "Tunisia"
	// 27 "England"
	// 28 "Poland"
	// 29 "Senegal"
	// 30 "Colombia"
	// 31 "Japan"

	struct Country {
		address owner;
		uint8 id;
		uint price;
	}

	struct EthCup {
		address owner;
		uint price;
	}

	EthCup public cup;

	mapping (address => uint) public balances;
	mapping (uint8 => Country) public countries;

	/// withdrawWallet is the fixed destination of funds to withdraw. It might
	/// differ from owner address to allow for a cold storage address.
	address public withdrawWallet;

	function () public payable {

		balances[withdrawWallet] += msg.value;
	}

	constructor() public {
		require(msg.sender != address(0));

		withdrawWallet = msg.sender;
	}

	modifier unlocked() {
		require(getTime() < LOCK_START || getTime() > LOCK_END);
		_;
	}

	/**
   	* @dev Throws if game is not paused
   	*/
	modifier isPaused() {
		require(paused == true);
		_;
	}

	/**
   	* @dev Throws if game is paused
   	*/
	modifier buyAvailable() {
		require(paused == false);
		_;
	}

	/**
   	* @dev Throws if game is paused
   	*/
	modifier cupAvailable() {
		require(cup.owner != address(0));
		_;
	}

	function addCountries() external onlyOwner {

		for(uint8 i = 0; i < 32; i++) {
			countries[i] = Country(withdrawWallet, i, startPrice);
		}			
	}

	/// @dev Set address withdaw wallet
	/// @param _address The address where the balance will be withdrawn
	function setWithdrawWallet(address _address) external onlyOwner {

		uint balance = balances[withdrawWallet];

		balances[withdrawWallet] = 0; // Set to zero previous address balance

		withdrawWallet = _address;

		// Add the previous balance to the new address
		balances[withdrawWallet] = balance;
	}


	///	Buy a country
	///	@param id - The country id
	function buy(uint8 id) external payable buyAvailable unlocked {

		require(id < 32);
		
		uint price = getPrice(countries[id].price);

		require(msg.value > startPrice);
		require(msg.value >= price);

		uint fee = msg.value.mul(DEV_FEE).div(100);

		// Add sell price minus fees to previous country owner
		balances[countries[id].owner] += msg.value.sub(fee);
	

		// Add fee to developers balance
		balances[withdrawWallet] += fee;

		// Set new owner, with new message
		countries[id].owner = msg.sender;
		countries[id].price = msg.value;

		// Trigger buy event
		emit Buy(msg.sender, id, msg.value);

	}

	///	Buy the cup from previous owner
	function buyCup() external payable buyAvailable cupAvailable {

		uint price = getPrice(cup.price);

		require(msg.value >= price);

		uint fee = msg.value.mul(DEV_FEE).div(100);

		// Add sell price minus fees to previous cup owner
		balances[cup.owner] += msg.value.sub(fee);
	
		// Add fee to developers balance
		balances[withdrawWallet] += fee;

		// Set new owner, with new message
		cup.owner = msg.sender;
		cup.price = msg.value;

		// Trigger buy event
		emit BuyCup(msg.sender, msg.value);

	}

	/// Get new price
	function getPrice(uint price) public pure returns (uint) {

		return uint(int(price) + ((int(price) * BUY_INCREASE) / 100));
	}


	/// Withdraw the user balance in the contract to the user address.
	function withdraw() external returns (bool) {

		uint amount = balances[msg.sender];

		require(amount > 0);

		balances[msg.sender] = 0;

		if(!msg.sender.send(amount)) {
			balances[msg.sender] = amount;

			return false;
		}

		return true;
	}

	/// Get user balance
	function getBalance() external view returns(uint) {
		return balances[msg.sender];
	}

	/// Get user balance by address
	function getBalanceByAddress(address user) external view onlyOwner returns(uint) {
		return balances[user];
	}

	/// @notice Get a country by its id
	/// @param id The country id
	function getCountryById(uint8 id) external view returns (address, uint, uint) {
		return (
			countries[id].owner,
			countries[id].id,
			countries[id].price
		);
	}

	/// Pause the game preventing any buys
	/// This will only be done to award the cup
	/// The game will automatically stops purchases during
	/// the tournament final
	function pause() external onlyOwner {

		require(paused == false);

		paused = true;
	}

	/// Resume all trading
	function resume() external onlyOwner {

		require(paused == true);

		paused = false;
	}

	/// Award cup to the tournament champion
	/// Can only be awarded once, and only if the tournament has finished
	function awardCup(uint8 id) external onlyOwner isPaused {

		address owner = countries[id].owner;

		require(getTime() > TOURNAMENT_ENDS);
		require(cup.owner == address(0));
		require(cup.price == 0);
		require(owner != address(0));

		cup = EthCup(owner, cupStartPrice);

	}

	function getTime() public view returns (uint) {
		return now;
	}

}