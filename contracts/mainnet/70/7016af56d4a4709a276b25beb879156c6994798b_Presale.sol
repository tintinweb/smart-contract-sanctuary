pragma solidity ^0.4.18;

// File: contracts/IPricingStrategy.sol

interface IPricingStrategy {

    function isPricingStrategy() public view returns (bool);

    /** Calculate the current price for buy in amount. */
    function calculateTokenAmount(uint weiAmount, uint tokensSold) public view returns (uint tokenAmount);

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

// File: contracts/token/ERC223.sol

contract ERC223 is ERC20 {
    function transfer(address _to, uint _value, bytes _data) public returns (bool);
    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

// File: contracts/token/TokenReciever.sol

/*
 * Contract that is working with ERC223 tokens
 */
 
 contract TokenReciever {
    function tokenFallback(address _from, uint _value, bytes _data) public pure {
    }
}

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

// File: zeppelin-solidity/contracts/ownership/Contactable.sol

/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable{

    string public contactInformation;

    /**
     * @dev Allows the owner to set a string with their contact information.
     * @param info The contact information to attach to the contract.
     */
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}

// File: contracts/token/PlayHallToken.sol

contract PlayHallToken is ERC223, Contactable {
    using SafeMath for uint;

    string constant public name = "PlayHall Token";
    string constant public symbol = "PHT";
    uint constant public decimals = 18;

    bool public isActivated = false;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) internal allowed;
    mapping (address => bool) public freezedList;
    
    // address, who is allowed to issue new tokens (presale and sale contracts)
    address public minter;

    bool public mintingFinished = false;

    event Mint(address indexed to, uint amount);
    event MintingFinished();

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier whenActivated() {
        require(isActivated);
        _;
    }

    function PlayHallToken() public {
        minter = msg.sender;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public returns (bool) {
        bytes memory empty;
        return transfer(_to, _value, empty);
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data Optional metadata.
    */
    function transfer(address _to, uint _value, bytes _data) public whenActivated returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(!freezedList[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        if (isContract(_to)) {
            TokenReciever receiver = TokenReciever(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        bytes memory empty;
        return transferFrom(_from, _to, _value, empty);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     * @param _data Optional metadata.
     */
    function transferFrom(address _from, address _to, uint _value, bytes _data) public whenActivated returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(!freezedList[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        if (isContract(_to)) {
            TokenReciever receiver = TokenReciever(_to);
            receiver.tokenFallback(_from, _value, _data);
        }

        Transfer(_from, _to, _value);
        Transfer(_from, _to, _value, _data);
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
    function approve(address _spender, uint _value) public returns (bool) {
        require(_value == 0 || allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint) {
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

      /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint _amount, bool freeze) canMint onlyMinter external returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        if (freeze) {
            freezedList[_to] = true;
        }
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() canMint onlyMinter external returns (bool) {
        mintingFinished = true;
        MintingFinished();
        return true;
    }
    
    /**
     * Minter can pass it&#39;s role to another address
     */
    function setMinter(address _minter) external onlyMinter {
        require(_minter != 0x0);
        minter = _minter;
    }

    /**
     * Owner can unfreeze any address
     */
    function removeFromFreezedList(address user) external onlyOwner {
        freezedList[user] = false;
    }

    /**
     * Activation of the token allows all tokenholders to operate with the token
     */
    function activate() external onlyOwner returns (bool) {
        isActivated = true;
        return true;
    }

    function isContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
              //retrieve the size of the code on target address, this needs assembly
              length := extcodesize(_addr)
        }
        return (length>0);
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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: contracts/SaleBase.sol

contract SaleBase is Pausable, Contactable {
    using SafeMath for uint;
  
    // The token being sold
    PlayHallToken public token;
  
    // start and end timestamps where purchases are allowed (both inclusive)
    uint public startTime;
    uint public endTime;
  
    // address where funds are collected
    address public wallet;
  
    // the contract, which determine how many token units a buyer gets per wei
    IPricingStrategy public pricingStrategy;
  
    // amount of raised money in wei
    uint public weiRaised;

    // amount of tokens that was sold on the crowdsale
    uint public tokensSold;

    // maximum amount of wei in total, that can be bought
    uint public weiMaximumGoal;

    // if weiMinimumGoal will not be reached till endTime, buyers will be able to refund ETH
    uint public weiMinimumGoal;

    // minimum amount of wel, that can be contributed
    uint public weiMinimumAmount;

    // How many distinct addresses have bought
    uint public buyerCount;

    // how much wei we have returned back to the contract after a failed crowdfund
    uint public loadedRefund;

    // how much wei we have given back to buyers
    uint public weiRefunded;

    // how much ETH each address has bought to this crowdsale
    mapping (address => uint) public boughtAmountOf;

    // whether a buyer already bought some tokens
    mapping (address => bool) public isBuyer;

    // whether a buyer bought tokens through other currencies
    mapping (address => bool) public isExternalBuyer;

    address public admin;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param tokenAmount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint value,
        uint tokenAmount
    );

    // a refund was processed for an buyer
    event Refund(address buyer, uint weiAmount);
    event RefundLoaded(uint amount);

    function SaleBase(
        uint _startTime,
        uint _endTime,
        IPricingStrategy _pricingStrategy,
        PlayHallToken _token,
        address _wallet,
        uint _weiMaximumGoal,
        uint _weiMinimumGoal,
        uint _weiMinimumAmount,
        address _admin
    ) public
    {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_pricingStrategy.isPricingStrategy());
        require(address(_token) != 0x0);
        require(_wallet != 0x0);
        require(_weiMaximumGoal > 0);
        require(_admin != 0x0);

        startTime = _startTime;
        endTime = _endTime;
        pricingStrategy = _pricingStrategy;
        token = _token;
        wallet = _wallet;
        weiMaximumGoal = _weiMaximumGoal;
        weiMinimumGoal = _weiMinimumGoal;
        weiMinimumAmount = _weiMinimumAmount;
        admin = _admin;
    }


    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == admin); 
        _;
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public whenNotPaused payable returns (bool) {
        uint weiAmount = msg.value;

        require(beneficiary != 0x0);
        require(weiAmount >= weiMinimumAmount);
        require(validPurchase(msg.value));
    
        // calculate token amount to be created
        uint tokenAmount = pricingStrategy.calculateTokenAmount(weiAmount, weiRaised);
        
        mintTokenToBuyer(beneficiary, tokenAmount, weiAmount);
        
        wallet.transfer(msg.value);

        return true;
    }

    function mintTokenToBuyer(address beneficiary, uint tokenAmount, uint weiAmount) internal {
        if (!isBuyer[beneficiary]) {
            // A new buyer
            buyerCount++;
            isBuyer[beneficiary] = true;
        }

        boughtAmountOf[beneficiary] = boughtAmountOf[beneficiary].add(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);
    
        token.mint(beneficiary, tokenAmount, true);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
    }

    // return true if the transaction can buy tokens
    function validPurchase(uint weiAmount) internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool withinCap = weiRaised.add(weiAmount) <= weiMaximumGoal;

        return withinPeriod && withinCap;
    }

    // return true if crowdsale event has ended
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= weiMaximumGoal;
        bool afterEndTime = now > endTime;
        
        return capReached || afterEndTime;
    }

    // get the amount of unsold tokens allocated to this contract;
    function getWeiLeft() external constant returns (uint) {
        return weiMaximumGoal - weiRaised;
    }

    // return true if the crowdsale has raised enough money to be a successful.
    function isMinimumGoalReached() public constant returns (bool) {
        return weiRaised >= weiMinimumGoal;
    }
    
    // allows to update tokens rate for owner
    function setPricingStrategy(IPricingStrategy _pricingStrategy) external onlyOwner returns (bool) {
        pricingStrategy = _pricingStrategy;
        return true;
    }

    /**
    * Allow load refunds back on the contract for the refunding.
    *
    * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
    */
    function loadRefund() external payable {
        require(msg.sender == wallet);
        require(msg.value > 0);
        require(!isMinimumGoalReached());
        
        loadedRefund = loadedRefund.add(msg.value);

        RefundLoaded(msg.value);
    }

    /**
    * Buyers can claim refund.
    *
    * Note that any refunds from proxy buyers should be handled separately,
    * and not through this contract.
    */
    function refund() external {
        require(!isMinimumGoalReached() && loadedRefund > 0);
        require(!isExternalBuyer[msg.sender]);
        uint weiValue = boughtAmountOf[msg.sender];
        require(weiValue > 0);
        
        boughtAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);
        msg.sender.transfer(weiValue);

        Refund(msg.sender, weiValue);
    }

    function registerPayment(address beneficiary, uint tokenAmount, uint weiAmount) public onlyOwnerOrAdmin {
        require(validPurchase(weiAmount));
        isExternalBuyer[beneficiary] = true;
        mintTokenToBuyer(beneficiary, tokenAmount, weiAmount);
    }

    function registerPayments(address[] beneficiaries, uint[] tokenAmounts, uint[] weiAmounts) external onlyOwnerOrAdmin {
        require(beneficiaries.length == tokenAmounts.length);
        require(tokenAmounts.length == weiAmounts.length);

        for (uint i = 0; i < beneficiaries.length; i++) {
            registerPayment(beneficiaries[i], tokenAmounts[i], weiAmounts[i]);
        }
    }

    function setAdmin(address adminAddress) external onlyOwner {
        admin = adminAddress;
    }
}

// File: contracts/presale/Presale.sol

/**
 * @title Presale
 * @dev Presale is a contract for managing a token crowdsale.
 * Presales have a start and end timestamps, where buyers can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Presale is SaleBase {
    function Presale(
        uint _startTime,
        uint _endTime,
        IPricingStrategy _pricingStrategy,
        PlayHallToken _token,
        address _wallet,
        uint _weiMaximumGoal,
        uint _weiMinimumGoal,
        uint _weiMinimumAmount,
        address _admin
    ) public SaleBase(
        _startTime,
        _endTime,
        _pricingStrategy,
        _token,
        _wallet,
        _weiMaximumGoal,
        _weiMinimumGoal,
        _weiMinimumAmount,
        _admin) 
    {

    }

    function changeTokenMinter(address newMinter) external onlyOwner {
        require(newMinter != 0x0);
        require(hasEnded());

        token.setMinter(newMinter);
    }
}