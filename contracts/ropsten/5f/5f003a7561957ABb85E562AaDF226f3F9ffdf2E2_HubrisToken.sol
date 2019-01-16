pragma solidity ^0.4.23;

// File: zeppelin/contracts/ownership/Ownable.sol

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
    constructor() public {
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

// File: zeppelin/contracts/math/SafeMath.sol

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
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: zeppelin/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

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
        emit Transfer(msg.sender, _to, _value);
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

}

// File: zeppelin/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


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
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
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

// File: contracts/TransferableToken.sol

pragma solidity ^0.4.23;

/**
 * @title Transferable token
 *
 * @dev StandardToken modified with transfert on/off mechanism.
 **/
contract TransferableToken is StandardToken,Ownable {

    /** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    * @dev TRANSFERABLE MECANISM SECTION
    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/

    event Transferable();
    event UnTransferable();

    bool public transferable = false;
    mapping (address => bool) public whitelisted;

    /**
        CONSTRUCTOR
    **/
    
    constructor() 
        StandardToken() 
        Ownable()
        public 
    {
        whitelisted[msg.sender] = true;
    }

    /**
        MODIFIERS
    **/

    /**
    * @dev Modifier to make a function callable only when the contract is not transferable.
    */
    modifier whenNotTransferable() {
        require(!transferable);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is transferable.
    */
    modifier whenTransferable() {
        require(transferable);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the caller can transfert token.
    */
    modifier canTransfert() {
        if(!transferable){
            require (whitelisted[msg.sender]);
        } 
        _;
   }
   
    /**
        OWNER ONLY FUNCTIONS
    **/

    /**
    * @dev called by the owner to allow transferts, triggers Transferable state
    */
    function allowTransfert() onlyOwner whenNotTransferable public {
        transferable = true;
        emit Transferable();
    }

    /**
    * @dev called by the owner to restrict transferts, returns to untransferable state
    */
    function restrictTransfert() onlyOwner whenTransferable public {
        transferable = false;
        emit UnTransferable();
    }

    /**
      @dev Allows the owner to add addresse that can bypass the transfer lock.
    **/
    function whitelist(address _address) onlyOwner public {
        require(_address != 0x0);
        whitelisted[_address] = true;
    }

    /**
      @dev Allows the owner to remove addresse that can bypass the transfer lock.
    **/
    function restrict(address _address) onlyOwner public {
        require(_address != 0x0);
        whitelisted[_address] = false;
    }


    /** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    * @dev Strandard transferts overloaded API
    * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/

    function transfer(address _to, uint256 _value) public canTransfert returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfert returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public canTransfert returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public canTransfert returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public canTransfert returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

// File: contracts/HBRSToken.sol

pragma solidity ^0.4.23;


contract HubrisToken is TransferableToken {
//    using SafeMath for uint256;

    string public symbol = "HBRS";
    string public name = "Hubris Token";
    uint8 public decimals = 18;
  
    uint256 constant public   SALE = 121000000E18; // Token Sale
    uint256 constant public   TEAM = 99000000E18; // TEAM Address
    
    address public sale_address = this;
    address public team_address = 0x40289D515dA7eAaDE8CCE588824dAbB58F2A5626;

    bool public initialDistributionDone = false;

    /**
    * @dev compute & distribute the tokens
    */
    function distribute() public onlyOwner {
        // Initialisation check
        require(!initialDistributionDone);
        require(sale_address != 0x0 && team_address != 0x0);      

        // Compute total supply 
        totalSupply_ = 220000000E18;

        // Distribute Token 
        balances[owner] = totalSupply_;
        emit Transfer(0x0, owner, totalSupply_);

        transfer(team_address, TEAM);
        transfer(sale_address, SALE);
        initialDistributionDone = true;
        whitelist(sale_address); // Auto whitelist sale address
        whitelist(team_address); // Auto whitelist team address (vesting transfert)
    }

    /**
    * @dev Allows owner to later update token name if needed.
    */
    function setName(string _name) onlyOwner public {
        name = _name;
    }
    
    /**
    * @dev Allows owner to later update token symbol if needed.
    */
    function setSymbol(string _symbol) onlyOwner public {
        symbol = _symbol;
    }

    /**
    * @dev Allows owner to withdraw any ether from contract
    */
    function forwardFunds(uint256 _amount) internal {
        owner.transfer(_amount);
    }
    
    /**
     * @dev When at risk, evacuate tokens
     */

    function evacuateTokens(address _wallet) onlyOwner public {
      require(_wallet != address(0));
      this.transfer(_wallet, this.balanceOf(this));
    }
}