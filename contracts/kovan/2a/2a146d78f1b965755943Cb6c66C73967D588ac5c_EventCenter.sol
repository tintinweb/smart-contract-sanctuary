// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccountIndexInterface {
    function owner() external view returns (address);
    function isAccount(address _address) external view returns (bool _isAccount);
}

contract EventCenter {

    event EventTest(address EOA ,address account);

    address internal accountIndex;
    
    modifier onlyAccount{
        require(accountIndex != address(0),"CHFRY: accountIndex not setup");
        require(AccountIndexInterface(accountIndex).isAccount(msg.sender), "CHFRY: only SmartAccount could emit Event");
        _;
    }

    modifier onlyOwner {
        require(accountIndex != address(0),"CHFRY: accountIndex not setup");
        require(msg.sender == AccountIndexInterface(accountIndex).owner(), "CHFRY: only AccountIndex Owner");
        _;
    }

    constructor (address _accountIndex) {
        accountIndex = _accountIndex;
    }
    
    function emitTest(address _eoa, address _account) external onlyAccount{
        emit EventTest(_eoa,_account);
    }
}