pragma solidity ^0.4.25;


/**
 * Math operations with safety checks
 */
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public totalSupply;

    function balanceOf(address who) public view returns (uint);

    function transfer(address to, uint value) public;

    event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length == size + 4, "payload size does not match");
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint balance)  {
        return balances[_owner];
    }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);

    function transferFrom(address from, address to, uint value) public;

    function approve(address spender, uint value) public;

    event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping(address => mapping(address => uint)) allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) public {

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value) public {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    /**
     * @dev Function to check the amount of tokens than an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


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
        require(msg.sender == owner, "only owner can call");
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint value);
    event MintFinished();

    bool public mintingFinished = false;
    uint public totalSupply = 0;


    modifier canMint() {
        require(!mintingFinished, "mint finished.");
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(0x0, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
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
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused, "contract not paused");
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused {
        require(paused, "contract paused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}


/**
 * Pausable token
 *
 * Simple ERC20 Token example, with pausable token creation
 **/

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint _value) whenNotPaused public {
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) whenNotPaused public {
        super.transferFrom(_from, _to, _value);
    }
}


/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a time has passed
 */
contract TokenTimelock {

    // ERC20 basic token contract being held
    ERC20Basic token;

    // beneficiary of tokens after they are released
    address beneficiary;

    // timestamp where token release is enabled
    uint releaseTime;

    constructor(ERC20Basic _token, address _beneficiary, uint _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
     * @dev beneficiary claims tokens held by time lock
     */
    function claim() public {
        require(msg.sender == beneficiary);
        require(now >= releaseTime);

        uint amount = token.balanceOf(this);
        require(amount > 0);

        token.transfer(beneficiary, amount);
    }
}


/**
 * @title Token
 * @dev An ERC20 compilable Token contract
 */
contract Token is PausableToken, MintableToken {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(
        string tokenName,
        string tokenSymbol,
        address tokenOwner,
        uint256 initialSupply,
        uint8 decimalUnits
    ) public {
        // Set the name for display purposes
        name = tokenName;
        // Set the symbol for display purposes
        symbol = tokenSymbol;
        // Amount of decimals for display purposes
        decimals = decimalUnits;
        // Set token owner
        owner = tokenOwner;
        // mint token for initial supply
        totalSupply = initialSupply;
        balances[tokenOwner] = initialSupply;
        emit Mint(tokenOwner, initialSupply);
        emit Transfer(0x0, tokenOwner, initialSupply);
    }

    /**
     * @dev mint timelocked tokens
     */
    function mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime)
    onlyOwner canMint public returns (TokenTimelock) {

        TokenTimelock timelock = new TokenTimelock(this, _to, _releaseTime);
        mint(timelock, _amount);

        return timelock;
    }

    /**
     * @dev transfer balance to owner
     */
    function withdrawEther(uint256 amount) onlyOwner public {
        owner.transfer(amount);
    }

    /**
     * @dev can accept ether
     */
    function() payable public {
    }

}