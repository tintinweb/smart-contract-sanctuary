/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

pragma solidity >=0.4.22 <0.7.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable {
    address public owner;

    event OwnerLog(address indexed previousOwner, address indexed newOwner, bytes4 sig);

    constructor() public { 
        owner = msg.sender; 
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner  public {
        require(newOwner != address(0));
        emit OwnerLog(owner, newOwner, msg.sig);
        owner = newOwner;
    }
}

contract ERCPaused is Ownable, Context {

    bool public pauesed = false;

    modifier isNotPaued {
        require (!pauesed);
        _;
    }
    function stop() onlyOwner public {
        pauesed = true;
    }
    function start() onlyOwner public {
        pauesed = false;
    }
}





library SafeMath {
    
    /**
     * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
          return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_;

    /**
     * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
    */
    function _transfer(address _sender, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[_sender] = balances[_sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_sender, _to, _value);
    
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) blackList;
	
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(blackList[msg.sender] <= 0);
		return _transfer(msg.sender, _to, _value);
	}
 

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
    */
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

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
    */
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
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
    */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

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

contract PausableToken is StandardToken, ERCPaused {

    function transfer(address _to, uint256 _value) public isNotPaued returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public isNotPaued returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public isNotPaued returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public isNotPaued returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public isNotPaued returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract BChia is PausableToken {
    string public constant name = "BChia";
    string public constant symbol = "BHA";
    uint public constant decimals = 18;
    using SafeMath for uint256;

    event Burn(address indexed from, uint256 value);  
    event BurnFrom(address indexed from, uint256 value);  

    constructor (uint256 _totsupply) public {
		totalSupply_ = _totsupply.mul(1e18);
        balances[msg.sender] = totalSupply_;
    }

    function transfer(address _to, uint256 _value) isNotPaued public returns (bool) {
        if(isBlackList(_to) == true || isBlackList(msg.sender) == true) {
            revert();
        } else {
            return super.transfer(_to, _value);
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) isNotPaued public returns (bool) {
        if(isBlackList(_to) == true || isBlackList(msg.sender) == true) {
            revert();
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }
    
    function burn(uint256 value) public {
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        emit Burn(msg.sender, value);
    }
    
    function burnFrom(address who, uint256 value) public onlyOwner payable returns (bool) {
        balances[who] = balances[who].sub(value);
        balances[owner] = balances[owner].add(value);

        emit BurnFrom(who, value);
        return true;
    }
	
	function setBlackList(bool bSet, address badAddress) public onlyOwner {
		if (bSet == true) {
			blackList[badAddress] = now;
		} else {
			if ( blackList[badAddress] > 0 ) {
				delete blackList[badAddress];
			}
		}
	}
	
    function isBlackList(address badAddress) public view returns (bool) {
        if ( blackList[badAddress] > 0 ) {
            return true;
        }
        return false;
    }
}