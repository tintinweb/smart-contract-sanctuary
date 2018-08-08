pragma solidity ^0.4.21;
contract ERC20Token  {
  function transfer(address to, uint256 value) public returns (bool);
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
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
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Pausable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}




contract PTMCrowdFund is Destructible {
    event PurchaseToken (address indexed from,uint256 weiAmount,uint256 _tokens);
     uint public priceOfToken=250000000000000;//1 eth = 4000 PTM
    ERC20Token erc20Token;
    using SafeMath for uint256;
    uint256 etherRaised;
    uint public constant decimals = 18;
    function PTMCrowdFund () public {
        owner = msg.sender;
        erc20Token = ERC20Token(0x7c32DB0645A259FaE61353c1f891151A2e7f8c1e);
    }
    function updatePriceOfToken(uint256 priceInWei) external onlyOwner {
        priceOfToken = priceInWei;
    }
    
    function updateTokenAddress ( address _tokenAddress) external onlyOwner {
        erc20Token = ERC20Token(_tokenAddress);
    }
    
      function()  public whenNotPaused payable {
          require(msg.value>0);
          uint256 tokens = (msg.value * (10 ** decimals)) / priceOfToken;
          erc20Token.transfer(msg.sender,tokens);
          etherRaised += msg.value;
          
      }
      
        /**
    * Transfer entire balance to any account (by owner and admin only)
    **/
    function transferFundToAccount(address _accountByOwner) public onlyOwner {
        require(etherRaised > 0);
        _accountByOwner.transfer(etherRaised);
        etherRaised = 0;
    }

    
    /**
    * Transfer part of balance to any account (by owner and admin only)
    **/
    function transferLimitedFundToAccount(address _accountByOwner, uint256 balanceToTransfer) public onlyOwner   {
        require(etherRaised > balanceToTransfer);
        _accountByOwner.transfer(balanceToTransfer);
        etherRaised = etherRaised.sub(balanceToTransfer);
    }
    
}