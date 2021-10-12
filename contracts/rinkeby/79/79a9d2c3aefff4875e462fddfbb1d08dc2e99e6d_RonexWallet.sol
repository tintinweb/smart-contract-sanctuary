// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

import "./MasterWallet.sol";
import "./CloneFactory.sol";

contract RonexWallet is CloneFactory {

    
    address public deployerAddress;
    address public ownerAddress;
    address payable public implementationAddress;
    address payable [] public wallets;
    address public coldWalletAddress;
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
    require(msg.sender == deployerAddress,
    "Only deployer is allowed!"
    );
    _;
    }
    modifier onlyOwner() {
    require(msg.sender == ownerAddress,
    "Only Owner is allowed!"
    );
    _;
    }

    constructor(address payable _implementationAddress) {
        ownerAddress = msg.sender;
        deployerAddress = msg.sender;
        coldWalletAddress = msg.sender;
        implementationAddress = _implementationAddress;
        MasterWallet(implementationAddress).Init(address(this));
        wallets.push(implementationAddress);
        locked = false;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        emit OwnerChanged(ownerAddress, _newOwner);
        ownerAddress = _newOwner;
    }

    function changeDeployer(address _newDeployer) external onlyOwner{
        require(_newDeployer != address(0));
        emit DeployerChanged(deployerAddress, _newDeployer);
        deployerAddress = _newDeployer;
    }

    function changeColdWallet(address _newColdWallet) external onlyOwner{
        require(_newColdWallet != address(0));
        require(!locked, "There is already an attemp to change cold wallet, please wait until the previous one is finished.");
        locked = true;
        emit ColdWalletChanged(coldWalletAddress, _newColdWallet);
        coldWalletAddress = _newColdWallet;
        locked = false;
    }

    function createWallet() external onlyDeployer {
        address payable wallet = createClone(implementationAddress);
        MasterWallet(wallet).Init(address(this));
        wallets.push(wallet);
        emit WalletCreatedEvent(wallet);
    }

    function createMultipleWallet(uint256 amount) external onlyDeployer {
        for (uint256 index = 0; index < amount; index++) {
        address payable wallet = createClone(implementationAddress);
        MasterWallet(wallet).Init(address(this));
        wallets.push(wallet);
        emit WalletCreatedEvent(wallet);
        }
    }

    function getDeployer() public view returns (address){
        return deployerAddress;
    }

    function getColdWallet() public view returns (address){
        return coldWalletAddress;
    }

    function getOwner() public view returns (address){
        return ownerAddress;
    }
    function getLocked() public view returns (bool){
        return locked;
    }
    function getWallet(uint id) public view returns (address){
        return wallets[id];
    }
}