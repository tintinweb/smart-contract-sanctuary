// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MecenasV3Aave.sol";


contract MecenasFactoryV3Aave {

    address public constant EMPTY_ADDRESS_FACTORY = address(0);
    LendingAddressProvider public immutable addressproviderfactory;
    
    struct Pool {
        MecenasV3Aave newpool;
        address newmarket;
        address newunderlying;
        string newnametoken;
    }
    
    mapping(address => Pool[]) public OwnerPools;
    mapping(MecenasV3Aave => uint) public MapPools;
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
        addressproviderfactory = LendingAddressProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);
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


    // this function creates a new Mecenas pool

    function newMecenasPool(address _underlying, uint mindeposit, uint agedeposit, uint agelottery) external {
        require(lockfactory == false);
        require(msg.sender != EMPTY_ADDRESS_FACTORY && _underlying != EMPTY_ADDRESS_FACTORY);
        require(mindeposit > 0 && agedeposit > 0 && agelottery > 0 );
        
        counterpools++;
    
        MecenasV3Aave newpool = new MecenasV3Aave(msg.sender, _underlying, factorydeveloper, factoryseeker, mindeposit, agedeposit, agelottery);
    
        address marketaavefactory = addressproviderfactory.getLendingPool();          
        ERC20 underlyingfactory = ERC20(_underlying); 
        string memory nametokenfactory = underlyingfactory.symbol();
        
        OwnerPools[msg.sender].push(Pool(MecenasV3Aave(newpool), marketaavefactory, _underlying, nametokenfactory));
        MapPools[newpool] = 1;
        FactoryPools.push(Pool(MecenasV3Aave(newpool), marketaavefactory, _underlying, nametokenfactory));
        
        emit ChildCreated(address(newpool), marketaavefactory, _underlying, msg.sender, mindeposit, agedeposit, agelottery);
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