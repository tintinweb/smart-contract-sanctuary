// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "./ERC20Interface.sol";
import "./IrexWallet.sol";

contract PubERC20Wallet {
    
    address public factoryAddr;
    bool public initialized = false; 
    
    event FlushToken(
        address indexed fromAddr,
        address indexed toAddr
    );
    event FlushETH(
        address indexed fromAddr,
        address indexed toAddr
    );
    event Deposited(
        address from,
        uint256 amount
    );
    
    modifier onlyUninitialized {
        require(!initialized, 'Contract already initialized');
        _;
    }
    modifier onlyInitialized {
        require(initialized, 'Contract Not initialized');
        _;
    }
    function Init(address _factoryAddr) external onlyUninitialized{
        factoryAddr = _factoryAddr;
        initialized = true;
    }
    
    function flushToken(address tokenContractAddress) external onlyInitialized {
        IrexWallet irexWallet = IrexWallet(factoryAddr);
        bool locked = irexWallet.getLocked();
        require(!locked, "Reentrant call");
        address deployer = irexWallet.getDeployer();
        address coldWallet = irexWallet.getColdWallet();
        require(deployer == msg.sender);
        ERC20Interface token =  ERC20Interface(tokenContractAddress);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(coldWallet, amount);
        emit FlushToken(address(this), coldWallet);
    }
    
    function flushETH() external onlyInitialized{
        IrexWallet irexWallet = IrexWallet(factoryAddr);
        bool locked = irexWallet.getLocked();
        require(!locked, "Reentrant call");
        address deployer = irexWallet.getDeployer();
        address coldWallet = irexWallet.getColdWallet();
        require(deployer == msg.sender);
        
        uint256 value = address(this).balance;
        if (value == 0) {
          return;
        }
        (bool success, ) = coldWallet.call{ value: value }('');
        require(success, 'Flush failed');
        emit FlushETH(address(this), coldWallet);        
    }
    
    fallback() external payable {
        if (msg.value > 0) {
            Deposited(msg.sender, msg.value);
        }
    }
    
    receive() external payable {
        if (msg.value > 0) {
            Deposited(msg.sender, msg.value);
        }
    }
    
}