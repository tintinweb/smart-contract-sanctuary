// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "./interfaces/EGovernanceInterface.sol";
import "./EJuneAccessControl.sol";

contract EGovernanceBase is EJuneAccessControl{
    EGovernanceInterface internal governance;
    constructor (address _governanceAdress) {
        require(_governanceAdress != address(0), "Governance is the zero address");
        governance = EGovernanceInterface(_governanceAdress);
    }


    //CONTRACT INTERFACES
    // modifier onlyFromJuneTokenAddress() {
    //     require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || _msgSender() == governance.juneTokenAddress(), "Dont have June Token Address permission!");
    //     _;
    // }

    // modifier onlyFromJuneNFTAddress() {
    //     require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || _msgSender() == governance.juneNFTAddress(), "Dont have June NFT Address permission!");
    //     _;
    // }

    modifier onlyFromJuneGatewayOracleAddress() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || _msgSender() == governance.juneGatewayOracleAddress(), "Dont have June Gateway Oracle Address permission!");
        _;
    }

    modifier onlyFromJuneNFTMarketAddress() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || _msgSender() == governance.juneNFTMarketAddress(), "Dont have June NFT Market Address permission!");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/AccessControlEnumerable.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";

contract EJuneAccessControl is Context, AccessControlEnumerable {
    bytes32 public constant JUNE_MINTER_ROLE = keccak256("JUNE_MINTER_ROLE");
    bytes32 public constant JUNE_GATEWAY_ORACLE_ROLE = keccak256("JUNE_GATEWAY_ORACLE_ROLE");
    

    //ROLES
    modifier onlyJuneGatewayOraclePermission() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(JUNE_GATEWAY_ORACLE_ROLE, _msgSender()), "Dont have June Gateway Oracle permission!");
        _;
    } 

    modifier onlyJuneMinterPermission() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(JUNE_MINTER_ROLE, _msgSender()), "Dont have June Minter permission!");
        _;
    } 

    modifier onlyAdminPermission() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Dont have June Admin permission!");
        _;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./EGovernanceBase.sol";
import "./interfaces/EJuneTokenInterface.sol";
import "./interfaces/EJuneNFTInterface.sol";
import "./interfaces/EJuneMapperInterface.sol";

import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155Receiver.sol";

