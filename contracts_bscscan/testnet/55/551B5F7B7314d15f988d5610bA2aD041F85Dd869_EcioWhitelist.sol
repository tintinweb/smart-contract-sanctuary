// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract EcioWhitelist is OwnableUpgradeable {
   
   using Counters for Counters.Counter;


   constructor(){
        __Ownable_init();
   }
   
    struct Activity { 
      uint acId;       //Activity Id
      uint startDate;  //Start Datetime
      uint endDate;    //End Datetime
      bool isEnable;   //Enable activity flag
      Counters.Counter limitUser; //Limit user register
    }
    
   //mapping(acId => mapping(registerAddress => status)
   mapping(uint => mapping(address => bool)) public activitiesRegisteredUser;
   
   
   mapping(uint256 => address[])  public activitiesUsers; 
   
   
   //mapping(acId => mapping(referralAddress => totalScore)
   mapping(uint => mapping(address => Counters.Counter)) public activityReferralScore;
    
   
   mapping(uint => Activity) public activities;
    
    
   Counters.Counter private acId;
    
    modifier isEnable(uint _acId) {
      require(activities[_acId].isEnable, "This activity is disabled.");
       _;
    }
    
    modifier isNoNore(uint _acId) {
      require(activities[_acId].limitUser.current() > 0,"This activity quota is no more.");
       _;
      
    }
    
    modifier isTimeup(uint _acId) {
      require (
          activities[_acId].startDate <= block.timestamp && activities[_acId].endDate >= block.timestamp,
      "This activity is time up.");
         _;
    
    }
    
   function createActivity(uint _limitUser,uint _start, uint _end, bool _isEnable) public onlyOwner {
       
        activities[acId.current()].acId =  acId.current();
        activities[acId.current()].limitUser._value = _limitUser;
        activities[acId.current()].startDate = _start;
        activities[acId.current()].endDate = _end;
        activities[acId.current()].isEnable = _isEnable;
        acId.increment();
       
   } 

   function enableActivity(uint _acId, bool _isEnable) public onlyOwner {
       activities[_acId].isEnable = _isEnable;
   }

   function hasRegister(uint _acId, address _address) public view virtual returns (bool) {
        return activitiesRegisteredUser[_acId][_address];
   }

   function registerWhitelist(uint _acId, address _referralAddress) external isTimeup(_acId) isNoNore(_acId) isEnable(_acId) {
         
        //Prevent duplicate register
        require(!activitiesRegisteredUser[_acId][msg.sender],"Your address has registered");
         
        //Register
        activitiesRegisteredUser[_acId][msg.sender] = true;
        
        activitiesUsers[_acId].push(msg.sender);
         
        //Increase referral score
        if(_referralAddress != address(0)){
             activityReferralScore[_acId][_referralAddress].increment();
         }
         
        //Decrease
        activities[_acId].limitUser.decrement();
   }
   
   function referralScore(uint _acId, address _referralAddress) public view virtual returns (uint){
       return activityReferralScore[_acId][_referralAddress].current();
   }
   
    function getFristRegister(uint _acId, uint limit)  
        public
        view
        virtual
        returns (address[] memory)
    {
      
      
        address[] memory accounts = new address[](limit);

        for (uint256 i = 0; i < activitiesUsers[_acId].length; ++i) {
            
            address _address =  activitiesUsers[_acId][i];
            
            accounts[i] = _address;
            
           if(i == limit - 1){
               break;
           }
        }

        return accounts;
    }
    
   function getTopScore(uint _acId)  
        public
        view
        virtual
        returns (uint256[] memory, address[] memory)
    {
      
        uint256[] memory scores   = new uint256[](activitiesUsers[_acId].length);
        address[] memory accounts = new address[](activitiesUsers[_acId].length);

        for (uint256 i = 0; i < activitiesUsers[_acId].length; ++i) {
            
            address _address =  activitiesUsers[_acId][i];
            
            accounts[i] = _address;
            
            scores[i]   = activityReferralScore[_acId][_address].current();
           
        }

        return (scores, accounts);
    }
 
 
    function getRandom(uint _acId, uint limit)  
        public
        view
        virtual
        returns (address[] memory)
    {
      
      
        address[] memory accounts = new address[](limit);

        for (uint256 i = 0; i < activitiesUsers[_acId].length; ++i) {
            
            address _address =  activitiesUsers[_acId][i];
            
            accounts[i] = _address;
            
           if(i == limit - 1){
               break;
           }
        }

        return accounts;
    }
    
     function getAll(uint _acId)  
        public
        view
        virtual
        returns (uint256[] memory, address[] memory)
    {
      
        uint256[] memory scores   = new uint256[](activitiesUsers[_acId].length);
        address[] memory accounts = new address[](activitiesUsers[_acId].length);

        for (uint256 i = 0; i < activitiesUsers[_acId].length; ++i) {
            
            address _address =  activitiesUsers[_acId][i];
            
            accounts[i] = _address;
            
            scores[i]   = activityReferralScore[_acId][_address].current();
           
        }

        return (scores, accounts);
    }

   
   
   
   
   
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

