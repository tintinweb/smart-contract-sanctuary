pragma solidity ^0.4.24;

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
pragma solidity ^0.4.16;

/*
 * Abstract Token Smart Contract.  Copyright &#169; 2017 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e4898d8f8c858d88ca928885808d898d968b92a48389858d88ca878b89">[email&#160;protected]</a>>
 */
pragma solidity ^0.4.20;

/*
 * EIP-20 Standard Token Smart Contract Interface.
 * Copyright &#169; 2016–2018 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="8be6e2e0e3eae2e7a5fde7eaefe2e6e2f9e4fdcbece6eae2e7a5e8e4e6">[email&#160;protected]</a>>
 */
pragma solidity ^0.4.20;

/**
 * ERC-20 standard token interface, as defined
 * <a href="https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md">here</a>.
 */
contract Token {
  /**
   * Get total number of tokens in circulation.
   *
   * @return total number of tokens in circulation
   */
  function totalSupply () public view returns (uint256 supply);

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) public view returns (uint256 balance);

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value)
  public returns (bool success);

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
   *        recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success);

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value)
  public returns (bool success);

  /**
   * Tell how many tokens given spender is currently allowed to transfer from
   * given owner.
   *
   * @param _owner address to get number of tokens allowed to be transferred
   *        from the owner of
   * @param _spender address to get number of tokens allowed to be transferred
   *        by the owner of
   * @return number of tokens given spender is currently allowed to transfer
   *         from given owner
   */
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining);

  /**
   * Logged when tokens were transferred from one owner to another.
   *
   * @param _from address of the owner, tokens were transferred from
   * @param _to address of the owner, tokens were transferred to
   * @param _value number of tokens transferred
   */
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

  /**
   * Logged when owner approved his tokens to be transferred by some spender.
   *
   * @param _owner owner who approved his tokens to be transferred
   * @param _spender spender who were allowed to transfer the tokens belonging
   *        to the owner
   * @param _value number of tokens belonging to the owner, approved to be
   *        transferred by the spender
   */
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}
/*
 * Safe Math Smart Contract.  Copyright &#169; 2016–2017 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0e636765666f67622078626f6a6763677c61784e69636f6762206d6163">[email&#160;protected]</a>>
 */
pragma solidity ^0.4.20;

/**
 * Provides methods to safely add, subtract and multiply uint256 numbers.
 */
contract MySafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Add two uint256 values, throw in case of overflow.
   *
   * @param x first value to add
   * @param y second value to add
   * @return x + y
   */
  function safeAdd (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
    return x + y;
  }

  /**
   * Subtract one uint256 value from another, throw in case of underflow.
   *
   * @param x value to subtract from
   * @param y value to subtract
   * @return x - y
   */
  function safeSub (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x >= y);
    return x - y;
  }

  /**
   * Multiply two uint256 values, throw in case of overflow.
   *
   * @param x first value to multiply
   * @param y second value to multiply
   * @return x * y
   */
  function safeMul (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
}


/**
 * Abstract Token Smart Contract that could be used as a base contract for
 * ERC-20 token contracts.
 */
contract AbstractToken is Token, MySafeMath {
  /**
   * Create new Abstract Token contract.
   */
  function AbstractToken () public {
    // Do nothing
  }

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) public view returns (uint256 balance) {
    return accounts [_owner];
  }

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value)
  public returns (bool success) {
    uint256 fromBalance = accounts [msg.sender];
    if (fromBalance < _value) return false;
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = safeSub (fromBalance, _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (msg.sender, _to, _value);
    return true;
  }

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
   *        recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success) {
    uint256 spenderAllowance = allowances [_from][msg.sender];
    if (spenderAllowance < _value) return false;
    uint256 fromBalance = accounts [_from];
    if (fromBalance < _value) return false;

    allowances [_from][msg.sender] =
      safeSub (spenderAllowance, _value);

    if (_value > 0 && _from != _to) {
      accounts [_from] = safeSub (fromBalance, _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (_from, _to, _value);
    return true;
  }

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value)
  public returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    Approval (msg.sender, _spender, _value);

    return true;
  }

  /**
   * Tell how many tokens given spender is currently allowed to transfer from
   * given owner.
   *
   * @param _owner address to get number of tokens allowed to be transferred
   *        from the owner of
   * @param _spender address to get number of tokens allowed to be transferred
   *        by the owner of
   * @return number of tokens given spender is currently allowed to transfer
   *         from given owner
   */
  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

  /**
   * Mapping from addresses of token holders to the numbers of tokens belonging
   * to these token holders.
   */
  mapping (address => uint256) internal accounts;

  /**
   * Mapping from addresses of token holders to the mapping of addresses of
   * spenders to the allowances set by these token holders to these spenders.
   */
  mapping (address => mapping (address => uint256)) internal allowances;
}


