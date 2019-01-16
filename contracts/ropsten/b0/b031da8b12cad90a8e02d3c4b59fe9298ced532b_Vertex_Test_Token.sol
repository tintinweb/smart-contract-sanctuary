pragma solidity ^0.4.24;

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
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
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
   emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    // OwnershipTransferred(owner, newOwner);
   emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
   emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract TokenFreeze is Ownable, StandardToken {
  uint256 public unfreeze_date;
  
  event FreezeDateChanged(string message, uint256 date);

  function TokenFreeze() public {
    unfreeze_date = now;
  }

  modifier freezed() {
    require(unfreeze_date < now);
    _;
  }

  function changeFreezeDate(uint256 datetime) onlyOwner public {
    require(datetime != 0);
    unfreeze_date = datetime;
  emit  FreezeDateChanged("Unfreeze Date: ", datetime);
  }
  
  function transferFrom(address _from, address _to, uint256 _value) freezed public returns (bool) {
    super.transferFrom(_from, _to, _value);
  }

  function transfer(address _to, uint256 _value) freezed public returns (bool) {
    super.transfer(_to, _value);
  }

}

contract Whitelisted  {

  Whitelist.List private _list;
  
  modifier onlyWhitelisted() {
    require(Whitelist.check(_list, msg.sender) == true);
    _;
  }

  event AddressAdded(address _addr);
  event AddressRemoved(address _addr);
  
  function WhitelistedAddress()
  public
  {
    Whitelist.add(_list, msg.sender);
  }

  function WhitelistAddressenable(address _addr)
    public
  {
    Whitelist.add(_list, _addr);
    emit AddressAdded(_addr);
  }

  function WhitelistAddressdisable(address _addr)
    public
  {
    Whitelist.remove(_list, _addr);
   emit AddressRemoved(_addr);
  }
  
  function WhitelistAddressisListed(address _addr)
  public
  view
  returns (bool)
  {
      return Whitelist.check(_list, _addr);
  }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is TokenFreeze, Whitelisted {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  
  string public constant name = "Tertex";
  string public constant symbol = "Ttex";
  uint8 public constant decimals = 8;  // 18 is the most common number of decimal places
  bool public mintingFinished = false;
 
  mapping (address => bool) public whitelist; 
  
  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    
    totalSupply = totalSupply.add(_amount);
    require(totalSupply <= 30000000000000);
    balances[_to] = balances[_to].add(_amount);
    emit  Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

library Whitelist {
  
  struct List {
    mapping(address => bool) valid_address;
  }
  
  function add(List storage list, address _addr)
    internal
  {
    list.valid_address[_addr] = true;
  }

  function remove(List storage list, address _addr)
    internal
  {
    list.valid_address[_addr] = false;
  }

  function check(List storage list, address _addr)
    view
    internal
    returns (bool)
  {
    return list.valid_address[_addr];
  }
}


//For production, change all days to days
//Change and check days and discounts
contract Vertex_Test_Token is Ownable,  Whitelisted, MintableToken {
    using SafeMath for uint256;

    // The token being sold
    MintableToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    // uint256 public PrivateSaleStartTime;
    // uint256 public PrivateSaleEndTime;
    uint256 public ICOStartTime = 1548380800;
    uint256 public ICOEndTime = 1549903200;

    uint256 public hardCap = 300000000;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;
    uint256 public weiRaised;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Vertex_Token(uint256 _rate, address _wallet, uint256 _unfreeze_date)  public {
        require(_rate > 0);
        require(_wallet != address(0));

        token = createTokenContract();

        rate = _rate;
        wallet = _wallet;
        
        token.changeFreezeDate(_unfreeze_date);
    }
   
    // function startICO() onlyOwner public {
    //     require(ICOStartTime == 0);
    //     ICOStartTime = now;
    //     ICOEndTime = ICOStartTime + 112 days;
    // }
    // function stopICO() onlyOwner public {
    //     require(ICOEndTime > now);
    //     ICOEndTime = now;
    // }
    
    function changeTokenFreezeDate(uint256 _new_date) onlyOwner public {
        token.changeFreezeDate(_new_date);
    }
    
    function unfreezeTokens() onlyOwner public {
        token.changeFreezeDate(now);
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    function createTokenContract() internal returns (MintableToken) {
        return new MintableToken();
    }

    // fallback function can be used to buy tokens
    function () payable public {
        buyTokens(msg.sender);
    }

    //return token price in cents
    function getUSDPrice() public constant returns (uint256 cents_by_token) {
        uint256 total_tokens = SafeMath.div(totalTokenSupply(), token.decimals());

        if (total_tokens > 165000000)
            return 24;
        else if (total_tokens > 150000000)
            return 23;
        else if (total_tokens > 135000000)
            return 22;
        else if (total_tokens > 120000000)
            return 21;
        else if (total_tokens > 105000000)
            return 20;
        else if (total_tokens > 90000000)
            return 19;
        else if (total_tokens > 75000000)
            return 18;
        else if (total_tokens > 60000000)
            return 17;
        else if (total_tokens > 45000000)
            return 16;
        else if (total_tokens > 30000000)
            return 15;
        else if (total_tokens > 15000000)
            return 10;
        else
            return 5;
    }
    // function calcBonus(uint256 tokens, uint256 ethers) public constant returns (uint256 tokens_with_bonus) {
    //     return tokens;
    // }
    // string 123.45 to 12345 converter
    function stringFloatToUnsigned(string _s) payable public returns (string) {
        bytes memory _new_s = new bytes(bytes(_s).length - 1);
        uint k = 0;

        for (uint i = 0; i < bytes(_s).length; i++) {
            if (bytes(_s)[i] == &#39;.&#39;) { break; } // 1

            _new_s[k] = bytes(_s)[i];
            k++;
        }

        return string(_new_s);
    }
    
    
     
     function withdraw(uint amount) onlyOwner returns(bool) {
         require(amount < this.balance);
        wallet.transfer(amount);
        return true;

    }

   

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    
   //end
    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        // require(WhitelistAddressisListed(beneficiary));
        require(validPurchase());
        require(msg.value >= SafeMath.mul(rate, 50));  // minimum contrib amount 50 USD

        uint256 _convert_rate = SafeMath.div(SafeMath.mul(rate, getUSDPrice()), 100);

        // calculate token amount to be created
        uint256 weiAmount = SafeMath.mul(msg.value, 10**uint256(token.decimals()));
        uint256 tokens = SafeMath.div(weiAmount, _convert_rate);
        require(tokens > 0);
        
        //do not need bonus of contrib amount calc
        // tokens = calcBonus(tokens, msg.value.div(10**uint256(token.decimals())));

        // update state
        weiRaised = SafeMath.add(weiRaised, msg.value);

        // token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, msg.value, tokens);
        // forwardFunds();
    }


    //to send tokens for bitcoin bakers and bounty
    function sendTokens(address _to, uint256 _amount) onlyOwner public {
        token.mint(_to, _amount);
    }
    //change owner for child contract
    function transferTokenOwnership(address _newOwner) onlyOwner public {
        token.transferOwnership(_newOwner);
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(address(this).balance);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal constant returns (bool) {
        bool hardCapOk = token.totalSupply() < SafeMath.mul(hardCap, 10**uint256(token.decimals()));
       // bool withinPrivateSalePeriod = now >= PrivateSaleStartTime && now <= PrivateSaleEndTime;
        bool withinICOPeriod = now >= ICOStartTime && now <= ICOEndTime;
        bool nonZeroPurchase = msg.value != 0;
        
        // private-sale hardcap
        uint256 total_tokens = SafeMath.div(totalTokenSupply(), token.decimals());
        // if (withinPrivateSalePeriod && total_tokens >= 30000000)
        // {
        //     stopPrivateSale();
        //     return false;
        // }
        
        // return hardCapOk && (withinICOPeriod || withinPrivateSalePeriod) && nonZeroPurchase;
         return hardCapOk && withinICOPeriod && nonZeroPurchase;
    }
    
    // total supply of tokens
    function totalTokenSupply() public view returns (uint256) {
        return token.totalSupply();
    }
}