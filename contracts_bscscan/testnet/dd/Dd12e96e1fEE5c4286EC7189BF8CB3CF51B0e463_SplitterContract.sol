//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Interfaces/SplitterInterface.sol";

contract SplitterContract is AccessControl, SplitterInterface {
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CONNECTION_MANAGER_ROLE = keccak256("CONNECTION_MANAGER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint private _combinedWeight;
    uint private _participantCount;
    mapping(uint => ParticipantData) private _participantMap;

    string[] private _varableNameArray;
    bytes8[] private _variableHashArray;

    IERC20 private _tokenInstance;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _varableNameArray = new string[](5);
        _varableNameArray[0] = "weight";
        _varableNameArray[1] = "destinationAddress";
        _varableNameArray[2] = "capActive";
        _varableNameArray[3] = "cap";
        _varableNameArray[4] = "fallbackAddress";

        _variableHashArray = new bytes8[](5);
        _variableHashArray[0] = bytes8(keccak256(bytes(_varableNameArray[0])));
        _variableHashArray[1] = bytes8(keccak256(bytes(_varableNameArray[1])));
        _variableHashArray[2] = bytes8(keccak256(bytes(_varableNameArray[2])));
        _variableHashArray[3] = bytes8(keccak256(bytes(_varableNameArray[3])));
        _variableHashArray[4] = bytes8(keccak256(bytes(_varableNameArray[4])));
    }

    /////////////////////
    //* PUBLIC REGION *//
    /////////////////////
    function splitFunds() public override returns (bool) {
        uint currentBalance = getTokenBalance();
        require(currentBalance >= _combinedWeight, "Balance to low!");
        require(currentBalance > 0, "Balance is 0!");
        ParticipantData memory currentParticipant; 
        uint destinationAmount;
        uint currentSendingAmount;

        for (uint i=0; i<_participantCount; i++) {
            currentParticipant = getParticipantData(i);
            currentSendingAmount = (currentBalance * currentParticipant.weight) / _combinedWeight;
            if (currentParticipant.capActive) {
                destinationAmount = _tokenInstance.balanceOf(currentParticipant.destinationAddress);
                if ( destinationAmount >= currentParticipant.cap) {
                    _tokenInstance.transfer(currentParticipant.fallbackAddress, currentSendingAmount);
                    emit TokensSentToFallback(currentParticipant.fallbackAddress, currentSendingAmount);
                    continue;
                } else if (destinationAmount + currentSendingAmount >= currentParticipant.cap) {
                    _tokenInstance.transfer(currentParticipant.destinationAddress, currentParticipant.cap - destinationAmount);
                    emit TokensSent(currentParticipant.destinationAddress, currentParticipant.cap - destinationAmount);
                    _tokenInstance.transfer(currentParticipant.fallbackAddress, currentSendingAmount - (currentParticipant.cap - destinationAmount));
                    emit TokensSentToFallback(currentParticipant.fallbackAddress, currentSendingAmount - (currentParticipant.cap - destinationAmount));
                    continue;
                } 
            }
            _tokenInstance.transfer(currentParticipant.destinationAddress, currentSendingAmount);
            emit TokensSent(currentParticipant.destinationAddress, currentSendingAmount);
        }
        return true;
    }

    ///////////////////////////
    //* MANAGER_ROLE REGION *//
    ///////////////////////////
    function addParticipant(uint weight_, address destinationAddress_,  bool capActive_, uint cap_, address fallbackAddress_) public onlyRole(MANAGER_ROLE) override returns (bool) {
        ParticipantData memory newParticipant = ParticipantData(0, weight_, destinationAddress_, capActive_, cap_, fallbackAddress_);
        _appendParticipant(newParticipant);
        return true;
    }
    function removeParticipant(uint participantId_) public onlyRole(MANAGER_ROLE) override returns (bool) {
        _removeParticipant(participantId_);
        return true;
    }
    function editParticipant(uint participantId_, bytes8 variableHash_, bytes32 value_) public onlyRole(MANAGER_ROLE) override returns (bool) { 
        if (variableHash_ == _variableHashArray[0]) {
            uint oldWeight = getParticipantData(participantId_).weight;
            uint newWeight = uint(value_);
            require(oldWeight != newWeight, "Value is already set!");
            
            _participantMap[participantId_].weight = newWeight;
            _combinedWeight -= oldWeight;
            _combinedWeight += newWeight;

            emit ParticipantEdited(participantId_, variableHash_, bytes32(oldWeight), bytes32(newWeight));
        } else if (variableHash_ == _variableHashArray[1]) {
            address oldDestinationAddress = getParticipantData(participantId_).destinationAddress;
            address newDestinationAddress = bytes32ToAddress(value_);
            require(oldDestinationAddress != newDestinationAddress, "Value is already set!");
            
            _participantMap[participantId_].destinationAddress = newDestinationAddress;

            emit ParticipantEdited(participantId_, variableHash_, addressToBytes32(oldDestinationAddress), addressToBytes32(newDestinationAddress));
        } else if (variableHash_ == _variableHashArray[2]) {
            bool oldCapActive = getParticipantData(participantId_).capActive;
            bool newCapActive = (value_ != bytes32(0));
            require(oldCapActive != newCapActive, "Value is already set!");
            
            _participantMap[participantId_].capActive = newCapActive;

            if (newCapActive) {
                emit ParticipantEdited(participantId_, variableHash_, bytes32(uint(1)), bytes32(uint(0)));
            } else {
                emit ParticipantEdited(participantId_, variableHash_, bytes32(uint(0)), bytes32(uint(1)));
            }
            
        } else if (variableHash_ == _variableHashArray[3]) {
            uint oldCap = getParticipantData(participantId_).cap;
            uint newCap = uint(value_);
            require(oldCap != newCap, "Value is already set!");
            
            _participantMap[participantId_].cap = newCap;

            emit ParticipantEdited(participantId_, variableHash_, bytes32(oldCap), bytes32(newCap));
        } else if (variableHash_ == _variableHashArray[4]) {
            address oldFallbackAddress = getParticipantData(participantId_).fallbackAddress;
            address newFallbackAddress = bytes32ToAddress(value_);
            require(oldFallbackAddress != newFallbackAddress, "Value is already set!");
            
            _participantMap[participantId_].fallbackAddress = newFallbackAddress;

            emit ParticipantEdited(participantId_, variableHash_, addressToBytes32(oldFallbackAddress), addressToBytes32(newFallbackAddress));
        } else {
            revert("VariableHash is not correct!");
        }
        return true;
    }
    function switchParticipants(uint firstTokenId_, uint secondTokenId_) public onlyRole(MANAGER_ROLE) override returns (bool) {
        require(firstTokenId_ < secondTokenId_, "First token should be smaller than second");
        _switchParticipants(firstTokenId_, secondTokenId_);
        return true;
    }

    //////////////////////////////////////
    //* CONNECTION_MANAGER_ROLE REGION *//
    //////////////////////////////////////
    function setTokenInstance(address tokenAddress_) public onlyRole(CONNECTION_MANAGER_ROLE) override returns (bool) {
        address oldValue = address(_tokenInstance);
        require(oldValue != tokenAddress_, "Values is already set!");
        _tokenInstance = IERC20(tokenAddress_);
        emit TokenAddressChanged(oldValue, tokenAddress_);
        return true;
    }

    ///////////////////////
    //* INTERNAL REGION *//
    ///////////////////////
    function _appendParticipant(ParticipantData memory participant_) internal {
        
        participant_.id = getParticipantCount();
        _participantMap[getParticipantCount()] = participant_;
        
        _participantCount += 1;
        _combinedWeight += participant_.weight;
        
        emit ParticipantAdded(participant_.id, participant_.weight, _combinedWeight, participant_.destinationAddress, participant_.cap, participant_.capActive, participant_.fallbackAddress);
    }
    function _removeParticipant(uint participantId_) internal {
        uint currentParticipantId = participantId_;
        if (participantId_ != getLastParticipantId()) {
            _switchParticipants(participantId_, getLastParticipantId());
            currentParticipantId = getLastParticipantId();
        }
        ParticipantData memory currentParticipant = getParticipantData(currentParticipantId);
        emit ParticipantRemoved(currentParticipant.id, currentParticipant.weight, _combinedWeight, currentParticipant.destinationAddress, currentParticipant.cap, currentParticipant.capActive, currentParticipant.fallbackAddress);

        _participantCount -= 1;
        _combinedWeight -= currentParticipant.weight;
        delete _participantMap[currentParticipantId];
    }
    function _switchParticipants(uint firstTokenId_, uint secondTokenId_) internal {
        ParticipantData memory firstParticipant = getParticipantData(firstTokenId_);
        ParticipantData memory secondParticipant = getParticipantData(secondTokenId_);
        
        firstParticipant.id = secondTokenId_;
        _participantMap[secondTokenId_] = firstParticipant;

        secondParticipant.id = firstTokenId_;
        _participantMap[firstTokenId_] = secondParticipant;

        emit ParticipantSwitched(firstTokenId_, secondTokenId_);
    }
    function bytes32ToAddress(bytes32 hash) internal pure returns (address) {
        address addy;
        assembly {
            mstore(0, hash)
            addy := mload(0)
        }
        return addy;
    }
    function addressToBytes32(address addy) internal pure returns (bytes32) {
        bytes32 hash;
        assembly {
            mstore(0, addy)
            hash := mload(0)
        }
        return hash;
    }


    /////////////////////
    //* DEFAULT_ADMIN *//
    /////////////////////
    function setRoleAdmin(bytes32 role_, bytes32 adminRole_) public onlyRole(DEFAULT_ADMIN_ROLE) override returns (bool) {
        _setRoleAdmin(role_, adminRole_);
        emit AdminRoleSet(role_, adminRole_);
        return true;
    }
    function salvageTokensFromContract(address tokenAddress_, address to_, uint amount_) public onlyRole(DEFAULT_ADMIN_ROLE) override returns (bool) {
        (bool success, ) = tokenAddress_.call(abi.encodeWithSignature(
            "transfer(address,uint256)",
            to_, 
            amount_
        ));
        require(success, "Call failed!");
        emit TokensSalvaged(tokenAddress_, to_, amount_);
        return true;
    }
    function killContract() public onlyRole(DEFAULT_ADMIN_ROLE) override returns (bool) {
        emit ContractKilled();
        selfdestruct(payable(msg.sender));
        return true;
    }

    /////////////////////////////
    //* PUBLIC GETTERS REGION *//
    /////////////////////////////
    function getParticipantCount() public view override returns (uint) {
        return _participantCount;
    }
    function getLastParticipantId() public view override returns (uint) {
        return _participantCount - 1;
    }
    function getCombinedWeight() public view override returns (uint) {
        return _combinedWeight;
    }

    function getParticipantData(uint participantId_) public view override returns (ParticipantData memory) {
        require(participantId_ <= getLastParticipantId(), "ParticipantId is out of range!");
        return _participantMap[participantId_];
    }
    function getParticipantsData(uint startIndex_, uint endIndex_) public view override returns (ParticipantData[] memory) { 
        ParticipantData[] memory participantsDataArray = new ParticipantData[](endIndex_ - startIndex_);
        for (uint i=0; i<endIndex_ - startIndex_; i++) {
            participantsDataArray[i] = _participantMap[i + startIndex_];
        }
        return participantsDataArray;
    }

    function getTokenAddress() public view override returns (address) {
        return address(_tokenInstance);
    }
    function getTokenBalance() public view override returns (uint) {
        return _tokenInstance.balanceOf(address(this));
    }

    function getVariables() public view override returns (string[] memory, bytes8[] memory) {
        return (_varableNameArray, _variableHashArray);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";

struct ParticipantData {
    uint id;
    uint weight;
    address destinationAddress;
    bool capActive;
    uint cap;
    address fallbackAddress;
}

interface SplitterInterface is IAccessControl {

    /////////////////////
    //* PUBLIC REGION *//
    /////////////////////
    function splitFunds() external returns (bool);

    ///////////////////////////
    //* MANAGER_ROLE REGION *//
    ///////////////////////////
    function addParticipant(uint weight_, address destinationAddress_,  bool capActive_, uint cap_, address fallbackAddress_) external returns (bool);
    function removeParticipant(uint participantId_) external returns (bool);
    function editParticipant(uint participantId_, bytes8 variableHash_, bytes32 value_) external returns (bool);
    function switchParticipants(uint firstTokenId_, uint secondTokenId_) external returns (bool);

    //////////////////////////////////////
    //* CONNECTION_MANAGER_ROLE REGION *//
    //////////////////////////////////////
    function setTokenInstance(address tokenAddress_) external returns (bool);

    /////////////////////
    //* DEFAULT_ADMIN *//
    /////////////////////
    function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external returns (bool);
    function salvageTokensFromContract(address tokenAddress_, address to_, uint amount_) external returns (bool);
    function killContract() external returns (bool);

    /////////////////////////////
    //* PUBLIC GETTERS REGION *//
    /////////////////////////////
    function getParticipantCount() external view returns (uint);
    function getLastParticipantId() external view returns (uint);
    function getCombinedWeight() external view returns (uint);

    function getParticipantData(uint participantId_) external view returns (ParticipantData memory);
    function getParticipantsData(uint startIndex_, uint endIndex_) external view returns (ParticipantData[] memory);

    function getTokenAddress() external view returns (address);
    function getTokenBalance() external view returns (uint);

    function getVariables() external view returns (string[] memory, bytes8[] memory);

    //////////////
    //* EVENTS *//
    //////////////
    event TokensSent(address destinationAddress, uint amount);
    event TokensSentToFallback(address fallbackAddress, uint amount);

    event ParticipantAdded(uint id, uint weight, uint combinedWeight, address destinationAddress, uint cap, bool capActive, address fallbackAddress);
    event ParticipantEdited(uint id, bytes8 parameter, bytes32 oldValue, bytes32 newValue);
    event ParticipantSwitched(uint firstId, uint secondId);
    event ParticipantRemoved(uint id, uint weight, uint combinedWeight, address destinationAddress, uint cap, bool capActive, address fallbackAddress);

    event TokenAddressChanged(address oldValue, address newValue);

    event AdminRoleSet(bytes32 role, bytes32 adminRole);
    event TokensSalvaged(address tokenAddress, address reciever, uint amount);
    event ContractKilled();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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