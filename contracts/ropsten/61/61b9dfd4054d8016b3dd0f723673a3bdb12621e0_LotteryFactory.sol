pragma solidity ^0.4.24;

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



/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
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



/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 * to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

  /**
   * @dev Throws if operator is not whitelisted.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address _operator)
    onlyOwner
    public
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

contract ClubAccessControl is Whitelist {
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }
}

contract HKHcoinInterface {
    mapping (address => uint256) public balanceOf;
    function mintToken(address target, uint256 mintedAmount) public;
    function burnFrom(address _from, uint256 _value) public returns (bool success);
}

contract PlayerFactory is ClubAccessControl {
    struct Player {
        bool isFreezed;
        bool isExist;
    }

    mapping (address => Player) public players;
    HKHcoinInterface hkhconinContract;
    uint initCoins = 1000000;

    modifier onlyIfPlayerNotFreezed(address _playerAddress) { 
        require (!players[_playerAddress].isFreezed);
        _; 
    }
    
    modifier onlyIfPlayerExist(address _playerAddress) { 
        require (players[_playerAddress].isExist);
        _; 
    }

    event NewPlayer(address indexed _playerAddress);

    function setHKHcoinAddress(address _address) 
        external
        onlyIfWhitelisted(msg.sender)
    {
        hkhconinContract = HKHcoinInterface(_address);
    }

    function getBalanceOfPlayer(address _playerAddress)
        public
        onlyIfPlayerExist(_playerAddress)
        view
        returns (uint)
    {
        return hkhconinContract.balanceOf(_playerAddress);
    }

    function joinClub(address _playerAddress)
        external
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
    {
        require(!players[_playerAddress].isExist);
        players[_playerAddress] = Player(false, true);
        hkhconinContract.mintToken(_playerAddress, initCoins);
        emit NewPlayer(_playerAddress);
    }

    function reset(address _playerAddress)
        external
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        whenNotPaused
    {
        uint balance = hkhconinContract.balanceOf(_playerAddress);

        if(balance > initCoins)
            _destroy(_playerAddress, balance - initCoins);
        else if(balance < initCoins)
            _recharge(_playerAddress, initCoins - balance);

        emit NewPlayer(_playerAddress);
    }

    function recharge(address _playerAddress, uint _amount)
        public
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        whenNotPaused
    {
        _recharge(_playerAddress, _amount);
    }

    function destroy(address _playerAddress, uint _amount)
        public
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        whenNotPaused
    {
        _destroy(_playerAddress, _amount);
    }

    function freezePlayer(address _playerAddress)
        public
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        whenNotPaused
    {
        players[_playerAddress].isFreezed = true;
    }

    function resumePlayer(address _playerAddress)
        public
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        whenNotPaused
    {
        players[_playerAddress].isFreezed = false;
    }

    function _recharge(address _playerAddress, uint _amount)
        internal
    {
        hkhconinContract.mintToken(_playerAddress, _amount);
    }

    function _destroy(address _playerAddress, uint _amount)
        internal
    {
        hkhconinContract.burnFrom(_playerAddress, _amount);
    }
}

/**
 * 
 */
contract LotteryFactory is PlayerFactory {

    event BuyLottery(
        uint32 _id,
        address indexed _playerAddress,
        string _betline,
        string _place,
        uint32 _betAmount,
        uint32 indexed _date,
        uint8 indexed _race
    );

    struct Lottery {
        uint32 betAmount;
        uint32 dividend;
        uint32 date;
        uint8 race;
        bool isPaid;
        string betline;
        string place;
    }

    Lottery[] public lotteries;

    mapping (uint => address) public lotteryToOwner;
    mapping (address => uint) ownerLotteryCount;

    constructor() public {
        addAddressToWhitelist(msg.sender);
    }

    function getLotteriesByOwner(address _owner) 
        view 
        external 
        onlyIfPlayerExist(_owner) 
        returns(uint[]) 
    {
        uint[] memory result = new uint[](ownerLotteryCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < lotteries.length; i++) {
            if (lotteryToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function createLottery(
        address _playerAddress,
        string _betline, 
        string _place,
        uint32 _betAmount,
        uint32 _date,
        uint8 _race
    )
        external
        onlyIfWhitelisted(msg.sender)
        onlyIfPlayerExist(_playerAddress)
        onlyIfPlayerNotFreezed(_playerAddress)
        whenNotPaused
    {
        uint32 id = uint32(lotteries.push(Lottery(_betAmount, 0, _date, _race, false, _betline, _place))) - 1;
        lotteryToOwner[id] = _playerAddress;
        ownerLotteryCount[_playerAddress]++;
        _destroy(_playerAddress, _betAmount);
        emit BuyLottery(
            id,
            _playerAddress,
            _betline,
            _place,
            _betAmount,
            _date,
            _race
        );
    }

    function setDividendAndPayOut(
        uint32 _id,
        uint32 _dividend
    )
        external
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
    {
        if(lotteries[_id].isPaid == false) {
            lotteries[_id].dividend = _dividend;
            _recharge(lotteryToOwner[_id], lotteries[_id].dividend);
            lotteries[_id].isPaid = true;
        }
    }
}