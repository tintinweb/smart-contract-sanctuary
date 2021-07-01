pragma solidity 0.5.4;

import "./lib/Ownable.sol";
import "./lib/SafeMath.sol";

/**
 * @title Contract for Rewards Token
 * Copyright 2021
 */

contract Local2Token is Ownable {
    using SafeMath for uint;

    string public constant symbol = 'Local2';
    string public constant name = 'Local2';
    uint8 public constant decimals = 18;

    uint256 public constant hardCap = 5 * (10 ** (18 + 8)) ; //500M tokens. Max amount of tokens which can be minted
    uint256 public totalSupply;

    bool public mintingFinished = false;
    bool public frozen = true;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event NewToken(address indexed _token);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _burner, uint _burnedAmount);
    event Revoke(address indexed _from, uint256 _value);
    event MintFinished();
    event MintStarted();
    event Freeze();
    event Unfreeze();

    modifier canMint() {
        require(!mintingFinished, "Minting was already finished");
        _;
    }

    modifier canTransfer() {
        require(msg.sender == owner || !frozen, "Tokens could not be transferred");
        _;
    }

    constructor () public {
        emit NewToken(address(this));
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        require(_to != address(0), "Address should not be zero");
        require(totalSupply.add(_amount) <= hardCap);

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public onlyOwner returns (bool) {
        require(!mintingFinished);
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /**
     * @dev Function to start minging new tokens.
     * @return True if the operation was successful
     */
    function startMinting() public onlyOwner returns (bool) {
        require(mintingFinished);
        mintingFinished = false;
        emit MintStarted();
        return true;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
        require(_to != address(0), "Address should not be zero");
        require(_value <= balances[msg.sender], "Insufficient balance");

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool) {
        require(_to != address(0), "Address should not be zero");
        require(_value <= balances[_from], "Insufficient Balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient Allowance");

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
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
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /** 
     * @dev Burn tokens from an address
     * @param _burnAmount The amount of tokens to burn
     */
    function burn(uint _burnAmount) public {
        require(_burnAmount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_burnAmount);
        totalSupply = totalSupply.sub(_burnAmount);
        emit Burned(msg.sender, _burnAmount);
    }

    /**
     * @dev Revokes minted tokens
     * @param _from The address whose tokens are revoked
     * @param _value The amount of token to revoke
     */
    function revoke(address _from, uint256 _value) public onlyOwner returns (bool) {
        require(_value <= balances[_from]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Revoke(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }

    /**
     * @dev Freeze tokens
     */
    function freeze() public onlyOwner {
        require(!frozen);
        frozen = true;
        emit Freeze();
    }

    /**
     * @dev Unfreeze tokens 
     */
    function unfreeze() public onlyOwner {
        require(frozen);
        frozen = false;
        emit Unfreeze();
    }
}

pragma solidity 0.5.4;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

pragma solidity 0.5.4;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}