pragma solidity ^0.4.18;


//>> Reference to https://github.com/Arachnid/solidity-stringutils

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }
    
    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }
    
    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice self) internal pure returns (bool) {
        return self._len == 0;
    }
}

//<< Reference to https://github.com/Arachnid/solidity-stringutils




//>> Reference to https://github.com/OpenZeppelin/zeppelin-solidity

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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
   @title ERC827 interface, an extension of ERC20 token standard
   Interface of a ERC827 token, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
 */
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}


/**
   @title ERC827, an extension of ERC20 token standard
   Implementation the ERC827, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
   Uses OpenZeppelin StandardToken.
 */
contract ERC827Token is ERC827, StandardToken {

  /**
     @dev Addition to ERC20 token methods. It allows to
     approve the transfer of value and execute a call with the sent data.
     Beware that changing an allowance with this method brings the risk that
     someone may use both the old and the new allowance by unfortunate
     transaction ordering. One possible solution to mitigate this race condition
     is to first reduce the spender&#39;s allowance to 0 and set the desired value
     afterwards:
     https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     @param _spender The address that will spend the funds.
     @param _value The amount of tokens to be spent.
     @param _data ABI-encoded contract call to call `_to` address.
     @return true if the call function was executed successfully
   */
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

  /**
     @dev Addition to ERC20 token methods. Transfer tokens to a specified
     address and execute a call with the sent data on the same transaction
     @param _to address The address which you want to transfer to
     @param _value uint256 the amout of tokens to be transfered
     @param _data ABI-encoded contract call to call `_to` address.
     @return true if the call function was executed successfully
   */
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

  /**
     @dev Addition to ERC20 token methods. Transfer tokens from one address to
     another and make a contract call on the same transaction
     @param _from The address which you want to send tokens from
     @param _to The address which you want to transfer to
     @param _value The amout of tokens to be transferred
     @param _data ABI-encoded contract call to call `_to` address.
     @return true if the call function was executed successfully
   */
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

  /**
   * @dev Addition to StandardToken methods. Increase the amount of tokens that
   * an owner allowed to a spender and execute a call with the sent data.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call(_data));

    return true;
  }

  /**
   * @dev Addition to StandardToken methods. Decrease the amount of tokens that
   * an owner allowed to a spender and execute a call with the sent data.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   * @param _data ABI-encoded contract call to call `_spender` address.
   */
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call(_data));

    return true;
  }

}

//<< Reference to https://github.com/OpenZeppelin/zeppelin-solidity




/**
 * @title MultiOwnable
 */
contract MultiOwnable {
    address public root;
    mapping (address => address) public owners; // owner => parent of owner
    
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function MultiOwnable() public {
        root= msg.sender;
        owners[root]= root;
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(owners[msg.sender] != 0);
        _;
    }
    
    /**
    * @dev Adding new owners
    */
    function newOwner(address _owner) onlyOwner public returns (bool) {
        require(_owner != 0);
        owners[_owner]= msg.sender;
        return true;
    }
    
    /**
     * @dev Deleting owners
     */
    function deleteOwner(address _owner) onlyOwner public returns (bool) {
        require(owners[_owner] == msg.sender || (owners[_owner] != 0 && msg.sender == root));
        owners[_owner]= 0;
        return true;
    }
}


/**
 * @title KStarCoinBasic
 */
