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
 * @title Basic token
 * @dev Basic version of StandardToken.
 */
contract BasicToken {
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
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_balances[msg.sender] >= _value);
        
        _balances[msg.sender] =_balances[msg.sender].sub(_value);
        _balances[_to] =_balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
  
}

contract DBToken is BasicToken,owned {
    string  constant public symbol = "DB";
    string  constant public name = "Digital Block";
    uint256 constant public decimals =6; 
    uint256 public lockedCounts = 8*(10**8)*(10**6);
    uint256 public eachUnlockCounts = 2*(10**8)*(10**6);
    //crowdSale end time, May/10/2018
    uint256 public startTime = 1525881600;

    struct LockStruct {
        uint256 unlockTime;
        bool locked;
    }

    LockStruct[] public unlockTimeMap;

    function DBToken() public {
        _supply =50*(10**8)*(10**6);
        _balances[0x01] = lockedCounts;
         _balances[msg.sender] =_supply.sub(lockedCounts);

        // November/10/2018
        unlockTimeMap.push(LockStruct({unlockTime:1541779200, locked: true})); 
        // May/10/2019
        unlockTimeMap.push(LockStruct({unlockTime:1557417600, locked: true})); 
        // November/10/2019
        unlockTimeMap.push(LockStruct({unlockTime:1573315200, locked: true})); 
        // May/10/2020
        unlockTimeMap.push(LockStruct({unlockTime:1589040000, locked: true})); 
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require (now >= startTime);

        return super.transfer(_to, _value);
    }

    function distribute(address _to, uint256 _value) onlyOwner public returns (bool) {

        return super.transfer(_to, _value);
    }

    /**
     * @dev unlock , only can be called by owner.
     */
    function unlock(uint256 _index) onlyOwner public {
        require(_index>=0 && _index<unlockTimeMap.length);
        require(now >= unlockTimeMap[_index].unlockTime && unlockTimeMap[_index].locked);
        require(_balances[0x01] >= eachUnlockCounts);

        _balances[0x01] =_balances[0x01].sub(eachUnlockCounts);
        _balances[owner] =_balances[owner].add(eachUnlockCounts);

        lockedCounts =lockedCounts.sub(eachUnlockCounts);
        unlockTimeMap[_index].locked = false;

        emit Transfer(0x01, owner, eachUnlockCounts);
    }
}