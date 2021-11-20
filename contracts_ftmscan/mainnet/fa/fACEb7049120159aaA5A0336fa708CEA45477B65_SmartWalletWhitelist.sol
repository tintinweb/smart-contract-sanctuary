// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

contract SmartWalletWhitelist {
    
    mapping(address => bool) public wallets;
    address public admin;
    address public checker;
    address public future_checker;
    
    event ApproveWallet(address);
    event RevokeWallet(address);
    
    constructor(address _admin) public {
        admin = _admin;
    }
    
    function commitSetChecker(address _checker) external {
        require(msg.sender == admin, "!admin");
        future_checker = _checker;
    }

    function changeAdmin(address _admin) external {
        require(msg.sender == admin, "!admin");
        admin = _admin;
    }
    
    function applySetChecker() external {
        require(msg.sender == admin, "!admin");
        checker = future_checker;
    }
    
    function approveWallet(address _wallet) public {
        require(msg.sender == admin, "!admin");
        wallets[_wallet] = true;
        
        emit ApproveWallet(_wallet);
    }
    function revokeWallet(address _wallet) external {
        require(msg.sender == admin, "!admin");
        wallets[_wallet] = false;
        
        emit RevokeWallet(_wallet);
    }
    
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