pragma solidity ^0.4.25;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * Original source: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
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
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
       // Don&#39;t `assert(b > 0)` because Solidity automatically throws when dividing by 0 since version 0.4.
       
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
        // Don&#39;t `assert(c>=a && c>=b)` because addition is commutative (and it costs more gas).
        // Cf. https://ethereum.stackexchange.com/questions/15258/safemath-safe-add-function-assertions-against-overflows
        assert(c >= a);
    
        return c;
    }
}

/**
 * @title ERC Token Standard #20 Interface
 *
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20Interface {

    //
    // Functions
    //

    /**
     * @dev Get the total token supply.
     *
     * @return The total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256 __totalSupply);

    /**
     * @dev Gets the balance of a specified address.
     *
     * @param _who The address to query the balance of.
     * @return The amount owned by the passed address.
     */
    function balanceOf(address _who) public view returns (uint256 balance);

    /**
     * @dev Transfer an amount of tokens to a specified address.
     * @dev This function must fire the `Transfer` event.
     * @dev This function should throw an exception if the sender account balance does not have enough tokens to spend.
     *
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @return The success of the operation.
     */
    function transfer(address _to, uint256 _value) public returns (bool success);

    /**
     * @dev Transfer an amount of tokens from one address to another.
     * The transferFrom method is used for a withdraw workflow, allowing contracts to send tokens on your behalf,
     * for example to "deposit" to a contract address and/or to charge fees in sub-currencies;
     * the command should fail unless the _from account has deliberately authorized the sender of the message via some mechanism
     * (Cf approve and allowance functions).
     *
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     * @return the success of the operation.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @dev If this function is called again it overwrites the current allowance with _value.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     * @return the success of the operation.
     */
    function approve(address _spender, uint256 _value) public returns (bool success);

    /**
     * @dev Returns the amount of tokens which a spender is allowed to withdraw from an owner.
     *
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return The amount of tokens available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 availableTokens);


    //
    // Events
    //

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);

    // Triggered whenever approve function is called.
    event Approval(address indexed _tokenOwner, address indexed _spender, uint256 _tokens);
}

/** 
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 */
contract ERC20 is ERC20Interface {

    using SafeMath for uint256;

    // The name of the token (e.g. &#39;Crypto20&#39;, &#39;Golem Network Token&#39;, &#39;Bancor Network Token&#39;...)
    string public name;

    // The ticker of the token (e.g. C20, GNT, BNT...)
    string public symbol;

    // How divisible a token can be, from 0 (not at all divisible) to 18 (pretty much continuous).
    // Technically speaking, the decimals value is the number of digits that come after the decimal place when
    // displaying token values on-screen.
    // The reason that decimals exists is that Ethereum does not deal with decimal numbers, representing all numeric
    // values as integers
    uint8 public decimals;

    // The total number of tokens in existence.
    // Do not forget to take into account the number of decimals.
    // @todo do we have to clarify that totalSupply has `internal` as visibility (it&#39;s the default value)?
    uint256 totalSupply_;

    // Map containing the amount of tokens owned by every address.
    // @todo do we have to clarify that balances has `internal` as visibility (it&#39;s the default value)?
    mapping(address => uint256) balances;

    // Map containing the amount of tokens that every owner allowed to every spender.
    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Create an instance of this contract.
     * @param _name Name of the token.
     * @param _symbol Symbol of the token.
     * @param _decimals Number of digits after the decimal of a token.
     */
    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
     * @dev Get the total token supply.
     * @return The total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Gets the balance of a specified address.
     * @param _who The address to query the balance of.
     * @return The amount owned by the passed address.
     */
    function balanceOf(address _who) public view returns (uint256) {
        return balances[_who];
    }

    /**
     * @dev Transfer an amount of tokens to a specified address.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @return The success of the operation.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
       require(_to != address(0));
       // Control if the from account has enough tokens to spend.
       require(_value <= balances[msg.sender]);
       // @todo verify if we need to control the amount of transfer (i.e. add `require(_value>0)`)

       balances[msg.sender] = balances[msg.sender].sub(_value);
       balances[_to] = balances[_to].add(_value);
       emit Transfer(msg.sender, _to, _value);
    
       return true;
    }

    /**
     * @dev Transfer an amount of tokens from one address to another.
     *
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     * @return the success of the operation.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        // @todo do we need to add a control on _value? (i.e. `require(_value > 0)`)
        // @todo search &#39;mitigate short address attack&#39;

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Returns the amount of tokens which a spender is allowed to withdraw from an owner.
     *
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return The amount of tokens available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     * @return The success of the operation.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        // @todo check this control.
        // To change the approve amount you first have to reduce the addresses&#39;
        //  allowance to zero by calling &#39;approve(_spender, 0)&#39; if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     *
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     * @return The success of the operation.
     */
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
     *
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     * @return The success of the operation.
     */
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

/** 
 * 
 */
contract MBTC1 is ERC20 {
    address public owner;

    uint256 public nav;

    mapping(string => uint256) underlyings;
    
    event Buy(address indexed participant, address indexed beneficiairy, uint256 ethAmountValue, uint256 nbTokens);


    constructor(string _name, string _symbol, uint8 _decimals, uint256 _initialSupply, uint256 _nav) ERC20(_name, _symbol, _decimals) public {
         owner = msg.sender;
         totalSupply_ = _initialSupply *  10 ** uint256(decimals);
         balances[owner] = totalSupply_;
         nav = _nav;
      }

    function kill() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

    function updateNav(uint256 _nav) public {
        require(msg.sender == owner);
        nav = _nav;
    }
   
    function updateUnderlying(string _name, uint256 _weight) public {
        require(msg.sender == owner);
        underlyings[_name] = _weight;
    }
    
    function buy() external payable {
        buyTo(msg.sender);
    }
    
    function buyTo(address beneficiary)  public payable {
        require(beneficiary != address(0));
        uint256 nbTokens = msg.value.div(nav);
        transferFrom(this, msg.sender, nbTokens);
        emit Buy(msg.sender, beneficiary, msg.value, nbTokens);
    }
}