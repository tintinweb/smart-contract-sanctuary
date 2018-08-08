pragma solidity ^0.4.24;

/* 

https://dragoneth.com

*/

contract DragonsETH {
    function createDragon(
        address _to, 
        uint256 _timeToBorn, 
        uint256 _parentOne, 
        uint256 _parentTwo, 
        uint256 _gen1, 
        uint240 _gen2
    ) 
        external;
}

library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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

contract RBACWithAdmin is RBAC {
  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_ADMIN = "admin";
  string public constant ROLE_PAUSE_ADMIN = "pauseAdmin";

  /**
   * @dev modifier to scope access to admins
   * // reverts
   */
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }
  modifier onlyPauseAdmin()
  {
    checkRole(msg.sender, ROLE_PAUSE_ADMIN);
    _;
  }
  /**
   * @dev constructor. Sets msg.sender as admin by default
   */
  constructor()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
    addRole(msg.sender, ROLE_PAUSE_ADMIN);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }
}

contract Pausable is RBACWithAdmin {
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
  function pause() onlyPauseAdmin whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyPauseAdmin whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

contract CrowdSaleDragonETH is Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using AddressUtils for address;
    address private wallet;
    address public mainContract;
    uint256 public crowdSaleDragonPrice = 0.01 ether;
    uint256 public soldDragons;
    uint256 public priceChanger = 0.00002 ether;
    uint256 public timeToBorn = 5760; // ~ 24h
    uint256 public contRefer50x50;
    mapping(address => bool) public refer50x50;
    
    constructor(address _wallet, address _mainContract) public {
        wallet = _wallet;
        mainContract = _mainContract;
    }


    function() external payable whenNotPaused nonReentrant {
        require(soldDragons <= 100000);
        require(msg.value >= crowdSaleDragonPrice);
        require(!msg.sender.isContract());
        uint256 count_to_buy;
        uint256 return_value;
  
        count_to_buy = msg.value.div(crowdSaleDragonPrice);
        if (count_to_buy > 15) 
            count_to_buy = 15;
        // operation safety check with functions div() and require() above
        return_value = msg.value - count_to_buy * crowdSaleDragonPrice;
        if (return_value > 0) 
            msg.sender.transfer(return_value);
            
        uint256 mainValue = msg.value - return_value;
        
        if (msg.data.length == 20) {
            address referer = bytesToAddress(bytes(msg.data));
            require(referer != msg.sender);
            if (referer == address(0))
                wallet.transfer(mainValue);
            else {
                if (refer50x50[referer]) {
                    referer.transfer(mainValue/2);
                    wallet.transfer(mainValue - mainValue/2);
                } else {
                    referer.transfer(mainValue*3/10);
                    wallet.transfer(mainValue - mainValue*3/10);
                }
            }
        } else 
            wallet.transfer(mainValue);

        for(uint256 i = 1; i <= count_to_buy; i += 1) {
            DragonsETH(mainContract).createDragon(msg.sender, block.number + timeToBorn, 0, 0, 0, 0);
            soldDragons++;
            crowdSaleDragonPrice = crowdSaleDragonPrice + priceChanger;
        }
        
    }

    function sendBonusEgg(address _to, uint256 _count) external onlyRole("BountyAgent") {
        for(uint256 i = 1; i <= _count; i += 1) {
            DragonsETH(mainContract).createDragon(_to, block.number + timeToBorn, 0, 0, 0, 0);
            soldDragons++;
            crowdSaleDragonPrice = crowdSaleDragonPrice + priceChanger;
        }
        
    }



    function changePrice(uint256 _price) external onlyAdmin {
        crowdSaleDragonPrice = _price;
    }

    function setPriceChanger(uint256 _priceChanger) external onlyAdmin {
        priceChanger = _priceChanger;
    }

    function changeWallet(address _wallet) external onlyAdmin {
        wallet = _wallet;
    }
    

    function setRefer50x50(address _refer) external onlyAdmin {
        require(contRefer50x50 < 50);
        require(refer50x50[_refer] == false);
        refer50x50[_refer] = true;
        contRefer50x50 += 1;
    }

    function setTimeToBorn(uint256 _timeToBorn) external onlyAdmin {
        timeToBorn = _timeToBorn;
        
    }

    function withdrawAllEther() external onlyAdmin {
        require(wallet != 0);
        wallet.transfer(address(this).balance);
    }
   
    function bytesToAddress(bytes _bytesData) internal pure returns(address _addressReferer) {
        assembly {
            _addressReferer := mload(add(_bytesData,0x14))
        }
        return _addressReferer;
    }
}