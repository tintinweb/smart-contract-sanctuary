pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

import "./math/SafeMath.sol";

import "./interface/IToken.sol";
import "./interface/ICreatorToken.sol";

import "./access/roles/ManagerRole.sol";

contract TokenRegistry is ManagerRole {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event CreateToken(address token);
    event AddToken(address token);
    event UpdateToken(address token);
    event BuyToken(address buyer, uint256 amount);

    ICreatorToken private _creatorToken;
    // TechAngel fund contract
    address private _techAngelFund;
    // Team fund contract
    address private _teamFund;

    struct TokenParametres {
        uint256 shareTechAngelFund;         // Share TechAngel fund in ETH regarding the purchase of ether
        uint256 shareTeamFund;              // Share Team fund in ETH regarding the purchase of ether
        uint256 priceToken;                 // Price on 1 + decimals token
        bool activeBuyToken;                // Active buy token for ETH
    }

    // Additional parameters for token counters
    mapping(address => TokenParametres) private _tokenContractsParametres;
    // Collection of all token addresses
    EnumerableSet.AddressSet private _addressesToken;

    receive() external payable { }

    /**
     * @dev Creator token contract.
     * @param name The name token contract.
     * @param symbol The symbol token contract.
     * @param decimals A number of simbols after comma.
     * @param cap Maximum possible number of minced tokens.
     * @param shareTechAngelEther Ether share from buying tokens for ether.
     * @param shareTeamEther Ether share from buying tokens for ether.
     * @param admin Admin token of the contract.
     * @param minter Minter token of the contract.
     * @return A boolean that indicates if the operation was successful.
     */
    function createTokenContract(
        string memory name, 
        string memory symbol, 
        uint8 decimals,
        uint256 cap,
        uint256 shareTechAngelEther,
        uint256 shareTeamEther,
        address admin,
        address minter
    ) public onlyManager returns (bool) {
        address _token = _creatorToken.createTokenContract(name, symbol, decimals, cap);

        IToken _tokenContract = IToken(_token);

        _tokenContract.addAdmin(MINTER_ADMIN_ROLE, address(this));
        _tokenContract.addAdmin(MINTER_ADMIN_ROLE, admin);
        _tokenContract.finalize();

        _tokenContract.grantRole(MINTER_ROLE, minter);
        _tokenContract.grantRole(MINTER_ROLE, address(this));
        _tokenContract.renounceRole(MINTER_ADMIN_ROLE, address(this));
        

        _tokenContractsParametres[address(_tokenContract)] = TokenParametres(
            shareTechAngelEther,
            shareTeamEther,
            0,
            false
        );

        _addressesToken.add(address(_tokenContract));

        emit CreateToken(address(_tokenContract));

        return true;
    }

    /**
     * @dev Purchase of tokens for ether.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function buyToken(address token) public virtual payable returns (bool) {
        IToken _token = IToken(token);

        require(_addressesToken.contains(token), "TokenRegistry: token contract not found in registry");

        require(_techAngelFund != address(0), "TokenRegistry: TechAngel fund Not Found");
        require(_teamFund != address(0), "TokenRegistry: Team fund Not Found");
        require(msg.value >= _tokenContractsParametres[token].priceToken, "TokenRegistry: Amount sending token less price buy token");
        require(_tokenContractsParametres[token].activeBuyToken, "TokenRegistry: Token purchase blocked");

        uint256 payoutTechAngel;
        uint256 payoutTeam;

        payoutTechAngel = msg.value.mul(_tokenContractsParametres[token].shareTechAngelFund).div(100);
        payoutTeam = msg.value.mul(_tokenContractsParametres[token].shareTeamFund).div(100);

        uint256 amountToken = msg.value.mul(10**uint256(_token.decimals())).div(_tokenContractsParametres[token].priceToken);

        _token.mint(_msgSender(), amountToken);

        payable(_techAngelFund).transfer(payoutTechAngel);
        payable(_teamFund).transfer(payoutTeam);

        emit BuyToken(_msgSender(), amountToken);
        return true;
    }

    /**
     * @dev Transfer of tokens that lie on a smart contract.
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferTo(address payable to, uint256 amount) public onlyManager returns (bool) {
        require(to != address(0), "TokenManager: Address Not Found");

        to.transfer(amount);
        return true;
    }

    /**
     * @dev Set active or disactive buy token.
     * @return Price tokens.
     */
    function activeBuyToken(address token, bool status) public returns (bool) {
        IToken _token = IToken(token);

        require(_addressesToken.contains(token), "TokenRegistry: token contract not found in registry");
        require(_token.hasRole(MINTER_ROLE, msg.sender), "TokenRegistry: the sender does not have permission");

        _tokenContractsParametres[token].activeBuyToken = status;
        return true;
    }

    /**
     * @dev Set price buy token.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function setPriceToken(address token, uint256 newPrice) public returns (bool) {
        IToken _token = IToken(token);

        require(_addressesToken.contains(token), "TokenRegistry: token contract not found in registry");
        require(_token.hasRole(MINTER_ROLE, msg.sender), "TokenRegistry: the sender does not have permission");
        require(newPrice > 0, "TokenRegistry: newPrice is 0");

        _tokenContractsParametres[token].priceToken = newPrice;
        return true;
    }

    /**
     * @dev Set address fund TechAngel.
     * @param fundAddress Address Fund.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function setTechAngelFund(address payable fundAddress) public onlyManager returns (bool) {
        require(fundAddress != address(0), "TokenRegistry: fundAddress Not Found");

        _techAngelFund = fundAddress;
        return true;
    }

    /**
     * @dev Set address Team.
     * @param fundAddress Address Fund.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function setTeamFund(address payable fundAddress) public onlyManager returns (bool) {
        require(fundAddress != address(0), "TokenRegistry: fundAddress Not Found");

        _teamFund = fundAddress;
        return true;
    }

    /**
     * @dev Set share fund TechAngel.
     * @param newShare New share fund TechAngel.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function setShareTechAngelFundEth(address token, uint256 newShare) public onlyManager returns (bool) {
        _tokenContractsParametres[token].shareTechAngelFund = newShare;
        return true;
    }

    /**
     * @dev Set share Team fund.
     * @param newShare New share Team fund.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function setShareTeamFundEth(address token, uint256 newShare) public onlyManager returns (bool) {
        _tokenContractsParametres[token].shareTeamFund = newShare;
        return true;
    } 

    /**
     * @dev Set address creator token contract.
     * @param creator Address creator token contract .
     * @return A boolean value indicating whether the operation succeeded.
     */
    function setCreatorToken(ICreatorToken creator) public onlyManager returns (bool) {
        _creatorToken = creator;
        return true;
    } 

    /**
     * @dev Get all creating tokens.
     * @return Collection token contracts.
     */
    function getTokenContracts() public view returns (address[] memory) {
        return _addressesToken.collection();
    }

    /**
     * @dev Get address contract fund TechAngel.
     * @return address contract TechAngel.
     */
    function getTechAngelFund() public view returns (address) {
        return _techAngelFund;
    }

    /**
     * @dev Get address contract Team fund.
     * @return address contract Team.
     */
    function getTeamFund() public view returns (address) {
        return _teamFund;
    }

    /**
     * @dev Get creator token contract.
     * @return address creator token contract.
     */
    function getCreatorToken() public view returns (ICreatorToken) {
        return _creatorToken;
    }

    /**
     * @dev Get address contract Team fund.
     * @param token contract address.
     */
    function getInfoTokenContract(address token) public view returns (
        uint256 shareTechAngelFund,
        uint256 shareTeamFund,
        uint256 priceToken,
        bool activeBuy,
        bool pauseContract
    ) {
        IToken _token = IToken(token);

        return (
            _tokenContractsParametres[token].shareTechAngelFund,
            _tokenContractsParametres[token].shareTeamFund,
            _tokenContractsParametres[token].priceToken,
            _tokenContractsParametres[token].activeBuyToken,
            _token.paused()
        );
    }
}

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../GSN/Context.sol";

contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    // Collection roles and addresses
    mapping (bytes32 => RoleData) private _roles;
    // Roles and Role Addresses
    mapping (bytes32 => address[]) private _addressesRoles;
    
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getMembersRole(bytes32 role) public view returns (address[] memory Accounts) {
        return _addressesRoles[role];
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");

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
     */
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

pragma solidity ^0.6.0;

import "../AccessControl.sol";
import "../../ownership/Ownable.sol";

import "../../interface/IRoleModel.sol";

contract ManagerRole is AccessControl, Ownable, IRoleModel {
    bool private _finalized = false;
    event Finalized();

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "ManagerRole: caller does not have the Manager role");
        _;
    }

    constructor () public {
        _setRoleAdmin(MANAGER_ROLE, MANAGER_ADMIN_ROLE);
    }

    /**
     * @dev Create and ading new role.
     * @param role role account.
     * @param account account for adding to the role.
     */
    function addAdmin(bytes32 role, address account) public virtual onlyOwner returns (bool) {
        require(!_finalized, "ManagerRole: already finalized");

        _setupRole(role, account);
        return true;
    }

    /**
     * @dev Block adding admins.
     */
    function finalize() public virtual onlyOwner {
        require(!_finalized, "ManagerRole: already finalized");

        _finalized = true;
        emit Finalized();
    }
}

pragma solidity ^0.6.0;

interface ICreatorToken {
    function createTokenContract(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 cap
    ) external returns (address);
}

pragma solidity ^0.6.0;

contract IRoleModel {
    /**
     * MANAGER_ADMIN_ROLE - Role for adding managers
     */
    bytes32 public constant MANAGER_ADMIN_ROLE = keccak256("MANAGER_ADMIN_ROLE");

    /**
     * MANAGER_ROLE - Role for managing tokens, selling tokens or changing the terms of token sale
     */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /**
     * MINTER_ADMIN_ROLE - Role for adding minters
     */
    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");

    /**
     * MINTER_ROLE - Role for minting token
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
}

pragma solidity ^0.6.0;

interface IToken {

    // ***** GET INFO ***** //
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getMembersRole(bytes32 role) external view returns (address[] memory Accounts);

    function paused() external view returns (bool);
    
    // ***** SET INFO ***** //

    function mint(address to, uint256 amount) external returns (bool);

    function addAdmin(bytes32 role, address account) external returns (bool);

    function grantRole(bytes32 role, address account) external;

    function finalize() external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Collection addresses
        address[] _collection;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }
    
    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._collection.push(addressValue);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value, address addressValue) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];
            
            for(uint256 i = 0; i < set._collection.length; i++) {
                if (set._collection[i] == addressValue) {
                    _removeIndexArray(i, set._collection);
                    break;
                }
            }
            
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    
    function _collection(Set storage set) private view returns (address[] memory) {
        return set._collection;    
    }
    
    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
        for(uint256 i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }
        
        array.pop();
    }
   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)), value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)), value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    
    function collection(AddressSet storage set) internal view returns (address[] memory) {
        return _collection(set._inner);
    }
   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }
}