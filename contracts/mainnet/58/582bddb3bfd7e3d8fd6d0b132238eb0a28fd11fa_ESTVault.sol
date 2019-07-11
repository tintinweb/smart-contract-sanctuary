/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.4.24;

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

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

/**
 * @title tokenRecipient
 * @dev An interface capable of calling `receiveApproval`, which is used by `approveAndCall` to notify the contract from this interface
 */
interface tokenRecipient { function receiveApproval(address from, uint256 value, address token, bytes extraData) external; }

/**
 * @title TokenERC20
 * @dev A simple ERC20 standard token with burnable function
 */
contract TokenERC20 {
    using SafeMath for uint256;

    // Total number of tokens in existence
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    // This notifies clients about the amount burnt/transferred/approved
    event Burn(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Gets the balance of the specified address
     * @param _owner The address to query
     * @return Token balance of `_owner`
     */
    function balanceOf(address _owner) view public returns(uint256) {
        return balances[_owner];
    }

    /**
     * @dev Gets a spender&#39;s allowance from a token holder
     * @param _owner The address which allows spender to spend
     * @param _spender The address being allowed
     * @return Approved amount for `spender` to spend from `_owner`
     */
    function allowance(address _owner, address _spender) view public returns(uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Basic transfer of all transfer-related functions
     * @param _from The address of sender
     * @param _to The address of recipient
     * @param _value The amount sender want to transfer to recipient
     */
    function _transfer(address _from, address _to, uint _value) internal {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer( _from, _to, _value);
    }

    /**
     * @notice Transfer tokens
     * @dev Send `_value` tokens to `_to` from your account
     * @param _to The address of the recipient
     * @param _value The amount to send
     * @return True if the transfer is done without error
     */
    function transfer(address _to, uint256 _value) public returns(bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @notice Transfer tokens from other address
     * @dev Send `_value` tokens to `_to` on behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount to send
     * @return True if the transfer is done without error
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * @notice Set allowance for other address
     * @dev Allows `_spender` to spend no more than `_value` tokens on your behalf
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @return True if the approval is done without error
     */
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @notice Set allowance for other address and notify
     * @dev Allows contract `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     * @param _spender The contract address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     * @return True if it is done without error
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }

    /**
     * @notice Destroy tokens
     * @dev Remove `_value` tokens from the system irreversibly
     * @param _value The amount of money will be burned
     * @return True if `_value` is burned successfully
     */
    function burn(uint256 _value) public returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * @notice Destroy tokens from other account
     * @dev Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from The address of the burner
     * @param _value The amount of token will be burned
     * @return True if `_value` is burned successfully
     */
    function burnFrom(address _from, uint256 _value) public returns(bool) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }

    /**
     * @notice Transfer tokens to multiple account
     * @dev Send `_value` tokens to corresponding `_to` from your account
     * @param _to The array of ddress of the recipients
     * @param _value The array of amount to send
     * @return True if the transfer is done without error
     */
    function transferMultiple(address[] _to, uint256[] _value) external returns(bool) {
        require(_to.length == _value.length);
        uint256 i = 0;
        while (i < _to.length) {
           _transfer(msg.sender, _to[i], _value[i]);
           i += 1;
        }
        return true;
    }
}

/**
 * @title EventSponsorshipToken
 * @author Ping Chen
 */
contract EventSponsorshipToken is TokenERC20 {
    using SafeMath for uint256;

    // Token Info.
    string public constant name = "EventSponsorshipToken";
    string public constant symbol = "EST";
    uint8 public constant decimals = 18;

    /**
     * @dev contract constructor
     * @param _wallet The address where initial supply goes to
     * @param _totalSupply initial supply
     */
    constructor(address _wallet, uint256 _totalSupply) public {
        totalSupply = _totalSupply;
        balances[_wallet] = _totalSupply;
    }

}

contract ESTVault is Ownable {
    using SafeMath for uint256;

    struct vault {
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }

    mapping(address => vault[]) public vaults;

    EventSponsorshipToken EST = EventSponsorshipToken(0xD427c628C5f72852965fADAf1231b618c0C82395);

    event Lock(address to, uint256 value, uint256 time);
    event Revoke(address to, uint256 index);
    event Redeem(address to, uint256 index);

    function lock(address to, uint256 value, uint256 time) external {
        _lock(to, value, time);
    }

    function lockMultiple(address[] to, uint256[] value, uint256[] time) external {
        require(to.length == value.length && to.length == time.length);
        for(uint256 i = 0 ; i < to.length ; i++)
            _lock(to[i], value[i], time[i]);
    }

    function revoke(address to, uint256 index) public onlyOwner {
        vault storage v = vaults[to][index];
        require(now >= v.unlockTime);
        require(!v.claimed);
        v.claimed = true;
        require(EST.transfer(msg.sender, v.amount));
        emit Revoke(to, index);
    }

    function _lock(address to, uint256 value, uint256 time) internal {
        require(EST.transferFrom(msg.sender, address(this), value));
        vault memory v;
        v.amount = value;
        v.unlockTime = time;
        vaults[to].push(v);
        emit Lock(to, value, time);
    }

    function redeem(uint256 index) external {
        vault storage v = vaults[msg.sender][index];
        require(now >= v.unlockTime);
        require(!v.claimed);
        v.claimed = true;
        require(EST.transfer(msg.sender, v.amount));
        emit Redeem(msg.sender, index);
    }

}