// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MecenasMultisignWallet.sol";


contract MecenasMultisignWalletFactory {

    address public constant EMPTY_ADDRESS_FACTORY = address(0);

    struct Wallet {
        MecenasMultisignWallet wallet;
        address pool;
        address underlying;
    }
    
    uint public counterwallets;
    address public factoryowner;
    bool public lockfactory;
        
    mapping(address => Wallet[]) public OwnerWallets;
    Wallet[] public FactoryWallets;
     
    event ChildCreated(address indexed childAddress, address indexed pooladdress, address indexed underlyingaddress);
    event ChangeFactoryOwner(address indexed oldowner, address indexed newowner);
    event ChangeFactoryLock(bool oldlock, bool newlock);


    constructor() {
        factoryowner = msg.sender;
    }    

    
    // this function changes the factory owner address

    function changeowner(address _newowner) public {
        require(_newowner != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address oldowner = factoryowner;
        factoryowner = _newowner;
    
        emit ChangeFactoryOwner(oldowner, factoryowner);
    }


    // this function locks and unlocks de factory 
    // false = unlock
    // true = lock
    
    function changelockfactory(bool _newlock) public {
        require(_newlock == true || _newlock == false);
        require(msg.sender == factoryowner);
        bool oldlock = lockfactory;
        lockfactory = _newlock;
    
        emit ChangeFactoryLock(oldlock, lockfactory);
    }


    // this function creates a new Mecenas Multisign Wallet

    function newMecenasWallet(address _owneraddress, address _pooladdress, address _underlyingaddress) external returns (address) {
        require(lockfactory == false);
        require(_pooladdress != EMPTY_ADDRESS_FACTORY && _underlyingaddress != EMPTY_ADDRESS_FACTORY && msg.sender != EMPTY_ADDRESS_FACTORY);
        
        counterwallets++;
    
        MecenasMultisignWallet newwallet = new MecenasMultisignWallet(_owneraddress, _pooladdress, _underlyingaddress);
        
        FactoryWallets.push(Wallet(newwallet, _pooladdress, _underlyingaddress));
        OwnerWallets[_owneraddress].push(Wallet(MecenasMultisignWallet(newwallet), address(_pooladdress), address(_underlyingaddress)));

        emit ChildCreated(address(newwallet), _pooladdress, _underlyingaddress);

        return address(newwallet);
    }
    
    
    
    // this function returns an array of struct of wallets created by owner

    function getOwnerWallets(address _account) external view returns (Wallet[] memory) {
      return OwnerWallets[_account];
    } 


    // this function returns an array of struct of wallets created
    
    function getTotalWallets() external view returns (Wallet[] memory) {
      return FactoryWallets;
    }

}