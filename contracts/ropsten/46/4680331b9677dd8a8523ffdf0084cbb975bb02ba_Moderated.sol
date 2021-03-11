/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity 0.5.4;


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


// @notice Moderators are able to modify whitelists and transfer permissions in Moderator contracts.
contract ModeratorRole {
    using Roles for Roles.Role;

    event ModeratorAdded(address indexed account);
    event ModeratorRemoved(address indexed account);

    Roles.Role internal _moderators;

    modifier onlyModerator() {
        require(isModerator(msg.sender), "Only Moderators can execute this function.");
        _;
    }

    constructor() internal {
        _addModerator(msg.sender);
    }

    function isModerator(address account) public view returns (bool) {
        return _moderators.has(account);
    }

    function addModerator(address account) public onlyModerator {
        _addModerator(account);
    }

    function renounceModerator() public {
        _removeModerator(msg.sender);
    }    

    function _addModerator(address account) internal {
        _moderators.add(account);
        emit ModeratorAdded(account);
    }    

    function _removeModerator(address account) internal {
        _moderators.remove(account);
        emit ModeratorRemoved(account);
    }
}

// @notice Controllers are capable of performing ERC1644 forced transfers.
contract ControllerRole {
    using Roles for Roles.Role;

    event ControllerAdded(address indexed account);
    event ControllerRemoved(address indexed account);

    Roles.Role internal _controllers;

    modifier onlyController() {
        require(isController(msg.sender), "Only Controllers can execute this function.");
        _;
    }

    constructor() internal {
        _addController(msg.sender);
    }

    function isController(address account) public view returns (bool) {
        return _controllers.has(account);
    }

    function addController(address account) public onlyController {
        _addController(account);
    }

    function renounceController() public {
        _removeController(msg.sender);
    }

    function _addController(address account) internal {
        _controllers.add(account);
        emit ControllerAdded(account);
    }    

    function _removeController(address account) internal {
        _controllers.remove(account);
        emit ControllerRemoved(account);
    }
}
interface IModerator {
    function verifyIssue(address _tokenHolder, uint256 _value, bytes calldata _data) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyTransferFrom(address _from, address _to, address _forwarder, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyRedeem(address _sender, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyRedeemFrom(address _sender, address _tokenHolder, uint256 _amount, bytes calldata _data) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);        

    function verifyControllerTransfer(address _controller, address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyControllerRedeem(address _controller, address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);
}

contract Blacklistable is ModeratorRole {
    event Blacklisted(address account);
    event Unblacklisted(address account);

    mapping (address => bool) public isBlacklisted;

    modifier onlyBlacklisted(address account) {
        require(isBlacklisted[account], "Account is not blacklisted.");
        _;
    }

    modifier onlyNotBlacklisted(address account) {
        require(!isBlacklisted[account], "Account is blacklisted.");
        _;
    }

    function blacklist(address account) external onlyModerator {
        require(account != address(0), "Cannot blacklist zero address.");
        require(account != msg.sender, "Cannot blacklist self.");
        require(!isBlacklisted[account], "Address already blacklisted.");
        isBlacklisted[account] = true;
        emit Blacklisted(account);
    }

    function unblacklist(address account) external onlyModerator {
        require(account != address(0), "Cannot unblacklist zero address.");
        require(account != msg.sender, "Cannot unblacklist self.");
        require(isBlacklisted[account], "Address not blacklisted.");
        isBlacklisted[account] = false;
        emit Unblacklisted(account);
    }
}

contract Whitelistable is ModeratorRole {
    event Whitelisted(address account);
    event Unwhitelisted(address account);

    mapping (address => bool) public isWhitelisted;

    modifier onlyWhitelisted(address account) {
        require(isWhitelisted[account], "Account is not whitelisted.");
        _;
    }

    modifier onlyNotWhitelisted(address account) {
        require(!isWhitelisted[account], "Account is whitelisted.");
        _;
    }

    function whitelist(address account) external onlyModerator {
        require(account != address(0), "Cannot whitelist zero address.");
        require(account != msg.sender, "Cannot whitelist self.");
        require(!isWhitelisted[account], "Address already whitelisted.");
        isWhitelisted[account] = true;
        emit Whitelisted(account);
    }

    function unwhitelist(address account) external onlyModerator {
        require(account != address(0), "Cannot unwhitelist zero address.");
        require(account != msg.sender, "Cannot unwhitelist self.");
        require(isWhitelisted[account], "Address not whitelisted.");
        isWhitelisted[account] = false;
        emit Unwhitelisted(account);
    }
}

contract PermissionedModerator is IModerator, ModeratorRole {
    byte internal constant STATUS_TRANSFER_FAILURE = 0x50; // Uses status codes from ERC-1066
    byte internal constant STATUS_TRANSFER_SUCCESS = 0x51;

    bytes32 internal constant ALLOWED_APPLICATION_CODE = keccak256("org.tenx.allowed");
    bytes32 internal constant FORBIDDEN_APPLICATION_CODE = keccak256("org.tenx.forbidden");

    mapping (address => Permission) public permissions; // Address-specific transfer permissions

    struct Permission {
        bool sendAllowed; // default: false
        bool receiveAllowed; // default: false
        uint256 sendTime; // block.timestamp when the sale lockup period ends and the investor can freely sell his tokens. default: 0
        uint256 receiveTime; // block.timestamp when purchase lockup period ends and investor can freely purchase tokens from others. default: 0
        uint256 expiryTime; // block.timestamp till investors KYC will be validated. After that investor need to do re-KYC. default: 0
    }

    event PermissionChanged(
        address indexed investor,
        bool sendAllowed,
        uint256 sendTime,
        bool receiveAllowed,
        uint256 receiveTime,
        uint256 expiryTime,
        address moderator
    );

    /**
    * @notice Sets transfer permissions on a specified address.
    * @param _investor Address
    * @param _sendAllowed Boolean, transfers from this address is allowed if true.
    * @param _sendTime block.timestamp only after which transfers from this address is allowed.
    * @param _receiveAllowed Boolean, transfers to this address is allowed if true.
    * @param _receiveTime block.timestamp only after which transfers to this address is allowed.
    * @param _expiryTime block.timestamp after which any transfers from this address is disallowed.
    */
    function setPermission(
        address _investor,
        bool _sendAllowed,
        uint256 _sendTime,
        bool _receiveAllowed,
        uint256 _receiveTime,
        uint256 _expiryTime) external onlyModerator {
        require(_investor != address(0), "Investor must not be a zero address.");
        require(_expiryTime > block.timestamp, "Cannot set an expired permission."); // solium-disable-line security/no-block-members
        permissions[_investor] = Permission({
            sendAllowed: _sendAllowed,
            sendTime: _sendTime,
            receiveAllowed: _receiveAllowed,
            receiveTime: _receiveTime,
            expiryTime: _expiryTime
        });
        emit PermissionChanged(_investor, _sendAllowed, _sendTime, _receiveAllowed, _receiveTime, _expiryTime, msg.sender);
    }

    /**
    * @notice Verify if an issue is allowed.
    * @param _tokenHolder address The address tokens are minted to
    * @return {
        "allowed": "Returns true if issue is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }    
    */
    function verifyIssue(address _tokenHolder, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        if (canReceive(_tokenHolder)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }    

    /**
    * @notice Verify if a transfer is allowed.
    * @param _from address The address tokens are transferred from
    * @param _to address The address tokens are transferred to
    * @return {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyTransfer(address _from, address _to, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode)
    {
        if (canSend(_from) && canReceive(_to)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    /**
    * @notice Verify if a transferFrom is allowed.
    * @param _from address The address tokens are transferred from
    * @param _to address The address tokens are transferred to
    * @return {
        "allowed": "Returns true if transferFrom is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyTransferFrom(address _from, address _to, address, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode)
    {
        if (canSend(_from) && canReceive(_to)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    /**
    * @notice Verify if a redeem is allowed.
    * @dev All redeems are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if redeem is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyRedeem(address _sender, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        if (canSend(_sender)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    /**
    * @notice Verify if a redeemFrom is allowed.
    * @dev All redeemFroms are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if redeem is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyRedeemFrom(address _sender, address _tokenHolder, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        if (canSend(_sender) && canSend(_tokenHolder)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    /**
    * @notice Verify if a controllerTransfer is allowed.
    * @dev All controllerTransfers are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }    
    */
    function verifyControllerTransfer(address, address, address, uint256, bytes calldata, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = ALLOWED_APPLICATION_CODE;
    }

    /**
    * @notice Verify if a controllerRedeem is allowed.
    * @dev All controllerRedeems are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }    
    */
    function verifyControllerRedeem(address, address, uint256, bytes calldata, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = ALLOWED_APPLICATION_CODE;
    }

    /**
    * @notice Returns true if a transfer from an address is allowed.
    * @dev p.sendTime must be a date in the past for a transfer to be allowed.
    * @param _investor Address
    * @return true if address is whitelisted to send tokens, false otherwise.
    */
    function canSend(address _investor) public view returns (bool) {
        Permission storage p = permissions[_investor];
        // solium-disable-next-line security/no-block-members
        return (p.expiryTime > block.timestamp) && p.sendAllowed && (p.sendTime <= block.timestamp);
    }

    /**
    * @notice Returns true if a transfer to an address is allowed.
    * @dev p.receiveTime must be a date in the past for a transfer to be allowed.
    * @param _investor Address
    * @return true if address is whitelisted to receive tokens, false otherwise.
    */
    function canReceive(address _investor) public view returns (bool) {
        Permission storage p = permissions[_investor];
        // solium-disable-next-line security/no-block-members
        return (p.expiryTime > block.timestamp) && p.receiveAllowed && (p.receiveTime <= block.timestamp);
    }

    /**
    * @notice Returns true if an address is send or receive timelocked.
    * @param _investor Address
    * @return true if address is timelocked, false otherwise.
    */
    function isTimelocked(address _investor) public view returns (bool) {
        Permission storage p = permissions[_investor];
        // solium-disable-next-line security/no-block-members
        return (p.receiveTime > block.timestamp) || (p.sendTime > block.timestamp);
    }
}

contract BlacklistModerator is IModerator, Blacklistable {
    byte internal constant STATUS_TRANSFER_FAILURE = 0x50; // Uses status codes from ERC-1066
    byte internal constant STATUS_TRANSFER_SUCCESS = 0x51;

    bytes32 internal constant ALLOWED_APPLICATION_CODE = keccak256("org.tenx.allowed");
    bytes32 internal constant FORBIDDEN_APPLICATION_CODE = keccak256("org.tenx.forbidden");

    function verifyIssue(address _account, uint256, bytes calldata) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        if (isAllowed(_account)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    function verifyTransfer(address _from, address _to, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        if (isAllowed(_from) && isAllowed(_to)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    function verifyTransferFrom(address _from, address _to, address _sender, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        if (isAllowed(_from) && isAllowed(_to) && isAllowed(_sender)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    function verifyRedeem(address _sender, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        if (isAllowed(_sender)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }

    function verifyRedeemFrom(address _sender, address _tokenHolder, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        if (isAllowed(_sender) && isAllowed(_tokenHolder)) {
            allowed = true;
            statusCode = STATUS_TRANSFER_SUCCESS;
            applicationCode = ALLOWED_APPLICATION_CODE;
        } else {
            allowed = false;
            statusCode = STATUS_TRANSFER_FAILURE;
            applicationCode = FORBIDDEN_APPLICATION_CODE;
        }
    }        

    function verifyControllerTransfer(address, address, address, uint256, bytes calldata, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = ALLOWED_APPLICATION_CODE;
    }

    function verifyControllerRedeem(address, address, uint256, bytes calldata, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = ALLOWED_APPLICATION_CODE;
    }

    function isAllowed(address _account) internal view returns (bool) {
        return !isBlacklisted[_account];
    }
}

contract BasicModerator is IModerator, ModeratorRole {
    byte internal constant STATUS_TRANSFER_SUCCESS = 0x51; // Uses status codes from ERC-1066
    bytes32 internal constant SUCCESS_APPLICATION_CODE = "";

    /**
    * @notice Verify if an issuance is allowed
    * @dev All issues are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if issue is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyIssue(address, uint256, bytes calldata) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = SUCCESS_APPLICATION_CODE;
    }

    /**
    * @notice Verify if a transfer is allowed.
    * @dev All transfers are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }    
    */
    function verifyTransfer(address, address, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = SUCCESS_APPLICATION_CODE;
    }

    /**
    * @notice Verify if a transferFrom is allowed.
    * @dev All transferFroms are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if transferFrom is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyTransferFrom(address, address, address, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = SUCCESS_APPLICATION_CODE;
    }

    /**
    * @notice Verify if a redeem is allowed.
    * @dev All redeems are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if redeem is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyRedeem(address, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = SUCCESS_APPLICATION_CODE;
    }

    /**
    * @notice Verify if a redeemFrom is allowed.
    * @dev All redeemFroms are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if redeem is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }
    */
    function verifyRedeemFrom(address, address, uint256, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = SUCCESS_APPLICATION_CODE;
    }   

    /**
    * @notice Verify if a controllerTransfer is allowed.
    * @dev All controllerTransfers are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }    
    */
    function verifyControllerTransfer(address, address, address, uint256, bytes calldata, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = SUCCESS_APPLICATION_CODE;
    }

    /**
    * @notice Verify if a controllerRedeem is allowed.
    * @dev All controllerRedeems are allowed by this basic moderator contract
    * @return {
        "allowed": "Returns true if transfer is allowed, returns false otherwise.",
        "statusCode": "ERC1066 status code",
        "applicationCode": "Application-specific return code"
    }    
    */
    function verifyControllerRedeem(address, address, uint256, bytes calldata, bytes calldata) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode) 
    {
        allowed = true;
        statusCode = STATUS_TRANSFER_SUCCESS;
        applicationCode = SUCCESS_APPLICATION_CODE;
    }
}


contract Moderated is ControllerRole {
    IModerator public moderator; // External moderator contract

    event ModeratorUpdated(address moderator);

    constructor(IModerator _moderator) public {
        moderator = _moderator;
    }

    /**
    * @notice Links a Moderator contract to this contract.
    * @param _moderator Moderator contract address.
    */
    function setModerator(IModerator _moderator) external onlyController {
        require(address(moderator) != address(0), "Moderator address must not be a zero address.");
        require(Address.isContract(address(_moderator)), "Address must point to a contract.");
        moderator = _moderator;
        emit ModeratorUpdated(address(_moderator));
    }
}