contract KStarCoinBasic is ERC827Token, MultiOwnable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;
    using strings for *;

    // KStarCoin Distribution
    // - Crowdsale : 9%(softcap) ~ 45%(hardcap)
    // - Reserve: 15%
    // - Team: 10%
    // - Advisors & Partners: 5%
    // - Bounty Program + Ecosystem : 25% ~ 61%
    uint256 public capOfTotalSupply;
    uint256 public constant INITIAL_SUPPLY= 30e6 * 1 ether; // Reserve(15) + Team(10) + Advisors&Patners(5)

    uint256 public crowdsaleRaised;
    uint256 public constant CROWDSALE_HARDCAP= 45e6 * 1 ether; // Crowdsale(Max 45)

    /**
     * @dev Function to increase capOfTotalSupply in the next phase of KStarCoin&#39;s ecosystem
     */
    function increaseCap(uint256 _addedValue) onlyOwner public returns (bool) {
        require(_addedValue >= 100e6 * 1 ether);
        capOfTotalSupply = capOfTotalSupply.add(_addedValue);
        return true;
    }
    
    /**
     * @dev Function to check whether the current supply exceeds capOfTotalSupply
     */
    function checkCap(uint256 _amount) public view returns (bool) {
        return (totalSupply_.add(_amount) <= capOfTotalSupply);
    }
    
    //> for ERC20
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(super.transfer(_to, _value));
        KSC_Send(msg.sender, _to, _value, "");
        KSC_Receive(_to, msg.sender, _value, "");
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(super.transferFrom(_from, _to, _value));
        KSC_SendTo(_from, _to, _value, "");
        KSC_ReceiveFrom(_to, _from, _value, "");
        return true;
    }
    
    function approve(address _to, uint256 _value) public returns (bool) {
        require(super.approve(_to, _value));
        KSC_Approve(msg.sender, _to, _value, "");
        return true;
    }
    
    // additional StandardToken method of zeppelin-solidity
    function increaseApproval(address _to, uint _addedValue) public returns (bool) {
        require(super.increaseApproval(_to, _addedValue));
        KSC_ApprovalInc(msg.sender, _to, _addedValue, "");
        return true;
    }
    
    // additional StandardToken method of zeppelin-solidity
    function decreaseApproval(address _to, uint _subtractedValue) public returns (bool) {
        require(super.decreaseApproval(_to, _subtractedValue));
        KSC_ApprovalDec(msg.sender, _to, _subtractedValue, "");
        return true;
    }
	//<
    
    //> for ERC827
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
        return transfer(_to, _value, _data, "");
    }
    
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
        return transferFrom(_from, _to, _value, _data, "");
    }
    
    function approve(address _to, uint256 _value, bytes _data) public returns (bool) {
        return approve(_to, _value, _data, "");
    }
    
    // additional StandardToken method of zeppelin-solidity
    function increaseApproval(address _to, uint _addedValue, bytes _data) public returns (bool) {
        return increaseApproval(_to, _addedValue, _data, "");
    }
    
    // additional StandardToken method of zeppelin-solidity
    function decreaseApproval(address _to, uint _subtractedValue, bytes _data) public returns (bool) {
        return decreaseApproval(_to, _subtractedValue, _data, "");
    }
	//<
    
    //> notation for ERC827
    function transfer(address _to, uint256 _value, bytes _data, string _note) public returns (bool) {
        require(super.transfer(_to, _value, _data));
        KSC_Send(msg.sender, _to, _value, _note);
        KSC_Receive(_to, msg.sender, _value, _note);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value, bytes _data, string _note) public returns (bool) {
        require(super.transferFrom(_from, _to, _value, _data));
        KSC_SendTo(_from, _to, _value, _note);
        KSC_ReceiveFrom(_to, _from, _value, _note);
        return true;
    }
    
    function approve(address _to, uint256 _value, bytes _data, string _note) public returns (bool) {
        require(super.approve(_to, _value, _data));
        KSC_Approve(msg.sender, _to, _value, _note);
        return true;
    }
    
    function increaseApproval(address _to, uint _addedValue, bytes _data, string _note) public returns (bool) {
        require(super.increaseApproval(_to, _addedValue, _data));
        KSC_ApprovalInc(msg.sender, _to, _addedValue, _note);
        return true;
    }
    
    function decreaseApproval(address _to, uint _subtractedValue, bytes _data, string _note) public returns (bool) {
        require(super.decreaseApproval(_to, _subtractedValue, _data));
        KSC_ApprovalDec(msg.sender, _to, _subtractedValue, _note);
        return true;
    }
	//<
      
    /**
     * @dev Function to mint coins
     * @param _to The address that will receive the minted coins.
     * @param _amount The amount of coins to mint.
     * @return A boolean that indicates if the operation was successful.
     * @dev reference : https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/MintableToken.sol
     */
    function mint(address _to, uint256 _amount) onlyOwner internal returns (bool) {
        require(_to != address(0));
        require(checkCap(_amount));

        totalSupply_= totalSupply_.add(_amount);
        balances[_to]= balances[_to].add(_amount);

        Transfer(address(0), _to, _amount);
        return true;
    }
    
    /**
     * @dev Function to mint coins
     * @param _to The address that will receive the minted coins.
     * @param _amount The amount of coins to mint.
     * @param _note The notation for ethereum blockchain event log system
     * @return A boolean that indicates if the operation was successful.
     * @dev reference : https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/MintableToken.sol
     */
    function mint(address _to, uint256 _amount, string _note) onlyOwner public returns (bool) {
        require(mint(_to, _amount));
        KSC_Mint(_to, msg.sender, _amount, _note);
        return true;
    }

    /**
     * @dev Burns a specific amount of coins.
     * @param _to The address that will be burned the coins.
     * @param _amount The amount of coins to be burned.
     * @return A boolean that indicates if the operation was successful.
     * @dev reference : https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/BurnableToken.sol
     */
    function burn(address _to, uint256 _amount) onlyOwner internal returns (bool) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);

        balances[_to]= balances[_to].sub(_amount);
        totalSupply_= totalSupply_.sub(_amount);
        
        return true;
    }
    
    /**
     * @dev Burns a specific amount of coins.
     * @param _to The address that will be burned the coins.
     * @param _amount The amount of coins to be burned.
     * @param _note The notation for ethereum blockchain event log system
     * @return A boolean that indicates if the operation was successful.
     * @dev reference : https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/BurnableToken.sol
     */
    function burn(address _to, uint256 _amount, string _note) onlyOwner public returns (bool) {
        require(burn(_to, _amount));
        KSC_Burn(_to, msg.sender, _amount, _note);
        return true;
    }
    
    // for crowdsale
    /**
     * @dev Function which allows users to buy KStarCoin during the crowdsale period
     * @param _to The address that will receive the coins.
     * @param _value The amount of coins to sell.
     * @param _note The notation for ethereum blockchain event log system
     * @return A boolean that indicates if the operation was successful.
     */
    function sell(address _to, uint256 _value, string _note) onlyOwner public returns (bool) {
        require(crowdsaleRaised.add(_value) <= CROWDSALE_HARDCAP);
        require(mint(_to, _value));
        
        crowdsaleRaised= crowdsaleRaised.add(_value);
        KSC_Buy(_to, msg.sender, _value, _note);
        return true;
    }
    
    // for buyer with cryptocurrency other than ETH
    /**
     * @dev This function is occured when owner mint coins to users as they buy with cryptocurrency other than ETH.
     * @param _to The address that will receive the coins.
     * @param _value The amount of coins to mint.
     * @param _note The notation for ethereum blockchain event log system
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToOtherCoinBuyer(address _to, uint256 _value, string _note) onlyOwner public returns (bool) {
        require(mint(_to, _value));
        KSC_BuyOtherCoin(_to, msg.sender, _value, _note);
        return true;
    }
  
    // for bounty program
    /**
     * @dev Function to reward influencers with KStarCoin
     * @param _to The address that will receive the coins.
     * @param _value The amount of coins to mint.
     * @param _note The notation for ethereum blockchain event log system
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToInfluencer(address _to, uint256 _value, string _note) onlyOwner public returns (bool) {
        require(mint(_to, _value));
        KSC_GetAsInfluencer(_to, msg.sender, _value, _note);
        return true;
    }
    
    // for KSCPoint (KStarLive ecosystem point)
    /**
     * @dev Function to exchange KSCPoint to KStarCoin
     * @param _to The address that will receive the coins.
     * @param _value The amount of coins to mint.
     * @param _note The notation for ethereum blockchain event log system
     * @return A boolean that indicates if the operation was successful.
     */
    function exchangePointToCoin(address _to, uint256 _value, string _note) onlyOwner public returns (bool) {
        require(mint(_to, _value));
        KSC_ExchangePointToCoin(_to, msg.sender, _value, _note);
        return true;
    }
    
    // Event functions to log the notation for ethereum blockchain 
    // for initializing
    event KSC_Initialize(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
    // for transfer()
    event KSC_Send(address indexed _src, address indexed _desc, uint256 _value, string _note);
    event KSC_Receive(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
    // for approve(), increaseApproval(), decreaseApproval()
    event KSC_Approve(address indexed _src, address indexed _desc, uint256 _value, string _note);
    event KSC_ApprovalInc(address indexed _src, address indexed _desc, uint256 _value, string _note);
    event KSC_ApprovalDec(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
    // for transferFrom()
    event KSC_SendTo(address indexed _src, address indexed _desc, uint256 _value, string _note);
    event KSC_ReceiveFrom(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
    // for mint(), burn()
    event KSC_Mint(address indexed _src, address indexed _desc, uint256 _value, string _note);
    event KSC_Burn(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
    // for crowdsale
    event KSC_Buy(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
    // for buyer with cryptocurrency other than ETH
    event KSC_BuyOtherCoin(address indexed _src, address indexed _desc, uint256 _value, string _note);
    
    // for bounty program
    event KSC_GetAsInfluencer(address indexed _src, address indexed _desc, uint256 _value, string _note);

    // for KSCPoint (KStarLive ecosystem point)
    event KSC_ExchangePointToCoin(address indexed _src, address indexed _desc, uint256 _value, string _note);
}


/**
 * @title KStarCoin v1.0
 * @author Tae Kim
 * @notice KStarCoin is an ERC20 (with an alternative of ERC827) Ethereum based token, which will be integrated in KStarLive platform.
 */
contract KStarCoin is KStarCoinBasic {
    string public constant name= "KStarCoin";
    string public constant symbol= "KSC";
    uint8 public constant decimals= 18;
    
    // Constructure
    function KStarCoin() public {
        totalSupply_= INITIAL_SUPPLY;
        balances[msg.sender]= INITIAL_SUPPLY;
	    capOfTotalSupply = 100e6 * 1 ether;
        crowdsaleRaised= 0;
        
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
        KSC_Initialize(msg.sender, 0x0, INITIAL_SUPPLY, "");
    }
}