contract EJuneGatewayOracle is EGovernanceBase, IERC1155Receiver{
    struct DepositInfo {
        uint id;    //only for NFT
        uint amount;
        address mainAddress;        
        address sidechainAddress;        
    }
    mapping(uint256=>DepositInfo) public sideChainDepositMap;
    mapping(uint256=>bool) private pendingSideChainDepositRequests;


    uint private randNonce = 0;
    // uint private modulus = 1000;

    uint public minAllowDeposit = 0;


    uint public numOracles = 0;

    event RequestDepositTokenToSideChain(address indexed mainAddress, address indexed sidechainAddress, uint256 amount, uint requestId);
    event DepositTokenToSideChain(address indexed mainAddress,  address indexed sidechainAddress, uint256 amount, bool error);
    event WithdrawalTokenFromSideChain(address indexed mainAddress,  address indexed sidechainAddress, uint256 amount, bool error);

    event RequestDepositNFTToSideChain(address indexed mainAddress, address indexed sidechainAddress, uint256 id, uint256 amount, uint256 requestId);
    event DepositNFTToSideChain(address indexed mainAddress,  address indexed sidechainAddress, uint256 id, uint256 amount, bool error);
    event WithdrawalNFTFromSideChain(address indexed mainAddress,  address indexed sidechainAddress, uint256 id, uint256 amount, bool error);

    event AddOracleEvent(address oracleAddress);
    event RemoveOracleEvent(address oracleAddress);

    constructor(address _governanceAdress) EGovernanceBase(_governanceAdress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addOracle(address _oracle) public onlyAdminPermission{
        require(!hasRole(JUNE_GATEWAY_ORACLE_ROLE, _oracle),"Already an oracle!");

        grantRole(JUNE_GATEWAY_ORACLE_ROLE, _oracle);
        numOracles++;
        emit AddOracleEvent(_oracle);
    }

    function removeOracle(address _oracle) public onlyAdminPermission{
        require(hasRole(JUNE_GATEWAY_ORACLE_ROLE, _oracle),"Not an oracle!");
        require(numOracles > 1, "Do not remove the last oracle!");
        revokeRole(JUNE_GATEWAY_ORACLE_ROLE, _oracle);
        numOracles--;
        emit RemoveOracleEvent(_oracle);
    }

    function setMinAllowDeposit(uint _minAllowDeposit) public onlyAdminPermission{
        minAllowDeposit = _minAllowDeposit;
    }

    function depositTokenToSideChain(uint256 _amount) public returns (uint256){
        require(_amount > minAllowDeposit, "Invalid deposit Amount!");

        EJuneMapperInterface juneMapper = EJuneMapperInterface(governance.juneMapperAddress());
        address sidechainAddress = juneMapper.getSideChainAddress(_msgSender());
        require(sidechainAddress != address(0), "Not found mapping sidechain address!");

        EJuneTokenInterface junetoken = EJuneTokenInterface(governance.juneTokenAddress());
        require(junetoken.balanceOf(_msgSender()) >= _amount, "Insufficient Balance!");
        junetoken.transferToGatewayOracle(_msgSender(), _amount);

        randNonce++;
        // uint requestId = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce))) % modulus;
        uint requestId = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce)));

        while (pendingSideChainDepositRequests[requestId]) {
            randNonce++;
            requestId = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce)));
        }

        pendingSideChainDepositRequests[requestId] = true;

        sideChainDepositMap[requestId].amount = _amount;
        sideChainDepositMap[requestId].mainAddress = _msgSender();
        sideChainDepositMap[requestId].sidechainAddress = sidechainAddress;

        emit RequestDepositTokenToSideChain(_msgSender(), sidechainAddress, _amount, requestId);        
        return requestId;
    }

    function onDepositTokenToSideChain(uint256 _requestId, address _mainAddress, address _sidechainAddress, bool _error) public onlyJuneGatewayOraclePermission{
        require(pendingSideChainDepositRequests[_requestId], "This request is not in pending list.");
        require(sideChainDepositMap[_requestId].amount > 0 && sideChainDepositMap[_requestId].mainAddress == _mainAddress && sideChainDepositMap[_requestId].sidechainAddress == _sidechainAddress, "This request is not in my pending list.");

        uint amount = sideChainDepositMap[_requestId].amount;
        if (_error){
            //refund token back to owner
            EJuneTokenInterface junetoken = EJuneTokenInterface(governance.juneTokenAddress());
            if (junetoken.balanceOf(address(this)) < amount){
                return;
            }
            junetoken.transfer(_mainAddress, amount);
        }
        
        delete pendingSideChainDepositRequests[_requestId];
        delete sideChainDepositMap[_requestId];

        emit DepositTokenToSideChain(_mainAddress, _sidechainAddress, amount, _error);
    }


    function requestWithdrawalTokenToMainChain(address _sidechainAddress, uint256 _amount) public onlyJuneGatewayOraclePermission{
        require(_amount > 0, "Invalid Amount!");

        EJuneMapperInterface juneMapper = EJuneMapperInterface(governance.juneMapperAddress());
        address mainAddress = juneMapper.getMainAddress(_sidechainAddress);
        require(mainAddress != address(0), "Not found mapping main address!");

        EJuneTokenInterface junetoken = EJuneTokenInterface(governance.juneTokenAddress());
        require(junetoken.balanceOf(address(this)) >= _amount, "Insufficient eth gateway Balance!");
        junetoken.transfer(mainAddress, _amount);

        emit WithdrawalTokenFromSideChain(mainAddress, _sidechainAddress, _amount, false);
    }

    function transferToken(address to, uint amount) public onlyAdminPermission{
        EJuneTokenInterface junetoken = EJuneTokenInterface(governance.juneTokenAddress());

        require(amount > 0, "Invalid amount");
        require(junetoken.balanceOf(address(this)) >= amount, "Insufficient Balance!");
        
        junetoken.transfer(to, amount);
    }


    /////////////////////////////NFT//////////////////
    function depositNFTToSideChain(uint256 _id, uint256 _amount) public returns (uint256){
        require(_amount > 0, "Invalid deposit Amount!");

        EJuneMapperInterface juneMapper = EJuneMapperInterface(governance.juneMapperAddress());
        address sidechainAddress = juneMapper.getSideChainAddress(_msgSender());
        require(sidechainAddress != address(0), "Not found mapping sidechain address!");

        EJuneNFTInterface juneNFT = EJuneNFTInterface(governance.juneNFTAddress());
        require(juneNFT.balanceOf(_msgSender(), _id) >= _amount, "Insufficient Balance!");
        juneNFT.transferToGatewayOracle(_msgSender(), _id, _amount, '0x00');

        randNonce++;
        // uint requestId = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce))) % modulus;
        uint requestId = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce)));

        while (pendingSideChainDepositRequests[requestId]) {
            randNonce++;
            requestId = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce)));
        }

        pendingSideChainDepositRequests[requestId] = true;

        sideChainDepositMap[requestId].id = _id;
        sideChainDepositMap[requestId].amount = _amount;
        sideChainDepositMap[requestId].mainAddress = _msgSender();
        sideChainDepositMap[requestId].sidechainAddress = sidechainAddress;

        emit RequestDepositNFTToSideChain(_msgSender(), sidechainAddress, _id, _amount, requestId);        
        return requestId;
    }

    function onDepositNFTToSideChain(uint256 _requestId, address _mainAddress, address _sidechainAddress, bool _error) public onlyJuneGatewayOraclePermission{
        require(pendingSideChainDepositRequests[_requestId], "This request is not in pending list.");
        require(sideChainDepositMap[_requestId].amount > 0 && sideChainDepositMap[_requestId].mainAddress == _mainAddress && sideChainDepositMap[_requestId].sidechainAddress == _sidechainAddress, "This request is not in my pending list.");

        uint amount = sideChainDepositMap[_requestId].amount;
         uint id = sideChainDepositMap[_requestId].id;
        if (_error){
            //refund token back to owner
            EJuneNFTInterface juneNFT = EJuneNFTInterface(governance.juneNFTAddress());
            if (juneNFT.balanceOf(address(this), id) < amount){
                return;
            }
            juneNFT.safeTransferFrom(address(this), _mainAddress, id, amount, '0x00');
        }
        
        delete pendingSideChainDepositRequests[_requestId];
        delete sideChainDepositMap[_requestId];

        emit DepositNFTToSideChain(_mainAddress, _sidechainAddress, id, amount, _error);
    }

    function requestWithdrawalNFTToMainChain(address _sidechainAddress, uint256 _id, uint256 _amount) public onlyJuneGatewayOraclePermission{
        require(_amount > 0, "Invalid Amount!");

        EJuneMapperInterface juneMapper = EJuneMapperInterface(governance.juneMapperAddress());
        address mainAddress = juneMapper.getMainAddress(_sidechainAddress);
        require(mainAddress != address(0), "Not found mapping main address!");

        EJuneNFTInterface juneNFT = EJuneNFTInterface(governance.juneNFTAddress());
        require(juneNFT.balanceOf(address(this), _id) >= _amount, "Insufficient eth gateway Balance!");

        juneNFT.safeTransferFrom(address(this), mainAddress, _id, _amount, '0x00');

        emit WithdrawalNFTFromSideChain(mainAddress, _sidechainAddress, _id, _amount, false);
    }


    function transferNFT(address to, uint256 id, uint amount) public onlyAdminPermission{
        EJuneNFTInterface juneNFT = EJuneNFTInterface(governance.juneNFTAddress());

        require(amount > 0, "Invalid amount");
        require(juneNFT.balanceOf(address(this), id) >= amount, "Insufficient Balance!");
        
        juneNFT.safeTransferFrom(address(this), to, id, amount, '0x00');
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4){
        // this.onERC1155Received.selector;
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }


    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4){
        // this.onERC1155BatchReceived.selector;
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


interface EGovernanceInterface {
    function juneWallet() external view returns (address);
    function juneTokenAddress() external view returns (address);
    function juneNFTAddress() external view returns (address);
    function juneNFTMarketAddress() external view returns (address);
    function juneGatewayOracleAddress() external view returns (address);
    function juneMapperAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


interface EJuneMapperInterface {
    function getSideChainAddress(address _mainAddress) external view returns(address);
    function getMainAddress(address _sidechainAddress) external view returns(address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


interface EJuneNFTInterface {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function transferToGatewayOracle(address from, uint256 id, uint256 amount, bytes memory data) external;

    function mintedTokensMap(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


interface EJuneTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferToGatewayOracle(address from, uint256 amount) external;
    function transferToJuneWallet(address from, uint256 amount) external;
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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
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

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
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
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
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
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

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
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
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
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

