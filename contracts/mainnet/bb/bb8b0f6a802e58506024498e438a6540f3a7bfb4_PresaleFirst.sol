pragma solidity ^0.4.19;


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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      WhitelistedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

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


contract PresaleFirst is Whitelist, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public constant maxcap = 1500 ether;
    uint256 public constant exceed = 300 ether;
    uint256 public constant minimum = 0.5 ether;
    uint256 public constant rate = 11500;

    uint256 public startNumber;
    uint256 public endNumber;
    uint256 public weiRaised;
    address public wallet;
    ERC20 public token;

    function PresaleFirst (
        uint256 _startNumber,
        uint256 _endNumber,
        address _wallet,
        address _token
        ) public {
        require(_wallet != address(0));
        require(_token != address(0));

        startNumber = _startNumber;
        endNumber = _endNumber;
        wallet = _wallet;
        token = ERC20(_token);
        weiRaised = 0;
    }

//////////////////
//  collect eth
//////////////////

    mapping (address => uint256) public buyers;
    address[] private keys;

    function getKeyLength() external constant returns (uint256) {
        return keys.length;
    }

    function () external payable {
        collect(msg.sender);
    }

    function collect(address _buyer) public payable onlyWhitelisted whenNotPaused {
        require(_buyer != address(0));
        require(weiRaised <= maxcap);
        require(preValidation());
        require(buyers[_buyer] < exceed);

        // get exist amount
        if(buyers[_buyer] == 0) {
            keys.push(_buyer);
        }

        uint256 purchase = getPurchaseAmount(_buyer);
        uint256 refund = (msg.value).sub(purchase);

        // refund
        _buyer.transfer(refund);

        // buy
        uint256 tokenAmount = purchase.mul(rate);
        weiRaised = weiRaised.add(purchase);

        // wallet
        buyers[_buyer] = buyers[_buyer].add(purchase);
        emit BuyTokens(_buyer, purchase, tokenAmount);
    }

//////////////////
//  validation functions for collect
//////////////////

    function preValidation() private constant returns (bool) {
        // check minimum
        bool a = msg.value >= minimum;

        // sale duration
        bool b = block.number >= startNumber && block.number <= endNumber;

        return a && b;
    }

    function getPurchaseAmount(address _buyer) private constant returns (uint256) {
        return checkOverMaxcap(checkOverExceed(_buyer));
    }

    // 1. check over exceed
    function checkOverExceed(address _buyer) private constant returns (uint256) {
        if(msg.value >= exceed) {
            return exceed;
        } else if(msg.value.add(buyers[_buyer]) >= exceed) {
            return exceed.sub(buyers[_buyer]);
        } else {
            return msg.value;
        }
    }

    // 2. check sale hardcap
    function checkOverMaxcap(uint256 amount) private constant returns (uint256) {
        if((amount + weiRaised) >= maxcap) {
            return (maxcap.sub(weiRaised));
        } else {
            return amount;
        }
    }

//////////////////
//  finalize
//////////////////

    bool finalized = false;

    function finalize() public onlyOwner {
        require(!finalized);
        require(weiRaised >= maxcap || block.number >= endNumber);

        // dev team
        withdrawEther();
        withdrawToken();

        finalized = true;
    }

//////////////////
//  release
//////////////////

    function release(address addr) public onlyOwner {
        require(!finalized);

        token.safeTransfer(addr, buyers[addr].mul(rate));
        emit Release(addr, buyers[addr].mul(rate));

        buyers[addr] = 0;
    }

    function releaseMany(uint256 start, uint256 end) external onlyOwner {
        for(uint256 i = start; i < end; i++) {
            release(keys[i]);
        }
    }

//////////////////
//  refund
//////////////////

    function refund(address addr) public onlyOwner {
        require(!finalized);

        addr.transfer(buyers[addr]);
        emit Refund(addr, buyers[addr]);

        buyers[addr] = 0;
    }

    function refundMany(uint256 start, uint256 end) external onlyOwner {
        for(uint256 i = start; i < end; i++) {
            refund(keys[i]);
        }
    }

//////////////////
//  withdraw
//////////////////

    function withdrawToken() public onlyOwner {
        token.safeTransfer(wallet, token.balanceOf(this));
        emit Withdraw(wallet, token.balanceOf(this));
    }

    function withdrawEther() public onlyOwner {
        wallet.transfer(address(this).balance);
        emit Withdraw(wallet, address(this).balance);
    }

//////////////////
//  events
//////////////////

    event Release(address indexed _to, uint256 _amount);
    event Withdraw(address indexed _from, uint256 _amount);
    event Refund(address indexed _to, uint256 _amount);
    event BuyTokens(address indexed buyer, uint256 price, uint256 tokens);
}