pragma solidity 0.5.2;

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

contract Ownable {

    address public owner;
    bool public stopped = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public{
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

    /** 
    * Stop ICO contract
    */
    function stop() onlyOwner public{
        stopped = true;
    }

    /** 
    * Start ICO contract
    */
    function start() onlyOwner public{
        stopped = false;
    }

    /** 
    Validate if ICO running
    */
    modifier isRunning {
        assert (!stopped);
        _;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

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

    /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != address(0));
    totalSupply_ = totalSupply_.add(value);
    balances[account] = balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

}

contract BurnableToken is BasicToken, Ownable {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public onlyOwner{
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {

    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }
    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

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

/**
 * @title ERC20 Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is BasicToken, Ownable {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint( address to, uint256 value ) public onlyOwner returns (bool){
      _mint(to, value);
      return true;
    }
  }

contract CryptoxygenToken is StandardToken, BurnableToken, ERC20Mintable {

    using SafeMath for uint;

    string constant public symbol = "OXY2";
    string constant public name = "Cryptoxygen";

    uint8 constant public decimals = 5;
    uint256 public constant decimalFactor = 10 ** uint256(decimals);
    uint256 public constant INITIAL_SUPPLY = 250000000 * decimalFactor;

    uint constant ITSStartTime = 1547553600;  // Tuesday, 15 January 2019 12:00:00
    uint constant ITSEndTime = 1553256000;    // Friday, 22 March 2019 12:00:00
    uint constant unlockTimeF1 = 1558440000; // Tuesday, 21 May 2019 12:00:00
    uint constant unlockTimeF2 = 1561118400;  // Friday, 21 June 2019 12:00:00

    uint256 constant publicTokens  = 150000000 * decimalFactor;
    uint256 constant devTokens = 45000000 * decimalFactor;
    uint256 constant investorTokens= 15000000 * decimalFactor;
    uint256 constant founderTokens1 = 20000000 * decimalFactor;
    uint256 constant founderTokens2 = 10000000 * decimalFactor;
    uint256 constant founderTokens3 = 10000000 * decimalFactor;

    address constant adrDev = 0xF14Eb018a5cAa6b22B67FFFfA61c9B78aB3957d2;
    address constant adrInvestor = 0x2A7B09b90f8bDD22a9d66c83aDa49961827C1Dbe;
    address constant adrFounder1 = 0x68293d5F4826E200A33055d183E73F4227ecEd99;
    address constant adrFounder2 = 0xaE4dA48373f8CD3d54Dd3a8AAAa9aEc568ef29C6;
    address constant adrFounder3 = 0x77264564D740245E377E263675bdDA2D23baaC97;

    constructor(address ownerAdrs) public {
        totalSupply_ = INITIAL_SUPPLY;
        //InitialDistribution
        preSale(ownerAdrs,publicTokens);
        
        preSale(adrDev,devTokens);
        preSale(adrInvestor,investorTokens);
        preSale(adrFounder1,founderTokens1);
        preSale(adrFounder2,founderTokens2);
        preSale(adrFounder3,founderTokens3);
    }

    function preSale(address _address, uint _amount) internal returns (bool) {
        balances[_address] = _amount;
        emit Transfer(address(0x0), _address, _amount);
    }

    function checkPermissions(address _address) internal view returns (bool) {

        if( ( block.timestamp < unlockTimeF1 ) && ( _address == adrFounder1 || _address == adrFounder2 || _address == adrFounder3 ) ){
            return false;
        }else if( ( block.timestamp < unlockTimeF2 ) && ( _address == adrDev || _address == adrInvestor ) ){
            return false;
        }else if ( _address == owner ){
            return true;
        }else if( block.timestamp < ITSEndTime ){
            return false;
        }else{
            return true;
        }
    }

    function transfer(address _to, uint256 _value) isRunning public returns (bool) {
        require(checkPermissions(msg.sender));
        super.transfer(_to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) isRunning public returns (bool) {
        require(checkPermissions(_from));
        super.transferFrom(_from, _to, _value);
        return true;
    }
    
}