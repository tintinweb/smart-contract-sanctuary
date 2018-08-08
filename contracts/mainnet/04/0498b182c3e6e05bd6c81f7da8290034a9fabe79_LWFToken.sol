pragma solidity ^0.4.15;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library Utils {

    /**
    @dev Helper function, determines if a given address is an account or a contract.
    @return True if address is a contract, false otherwise
     */
    function isContract(address _addr) constant internal returns (bool) {
        uint size;

        assembly {
            size := extcodesize(_addr)
        }

        return (_addr == 0) ? false : size > 0;
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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

/**
@title Burnable
@dev Burnable custom interface, should allow external contracts to burn tokens on certain conditions.
 */
contract Burnable {

    event Burn(address who, uint256 amount);

    modifier onlyBurners {
        require(isBurner(msg.sender));
        _;
    }
    function burn(address target, uint256 amount) external onlyBurners returns (bool);
    function setBurner(address who, bool auth) returns (bool);
    function isBurner(address who) constant returns (bool);
}

/**
@title Lockable
@dev Lockable custom interface, should allow external contracts to lock accounts on certain conditions.
 */
contract Lockable {

    uint256 public lockExpiration;

    /**
    @dev Constructor
    @param _lockExpiration lock expiration datetime in UNIX time
     */
    function Lockable(uint256 _lockExpiration) {
        lockExpiration = _lockExpiration;
    }

    function isLocked(address who) constant returns (bool);
}

/**
@title ERC20 interface
@dev Standard ERC20 Interface.
*/
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
@title LWFToken
@dev ERC20 standard.
@dev Extra features: Burnable and Lockable under certain conditions.
@dev contract owner is set to msg.sender, lockExpiration for devs set to: 1535760000 || Saturday, 01-Sep-18 00:00:00 UTC
 */
contract LWFToken is ERC20, Burnable, Lockable(1535760000), Claimable {
using SafeMath for uint256;

    // Snapshot of Account balance at specific block
    struct Snapshot {
        uint256 block;
        uint256 balance;
    }

    struct Account {
        uint256 balance;
        Snapshot[] history; // history of snapshots
        mapping(address => uint256) allowed;
        bool isSet;
    }

    address[] accountsList;

    mapping(address => Account) accounts;

    bool public maintenance;

    // BURN SETTINGS
    mapping(address => bool) burners; // contracts authorized to block tokens
    bool public burnAllowed;

    // LOCK SETTINGS
    mapping(address => bool) locked; //locked users addresses

    // COSMETIC THINGS
    string public name = "LWF";
    string public symbol = "LWF";
    string public version = "release-1.1";

    uint256 public decimals = 2;

    /**
    @dev Throws if token is under maintenance.
     */
    modifier disabledInMaintenance() {
        if (maintenance)
            revert();
        _;
    }

    /**
    @dev Throws if token is not under maintenance.
     */
    modifier onlyUnderMaintenance() {
        if (!maintenance)
            revert();
        _;
    }

    /**
    @dev Registers the recipient account when tokens are sent to an unregistered account.
    @param _recipient the recipient of the transfer
     */
    modifier trackNewUsers (address _recipient) {
        if (!accounts[_recipient].isSet) {
            accounts[_recipient].isSet = true;
            accountsList.push(_recipient);
        }
        _;
    }

    /**
    @dev The constructor sets the initial balance to 30 million tokens.
    @dev 27 million assigned to the contract owner.
    @dev 3 million reserved and locked. (except bounty)
    @dev Holders history is updated for data integrity.
    @dev Burn functionality are enabled by default.
     */
    function LWFToken() {
        totalSupply = 30 * (10**6) * (10**decimals);

        burnAllowed = true;
        maintenance = false;

        require(_setup(0x927Dc9F1520CA2237638D0D3c6910c14D9a285A8, 2700000000, false));

        require(_setup(0x7AE7155fF280D5da523CDDe3855b212A8381F9E8, 30000000, false));
        require(_setup(0x796d507A80B13c455c2C1D121eDE4bccca59224C, 263000000, true));

        require(_setup(0xD77d620EC9774295ad8263cBc549789EE39C0BC0, 1000000, true));
        require(_setup(0x574B35eC5650BE0aC217af9AFCfe1c7a3Ff0BecD, 1000000, true));
        require(_setup(0x7c5a61f34513965AA8EC090011721a0b0A9d4D3a, 1000000, true));
        require(_setup(0x0cDBb03DD2E8226A6c3a54081E93750B4f85DB92, 1000000, true));
        require(_setup(0x03b6cF4A69fF306B3df9B9CeDB6Dc4ED8803cBA7, 1000000, true));
        require(_setup(0xe2f7A1218E5d4a362D1bee8d2eda2cd285aAE87A, 1000000, true));
        require(_setup(0xAcceDE2eFD2765520952B7Cb70406A43FC17e4fb, 1000000, true));
    }

    /**
    @return accountsList length
     */
    function accountsListLength() external constant returns (uint256) {
        return accountsList.length;
    }

    /**
    @dev Gets the address of any account in &#39;accountList&#39;.
    @param _index The index to query the address of
    @return An address pointing to a registered account
    */
    function getAccountAddress(uint256 _index) external constant returns (address) {
        return accountsList[_index];
    }

    /**
    @dev Checks if an accounts is registered.
    @param _address The address to check
    @return A bool set true if the account is registered, false otherwise
     */
    function isSet(address _address) external constant returns (bool) {
        return accounts[_address].isSet;
    }

    /**
    @dev Gets the balance of the specified address at the first block minor or equal the specified block
    @param _owner The address to query the the balance of
    @param _block The block
    @return An uint256 representing the amount owned by the passed address at the specified block.
    */
    function balanceAt(address _owner, uint256 _block) external constant returns (uint256 balance) {
        uint256 i = accounts[_owner].history.length;
        do {
            i--;
        } while (i > 0 && accounts[_owner].history[i].block > _block);
        uint256 matchingBlock = accounts[_owner].history[i].block;
        uint256 matchingBalance = accounts[_owner].history[i].balance;
        return (i == 0 && matchingBlock > _block) ? 0 : matchingBalance;
    }

    /**
    @dev Authorized contracts can burn tokens.
    @param _amount Quantity of tokens to burn
    @return A bool set true if successful, false otherwise
     */
    function burn(address _address, uint256 _amount) onlyBurners disabledInMaintenance external returns (bool) {
        require(burnAllowed);

        var _balance = accounts[_address].balance;
        accounts[_address].balance = _balance.sub(_amount);

        // update history with recent burn
        require(_updateHistory(_address));

        totalSupply = totalSupply.sub(_amount);
        Burn(_address,_amount);
        Transfer(_address, 0x0, _amount);
        return true;
    }

    /**
    @dev Send a specified amount of tokens from sender address to &#39;_recipient&#39;.
    @param _recipient address receiving tokens
    @param _amount the amount of tokens to be transferred
    @return A bool set true if successful, false otherwise
     */
    function transfer(address _recipient, uint256 _amount) returns (bool) {
        require(!isLocked(msg.sender));
        return _transfer(msg.sender,_recipient,_amount);
    }

    /**
    @dev Transfer tokens from one address to another
    @param _from address The address which you want to send tokens from
    @param _to address The address which you want to transfer to
    @param _amount the amount of tokens to be transferred
    @return A bool set true if successful, false otherwise
    */
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool) {
        require(!isLocked(_from));
        require(_to != address(0));

        var _allowance = accounts[_from].allowed[msg.sender];

        // Check is not needed because sub(_allowance, _amount) will already throw if this condition is not met
        // require (_amount <= _allowance);
        accounts[_from].allowed[msg.sender] = _allowance.sub(_amount);
        return _transfer(_from, _to, _amount);
    }

    /**
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) returns (bool) {
        //  To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition
        require((_value == 0) || (accounts[msg.sender].allowed[_spender] == 0));

        accounts[msg.sender].allowed[_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    @dev Approve should be called when allowed[_spender] == 0. To increment
         allowed value is better to use this function to avoid 2 calls (and wait until
         the first transaction is mined)
    @param _spender The address which will spend the funds
    @param _addedValue The value which will be added from the allowed balance
    */
    function increaseApproval(address _spender, uint _addedValue) returns (bool success) {
        uint256 _allowance = accounts[msg.sender].allowed[_spender];
        accounts[msg.sender].allowed[_spender] = _allowance.add(_addedValue);
        Approval(msg.sender, _spender, accounts[msg.sender].allowed[_spender]);
        return true;
    }

    /**
    @dev Approve should be called when allowed[_spender] == 0. To decrement
         allowed value is better to use this function to avoid 2 calls (and wait until
         the first transaction is mined)
    @param _spender The address which will spend the funds
    @param _subtractedValue The value which will be subtracted from the allowed balance
    @return A bool set true if successful, false otherwise
    */
    function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success) {
        uint oldValue = accounts[msg.sender].allowed[_spender];
        accounts[msg.sender].allowed[_spender] = (_subtractedValue > oldValue) ? 0 : oldValue.sub(_subtractedValue);
        Approval(msg.sender, _spender, accounts[msg.sender].allowed[_spender]);
        return true;
    }

    /**
    @dev Sets a contract authorization to burn tokens.
    @param _address The address to authorize/deauthorize
    @param _auth True for authorization, false otherwise
    @return A bool set true if successful, false otherwise
     */
    function setBurner(address _address, bool _auth) onlyOwner returns (bool) {
        require(burnAllowed);
        assert(Utils.isContract(_address));
        burners[_address] = _auth;
        return true;
    }

    /**
    @dev Checks if the provided contract can burn tokens.
    @param _address The address to check
    @return A bool set true if authorized, false otherwise
     */
    function isBurner(address _address) constant returns (bool) {
        return burnAllowed ? burners[_address] : false;
    }

    /**
    @dev Checks if the token owned by the provided address are locked.
    @param _address The address to check
    @return A bool set true if locked, false otherwise
     */
    function isLocked(address _address) constant returns (bool) {
        return now >= lockExpiration ? false : locked[_address];
    }

    /**
    @dev Function permanently disabling &#39;burn()&#39; and &#39;setBurner()&#39;.
    @dev Already burned tokens are not recoverable.
    @dev Effects of this transaction are irreversible.
    @return A bool set true if successful, false otherwise
     */
    function burnFeatureDeactivation() onlyOwner returns (bool) {
        require(burnAllowed);
        burnAllowed = false;
        return true;
    }

    /**
    @dev Gets the balance of the specified address.
    @param _owner The address to query the the balance of.
    @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return accounts[_owner].balance;
    }

    /**
    @dev Function to check the amount of tokens that an owner allowed to a spender.
    @param _owner address The address which owns the funds.
    @param _spender address The address which will spend the funds.
    @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return accounts[_owner].allowed[_spender];
    }

    /**
    @dev Sets the maintenance mode. During maintenance operations modifying balances are frozen.
    @param _state true if maintenance is on, false otherwise
    @return A bool set true if successful, false otherwise
     */
    function setMaintenance(bool _state) onlyOwner returns (bool) {
        maintenance = _state;
        return true;
    }

    /**
    @dev Maintenance function, if accountsList grows too long back end can safely clean unused accounts
        and push the renewed list into the contract.
    @dev Accounts removed from the list must be deactivated with maintenanceDeactivateUser(_user)
    @param _accountsList A list containing the accounts&#39; addresses
    @return A bool set true if successful, false otherwise
     */
    function maintenanceSetAccountsList(address[] _accountsList) onlyOwner onlyUnderMaintenance returns (bool) {
        accountsList = _accountsList;
        return true;
    }

    /**
    @dev Maintenance function reserved to back end, removes an account from the list.
    @return A bool set true if successful, false otherwise
     */
    function maintenanceDeactivateUser(address _user) onlyOwner onlyUnderMaintenance returns (bool) {
        accounts[_user].isSet = false;
        delete accounts[_user].history;
        return true;
    }

    /**
    @dev Auxiliary method used in constructor to reserve some tokens and lock them in some cases.
    @param _address The address to assign tokens
    @param _amount The amount of tokens
    @param _lock True to lock until &#39;lockExpiration&#39;, false to not
    @return A bool set true if successful, false otherwise
     */
    function _setup(address _address, uint256 _amount, bool _lock) internal returns (bool) {
        locked[_address] = _lock;
        accounts[_address].balance = _amount;
        accounts[_address].isSet = true;
        require(_updateHistory(_address));
        accountsList.push(_address);
        Transfer(this, _address, _amount);
        return true;
    }

    /**
    @dev Function implementing the shared logic of &#39;transfer()&#39; and &#39;transferFrom()&#39;
    @param _from address sending tokens
    @param _recipient address receiving tokens
    @param _amount tokens to send
    @return A bool set true if successful, false otherwise
     */
    function _transfer(address _from, address _recipient, uint256 _amount) internal disabledInMaintenance trackNewUsers(_recipient) returns (bool) {

        accounts[_from].balance = balanceOf(_from).sub(_amount);
        accounts[_recipient].balance = balanceOf(_recipient).add(_amount);

        // save this transaction in both accounts history
        require(_updateHistory(_from));
        require(_updateHistory(_recipient));

        Transfer(_from, _recipient, _amount);
        return true;
    }

    /**
    @dev Updates the user history with the latest balance.
    @param _address The Account&#39;s address to update
    @return A bool set true if successful, false otherwise
     */
    function _updateHistory(address _address) internal returns (bool) {
        accounts[_address].history.push(Snapshot(block.number, balanceOf(_address)));
        return true;
    }

}