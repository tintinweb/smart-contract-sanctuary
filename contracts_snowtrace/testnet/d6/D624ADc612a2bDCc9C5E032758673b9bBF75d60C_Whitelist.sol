// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IWhitelist.sol";

contract Whitelist is IWhitelist {

    uint256 public constant BATCH_MAX_NUM = 200;

    address public governanceAccount;
    address public whitelistAdmin;

    mapping(address => uint256) private _whitelisteds;

    constructor() {
        governanceAccount = msg.sender;
        whitelistAdmin = msg.sender;
    }

    modifier onlyBy(address account) {
        require(
            msg.sender == account,
            "Whitelist: sender unauthorized"
        );
        _;
    }

    function addWhitelisted(address account, uint256 amount)
    external
    override
    onlyBy(whitelistAdmin)
    {
        _addWhitelisted(account, amount);
    }

    function removeWhitelisted(address account)
    external
    override
    onlyBy(whitelistAdmin)
    {
        _removeWhitelisted(account);
    }

    function addWhitelistedBatch(
        address[] memory accounts,
        uint256[] memory amounts
    ) external override onlyBy(whitelistAdmin) {
        require(accounts.length > 0, "Whitelist: empty");
        require(
            accounts.length <= BATCH_MAX_NUM,
            "Whitelist: exceed max"
        );
        require(
            amounts.length == accounts.length,
            "Whitelist: different length"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _addWhitelisted(accounts[i], amounts[i]);
        }
    }

    function removeWhitelistedBatch(address[] memory accounts)
    external
    override
    onlyBy(whitelistAdmin)
    {
        require(accounts.length > 0, "Whitelist: empty");
        require(
            accounts.length <= BATCH_MAX_NUM,
            "Whitelist: exceed max"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _removeWhitelisted(accounts[i]);
        }
    }

    function setGovernanceAccount(address account)
    external
    override
    onlyBy(governanceAccount)
    {
        require(account != address(0), "Whitelist: zero account");

        governanceAccount = account;
    }

    function setWhitelistAdmin(address account)
    external
    override
    onlyBy(governanceAccount)
    {
        require(account != address(0), "Whitelist: zero account");

        whitelistAdmin = account;
    }

    function isWhitelisted(address account)
    external
    view
    override
    returns (bool isWhitelisted_)
    {
        require(account != address(0), "Whitelist: zero account");

        isWhitelisted_ = _whitelisteds[account] > 0;
    }

    function whitelistedAmountFor(address account)
    external
    view
    override
    returns (uint256 whitelistedAmount)
    {
        require(account != address(0), "Whitelist: zero account");

        whitelistedAmount = _whitelisteds[account];
    }

    function _addWhitelisted(address account, uint256 amount) internal {
        require(account != address(0), "Whitelist: zero account");
        require(amount > 0, "Whitelist: zero amount");
        require(
            _whitelisteds[account] == 0,
            "Whitelist: already whitelisted"
        );

        _whitelisteds[account] = amount;

        emit WhitelistedAdded(account, amount);
    }

    function _removeWhitelisted(address account) internal {
        require(account != address(0), "Whitelist: zero account");
        require(
            _whitelisteds[account] > 0,
            "Whitelist: not whitelisted"
        );

        _whitelisteds[account] = 0;

        emit WhitelistedRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IWhitelist {
    function addWhitelisted(address account, uint256 amount) external;

    function removeWhitelisted(address account) external;

    function addWhitelistedBatch(
        address[] memory accounts,
        uint256[] memory amounts
    ) external;

    function removeWhitelistedBatch(address[] memory accounts) external;

    function setGovernanceAccount(address account) external;

    function setWhitelistAdmin(address account) external;

    function isWhitelisted(address account)
    external
    view
    returns (bool isWhitelisted_);

    function whitelistedAmountFor(address account)
    external
    view
    returns (uint256 whitelistedAmount);

    event WhitelistedAdded(address indexed account, uint256 amount);
    event WhitelistedRemoved(address indexed account);
}