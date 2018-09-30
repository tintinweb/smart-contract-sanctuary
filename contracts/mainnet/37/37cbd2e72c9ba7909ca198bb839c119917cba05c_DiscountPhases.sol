pragma solidity ^0.4.13;

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

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

contract Staff is Ownable, RBAC {

	string public constant ROLE_STAFF = "staff";

	function addStaff(address _staff) public onlyOwner {
		addRole(_staff, ROLE_STAFF);
	}

	function removeStaff(address _staff) public onlyOwner {
		removeRole(_staff, ROLE_STAFF);
	}

	function isStaff(address _staff) view public returns (bool) {
		return hasRole(_staff, ROLE_STAFF);
	}
}

contract StaffUtil {
	Staff public staffContract;

	constructor (Staff _staffContract) public {
		require(msg.sender == _staffContract.owner());
		staffContract = _staffContract;
	}

	modifier onlyOwner() {
		require(msg.sender == staffContract.owner());
		_;
	}

	modifier onlyOwnerOrStaff() {
		require(msg.sender == staffContract.owner() || staffContract.isStaff(msg.sender));
		_;
	}
}

contract DiscountPhases is StaffUtil {
	using SafeMath for uint256;

	event DiscountPhaseAdded(uint index, string name, uint8 percent, uint fromDate, uint toDate, uint timestamp, address byStaff);
	event DiscountPhaseRemoved(uint index, uint timestamp, address byStaff);

	struct DiscountPhase {
		uint8 percent;
		uint fromDate;
		uint toDate;
	}

	DiscountPhase[] public discountPhases;

	constructor(Staff _staffContract) StaffUtil(_staffContract) public {
	}

	function calculateBonusAmount(uint256 _purchasedAmount) public constant returns (uint256) {
		for (uint i = 0; i < discountPhases.length; i++) {
			if (now >= discountPhases[i].fromDate && now <= discountPhases[i].toDate) {
				return _purchasedAmount.mul(discountPhases[i].percent).div(100);
			}
		}
	}

	function addDiscountPhase(string _name, uint8 _percent, uint _fromDate, uint _toDate) public onlyOwnerOrStaff {
		require(bytes(_name).length > 0);
		require(_percent > 0 && _percent <= 100);

		if (now > _fromDate) {
			_fromDate = now;
		}
		require(_fromDate < _toDate);

		for (uint i = 0; i < discountPhases.length; i++) {
			require(_fromDate > discountPhases[i].toDate || _toDate < discountPhases[i].fromDate);
		}

		uint index = discountPhases.push(DiscountPhase({percent : _percent, fromDate : _fromDate, toDate : _toDate})) - 1;

		emit DiscountPhaseAdded(index, _name, _percent, _fromDate, _toDate, now, msg.sender);
	}

	function removeDiscountPhase(uint _index) public onlyOwnerOrStaff {
		require(now < discountPhases[_index].toDate);
		delete discountPhases[_index];
		emit DiscountPhaseRemoved(_index, now, msg.sender);
	}
}