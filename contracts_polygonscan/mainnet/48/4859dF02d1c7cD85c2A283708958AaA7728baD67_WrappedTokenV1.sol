// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./ERC1404.sol";

import "./roles/OwnerRole.sol";

import "./capabilities/Proxiable.sol";

import "./capabilities/Burnable.sol";
import "./capabilities/Mintable.sol";
import "./capabilities/Pausable.sol";
import "./capabilities/Revocable.sol";

import "./capabilities/Blacklistable.sol";
import "./capabilities/Whitelistable.sol";

import "./capabilities/RevocableToAddress.sol";

/// @title Wrapped Token V1 Contract
/// @notice The role based access controls allow the Owner accounts to determine which permissions are granted to admin
/// accounts. Admin accounts can enable, disable, and configure the token restrictions built into the contract.
/// @dev This contract implements the ERC1404 Interface to add transfer restrictions to a standard ERC20 token.
contract WrappedTokenV1 is
    Proxiable,
    ERC20Upgradeable,
    ERC1404,
    OwnerRole,
    Whitelistable,
    Mintable,
    Burnable,
    Revocable,
    Pausable,
    Blacklistable,
    RevocableToAddress
{
    AggregatorV3Interface public reserveFeed;

    // ERC1404 Error codes and messages
    uint8 public constant SUCCESS_CODE = 0;
    uint8 public constant FAILURE_NON_WHITELIST = 1;
    uint8 public constant FAILURE_PAUSED = 2;
    string public constant SUCCESS_MESSAGE = "SUCCESS";
    string public constant FAILURE_NON_WHITELIST_MESSAGE =
        "The transfer was restricted due to white list configuration.";
    string public constant FAILURE_PAUSED_MESSAGE =
        "The transfer was restricted due to the contract being paused.";
    string public constant UNKNOWN_ERROR = "Unknown Error Code";

    /// @notice The from/to account has been explicitly denied the ability to send/receive
    uint8 public constant FAILURE_BLACKLIST = 3;
    string public constant FAILURE_BLACKLIST_MESSAGE =
        "Restricted due to blacklist";

    event OracleAddressUpdated(address newAddress);

    constructor(
        string memory name,
        string memory symbol,
        AggregatorV3Interface resFeed
    ) {
        initialize(msg.sender, name, symbol, 0, resFeed, true, false);
    }

    /// @notice This method can only be called once for a unique contract address
    /// @dev Initialization for the token to set readable details and mint all tokens to the specified owner
    /// @param owner Owner address for the contract
    /// @param name Token name identifier
    /// @param symbol Token symbol identifier
    /// @param initialSupply Amount minted to the owner
    /// @param resFeed oracle contract address
    /// @param whitelistEnabled A boolean flag that enables token transfers to be white listed
    /// @param flashMintEnabled A boolean flag that enables tokens to be flash minted
    function initialize(
        address owner,
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        AggregatorV3Interface resFeed,
        bool whitelistEnabled,
        bool flashMintEnabled
    ) public initializer {
        reserveFeed = resFeed;

        ERC20Upgradeable.__ERC20_init(name, symbol);
        Mintable._mint(msg.sender, owner, initialSupply);
        OwnerRole._addOwner(owner);

        Mintable._setFlashMintEnabled(flashMintEnabled);
        Whitelistable._setWhitelistEnabled(whitelistEnabled);

        Mintable._setFlashMintFeeReceiver(owner);
    }

    /// @dev Public function to update the address of the code contract
    /// @param newAddress new implementation contract address
    function updateCodeAddress(address newAddress) external onlyOwner {
        Proxiable._updateCodeAddress(newAddress);
    }

    /// @dev Public function to update the address of the code oracle, retricted to owner
    /// @param resFeed oracle contract address
    function updateOracleAddress(AggregatorV3Interface resFeed)
        external
        onlyOwner
    {
        reserveFeed = resFeed;

        mint(msg.sender, 0);
        emit OracleAddressUpdated(address(reserveFeed));
    }

    /// @notice If the function returns SUCCESS_CODE (0) then it should be allowed
    /// @dev Public function detects whether a transfer should be restricted and not allowed
    /// @param from The sender of a token transfer
    /// @param to The receiver of a token transfer
    ///
    function detectTransferRestriction(
        address from,
        address to,
        uint256
    ) public view override returns (uint8) {
        // Restrictions are enabled, so verify the whitelist config allows the transfer.
        // Logic defined in Blacklistable parent class
        if (!checkBlacklistAllowed(from, to)) {
            return FAILURE_BLACKLIST;
        }

        // Check the paused status of the contract
        if (Pausable.paused()) {
            return FAILURE_PAUSED;
        }

        // If an owner transferring, then ignore whitelist restrictions
        if (OwnerRole.isOwner(from)) {
            return SUCCESS_CODE;
        }

        // Restrictions are enabled, so verify the whitelist config allows the transfer.
        // Logic defined in Whitelistable parent class
        if (!checkWhitelistAllowed(from, to)) {
            return FAILURE_NON_WHITELIST;
        }

        // If no restrictions were triggered return success
        return SUCCESS_CODE;
    }

    /// @notice It should return enough information for the user to know why it failed.
    /// @dev Public function allows a wallet or other client to get a human readable string to show a user if a transfer
    /// was restricted.
    /// @param restrictionCode The sender of a token transfer
    function messageForTransferRestriction(uint8 restrictionCode)
        public
        pure
        override
        returns (string memory)
    {
        if (restrictionCode == FAILURE_BLACKLIST) {
            return FAILURE_BLACKLIST_MESSAGE;
        }

        if (restrictionCode == SUCCESS_CODE) {
            return SUCCESS_MESSAGE;
        }

        if (restrictionCode == FAILURE_NON_WHITELIST) {
            return FAILURE_NON_WHITELIST_MESSAGE;
        }

        if (restrictionCode == FAILURE_PAUSED) {
            return FAILURE_PAUSED_MESSAGE;
        }

        // An unknown error code was passed in.
        return UNKNOWN_ERROR;
    }

    /// @dev Modifier that evaluates whether a transfer should be allowed or not
    /// @param from The sender of a token transfer
    /// @param to The receiver of a token transfer
    /// @param value Quantity of tokens being exchanged between the sender and receiver
    modifier notRestricted(
        address from,
        address to,
        uint256 value
    ) {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(
            restrictionCode == SUCCESS_CODE,
            messageForTransferRestriction(restrictionCode)
        );
        _;
    }

    /// @dev Public function that overrides the parent class token transfer function to enforce restrictions
    /// @param to Receiver of the token transfer
    /// @param value Amount of tokens to transfer
    /// @return success Status of the transfer
    function transfer(address to, uint256 value)
        public
        override
        notRestricted(msg.sender, to, value)
        returns (bool success)
    {
        success = ERC20Upgradeable.transfer(to, value);
    }

    /// @dev Public function that overrides the parent class token transferFrom function to enforce restrictions
    /// @param from Sender of the token transfer
    /// @param to Receiver of the token transfer
    /// @param value Amount of tokens to transfer
    /// @return success Status of the transfer
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override notRestricted(from, to, value) returns (bool success) {
        success = ERC20Upgradeable.transferFrom(from, to, value);
    }

    /// @dev Public function to recover all ether sent to this contract to an owner address
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @dev Public function to recover all tokens sent to this contract to an owner address
    /// @param token ERC20 that has a balance for this contract address
    /// @return success Status of the transfer
    function recover(IERC20Upgradeable token)
        external
        onlyOwner
        returns (bool success)
    {
        success = token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /// @dev Allow Owners to mint tokens to valid addresses
    /// @param account The account tokens will be added to
    /// @param amount The number of tokens to add to a balance
    function mint(address account, uint256 amount)
        public
        override
        onlyMinter
        returns (bool)
    {
        uint256 total = amount + ERC20Upgradeable.totalSupply();
        (, int256 answer, , , ) = reserveFeed.latestRoundData();

        uint256 decimals = ERC20Upgradeable.decimals();
        uint256 reserveFeedDecimals = reserveFeed.decimals();

        require(decimals >= reserveFeedDecimals, "invalid price feed decimals");

        require(
            (answer > 0) &&
                (uint256(answer) * 10**uint256(decimals - reserveFeedDecimals) >
                    total),
            "reserve must exceed the total supply"
        );

        return Mintable.mint(account, amount);
    }

    /// @dev Overrides the parent hook which is called ahead of `transfer` every time that method is called
    /// @param from Sender of the token transfer
    /// @param amount Amount of token being transferred
    function _beforeTokenTransfer(
        address from,
        address,
        uint256 amount
    ) internal view override {
        if (from != address(0)) {
            return;
        }

        require(
            ERC20FlashMintUpgradeable.maxFlashLoan(address(this)) > amount,
            "mint exceeds max allowed"
        );
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnerRole.sol";

/// @title WhitelisterRole Contract
/// @notice Only administrators can update the white lister roles
/// @dev Keeps track of white listers and can check if an account is authorized
contract WhitelisterRole is OwnerRole {
    event WhitelisterAdded(
        address indexed addedWhitelister,
        address indexed addedBy
    );
    event WhitelisterRemoved(
        address indexed removedWhitelister,
        address indexed removedBy
    );

    Role private _whitelisters;

    /// @dev Modifier to make a function callable only when the caller is a white lister
    modifier onlyWhitelister() {
        require(
            isWhitelister(msg.sender),
            "WhitelisterRole: caller does not have the Whitelister role"
        );
        _;
    }

    /// @dev Public function returns `true` if `account` has been granted a white lister role
    function isWhitelister(address account) public view returns (bool) {
        return _has(_whitelisters, account);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Adds an address as a white lister
    /// @param account The address that is guaranteed white lister authorization
    function _addWhitelister(address account) internal {
        _add(_whitelisters, account);
        emit WhitelisterAdded(account, msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Removes an account from being a white lister
    /// @param account The address removed as a white lister
    function _removeWhitelister(address account) internal {
        _remove(_whitelisters, account);
        emit WhitelisterRemoved(account, msg.sender);
    }

    /// @dev Public function that adds an address as a white lister
    /// @param account The address that is guaranteed white lister authorization
    function addWhitelister(address account) external onlyOwner {
        _addWhitelister(account);
    }

    /// @dev Public function that removes an account from being a white lister
    /// @param account The address removed as a white lister
    function removeWhitelister(address account) external onlyOwner {
        _removeWhitelister(account);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnerRole.sol";

/// @title RevokerRole Contract
/// @notice Only administrators can update the revoker roles
/// @dev Keeps track of revokers and can check if an account is authorized
contract RevokerRole is OwnerRole {
    event RevokerAdded(address indexed addedRevoker, address indexed addedBy);
    event RevokerRemoved(
        address indexed removedRevoker,
        address indexed removedBy
    );

    Role private _revokers;

    /// @dev Modifier to make a function callable only when the caller is a revoker
    modifier onlyRevoker() {
        require(
            isRevoker(msg.sender),
            "RevokerRole: caller does not have the Revoker role"
        );
        _;
    }

    /// @dev Public function returns `true` if `account` has been granted a revoker role
    function isRevoker(address account) public view returns (bool) {
        return _has(_revokers, account);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Adds an address as a revoker
    /// @param account The address that is guaranteed revoker authorization
    function _addRevoker(address account) internal {
        _add(_revokers, account);
        emit RevokerAdded(account, msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Removes an account from being a revoker
    /// @param account The address removed as a revoker
    function _removeRevoker(address account) internal {
        _remove(_revokers, account);
        emit RevokerRemoved(account, msg.sender);
    }

    /// @dev Public function that adds an address as a revoker
    /// @param account The address that is guaranteed revoker authorization
    function addRevoker(address account) external onlyOwner {
        _addRevoker(account);
    }

    /// @dev Public function that removes an account from being a revoker
    /// @param account The address removed as a revoker
    function removeRevoker(address account) external onlyOwner {
        _removeRevoker(account);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnerRole.sol";

/// @title PauserRole Contract
/// @notice Only administrators can update the pauser roles
/// @dev Keeps track of pausers and can check if an account is authorized
contract PauserRole is OwnerRole {
    event PauserAdded(address indexed addedPauser, address indexed addedBy);
    event PauserRemoved(
        address indexed removedPauser,
        address indexed removedBy
    );

    Role private _pausers;

    /// @dev Modifier to make a function callable only when the caller is a pauser
    modifier onlyPauser() {
        require(
            isPauser(msg.sender),
            "PauserRole: caller does not have the Pauser role"
        );
        _;
    }

    /// @dev Public function returns `true` if `account` has been granted a pauser role
    function isPauser(address account) public view returns (bool) {
        return _has(_pausers, account);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Adds an address as a pauser
    /// @param account The address that is guaranteed pauser authorization
    function _addPauser(address account) internal {
        _add(_pausers, account);
        emit PauserAdded(account, msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Removes an account from being a pauser
    /// @param account The address removed as a pauser
    function _removePauser(address account) internal {
        _remove(_pausers, account);
        emit PauserRemoved(account, msg.sender);
    }

    /// @dev Public function that adds an address as a pauser
    /// @param account The address that is guaranteed pauser authorization
    function addPauser(address account) external onlyOwner {
        _addPauser(account);
    }

    /// @dev Public function that removes an account from being a pauser
    /// @param account The address removed as a pauser
    function removePauser(address account) external onlyOwner {
        _removePauser(account);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title OwnerRole Contract
/// @notice Only administrators can update the owner roles
/// @dev Keeps track of owners and can check if an account is authorized
contract OwnerRole {
    event OwnerAdded(address indexed addedOwner, address indexed addedBy);
    event OwnerRemoved(address indexed removedOwner, address indexed removedBy);

    struct Role {
        mapping(address => bool) members;
    }

    Role private _owners;

    /// @dev Modifier to make a function callable only when the caller is an owner
    modifier onlyOwner() {
        require(
            isOwner(msg.sender),
            "OwnerRole: caller does not have the Owner role"
        );
        _;
    }

    /// @dev Public function returns `true` if `account` has been granted an owner role
    function isOwner(address account) public view returns (bool) {
        return _has(_owners, account);
    }

    /// @dev Public function that adds an address as an owner
    /// @param account The address that is guaranteed owner authorization
    function addOwner(address account) external onlyOwner {
        _addOwner(account);
    }

    /// @dev Public function that removes an account from being an owner
    /// @param account The address removed as a owner
    function removeOwner(address account) external onlyOwner {
        _removeOwner(account);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Adds an address as an owner
    /// @param account The address that is guaranteed owner authorization
    function _addOwner(address account) internal {
        _add(_owners, account);
        emit OwnerAdded(account, msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Removes an account from being an owner
    /// @param account The address removed as an owner
    function _removeOwner(address account) internal {
        _remove(_owners, account);
        emit OwnerRemoved(account, msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Give an account access to this role
    /// @param role All authorizations for the contract
    /// @param account The address that is guaranteed owner authorization
    function _add(Role storage role, address account) internal {
        require(account != address(0x0), "Invalid 0x0 address");
        require(!_has(role, account), "Roles: account already has role");
        role.members[account] = true;
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Remove an account's access to this role
    /// @param role All authorizations for the contract
    /// @param account The address that is guaranteed owner authorization
    function _remove(Role storage role, address account) internal {
        require(_has(role, account), "Roles: account does not have role");
        role.members[account] = false;
    }

    /// @dev Check if an account is in the set of roles
    /// @param role All authorizations for the contract
    /// @param account The address that is guaranteed owner authorization
    /// @return boolean
    function _has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.members[account];
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnerRole.sol";

/// @title MinterRole Contract
/// @notice Only administrators can update the minter roles
/// @dev Keeps track of minters and can check if an account is authorized
contract MinterRole is OwnerRole {
    event MinterAdded(address indexed addedMinter, address indexed addedBy);
    event MinterRemoved(
        address indexed removedMinter,
        address indexed removedBy
    );

    Role private _minters;

    /// @dev Modifier to make a function callable only when the caller is a minter
    modifier onlyMinter() {
        require(
            isMinter(msg.sender),
            "MinterRole: caller does not have the Minter role"
        );
        _;
    }

    /// @dev Public function returns `true` if `account` has been granted a minter role
    function isMinter(address account) public view returns (bool) {
        return _has(_minters, account);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Adds an address as a minter
    /// @param account The address that is guaranteed minter authorization
    function _addMinter(address account) internal {
        _add(_minters, account);
        emit MinterAdded(account, msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Removes an account from being a minter
    /// @param account The address removed as a minter
    function _removeMinter(address account) internal {
        _remove(_minters, account);
        emit MinterRemoved(account, msg.sender);
    }

    /// @dev Public function that adds an address as a minter
    /// @param account The address that is guaranteed minter authorization
    function addMinter(address account) external onlyOwner {
        _addMinter(account);
    }

    /// @dev Public function that removes an account from being a minter
    /// @param account The address removed as a minter
    function removeMinter(address account) external onlyOwner {
        _removeMinter(account);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnerRole.sol";

/// @title BurnerRole Contract
/// @notice Only administrators can update the burner roles
/// @dev Keeps track of burners and can check if an account is authorized
contract BurnerRole is OwnerRole {
    event BurnerAdded(address indexed addedBurner, address indexed addedBy);
    event BurnerRemoved(
        address indexed removedBurner,
        address indexed removedBy
    );

    Role private _burners;

    /// @dev Modifier to make a function callable only when the caller is a burner
    modifier onlyBurner() {
        require(
            isBurner(msg.sender),
            "BurnerRole: caller does not have the Burner role"
        );
        _;
    }

    /// @dev Public function returns `true` if `account` has been granted a burner role
    function isBurner(address account) public view returns (bool) {
        return _has(_burners, account);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Adds an address as a burner
    /// @param account The address that is guaranteed burner authorization
    function _addBurner(address account) internal {
        _add(_burners, account);
        emit BurnerAdded(account, msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Removes an account from being a burner
    /// @param account The address removed as a burner
    function _removeBurner(address account) internal {
        _remove(_burners, account);
        emit BurnerRemoved(account, msg.sender);
    }

    /// @dev Public function that adds an address as a burner
    /// @param account The address that is guaranteed burner authorization
    function addBurner(address account) external onlyOwner {
        _addBurner(account);
    }

    /// @dev Public function that removes an account from being a burner
    /// @param account The address removed as a burner
    function removeBurner(address account) external onlyOwner {
        _removeBurner(account);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnerRole.sol";

/// @title BlacklisterRole Contract
/// @notice Only administrators can update the black lister roles
/// @dev Keeps track of black listers and can check if an account is authorized
contract BlacklisterRole is OwnerRole {
    event BlacklisterAdded(
        address indexed addedBlacklister,
        address indexed addedBy
    );
    event BlacklisterRemoved(
        address indexed removedBlacklister,
        address indexed removedBy
    );

    Role private _Blacklisters;

    /// @dev Modifier to make a function callable only when the caller is a black lister
    modifier onlyBlacklister() {
        require(isBlacklister(msg.sender), "BlacklisterRole missing");
        _;
    }

    /// @dev Public function returns `true` if `account` has been granted a black lister role
    function isBlacklister(address account) public view returns (bool) {
        return _has(_Blacklisters, account);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Adds an address as a black lister
    /// @param account The address that is guaranteed black lister authorization
    function _addBlacklister(address account) internal {
        _add(_Blacklisters, account);
        emit BlacklisterAdded(account, msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Removes an account from being a black lister
    /// @param account The address removed as a black lister
    function _removeBlacklister(address account) internal {
        _remove(_Blacklisters, account);
        emit BlacklisterRemoved(account, msg.sender);
    }

    /// @dev Public function that adds an address as a black lister
    /// @param account The address that is guaranteed black lister authorization
    function addBlacklister(address account) external onlyOwner {
        _addBlacklister(account);
    }

    /// @dev Public function that removes an account from being a black lister
    /// @param account The address removed as a black lister
    function removeBlacklister(address account) external onlyOwner {
        _removeBlacklister(account);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../roles/WhitelisterRole.sol";

/// @title Whitelistable Contract
/// @notice Only administrators can update the white lists, and any address can only be a member of one whitelist at a
/// time
/// @dev Keeps track of white lists and can check if sender and reciever are configured to allow a transfer
contract Whitelistable is WhitelisterRole {
    // The mapping to keep track of which whitelist any address belongs to.
    // 0 is reserved for no whitelist and is the default for all addresses.
    mapping(address => uint8) public addressWhitelists;

    // The mapping to keep track of each whitelist's outbound whitelist flags.
    // Boolean flag indicates whether outbound transfers are enabled.
    mapping(uint8 => mapping(uint8 => bool)) public outboundWhitelistsEnabled;

    // Track whether whitelisting is enabled
    bool public isWhitelistEnabled;

    // Zero is reserved for indicating it is not on a whitelist
    uint8 constant NO_WHITELIST = 0;

    // Events to allow tracking add/remove.
    event AddressAddedToWhitelist(
        address indexed addedAddress,
        uint8 indexed whitelist,
        address indexed addedBy
    );
    event AddressRemovedFromWhitelist(
        address indexed removedAddress,
        uint8 indexed whitelist,
        address indexed removedBy
    );
    event OutboundWhitelistUpdated(
        address indexed updatedBy,
        uint8 indexed sourceWhitelist,
        uint8 indexed destinationWhitelist,
        bool from,
        bool to
    );
    event WhitelistEnabledUpdated(
        address indexed updatedBy,
        bool indexed enabled
    );

    /// @notice Only administrators should be allowed to update this
    /// @dev Enable or disable the whitelist enforcement
    /// @param enabled A boolean flag that enables token transfers to be white listed
    function _setWhitelistEnabled(bool enabled) internal {
        isWhitelistEnabled = enabled;
        emit WhitelistEnabledUpdated(msg.sender, enabled);
    }

    /// @notice Only administrators should be allowed to update this. If an address is on an existing whitelist, it will
    /// just get updated to the new value (removed from previous)
    /// @dev Sets an address's white list ID.
    /// @param addressToAdd The address added to a whitelist
    /// @param whitelist Number identifier for the whitelist the address is being added to
    function _addToWhitelist(address addressToAdd, uint8 whitelist) internal {
        // Verify a valid address was passed in
        require(
            addressToAdd != address(0),
            "Cannot add address 0x0 to a whitelist."
        );

        // Verify the whitelist is valid
        require(whitelist != NO_WHITELIST, "Invalid whitelist ID supplied");

        // Save off the previous white list
        uint8 previousWhitelist = addressWhitelists[addressToAdd];

        // Set the address's white list ID
        addressWhitelists[addressToAdd] = whitelist;

        // If the previous whitelist existed then we want to indicate it has been removed
        if (previousWhitelist != NO_WHITELIST) {
            // Emit the event for tracking
            emit AddressRemovedFromWhitelist(
                addressToAdd,
                previousWhitelist,
                msg.sender
            );
        }

        // Emit the event for new whitelist
        emit AddressAddedToWhitelist(addressToAdd, whitelist, msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Clears out an address's white list ID
    /// @param addressToRemove The address removed from a white list
    function _removeFromWhitelist(address addressToRemove) internal {
        // Verify a valid address was passed in
        require(
            addressToRemove != address(0),
            "Cannot remove address 0x0 from a whitelist."
        );

        // Save off the previous white list
        uint8 previousWhitelist = addressWhitelists[addressToRemove];

        // Verify the address was actually on a whitelist
        require(
            previousWhitelist != NO_WHITELIST,
            "Address cannot be removed from invalid whitelist."
        );

        // Zero out the previous white list
        addressWhitelists[addressToRemove] = NO_WHITELIST;

        // Emit the event for tracking
        emit AddressRemovedFromWhitelist(
            addressToRemove,
            previousWhitelist,
            msg.sender
        );
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Sets the flag to indicate whether source whitelist is allowed to send to destination whitelist
    /// @param sourceWhitelist The white list of the sender
    /// @param destinationWhitelist The white list of the receiver
    /// @param newEnabledValue A boolean flag that enables token transfers between white lists
    function _updateOutboundWhitelistEnabled(
        uint8 sourceWhitelist,
        uint8 destinationWhitelist,
        bool newEnabledValue
    ) internal {
        // Get the old enabled flag
        bool oldEnabledValue = outboundWhitelistsEnabled[sourceWhitelist][
            destinationWhitelist
        ];

        // Update to the new value
        outboundWhitelistsEnabled[sourceWhitelist][
            destinationWhitelist
        ] = newEnabledValue;

        // Emit event for tracking
        emit OutboundWhitelistUpdated(
            msg.sender,
            sourceWhitelist,
            destinationWhitelist,
            oldEnabledValue,
            newEnabledValue
        );
    }

    /// @notice The source whitelist must be enabled to send to the whitelist where the receive exists
    /// @dev Determine if the a sender is allowed to send to the receiver
    /// @param sender The address of the sender
    /// @param receiver The address of the receiver
    function checkWhitelistAllowed(address sender, address receiver)
        public
        view
        returns (bool)
    {
        // If whitelist enforcement is not enabled, then allow all
        if (!isWhitelistEnabled) {
            return true;
        }

        // First get each address white list
        uint8 senderWhiteList = addressWhitelists[sender];
        uint8 receiverWhiteList = addressWhitelists[receiver];

        // If either address is not on a white list then the check should fail
        if (
            senderWhiteList == NO_WHITELIST || receiverWhiteList == NO_WHITELIST
        ) {
            return false;
        }

        // Determine if the sending whitelist is allowed to send to the destination whitelist
        return outboundWhitelistsEnabled[senderWhiteList][receiverWhiteList];
    }

    /// @dev Public function that enables or disables the white list enforcement
    /// @param enabled A boolean flag that enables token transfers to be whitelisted
    function setWhitelistEnabled(bool enabled) external onlyOwner {
        _setWhitelistEnabled(enabled);
    }

    /// @notice If an address is on an existing whitelist, it will just get updated to the new value (removed from
    /// previous)
    /// @dev Public function that sets an address's white list ID
    /// @param addressToAdd The address added to a whitelist
    /// @param whitelist Number identifier for the whitelist the address is being added to
    function addToWhitelist(address addressToAdd, uint8 whitelist)
        external
        onlyWhitelister
    {
        _addToWhitelist(addressToAdd, whitelist);
    }

    /// @dev Public function that clears out an address's white list ID
    /// @param addressToRemove The address removed from a white list
    function removeFromWhitelist(address addressToRemove)
        external
        onlyWhitelister
    {
        _removeFromWhitelist(addressToRemove);
    }

    /// @dev Public function that sets the flag to indicate whether source white list is allowed to send to destination
    /// white list
    /// @param sourceWhitelist The white list of the sender
    /// @param destinationWhitelist The white list of the receiver
    /// @param newEnabledValue A boolean flag that enables token transfers between white lists
    function updateOutboundWhitelistEnabled(
        uint8 sourceWhitelist,
        uint8 destinationWhitelist,
        bool newEnabledValue
    ) external onlyWhitelister {
        _updateOutboundWhitelistEnabled(
            sourceWhitelist,
            destinationWhitelist,
            newEnabledValue
        );
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../roles/RevokerRole.sol";

/// @title RevocableToAddress Contract
/// @notice Only administrators can revoke tokens to an address
/// @dev Enables reducing a balance by transfering tokens to an address
contract RevocableToAddress is ERC20Upgradeable, RevokerRole {
    event RevokeToAddress(
        address indexed revoker,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /// @notice Only administrators should be allowed to revoke on behalf of another account
    /// @dev Revoke a quantity of token in an account, reducing the balance
    /// @param from The account tokens will be deducted from
    /// @param to The account revoked token will be transferred to
    /// @param amount The number of tokens to remove from a balance
    function _revokeToAddress(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        ERC20Upgradeable._transfer(from, to, amount);
        emit RevokeToAddress(msg.sender, from, to, amount);
        return true;
    }

    /**
    Allow Admins to revoke tokens from any address to any destination
    */

    /// @notice Only administrators should be allowed to revoke on behalf of another account
    /// @dev Revoke a quantity of token in an account, reducing the balance
    /// @param from The account tokens will be deducted from
    /// @param amount The number of tokens to remove from a balance
    function revokeToAddress(
        address from,
        address to,
        uint256 amount
    ) external onlyRevoker returns (bool) {
        return _revokeToAddress(from, to, amount);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../roles/RevokerRole.sol";

/// @title Revocable Contract
/// @notice Only administrators can revoke tokens
/// @dev Enables reducing a balance by transfering tokens to the caller
contract Revocable is ERC20Upgradeable, RevokerRole {
    event Revoke(address indexed revoker, address indexed from, uint256 amount);

    /// @notice Only administrators should be allowed to revoke on behalf of another account
    /// @dev Revoke a quantity of token in an account, reducing the balance
    /// @param from The account tokens will be deducted from
    /// @param amount The number of tokens to remove from a balance
    function _revoke(address from, uint256 amount) internal returns (bool) {
        ERC20Upgradeable._transfer(from, msg.sender, amount);
        emit Revoke(msg.sender, from, amount);
        return true;
    }

    /// @dev Allow Revokers to revoke tokens for addresses
    /// @param from The account tokens will be deducted from
    /// @param amount The number of tokens to remove from a balance
    function revoke(address from, uint256 amount)
        external
        onlyRevoker
        returns (bool)
    {
        return _revoke(from, amount);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    uint256 constant PROXIABLE_MEM_SLOT =
        0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;

    event CodeAddressUpdated(address newAddress);

    function _updateCodeAddress(address newAddress) internal {
        require(
            bytes32(PROXIABLE_MEM_SLOT) ==
                Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            // solium-disable-line
            sstore(PROXIABLE_MEM_SLOT, newAddress)
        }

        emit CodeAddressUpdated(newAddress);
    }

    function getLogicAddress() external view returns (address logicAddress) {
        assembly {
            // solium-disable-line
            logicAddress := sload(PROXIABLE_MEM_SLOT)
        }
    }

    function proxiableUUID() external pure returns (bytes32) {
        return bytes32(PROXIABLE_MEM_SLOT);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../roles/PauserRole.sol";

/// @title Pausable Contract
/// @notice Child contracts will not be pausable by simply including this module, but only once the modifiers are put in
/// place
/// @dev Contract module which allows children to implement an emergency stop mechanism that can be triggered by an
/// authorized account. This module is used through inheritance. It will make available the modifiers `whenNotPaused`
/// and `whenPaused`, which can be applied to the functions of your contract.
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    /// @dev Returns true if the contract is paused, and false otherwise.
    /// @return A boolean flag for if the contract is paused
    function paused() public view returns (bool) {
        return _paused;
    }

    /// @dev Modifier to make a function callable only when the contract is not paused
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Triggers stopped state
    function _pause() internal {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Resets to normal state
    function _unpause() internal {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @dev Public function triggers stopped state
    function pause() external onlyPauser whenNotPaused {
        Pausable._pause();
    }

    /// @dev Public function resets to normal state.
    function unpause() external onlyPauser whenPaused {
        Pausable._unpause();
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol";

import "../roles/MinterRole.sol";

/// @title Mintable Contract
/// @notice Only administrators can mint tokens
/// @dev Enables increasing a balance by minting tokens
contract Mintable is
    ERC20FlashMintUpgradeable,
    MinterRole,
    ReentrancyGuardUpgradeable
{
    event Mint(address indexed minter, address indexed to, uint256 amount);

    uint256 public flashMintFee = 0;
    address public flashMintFeeReceiver;

    bool public isFlashMintEnabled = false;

    bytes32 public constant _RETURN_VALUE =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    /// @notice Only administrators should be allowed to mint on behalf of another account
    /// @dev Mint a quantity of token in an account, increasing the balance
    /// @param minter Designated to be allowed to mint account tokens
    /// @param to The account tokens will be increased to
    /// @param amount The number of tokens to add to a balance
    function _mint(
        address minter,
        address to,
        uint256 amount
    ) internal returns (bool) {
        ERC20Upgradeable._mint(to, amount);
        emit Mint(minter, to, amount);
        return true;
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Enable or disable the flash mint functionality
    /// @param enabled A boolean flag that enables tokens to be flash minted
    function _setFlashMintEnabled(bool enabled) internal {
        isFlashMintEnabled = enabled;
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Sets the address that will receive fees of flash mints
    /// @param receiver The account that will receive flash mint fees
    function _setFlashMintFeeReceiver(address receiver) internal {
        flashMintFeeReceiver = receiver;
    }

    /// @dev Allow Owners to mint tokens to valid addresses
    /// @param account The account tokens will be added to
    /// @param amount The number of tokens to add to a balance
    function mint(address account, uint256 amount)
        public
        virtual
        onlyMinter
        returns (bool)
    {
        return Mintable._mint(msg.sender, account, amount);
    }

    /// @dev Public function to set the fee paid by the borrower for a flash mint
    /// @param fee The number of tokens that will cost to flash mint
    function setFlashMintFee(uint256 fee) external onlyMinter {
        flashMintFee = fee;
    }

    /// @dev Public function to enable or disable the flash mint functionality
    /// @param enabled A boolean flag that enables tokens to be flash minted
    function setFlashMintEnabled(bool enabled) external onlyMinter {
        _setFlashMintEnabled(enabled);
    }

    /// @dev Public function to update the receiver of the fee paid for a flash mint
    /// @param receiver The account that will receive flash mint fees
    function setFlashMintFeeReceiver(address receiver) external onlyMinter {
        _setFlashMintFeeReceiver(receiver);
    }

    /// @dev Public function that returns the fee set for a flash mint
    /// @param token The token to be flash loaned
    /// @return The fees applied to the corresponding flash loan
    function flashFee(address token, uint256)
        public
        view
        override
        returns (uint256)
    {
        require(token == address(this), "ERC20FlashMint: wrong token");

        return flashMintFee;
    }

    /// @dev Performs a flash loan. New tokens are minted and sent to the
    /// `receiver`, who is required to implement the {IERC3156FlashBorrower}
    /// interface. By the end of the flash loan, the receiver is expected to own
    /// amount + fee tokens so that the fee can be sent to the fee receiver and the
    /// amount minted should be burned before the transaction completes
    /// @param receiver The receiver of the flash loan. Should implement the
    /// {IERC3156FlashBorrower.onFlashLoan} interface
    /// @param token The token to be flash loaned. Only `address(this)` is
    /// supported
    /// @param amount The amount of tokens to be loaned
    /// @param data An arbitrary datafield that is passed to the receiver
    /// @return `true` if the flash loan was successful
    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) public override nonReentrant returns (bool) {
        require(isFlashMintEnabled, "flash mint is disabled");

        uint256 fee = flashFee(token, amount);
        _mint(address(receiver), amount);

        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) ==
                _RETURN_VALUE,
            "ERC20FlashMint: invalid return value"
        );
        uint256 currentAllowance = allowance(address(receiver), address(this));
        require(
            currentAllowance >= amount + fee,
            "ERC20FlashMint: allowance does not allow refund"
        );

        _transfer(address(receiver), flashMintFeeReceiver, fee);
        _approve(
            address(receiver),
            address(this),
            currentAllowance - amount - fee
        );
        _burn(address(receiver), amount);

        return true;
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../roles/BurnerRole.sol";

/// @title Burnable Contract
/// @notice Only administrators can burn tokens
/// @dev Enables reducing a balance by burning tokens
contract Burnable is ERC20Upgradeable, BurnerRole {
    event Burn(address indexed burner, address indexed from, uint256 amount);

    /// @notice Only administrators should be allowed to burn on behalf of another account
    /// @dev Burn a quantity of token in an account, reducing the balance
    /// @param burner Designated to be allowed to burn account tokens
    /// @param from The account tokens will be deducted from
    /// @param amount The number of tokens to remove from a balance
    function _burn(
        address burner,
        address from,
        uint256 amount
    ) internal returns (bool) {
        ERC20Upgradeable._burn(from, amount);
        emit Burn(burner, from, amount);
        return true;
    }

    /// @dev Allow Burners to burn tokens for addresses
    /// @param account The account tokens will be deducted from
    /// @param amount The number of tokens to remove from a balance
    function burn(address account, uint256 amount)
        external
        onlyBurner
        returns (bool)
    {
        return _burn(msg.sender, account, amount);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../roles/BlacklisterRole.sol";

/// @title Blacklistable Contract
/// @notice Only administrators can update the black list
/// @dev Keeps track of black lists and can check if sender and reciever are configured to allow a transfer
contract Blacklistable is BlacklisterRole {
    // The mapping to keep track if an address is black listed
    mapping(address => bool) public addressBlacklists;

    // Track whether Blacklisting is enabled
    bool public isBlacklistEnabled;

    // Events to allow tracking add/remove.
    event AddressAddedToBlacklist(
        address indexed addedAddress,
        address indexed addedBy
    );
    event AddressRemovedFromBlacklist(
        address indexed removedAddress,
        address indexed removedBy
    );
    event BlacklistEnabledUpdated(
        address indexed updatedBy,
        bool indexed enabled
    );

    /// @notice Only administrators should be allowed to update this
    /// @dev Enable or disable the black list enforcement
    /// @param enabled A boolean flag that enables token transfers to be black listed
    function _setBlacklistEnabled(bool enabled) internal {
        isBlacklistEnabled = enabled;
        emit BlacklistEnabledUpdated(msg.sender, enabled);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Sets an address's black listing status
    /// @param addressToAdd The address added to a black list
    function _addToBlacklist(address addressToAdd) internal {
        // Verify a valid address was passed in
        require(addressToAdd != address(0), "Cannot add 0x0");

        // Verify the address is on the blacklist before it can be removed
        require(!addressBlacklists[addressToAdd], "Already on list");

        // Set the address's white list ID
        addressBlacklists[addressToAdd] = true;

        // Emit the event for new Blacklist
        emit AddressAddedToBlacklist(addressToAdd, msg.sender);
    }

    /// @notice Only administrators should be allowed to update this
    /// @dev Clears out an address from the black list
    /// @param addressToRemove The address removed from a black list
    function _removeFromBlacklist(address addressToRemove) internal {
        // Verify a valid address was passed in
        require(addressToRemove != address(0), "Cannot remove 0x0");

        // Verify the address is on the blacklist before it can be removed
        require(addressBlacklists[addressToRemove], "Not on list");

        // Zero out the previous white list
        addressBlacklists[addressToRemove] = false;

        // Emit the event for tracking
        emit AddressRemovedFromBlacklist(addressToRemove, msg.sender);
    }

    /// @notice If either the sender or receiver is black listed, then the transfer should be denied
    /// @dev Determine if the a sender is allowed to send to the receiver
    /// @param sender The sender of a token transfer
    /// @param receiver The receiver of a token transfer
    function checkBlacklistAllowed(address sender, address receiver)
        public
        view
        returns (bool)
    {
        // If black list enforcement is not enabled, then allow all
        if (!isBlacklistEnabled) {
            return true;
        }

        // If either address is on the black list then fail
        return !addressBlacklists[sender] && !addressBlacklists[receiver];
    }

    /// @dev Public function that enables or disables the black list enforcement
    /// @param enabled A boolean flag that enables token transfers to be black listed
    function setBlacklistEnabled(bool enabled) external onlyOwner {
        _setBlacklistEnabled(enabled);
    }

    /// @dev Public function that allows admins to remove an address from a black list
    /// @param addressToAdd The address added to a black list
    function addToBlacklist(address addressToAdd) external onlyBlacklister {
        _addToBlacklist(addressToAdd);
    }

    /// @dev Public function that allows admins to remove an address from a black list
    /// @param addressToRemove The address removed from a black list
    function removeFromBlacklist(address addressToRemove)
        external
        onlyBlacklister
    {
        _removeFromBlacklist(addressToRemove);
    }

    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ERC1404 {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @dev Overwrite with your custom transfer restriction logic
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    function detectTransferRestriction(
        address from,
        address to,
        uint256 value
    ) public view virtual returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @dev Overwrite with your custom message and restrictionCode handling
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    function messageForTransferRestriction(uint8 restrictionCode)
        public
        view
        virtual
        returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/ERC20FlashMint.sol)

pragma solidity ^0.8.0;

import "../../../interfaces/IERC3156Upgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC3156 Flash loans extension, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * Adds the {flashLoan} method, which provides flash loan support at the token
 * level. By default there is no fee, but this can be changed by overriding {flashFee}.
 *
 * _Available since v4.1._
 */
abstract contract ERC20FlashMintUpgradeable is Initializable, ERC20Upgradeable, IERC3156FlashLenderUpgradeable {
    function __ERC20FlashMint_init() internal initializer {
        __Context_init_unchained();
        __ERC20FlashMint_init_unchained();
    }

    function __ERC20FlashMint_init_unchained() internal initializer {
    }
    bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /**
     * @dev Returns the maximum amount of tokens available for loan.
     * @param token The address of the token that is requested.
     * @return The amont of token that can be loaned.
     */
    function maxFlashLoan(address token) public view override returns (uint256) {
        return token == address(this) ? type(uint256).max - ERC20Upgradeable.totalSupply() : 0;
    }

    /**
     * @dev Returns the fee applied when doing flash loans. By default this
     * implementation has 0 fees. This function can be overloaded to make
     * the flash loan mechanism deflationary.
     * @param token The token to be flash loaned.
     * @param amount The amount of tokens to be loaned.
     * @return The fees applied to the corresponding flash loan.
     */
    function flashFee(address token, uint256 amount) public view virtual override returns (uint256) {
        require(token == address(this), "ERC20FlashMint: wrong token");
        // silence warning about unused variable without the addition of bytecode.
        amount;
        return 0;
    }

    /**
     * @dev Performs a flash loan. New tokens are minted and sent to the
     * `receiver`, who is required to implement the {IERC3156FlashBorrower}
     * interface. By the end of the flash loan, the receiver is expected to own
     * amount + fee tokens and have them approved back to the token contract itself so
     * they can be burned.
     * @param receiver The receiver of the flash loan. Should implement the
     * {IERC3156FlashBorrower.onFlashLoan} interface.
     * @param token The token to be flash loaned. Only `address(this)` is
     * supported.
     * @param amount The amount of tokens to be loaned.
     * @param data An arbitrary datafield that is passed to the receiver.
     * @return `true` is the flash loan was successful.
     */
    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) public virtual override returns (bool) {
        uint256 fee = flashFee(token, amount);
        _mint(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == _RETURN_VALUE,
            "ERC20FlashMint: invalid return value"
        );
        uint256 currentAllowance = allowance(address(receiver), address(this));
        require(currentAllowance >= amount + fee, "ERC20FlashMint: allowance does not allow refund");
        _approve(address(receiver), address(this), currentAllowance - amount - fee);
        _burn(address(receiver), amount + fee);
        return true;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance =   _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC3156.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrowerUpgradeable.sol";
import "./IERC3156FlashLenderUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrowerUpgradeable.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLenderUpgradeable {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrowerUpgradeable receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrowerUpgradeable {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}