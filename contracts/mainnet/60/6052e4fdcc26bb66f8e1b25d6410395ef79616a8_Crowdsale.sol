pragma solidity ^0.4.18;


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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
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
  * Modifier avoids short address attacks.
  * For more info check: https://ericrafaloff.com/analyzing-the-erc20-short-address-attack/
  */
  modifier onlyPayloadSize(uint size) {
      if (msg.data.length < size + 4) {
      revert();
      }
      _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
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
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
    require(_to != address(0));
    require(allowed[_from][msg.sender] >= _value);
    require(balances[_from] >= _value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
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
  function Ownable() internal {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable  {
    event Pause();
    event Unpause();
    event Freeze ();
    event LogFreeze();

    bool public paused = false;

    address public founder;
    
    /**
    * @dev modifier to allow actions only when the contract IS paused
    */
    modifier whenNotPaused() {
        require(!paused || msg.sender == founder);
        _;
    }

    /**
    * @dev modifier to allow actions only when the contract IS NOT paused
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused onlyPayloadSize(2 * 32) returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused onlyPayloadSize(3 * 32) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  //The functions below surve no real purpose. Even if one were to approve another to spend
  //tokens on their behalf, those tokens will still only be transferable when the token contract
  //is not paused.

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract MintableToken is PausableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract FoxTradingToken is MintableToken {

  string public name;
  string public symbol;
  uint8 public decimals;

  event TokensBurned(address initiatior, address indexed _partner, uint256 _tokens);
 

  /**
   * @dev Constructor that gives the founder all of the existing tokens.
   */
    function FoxTradingToken() public {
        name = "Fox Trading";
        symbol = "FOXT";
        decimals = 18;
        totalSupply = 3000000e18;
        founder = 0x698825d0CfeeD6F65E981FFB543ef5196A5C2A5A;
        balances[founder] = totalSupply;
        emit Transfer(0x0, founder, totalSupply);
        pause();
    }

    modifier onlyFounder {
      require(msg.sender == founder);
      _;
    }

    event NewFounderAddress(address indexed from, address indexed to);

    function changeFounderAddress(address _newFounder) public onlyFounder {
        require(_newFounder != 0x0);
        emit NewFounderAddress(founder, _newFounder);
        founder = _newFounder;
    }

    /*
    * @dev Token burn function to be called at the time of token swap
    * @param _partner address to use for token balance buring
    * @param _tokens uint256 amount of tokens to burn
    */
    function burnTokens(address _partner, uint256 _tokens) public onlyFounder {
        require(balances[_partner] >= _tokens);
        balances[_partner] = balances[_partner].sub(_tokens);
        totalSupply = totalSupply.sub(_tokens);
        emit TokensBurned(msg.sender, _partner, _tokens);
    }
}


contract Crowdsale is Ownable {

    using SafeMath for uint256;

    FoxTradingToken public token;

    uint256 public tokenCapForFirstMainStage;
    uint256 public tokenCapForSecondMainStage;
    uint256 public tokenCapForThirdMainStage;
    uint256 public tokenCapForFourthMainStage;
    uint256 public totalTokensForSale;
    uint256 public startTime;
    uint256 public endTime;
    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;
    bool public ICOpaused;

    uint256[4] public ICObonusStages;

    uint256 public tokensSold;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event ICOSaleExtended(uint256 newEndTime);

    function Crowdsale() public {
        token = new FoxTradingToken();  
        startTime = now; 
        rate = 1200;
        wallet = 0x698825d0CfeeD6F65E981FFB543ef5196A5C2A5A;
        totalTokensForSale = 6200000e18;
        tokensSold = 0;

        tokenCapForFirstMainStage = 1000000e18;
        tokenCapForSecondMainStage = 2000000e18;  
        tokenCapForThirdMainStage = 3000000e18;  
        tokenCapForFourthMainStage = 6200000e18; 
    
        ICObonusStages[0] = now.add(7 days);
        for (uint y = 1; y < ICObonusStages.length; y++) {
            ICObonusStages[y] = ICObonusStages[y - 1].add(7 days);
        }
        
        endTime = ICObonusStages[3];
        
        ICOpaused = false;
    }
    
    modifier whenNotPaused {
        require(!ICOpaused);
        _;
    }

    function() external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _addr) public payable whenNotPaused {
        require(validPurchase() && tokensSold < totalTokensForSale);
        require(_addr != 0x0 && msg.value >= 100 finney);  
        uint256 toMint;
        toMint = msg.value.mul(getRateWithBonus());
        tokensSold = tokensSold.add(toMint);
        token.mint(_addr, toMint);
        forwardFunds();
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function processOfflinePurchase(address _to, uint256 _toMint) public onlyOwner {
        require(tokensSold.add(_toMint) <= totalTokensForSale);
        require(_toMint > 0 && _to != 0x0);
        tokensSold = tokensSold.add(_toMint);
        token.mint(_to, _toMint);
    }
    
    
    /**
     * @param _addrs The array of ETH addresses
     * @param _values The amount of tokens to send to each address
     * */
    function airDrop(address[] _addrs, uint256[] _values) public onlyOwner {
        //require(_addrs.length > 0);
        for (uint i = 0; i < _addrs.length; i++) {
            if (_addrs[i] != 0x0 && _values[i] > 0) {
                token.mint(_addrs[i], _values[i]);
            }
        }
    }


    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime; 
        bool nonZeroPurchase = msg.value != 0; 
        return withinPeriod && nonZeroPurchase;
    }

    
    function finishMinting() public onlyOwner {
        token.finishMinting();
    }
    
    function getRateWithBonus() internal view returns (uint256 rateWithDiscount) {
        if (tokensSold < totalTokensForSale) {
            return rate.mul(getCurrentBonus()).div(100).add(rate);
            return rateWithDiscount;
        }
        return rate;
    }

    /**
    * Function is called when the buy function is invoked  only after the pre sale duration and returns 
    * the current discount in percentage.
    *
    * day 31 - 37   / week 1: 20%
    * day 38 - 44   / week 2: 15%
    * day 45 - 51   / week 3: 10%
    * day 52 - 58   / week 4:  0%
    */
    function getCurrentBonus() internal view returns (uint256 discount) {
        require(tokensSold < tokenCapForFourthMainStage);
        uint256 timeStamp = now;
        uint256 stage;

        for (uint i = 0; i < ICObonusStages.length; i++) {
            if (timeStamp <= ICObonusStages[i]) {
                stage = i + 1;
                break;
            } 
        } 

        if(stage == 1 && tokensSold < tokenCapForFirstMainStage) { discount = 20; }
        if(stage == 1 && tokensSold >= tokenCapForFirstMainStage) { discount = 15; }
        if(stage == 1 && tokensSold >= tokenCapForSecondMainStage) { discount = 10; }
        if(stage == 1 && tokensSold >= tokenCapForThirdMainStage) { discount = 0; }

        if(stage == 2 && tokensSold < tokenCapForSecondMainStage) { discount = 15; }
        if(stage == 2 && tokensSold >= tokenCapForSecondMainStage) { discount = 10; }
        if(stage == 2 && tokensSold >= tokenCapForThirdMainStage) { discount = 0; }

        if(stage == 3 && tokensSold < tokenCapForThirdMainStage) { discount = 10; }
        if(stage == 3 && tokensSold >= tokenCapForThirdMainStage) { discount = 0; }

        if(stage == 4) { discount = 0; }

        return discount;
    }



    function extendDuration(uint256 _newEndTime) public onlyOwner {
        require(endTime < _newEndTime);
        endTime = _newEndTime;
        emit ICOSaleExtended(_newEndTime);
    }


    function hasEnded() public view returns (bool) { 
        return now > endTime;
    }

    /**
    * Allows the owner of the ICO contract to unpause the token contract. This function is needed
    * because the ICO contract deploys a new instance of the token contract, and by default the 
    * ETH address which deploys a contract which is Ownable is assigned ownership of the contract,
    * so the ICO contract is the owner of the token contract. Since unpause is a function which can
    * only be executed by the owner, by adding this function here, then the owner of the ICO contract
    * can call this and then the ICO contract will invoke the unpause function of the token contract
    * and thus the token contract will successfully unpause as its owner the ICO contract invokend
    * the the function. 
    */
    function unpauseToken() public onlyOwner {
        token.unpause();
    }
    
    function pauseUnpauseICO() public onlyOwner {
        if (ICOpaused) {
            ICOpaused = false;
        } else {
            ICOpaused = true;
        }
    }
}