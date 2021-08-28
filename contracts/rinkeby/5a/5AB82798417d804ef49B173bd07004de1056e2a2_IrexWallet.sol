// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "./PubERC20Wallet.sol";
import "./CloneFactory.sol";

contract IrexWallet is CloneFactory {

    address payable [] public wallets;
    address public coldWalletAddr;
    address public deployerAddr;
    address public ownerAddr;
    address payable public implementationAddr;
    bool public locked;

    event WalletCreatedEvent(
        address addr
    );
    event OwnerChanged(
        address indexed previousAddr,
        address indexed newAddr
    );
    event DeployerChanged(
        address indexed previousAddr,
        address indexed newAddr
    );
    event ColdWalletChanged(
        address indexed previousAddr,
        address indexed newAddr
    );

    modifier onlyDeployer() {
    require(msg.sender == deployerAddr,
    "Only deployer can call this!"
    );
    _;
    }
    modifier onlyOwner() {
    require(msg.sender == ownerAddr,
    "Only owner can call this!"
    );
    _;
    }

    constructor(address payable _implementationAddr) {
        ownerAddr = msg.sender;
        deployerAddr = msg.sender;
        coldWalletAddr = msg.sender;
        implementationAddr = _implementationAddr;
        PubERC20Wallet(implementationAddr).Init(address(this));
        wallets.push(implementationAddr);
        locked = false;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        emit OwnerChanged(ownerAddr, _newOwner);
        ownerAddr = _newOwner;
    }

    function changeDeployer(address _newDeployer) external onlyOwner{
        require(_newDeployer != address(0));
        emit DeployerChanged(deployerAddr, _newDeployer);
        deployerAddr = _newDeployer;
    }

    function changeColdWallet(address _newColdWallet) external onlyOwner{
        require(_newColdWallet != address(0));
        require(!locked, "Reentrant call");
        locked = true;
        emit ColdWalletChanged(coldWalletAddr, _newColdWallet);
        coldWalletAddr = _newColdWallet;
        locked = false;
    }

    function createWallet() external onlyDeployer {
        address payable wallet = createClone(implementationAddr);
        PubERC20Wallet(wallet).Init(address(this));
        wallets.push(wallet);
        emit WalletCreatedEvent(wallet);
    }

    function createMultipleWallet(uint256 amount) external onlyDeployer {
        for (uint256 index = 0; index < amount; index++) {
        address payable wallet = createClone(implementationAddr);
        PubERC20Wallet(wallet).Init(address(this));
        wallets.push(wallet);
        emit WalletCreatedEvent(wallet);
        }
    }

    function getDeployer() public view returns (address){
        return deployerAddr;
    }

    function getColdWallet() public view returns (address){
        return coldWalletAddr;
    }

    function getOwner() public view returns (address){
        return ownerAddr;
    }
    function getLocked() public view returns (bool){
        return locked;
    }
    function getWallet(uint id) public view returns (address){
        return wallets[id];
    }
}