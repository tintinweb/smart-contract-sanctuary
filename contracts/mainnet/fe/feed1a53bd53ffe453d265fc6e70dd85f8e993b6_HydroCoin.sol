pragma solidity ^0.4.13;


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


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

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
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(0X0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}



contract HydroCoin is MintableToken, Pausable {
  string public name = "H2O Token";
  string public symbol = "H2O";
  uint256 public decimals = 18;

  //----- splitter functions


    event Ev(string message, address whom, uint256 val);

    struct XRec {
        bool inList;
        address next;
        address prev;
        uint256 val;
    }

    struct QueueRecord {
        address whom;
        uint256 val;
    }

    address public first = 0x0;
    address public last = 0x0;
    bool    public queueMode;
    uint256 public pos;

    mapping (address => XRec) public theList;

    QueueRecord[]  theQueue;

    function startQueueing() onlyOwner {
        queueMode = true;
        pos = 0;
    }

    function stopQueueing(uint256 num) onlyOwner {
        queueMode = false;
        for (uint256 i = 0; i < num; i++) {
            if (pos >= theQueue.length) {
                delete theQueue;
                return;
            }
            update(theQueue[pos].whom,theQueue[pos].val);
            pos++;
        }
        queueMode = true;
    } 

   function queueLength() constant returns (uint256) {
        return theQueue.length;
    }

    function addRecToQueue(address whom, uint256 val) internal {
        theQueue.push(QueueRecord(whom,val));
    }

    // add a record to the END of the list
    function add(address whom, uint256 value) internal {
        theList[whom] = XRec(true,0x0,last,value);
        if (last != 0x0) {
            theList[last].next = whom;
        } else {
            first = whom;
        }
        last = whom;
        Ev("add",whom,value);
    }

   function remove(address whom) internal {
        if (first == whom) {
            first = theList[whom].next;
            theList[whom] = XRec(false,0x0,0x0,0);
            Ev("remove",whom,0);
            return;
        }
        address next = theList[whom].next;
        address prev = theList[whom].prev;
        if (prev != 0x0) {
            theList[prev].next = next;
        }
        if (next != 0x0) {
            theList[next].prev = prev;
        }
        if (last == whom) {
            last = prev;
        }

        theList[whom] =XRec(false,0x0,0x0,0);
        Ev("remove",whom,0);
    }

    function update(address whom, uint256 value) internal {
        if (queueMode) {
            addRecToQueue(whom,value);
            return;
        }
        if (value != 0) {
            if (!theList[whom].inList) {
                add(whom,value);
            } else {
                theList[whom].val = value;
                Ev("update",whom,value);
            }
            return;
        }
        if (theList[whom].inList) {
                remove(whom);
        }
    }




// ----- H20 stuff -----


  /**
   * @dev Allows anyone to transfer the H20 tokens once trading has started
   * @param _to the recipient address of the tokens.
   * @param _value number of tokens to be transfered.
   */
  function transfer(address _to, uint _value) whenNotPaused returns (bool) {
      bool result = super.transfer(_to, _value);
      update(msg.sender,balances[msg.sender]);
      update(_to,balances[_to]);
      return result;
  }

  /**
   * @dev Allows anyone to transfer the H20 tokens once trading has started
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
      bool result = super.transferFrom(_from, _to, _value);
      update(_from,balances[_from]);
      update(_to,balances[_to]);
      return result;
  }

 /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
 
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
      bool result = super.mint(_to,_amount);
      update(_to,balances[_to]);
      return result;
  }

  function emergencyERC20Drain( ERC20 token, uint amount ) {
      token.transfer(owner, amount);
  }
 
}


contract HydroCoinPresale is Ownable,Pausable {
  using SafeMath for uint256;

  // The token being sold
  HydroCoin public token;

  // start and end block where investments are allowed (both inclusive)
  uint256 public startTimestamp; 
  uint256 public endTimestamp;

  // address where funds are collected
  address public hardwareWallet = 0xa6128CA2eD94FB697d7058dC3Fd22740F82FF06A;

  mapping (address => uint256) public deposits;

  // how many token units a buyer gets per wei
  uint256 public rate = 125;

  // amount of raised money in wei
  uint256 public weiRaised;

  // minimum contributio to participate in tokensale
  uint256 public minContribution  = 50 ether;

  // maximum amount of ether being raised
  uint256 public hardcap  = 1500 ether; 

  // amount to allocate to vendors
  uint256 public vendorAllocation  = 1000000 * 10 ** 18; // H20

  // number of participants in presale
  uint256 public numberOfPurchasers = 0;

  address public companyTokens = 0xF1D5007d3884B8Ec6C2f89088b2bA28C5291C70f;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event PreSaleClosed();

  function setWallet(address _wallet) onlyOwner {
    hardwareWallet = _wallet;
  }

  function HydroCoinPresale() {
    startTimestamp = 1506333600;
    endTimestamp = startTimestamp + 1 weeks;

    token = new HydroCoin();

    require(startTimestamp >= now);
    require(endTimestamp >= startTimestamp);

    token.mint(companyTokens, vendorAllocation);
  }

  // check if valid purchase
  modifier validPurchase {
    require(now >= startTimestamp);
    require(now <= endTimestamp);
    require(msg.value >= minContribution);
    require(weiRaised.add(msg.value) <= hardcap);
    _;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    if (now > endTimestamp)
        return true;
    if (weiRaised >= hardcap)
        return true;
    return false;
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable validPurchase {
    require(beneficiary != 0x0);

    uint256 weiAmount = msg.value;

    if (deposits[msg.sender] == 0) {
        numberOfPurchasers++;
    }
    deposits[msg.sender] = weiAmount.add(deposits[msg.sender]);
    

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    hardwareWallet.transfer(msg.value);
  }

  // transfer ownership of the token to the owner of the presale contract
  function finishPresale() public onlyOwner {
    require(hasEnded());
    token.transferOwnership(owner);
    PreSaleClosed();
  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

    function emergencyERC20Drain( ERC20 theToken, uint amount ) {
        theToken.transfer(owner, amount);
    }


}