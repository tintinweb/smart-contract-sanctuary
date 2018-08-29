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

// File: contracts/HeapTycoon.sol

contract HeapTycoon is Ownable
{
	using SafeMath for uint256;

	uint8 PAGE_SIZE = 25;

//0.005
	uint256 MASTER_FEE = 5000000000000000;

//0.01
	uint256 MIN_TICKET = 10000000000000000;

//10
	uint256 MAX_TICKET = 10000000000000000000;

	address public master;

	struct Heap
	{
		uint256 ticket;
		uint256 time;
		bytes32 name;
		uint256 fee;
		address owner;
		uint256 cap;
		uint256 timer;
		uint256 timer_inc;
		uint256 bonus;
		uint256 bonus_fee;
		address cur_addr;
		address[] players;
	}

	Heap[] heaps;

	mapping(bytes32 => bool) used_names;


	constructor() public
	{
		master = msg.sender;

		used_names[bytes32(0)] = true;
	}


	function set_master(address addr) public onlyOwner
	{
		require(addr != address(0));

		master = addr;
	}


	function create(uint256 ticket, bytes32 name, uint256 fee, uint256 timer_inc, uint256 bonus_fee) public payable
	{
		require(msg.sender == tx.origin);
		require(msg.value >= ticket.mul(20));
		require(ticket >= MIN_TICKET);
		require(ticket <= MAX_TICKET);
		require(used_names[name] == false);
		require(fee <= ticket.div(10));
		require(fee >= ticket.div(10000));
		require(timer_inc >= 30);
		require(timer_inc <= 10 days);
		require(bonus_fee <= ticket.div(10));
		require(bonus_fee >= ticket.div(10000));
		require(msg.sender != address(0));
		require(msg.sender != address(this));
		require(msg.sender != address(master));
		require(msg.sender != address(owner));

		address[] memory players;

		Heap memory heap = Heap(ticket, now, name, fee, msg.sender, 0, now.add(timer_inc), timer_inc, 0, bonus_fee, address(0), players);

		used_names[name] = true;

		heaps.push(heap);

		master.transfer(msg.value);
	}


	function buy(uint256 id) public payable
	{
		require(msg.sender == tx.origin);
		require(id < heaps.length);
		require(msg.value >= heaps[id].ticket);
		require(msg.sender != address(0));
		require(msg.sender != address(this));
		require(msg.sender != address(master));
		require(msg.sender != address(owner));

		bytes32 hash;

		uint256 index;

		uint256 val;

		bool res;

		uint256 bonus_val;


		val = heaps[id].ticket.sub(heaps[id].fee).sub(MASTER_FEE).sub(heaps[id].bonus_fee).div(10);

		heaps[id].players.push(msg.sender);

		if(now < heaps[id].timer)
		{
			heaps[id].cur_addr = msg.sender;
			heaps[id].timer = heaps[id].timer.add(heaps[id].timer_inc);
			heaps[id].bonus = heaps[id].bonus.add(heaps[id].bonus_fee);
		}
		else
		{
			bonus_val = heaps[id].bonus;
			heaps[id].bonus = heaps[id].bonus_fee;
			heaps[id].timer = now.add(heaps[id].timer_inc);
		}

		heaps[id].cap = heaps[id].cap.add(msg.value);

		res = master.send(MASTER_FEE);

		for(uint8 i = 0; i < 10; i++)
		{
			hash = keccak256(abi.encodePacked(uint256(blockhash(i)) + uint256(msg.sender) + uint256(heaps.length)));
			index = uint256(hash) % heaps[id].players.length;
			res = heaps[id].players[index].send(val);
		}

		if(bonus_val > 0)
			res = heaps[id].cur_addr.send(bonus_val);

		res = heaps[id].owner.send(heaps[id].fee);
	}


	function get_len() external view returns (uint256)
	{
		return heaps.length;
	}


	function get_heaps(uint256 page) external view returns (uint256[] ids, uint256[] tickets, bytes32[] names, uint256[] caps, uint256[] timers, uint256[] bonuses)
	{
		ids = new uint256[](PAGE_SIZE);
		tickets = new uint256[](PAGE_SIZE);
		names = new bytes32[](PAGE_SIZE);
		caps = new uint256[](PAGE_SIZE);
		timers = new uint256[](PAGE_SIZE);
		bonuses = new uint256[](PAGE_SIZE);

		uint256 start = page.mul(PAGE_SIZE);

		uint256 timer;

		for(uint256 i = 0; i < PAGE_SIZE; i++)
		{
			if(start + i < heaps.length)
			{
				timer = 0;

				if(now < heaps[start + i].timer)
					timer = heaps[start + i].timer - now;

				ids[i] = start + i;
				tickets[i] = heaps[start + i].ticket;
				names[i] = heaps[start + i].name;
				caps[i] = heaps[start + i].cap;
				timers[i] = timer;
				bonuses[i] = heaps[start + i].bonus;
			}
		}
	}


	function is_name_used(bytes32 name) external view returns(bool)
	{
		return used_names[name];
	}


	function get_heap(uint256 id) external view returns(uint256[] data, bytes32 name, address owner, address cur_addr)
	{
		data = new uint256[](11);

		if(id >= heaps.length)
			return;

		name = heaps[id].name;
		owner = heaps[id].owner;
		cur_addr = heaps[id].cur_addr;

		uint timer;

		if(now < heaps[id].timer)
			timer = heaps[id].timer - now;

		data[0] = heaps[id].ticket;
		data[1] = heaps[id].time;
		data[2] = heaps[id].fee;
		data[3] = heaps[id].cap;
		data[4] = timer;
		data[5] = heaps[id].timer_inc;
		data[6] = heaps[id].bonus;
		data[7] = heaps[id].bonus_fee;
		data[8] = heaps[id].ticket.sub(heaps[id].fee).sub(MASTER_FEE).sub(heaps[id].bonus_fee).div(10);
	}
}