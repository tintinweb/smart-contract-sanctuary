pragma solidity ^0.4.21;


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
      emit WhitelistedAddressAdded(addr);
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
      emit WhitelistedAddressRemoved(addr);
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

contract BuyLimits {
    event LogLimitsChanged(uint _minBuy, uint _maxBuy);

    // Variables holding the min and max payment in wei
    uint public minBuy; // min buy in wei
    uint public maxBuy; // max buy in wei, 0 means no maximum

    /*
    ** Modifier, reverting if not within limits.
    */
    modifier isWithinLimits(uint _amount) {
        require(withinLimits(_amount));
        _;
    }

    /*
    ** @dev Constructor, define variable:
    */
    function BuyLimits(uint _min, uint  _max) public {
        _setLimits(_min, _max);
    }

    /*
    ** @dev Check TXs value is within limits:
    */
    function withinLimits(uint _value) public view returns(bool) {
        if (maxBuy != 0) {
            return (_value >= minBuy && _value <= maxBuy);
        }
        return (_value >= minBuy);
    }

    /*
    ** @dev set limits logic:
    ** @param _min set the minimum buy in wei
    ** @param _max set the maximum buy in wei, 0 indeicates no maximum
    */
    function _setLimits(uint _min, uint _max) internal {
        if (_max != 0) {
            require (_min <= _max); // Sanity Check
        }
        minBuy = _min;
        maxBuy = _max;
        emit LogLimitsChanged(_min, _max);
    }
}


/**
 * @title DAOstackPresale
 * @dev A contract to allow only whitelisted followers to participate in presale.
 */
contract DAOstackPreSale is Pausable,BuyLimits,Whitelist {
    event LogFundsReceived(address indexed _sender, uint _amount);

    address public wallet;

    /**
    * @dev Constructor.
    * @param _wallet Address where the funds are transfered to
    * @param _minBuy Address where the funds are transfered to
    * @param _maxBuy Address where the funds are transfered to
    */
    function DAOstackPreSale(address _wallet, uint _minBuy, uint _maxBuy)
    public
    BuyLimits(_minBuy, _maxBuy)
    {
        // Set wallet:
        require(_wallet != address(0));
        wallet = _wallet;
    }

    /**
    * @dev Fallback, funds coming in are transfered to wallet
    */
    function () payable whenNotPaused onlyWhitelisted isWithinLimits(msg.value) external {
        wallet.transfer(msg.value);
        emit LogFundsReceived(msg.sender, msg.value);
    }

    /*
    ** @dev Drain function, in case of failure. Contract should not hold eth anyhow.
    */
    function drain() external {
        wallet.transfer((address(this)).balance);
    }

}