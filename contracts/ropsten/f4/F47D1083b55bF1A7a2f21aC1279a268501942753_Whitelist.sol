// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./interfaces/IWhitelist.sol";

contract Whitelist is IWhitelist {
    uint256 public constant BATCH_MAX_NUM = 500;

    address public whitelistAdmin;

    mapping(address => bool) private _whitelisteds;

    constructor() {
        whitelistAdmin = msg.sender;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "Whitelist: sender unauthorized");
        _;
    }

    function addWhitelisted(address account)
        external
        override
        onlyBy(whitelistAdmin)
    {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account)
        external
        override
        onlyBy(whitelistAdmin)
    {
        _removeWhitelisted(account);
    }

    function addWhitelistedBatch(address[] memory accounts)
        external
        override
        onlyBy(whitelistAdmin)
    {
        require(accounts.length > 0, "Whitelist: empty");
        require(accounts.length <= BATCH_MAX_NUM, "Whitelist: exceed max");

        for (uint256 i = 0; i < accounts.length; i++) {
            _addWhitelisted(accounts[i]);
        }
    }

    function removeWhitelistedBatch(address[] memory accounts)
        external
        override
        onlyBy(whitelistAdmin)
    {
        require(accounts.length > 0, "Whitelist: empty");
        require(accounts.length <= BATCH_MAX_NUM, "Whitelist: exceed max");

        for (uint256 i = 0; i < accounts.length; i++) {
            _removeWhitelisted(accounts[i]);
        }
    }

    function setWhitelistAdmin(address account)
        external
        onlyBy(whitelistAdmin)
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

        isWhitelisted_ = _whitelisteds[account];
    }

    function _addWhitelisted(address account) internal {
        require(account != address(0), "Whitelist: zero account");
        require(!_whitelisteds[account], "Whitelist: already whitelisted");

        _whitelisteds[account] = true;

        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        require(account != address(0), "Whitelist: zero account");
        require(_whitelisteds[account], "Whitelist: not whitelisted");

        _whitelisteds[account] = false;

        emit WhitelistedRemoved(account);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IWhitelist {
    function addWhitelisted(address account) external;

    function removeWhitelisted(address account) external;

    function addWhitelistedBatch(address[] memory accounts) external;

    function removeWhitelistedBatch(address[] memory accounts) external;

    function isWhitelisted(address account)
        external
        view
        returns (bool isWhitelisted_);

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);
}