/**
 * Social Media Market token smart contract.
 */
contract SocialMediaMarketToken is AbstractToken {
  /**
   * Address of the owner of this smart contract.
   */
  address private owner;

  /**
   * Total number of tokens in circulation.
   */
  uint256 tokenCount;

  /**
   * True if tokens transfers are currently frozen, false otherwise.
   */
  bool frozen = false;

  /**
   * Create new Social Media Market token smart contract, with given number of tokens issued
   * and given to msg.sender, and make msg.sender the owner of this smart
   * contract.
   *
   * @param _tokenCount number of tokens to issue and give to msg.sender
   */
  function SocialMediaMarketToken (uint256 _tokenCount) public {
    owner = msg.sender;
    tokenCount = _tokenCount;
    accounts [msg.sender] = _tokenCount;
  }

  /**
   * Get total number of tokens in circulation.
   *
   * @return total number of tokens in circulation
   */
  function totalSupply () public view returns (uint256 supply) {
    return tokenCount;
  }

  /**
   * Get name of this token.
   *
   * @return name of this token
   */
  function name () public pure returns (string result) {
    return "Test Social Media Market";
  }

  /**
   * Get symbol of this token.
   *
   * @return symbol of this token
   */
  function symbol () public pure returns (string result) {
    return "TSMM";
  }

  /**
   * Get number of decimals for this token.
   *
   * @return number of decimals for this token
   */
  function decimals () public pure returns (uint8 result) {
    return 8;
  }

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value)
    public returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transfer (_to, _value);
  }

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
   *        recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
    public returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }

  /**
   * Change how many tokens given spender is allowed to transfer from message
   * spender.  In order to prevent double spending of allowance, this method
   * receives assumed current allowance value as an argument.  If actual
   * allowance differs from an assumed one, this method just returns false.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _currentValue assumed number of tokens currently allowed to be
   *        transferred
   * @param _newValue number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _currentValue, uint256 _newValue)
    public returns (bool success) {
    if (allowance (msg.sender, _spender) == _currentValue)
      return approve (_spender, _newValue);
    else return false;
  }

  /**
   * Burn given number of tokens belonging to message sender.
   *
   * @param _value number of tokens to burn
   * @return true on success, false on error
   */
  function burnTokens (uint256 _value) public returns (bool success) {
    if (_value > accounts [msg.sender]) return false;
    else if (_value > 0) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      tokenCount = safeSub (tokenCount, _value);

      Transfer (msg.sender, address (0), _value);
      return true;
    } else return true;
  }

  /**
   * Set new owner for the smart contract.
   * May only be called by smart contract owner.
   *
   * @param _newOwner address of new owner of the smart contract
   */
  function setOwner (address _newOwner) public {
    require (msg.sender == owner);

    owner = _newOwner;
  }

  /**
   * Freeze token transfers.
   * May only be called by smart contract owner.
   */
  function freezeTransfers () public {
    require (msg.sender == owner);

    if (!frozen) {
      frozen = true;
      Freeze ();
    }
  }

  /**
   * Unfreeze token transfers.
   * May only be called by smart contract owner.
   */
  function unfreezeTransfers () public {
    require (msg.sender == owner);

    if (frozen) {
      frozen = false;
      Unfreeze ();
    }
  }

  /**
   * Logged when token transfers were frozen.
   */
  event Freeze ();

  /**
   * Logged when token transfers were unfrozen.
   */
  event Unfreeze ();
}

contract MyToken is SocialMediaMarketToken {}

