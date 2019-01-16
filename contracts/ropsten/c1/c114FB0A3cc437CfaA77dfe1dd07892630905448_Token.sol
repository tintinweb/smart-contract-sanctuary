pragma solidity ^0.4.24;

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
 * for you to write your own implementation of this interface using Enums or similar.checkRole
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 * to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

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

}
/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";
  bool whitelistAllow = false;

  /**
   * @dev Throws if operator is not whitelisted.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    if(!whitelistAllow){
        require(hasRole(_operator, ROLE_WHITELISTED));
    }
    _;
  }

    function whiteListAllAllow() external onlyOwner {
        whitelistAllow = true;
    }
    function whiteListAllNoAllow() external onlyOwner {
        whitelistAllow = false;
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
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable, Whitelist {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(_value > 0);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}
/*
 * @title Period Config
 * @dev ICO period, rate setting contract.
 */
contract PeriodConfig {
    uint8 public constant decimals = 18;

    struct Breakdown{
        address userAddress;
        uint token_value;
        uint ether_value;
        uint32 insertTime;
    }
    mapping (uint => Breakdown[]) public saleBreakdown;
    mapping (string => mapping(uint => uint)) internal saleData;

    string[] public saleType = ["pre-sale 1th","pre-sale 2th"];

    constructor() public {
    //start Time
        saleData["startTime"][1] = now; //09-10
        saleData["startTime"][2] = now; //11-01

    //end Time
        saleData["endTime"][1] = now; //10-30
        saleData["endTime"][2] = now + 120 seconds; //12-30

    //token rate
        saleData["ethRate"][1] = 45670;

    //total supply
        saleData["totalSupply"][1] = 1500000000 * (10 ** uint256(decimals));
        saleData["totalSupply"][2] = 1500000000 * (10 ** uint256(decimals));
    }

    function getBreakdown_length(uint _sale) public view returns(uint){
        return saleBreakdown[_sale].length;
    }

    function getSale_length() public view returns(uint){
        return saleType.length;
    }

    function getSeasonSupply(uint _season) public view returns(uint){
        return saleData["totalSupply"][_season];
    }

    function getTokenTotalSale(uint _sale) public view returns(uint){
        uint result = 0;
        for(uint i = 0; i < saleBreakdown[_sale].length;i++){
            result += saleBreakdown[_sale][i].token_value;
        }
        return result;
    }

    function getCheckSale() public view returns(uint){
          for(uint i = 1; i <= saleType.length; i++){
              if(now >= saleData["startTime"][i] && now < saleData["endTime"][i]){
                return i;
              }
          }
          return 0;
     }
}
contract Token is Pausable, BasicToken, PeriodConfig{
    using SafeMath for uint256;

    string public constant name = "ADM TOKEN";
    string public constant symbol = "ADM";
    address[] whiteListArray;
    mapping (uint => bool) tokenMoveCheck;

    event TokenMove(string error, uint sale);
    event BurnToken(string error, uint sale);

    constructor() public {
        totalSupply_ = 7000000000 * (10 ** uint256(decimals));
		balances[msg.sender] = 100000000000 * (10 ** uint256(decimals));

        emit Transfer(address(0),msg.sender,1000000000 * (10 ** uint256(decimals)));

        whiteListArray.push(msg.sender);
        addAddressesToWhitelist(whiteListArray);
    }

    function () external whenNotPaused payable {
        uint sale = getCheckSale();
        require(sale != 0);
        require(msg.value != 0);
		require(saleData["ethRate"][sale] != 0);

        if(!tokenMoveCheck[sale] && sale != 1) _tokenMove(sale);
        uint tokens = saleData["ethRate"][sale].mul(msg.value);
        require(saleData["totalSupply"][sale] >= tokens);

        balances[msg.sender] = balances[msg.sender].add(tokens);

        Breakdown memory breakdown;
        breakdown.userAddress = msg.sender;
        breakdown.token_value = breakdown.token_value.add(tokens);
        breakdown.ether_value = breakdown.ether_value.add(msg.value);
        breakdown.insertTime = uint32(now);
        saleBreakdown[sale].push(breakdown);

        saleData["totalSupply"][sale] = saleData["totalSupply"][sale].sub(tokens);

        emit Transfer(address(0),msg.sender,tokens);
        0x3bB45E123839EF037a7E267BE4D2e8F102995037.transfer(msg.value);
    }

    function btcToken(address _to,uint _sale, uint _value) external onlyOwner returns(bool){
		require(_value != 0);

		uint nowSale = getCheckSale();
		uint saleLength = getSale_length();

		if(saleData["endTime"][saleLength] < now){
			nowSale = saleLength;    
		}

		require(_sale <= nowSale);
  		if(!tokenMoveCheck[nowSale] && nowSale != 1) _tokenMove(nowSale);

		uint tokens = _value;
		require(saleData["totalSupply"][nowSale] >= tokens);

		saleData["totalSupply"][nowSale] = saleData["totalSupply"][nowSale].sub(tokens);	
		balances[_to] = balances[_to].add(tokens);

		emit Transfer(owner,_to,tokens);
		return true;
    }

    function transfer(address _to, uint256 _value) public onlyIfWhitelisted(msg.sender) returns (bool){
    	return super.transfer(_to, _value);
    }

    function _tokenMove(uint _sale) internal{
        for(uint i = 1; i < _sale; i++){
            saleData["totalSupply"][_sale] = saleData["totalSupply"][_sale].add(saleData["totalSupply"][i]);
            saleData["totalSupply"][i] = 0;
        }
        emit TokenMove("token move",_sale);
        tokenMoveCheck[_sale] = true;
    }

    function burnToken(uint _sale) external whenPaused onlyOwner{
      require(saleData["totalSupply"][_sale] != 0);
      totalSupply_ -= totalSupply_.sub(saleData["totalSupply"][_sale]);
      saleData["totalSupply"][_sale] = 0;
      emit BurnToken("burn token",_sale);
    }

    function setRate(uint _sale, uint _value) external onlyOwner {
		saleData["ethRate"][_sale] = _value;
    }

	function getRate(uint _sale) public view returns(uint) {
		return saleData["ethRate"][_sale];
    }
}