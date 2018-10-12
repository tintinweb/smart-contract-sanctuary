pragma solidity ^0.4.25;


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
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
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
    public
    view
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
    public
    view
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
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {

  /**
   * @dev Throws if operator is not whitelisted.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator, string _role) {
    checkRole(_operator, _role);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address _operator, string _role)
    public
    onlyOwner
  {
    addRole(_operator, _role);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, _role);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] _operators, string _role)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i], _role);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address _operator, string _role)
    public
    onlyOwner
  {
    removeRole(_operator, _role);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] _operators, string _role)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i], _role);
    }
  }

}

contract MonthlySubscription is Whitelist {
   using SafeMath for uint256;

    struct BigchainDbItem {
        string Name;
        string PublicKey;
        string PrivateKey;
        address PendingTransferAddress;
        bool IsActive;
    }
   mapping (string => uint256) private price;
   mapping (address => BigchainDbItem[]) private items;
   
   function setItem(address _address, string _name, string _publicKey, string _privateKey, bool isActive) public 
   onlyOwner{
        BigchainDbItem memory item = BigchainDbItem(_name, _publicKey, _privateKey, _address, isActive);
        BigchainDbItem[] storage itemList = items[_address];
        itemList.push(item);
   }
   
   function setAllItemActive(address _address, bool isActive) public 
   onlyOwner{
       BigchainDbItem[] storage itemList = items[_address];
       for (uint i = 0; i < itemList.length; i++) {
           itemList[i].IsActive = isActive;
       }
   }
   function setItemActive(address _address, string publicKey, bool isActive) public 
   onlyOwner{
       BigchainDbItem[] storage itemList = items[_address];
       var keyHash = keccak256(publicKey);
       
       for (uint i = 0; i < itemList.length; i++) {
           if(keccak256(itemList[i].PublicKey) == keyHash){
               itemList[i].IsActive = isActive;
           }
           
       }
   }
   function getItem(address _address) public view returns(string, string, string, string) {
        BigchainDbItem[] storage itemList = items[_address];
    
        string memory name = "";
        string memory publicKey = "";
        string memory privateKey = "";
        string memory isActive = "";
        for (uint i = 0; i < itemList.length; i++) {
            BigchainDbItem storage item = itemList[i];
            
            if((bytes(item.Name)).length > 0){
                name = strConcat(name, &#39;;&#39;, item.Name);
                publicKey = strConcat(publicKey, &#39;;&#39;, item.PublicKey);
                privateKey = strConcat(privateKey, &#39;;&#39;, item.PrivateKey);
                isActive = strConcat(isActive, &#39;;&#39;,item.IsActive? &#39;1&#39;:&#39;0&#39;);
            }
            
        }
        return(name, publicKey, privateKey, isActive);
   }
   function requestTransferItem(address _fromAdd, address _toAdd, string publicKey) public
   {
        require(msg.sender == _fromAdd);
       
        BigchainDbItem[] storage itemList = items[_fromAdd];
        var keyHash = keccak256(publicKey);
        
        for (uint i = 0; i < itemList.length; i++) {
            if(keccak256(itemList[i].PublicKey) == keyHash){
                itemList[i].PendingTransferAddress = _toAdd;
                break;
            }
        }
       
   }
   function confirmTransferItem(address _fromAdd, address _toAdd, string publicKey) public
   {
        require(msg.sender == _toAdd);
        
        BigchainDbItem[] storage itemList = items[_fromAdd];
        BigchainDbItem[] storage resultList = items[_toAdd];
        var keyHash = keccak256(publicKey);
        
        for (uint i = 0; i < itemList.length; i++) {
            if((keccak256(itemList[i].PublicKey) == keyHash) 
            && _toAdd == itemList[i].PendingTransferAddress){
                resultList.push(itemList[i]);
                delete itemList[i];
                break;
            }
        }
   }
   function strConcat(string _a, string _b, string _c) 
   internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        return string(babcde);
    }
    /**
    * @dev This will set the string we will use for the month + the price it will cost pe month. 
    */
   function setPrice(string _role, uint256 _price) public
   onlyOwner {
       price[_role] = _price;
   }
    /**
    * @dev This will call the price according to the string pricexmonth
    */
   function getPrice(string _role) public
   view returns (uint256)
   {
       return price[_role];
   }
    /**
    * @dev gets msg.value, makes sure its bigger than minimmun for month payment.
    */
   function subscribe(string _role) public payable{
       require(msg.value >= price[_role]);
       owner.transfer(msg.value);
       addAddressToWhitelist(msg.sender, _role);
   }

   /*function isSubscribed(address _address, string _role)
   public onlyIfWhitelisted(_address, _role)
   view
   returns (bool){
       //do something here
       return true;
   }*/
}