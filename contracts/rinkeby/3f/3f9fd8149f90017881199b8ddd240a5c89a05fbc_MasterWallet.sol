// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "./ERC20Interface.sol";
import "./RonexWallet.sol";

contract MasterWallet {

    bool public initialized = false;
    address public factoryAddress;

    event SinkToken(
        address indexed fromAddr,
        address indexed toAddr
    );
    event SinkETH(
        address indexed fromAddr,
        address indexed toAddr
    );
    event Deposited(
        address from,
        uint256 amount
    );

    modifier onlyInitialized {
        require(initialized, 'Contract Not initialized');
        _;
    }
    
    modifier onlyUninitialized {
        require(!initialized, 'Contract already initialized');
        _;
    }
    
    function Init(address _factoryAddress) external onlyUninitialized{
        factoryAddress = _factoryAddress;
        initialized = true;
    }

    function sinkTokenFromContract(address tokenContractAddress) external onlyInitialized {
        RonexWallet ronexWallet = RonexWallet(factoryAddress);
        bool locked = ronexWallet.getLocked();
        require(!locked, "tokens is flushing");
        address deployer = ronexWallet.getDeployer();
        address coldWallet = ronexWallet.getColdWallet();
        require(deployer == msg.sender, 'Only deployer can flush the token!');
        ERC20Interface token =  ERC20Interface(tokenContractAddress);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(coldWallet, amount);
        emit SinkToken(address(this), coldWallet);
    }

    function sinkCurrentEtherBalance() external onlyInitialized{
        RonexWallet ronexWallet = RonexWallet(factoryAddress);
        bool locked = ronexWallet.getLocked();
        require(!locked, "ethereum is flushing");
        address deployer = ronexWallet.getDeployer();
        address coldWallet = ronexWallet.getColdWallet();
        require(deployer == msg.sender, 'Only deployer can flush the ethereum!');

        uint256 value = address(this).balance;
        if (value == 0) {
          return;
        }
        (bool success, ) = coldWallet.call{ value: value }('');
        require(success, 'Flush failed');
        emit SinkETH(address(this), coldWallet);
    }

    receive() external payable {
        if (msg.value > 0) {
            Deposited(msg.sender, msg.value);
        }
    }

    fallback() external payable {
        if (msg.value > 0) {
            Deposited(msg.sender, msg.value);
        }
    }
}