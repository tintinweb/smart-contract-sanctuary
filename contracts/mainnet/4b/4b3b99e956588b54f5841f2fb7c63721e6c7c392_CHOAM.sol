pragma solidity ^0.4.24;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
}

// File: contracts/CHOAM.sol

contract CHOAM is Ownable
{
	using SafeMath for uint256;

	uint256 public constant PLANET_PRICE = 	100000000000000000;
	uint256 public constant FEE_RANGE = 		29000000000000000;
	uint256 public constant FEE_MIN = 			5000000000000000;
	uint256 public constant FEE_SILO =			10000000000000000;
	uint256 public constant TIMER_STEP = 		120;

	uint256 public constant PAGE_SIZE = 25;

	address public master;

	bool public inited = false;

	uint256 public koef = 1;

	bool private create_flag = false;

	uint256 public silo;

	address public silo_addr = address(0);

	uint256 public silo_timer = now;

	struct Player
	{
		uint256 balance;
		uint256 position;
		uint8 state;
		uint256 discount;
		uint256[] planets;
	}

	mapping(address => Player) players;

	struct Planet
	{
		uint256 fee;
		bytes32 data;
		address owner;
	}

	struct Node
	{
		Planet planet;
		uint256 prev;
		uint256 next;
	}

	Node[] public nodes;


	constructor() public
	{
		master = msg.sender;
	}


	function init() public onlyOwner
	{
		if(!inited)
		{
			create_planet();
			create_planet();
			create_planet();
			create_planet();
			create_planet();
			create_planet();
			create_planet();
			create_planet();
			create_planet();
			create_planet();
			create_planet();
			create_planet();

			inited = true;
		}
	}


	function() public payable
	{
		buy_spice_melange();
	}


	function get_owner_planets(uint256 page) external view returns (uint256[] fees, bytes32[] datas, uint256[] ids, uint256[] order)
	{
		require(msg.sender != address(0));

		fees = new uint256[](PAGE_SIZE);
		datas = new bytes32[](PAGE_SIZE);
		ids = new uint256[](PAGE_SIZE);
		order = new uint256[](PAGE_SIZE);

		uint256 start = page.mul(PAGE_SIZE);

		for(uint8 i = 0; i < PAGE_SIZE; i++)
		{
			if(i + start < players[msg.sender].planets.length)
			{
				uint256 tmp = players[msg.sender].planets[i + start];
				fees[i] = nodes[tmp].planet.fee.div(koef);
				datas[i] = nodes[tmp].planet.data;
				ids[i] = tmp;
				order[i] = i + start;
			}
		}
	}


	function set_master(address adr) public onlyOwner
	{
		require(adr != address(0));
		require(msg.sender != address(this));

		master = adr;
	}


	function set_koef(uint256 _koef) public onlyOwner
	{
		require(_koef > 0);

		koef = _koef;
	}


	function get_planet_price() public view returns (uint256)
	{
		return PLANET_PRICE.div(koef).add(FEE_SILO.div(koef));
	}


	function get_planet_info(uint id) external view returns (uint256 fee, bytes32 data, address owner, uint256 prev, uint256 next)
	{
		fee = nodes[id].planet.fee.div(koef);
		data = nodes[id].planet.data;
		owner = nodes[id].planet.owner;
		prev = nodes[id].prev;
		next = nodes[id].next;
	}


	function get_info(uint256 id) public view returns (uint256[] fees, bytes32[] datas, address[] addresses, uint256[] infos)
	{
		fees = new uint256[](12);
		datas = new bytes32[](12);
		addresses = new address[](14);
		infos = new uint256[](14);

		uint8 i;

		for(i = 0; i < 12; i++)
		{
			if(i < nodes.length)
			{
				fees[i] = nodes[id].planet.fee.div(koef);
				datas[i] = nodes[id].planet.data;
				addresses[i] = nodes[id].planet.owner;
				infos[i] = id;

				id = nodes[id].next;
			}
		}

		addresses[i] = silo_addr;
		infos[i] = silo;
		i++;
		if(now < silo_timer)
			infos[i] = silo_timer - now;

	}


	function get_player_state() external view returns (uint256 balance, uint256 position, uint8 state, uint256 discount,
		uint256 planet_price, uint256 owned_len)
	{
		balance = players[msg.sender].balance;
		position = players[msg.sender].position;
		state = players[msg.sender].state;
		discount = players[msg.sender].discount;
		planet_price = PLANET_PRICE.div(koef);
		planet_price = planet_price.sub(planet_price.mul(discount).div(100)).add(FEE_SILO.div(koef));
		owned_len = players[msg.sender].planets.length;
	}


	function create_planet() private
	{
		bytes32 hash = keccak256(abi.encodePacked(uint256(blockhash(11)) + uint256(msg.sender) + uint256(nodes.length)));

		uint256 fee = (uint256(hash) % FEE_RANGE).add(FEE_MIN);

		uint256 id = 0;

		if(nodes.length > 0)
		{
			id = uint256(hash) % nodes.length;
		}

		insert(Planet(fee, hash, address(0)), id);
	}


	function buy_spice_melange() public payable
	{
		require(msg.sender == tx.origin);
		require(msg.sender != address(0));
		require(msg.sender != address(this));
		require(msg.value > 0);

		if(players[msg.sender].state == 0 && nodes.length > 0)
		{
			bytes32 hash = keccak256(abi.encodePacked(uint256(blockhash(11)) + uint256(msg.sender) + uint256(nodes.length)));

			players[msg.sender].position = uint256(hash) % nodes.length;

			players[msg.sender].state = 1;
		}

		players[msg.sender].balance = players[msg.sender].balance.add(msg.value);
	}


	function sell_spice_melange(uint256 amount) public returns (uint256)
	{
		require(msg.sender == tx.origin);
		require(msg.sender != address(0));
		require(msg.sender != address(this));
		require(players[msg.sender].state > 0);
		require(amount <= players[msg.sender].balance);

		if(amount > 0)
		{
			players[msg.sender].balance = players[msg.sender].balance.sub(amount);

			if(!msg.sender.send(amount))
			{
				return 0;
			}
		}
		return amount;
	}


	function move() public
	{
		require(msg.sender == tx.origin);
		require(msg.sender != address(0));
		require(msg.sender != address(this));
		require(players[msg.sender].balance > 0);
		require(players[msg.sender].state > 0);

		uint256 id = players[msg.sender].position;

		while(true)
		{
			id = nodes[id].next;

			if(nodes[id].planet.owner == address(0))
			{
				players[msg.sender].position = id;
				break;
			}
			else if(nodes[id].planet.owner == msg.sender)
			{
				players[msg.sender].position = id;
			}
			else
			{
				uint256 fee = nodes[id].planet.fee.div(koef);

				if(fee > players[msg.sender].balance)
					break;

				players[msg.sender].balance = players[msg.sender].balance.sub(fee);
				players[nodes[id].planet.owner].balance = players[nodes[id].planet.owner].balance.add(fee);

				players[msg.sender].position = id;
			}
		}
	}


	function step() public
	{
		require(msg.sender == tx.origin);
		require(msg.sender != address(0));
		require(msg.sender != address(this));
		require(players[msg.sender].balance > 0);
		require(players[msg.sender].state > 0);

		uint256 id = players[msg.sender].position;

		id = nodes[id].next;

		if(nodes[id].planet.owner == address(0))
		{
			players[msg.sender].position = id;
		}
		else if(nodes[id].planet.owner == msg.sender)
		{
			players[msg.sender].position = id;
		}
		else
		{
			uint256 fee = nodes[id].planet.fee.div(koef);
			if(fee > players[msg.sender].balance)
				return;
			players[msg.sender].balance = players[msg.sender].balance.sub(fee);
			players[nodes[id].planet.owner].balance = players[nodes[id].planet.owner].balance.add(fee);
			players[msg.sender].position = id;
		}

		return;
	}


	function buy_planet() public
	{
		require(msg.sender == tx.origin);
		require(msg.sender != address(0));
		require(msg.sender != address(this));
		require(players[msg.sender].state > 0);

		uint256 price = PLANET_PRICE.div(koef);

		price = price.sub(price.mul(players[msg.sender].discount).div(100)).add(FEE_SILO.div(koef));

		require(players[msg.sender].balance >= price);

		uint256 id = players[msg.sender].position;

		require(nodes[id].planet.owner == address(0));

		players[msg.sender].balance = players[msg.sender].balance.sub(price);

		players[msg.sender].planets.push(id);

		nodes[id].planet.owner = msg.sender;

		if(!create_flag)
		{
			create_flag = true;
		}
		else
		{
			create_planet();
			create_planet();
			create_planet();

			create_flag = false;
		}

		if(now < silo_timer)
		{
			silo_addr = msg.sender;
			silo_timer = silo_timer.add(TIMER_STEP);
			silo = silo.add(FEE_SILO);
		}
		else
		{
			if(silo > 0 && silo_addr != address(0))
				players[silo_addr].balance = players[silo_addr].balance.add(silo);

			silo_addr = msg.sender;
			silo_timer = now.add(TIMER_STEP);
			silo = FEE_SILO;

		}

		if(players[msg.sender].discount < 50)
			players[msg.sender].discount = players[msg.sender].discount.add(1);

		master.transfer(price);
	}


	function get_len() external view returns(uint256)
	{
		return nodes.length;
	}


	function insert(Planet planet, uint256 prev) private returns(uint256)
	{
		Node memory node;

		if(nodes.length == 0)
		{
			node = Node(planet, 0, 0);
		}
		else
		{
			require(prev < nodes.length);

			node = Node(planet, prev, nodes[prev].next);

			nodes[node.next].prev = nodes.length;
			nodes[prev].next = nodes.length;
		}

		return nodes.push(node) - 1;
	}
}