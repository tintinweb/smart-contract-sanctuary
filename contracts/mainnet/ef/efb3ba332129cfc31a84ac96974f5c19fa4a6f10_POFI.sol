pragma solidity ^0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * SafeMath mul function
     * @dev function for safe multiply, throws on overflow.
     **/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
  	 * SafeMath div function
  	 * @dev function for safe devide, throws on overflow.
  	 **/
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    /**
  	 * SafeMath sub function
  	 * @dev function for safe subtraction, throws on overflow.
  	 **/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
  	 * SafeMath add function
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
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public isOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event NotPausable();

  bool public paused = false;
  bool public canPause = true;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
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
     **/
    function pause() isOwner whenNotPaused public {
        require(canPause == true);
        paused = true;
        emit Pause();
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() isOwner whenPaused public {
    require(paused == true);
    paused = false;
    emit Unpause();
  }

  /**
     * @dev Prevent the token from ever being paused again
     **/
    function notPausable() isOwner public{
        paused = false;
        canPause = false;
        emit NotPausable();
    }
}

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/

contract StandardToken is Pausable {

    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    /**
     * @dev Returns the total supply of the token
     **/
    function totalSupply() public constant returns (uint256 supply) {
        return totalSupply;
    }

    /**
     * @dev Transfer tokens when not paused
     **/
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    /**
     * @dev transferFrom function to tansfer tokens when token is not paused
     **/
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    /**
     * @dev returns balance of the owner
     **/
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev approve spender when not paused
     **/
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
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
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface with the features of the above declared standard token
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract POFI is StandardToken  {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    string public version = '1.0';
    uint8 public decimals;
    uint16 public exchangeRate;
    uint256 public lockedTime;
    uint256 public othersLockedTime;
    uint256 public marketingLockedTime;

    event TokenNameChanged(string indexed previousName, string indexed newName);
    event TokenSymbolChanged(string indexed previousSymbol, string indexed newSymbol);
    event ExchangeRateChanged(uint16 indexed previousRate, uint16 indexed newRate);

    /**
   * ERC20 Token Constructor
   * @dev Create and issue tokens to msg.sender.
   */
    constructor (address privatesale, address presale, address marketing) public {
        decimals        = 18;
        exchangeRate    = 12566;
        lockedTime     = 1632031991; // 1 year locked
        othersLockedTime = 1609528192; // 3 months locked
        marketingLockedTime = 1614625792; // 6 months locked
        symbol          = "POFI";
        name            = "PoFi Network";

        mint(privatesale, 15000000 * 10**uint256(decimals)); // Privatesale 15% of the tokens
        mint(presale, 10000000 * 10**uint256(decimals)); // Presale 10% of the tokens
        mint(marketing, 5000000 * 10**uint256(decimals)); // Marketing/partnership/uniswap liquidity (5% of the tokens, the other 5% is locked for 6 months)
        mint(address(this), 70000000 * 10**uint256(decimals)); // Team 10% of tokens locked for 1 year, Others(Audit/Dev) 5% of tokens locked for 3 months, marketing 5% of tokens locked for 6 months, rewards 50% of the total token supply is locked for 3 months



    }

    /**
     * @dev Function to change token name.
     * @return A boolean.
     */
    function changeTokenName(string newName) public isOwner returns (bool success) {
        emit TokenNameChanged(name, newName);
        name = newName;
        return true;
    }

    /**
     * @dev Function to change token symbol.
     * @return A boolean.
     */
    function changeTokenSymbol(string newSymbol) public isOwner returns (bool success) {
        emit TokenSymbolChanged(symbol, newSymbol);
        symbol = newSymbol;
        return true;
    }

    /**
     * @dev Function to check the exchangeRate.
     * @return A boolean.
     */
    function changeExchangeRate(uint16 newRate) public isOwner returns (bool success) {
        emit ExchangeRateChanged(exchangeRate, newRate);
        exchangeRate = newRate;
        return true;
    }

    function () public payable {
        fundTokens();
    }

    /**
     * @dev Function to fund tokens
     */
    function fundTokens() public payable {
        require(msg.value > 0);
        uint256 tokens = msg.value.mul(exchangeRate);
        require(balances[owner].sub(tokens) > 0);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        emit Transfer(msg.sender, owner, tokens);
        forwardFunds();
    }
    /**
     * @dev Function to forward funds internally.
     */
    function forwardFunds() internal {
        owner.transfer(msg.value);
    }

    /**
     * @notice Release locked tokens of team.
     */
    function releaseTeamLockedPOFI() public isOwner returns(bool){
        require(block.timestamp >= lockedTime, "Tokens are locked in the smart contract until respective release Time ");

        uint256 amount = balances[address(this)];
        require(amount > 0, "TokenTimelock: no tokens to release");

        emit Transfer(address(this), msg.sender, amount);

        return true;
    }
    
    /**
     * @notice Release locked tokens of Others(Dev/Audit).
     */
    function releaseOthersLockedPOFI() public isOwner returns(bool){
        require(block.timestamp >= othersLockedTime, "Tokens are locked in the smart contract until respective release time");

        uint256 amount = 5000000; // 5M others locked tokens which will be released after 3 months

        emit Transfer(address(this), msg.sender, amount);

        return true;
    }
    
    /**
     * @notice Release locked tokens of Marketing.
     */
    function releaseMarketingLockedPOFI() public isOwner returns(bool){
        require(block.timestamp >= marketingLockedTime, "Tokens are locked in the smart contract until respective release time");

        uint256 amount = 5000000; // 5M others locked tokens which will be released after 3 months

        emit Transfer(address(this), msg.sender, amount);

        return true;
    }
    
    /**
     * @notice Release locked tokens of Rewards(Staking/Liqudity incentive mining).
     */
    function releaseRewardsLockedPOFI() public isOwner returns(bool){
        require(block.timestamp >= othersLockedTime, "Tokens are locked in the smart contract until respective release time");

        uint256 amount = 50000000; // 50M rewards locked tokens which will be released after 3 months

        emit Transfer(address(this), msg.sender, amount);

        return true;
    }
    
    
    

    /**
     * @dev User to perform {approve} of token and {transferFrom} in one function call.
     *
     *
     * Requirements
     *
     * - `spender' must have implemented {receiveApproval} function.
     */
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _extraData
    ) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        if(!_spender.call(
            bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))),
            msg.sender,
            _value,
            this,
            _extraData
        )) { revert(); }
        return true;
    }

}