contract SocialMediaMarket is Ownable {
    using SafeMath for uint256;

    MyToken private _token;

    address public platform;
    address public token;
    uint8 public decimals;
    uint256 public percent;
    string public version = "0.0.2";

    struct Item {
        uint256 amount;
        uint256 fee_amount;
        uint256 amountTransferred;
        address adv_address;
        address inf_address;
        uint256 percent;
        int256 status;
    }

    mapping(uint64 => Item) public items;

    event InitiatedEscrow(uint64 indexed id, uint256 _amount, uint256 _fee_amount, address adv_address, address inf_address);
    event Withdraw(uint64 indexed id, uint256 _amount, address _person, address _platform, uint256 _percent, uint256 _percentBack);
    event Payback(uint64 indexed id, uint256 _amount, address _person);

    constructor(address tokenAddress, address platformAddress, uint256 percentPayout) public {
        require(platformAddress != 0x0);
        require(percentPayout > 0 && percentPayout < 100);

        platform = platformAddress;
        percent = percentPayout;

        token = tokenAddress;
        _token = MyToken(tokenAddress);
        decimals = _token.decimals();
    }
    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */

    function renounceOwnership() public onlyOwner {
        revert(&#39;renounceOwnership is blocked&#39;);
    }

    function initiateEscrow(uint64 id, uint256 amount, uint256 fee_amount, address adv_address, address inf_address) onlyOwner public {
        require(items[id].amount == 0);
        require(amount > 0);
        require(fee_amount > 0);

        uint256 approveAmount = amount.add(fee_amount);
        require(_token.allowance(adv_address, address(this)) >= approveAmount);

        require(_token.transferFrom(adv_address, address(this), approveAmount));

        items[id] = Item(amount, fee_amount, approveAmount, adv_address, inf_address, percent, 0);

        emit InitiatedEscrow(id, amount, fee_amount, adv_address, inf_address);
    }

    function updateEscrow(uint64 id, uint256 amount, uint256 fee_amount) onlyOwner public {
        require(items[id].amount > 0);
        require(items[id].status == 0);
        require(items[id].amount != amount);
        require(amount > 0);
        require(fee_amount > 0);

        uint256 currentAmount = amount.add(fee_amount);
        if (currentAmount <= items[id].amountTransferred) {
            items[id].amount = amount;
            items[id].fee_amount = fee_amount;
        }
        else {
            uint256 approveAmount = currentAmount - items[id].amountTransferred;
            require(_token.allowance(items[id].adv_address, address(this)) >= approveAmount);
            items[id].amount = amount;
            items[id].fee_amount = fee_amount;
            items[id].amountTransferred = currentAmount;
            require(_token.transferFrom(items[id].adv_address, address(this), approveAmount));
        }
    }


    function withdraw(uint64 id, address[] addresses, uint256 percentBack) onlyOwner public {
        require(items[id].amount > 0);
        require(items[id].status == 0);
        require(percentBack <= items[id].percent);
        uint256 currentAmount = items[id].amount.mul(100 - items[id].percent) / 100;
        require(_token.transfer(items[id].inf_address, currentAmount));
        uint256 currentFee = 0;
        if (addresses.length > 0) {
            require(items[id].fee_amount / addresses.length > 0);

            for (uint256 i = 0; i < addresses.length; i += 1) {
                require(_token.transfer(addresses[i], items[id].fee_amount / addresses.length));
            }
            currentFee = items[id].fee_amount % addresses.length;
            items[id].status = 2;
        } else {
            currentFee = items[id].fee_amount;
            items[id].status = 1;
        }

        uint256 amountBack = items[id].amountTransferred - items[id].amount - items[id].fee_amount;
        currentAmount = items[id].amount - currentAmount;

        if (percentBack == 0 && amountBack == 0) {
            require(_token.transfer(platform, currentAmount + currentFee));
        } else {
            uint256 currentAmountBack = currentAmount.mul(percentBack) / items[id].percent;

            require(_token.transfer(items[id].adv_address, currentAmountBack + amountBack));
            if (percentBack < items[id].percent || currentFee != 0) {
                require(_token.transfer(platform, currentAmount - currentAmountBack + currentFee));
            }
        }


        emit Withdraw(id, items[id].amount, items[id].inf_address, platform, items[id].percent, percentBack);

    }

    function payback(uint64 id, address[] addresses) onlyOwner public {
        require(items[id].amount > 0);
        require(items[id].status == 0);
        require(_token.transfer(items[id].adv_address, items[id].amountTransferred - items[id].fee_amount));
        uint256 currentFee = 0;
        if (addresses.length > 0) {
            uint256 feeForPerson = items[id].fee_amount / addresses.length;
            require(feeForPerson > 0);

            for (uint256 i = 0; i < addresses.length; i += 1) {
                require(_token.transfer(addresses[i], feeForPerson));
            }
            currentFee = items[id].fee_amount % addresses.length;
            items[id].status = - 2;
        } else {
            currentFee = items[id].fee_amount;
            items[id].status = - 1;
        }

        if (currentFee > 0) {
            require(_token.transfer(platform, currentFee));
        }

        emit Payback(id, items[id].amountTransferred - items[id].fee_amount, items[id].adv_address);
    }

    function changePlatform(address platformAddress) onlyOwner public {
        require(platformAddress != platform);
        require(platformAddress != 0x0);
        platform = platformAddress;
    }

    function changePercent(uint256 percentPayout) onlyOwner public {
        require(percentPayout != percent);
        require(percentPayout > 0 && percentPayout < 100);
        percent = percentPayout;
    }
}