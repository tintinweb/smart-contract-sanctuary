pragma solidity ^0.4.24;

/**
 * @title SafeMath from Zeppelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0 || b == 0) {
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
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
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
        assert(c >= b);
        return c;
    }
}

/**
 * @title ERC20 Interface
 */
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Standard ERC20 Token
 * @dev This contract is based on Zeppelin StandardToken.sol and MonolithDAO Token.sol
 */
contract StandardERC20Token is ERC20Interface {

    using SafeMath for uint256;

    // Name of ERC20 token
    string public name;

    // Symbol of ERC20 token
    string public symbol;

    // Decimals of ERC20 token
    uint8 public decimals;

    // Total supply of ERC20 token
    uint256 internal supply;

    // Mapping of balances
    mapping(address => uint256) internal balances;

    // Mapping of approval
    mapping (address => mapping (address => uint256)) internal allowed;

    // Modifier to check the length of msg.data
    modifier onlyPayloadSize(uint256 size) {
        if(msg.data.length < size.add(4)) {
            revert();
        }
        _;
    }

    /**
    * @dev Don&#39;t accept ETH
     */
    function () public payable {
        revert();
    }

    /**
    * @dev Constructor
    *
    * @param _issuer The account who owns all tokens
    * @param _name The name of the token
    * @param _symbol The symbol of the token
    * @param _decimals The decimals of the token
    * @param _amount The initial amount of the token
    */
    constructor(address _issuer, string _name, string _symbol, uint8 _decimals, uint256 _amount) public {
        require(_issuer != address(0));
        require(bytes(_name).length > 0);
        require(bytes(_symbol).length > 0);
        require(_decimals <= 18);
        require(_amount > 0);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        supply = _amount.mul(10 ** uint256(decimals));
        balances[_issuer] = supply;
    }

    /**
    * @dev Get the total amount of tokens
    *
    * @return Total amount of tokens
    */
    function totalSupply() public view returns (uint256) {
        return supply;
    }

    /**
    * @dev Get the balance of the specified address
    *
    * @param _owner The address from which the balance will be retrieved
    * @return The balance
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
    * @dev Transfer token for a specified address
    *
    * @param _to The address of the recipient
    * @param _value The amount of token to be transferred
    * @return Whether the transfer was successful or not
    */
    function transfer(address _to, uint256 _value) onlyPayloadSize(64) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    *
    * @param _from The address of the sender
    * @param _to The address of the recipient
    * @param _value The amount of token to be transferred
    * @return Whether the transfer was successful or not
    */
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(96) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
    * To prevent attack described in https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729, 
    * approve is not allowed when the allowance of specified spender is not zero, call increaseApproval 
    * or decreaseApproval to change an allowance
    *
    * @param _spender The address of the account able to transfer the tokens
    * @param _value The amount of wei to be approved for transfer
    * @return Whether the approval was successful or not
    */
    function approve(address _spender, uint256 _value) onlyPayloadSize(64) public returns (bool) {
        require(_value > 0);
        require(allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender
    *
    * @param _owner The address of the account owning tokens
    * @param _spender The address of the account able to transfer the tokens
    * @return Amount of remaining tokens allowed to spent
    */
    function allowance(address _owner, address _spender) onlyPayloadSize(64) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender
    *
    * @param _spender The address which will spend the funds
    * @param _value The amount of tokens to increase the allowance by
    * @return Whether the approval was successful or not
    */
    function increaseApproval(address _spender, uint _value) onlyPayloadSize(64) public returns (bool) {
        require(_value > 0);

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender
    *
    * @param _spender The address which will spend the funds
    * @param _value The amount of tokens to decrease the allowance by
    * @return Whether the approval was successful or not
    */
    function decreaseApproval(address _spender, uint _value) onlyPayloadSize(64) public returns (bool) {
        require(_value > 0);

        uint256 value = allowed[msg.sender][_spender];

        if (_value >= value) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = value.sub(_value);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

/**
 * @title LongHash ERC20 Token
  */
contract LongHashERC20Token is StandardERC20Token {

    // Issuer of tokens
    address public issuer;

    // Events
    event Issuance(address indexed _from, uint256 _amount, uint256 _value);
    event Burn(address indexed _from, uint256 _amount, uint256 _value);

    // Modifier to check the issuer
    modifier onlyIssuer() {
        if (msg.sender != issuer) {
            revert();
        }
        _;
    }

    /**
    * @dev Constructor
    *
    * @param _issuer The account who owns all tokens
    * @param _name The name of the token
    * @param _symbol The symbol of the token
    * @param _decimals The decimals of the token
    * @param _amount The initial amount of the token
    */
    constructor(address _issuer, string _name, string _symbol, uint8 _decimals, uint256 _amount) 
        StandardERC20Token(_issuer, _name, _symbol, _decimals, _amount) public {
        issuer = _issuer;
    }

    /**
    * @dev Issuing tokens
    *
    * @param _amount The amount of tokens to be issued
    * @return Whether the issuance was successful or not
    */
    function issue(uint256 _amount) onlyIssuer() public returns (bool) {
        require(_amount > 0);
        uint256 value = _amount.mul(10 ** uint256(decimals));

        supply = supply.add(value);
        balances[issuer] = balances[issuer].add(value);

        emit Issuance(msg.sender, _amount, value);
        return true;
    }

    /**
    * @dev Burn tokens
    *
    * @param _amount The amount of tokens to be burned
    * @return Whether the burn was successful or not
    */
    function burn(uint256 _amount) onlyIssuer() public returns (bool) {
        uint256 value;

        require(_amount > 0);
        value = _amount.mul(10 ** uint256(decimals));
        require(supply >= value);
        require(balances[issuer] >= value);

        supply = supply.sub(value);
        balances[issuer] = balances[issuer].sub(value);

        emit Burn(msg.sender, _amount, value);
        return true;
    }

    /**
    * @dev Change the issuer of tokens
    *
    * @param _to The new issuer
    * @param _transfer Whether transfer the old issuer&#39;s tokens to new issuer
    * @return Whether the burn was successful or not
    */
    function changeIssuer(address _to, bool _transfer) onlyIssuer() public returns (bool) {
        require(_to != address(0));

        if (_transfer) {
            balances[_to] = balances[issuer];
            balances[issuer] = 0;
        }
        issuer = _to;

        return true;
    }
}