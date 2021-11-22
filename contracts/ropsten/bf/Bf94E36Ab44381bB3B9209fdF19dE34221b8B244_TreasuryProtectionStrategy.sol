/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function setGuardian(Guardian newGuardian) public {
        require(msg.sender == controller.admin(), "LOSSLESS: Not lossless admin");
        guardian = newGuardian;
        emit GuardianSet(address(newGuardian));
    }
}
contract TreasuryProtectionStrategy is StrategyBase {
    mapping(address => Protection) private protectedAddresses;

    struct Whitelist {
        mapping(address => bool) whitelist;
    }

    struct Protection {
        mapping(address => Whitelist) protection; 
    }

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
        for(uint8 i = 0; i < whitelist.length; i++) {
            protectedAddresses[token].protection[protectedAddress].whitelist[whitelist[i]] = true;
        }

        guardian.setProtectedAddress(token, protectedAddress);
    }

    // @dev Remove whitelist for protected addresss.
    function removeProtectedAddresses(address token, address[] calldata addressesToRemove) public onlyProtectionAdmin(token) {
        for(uint8 i = 0; i < addressesToRemove.length; i++) {
            delete protectedAddresses[token].protection[addressesToRemove[i]];
            guardian.removeProtectedAddresses(token, addressesToRemove[i]);
        }
    }
}