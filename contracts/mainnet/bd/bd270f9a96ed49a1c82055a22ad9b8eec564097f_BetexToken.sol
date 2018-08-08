pragma solidity ^0.4.21;

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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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


/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="285a4d454b47681a">[email&#160;protected]</a>π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}


/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3f4d5a525c507f0d">[email&#160;protected]</a>π.com>
 * @dev This blocks incoming ERC223 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC223 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ uint256 the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}


/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b9cbdcd4dad6f98b">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be send to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
*/
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}


/**
 * @title Base contract for contracts that should not own things.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fe8c9b939d91becc">[email&#160;protected]</a>π.com>
 * @dev Solves a class of errors where a contract accidentally becomes owner of Ether, Tokens or
 * Owned contracts. See respective base contracts for details.
 */
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}


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
    Transfer(msg.sender, _to, _value);
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
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title BetexToken
 */
contract BetexToken is StandardToken, NoOwner {

    string public constant name = "Betex Token"; // solium-disable-line uppercase
    string public constant symbol = "BETEX"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase

    // transfer unlock time (except team and broker recipients)
    uint256 public firstUnlockTime;

    // transfer unlock time for the team and broker recipients
    uint256 public secondUnlockTime; 

    // addresses locked till second unlock time
    mapping (address => bool) public blockedTillSecondUnlock;

    // token holders
    address[] public holders;

    // holder number
    mapping (address => uint256) public holderNumber;

    // ICO address
    address public icoAddress;

    // supply constants
    uint256 public constant TOTAL_SUPPLY = 10000000 * (10 ** uint256(decimals));
    uint256 public constant SALE_SUPPLY = 5000000 * (10 ** uint256(decimals));

    // funds supply constants
    uint256 public constant BOUNTY_SUPPLY = 200000 * (10 ** uint256(decimals));
    uint256 public constant RESERVE_SUPPLY = 800000 * (10 ** uint256(decimals));
    uint256 public constant BROKER_RESERVE_SUPPLY = 1000000 * (10 ** uint256(decimals));
    uint256 public constant TEAM_SUPPLY = 3000000 * (10 ** uint256(decimals));

    // funds addresses constants
    address public constant BOUNTY_ADDRESS = 0x48c15e5A9343E3220cdD8127620AE286A204448a;
    address public constant RESERVE_ADDRESS = 0xC8fE659AaeF73b6e41DEe427c989150e3eDAf57D;
    address public constant BROKER_RESERVE_ADDRESS = 0x8697d46171aBCaD2dC5A4061b8C35f909a402417;
    address public constant TEAM_ADDRESS = 0x1761988F02C75E7c3432fa31d179cad6C5843F24;

    // min tokens to be a holder, 0.1
    uint256 public constant MIN_HOLDER_TOKENS = 10 ** uint256(decimals - 1);
    
    /**
     * @dev Constructor
     * @param _firstUnlockTime first unlock time
     * @param _secondUnlockTime second unlock time
     */
    function BetexToken
    (
        uint256 _firstUnlockTime, 
        uint256 _secondUnlockTime
    )
        public 
    {        
        require(_secondUnlockTime > firstUnlockTime);

        firstUnlockTime = _firstUnlockTime;
        secondUnlockTime = _secondUnlockTime;

        // Allocate tokens to the bounty fund
        balances[BOUNTY_ADDRESS] = BOUNTY_SUPPLY;
        holders.push(BOUNTY_ADDRESS);
        emit Transfer(0x0, BOUNTY_ADDRESS, BOUNTY_SUPPLY);

        // Allocate tokens to the reserve fund
        balances[RESERVE_ADDRESS] = RESERVE_SUPPLY;
        holders.push(RESERVE_ADDRESS);
        emit Transfer(0x0, RESERVE_ADDRESS, RESERVE_SUPPLY);

        // Allocate tokens to the broker reserve fund
        balances[BROKER_RESERVE_ADDRESS] = BROKER_RESERVE_SUPPLY;
        holders.push(BROKER_RESERVE_ADDRESS);
        emit Transfer(0x0, BROKER_RESERVE_ADDRESS, BROKER_RESERVE_SUPPLY);

        // Allocate tokens to the team fund
        balances[TEAM_ADDRESS] = TEAM_SUPPLY;
        holders.push(TEAM_ADDRESS);
        emit Transfer(0x0, TEAM_ADDRESS, TEAM_SUPPLY);

        totalSupply_ = TOTAL_SUPPLY.sub(SALE_SUPPLY);
    }

    /**
     * @dev set ICO address and allocate sale supply to it
     */
    function setICO(address _icoAddress) public onlyOwner {
        require(_icoAddress != address(0));
        require(icoAddress == address(0));
        require(totalSupply_ == TOTAL_SUPPLY.sub(SALE_SUPPLY));
        
        // Allocate tokens to the ico contract
        balances[_icoAddress] = SALE_SUPPLY;
        emit Transfer(0x0, _icoAddress, SALE_SUPPLY);

        icoAddress = _icoAddress;
        totalSupply_ = TOTAL_SUPPLY;
    }
    
    // standard transfer function with timelocks
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(transferAllowed(msg.sender));
        enforceSecondLock(msg.sender, _to);
        preserveHolders(msg.sender, _to, _value);
        return super.transfer(_to, _value);
    }

    // standard transferFrom function with timelocks
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transferAllowed(msg.sender));
        enforceSecondLock(msg.sender, _to);
        preserveHolders(_from, _to, _value);
        return super.transferFrom(_from, _to, _value);
    }

    // get holders count
    function getHoldersCount() public view returns (uint256) {
        return holders.length;
    }

    // enforce second lock on receiver
    function enforceSecondLock(address _from, address _to) internal {
        if (now < secondUnlockTime) { // solium-disable-line security/no-block-members
            if (_from == TEAM_ADDRESS || _from == BROKER_RESERVE_ADDRESS) {
                require(balances[_to] == uint256(0) || blockedTillSecondUnlock[_to]);
                blockedTillSecondUnlock[_to] = true;
            }
        }
    }

    // preserve holders list
    function preserveHolders(address _from, address _to, uint256 _value) internal {
        if (balances[_from].sub(_value) < MIN_HOLDER_TOKENS) 
            removeHolder(_from);
        if (balances[_to].add(_value) >= MIN_HOLDER_TOKENS) 
            addHolder(_to);   
    }

    // remove holder from the holders list
    function removeHolder(address _holder) internal {
        uint256 _number = holderNumber[_holder];

        if (_number == 0 || holders.length == 0 || _number > holders.length)
            return;

        uint256 _index = _number.sub(1);
        uint256 _lastIndex = holders.length.sub(1);
        address _lastHolder = holders[_lastIndex];

        if (_index != _lastIndex) {
            holders[_index] = _lastHolder;
            holderNumber[_lastHolder] = _number;
        }

        holderNumber[_holder] = 0;
        holders.length = _lastIndex;
    } 

    // add holder to the holders list
    function addHolder(address _holder) internal {
        if (holderNumber[_holder] == 0) {
            holders.push(_holder);
            holderNumber[_holder] = holders.length;
        }
    }

    // @return true if transfer operation is allowed
    function transferAllowed(address _sender) internal view returns(bool) {
        if (now > secondUnlockTime || _sender == icoAddress) // solium-disable-line security/no-block-members
            return true;
        if (now < firstUnlockTime) // solium-disable-line security/no-block-members
            return false;
        if (blockedTillSecondUnlock[_sender])
            return false;
        return true;
    }

}