pragma solidity ^0.4.22;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);
    function transferFrom(address, address, uint256) public returns (bool);
    function approve(address, uint256) public returns (bool);
    function allowance(address, address) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Owned {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // allow transfer of ownership to another address in case shit hits the fan. 
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    
    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
	    require(_to != address(0));
	    require(_value <= balances[_from]);
	    require(_value <= allowed[_from][msg.sender]);

	    balances[_from] = balances[_from].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
	    emit Transfer(_from, _to, _value);
	    return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    


    function approve(address _spender, uint256 _value) public returns (bool success) {
        // Added to prevent potential race attack.
        // forces caller of this function to ensure address allowance is already 0
        // ref: https://github.com/ethereum/EIPs/issues/738
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

//token contract
contract GalaxiumCoin is Owned, StandardToken {
    
    event Burn(address indexed burner, uint256 value);
    
    /* Public variables of the token */
    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    uint256 public totalSupply;
    address public distributionAddress;
    bool public isTransferable = false;
    

    function GalaxiumCoin() {
        name = "Galaxium Coin";                          
        decimals = 18; 
        symbol = "GXM";
        totalSupply = 50000000 * 10 ** uint256(decimals); 
        owner = msg.sender;

        //transfer all to handler address
        balances[msg.sender] = totalSupply;
        emit Transfer(0x0, msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferable);
        return super.transfer(_to, _value);
    } 

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferable);
        return super.transferFrom(_from, _to, _value);
    } 

    /**
     * Get totalSupply of tokens - Minus any from address 0 if that was used as a burnt method
     * Suggested way is still to use the burnSent function
     */    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    /**
     * unlocks tokens, only allowed once
     */
    function enableTransfers() public onlyOwner {
        isTransferable = true;
    }
    
    /**
     * Callable by anyone
     * Accepts an input of the number of tokens to be burnt held by the sender.
     */
    function burnSent(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }

    /**
     * Allow distribution helper to help with distributeToken function
     */
    function setDistributionAddress(address _setAddress) public onlyOwner {
        distributionAddress = _setAddress;
    }

    /**
     * Called by owner to transfer tokens - Managing manual distribution.
     * Also allow distribution contract to call for this function
     */
    function distributeTokens(address _to, uint256 _value) public {
        require(distributionAddress == msg.sender || owner == msg.sender);
        super.transfer(_to, _value);
    }
}