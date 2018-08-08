pragma solidity ^0.4.13;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function add(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function sub(uint256 x, uint256 y) internal returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function mul(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
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
/*
 * Haltable
 *
 * Abstract contract that allows children to implement an
 * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
 *
 *
 * Originally envisioned in FirstBlood ICO contract.
 */
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require (!halted);
    _;
  }

  modifier onlyInEmergency {
    require (halted);
    _;
  }

  // called by the owner on emergency, triggers stopped state
  function halt() external onlyOwner {
    halted = true;
  }

  // called by the owner on end of emergency, returns to normal state
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
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
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract preDGZToken is StandardToken {
    using SafeMath for uint256;

    /*/ Public variables of the token /*/
    string public constant name = "Dogezer preDGZ Token";
    string public constant symbol = "preDGZ";
    uint8 public decimals = 8;
    uint256 public totalSupply = 200000000000000;

    /*/ Initializes contract with initial supply tokens to the creator of the contract /*/
    function preDGZToken() 
    {
        balances[msg.sender] = totalSupply;              // Give the creator all initial tokens
    }
}



contract DogezerPreICOCrowdsale is Haltable{
    using SafeMath for uint;
    string public name = "Dogezer preITO";

    address public beneficiary;
    uint public startTime;
    uint public duration;


    uint public fundingGoal; 
    uint public amountRaised; 
    uint public price; 
    preDGZToken public tokenReward;

    mapping(address => uint256) public balanceOf;

    event SaleFinished(uint finishAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    bool public crowdsaleClosed = false;


    /*  at initialization, setup the owner */
    function DogezerPreICOCrowdsale(
        address addressOfTokenUsedAsReward,
		address addressOfBeneficiary
    ) {
        beneficiary = addressOfBeneficiary;
        startTime = 1504270800;
        duration = 707 hours;
        fundingGoal = 4000 * 1 ether;
        amountRaised = 0;
        price = 0.00000000002 * 1 ether;
        tokenReward = preDGZToken(addressOfTokenUsedAsReward);
    }

    modifier onlyAfterStart() {
        require (now >= startTime);
        _;
    }

    modifier onlyBeforeEnd() {
        require (now <= startTime + duration);
        _;
    }

    /* The function without name is the default function that is called whenever anyone sends funds to a contract */
    function () payable stopInEmergency onlyAfterStart onlyBeforeEnd
    {
		require (msg.value >= 0.002 * 1 ether);
        require (crowdsaleClosed == false);
        require (fundingGoal >= amountRaised + msg.value);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;  
        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true); 
        if (amountRaised == fundingGoal)
        {
            crowdsaleClosed = true;
            SaleFinished(amountRaised);
        }
    }
 
   function withdrawal (uint amountWithdraw) onlyOwner
   {
		beneficiary.transfer(amountWithdraw);
   }
   
   function changeBeneficiary(address newBeneficiary) onlyOwner {
		if (newBeneficiary != address(0)) {
		  beneficiary = newBeneficiary;
		}
	}
   
   function finalizeSale () onlyOwner
   {
       require (crowdsaleClosed == false);
       crowdsaleClosed = true;
       SaleFinished(amountRaised);
   }
}