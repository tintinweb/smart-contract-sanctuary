pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev Adds onlyOwner modifier. Subcontracts should implement checkOwner to check if caller is owner.
 */
contract Ownable {
    modifier onlyOwner() {
        checkOwner();
        _;
    }

    function checkOwner() internal;
}

/**
 * @title Read-only ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ReadOnlyToken {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function allowance(address owner, address spender) public constant returns (uint256);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract Token is ReadOnlyToken {
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MintableToken is Token {
    event Mint(address indexed to, uint256 amount);

    function mint(address _to, uint256 _amount) public returns (bool);
}

/**
 * @title Secured
 * @dev Adds only(role) modifier. Subcontracts should implement checkRole to check if caller is allowed to do action.
 */
contract Secured {
    modifier only(string role) {
        require(msg.sender == getRole(role));
        _;
    }

    function getRole(string role) constant public returns (address);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev this version copied from zeppelin-solidity, constant changed to pure
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract ReadOnlyTokenImpl is ReadOnlyToken {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract TokenImpl is Token, ReadOnlyTokenImpl {
  using SafeMath for uint256;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emitTransfer(msg.sender, _to, _value);
    return true;
  }

  function emitTransfer(address _from, address _to, uint256 _value) internal {
    emit Transfer(_from, _to, _value);
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
    emitTransfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract MintableTokenImpl is Ownable, Secured, TokenImpl, MintableToken {
    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) only("minter") public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emitMint(_to, _amount);
        emitTransfer(address(0), _to, _amount);
        return true;
    }

    function emitMint(address _to, uint256 _value) internal {
        emit Mint(_to, _value);
    }
}

/**
 * @title OwnableImpl
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnableImpl is Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function OwnableImpl() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function checkOwner() internal {
        require(msg.sender == owner);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract SecuredImpl is Ownable, Secured {
        mapping(string => address) users;
        event RoleTransferred(address indexed previousUser, address indexed newUser, string role);

        function getRole(string role) constant public returns (address) {
                return users[role];
        }

        function transferRole(string role, address to) onlyOwner public {
                require(to != address(0));
                emit RoleTransferred(users[role], to, role);
                users[role] = to;
        }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

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
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is Pausable, TokenImpl {

        function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
                return super.transfer(_to, _value);
        }

        function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
                return super.transferFrom(_from, _to, _value);
        }

        function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
                return super.approve(_spender, _value);
        }

        function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
                return super.increaseApproval(_spender, _addedValue);
        }

        function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
                return super.decreaseApproval(_spender, _subtractedValue);
        }
}

contract BurnableToken is Token {
        event Burn(address indexed burner, uint256 value);
        function burn(uint256 _value) public;
}

contract BurnableTokenImpl is TokenImpl, BurnableToken {
        /**
         * @dev Burns a specific amount of tokens.
         * @param _value The amount of token to be burned.
         */
        function burn(uint256 _value) public {
                require(_value <= balances[msg.sender]);
                // no need to require value <= totalSupply, since that would imply the
                // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

                address burner = msg.sender;
                balances[burner] = balances[burner].sub(_value);
                totalSupply = totalSupply.sub(_value);
                emit Burn(burner, _value);
        }
}

contract DemoToken is OwnableImpl, SecuredImpl, PausableToken, MintableTokenImpl, BurnableTokenImpl {
        string public constant name = "Demo Token";
        string public constant symbol = "DEMO1";
        uint8 public constant decimals = 18;

        function burn(uint256 _value) public whenNotPaused {
                super.burn(_value);
        }
}