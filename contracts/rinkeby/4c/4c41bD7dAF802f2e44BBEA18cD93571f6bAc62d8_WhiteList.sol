// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

import "./interfaces/IWhitelist.sol";
import "./utils/Context.sol";

/**
 * @dev Implementation of the {IWhitelist} interface.
 *
 * This implementation is used for a general whitelisting of address that
 * can take part in the EDGEX eco-system.
 *
 * It provides flexibility and buffers the platform from bad actors.
 *
 * Note: Governed by a single governance address.
 */

contract WhiteList is IWhiteList, Context {
    address public governor;

    /**
     * @dev returns whether an address is whitelisted.
     */
    mapping(address => bool) private _whitelisted;

    /**
     * @dev validates the `caller`
     *
     * If `caller` is not the `governor` returns an error.
     */
    modifier onlyGovernor() {
        require(_msgSender() == governor, "Error: access denied.");
        _;
    }

    /**
     * @dev Sets the values for {governor}.
     *
     * To change the governor in later stage use the transferGovernor
     * function.
     */
    constructor(address _governor) {
        governor = _governor;
    }

    /**
     * @dev Emitted when governor is changed from one account(`from`)
     * to another account(`to`)
     *
     * Note: `from` and `to` cannot be a zero address.
     */
    event RevokeAccess(address indexed from, address indexed to);

    /**
     * @dev Emitted when an address is whitelisted.
     */
    event Whitelist(address indexed whitelistedAccount);

    /**
     * @dev Emitted when an account is blacklisted.
     */
    event Blacklist(address indexed blacklistedAccount);

    /**
     * @dev transfers the control of whitelisting to another wallet.
     *
     * Requirements:
     * `_newGovernor` should not be a zero address.
     * `caller` should be the current governor.
     *
     * returns a bool to represent the status of the transaction.
     */
    function transferGovernor(address _newGovernor)
        public
        virtual
        override
        onlyGovernor
        returns (bool)
    {
        require(
            _newGovernor != address(0),
            "Error: governor cannot be zero address"
        );

        address oldGovernor = governor;
        governor = _newGovernor;

        emit RevokeAccess(oldGovernor, _newGovernor);
        return true;
    }

    /**
     * @dev whitelist the `_user` for purchase.
     *
     * Requirements:
     * `_user` should not be a zero address.
     * `_user` should not be already whitelisted.
     *
     * returns a bool to represent the status of the transaction.
     */
    function whitelist(address _user)
        public
        virtual
        override
        onlyGovernor
        returns (bool)
    {
        require(_user != address(0), "Error: cannot whitelist zero address");

        _whitelisted[_user] = true;

        emit Whitelist(_user);
        return true;
    }

    /**
     * @dev blacklists the `user` from sale.
     *
     * Requirements:
     * `_user` should be whitelisted before.
     * `_user` cannot be a zero address.
     *
     * returns a bool to represent the status of the transaction.
     */
    function blacklist(address _user)
        public
        virtual
        override
        onlyGovernor
        returns (bool)
    {
        require(_user != address(0), "Error: cannot blacklist zero address");

        _whitelisted[_user] = false;

        emit Blacklist(_user);
        return true;
    }

    /**
     * @dev returns a bool to represent the whitelisting status of a wallet.
     *
     * true - address is whitelisted and can purchase tokens.
     * false - prevented from sale.
     */
    function whitelisted(address _user) public view override returns (bool) {
        return (_whitelisted[_user]);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/**
 * @dev interface of Whitelist Contract.
 */

interface IWhiteList {
    /**
     * @dev whitelist the `_user` for purchase.
     *
     * Requirements:
     * `_user` should not be a zero address.
     * `_user` should not be already whitelisted.
     *
     * returns a bool to represent the status of the transaction.
     */
    function whitelist(address _user) external returns (bool);

    /**
     * @dev blacklists the `user` from sale.
     *
     * Requirements:
     * `_user` should be whitelisted before.
     * `_user` cannot be a zero address.
     *
     * returns a bool to represent the status of the transaction.
     */
    function blacklist(address _user) external returns (bool);

    /**
     * @dev transfers the control of whitelisting to another wallet.
     *
     * Requirements:
     * `_newGovernor` should not be a zero address.
     * `caller` should be the current governor.
     *
     * returns a bool to represent the status of the transaction.
     */
    function transferGovernor(address _newGovernor) external returns (bool);

    /**
     * @dev returns a bool to represent the whitelisting status of a wallet.
     *
     * true - address is whitelisted and can purchase tokens.
     * false - prevented from sale.
     */
    function whitelisted(address _user) external view returns (bool);
}

// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}