// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MecenasV2.sol";


contract MecenasFactoryV2 {

    address public constant EMPTY_ADDRESS_FACTORY = address(0);

    uint public counterpools;
    MecenasV2[] public pools;
    address[] public markets;
    address[] public tokens;

    address public factoryowner;
    address public factorydeveloper;
    address public factoryseeker;

    bool public lockfactory;

    mapping(address => MecenasV2[]) public ownerPools;
    mapping(address => address[]) public ownerMarkets;
    mapping(address => address[]) public ownerUnderlying;

    event ChildCreated(address childAddress, address indexed yield, address indexed underlying, address indexed owner, uint _mindeposit, uint _agedeposit, uint _agelottery);
    event ChangeFactoryDeveloper(address indexed olddeveloper, address indexed newdeveloper);
    event ChangeFactorySeeker(address indexed oldseeker, address indexed newseeker);
    event ChangeFactoryOwner(address indexed oldowner, address indexed newowner);
    event ChangeFactoryLock(bool oldlock, bool newlock);


    constructor(address _developer, address _seeker) {
        factoryowner = msg.sender;
        factorydeveloper = _developer;
        factoryseeker = _seeker;
        lockfactory = false;
    }    


    function changedeveloper(address _newdeveloper) public {
        require(msg.sender != EMPTY_ADDRESS_FACTORY);
        require(_newdeveloper != EMPTY_ADDRESS_FACTORY, "New developer is the zero address");
        require(msg.sender == factoryowner, "Caller is not the owner");
        address olddeveloper = factorydeveloper;
        factorydeveloper = _newdeveloper;
    
        emit ChangeFactoryDeveloper(olddeveloper, factorydeveloper);
    }


    function changeseeker(address _newseeker) public {
        require(msg.sender != EMPTY_ADDRESS_FACTORY);
        require(_newseeker != EMPTY_ADDRESS_FACTORY, "New seeker is the zero address");
        require(msg.sender == factoryowner, "Caller is not the owner");
        address oldseeker = factoryseeker;
        factoryseeker = _newseeker;
    
        emit ChangeFactorySeeker(oldseeker, factoryseeker);
    }


    function changeowner(address _newowner) public {
        require(msg.sender != EMPTY_ADDRESS_FACTORY);
        require(_newowner != EMPTY_ADDRESS_FACTORY, "New owner is the zero address");
        require(msg.sender == factoryowner, "Caller is not the owner");
        address oldowner = factoryowner;
        factoryowner = _newowner;
    
        emit ChangeFactoryOwner(oldowner, factoryowner);
    }


    function changelockfactory(bool _newlock) public {
        require(msg.sender != EMPTY_ADDRESS_FACTORY);
        require(_newlock == true || _newlock == false, "Incorrect parameters");
        require(msg.sender == factoryowner, "Caller is not the owner");
        bool oldlock = lockfactory;
        lockfactory = _newlock;
    
        emit ChangeFactoryLock(oldlock, lockfactory);
    }


    function newMecenasPool(address _yield, address _underlying, uint mindeposit, uint agedeposit, uint agelottery) external {
        require(lockfactory == false);
        require(msg.sender != EMPTY_ADDRESS_FACTORY);
        require(_yield != EMPTY_ADDRESS_FACTORY);
        require(_underlying != EMPTY_ADDRESS_FACTORY);
        
        require(mindeposit > 0);
        require(agedeposit > 0);
        require(agelottery > 0);
        
        counterpools++;
        MecenasV2 newpool = new MecenasV2(msg.sender, _yield, _underlying, factorydeveloper, factoryseeker, mindeposit, agedeposit, agelottery);
        pools.push(newpool);
        markets.push(_yield);
        tokens.push(_underlying);
        
        ownerPools[msg.sender].push(newpool);
        ownerMarkets[msg.sender].push(_yield);
        ownerUnderlying[msg.sender].push(_underlying);
        
        emit ChildCreated(address(newpool), _yield, _underlying, msg.sender, mindeposit, agedeposit, agelottery);
    }
    
    
    function getOwnerPools(address _account) external view returns (MecenasV2[] memory) {
      return ownerPools[_account];
    } 
    
    
    function getOwnerMarkets(address _account) external view returns (address[] memory) {
      return ownerMarkets[_account];
    }

    
    function getOwnerUnderlying(address _account) external view returns (address[] memory) {
      return ownerUnderlying[_account];
        
    }
    
    
    function getTotalPools() external view returns (MecenasV2[] memory) {
      return pools;
    }

    
    function getTotalMarkets() external view returns (address[] memory) {
      return markets;
    }
    
    
    function getTotalUnderlying() external view returns (address[] memory) {
      return tokens;
    }
}