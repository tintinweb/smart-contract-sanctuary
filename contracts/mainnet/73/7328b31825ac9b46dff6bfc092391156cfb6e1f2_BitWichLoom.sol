pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
    require(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

contract NamedToken is ERC20 {
   string public name;
   string public symbol;
}

contract BitWich is Pausable {
    using SafeMath for uint;
    using SafeERC20 for ERC20;
    
    event LogBought(address indexed buyer, uint buyCost, uint amount);
    event LogSold(address indexed seller, uint sellValue, uint amount);
    event LogPriceChanged(uint newBuyCost, uint newSellValue);

    // ERC20 contract to operate over
    ERC20 public erc20Contract;

    // amount bought - amount sold = amount willing to buy from others
    uint public netAmountBought;
    
    // number of tokens that can be bought from contract per wei sent
    uint public buyCost;
    
    // number of tokens that can be sold to contract per wei received
    uint public sellValue;
    
    constructor(uint _buyCost, 
                uint _sellValue,
                address _erc20ContractAddress) public {
        require(_buyCost > 0);
        require(_sellValue > 0);
        
        buyCost = _buyCost;
        sellValue = _sellValue;
        erc20Contract = NamedToken(_erc20ContractAddress);
    }
    
    /* ACCESSORS */
    function tokenName() external view returns (string) {
        return NamedToken(erc20Contract).name();
    }
    
    function tokenSymbol() external view returns (string) {
        return NamedToken(erc20Contract).symbol();
    }
    
    function amountForSale() external view returns (uint) {
        return erc20Contract.balanceOf(address(this));
    }
    
    // Accessor for the cost in wei of buying a certain amount of tokens.
    function getBuyCost(uint _amount) external view returns(uint) {
        uint cost = _amount.div(buyCost);
        if (_amount % buyCost != 0) {
            cost = cost.add(1); // Handles truncating error for odd buyCosts
        }
        return cost;
    }
    
    // Accessor for the value in wei of selling a certain amount of tokens.
    function getSellValue(uint _amount) external view returns(uint) {
        return _amount.div(sellValue);
    }
    
    /* PUBLIC FUNCTIONS */
    // Perform the buy of tokens for ETH and add to the net amount bought
    function buy(uint _minAmountDesired) external payable whenNotPaused {
        processBuy(msg.sender, _minAmountDesired);
    }
    
    // Perform the sell of tokens, send ETH to the seller, and reduce the net amount bought
    // NOTE: seller must call ERC20.approve() first before calling this,
    //       unless they can use ERC20.approveAndCall() directly
    function sell(uint _amount, uint _weiExpected) external whenNotPaused {
        processSell(msg.sender, _amount, _weiExpected);
    }
    
    /* INTERNAL FUNCTIONS */
    // NOTE: _minAmountDesired protects against cost increase between send time and process time
    function processBuy(address _buyer, uint _minAmountDesired) internal {
        uint amountPurchased = msg.value.mul(buyCost);
        require(erc20Contract.balanceOf(address(this)) >= amountPurchased);
        require(amountPurchased >= _minAmountDesired);
        
        netAmountBought = netAmountBought.add(amountPurchased);
        emit LogBought(_buyer, buyCost, amountPurchased);

        erc20Contract.safeTransfer(_buyer, amountPurchased);
    }
    
    // NOTE: _weiExpected protects against a value decrease between send time and process time
    function processSell(address _seller, uint _amount, uint _weiExpected) internal {
        require(netAmountBought >= _amount);
        require(erc20Contract.allowance(_seller, address(this)) >= _amount);
        uint value = _amount.div(sellValue); // tokens divided by (tokens per wei) equals wei
        require(value >= _weiExpected);
        assert(address(this).balance >= value); // contract should always have enough wei
        _amount = value.mul(sellValue); // in case of rounding down, reduce the _amount sold
        
        netAmountBought = netAmountBought.sub(_amount);
        emit LogSold(_seller, sellValue, _amount);
        
        erc20Contract.safeTransferFrom(_seller, address(this), _amount);
        _seller.transfer(value);
    }
    
    // NOTE: this should never return true unless this contract has a bug 
    function lacksFunds() external view returns(bool) {
        return address(this).balance < getRequiredBalance(sellValue);
    }
    
    /* OWNER FUNCTIONS */
    // Owner function to check how much extra ETH is available to cash out
    function amountAvailableToCashout() external view onlyOwner returns (uint) {
        return address(this).balance.sub(getRequiredBalance(sellValue));
    }

    // Owner function for cashing out extra ETH not needed for buying tokens
    function cashout() external onlyOwner {
        uint requiredBalance = getRequiredBalance(sellValue);
        assert(address(this).balance >= requiredBalance);
        
        owner.transfer(address(this).balance.sub(requiredBalance));
    }
    
    // Owner function for closing the paused contract and cashing out all tokens and ETH
    function close() public onlyOwner whenPaused {
        erc20Contract.transfer(owner, erc20Contract.balanceOf(address(this)));
        selfdestruct(owner);
    }
    
    // Owner accessor to get how much ETH is needed to send 
    // in order to change sell price to proposed price
    function extraBalanceNeeded(uint _proposedSellValue) external view onlyOwner returns (uint) {
        uint requiredBalance = getRequiredBalance(_proposedSellValue);
        return (requiredBalance > address(this).balance) ? requiredBalance.sub(address(this).balance) : 0;
    }
    
    // Owner function for adjusting prices (might need to add ETH if raising sell price)
    function adjustPrices(uint _buyCost, uint _sellValue) external payable onlyOwner whenPaused {
        buyCost = _buyCost == 0 ? buyCost : _buyCost;
        sellValue = _sellValue == 0 ? sellValue : _sellValue;
        
        uint requiredBalance = getRequiredBalance(sellValue);
        require(msg.value.add(address(this).balance) >= requiredBalance);
        
        emit LogPriceChanged(buyCost, sellValue);
    }
    
    function getRequiredBalance(uint _proposedSellValue) internal view returns (uint) {
        return netAmountBought.div(_proposedSellValue).add(1);
    }
    
    // Owner can transfer out any accidentally sent ERC20 tokens
    // excluding the token intended for this contract
    function transferAnyERC20Token(address _address, uint _tokens) external onlyOwner {
        require(_address != address(erc20Contract));
        
        ERC20(_address).safeTransfer(owner, _tokens);
    }
}

contract BitWichLoom is BitWich {
    constructor() 
            BitWich(800, 1300, 0xA4e8C3Ec456107eA67d3075bF9e3DF3A75823DB0) public {
    }
}