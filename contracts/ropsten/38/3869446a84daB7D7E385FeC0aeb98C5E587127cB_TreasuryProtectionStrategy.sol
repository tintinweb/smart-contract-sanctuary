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
    function setProtectedAddress(address token, address protectedAddress, address[] calldata whitelist) external onlyProtectionAdmin(token) {
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