pragma solidity ^0.5.16;

import "./ERC20.sol";
import "./BlackListRole.sol";
import "./Ownable.sol";

/**
 * @title KineUSD
 * @notice Kine is the platform token of Kine system.
 * @author Kine
 */
contract Kine is Ownable, ERC20, BlackListRole {
    /// @notice Kine token name
    string public name;
    /// @notice Kine token symbol
    string public symbol;
    /// @notice Kine token decimals
    uint8 public decimals;

    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint totalSupply) public {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _mint(msg.sender, totalSupply);
    }

    /**
     * @notice Transfer caller's Kine to target address
     * @param to Transfer target address
     * @param value The amount of Kine to transfer
     * @return True if transfer succeed, false if failed
     */
    function transfer(address to, uint value) public onlyNotBlacklisted(msg.sender) returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @notice Transfer source address's Kine to target address
     * @param from Source address
     * @param to Target address
     * @param value The amount of Kine to transfer
     * @return True if transfer succeed, false if failed
     */
    function transferFrom(address from, address to, uint value) public onlyNotBlacklisted(from) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /// @notice Add new account as blacklist admin member
    /// @dev Only owner can add new blacklist admin member
    function addBlacklistAdmin(address account) public onlyOwner {
        _addBlacklistAdmin(account);
    }

    /// @notice Remove account from blacklist admin members
    /// @dev Besides owner can remove admins, the blacklist admin can also renounce itself
    function removeBlacklistAdmin(address account) public onlyOwner {
        _removeBlacklistAdmin(account);
    }
}