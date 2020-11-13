// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

contract SmartWalletWhitelist {
    
    mapping(address => bool) public wallets;
    address public dao;
    address public checker;
    
    event ApproveWallet(address);
    event RevokeWallet(address);
    event SetChecker(address);
    event SetDAO(address);
    
    constructor(address _dao) public {
        dao = _dao;
    }
    
    function setDAO(address _dao) external {
        require(msg.sender == dao, "!dao");
        dao = _dao;
        
        emit SetDAO(dao);
    }
    
    function setChecker(address _checker) external {
        require(msg.sender == dao, "!dao");
        checker = _checker;
        
        emit SetChecker(checker);
    }
    
    function approveWallet(address _wallet) public {
        require(msg.sender == dao, "!dao");
        wallets[_wallet] = true;
        
        emit ApproveWallet(_wallet);
    }
    
    function revokeWallet(address _wallet) external {
        require(msg.sender == dao, "!dao");
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