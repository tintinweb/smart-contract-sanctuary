// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Registry.sol";

contract BeforeTokenTransferHook {
    address private _minter;
    address private _settingsController;
    Registry private _burners;
    Registry private _blockedUsers;

    modifier onlySettingsController() {
        require(_settingsController == msg.sender);
        _;
    }

    /**
     * @dev Sets the values for {minter} and {settingsController}, initializes burners and blocked users registries.
     */
    constructor(
        address minter_,
        address settingsController_,
        Registry burners_,
        Registry blockedUsers_
    )  {
        _minter = minter_;
        _settingsController = settingsController_;
        _burners = burners_;
        _blockedUsers = blockedUsers_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    function execute(address from, address to, uint256 amount) public view {
        // before burn
        if (to == address(0)) {
            require(_burners.get(from), "Account is not in the burner registry");
        }

        // before mint
        if (from == address(0)) {
            require(to == _minter, "Account has no mint privilege");
        }

        require(_blockedUsers.get(from) == false, "Account is blocked");
    }

    /**
     * @dev Sets registry of the users who are not allowed to transfer tokens.
     */
    function setBlockedUsers(Registry blockedUsers_) public onlySettingsController {
        _blockedUsers = blockedUsers_;
    }

    /**
     * @dev Sets registry of the users who can burn tokens.
     */
    function setBurners(Registry burners_) public onlySettingsController {
        _burners = burners_;
    }

    /**
     * @dev Sets account who can mint tokens.
     */
    function setMinter(address minter_) public onlySettingsController {
        _minter = minter_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract Registry {
    event AddressAdded(address account);
    event AddressRemoved(address account);

    address private _owner;
    mapping(address => bool) internal _registry;

    modifier onlyOwner {
        require(_owner == msg.sender);
        _;
    }

    /**
     * @dev Sets {owner}.
     */
    constructor(address owner_) {
        _owner = owner_;
    }

    /**
     * @dev Gets `addr_` value from the registry.
     */
    function get(address _addr) public view returns (bool) {
        return _registry[_addr];
    }

    /**
     * @dev Adds `addr_` to the registry.
     */
    function add(address addr_) onlyOwner public {
        _registry[addr_] = true;
        emit AddressAdded(addr_);
    }

    /**
     * @dev Removes `addr_` from the registry.
     */
    function remove(address addr_) onlyOwner public {
        delete _registry[addr_];
        emit AddressRemoved(addr_);
    }
}

