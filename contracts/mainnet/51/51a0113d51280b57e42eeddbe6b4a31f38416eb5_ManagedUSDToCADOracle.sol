// File: openzeppelin-solidity/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/access/Roles.sol

/**
 * @title Roles
 * @notice copied from openzeppelin-solidity
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/access/WhitelistAdminRole.sol



/**
 * @title WhitelistAdminRole
 * @notice copied from openzeppelin-solidity
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

// File: contracts/access/WhitelistedRole.sol



/**
 * @title WhitelistedRole
 * @notice copied from openzeppelin-solidity
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

// File: contracts/oracle/IExchangeRateOracle.sol


/**
 * @title IExchangeRateOracle
 * @notice provides interface for fetching exchange rate values onchain, underlying implementations could use different oracles.
*/
interface IExchangeRateOracle {

    /**
     * @notice return the value and the value's timestamp given a request ID
     * @dev use granularity instead of defaulting to 18 for future oracle integrations
     * @param requestId     a number that specifies the exchange rate pair
     * @return false if could not get value, true with valid value, granularity, and timestamp if could get value
     */
    function getCurrentValue(uint256 requestId) external view returns (bool, uint256, uint256, uint256);
}

// File: contracts/oracle/ManagedUSDToCADOracle.sol


/**
 * @title ManagedUSDToCADOracle
 * @notice Provides a simple USD to CAD rate, centrally managed, not backed by services like Chainlink or Tellor
*/
contract ManagedUSDToCADOracle is IExchangeRateOracle, WhitelistedRole {

    event RateUpdated(uint256 value, uint256 timestamp);

    // exchange rate stored as an integer
    uint256 public _USDToCADRate;

    // specifies how many decimal places have been converted into integer
    uint256 public _granularity;

    // specifies the time the exchange was last updated
    uint256 public _timestamp;


    constructor(uint256 value, uint256 granularity) public {
        _USDToCADRate = value;
        _granularity = granularity;
        _timestamp = block.timestamp;

        _addWhitelisted(msg.sender);
    }

    /**
     * @notice return the value and the value's timestamp given a request ID
     * @param requestId     a number that specifies the exchange rate pair, should always be 1
     * @return  success (always true), latest exchange rate, granularity, and timestamp
     */
    function getCurrentValue(uint256 requestId) external view virtual override returns (bool, uint256, uint256, uint256) {
        require(requestId == 1, "Request Id must be 1");

        return (true, _USDToCADRate, _granularity, _timestamp);
    }

    /**
     * @notice admin can update the exchange rate
     * @param requestId     a number that specifies the exchange rate pair, should always be 1
     * @param value         the new exchange rate
     * @param granularity   number of decimal places the exchange value is accurate to
     * @return  true if success
     */
    function updateValue(uint256 requestId, uint256 value, uint256 granularity) external onlyWhitelisted returns (bool) {
        require(requestId == 1, "Request Id must be 1");
        require(value > 0, "Exchange rate cannot be zero");
        require(granularity > 0, "Granularity cannot be zero");

        _USDToCADRate = value;
        _granularity = granularity;
        _timestamp = block.timestamp;

        emit RateUpdated(value, granularity);
        return true;
    }
}