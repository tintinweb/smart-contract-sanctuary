pragma solidity ^0.4.23;

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

contract ERC20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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

/**
 * @title WiredToken
 * @author Tsuchinoko & NanJ people
 * @dev WiredToken is an ERC223 Token with ERC20 functions and events
 *      Fully backward compatible with ERC20
 */
contract WiredToken is ERC20Interface, Ownable {
    using SafeMath for uint256;

    string constant public name = "WiredToken";
    string constant public symbol = "WRD";
    uint8 constant public decimals = 5;
    uint256 public totalSupply = 41e11 * 1e5;
    uint256 public distributeAmount = 0;
    bool public mintingFinished = false;

    address public founder = 0x01B7ECa9Af127aCbA03aB84E88B0e56132CFb62D;
    address public preSeasonGame = 0x01B7ECa9Af127aCbA03aB84E88B0e56132CFb62D;
    address public activityFunds = 0x01B7ECa9Af127aCbA03aB84E88B0e56132CFb62D;
    address public lockedFundsForthefuture = 0x01B7ECa9Af127aCbA03aB84E88B0e56132CFb62D;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public unlockUnixTime;

    event FrozenFunds(address indexed target, bool frozen);
    event LockedFunds(address indexed target, uint256 locked);
    event Burn(address indexed from, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    /**
     * @dev Constructor is called only once and can not be called again
     */
    constructor() public {
        owner = activityFunds;

        balanceOf[founder] = totalSupply.mul(25).div(100);
        balanceOf[preSeasonGame] = totalSupply.mul(55).div(100);
        balanceOf[activityFunds] = totalSupply.mul(10).div(100);
        balanceOf[lockedFundsForthefuture] = totalSupply.mul(10).div(100);
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

    /**
     * @dev Prevent targets from sending or receiving tokens by setting Unix times
     * @param targets Addresses to be locked funds
     * @param unixTimes Unix times when locking up will be finished
     */
    function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
        require(targets.length > 0
                && targets.length == unixTimes.length);

        for(uint j = 0; j < targets.length; j++){
            require(unlockUnixTime[targets[j]] < unixTimes[j]);
            unlockUnixTime[targets[j]] = unixTimes[j];
            emit LockedFunds(targets[j], unixTimes[j]);
        }
    }

    /**
     * @dev Standard function transfer similar to ERC20 transfer with no _data
     *      Added due to backwards compatibility reasons
     */
    function transfer(address _to, uint _value) public returns (bool success) {
        require(_value > 0
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]);
        require(balanceOf[msg.sender] >= _value);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     *      Added due to backwards compatibility with ERC20
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balanceOf[_from] >= _value
                && allowance[_from][msg.sender] >= _value
                && now > unlockUnixTime[_from]
                && now > unlockUnixTime[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Allows _spender to spend no more than _value tokens in your behalf
     *      Added due to backwards compatibility with ERC20
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     *      Added due to backwards compatibility with ERC20
     * @param _owner address The address which owns the funds
     * @param _spender address The address which will spend the funds
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _from The address that will burn the tokens.
     * @param _unitAmount The amount of token to be burned.
     */
    function burn(address _from, uint256 _unitAmount) onlyOwner public {
        require(_unitAmount > 0
                && balanceOf[_from] >= _unitAmount);

        balanceOf[_from] = balanceOf[_from].sub(_unitAmount);
        totalSupply = totalSupply.sub(_unitAmount);
        emit Burn(_from, _unitAmount);
    }


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _unitAmount The amount of tokens to mint.
     */
    function mint(address _to, uint256 _unitAmount) onlyOwner canMint public returns (bool) {
        require(_unitAmount > 0);

        totalSupply = totalSupply.add(_unitAmount);
        balanceOf[_to] = balanceOf[_to].add(_unitAmount);
        emit Mint(_to, _unitAmount);
        emit Transfer(address(0), _to, _unitAmount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /**
     * @dev Function to distribute tokens to the list of addresses by the provided amount
     */
    function distributeAirdrop(address[] addresses, uint256 amount) public returns (bool) {
        require(amount > 0
                && addresses.length > 0
                && now > unlockUnixTime[msg.sender]);

        amount = amount.mul(1e8);
        uint256 totalAmount = amount.mul(addresses.length);
        require(balanceOf[msg.sender] >= totalAmount);

        for (uint j = 0; j < addresses.length; j++) {
            require(addresses[j] != 0x0
                    && now > unlockUnixTime[addresses[j]]);

            balanceOf[addresses[j]] = balanceOf[addresses[j]].add(amount);
            emit Transfer(msg.sender, addresses[j], amount);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

    function distributeAirdrop(address[] addresses, uint[] amounts) public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length
                && now > unlockUnixTime[msg.sender]);

        uint256 totalAmount = 0;

        for(uint j = 0; j < addresses.length; j++){
            require(amounts[j] > 0
                    && addresses[j] != 0x0
                    && now > unlockUnixTime[addresses[j]]);

            amounts[j] = amounts[j].mul(1e8);
            totalAmount = totalAmount.add(amounts[j]);
        }
        require(balanceOf[msg.sender] >= totalAmount);

        for (j = 0; j < addresses.length; j++) {
            balanceOf[addresses[j]] = balanceOf[addresses[j]].add(amounts[j]);
            emit Transfer(msg.sender, addresses[j], amounts[j]);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

}