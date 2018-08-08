pragma solidity ^0.4.20;

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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

/**
 * Token contract interface for external use
 */
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }


/**
* @title Admin parameters
* @dev Define administration parameters for this contract
*/
contract admined { //This token contract is administered
    address public admin; //Admin address is public
    address public allowedAddress; //an address that can override lock condition

    /**
    * @dev Contract constructor
    * define initial administrator
    */
    function admined() internal {
        admin = msg.sender; //Set initial admin to contract creator
        Admined(admin);
    }

   /**
    * @dev Function to set an allowed address
    * @param _to The address to give privileges.
    */
    function setAllowedAddress(address _to) onlyAdmin public {
        allowedAddress = _to;
        AllowedSet(_to);
    }

    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    modifier crowdsaleonly() { //A modifier to lock transactions
        require(allowedAddress == msg.sender);
        _;
    }

   /**
    * @dev Function to set new admin address
    * @param _newAdmin The address to transfer administration to
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != 0);
        admin = _newAdmin;
        TransferAdminship(admin);
    }


    //All admin actions have a log for public review
    event AllowedSet(address _to);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

/**
* @title Token definition
* @dev Define token paramters including ERC20 ones
*/
contract ERC20Token is ERC20TokenInterface, admined { //Standard definition of a ERC20Token
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances; //A mapping of all balances per address
    mapping (address => mapping (address => uint256)) allowed; //A mapping of all allowances
    mapping (address => bool) frozen; //A mapping of frozen accounts

    /**
    * @dev Get the balance of an specified address.
    * @param _owner The address to be query.
    */
    function balanceOf(address _owner) public constant returns (uint256 value) {
        return balances[_owner];
    }

    /**
    * @dev transfer token to a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value)  public returns (bool success) {
        require(_to != address(0)); //If you dont want that people destroy token
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev transfer token from an address to another specified address using allowance
    * @param _from The address where token comes.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success) {
        require(_to != address(0)); //If you dont want that people destroy token
        require(frozen[_from]==false);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Assign allowance to an specified address to use the owner balance
    * @param _spender The address to be allowed to spend.
    * @param _value The amount to be allowed.
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0)); //exploit mitigation
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Get the allowance of an specified address to use another address balance.
    * @param _owner The address of the owner of the tokens.
    * @param _spender The address of the allowed spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Log Events
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
* @title Asset
* @dev Initial supply creation
*/
contract EKK is ERC20Token {

    string public name = &#39;EKK Token&#39;;
    uint8 public decimals = 18;
    string public symbol = &#39;EKK&#39;;
    string public version = &#39;1&#39;;
    uint256 public totalSupply = 2000000000 * 10**uint256(decimals);      //initial token creation
    uint256 public publicAllocation = 1000000000 * 10 ** uint(decimals);  // 50%  Token sales & Distribution
    uint256 public growthReserve = 700000000 * 10 ** uint(decimals);      // 35%  Platform Growth Reserve
    uint256 public marketingAllocation= 100000000 * 10 ** uint(decimals);  // 5%   Markting/Promotion
    uint256 public teamAllocation = 160000000 *10 ** uint(decimals);      // 8%   Team
    uint256 public advisorsAllocation = 40000000 * 10 ** uint(decimals);            // 2%   Advisors
    //address public owner;
    function EKK() public {

        balances[this] = totalSupply;

        Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, balances[msg.sender]);
    }

    /**
    *@dev Function to handle callback calls
    */
    function() public {
        revert();
    }

    /**
    * @dev Get publicAllocation
    */
    function getPublicAllocation() public view returns (uint256 value) {
        return publicAllocation;
    }
   /**
    * @dev setOwner for EKKcrowdsale contract only
    */
    // function setOwner(address _owner) onlyAdmin public {
    //   owner = _owner;
    // }
      /**
 *  transfer, only can be called by crowdsale contract
 */
    function transferFromPublicAllocation(address _to, uint256 _value) crowdsaleonly public returns (bool success) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[this] >= _value && publicAllocation >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[this].add(balances[_to]);
        // Subtract from the sender
        balances[this] = balances[this].sub(_value);
        publicAllocation = publicAllocation.sub(_value);
        // Add the same to the recipient
        balances[_to] = balances[_to].add(_value);
        Transfer(this, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[this] + balances[_to] == previousBalances);
        return true;
    }

    function growthReserveTokenSend(address to, uint256 _value) onlyAdmin public  {
        uint256 value = _value * 10 ** uint(decimals);
        require(to != 0x0 && growthReserve >= value);
        balances[this] = balances[this].sub(value);
        balances[to] = balances[to].add(value);
        growthReserve = growthReserve.sub(value);
        Transfer(this, to, value);
    }

    function marketingAllocationTokenSend(address to, uint256 _value) onlyAdmin public  {
        uint256 value = _value * 10 ** uint(decimals);
        require(to != 0x0 && marketingAllocation >= value);
        balances[this] = balances[this].sub(value);
        balances[to] = balances[to].add(value);
        marketingAllocation = marketingAllocation.sub(value);
        Transfer(this, to, value);
    }

    function teamAllocationTokenSend(address to, uint256 _value) onlyAdmin public  {
        uint256 value = _value * 10 ** uint(decimals);
        require(to != 0x0 && teamAllocation >= value);
        balances[this] = balances[this].sub(value);
        balances[to] = balances[to].add(value);
        teamAllocation = teamAllocation.sub(value);
        Transfer(this, to, value);
    }

    function advisorsAllocationTokenSend(address to, uint256 _value) onlyAdmin public  {
        uint256 value = _value * 10 ** uint(decimals);
        require(to != 0x0 && advisorsAllocation >= value);
        balances[this] = balances[this].sub(value);
        balances[to] = balances[to].add(value);
        advisorsAllocation = advisorsAllocation.sub(value);
        Transfer(this, to, value);
    }

    // unsold tokens back to Platform Growth Reserve
    function transferToGrowthReserve() crowdsaleonly public  {
        growthReserve = growthReserve.add(publicAllocation);
        publicAllocation = 0;
    }
    //refund tokens after crowdsale
    function refundTokens(address _sender) crowdsaleonly public {
        growthReserve = growthReserve.add(balances[_sender]);
        //balances[_sender] = 0;
    }
    
}