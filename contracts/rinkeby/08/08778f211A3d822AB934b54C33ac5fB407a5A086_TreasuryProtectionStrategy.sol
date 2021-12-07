// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./StrategyBase.sol";

contract TreasuryProtectionStrategy is StrategyBase {
    mapping(address => Protection) private protectedAddresses;

    struct Whitelist {
        mapping(address => bool) whitelist;
    }

    struct Protection {
        mapping(address => Whitelist) protection; 
    }

    event WhitelistAddresses(address token, address protectedAddress, address[] whitelist, bool state);
    event RemovedWhitelistAddresses(address token, address[] addressesToRemove);

    constructor(Guardian _guardian, LosslessController _controller) StrategyBase(_guardian, _controller) {}

    // --- VIEWS ---

    function isAddressWhitelisted(address token, address protectedAddress, address whitelistedAddress) public view returns(bool) {
        return protectedAddresses[token].protection[protectedAddress].whitelist[whitelistedAddress];
    }

    // @dev Called by controller to check if transfer is allowed to happen.
    function isTransferAllowed(address token, address sender, address recipient, uint256 amount) external view {
        require(isAddressWhitelisted(token, sender, recipient), "LOSSLESS: not whitelisted");
    }

    // --- METHODS ---

    // @dev Called by project owners. Sets a whitelist for protected address.
    function setProtectedAddress(address token, address protectedAddress, address[] calldata whitelist) public onlyProtectionAdmin(token) {
        setWhitelistState(token, protectedAddress, whitelist, true);
        guardian.setProtectedAddress(token, protectedAddress);
    }

    // @dev Called by project owners. Adds or removes addresses for the whitelist of the protected address.
    function setWhitelistState(address token, address protectedAddress, address[] calldata addresses, bool state) public onlyProtectionAdmin(token) {
        for(uint8 i = 0; i < addresses.length; i++) {
            protectedAddresses[token].protection[protectedAddress].whitelist[addresses[i]] = state;
        }
        emit WhitelistAddresses(token, protectedAddress, addresses, state);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface LosslessController {
    function admin() external returns(address);

    function isAddressProtected(address token, address protectedAddress) external view returns (bool);
}

interface Guardian {
    function protectionAdmin(address token) external returns (address);

    function setProtectedAddress(address token, address guardedAddress) external;

    function removeProtectedAddresses(address token, address protectedAddress) external;
}

abstract contract StrategyBase {
    Guardian public guardian;
    LosslessController public controller;

    // --- EVENTS ---

    event GuardianSet(address indexed newGuardian);
    event Paused(address indexed token, address indexed protectedAddress);
    event Unpaused(address indexed token, address indexed protectedAddress);

    constructor(Guardian _guardian, LosslessController _controller) {
        guardian = _guardian;
        controller = _controller;
    }

    // --- MODIFIERS ---

    modifier onlyProtectionAdmin(address token) {
        require(msg.sender == guardian.protectionAdmin(token), "LOSSLESS: Not protection admin");
        _;
    }

    // --- METHODS ---

    // @dev In case guardian is changed, this allows not to redeploy strategy and just update it.
    function setGuardian(Guardian newGuardian) external {
        require(msg.sender == controller.admin(), "LOSSLESS: Not lossless admin");
        guardian = newGuardian;
        emit GuardianSet(address(newGuardian));
    }
}