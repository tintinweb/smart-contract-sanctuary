pragma solidity ^0.4.23;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
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
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

// File: contracts/MidasToken.sol

contract MidasToken is StandardToken, Pausable {
    string public constant name = &#39;MidasProtocol&#39;;
    string public constant symbol = &#39;MAS&#39;;
    uint256 public constant minTomoContribution = 100 ether;
    uint256 public constant minEthContribution = 0.1 ether;
    uint256 public constant maxEthContribution = 500 ether;
    uint256 public constant ethConvertRate = 10000; // 1 ETH = 10000 MAS
    uint256 public constant tomoConvertRate = 10; // 1 TOMO = 10 MAS
    uint256 public totalTokenSold = 0;
    uint256 public maxCap = maxEthContribution.mul(ethConvertRate); // Max MAS can buy

    uint256 public constant decimals = 18;
    address public tokenSaleAddress;
    address public midasDepositAddress;
    address public ethFundDepositAddress;
    address public midasFounderAddress;
    address public midasAdvisorOperateMarketingAddress;

    uint256 public fundingStartTime;
    uint256 public fundingEndTime;

    uint256 public constant midasDeposit = 500000000 * 10 ** decimals; // 500.000.000 tokens
    uint256 public constant tokenCreationCap = 5000000 * 10 ** 18; // 5.000.000 token for sale

    mapping(address => bool) public frozenAccount;
    mapping(address => uint256) public participated;

    mapping(address => uint256) public whitelist;
    bool public isFinalized;
    bool public isTransferable;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    event BuyByEth(address from, address to, uint256 val);
    event BuyByTomo(address from, address to, uint256 val);
    event ListAddress(address _user, uint256 cap, uint256 _time);
    event RefundMidas(address to, uint256 val);

    //============== MIDAS TOKEN ===================//

    constructor (address _midasDepositAddress, address _ethFundDepositAddress, address _midasFounderAddress, address _midasAdvisorOperateMarketingAddress, uint256 _fundingStartTime, uint256 _fundingEndTime) public {
        midasDepositAddress = _midasDepositAddress;
        ethFundDepositAddress = _ethFundDepositAddress;
        midasFounderAddress = _midasFounderAddress;
        midasAdvisorOperateMarketingAddress = _midasAdvisorOperateMarketingAddress;

        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;

        balances[midasDepositAddress] = midasDeposit;
        emit Transfer(0x0, midasDepositAddress, midasDeposit);
        totalSupply_ = midasDeposit;
        isFinalized = false;
        isTransferable = true;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(isTransferable == true || msg.sender == midasAdvisorOperateMarketingAddress || msg.sender == midasDepositAddress);
        return super.transfer(_to, _value);
    }

    function setTransferStatus(bool status) public onlyOwner {
        isTransferable = status;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        return super.approve(_spender, _value);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

    function freezeAccounts(address[] _targets, bool _freeze) onlyOwner public {
        for (uint i = 0; i < _targets.length; i++) {
            freezeAccount(_targets[i], _freeze);
        }
    }

    //============== MIDAS PIONEER SALE ===================//

    //============== MIDAS WHITELIST ===================//

    function listAddress(address _user, uint256 cap) public onlyOwner {
        whitelist[_user] = cap;
        emit ListAddress(_user, cap, now);
    }

    function listAddresses(address[] _users, uint256[] _caps) public onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            listAddress(_users[i], _caps[i]);
        }
    }

    function getCap(address _user) public view returns (uint) {
        return whitelist[_user];
    }

    //============== MIDAS PUBLIC SALE =================//

    function() public payable {
        buyByEth(msg.sender, msg.value);
    }

    function buyByEth(address _recipient, uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(now >= fundingStartTime);
        require(now <= fundingEndTime);
        require(_value >= minEthContribution);
        require(_value <= maxEthContribution);
        require(!isFinalized);
        require(totalTokenSold < tokenCreationCap);

        uint256 tokens = _value.mul(ethConvertRate);

        uint256 cap = getCap(_recipient);
        require(cap > 0);

        uint256 tokensToAllocate = 0;
        uint256 tokensToRefund = 0;
        uint256 etherToRefund = 0;

        tokensToAllocate = maxCap.sub(participated[_recipient]);

        // calculate refund if over max cap or individual cap
        if (tokens > tokensToAllocate) {
            tokensToRefund = tokens.sub(tokensToAllocate);
            etherToRefund = tokensToRefund.div(ethConvertRate);
        } else {
            // user can buy amount they want
            tokensToAllocate = tokens;
        }

        uint256 checkedTokenSold = totalTokenSold.add(tokensToAllocate);

        // if reaches hard cap
        if (tokenCreationCap < checkedTokenSold) {
            tokensToAllocate = tokenCreationCap.sub(totalTokenSold);
            tokensToRefund = tokens.sub(tokensToAllocate);
            etherToRefund = tokensToRefund.div(ethConvertRate);
            totalTokenSold = tokenCreationCap;
        } else {
            totalTokenSold = checkedTokenSold;
        }

        // save to participated data
        participated[_recipient] = participated[_recipient].add(tokensToAllocate);

        // allocate tokens
        balances[midasDepositAddress] = balances[midasDepositAddress].sub(tokensToAllocate);
        balances[_recipient] = balances[_recipient].add(tokensToAllocate);

        // refund ether
        if (etherToRefund > 0) {
            // refund in case user buy over hard cap, individual cap
            emit RefundMidas(msg.sender, etherToRefund);
            msg.sender.transfer(etherToRefund);
        }
        ethFundDepositAddress.transfer(address(this).balance);
        //        // lock this account balance
        emit BuyByEth(midasDepositAddress, _recipient, _value);
        return true;
    }

    function buyByTomo(address _recipient, uint256 _value) public onlyOwner returns (bool success) {
        require(_value > 0);
        require(now >= fundingStartTime);
        require(now <= fundingEndTime);
        require(_value >= minTomoContribution);
        require(!isFinalized);
        require(totalTokenSold < tokenCreationCap);

        uint256 tokens = _value.mul(tomoConvertRate);

        uint256 cap = getCap(_recipient);
        require(cap > 0);

        uint256 tokensToAllocate = 0;
        uint256 tokensToRefund = 0;
        tokensToAllocate = maxCap;
        // calculate refund if over max cap or individual cap
        if (tokens > tokensToAllocate) {
            tokensToRefund = tokens.sub(tokensToAllocate);
        } else {
            // user can buy amount they want
            tokensToAllocate = tokens;
        }

        uint256 checkedTokenSold = totalTokenSold.add(tokensToAllocate);

        // if reaches hard cap
        if (tokenCreationCap < checkedTokenSold) {
            tokensToAllocate = tokenCreationCap.sub(totalTokenSold);
            totalTokenSold = tokenCreationCap;
        } else {
            totalTokenSold = checkedTokenSold;
        }

        // allocate tokens
        balances[midasDepositAddress] = balances[midasDepositAddress].sub(tokensToAllocate);
        balances[_recipient] = balances[_recipient].add(tokensToAllocate);

        emit BuyByTomo(midasDepositAddress, _recipient, _value);
        return true;
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external onlyOwner {
        require(!isFinalized);
        // move to operational
        isFinalized = true;
        ethFundDepositAddress.transfer(address(this).balance);
    }
}