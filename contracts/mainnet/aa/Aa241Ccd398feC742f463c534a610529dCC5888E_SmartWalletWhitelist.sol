// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/// @notice Interface of the `SmartWalletChecker` contracts of the protocol
interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

/// @title SmartWalletWhitelist
/// @author Curve Finance and adapted by Angle Core Team (https://etherscan.io/address/0xca719728ef172d0961768581fdf35cb116e0b7a4#code)
/// @notice Provides functions to check whether a wallet has been verified or not to own veANGLE
contract SmartWalletWhitelist {
    /// @notice Mapping between addresses and whether they are whitelisted or not
    mapping(address => bool) public wallets;
    /// @notice Admin address of the contract
    address public admin;
    /// @notice Future admin address of the contract
    //solhint-disable-next-line
    address public future_admin;
    /// @notice Contract which works as this contract and that can whitelist addresses
    address public checker;
    /// @notice Future address to become checker
    //solhint-disable-next-line
    address public future_checker;

    event ApproveWallet(address indexed _wallet);
    event RevokeWallet(address indexed _wallet);

    /// @notice Constructor of the contract
    /// @param _admin Admin address of the contract
    constructor(address _admin) {
        require(_admin != address(0), "0");
        admin = _admin;
    }

    /// @notice Commits to change the admin
    /// @param _admin New admin of the contract
    function commitAdmin(address _admin) external {
        require(msg.sender == admin, "!admin");
        future_admin = _admin;
    }

    /// @notice Changes the admin to the admin that has been committed
    function applyAdmin() external {
        require(msg.sender == admin, "!admin");
        require(future_admin != address(0), "admin not set");
        admin = future_admin;
    }

    /// @notice Commits to change the checker address
    /// @param _checker New checker address
    /// @dev This address can be the zero address in which case there will be no checker
    function commitSetChecker(address _checker) external {
        require(msg.sender == admin, "!admin");
        future_checker = _checker;
    }

    /// @notice Applies the checker previously committed
    function applySetChecker() external {
        require(msg.sender == admin, "!admin");
        checker = future_checker;
    }

    /// @notice Approves a wallet
    /// @param _wallet Wallet to approve
    function approveWallet(address _wallet) public {
        require(msg.sender == admin, "!admin");
        wallets[_wallet] = true;

        emit ApproveWallet(_wallet);
    }

    /// @notice Revokes a wallet
    /// @param _wallet Wallet to revoke
    function revokeWallet(address _wallet) external {
        require(msg.sender == admin, "!admin");
        wallets[_wallet] = false;

        emit RevokeWallet(_wallet);
    }

    /// @notice Checks whether a wallet is whitelisted
    /// @param _wallet Wallet address to check
    /// @dev This function can also rely on another SmartWalletChecker (a `checker` to see whether the wallet is whitelisted or not)
    function check(address _wallet) external view returns (bool) {
        bool _check = wallets[_wallet];
        if (_check) {
            return _check;
        } else {
            if (checker != address(0)) {
                return SmartWalletChecker(checker).check(_wallet);
            }
        }
        return false;
    }
}