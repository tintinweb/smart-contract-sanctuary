pragma solidity ^0.4.19;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/StandardToken.sol

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

// File: contracts/NaviToken.sol

contract NaviToken is StandardToken, Ownable {
    event AssignmentStopped();
    event Frosted(address indexed to, uint256 amount, uint256 defrostClass);
    event Defrosted(address indexed to, uint256 amount, uint256 defrostClass);

	using SafeMath for uint256;

    /* Overriding some ERC20 variables */
    string public constant name      = "NaviToken";
    string public constant symbol    = "NAVI";
    uint8 public constant decimals   = 18;

    uint256 public constant MAX_NUM_NAVITOKENS    = 1000000000 * 10 ** uint256(decimals);
    uint256 public constant START_ICO_TIMESTAMP   = 1519912800;  // TODO: line to uncomment for the PROD before the main net deployment
    //uint256 public START_ICO_TIMESTAMP; // TODO: !!! line to remove before the main net deployment (not constant for testing and overwritten in the constructor)

    uint256 public constant MONTH_IN_MINUTES = 43200; // month in minutes  (1month = 43200 min)
    uint256 public constant DEFROST_AFTER_MONTHS = 6;

    uint256 public constant DEFROST_FACTOR_TEAMANDADV = 30;

    enum DefrostClass {Contributor, ReserveAndTeam, Advisor}

    // Fields that can be changed by functions
    address[] icedBalancesReserveAndTeam;
    mapping (address => uint256) mapIcedBalancesReserveAndTeamFrosted;
    mapping (address => uint256) mapIcedBalancesReserveAndTeamDefrosted;

    address[] icedBalancesAdvisors;
    mapping (address => uint256) mapIcedBalancesAdvisors;

    //Boolean to allow or not the initial assignement of token (batch)
    bool public batchAssignStopped = false;

    modifier canAssign() {
        require(!batchAssignStopped);
        require(elapsedMonthsFromICOStart() < 2);
        _;
    }

    function NaviToken() public {
        // for test only: set START_ICO to contract creation timestamp
        //START_ICO_TIMESTAMP = now; // TODO: line to remove before the main net deployment
    }

    /**
    * @dev Transfer tokens in batches (of addresses)
    * @param _addr address The address which you want to send tokens from
    * @param _amounts address The address which you want to transfer to
    */
    function batchAssignTokens(address[] _addr, uint256[] _amounts, DefrostClass[] _defrostClass) public onlyOwner canAssign {
        require(_addr.length == _amounts.length && _addr.length == _defrostClass.length);
        //Looping into input arrays to assign target amount to each given address
        for (uint256 index = 0; index < _addr.length; index++) {
            address toAddress = _addr[index];
            uint amount = _amounts[index];
            DefrostClass defrostClass = _defrostClass[index]; // 0 = ico contributor, 1 = reserve and team , 2 = advisor

            totalSupply = totalSupply.add(amount);
            require(totalSupply <= MAX_NUM_NAVITOKENS);

            if (defrostClass == DefrostClass.Contributor) {
                // contributor account
                balances[toAddress] = balances[toAddress].add(amount);
                Transfer(address(0), toAddress, amount);
            } else if (defrostClass == DefrostClass.ReserveAndTeam) {
                // Iced account. The balance is not affected here
                icedBalancesReserveAndTeam.push(toAddress);
                mapIcedBalancesReserveAndTeamFrosted[toAddress] = mapIcedBalancesReserveAndTeamFrosted[toAddress].add(amount);
                Frosted(toAddress, amount, uint256(defrostClass));
            } else if (defrostClass == DefrostClass.Advisor) {
                // advisors account: tokens to defrost
                icedBalancesAdvisors.push(toAddress);
                mapIcedBalancesAdvisors[toAddress] = mapIcedBalancesAdvisors[toAddress].add(amount);
                Frosted(toAddress, amount, uint256(defrostClass));
            }
        }
    }

    function elapsedMonthsFromICOStart() view public returns (uint256) {
       return (now <= START_ICO_TIMESTAMP) ? 0 : (now - START_ICO_TIMESTAMP) / 60 / MONTH_IN_MINUTES;
    }

    function canDefrostReserveAndTeam() view public returns (bool) {
        return elapsedMonthsFromICOStart() > DEFROST_AFTER_MONTHS;
    }

    function defrostReserveAndTeamTokens() public {
        require(canDefrostReserveAndTeam());

        uint256 monthsIndex = elapsedMonthsFromICOStart() - DEFROST_AFTER_MONTHS;

        if (monthsIndex > DEFROST_FACTOR_TEAMANDADV){
            monthsIndex = DEFROST_FACTOR_TEAMANDADV;
        }

        // Looping into the iced accounts
        for (uint256 index = 0; index < icedBalancesReserveAndTeam.length; index++) {

            address currentAddress = icedBalancesReserveAndTeam[index];
            uint256 amountTotal = mapIcedBalancesReserveAndTeamFrosted[currentAddress].add(mapIcedBalancesReserveAndTeamDefrosted[currentAddress]);
            uint256 targetDefrosted = monthsIndex.mul(amountTotal).div(DEFROST_FACTOR_TEAMANDADV);
            uint256 amountToRelease = targetDefrosted.sub(mapIcedBalancesReserveAndTeamDefrosted[currentAddress]);

            if (amountToRelease > 0) {
                mapIcedBalancesReserveAndTeamFrosted[currentAddress] = mapIcedBalancesReserveAndTeamFrosted[currentAddress].sub(amountToRelease);
                mapIcedBalancesReserveAndTeamDefrosted[currentAddress] = mapIcedBalancesReserveAndTeamDefrosted[currentAddress].add(amountToRelease);
                balances[currentAddress] = balances[currentAddress].add(amountToRelease);

                Transfer(address(0), currentAddress, amountToRelease);
                Defrosted(currentAddress, amountToRelease, uint256(DefrostClass.ReserveAndTeam));
            }
        }
    }

    function canDefrostAdvisors() view public returns (bool) {
        return elapsedMonthsFromICOStart() >= DEFROST_AFTER_MONTHS;
    }

    function defrostAdvisorsTokens() public {
        require(canDefrostAdvisors());
        for (uint256 index = 0; index < icedBalancesAdvisors.length; index++) {
            address currentAddress = icedBalancesAdvisors[index];
            uint256 amountToDefrost = mapIcedBalancesAdvisors[currentAddress];
            if (amountToDefrost > 0) {
                balances[currentAddress] = balances[currentAddress].add(amountToDefrost);
                mapIcedBalancesAdvisors[currentAddress] = mapIcedBalancesAdvisors[currentAddress].sub(amountToDefrost);

                Transfer(address(0), currentAddress, amountToDefrost);
                Defrosted(currentAddress, amountToDefrost, uint256(DefrostClass.Advisor));
            }
        }
    }

    function stopBatchAssign() public onlyOwner canAssign {
        batchAssignStopped = true;
        AssignmentStopped();
    }

    function() public payable {
        revert();
    }
}