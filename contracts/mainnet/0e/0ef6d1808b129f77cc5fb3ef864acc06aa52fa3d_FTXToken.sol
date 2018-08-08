pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * https://github.com/OpenZeppelin/zeppelin-solidity/
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

  function cei(uint256 a, uint256 b) internal pure returns (uint256) {
    return ((a + b - 1) / b) * b;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 * https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 * https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

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
 * https://github.com/OpenZeppelin/zeppelin-solidity/
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool) {
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract Ownable {
  address public owner;                                                     // Operational owner.
  address public masterOwner = 0x5D1EC7558C8D1c40406913ab5dbC0Abf1C96BA42;  // for ownership transfer segregation of duty, hard coded to wallet account

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
  function transferOwnership(address newOwner) public {
    require(newOwner != address(0));
    require(masterOwner == msg.sender); // only master owner can initiate change to ownershipe
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract FTXToken is StandardToken, Ownable {

    /* metadata */
    string public constant NAME = "Fincoin";
    string public constant SYMBOL = "FTX";
    string public constant VERSION = "0.9";
    uint8 public constant DECIMALS = 18;

    /* all accounts in wei */
    uint256 public constant INITIAL_SUPPLY = 100000000 * 10**18;
    uint256 public constant FINTRUX_RESERVE_FTX = 10000000 * 10**18;
    uint256 public constant CROSS_RESERVE_FTX = 5000000 * 10**18;
    uint256 public constant TEAM_RESERVE_FTX = 10000000 * 10**18;

    // these three multi-sig addresses will be replaced on production:
    address public constant FINTRUX_RESERVE = 0x633348b01B3f59c8A445365FB2ede865ecc94a0B;
    address public constant CROSS_RESERVE = 0xED200B7BC7044290c99993341a82a21c4c7725DB;
    address public constant TEAM_RESERVE = 0xfc0Dd77c6bd889819E322FB72D4a86776b1632d5;

    // assuming Feb 28, 2018 5:00 PM UTC(1519837200) + 1 year, may change for production; 
    uint256 public constant VESTING_DATE = 1519837200 + 1 years;

    // minimum FTX token to be transferred to make the gas worthwhile (avoid micro transfer), cannot be higher than minimal subscribed amount in crowd sale.
    uint256 public token4Gas = 1*10**18;
    // gas in wei to reimburse must be the lowest minimum 0.6Gwei * 80000 gas limit.
    uint256 public gas4Token = 80000*0.6*10**9;
    // minimum wei required in an account to perform an action (avg gas price 4Gwei * avg gas limit 80000).
    uint256 public minGas4Accts = 80000*4*10**9;

    bool public allowTransfers = false;
    mapping (address => bool) public transferException;

    event Withdraw(address indexed from, address indexed to, uint256 value);
    event GasRebateFailed(address indexed to, uint256 value);

    /**
    * @dev Contructor that gives msg.sender all existing tokens. 
    */
    function FTXToken(address _owner) public {
        require(_owner != address(0));
        totalSupply = INITIAL_SUPPLY;
        balances[_owner] = INITIAL_SUPPLY - FINTRUX_RESERVE_FTX - CROSS_RESERVE_FTX - TEAM_RESERVE_FTX;
        balances[FINTRUX_RESERVE] = FINTRUX_RESERVE_FTX;
        balances[CROSS_RESERVE] = CROSS_RESERVE_FTX;
        balances[TEAM_RESERVE] = TEAM_RESERVE_FTX;
        owner = _owner;
        transferException[owner] = true;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(canTransferTokens());                                               // Team tokens lock 1 year
        require(_value > 0 && _value >= token4Gas);                                 // do nothing if less than allowed minimum but do not fail
        balances[msg.sender] = balances[msg.sender].sub(_value);                    // insufficient token balance would revert here inside safemath
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        // Keep a minimum balance of gas in all sender accounts. It would not be executed if the account has enough ETH for next action.
        if (this.balance > gas4Token && msg.sender.balance < minGas4Accts) {
            // reimburse gas in ETH to keep a minimal balance for next transaction, use send instead of transfer thus ignore failed rebate(not enough ether to rebate etc.).
            if (!msg.sender.send(gas4Token)) {
                GasRebateFailed(msg.sender,gas4Token);
            }
        }
        return true;
    }
    
    /* When necessary, adjust minimum FTX to transfer to make the gas worthwhile */
    function setToken4Gas(uint256 newFTXAmount) public onlyOwner {
        require(newFTXAmount > 0);                                                  // Upper bound is not necessary.
        token4Gas = newFTXAmount;
    }

    /* Only when necessary such as gas price change, adjust the gas to be reimbursed on every transfer when sender account below minimum */
    function setGas4Token(uint256 newGasInWei) public onlyOwner {
        require(newGasInWei > 0 && newGasInWei <= 840000*10**9);            // must be less than a reasonable gas value
        gas4Token = newGasInWei;
    }

    /* When necessary, adjust the minimum wei required in an account before an reimibusement of fee is triggerred */
    function setMinGas4Accts(uint256 minBalanceInWei) public onlyOwner {
        require(minBalanceInWei > 0 && minBalanceInWei <= 840000*10**9);    // must be less than a reasonable gas value
        minGas4Accts = minBalanceInWei;
    }

    /* This unnamed function is called whenever the owner send Ether to fund the gas fees and gas reimbursement */
    function() payable public onlyOwner {
    }

    /* Owner withdrawal for excessive gas fees deposited */
    function withdrawToOwner (uint256 weiAmt) public onlyOwner {
        require(weiAmt > 0);                                                // do not allow zero transfer
        msg.sender.transfer(weiAmt);
        Withdraw(this, msg.sender, weiAmt);                                 // signal the event for communication only it is meaningful
    }

    /*
        allow everyone to start transferring tokens freely at the same moment. 
    */
    function setAllowTransfers(bool bAllowTransfers) external onlyOwner {
        allowTransfers = bAllowTransfers;
    }

    /*
        add the ether address to whitelist to enable transfer of token.
    */
    function addToException(address addr) external onlyOwner {
        require(addr != address(0));
        require(!isException(addr));

        transferException[addr] = true;
    }

    /*
        remove the ether address from whitelist in case a mistake was made.
    */
    function delFrException(address addr) external onlyOwner {
        require(addr != address(0));
        require(transferException[addr]);

        delete transferException[addr];
    }

    /* return true when the address is in the exception list eg. token distribution contract and private sales addresses */
    function isException(address addr) public view returns (bool) {
        return transferException[addr];
    }

    /* below are internal functions */
    /*
        return true if token can be transferred.
    */
    function canTransferTokens() internal view returns (bool) {
        if (msg.sender == TEAM_RESERVE) {                                       // Vesting for FintruX TEAM is 1 year.
            return now >= VESTING_DATE;
        } else {
            // if transfer is disabled, only allow special addresses to transfer tokens.
            return allowTransfers || isException(msg.sender);
        }
    }

}