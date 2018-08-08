pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title owned
 * @dev The owned contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


/**
 * @title Controlled
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Controlled is owned {

  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
  }
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken.
 */
contract BasicToken is Controlled{
    using SafeMath for uint256;
    
    uint256       _supply;
    mapping (address => uint256)    _balances;
    
    event Transfer( address indexed from, address indexed to, uint256 value);

    function BasicToken() public {    }
    
    function totalSupply() public view returns (uint256) {
        return _supply;
    }
    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }
    
    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_balances[msg.sender] >= _value && _value > 0);
        
        _balances[msg.sender] =_balances[msg.sender].sub(_value);
        _balances[_to] =_balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
  
}

contract AicToken is BasicToken {
    string  constant public symbol = "AIC";
    string  constant public name = "AicBlock";
    uint256 constant public decimals = 18;
    uint256 public lockedCounts = 0;

    struct LockStruct {
        uint256 unlockTime;
        bool locked;
    }
    
    uint256[][] public unlockCountArray;
    address[] public addressArray;
    LockStruct[] public unlockTimeMap;

    function AicToken() public {
        
        _supply = 10*(10**8)*(10**18);
        _balances[0x01] = _supply;
        lockedCounts = _supply;
        
        //2018
        unlockTimeMap.push(LockStruct({unlockTime:1527782400, locked: true})); 
        unlockTimeMap.push(LockStruct({unlockTime:1535731200, locked: true})); 
        unlockTimeMap.push(LockStruct({unlockTime:1543593600, locked: true})); 
        //2019
        unlockTimeMap.push(LockStruct({unlockTime:1551369600, locked: true})); 
        unlockTimeMap.push(LockStruct({unlockTime:1559318400, locked: true})); 
        unlockTimeMap.push(LockStruct({unlockTime:1567267200, locked: true})); 
        unlockTimeMap.push(LockStruct({unlockTime:1575129600, locked: true})); 
        //2020
        unlockTimeMap.push(LockStruct({unlockTime:1582992000, locked: true})); 
        unlockTimeMap.push(LockStruct({unlockTime:1590940800, locked: true})); 
        unlockTimeMap.push(LockStruct({unlockTime:1598889600, locked: true}));
        unlockTimeMap.push(LockStruct({unlockTime:1606752000, locked: true}));
        
        unlockCountArray = new uint256[][](7);
        unlockCountArray[0] = [28000000,10500000,10500000,10500000,10500000,0,0,0,0,0,0];
        unlockCountArray[1] = [70000000,17500000,17500000,17500000,17500000,0,0,0,0,0,0];
        unlockCountArray[2] = [168000000,18000000,18000000,18000000,18000000,0,0,0,0,0,0];
        unlockCountArray[3] = [0,0,25000000,0,25000000,0,0,0,0,0,0];
        unlockCountArray[4] = [0,0,20000000,0,20000000,0,20000000,0,20000000,0,20000000];
        unlockCountArray[5] = [0,0,50000000,0,50000000,0,50000000,0,50000000,0,50000000];
        unlockCountArray[6] = [0,15000000,15000000,15000000,15000000,15000000,15000000,15000000,15000000,15000000,15000000];
    
    }
  
    
    function setAddressArr(address[] self) onlyOwner public {
        //Only call once
        require(unlockTimeMap[0].locked);
        require (self.length==7);
        
        addressArray = new address[](self.length);
        for (uint i = 0; i < self.length; i++){
           addressArray[i]=self[i]; 
        }
    
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require (now >= unlockTimeMap[0].unlockTime);

        return super.transfer(_to, _value);
    }

     /**
     * @dev unlock , only can be called by owner.
     */
    function unlock(uint256 _index) onlyOwner public {
         
        require (addressArray.length == 7);
        require(_index >= 0 && _index < unlockTimeMap.length);
        require(now >= unlockTimeMap[_index].unlockTime && unlockTimeMap[_index].locked);

        for (uint _addressIndex = 0; _addressIndex < addressArray.length; _addressIndex++) {
            
          uint256 unlockCount = unlockCountArray[_addressIndex][_index].mul(10**18);

          require(_balances[0x01] >= unlockCount);

          _balances[addressArray[_addressIndex]] = _balances[addressArray[_addressIndex]].add(unlockCount);
          _balances[0x01] = _balances[0x01].sub(unlockCount);
          
          lockedCounts = lockedCounts.sub(unlockCount);

          emit Transfer(0x01, addressArray[_addressIndex], unlockCount);  
        }

        unlockTimeMap[_index].locked = false;
    }
  
}