// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MecenasV3.sol";


contract MecenasFactoryV3 {

    address public constant EMPTY_ADDRESS_FACTORY = address(0);

    struct Pool {
        MecenasV3 newpool;
        address newmarket;
        address newunderlying;
        string newnametoken;
    }
    
    mapping(address => Pool[]) public OwnerPools;
    mapping(MecenasV3 => uint) public MapPools;
    Pool[] public FactoryPools;

    uint public counterpools;

    address public factoryowner;
    address public factorydeveloper;
    address public factoryseeker;

    bool public lockfactory;

 
    event ChildCreated(address childAddress, address indexed yield, address indexed underlying, address indexed owner, uint _mindeposit, uint _agedeposit, uint _agelottery);
    event ChangeFactoryDeveloper(address indexed olddeveloper, address indexed newdeveloper);
    event ChangeFactorySeeker(address indexed oldseeker, address indexed newseeker);
    event ChangeFactoryOwner(address indexed oldowner, address indexed newowner);
    event ChangeFactoryLock(bool oldlock, bool newlock);


    constructor(address _developer, address _seeker) {
        factoryowner = msg.sender;
        factorydeveloper = _developer;
        factoryseeker = _seeker;
    }    

    
    // this function changes the factory developer address

    function changedeveloper(address _newdeveloper) public {
        require(_newdeveloper != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address olddeveloper = factorydeveloper;
        factorydeveloper = _newdeveloper;
    
        emit ChangeFactoryDeveloper(olddeveloper, factorydeveloper);
    }


    // this function changes the factory seeker address

    function changeseeker(address _newseeker) public {
        require(_newseeker != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address oldseeker = factoryseeker;
        factoryseeker = _newseeker;
    
        emit ChangeFactorySeeker(oldseeker, factoryseeker);
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


    // this function creates a nwe Mecenas pool

    function newMecenasPool(address _yield, uint mindeposit, uint agedeposit, uint agelottery) external {
        require(lockfactory == false);
        require(msg.sender != EMPTY_ADDRESS_FACTORY && _yield != EMPTY_ADDRESS_FACTORY);
        require(mindeposit > 0 && agedeposit > 0 && agelottery > 0 );
        
        counterpools++;
    
        MecenasV3 newpool = new MecenasV3(msg.sender, _yield, factorydeveloper, factoryseeker, mindeposit, agedeposit, agelottery);
    
        CreamYield marketfactory = CreamYield(_yield);
        ERC20 underlyingfactory = ERC20(marketfactory.underlying()); 
        string memory nametokenfactory = underlyingfactory.symbol();
        
        OwnerPools[msg.sender].push(Pool(MecenasV3(newpool), address(_yield), address(underlyingfactory), nametokenfactory));
        MapPools[newpool] = 1;
        FactoryPools.push(Pool(MecenasV3(newpool), address(_yield), address(underlyingfactory), nametokenfactory));
        
        emit ChildCreated(address(newpool), address(_yield), address(underlyingfactory), msg.sender, mindeposit, agedeposit, agelottery);
    }
    
    
    // this function returns an array of struct of pools created by owner
    
    function getOwnerPools(address _account) external view returns (Pool[] memory) {
      return OwnerPools[_account];
    } 


    // this function returns an array of struct of pools created
    
    function getTotalPools() external view returns (Pool[] memory) {
      return FactoryPools;
    }

}