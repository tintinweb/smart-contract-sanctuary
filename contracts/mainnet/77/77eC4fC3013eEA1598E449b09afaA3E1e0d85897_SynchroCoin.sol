pragma solidity ^0.4.11;

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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


contract AbstractStarbaseCrowdsale {
    function workshop() constant returns (address) {}
    function startDate() constant returns (uint256) {}
    function endedAt() constant returns (uint256) {}
    function isEnded() constant returns (bool);
    function totalRaisedAmountInCny() constant returns (uint256);
    function numOfPurchasedTokensOnCsBy(address purchaser) constant returns (uint256);
    function numOfPurchasedTokensOnEpBy(address purchaser) constant returns (uint256);
}

contract AbstractStarbaseMarketingCampaign {
    function workshop() constant returns (address) {}
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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract SynchroCoin is Ownable, StandardToken {

    string public constant symbol = "SYC";

    string public constant name = "SynchroCoin";

    uint8 public constant decimals = 12;
    

    uint256 public STARTDATE;

    uint256 public ENDDATE;

    // 55% to distribute during CrowdSale
    uint256 public crowdSale;

    // 20% to pool to reward
    // 25% to other business operations
    address public multisig;

    function SynchroCoin(
    uint256 _initialSupply,
    uint256 _start,
    uint256 _end,
    address _multisig) {
        totalSupply = _initialSupply;
        STARTDATE = _start;
        ENDDATE = _end;
        multisig = _multisig;
        crowdSale = _initialSupply * 55 / 100;
        balances[multisig] = _initialSupply;
    }

    // crowdsale statuses
    uint256 public totalFundedEther;

    //This includes the Ether raised during the presale.
    uint256 public totalConsideredFundedEther = 338;

    mapping (address => uint256) consideredFundedEtherOf;

    mapping (address => bool) withdrawalStatuses;

    function calcBonus() public constant returns (uint256){
        return calcBonusAt(now);
    }

    function calcBonusAt(uint256 at) public constant returns (uint256){
        if (at < STARTDATE) {
            return 140;
        }
        else if (at < (STARTDATE + 1 days)) {
            return 120;
        }
        else if (at < (STARTDATE + 7 days)) {
            return 115;
        }
        else if (at < (STARTDATE + 14 days)) {
            return 110;
        }
        else if (at < (STARTDATE + 21 days)) {
            return 105;
        }
        else if (at <= ENDDATE) {
            return 100;
        }
        else {
            return 0;
        }
    }


    function() public payable {
        proxyPayment(msg.sender);
    }

    function proxyPayment(address participant) public payable {
        require(now >= STARTDATE);

        require(now <= ENDDATE);

        //require msg.value >= 0.1 ether
        require(msg.value >= 100 finney);

        totalFundedEther = totalFundedEther.add(msg.value);

        uint256 _consideredEther = msg.value.mul(calcBonus()).div(100);
        totalConsideredFundedEther = totalConsideredFundedEther.add(_consideredEther);
        consideredFundedEtherOf[participant] = consideredFundedEtherOf[participant].add(_consideredEther);
        withdrawalStatuses[participant] = true;

        // Log events
        Fund(
        participant,
        msg.value,
        totalFundedEther
        );

        // Move the funds to a safe wallet
        multisig.transfer(msg.value);
    }

    event Fund(
    address indexed buyer,
    uint256 ethers,
    uint256 totalEther
    );

    function withdraw() public returns (bool success){
        return proxyWithdraw(msg.sender);
    }

    function proxyWithdraw(address participant) public returns (bool success){
        require(now > ENDDATE);
        require(withdrawalStatuses[participant]);
        require(totalConsideredFundedEther > 1);

        uint256 share = crowdSale.mul(consideredFundedEtherOf[participant]).div(totalConsideredFundedEther);
        participant.transfer(share);
        withdrawalStatuses[participant] = false;
        return true;
    }

    /* Send coins */
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(now > ENDDATE);
        return super.transfer(_to, _amount);
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _amount) public
    returns (bool success)
    {
        require(now > ENDDATE);
        return super.transferFrom(_from, _to, _amount);
    }

}