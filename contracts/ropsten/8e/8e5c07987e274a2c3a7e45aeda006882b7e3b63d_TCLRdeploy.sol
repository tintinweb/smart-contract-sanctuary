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
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
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
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
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

  /**
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. We recommend to use use increaseApproval
   * and decreaseApproval functions instead !
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263555598
   */
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

// File: contracts/TCLRToken.sol


pragma solidity ^0.4.23;




contract TCLRToken is TransferableToken {
//    using SafeMath for uint256;

    string public symbol = "TCLR";
    string public name = "TCLR";
    uint8 public decimals = 18;
  

    uint256 constant internal DECIMAL_CASES    = (10 ** uint256(decimals));
    uint256 constant public   ICO             =  48369987 * DECIMAL_CASES; // ICO
    uint256 constant public   TEAM             =   7773748 * DECIMAL_CASES; // TEAM (lockedup 12 months)
    uint256 constant public   ADVISORS         =   4318748 * DECIMAL_CASES; // Advisors (lockedup 6 months)
    uint256 constant public   COMPANY         =   7773748 * DECIMAL_CASES; // Company
    uint256 constant public   BONUS  =   16411245 * DECIMAL_CASES;         // BONUS
    uint256 constant public   BOUNTY           =    1727500 * DECIMAL_CASES; // Bounty 

    address public ico_address     = 0x7C53f81cd5718162CC3903a10dbeE391A0E9d90E;    //address can be changed before deployment
    address public team_address     = 0x46B5cE5140FaB20567df484322A77fB3334Fb393;   //address can be changed before deployment
    address public advisors_address = 0x26B5cFAd1703f08d7AF2034f7B6465b58ead795E;   //address can be changed before deployment
    address public company_address = 0x242aed53b9C369B7Ef67D03Fe72248c3e054d873;   //address can be changed before deployment
    address public bonus_address = 0xE95F8397533c35B1E53309FeB93eAB6F757B8594;      //address can be changed before deployment
    address public bounty_address   = 0x69277dA93c2263e24e069D98d1040c7A7f7C8093;  //address can be changed before deployment
    bool public initialDistributionDone = false;

    /**
    * @dev Setup the initial distribution addresses
    */
    function reset(address _icoAddrss, address _teamAddrss, address _advisorsAddrss, address _companyAddrss, address _bonusAddrss, address _bountyAddrss) public onlyOwner{
        require(!initialDistributionDone);
        
        ico_address = _icoAddrss;
        team_address = _teamAddrss;
        advisors_address = _advisorsAddrss;
        company_address = _companyAddrss;
        bonus_address = _bonusAddrss;
        bounty_address = _bountyAddrss;
        
    }

    /**
    * @dev compute & distribute the tokens
    */
    function distribute() public onlyOwner {
        // Initialisation check
        require(!initialDistributionDone);
        require(ico_address != 0x0 && team_address != 0x0 && advisors_address != 0x0 && company_address != 0x0 && bonus_address != 0x0  && bounty_address != 0x0);      

        // Compute total supply 
        totalSupply_ = ICO.add(TEAM).add(ADVISORS).add(COMPANY).add(BONUS).add(BOUNTY);

        // Distribute TCLR Token 
        balances[owner] = totalSupply_;
        emit Transfer(0x0, owner, totalSupply_);
        
        transfer(ico_address, ICO);
        transfer(team_address, TEAM);
        transfer(advisors_address, ADVISORS);
        transfer(company_address, COMPANY);
        transfer(bonus_address, BONUS);
        transfer(bounty_address, BOUNTY);
        
        initialDistributionDone = true;
        whitelist(ico_address); // Auto whitelist ico_address
        whitelist(bounty_address); // Auto whitelist bounty_address
    }

    /**
    * @dev Allows owner to later update token name if needed.
    */
    function setName(string _name) onlyOwner public {
        name = _name;
    }

}

// File: contracts/KryllVesting.sol



pragma solidity ^0.4.23;




/**
 * @title TCLRdeploy
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract TCLRdeploy is Ownable {
    using SafeMath for uint256;

    event Released(uint256 amount);

    // beneficiary of tokens after they are released
    address public beneficiary;
    TCLRToken public token;

    uint256 public startTime;
    uint256 public cliff;
    uint256 public released;


    uint256 constant public   VESTING_DURATION    =  3600; // 1 hour in second
    uint256 constant public   CLIFF_DURATION      =   600; // 10 minutes in second


    /**
    * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
    * _beneficiary, gradually in a linear fashion. By then all of the balance will have vested.
    * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
    * @param _token The token to be vested
    */
    function setup(address _beneficiary,address _token) public onlyOwner{
        require(startTime == 0); // Vesting not started
        require(_beneficiary != address(0));
        // Basic init
        changeBeneficiary(_beneficiary);
        token = TCLRToken(_token);
    }

    /**
    * @notice Start the vesting process.
    */
    function start() public onlyOwner{
        require(token != address(0));
        require(startTime == 0); // Vesting not started
        startTime = now;
        cliff = startTime.add(CLIFF_DURATION);
    }

    /**
    * @notice Is vesting started flag.
    */
    function isStarted() public view returns (bool) {
        return (startTime > 0);
    }


    /**
    * @notice Owner can change beneficiary address
    */
    function changeBeneficiary(address _beneficiary) public onlyOwner{
        beneficiary = _beneficiary;
    }


    /**
    * @notice Transfers vested tokens to beneficiary.
    */
    function release() public {
        require(startTime != 0);
        require(beneficiary != address(0));
        
        uint256 unreleased = releasableAmount();
        require(unreleased > 0);

        released = released.add(unreleased);
        token.transfer(beneficiary, unreleased);
        emit Released(unreleased);
    }

    /**
    * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
    */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(released);
    }

    /**
    * @dev Calculates the amount that has already vested.
    */
    function vestedAmount() public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released);

        if (now < cliff) {
            return 0;
        } else if (now >= startTime.add(VESTING_DURATION)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(startTime)).div(VESTING_DURATION);
        }
    }
}