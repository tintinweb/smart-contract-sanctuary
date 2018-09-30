pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



contract TokenReceiver {
    /**
    * @dev Method to be triggerred during approveAndCall execution
    * @param _sender A wallet that initiated the operation
    * @param _value Amount of approved tokens
    * @param _data Additional arguments
    */
    function tokenFallback(address _sender, uint256 _value, bytes _data) external returns (bool);
}

/**
* @title Timestamped
* @dev Timestamped contract has a separate method for receiving current timestamp.
* This simplifies derived contracts testability.
*/
contract Timestamped {
    /**
    * @dev Returns current timestamp.
    */
    function _currentTime() internal view returns(uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}





/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}










/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}






/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}






/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5022353d333f1062">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this Ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by setting a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}




/**
* @title FlipNpikToken
* @dev The FlipNpikToken is a ERC20 token 
*/
contract FlipNpikToken is Timestamped, StandardToken, DetailedERC20, HasNoEther {
    using SafeMath for uint256;

    // A wallet that will hold tokens
    address public mainWallet;
    // A wallet that is required to unlock reserve tokens
    address public financeWallet;

    // Locked reserve tokens amount is 500M FNP
    uint256 public reserveSize = uint256(500000000).mul(10 ** 18);
    // List of signatures required to unlock reserve tokens
    mapping (address => bool) public reserveHolders;
    // Total amount of unlocked reserve tokens
    uint256 public totalUnlocked = 0;

    // Scheduled for minting reserve tokens amount is 575M FNP
    uint256 public mintSize = uint256(575000000).mul(10 ** 18);
    // Datetime when minting according to schedule becomes available
    uint256 public mintStart;
    // Total amount of minted reserve tokens
    uint256 public totalMinted = 0;    

    /**
    * Describes minting stage structure fields
    * @param start Minting stage start date
    * @param volumt Total tokens available for the stage
    */
    struct MintStage {
        uint256 start;
        uint256 volume;       
    }

    // Array of stages
    MintStage[] public stages;

    /**
    * @dev Event for reserve tokens minting operation logging
    * @param _amount Amount minted
    */
    event MintReserveLog(uint256 _amount);

    /**
    * @dev Event for reserve tokens unlock operation logging
    * @param _amount Amount unlocked
    */
    event UnlockReserveLog(uint256 _amount);

    /**
    * @param _mintStart Datetime when minting according to schedule becomes available
    * @param _mainWallet A wallet that will hold tokens
    * @param _financeWallet A wallet that is required to unlock reserve tokens
    * @param _owner Smart contract owner address
    */
    constructor (uint256 _mintStart, address _mainWallet, address _financeWallet, address _owner)
        DetailedERC20("FlipNpik", "FNP", 18) public {

        require(_mainWallet != address(0), "Main address is invalid.");
        mainWallet = _mainWallet;       

        require(_financeWallet != address(0), "Finance address is invalid.");
        financeWallet = _financeWallet;        

        require(_owner != address(0), "Owner address is invalid.");
        owner = _owner;

        _setStages(_mintStart);
        _setReserveHolders();

        // 425M FNP should be minted initially
        _mint(uint256(425000000).mul(10 ** 18));
    }       

    /**
    * @dev Mints reserved tokens
    */
    function mintReserve() public onlyOwner {
        require(mintStart < _currentTime(), "Minting has not been allowed yet.");
        require(totalMinted < mintSize, "No tokens are available for minting.");
        
        // Get stage based on current datetime
        MintStage memory currentStage = _getCurrentStage();
        // Get amount available for minting
        uint256 mintAmount = currentStage.volume.sub(totalMinted);

        if (mintAmount > 0 && _mint(mintAmount)) {
            emit MintReserveLog(mintAmount);
            totalMinted = totalMinted.add(mintAmount);
        }
    }

    /**
    * @dev Unlocks reserve
    */
    function unlockReserve() public {
        require(msg.sender == owner || msg.sender == financeWallet, "Operation is not allowed for the wallet.");
        require(totalUnlocked < reserveSize, "Reserve has been unlocked.");        
        
        // Save sender&#39;s signature for reserve tokens unlock
        reserveHolders[msg.sender] = true;

        if (_isReserveUnlocked() && _mint(reserveSize)) {
            emit UnlockReserveLog(reserveSize);
            totalUnlocked = totalUnlocked.add(reserveSize);
        }        
    }

    /**
    * @dev Executes regular token approve operation and trigger receiver SC accordingly
    * @param _to Address (SC) that should receive approval and be triggerred
    * @param _value Amount of tokens for approve operation
    * @param _data Additional arguments to be passed to the contract
    */
    function approveAndCall(address _to, uint256 _value, bytes _data) public returns(bool) {
        require(super.approve(_to, _value), "Approve operation failed.");

        // Check if destination address is SC
        if (isContract(_to)) {
            TokenReceiver receiver = TokenReceiver(_to);
            return receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    } 

    /**
    * @dev Mints tokens to main wallet balance
    * @param _amount Amount to be minted
    */
    function _mint(uint256 _amount) private returns(bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[mainWallet] = balances[mainWallet].add(_amount);

        emit Transfer(address(0), mainWallet, _amount);
        return true;
    }

    /**
    * @dev Configures minting stages
    * @param _mintStart Datetime when minting according to schedule becomes available
    */
    function _setStages(uint256 _mintStart) private {
        require(_mintStart >= _currentTime(), "Mint start date is invalid.");
        mintStart = _mintStart;

        stages.push(MintStage(_mintStart, uint256(200000000).mul(10 ** 18)));
        stages.push(MintStage(_mintStart.add(365 days), uint256(325000000).mul(10 ** 18)));
        stages.push(MintStage(_mintStart.add(2 * 365 days), uint256(450000000).mul(10 ** 18)));
        stages.push(MintStage(_mintStart.add(3 * 365 days), uint256(575000000).mul(10 ** 18)));
    }

    /**
    * @dev Configures unlock signature holders list
    */
    function _setReserveHolders() private {
        reserveHolders[mainWallet] = false;
        reserveHolders[financeWallet] = false;
    }

    /**
    * @dev Finds current stage parameters according to the rules and current date and time
    * @return Current stage parameters (stage start date and available volume of tokens)
    */
    function _getCurrentStage() private view returns (MintStage) {
        uint256 index = 0;
        uint256 time = _currentTime();        

        MintStage memory result;

        while (index < stages.length) {
            MintStage memory activeStage = stages[index];

            if (time >= activeStage.start) {
                result = activeStage;
            }

            index++;             
        }

        return result;
    }

    /**
    * @dev Checks if an address is a SC
    */
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }

    /**
    * @dev Checks if reserve tokens have all required signatures for unlock operation
    */
    function _isReserveUnlocked() private view returns(bool) {
        return reserveHolders[owner] == reserveHolders[financeWallet] && reserveHolders[owner];
    }
}