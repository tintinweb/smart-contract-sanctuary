/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact [email protected] if you like to use code
pragma solidity ^0.6.8;
interface IOracle {
    function getLatestPrice() external view returns ( uint256,uint8);
    function getCustomPrice(address aggregator) external view returns (uint256,uint8);
}
library SafeMath {
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
interface IPoolRegistry {
    function isTeam(address account) external view returns (bool);
    function getTeamAddresses() external view returns (address[] memory);
    function getOracleContract() external view returns (IOracle);
    function feesMultipier(address sender) external view returns (uint256);
}
contract IRoleModel {
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant GENERAL_PARTNER_ROLE = keccak256("GENERAL_PARTNER_ROLE");
    bytes32 public constant LIMITED_PARTNER_ROLE = keccak256("LIMITED_PARTNER_ROLE");
    bytes32 public constant STARTUP_TEAM_ROLE = keccak256("STARTUP_TEAM_ROLE");
    bytes32 public constant POOL_REGISTRY = keccak256("POOL_REGISTRY");
    bytes32 public constant RETURN_INVESTMENT_LPARTNER = keccak256("RETURN_INVESTMENT_LPARTNER");
    bytes32 public constant ORACLE = keccak256("ORACLE");
    bytes32 public constant REFERER_ROLE = keccak256("REFERER_ROLE");
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IOpenBiSeaAuction {
    function contractsNFTWhitelisted() external view returns (address[] memory);
    function whitelistContractCreator( address _contractNFT, uint256 fee ) external payable;
    function createAuction( address _contractNFT, uint256 _tokenId, uint256 _price,uint256 _deadline, bool _isERC1155, address _sender, bool _isUSD ) external;
    function bid( address _contractNFT,uint256 _tokenId, uint256 _price, bool _isERC1155, address _sender ) external returns (bool, uint256, address, bool);
    function cancelAuction( address _contractNFT, uint256 _tokenId, address _sender, bool _isERC1155 ) external;
    function checkTokensForClaim( address customer, uint256 priceMainToUSD) external view returns (uint256,uint256,uint256,bool);
    function setConsumersReceivedMainTokenLatestDate(address _sender) external;
}
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        address[] _collection;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(addressValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastValue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastValue;
            set._values.pop();

            address lastvalueAddress = set._collection[lastIndex];
            set._collection[toDeleteIndex] = lastvalueAddress;
            set._collection.pop();

            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            delete set._indexes[value];
//            for(uint256 i = 0; i < set._collection.length; i++) {
//                if (set._collection[i] == addressValue) {
//                    _removeIndexArray(i, set._collection);
//                    break;
//                }
//            }
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _collection(Set storage set) private view returns (address[] memory) {
        return set._collection;    
    }
//    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
//        for(uint256 i = index; i < array.length-1; i++) {
//            array[i] = array[i+1];
//        }
//        array.pop();
//    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function collection(AddressSet storage set) internal view returns (address[] memory) {
        return _collection(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
}
library EnumerableUintSet {
    struct Set {
        bytes32[] _values;
        uint256[] _collection;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value, uint256 savedValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(savedValue);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastValue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastValue;
            set._values.pop();

            uint256 lastvalueAddress = set._collection[lastIndex];
            set._collection[toDeleteIndex] = lastvalueAddress;
            set._collection.pop();

            set._indexes[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _collection(Set storage set) private view returns (uint256[] memory) {
        return set._collection;    
    }

    function _at(Set storage set, uint256 index) private view returns (uint256) {
        require(set._collection.length > index, "EnumerableSet: index out of bounds");
        return set._collection[index];
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function collection(UintSet storage set) internal view returns (uint256[] memory) {
        return _collection(set._inner);
    }
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return _at(set._inner, index);
    }
}
interface IAssetsManageTeam {
    function _depositToken(address pool, address team, address token, uint256 amount) external returns (bool);
    function _withdraw(address pool, address team, uint256 amount) external returns (bool);
    function _withdrawTokensToStartup(address pool,address token, address team, uint256 amount) external returns (bool);
    function _request(bool withdraw, address pool, address team, uint256 maxValue) external returns(bool);
    function _requestTokensWidthdrawalFromStartup(address pool, address token, address team, uint256 maxValue) external returns(bool);
    function _approve(address pool, address team, address owner) external returns(bool);
    function _approveTokensWidthdrawalFromStartup(address pool, address token, address team, address owner) external returns(bool);
    function _disapprove(address pool, address team, address owner) external returns(bool);
    function _lock(address pool, address team, address owner) external returns(bool);
    function _unlock(address pool, address team, address owner) external returns(bool);
    function addManager(address account) external;
    function getPerformedOperationsLength(address pool, address owner) external view returns(uint256 length);
    function getPerformedOperations(address pool, address owner, uint256 index) external view returns(address token, uint256 amountToken, uint256 withdraw, uint256 time);
    function getRequests(address pool) external view returns(address[] memory);
    function getApproval(address pool) external view returns(address[] memory);
    function getRequestTeamAddress(address pool, address team) external view returns(bool lock, uint256 maxValueToken, uint256 madeValueToken, uint256 maxValue, uint256 madeValue);
    function getApproveTeamAddress(address pool, address team) external view returns(bool lock, uint256 maxValueToken, uint256 madeValueToken, uint256 maxValue, uint256 madeValueE);
}
library Roles {
    struct Role {
        address[] accounts;
        mapping (address => bool) bearer;
        mapping (bytes32 => uint256) _indexes;
    }
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
        role.accounts.push(account);
        role._indexes[bytes32(uint256(account))] = role.accounts.length;
    }
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        uint256 valueIndex = role._indexes[bytes32(uint256(account))];
        if (valueIndex != 0) { // Equivalent to contains()
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = role.accounts.length - 1;
            address lastValue = role.accounts[lastIndex];
            role.accounts[toDeleteIndex] = lastValue;
            role.accounts.pop();
            delete role._indexes[bytes32(uint256(account))];
        }

        role.bearer[account] = false;
    }
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }

}
contract Context {
    constructor () internal { }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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
contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }
    mapping (bytes32 => RoleData) private _roles;
    mapping (bytes32 => address[]) private _addressesRoles;
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }
   function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }
    function getMembersRole(bytes32 role) public view returns (address[] memory Accounts) {
        return _addressesRoles[role];
    }
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }
    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            _addressesRoles[role].push(account);
            emit RoleGranted(role, account, _msgSender());
        }
    }
    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            for (uint256 i; i < _addressesRoles[role].length; i++) {
                if (_addressesRoles[role][i] == account) {
                    _removeIndexArray(i, _addressesRoles[role]);
                    break;
                }
            }
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
        for(uint256 i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }
        array.pop();
    }
}
contract PoolRoles is AccessControl, Ownable, IRoleModel {
    bool private _finalized = false;
    event Finalized();
    modifier onlyGPartner() {
        require(hasRole(GENERAL_PARTNER_ROLE, msg.sender), "Roles: caller does not have the general partner role");
        _;
    }
    modifier onlyLPartner() {
        require(hasRole(LIMITED_PARTNER_ROLE, msg.sender), "Roles: caller does not have the limited partner role");
        _;
    }
    modifier onlyStartupTeam() {
        require(hasRole(STARTUP_TEAM_ROLE, msg.sender), "Roles: caller does not have the team role");
        _;
    }
    modifier onlyPoolRegistry() {
        require(hasRole(POOL_REGISTRY, msg.sender), "Roles: caller does not have the pool regystry role");
        _;
    }
    modifier onlyReturnsInvestmentLpartner() {
        require(hasRole(RETURN_INVESTMENT_LPARTNER, msg.sender), "Roles: caller does not have the return invesment lpartner role");
        _;
    }
    modifier onlyOracle() {
        require(hasRole(ORACLE, msg.sender), "Roles: caller does not have oracle role");
        _;
    }
    constructor () public {
        _setRoleAdmin(GENERAL_PARTNER_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(LIMITED_PARTNER_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(STARTUP_TEAM_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(POOL_REGISTRY, SUPER_ADMIN_ROLE);
        _setRoleAdmin(RETURN_INVESTMENT_LPARTNER, SUPER_ADMIN_ROLE);
        _setRoleAdmin(ORACLE, SUPER_ADMIN_ROLE);
    }
    function addAdmin(bytes32 role, address account) public onlyOwner returns (bool) {
        require(!_finalized, "ManagerRole: already finalized");

        _setupRole(role, account);
        return true;
    }
    function finalize() public onlyOwner {
        require(!_finalized, "ManagerRole: already finalized");
        _finalized = true;
        emit Finalized();
    }
}
contract TeamRole {
    using Roles for Roles.Role;
    event TeamAdded(address indexed account);
    event TeamRemoved(address indexed account);
    event OracleAdded(address indexed account);
    event OracleRemoved(address indexed account);
    Roles.Role private _team;
    Roles.Role private _oracle;
    constructor () internal {
        _addTeam(msg.sender);
    }
    modifier onlyTeam() {
        require(isTeam(msg.sender), "TeamRole: caller does not have the Team role");
        _;
    }
    modifier onlyRegistryOracle() {
        require(isOracle(msg.sender), "TeamRole: caller does not have the Oracle role");
        _;
    }

    function isOracle(address account) public view returns (bool) {
        return _oracle.has(account);
    }
    function getOracleAddresses() public view returns (address[] memory) {
        return _oracle.accounts;
    }

    function addOracle(address account) public onlyTeam {
        _addOracle(account);
    }
    function _addOracle(address account) internal {
        _oracle.add(account);
        emit OracleAdded(account);
    }
    function renounceOracle() public {
        _removeOracle(msg.sender);
    }
    function _removeOracle(address account) internal {
        _oracle.remove(account);
        emit OracleRemoved(account);
    }

    function isTeam(address account) public view returns (bool) {
        return _team.has(account);
    }
    function getTeamAddresses() public view returns (address[] memory) {
        return _team.accounts;
    }
    function addTeam(address account) public onlyTeam {
        _addTeam(account);
    }
    function renounceTeam() public onlyTeam {
        _removeTeam(msg.sender);
    }
    function _addTeam(address account) internal {
        _team.add(account);
        emit TeamAdded(account);
    }
    function _removeTeam(address account) internal {
        _team.remove(account);
        emit TeamRemoved(account);
    }
}
contract OpenBiSea is PoolRoles,TeamRole  {
    using SafeMath for uint256;
    using EnumerableUintSet for EnumerableUintSet.UintSet;

    event Deposit(address indexed from, uint256 value);
    event DebugWithdrawLPartner(address sender,address owner, uint256 getDepositLengthSender, uint256 getDepositLengthOwner,uint256 totalAmountReturn,uint256 indexesDepositLength,uint256 balanceThis);
    string private _name;
    bool private _isPublicPool = true;
    address private _auction;
    address private _busdContract;
    address private _token;
    uint256 private _lockPeriod;
    uint256 private _rate;
    uint256 private _poolValueUSD = 0;
    uint256 private _poolValue = 0;
    string private _proofOfValue = "nothing";
    uint256 private _depositFixedFee;
    uint256 private _referralDepositFee;
    uint256 private _auctionCreationFeeMultiplier;
    uint256 private _auctionContractFeeMultiplier;
    uint256 private _totalIncome;
    uint256 private _premiumFee;
    struct DepositToPool {
        uint256 amount;          // Amount of funds deposited
        uint256 time;            // Deposit time
        uint256 lock_period;     // Asset lock time
        bool refund_authorize;   // Are assets unlocked for withdrawal
        uint256 amountWithdrawal;
        address investedToken;
    }
    mapping(address => DepositToPool[]) private _deposites;
    mapping(address => address) private _referrals;

//    mapping(address => uint256) private _consumersRevenueAmount;

    IAssetsManageTeam private _assetsManageTeam;
    IPoolRegistry private _poolRegistry;
    modifier onlyAdmin(address sender) {
        if(hasRole(GENERAL_PARTNER_ROLE, sender) || hasRole(SUPER_ADMIN_ROLE, sender) || _poolRegistry.isTeam(sender)) {
            _;
        } else {
            revert("The sender does not have permission");
        }
    }
    address private _tokenForTokensale;
    uint256 private _initialBalance;
    constructor (
        address tokenForTokensale,

        address superAdmin,
        address gPartner,
        address lPartner,
        address team,
        address poolRegistry,
        address returnInvestmentLpartner,
        IAssetsManageTeam assetsManageTeam,
        uint256 initialBalance,
        address busdContract
    ) public {
//        _name = name;
        _tokenForTokensale = tokenForTokensale;

        _assetsManageTeam = assetsManageTeam;
        _poolRegistry = IPoolRegistry(poolRegistry);
        _initialBalance = initialBalance;
        _busdContract = busdContract;
        PoolRoles.addAdmin(SUPER_ADMIN_ROLE, msg.sender);
        PoolRoles.addAdmin(SUPER_ADMIN_ROLE, superAdmin);
        PoolRoles.addAdmin(SUPER_ADMIN_ROLE, poolRegistry);
        PoolRoles.finalize();
        grantRole(GENERAL_PARTNER_ROLE, gPartner);
        grantRole(LIMITED_PARTNER_ROLE, lPartner);
        grantRole(STARTUP_TEAM_ROLE, team);
        grantRole(POOL_REGISTRY, poolRegistry);
        grantRole(RETURN_INVESTMENT_LPARTNER, returnInvestmentLpartner);
    }

    function _updatePool(
        string calldata name,
        bool isPublicPool,
        address token,
        uint256 locked,
        uint256 depositFixedFee,
        uint256 referralDepositFee,
        uint256 auctionCreationFeeMultiplier,
        uint256 auctionContractFeeMultiplier
    ) external onlyPoolRegistry returns (bool) {
        _name = name;
        _isPublicPool = isPublicPool;
        _lockPeriod = locked;
        _depositFixedFee = depositFixedFee;
        _referralDepositFee = referralDepositFee;
        _auctionCreationFeeMultiplier = auctionCreationFeeMultiplier;
        _auctionContractFeeMultiplier = auctionContractFeeMultiplier;
        return true;
    }

    function getInfoPool() public view returns( string memory name,bool isPublicPool,address tokenForTokensale,uint256 locked,uint256 initialBalance)
    {
        return ( _name,_isPublicPool,_tokenForTokensale,_lockPeriod, _initialBalance);
    }
    receive() external payable {}
    function getDeposit(address owner, uint256 index) public view returns(uint256 amount, uint256 time, uint256 lock_period, bool refund_authorize, uint256 amountWithdrawal, address investedToken) {
        return ( _deposites[owner][index].amount, _deposites[owner][index].time,_deposites[owner][index].lock_period, _deposites[owner][index].refund_authorize, _deposites[owner][index].amountWithdrawal, _deposites[owner][index].investedToken);
    }
    function getDepositLength(address owner) public view returns(uint256) {
        return (_deposites[owner].length);
    }
    function getReferral(address lPartner) public view returns (address) {
        return _referrals[lPartner];
    }
    function getInfoPoolFees() public view returns(uint256 rate, uint256 depositFixedFee, uint256 referralDepositFee, uint256 auctionCreationFeeMultiplier, uint256 auctionContractFeeMultiplier, uint256 totalIncome, uint256 premiumFee)
    {
        return (_rate, _depositFixedFee, _referralDepositFee, _auctionCreationFeeMultiplier, _auctionContractFeeMultiplier, _totalIncome, _premiumFee);
    }
    function _approveWithdrawLpartner(address lPartner, uint256 index, uint256 amount, address investedToken) external onlyReturnsInvestmentLpartner returns (bool) {
        _deposites[lPartner][index].refund_authorize = true;
        _deposites[lPartner][index].amountWithdrawal = amount;
        _deposites[lPartner][index].investedToken = investedToken;
        return true;
    }
    function _depositPoolRegistry(address sender, uint256 amount, uint256 feesMultipier) external onlyPoolRegistry returns (bool) {
        require(hasRole(LIMITED_PARTNER_ROLE, sender), "InvestmentPool: the sender does not have permission");
        return _deposit(sender, amount, feesMultipier);
    }
    function _withdrawTeam (address payable sender, uint256 amount) external onlyPoolRegistry returns (bool) {
        require(hasRole(STARTUP_TEAM_ROLE, sender), "InvestmentPool: the sender does not have permission");
        _assetsManageTeam._withdraw(address(this), sender, amount);
        sender.transfer(amount);
        return true;
    }
    function _withdrawTokensToStartup(address payable sender,address token, uint256 amount) external onlyPoolRegistry returns (bool) {
        require(hasRole(STARTUP_TEAM_ROLE, sender), "InvestmentPool: the sender does not have permission");
        _assetsManageTeam._withdrawTokensToStartup(address(this),token, sender, amount);
        IERC20(token).transfer(sender, amount);
        return true;
    }
    function _returnsInTokensFromTeam(address payable sender,address token, uint256 amount) external onlyPoolRegistry returns (bool) {
        require(hasRole(STARTUP_TEAM_ROLE, sender), "InvestmentPool: the sender does not have permission");
        IERC20(token).transferFrom(sender, address(this), amount);
        return true;
    }
    function _withdrawLPartner(address payable sender) external onlyPoolRegistry returns (bool, uint256, address) {
        require(hasRole(LIMITED_PARTNER_ROLE, sender), "InvestmentPool: the sender does not have permission");
        uint256 totalAmountReturn = 0;
        address token = address(0);
        uint256 lengthSender = getDepositLength(sender);
        bool result = false;
        for (uint256 i = 0; i < lengthSender; i++) {
            DepositToPool storage deposit = _deposites[sender][i];
            if (deposit.refund_authorize) {
                token = deposit.investedToken;
                if (deposit.amountWithdrawal > 0) {
                    if (token == address(0)) {
                        sender.transfer(deposit.amountWithdrawal);
                        totalAmountReturn = totalAmountReturn.add(deposit.amountWithdrawal);
                    } else {
                        IERC20(token).transfer(sender, deposit.amountWithdrawal);
                    }
                }
                _deposites[sender][i].refund_authorize = false;
                _deposites[sender][i].amountWithdrawal = 0;
            }
        }
        return (result,totalAmountReturn,token);
    }
    function _withdrawSuperAdmin(address payable sender,address token, uint256 amount) external onlyPoolRegistry returns (bool) {
        require(hasRole(SUPER_ADMIN_ROLE, sender), "InvestmentPool: the sender does not have permission");
        if (amount > 0) {
            if (token == address(0)) {
                sender.transfer(amount);
                return true;
            } else {
                IERC20(token).transfer(sender, amount);
                return true;
            }
        }
        return false;
    }
    function _activateDepositToPool() external onlyPoolRegistry returns (bool) {
        require(!_isPublicPool, "InvestmentPool: the pool is already activated");
        _isPublicPool = true;
        return true;
    }
    function _disactivateDepositToPool() external onlyPoolRegistry returns (bool) {
        require(_isPublicPool, "InvestmentPool: the pool is already deactivated");
        _isPublicPool = false;
        return true;
    }
    function _setReferral(address sender, address lPartner, address referral) external onlyPoolRegistry onlyAdmin(sender) returns (bool) {
        _referrals[lPartner] = referral;
        return true;
    }

    function _setRate(uint256 rate) external onlyPoolRegistry returns (bool) {
        _rate = rate;
        return true;
    }
    function _setPoolValues(uint256 poolValueUSD,uint256 poolValue,string calldata proofOfValue) external onlyPoolRegistry returns (bool) {
        _poolValueUSD = poolValueUSD;
        _poolValue = poolValue;
        _proofOfValue = proofOfValue;
        return true;
    }
    function _setAuction(address newAuction) public onlyTeam {
        _auction = newAuction;
    }
    function auction() public view returns (address)  {
        return _auction;
    }
    function getPoolValues() public view returns(uint256 poolValueUSD, uint256 poolValue, string memory proofOfValue)
    {
        return (_poolValueUSD, _poolValue, _proofOfValue);
    }
    function _depositInvestmentInTokensToPool(address payable sender, uint256 amount, address token) external onlyPoolRegistry returns (bool) {
        require(hasRole(LIMITED_PARTNER_ROLE, sender), "InvestmentPool: the sender does not have permission");
        uint256 depositFee = amount.mul(_depositFixedFee).div(100);
        uint256 depositFeeReferrer = amount.mul(_referralDepositFee).div(100);
        uint256 totalDeposit = 0;
        if (_referrals[sender] != address(0)) {
            totalDeposit = amount.sub(depositFee).sub(depositFeeReferrer);
        } else {
            totalDeposit = amount.sub(depositFee);
        }
        _deposites[sender].push(DepositToPool(totalDeposit, block.timestamp, _lockPeriod, false, 0, token));
        return true;
    }
    uint256 private initialPriceInt = 18446744073709551615;// 88800000000000000 - 0.0888 BNB one token, 18446744073709551615 - MATIC one token
    function getInitialPriceInt() public view returns (uint256)  {
        return initialPriceInt;
    }

//    uint256 private _tokensaleTotalAmount = (10 ** uint256(18)).mul(8000);// 8000 obs
    uint256 private _tokensaleTotalSold;

    function purchaseTokensQuantityFor(uint256 amount) public view returns (uint256,uint256) {
        uint256 delta = _initialBalance.sub(_tokensaleTotalSold);
        uint256 newPrice = initialPriceInt.mul(_initialBalance).div(delta);
        return (amount.mul(10 ** uint256(18)).div(newPrice),_initialBalance.sub(_tokensaleTotalSold));
    }

    function purchaseTokens() public payable returns (uint256) {
        require(msg.value > 100000000000000000, "TokensalePool: minimal purchase 0.1BNB.");
        uint256 amountTokens;
        uint256 balance;
        (amountTokens,balance) = purchaseTokensQuantityFor(msg.value);
        require(amountTokens > 0, "TokensalePool: we can't sell 0 tokens.");
        require(amountTokens < balance.div(3), "TokensalePool: we can't sell more than 30% from one transaction. Please decrease investment amount.");
        IERC20(_tokenForTokensale).transfer(msg.sender, amountTokens);
        _tokensaleTotalSold = _tokensaleTotalSold.add(amountTokens);
        return amountTokens;
    }
    uint256 constant private multiplierDefault = 100000;

    function _deposit(address sender, uint256 amount, uint256 feesMultipier) private returns (bool) {
        require(_isPublicPool, "InvestmentPool: pool deposit blocked");
        address payable team = payable(getRoleMember(GENERAL_PARTNER_ROLE,0));
        uint256 depositFee = amount.mul(_depositFixedFee).div(100).div(feesMultipier).mul(multiplierDefault);
        uint256 depositFeeReferrer = amount.mul(_referralDepositFee).div(100).div(feesMultipier).mul(multiplierDefault);
        uint256 totalDeposit = 0;
        if (_referrals[sender] != address(0)) {
            payable(_referrals[sender]).transfer(depositFeeReferrer);
            team.transfer(depositFee);
            totalDeposit = amount.sub(depositFee).sub(depositFeeReferrer);
        } else {
            team.transfer(depositFee);
            totalDeposit = amount.sub(depositFee);
        }
        _deposites[sender].push(DepositToPool(totalDeposit, block.timestamp, _lockPeriod, false, 0, address(0)));
        _totalIncome = _totalIncome.add(amount);
        emit Deposit(sender, amount);
        return true;
    }
    function _transferGeneralPartner(uint256 amount) private returns (bool) {
        address payable gPartner = payable(getMembersRole(GENERAL_PARTNER_ROLE)[0]);
        gPartner.transfer(amount);
        return true;
    }
    function _getTokenAmount(uint256 weiAmount) public view returns (uint256) {
        uint8 DECIMALS = IERC20(_token).decimals();
        return (weiAmount.mul(_rate)).div(10 ** uint256(DECIMALS));
    }
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            length := extcodesize(_addr)
        }
        return (length>0);
    }

    function _removeIndexArray(uint256 index, DepositToPool[] storage array) internal virtual {
        for(uint256 i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }
        array.pop();
    }

    function contractsNFTWhitelisted() public view returns (address[] memory) {
        return IOpenBiSeaAuction(_auction).contractsNFTWhitelisted();
    }

    function whitelistContractCreator( address _contractNFT ) public payable {
        require(msg.value >= initialPriceInt.mul(_auctionCreationFeeMultiplier), "OpenBiSea: you must send minimal amount or more");
        IOpenBiSeaAuction(_auction).whitelistContractCreator(_contractNFT,msg.value);
        _totalIncome = _totalIncome.add(msg.value);
    }

    function whitelistContractCreatorTokens( address _contractNFT ) public {
        uint256 amount = (10 ** uint256(18)).mul(_auctionCreationFeeMultiplier);
        IERC20(_tokenForTokensale).transferFrom(msg.sender,address(this),amount);
        _totalIncome = _totalIncome.add(initialPriceInt.mul(amount).div(10 ** uint256(18)));
        IOpenBiSeaAuction(_auction).whitelistContractCreator(_contractNFT,initialPriceInt.mul(amount));
    }
    function createAuction( address _contractNFT, uint256 _tokenId, uint256 _price,uint256 _deadline, bool _isERC1155, bool _isUSD ) public {
        IOpenBiSeaAuction(_auction).createAuction(_contractNFT,_tokenId, _price, _deadline,_isERC1155, msg.sender, _isUSD);
    }
    function bidUSD( address _contractNFT,uint256 _tokenId, uint256 _bidAmount, bool _isERC1155 ) public {
        IERC20(_busdContract).transferFrom(msg.sender,address(this),_bidAmount);
        bool isWin;
        uint256 amountTransferBack;
        address auctionLatestBidderOrSeller;
        bool isUSD;
        (isWin,amountTransferBack,auctionLatestBidderOrSeller,isUSD) = IOpenBiSeaAuction(_auction).bid( _contractNFT, _tokenId, _bidAmount, _isERC1155, msg.sender );
        if (isWin) {
            if (isUSD) {
                uint256 depositFee = _bidAmount.mul(_depositFixedFee).div(100);
                uint256 depositFeeReferrer = _bidAmount.mul(_referralDepositFee).div(100);
                uint256 totalSellerAmount = _bidAmount.sub(depositFee);
                if (_referrals[msg.sender] != address(0)) {
                    totalSellerAmount = totalSellerAmount.sub(depositFeeReferrer);
                    IERC20(_busdContract).transfer(_referrals[msg.sender],depositFeeReferrer);
                    IERC20(_busdContract).transfer(getRoleMember(GENERAL_PARTNER_ROLE,0),depositFee);
                } else {
                    IERC20(_busdContract).transfer(getRoleMember(GENERAL_PARTNER_ROLE,0),depositFee);
                }
                IERC20(_busdContract).transfer(auctionLatestBidderOrSeller,totalSellerAmount);
            }
        } else {
            if (amountTransferBack > 0 && isUSD) {
                IERC20(_busdContract).transfer(auctionLatestBidderOrSeller,amountTransferBack);
            }
        }
    }
    function bid( address _contractNFT,uint256 _tokenId, bool _isERC1155 ) public payable {
        bool isWin;
        uint256 amountTransferBack;
        address auctionLatestBidderOrSeller;
        bool isUSD;
        (isWin,amountTransferBack,auctionLatestBidderOrSeller,isUSD) = IOpenBiSeaAuction(_auction).bid( _contractNFT, _tokenId, msg.value, _isERC1155, msg.sender );
        if (isWin) {
            if (!isUSD) {
                uint256 depositFee = msg.value.mul(_depositFixedFee).div(100);
                uint256 depositFeeReferrer = msg.value.mul(_referralDepositFee).div(100);
                uint256 totalSellerAmount = msg.value.sub(depositFee);
                if (_referrals[msg.sender] != address(0)) {
                    totalSellerAmount = totalSellerAmount.sub(depositFeeReferrer);
                    payable(_referrals[msg.sender]).transfer(depositFeeReferrer);
                    payable(getRoleMember(GENERAL_PARTNER_ROLE,0)).transfer(depositFee);
                } else {
                    payable(getRoleMember(GENERAL_PARTNER_ROLE,0)).transfer(depositFee);
                }
                payable(auctionLatestBidderOrSeller).transfer(totalSellerAmount);
            }
        } else {
            if (amountTransferBack > 0 && !isUSD) {
                payable(auctionLatestBidderOrSeller).transfer(amountTransferBack);
            }
        }
    }
    function cancelAuction( address _contractNFT, uint256 _tokenId, bool _isERC1155 ) public {
        IOpenBiSeaAuction(_auction).cancelAuction(_contractNFT,_tokenId,msg.sender,_isERC1155);
    }
    function checkTokensForClaim( address customer, uint256 priceMainToUSD) public view returns (uint256,uint256,uint256,bool) {
        return IOpenBiSeaAuction(_auction).checkTokensForClaim(customer,priceMainToUSD);
    }
    event ClaimFreeTokens(uint256 amount, address investor,bool result);
    function claimFreeTokens() public returns (bool) {
        uint256 priceMainToUSD;
        uint8 decimals;
        (priceMainToUSD,decimals) = _poolRegistry.getOracleContract().getLatestPrice();

        uint256 tokensToPay;
        (tokensToPay,,,)= checkTokensForClaim(msg.sender,priceMainToUSD.div(10 ** uint256(decimals)));
        bool result = false;
        if (tokensToPay > 0) {
            IERC20(_tokenForTokensale).transfer(msg.sender, tokensToPay);
            IOpenBiSeaAuction(_auction).setConsumersReceivedMainTokenLatestDate(msg.sender);
            result = true;
        }
        emit ClaimFreeTokens(tokensToPay,msg.sender,result);
        return result;
    }
}