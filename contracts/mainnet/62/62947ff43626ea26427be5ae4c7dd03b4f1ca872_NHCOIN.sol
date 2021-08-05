/**
 *Submitted for verification at Etherscan.io on 2020-09-28
*/

pragma solidity ^0.5.0;

// 'Neo Holistic Coin' token contract
// Deployed to : 0xf94b6ae487bdDee3f2C748fF2FbeE7cD00C95aFF
// Symbol      : NHC
// Name        : NHCOIN
// Total supply: 500,000,000 NHC
// Decimals    : 8

library SafeMath {
  
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
      /**
     * @dev Integer division of two numbers, truncating the quotient.
     **/
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

/**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     **/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    /**
     * @dev Adds two numbers, throws on overflow.
     **/
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address payable public owner;
      
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
     **/
   constructor() public {
      owner = msg.sender;
    
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     **/
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
    
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     **/
    function transferOwnership(address payable newOwner) public onlyOwner {
      require(newOwner != address(0));
      owner = newOwner;
      emit OwnershipTransferred(owner, newOwner);
    }
    
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 **/
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    
    /**
     * @dev total number of tokens in existence
     **/
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     **/
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     **/
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract StandardToken is ERC20, BasicToken, Ownable {
    mapping (address => mapping (address => uint256)) allowed;
    
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     **/
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender] || msg.sender == owner);
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (msg.sender !=  owner) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        
        emit Transfer(_from, _to, _value);
        return true;
    }
      /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     **/
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     **/
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     **/
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     **/
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


contract Configurable {
    uint256 public constant cap = 500000000*10**8;
    
}

contract BurnableToken is BasicToken, Ownable {
    event Burn(address indexed burner, uint256 value);
    
    function burn(uint256 _value) public onlyOwner {
        _burn(msg.sender, _value);
      }
      
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

contract NHC is StandardToken, Configurable, BurnableToken  {

    
    constructor() public {
        balances[owner] = balances[owner].add(cap);
        totalSupply_ = totalSupply_.add(cap);
        emit Transfer(address(this), owner, cap);

    }
}

contract NHCOIN is NHC {
    string public constant name = "NHCOIN";
    string public constant symbol = "NHC";
    uint32 public constant decimals = 8;
}